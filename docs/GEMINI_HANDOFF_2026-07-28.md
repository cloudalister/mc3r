# Gemini Handoff — MC3 Recomp — 2026-07-28

## Papel

Você está retomando o boot do runner parcial (`work\link\partial\mc3_partial.exe`). Existe um plano seu de hoje (`docs\RECOMP_PLAN_2026-07-28.md`) que foi auditado (`docs\AUDIT_RECOMP_PLAN_2026-07-28.md`, score 6.5/10) — **leia a auditoria antes de agir**, ela corrige uma premissa errada do seu próprio plano (achava que faltavam 8 objetos do `batch_0015`; já foram compilados às 00:17 de hoje).

Regras anti-alucinação deste projeto (não são negociáveis, ver `docs\MASTER_PLAN_TITLE_SCREEN.md` seção 0 e `BRAIN.md` raiz):
1. Fonte de verdade = `BRAIN.md` + `PS2_PROJECT_STATE.md` + o que você mesmo confirmar rodando comandos. Se um doc mais antigo divergir do que você observa agora no filesystem, **o filesystem vence**.
2. Nunca afirme estado sem rodar o probe e ler o log.
3. Todo experimento de runtime fica atrás de env-gate (`MC3_*=1`) até validar contra PCSX2 real (PCSX2-MCP).
4. Não sinalize semáforos às cegas.
5. Ao editar `.cpp` gerado, lembre: `10_link_partial_runner.bat` **não recompila** — precisa recompilar o batch específico antes do relink (gotcha documentado, custou horas em 07-08).

## Tarefa 1 (bloqueadora, fazer primeiro): destravar o relink

Estado real confirmado agora (não confie no `PS2_PROJECT_STATE.md`, que ainda diz "8 objetos pendentes" — isso é falso):

- `work\compile\ghidra\batch_0015\obj\` tem os 250 objetos, incluindo os 8 que faltavam. Summary CSV: 250 linhas, todas exit code 0.
- Já houve uma tentativa de relink hoje às 00:17 (`work\logs\10_link_partial_runner_driver.log` tem só a linha de início). `work\logs\10_link_partial_runner.log` está vazio (0 bytes) — o `Link-PartialRunner.ps1` não escreveu nada. `mc3_partial.exe` continua com timestamp de 11/07 — **não foi regerado**.
- `Link-PartialRunner.ps1` já usa path absoluto do g++ (`C:\msys64\ucrt64\bin\g++.exe`), então o problema de `PATH` que afetava o `cc1plus` do compile ad-hoc **não é a causa aqui**.

Passos:

1. Rode em primeiro plano, sem redirecionar para log (para ver stdout/stderr direto no terminal):
   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File tools\Generate-PartialRegister.ps1
   ```
   Isso vai regenerar `register_functions.partial.cpp` / `missing_functions.partial.manifest.csv` refletindo que o `batch_0015` está completo agora (o manifest atual, de 14/07, ainda lista 9 endereços como missing — deve cair a 0 ou próximo disso).
2. Se o passo 1 terminar sem erro, rode o link:
   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File tools\Link-PartialRunner.ps1
   ```
   Observe qualquer exceção no terminal. Se travar sem saída, capture o PID do processo filho (`g++`/`ld`) via `Get-Process` para saber se está preso num link gigante (o `.exe` final tem ~460MB, link pode legitimamente demorar minutos — não mate cedo demais, mas se passar de ~10min sem crescer o tamanho do arquivo de saída parcial, é suspeito).
3. Confirme sucesso checando:
   - `work\link\partial\mc3_partial.exe` com timestamp novo.
   - `work\link\partial\missing_functions.partial.manifest.csv` com timestamp novo e, idealmente, sem os 9 endereços do `batch_0015` (`0x2A4AE0`..`0x2A4F40`).
4. Só depois disso, rode o boot probe:
   ```bat
   15_auto_boot_probe.bat 6 payload1m3skip5a
   ```
   e leia `work\boot_probe\latest_status.md`. Reporte a `Stable PC` nova — se ainda for `0x2b4488`, o relink não mudou o gate e a Tarefa 2 (abaixo) vira prioridade; se mudou, documente o novo PC/função antes de continuar.

**Não recompile `batch_0015` de novo** — já está feito, é desperdício de tempo repetir.

## Tarefa 2: causa-raiz do vtable+0x24 null (texture.zip)

Isso é a Etapa 4 do seu plano de hoje e a parte mais sólida dele — mantenha:

- Investigar `sub_004FAED8_0x4faed8` e `sub_004F9A68_0x4f9a68` (estado de inicialização do provedor de pacotes).
- Checar flags globais `0x629f40`, `0x629f41`, `0x629f4c` (fallback chain).
- Objetivo: entender por que `texture.zip` retorna `handle=0xffffffff` em `0x4f9760`. É caminho de arquivo errado no runner nativo, estado do provedor corrompido, ou algo que o jogo real resolve via um passo anterior que o recomp está pulando?
- Isso é análise estática + leitura de log (`work\logs\14_run_boot_trace.log`, grep por `handle=0xffffffff`). Só proponha um experimento env-gated depois de ter uma hipótese concreta de qual valor deveria estar ali — não adivinhe.

## Tarefa 3 (pedido novo do usuário, hoje): pular todos os vídeos/FMV do jogo

O usuário quer pular toda a reprodução de vídeo do jogo (logos, cutscenes, intros) — tanto porque isso não é o foco do recomp quanto porque pode ser exatamente o que está travando o boot antes da tela de título (o provedor de texturas/pacotes falhando em abrir `texture.zip` é consistente com o jogo tentando carregar assets de uma cutscene/vídeo que o ambiente nativo não consegue servir).

Isso é uma tarefa de **investigação primeiro, só leitura** — não patch cego:

1. Confirme que `extracted_iso\` só tem 70 arquivos de sistema (CNF/NETGUI/SYSTEM) e nenhum arquivo de vídeo/movie visível (`.pss`, `.str`, `.mpg`, `.bik` — busquei e não achei nenhum, nem strings "movie"/"fmv"/"intro" no ELF). Isso sugere que os vídeos (se existirem) estão empacotados dentro dos arquivos tipo `texture.zip`/pacotes carregados em runtime, não como arquivos soltos na ISO extraída aqui.
2. Procure no código gerado (`work\generated\ghidra\`) por funções candidatas a player de vídeo/FMV: geralmente reconhecível por (a) abrir um arquivo grande sequencialmente, (b) decodificar em blocos por frame com sync a vsync, (c) rodar antes do menu principal no fluxo de boot. Comece pelo entorno do gate atual (`sub_002B4438_0x2b4438` e quem o chama) e suba a árvore de chamadas até achar quem decide "tocar intro" vs "ir pro menu".
3. Se identificar uma flag/branch tipo "skip intro" ou "modo debug pula vídeo" já existente no binário original (comum em builds de dev do Rockstar/Rage engine), documente o endereço e o valor que a força a pular — isso é preferível a stubar a função de vídeo, porque usa um caminho que o próprio jogo já suporta.
4. Se não houver essa flag, a alternativa é fazer a função identificada retornar imediatamente (no-op) atrás de um env-gate novo, ex. `MC3_SKIP_VIDEO=1`, seguindo o mesmo padrão dos outros experimentos deste projeto (patch pontual, recompilar só o batch daquela função, relink `fast`, validar com `findstr` a string do experimento no `.exe`, rodar probe).
5. **Não prometa isso vai destravar o boot atual** — pode ser uma causa totalmente separada do gate de `0x2b4488`. Trate como investigação paralela; só implemente o env-gate depois de ter uma função concreta identificada, não antes.

Reporte de volta: (a) resultado da Tarefa 1 com o novo Stable PC, (b) qualquer achado concreto da Tarefa 2, (c) a função candidata a "player de vídeo" da Tarefa 3, com endereço e arquivo `.cpp` gerado correspondente — mesmo que ainda não tenha aplicado nenhum patch.
