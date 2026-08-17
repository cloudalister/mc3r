# PS2 Project State: Midnight Club 3 Recomp

Workspace: `D:\TARS\Emuladores\Sony\Playstation 2\isos\mc3recomp`

Game: Midnight Club 3 - DUB Edition Remix  
Serial: `SLUS_213.55`  
ELF: `extracted_iso\SLUS_213.55`  
Partial runner: `work\link\partial\mc3_partial.exe`

## Checkpoint 2026-08-01 06:20:19-06:21:20

- Lote grande de 60s estavel em `0x5419a0`; `render-started`, `dma=2 gif=0 gsw=0 vif=3`.
- Verificacao estrutural passou; trace focalizado preparado para o proximo lote.

## Checkpoint 2026-08-01 06:28-06:31

- Trace confirmou `FUN_005422c8` gravando `0x61fbb4=1`; sem isso o fluxo para em `0x5419a8`.
- Experimento env-gated `MC3_EXPERIMENT_5422C8_SKIP_LATCH=1` foi testado por 20s: continuou em `0x5419a8`, `gif=0 gsw=0`; bypass rejeitado.

## Checkpoint 2026-08-01 06:34-06:40

- Gates experimentais chegaram a `0x2b4488`; trace do provider mostrou objeto `0x6772f0`, vtable `0x6321e0`, metodo `0x429fc0`.
- O metodo retorna `v0=0` com `0x619f40=0`; provider nao inicializado. `gif=0 gsw=0`.
- Proximo alvo documentado: `FUN_00447928 -> FUN_003c8cf8 -> FUN_004faa10`, produtor da flag `0x619f40`.

## Correção de evidência 2026-08-01

- `texture.zip` não existe na ISO/pasta atualmente inspecionada. Menções antigas são hipótese/string live não confirmada, não causa provada.
- Registro completo: `docs\ASSET_EVIDENCE_CORRECTION_2026-08-01.md`.

## Checkpoint 2026-08-01 07:10

- A ISO local possui `ASSETS.DAT`, `STREAMS.DAT`, `TEXTURE.DAT` e `BANKS.DAT`; tamanhos e cabecalhos foram confirmados diretamente.
- O ELF referencia esses quatro conteineres via `cdrom0:`; o runtime resolve `cdrom0:` para `extracted_iso`, onde eles existem.
- Trace em `FUN_00447928` nao apareceu no probe: a rota que deveria marcar `0x619f40` ainda nao e alcancada. Relink passou; sem GIF/GS (`gif=0 gsw=0`).
- Proximo alvo: achar o chamador/registro indireto de `FUN_00447928` ou a inicializacao equivalente, mantendo todos os experimentos env-gated.

## Master Plan

Ordered execution plan, gate anatomy, and anti-hallucination rules: `docs\MASTER_PLAN_TITLE_SCREEN.md` (2026-07-07). Start there.

## Current Objective

Reach visible render/menu in the native partial runner by comparing the recomp boot probe against live PCSX2 behavior.

## Current Recomp Probe

Command:

```bat
15_auto_boot_probe.bat 8 595
```

Latest known status:

- classification: `render-started`
- stable PC: `0x245720`
- function: `sub_00245680_0x245680`
- counters: `dma=2 gif=0 gsw=0 vif=3`
- current blocker: outer loop still waits because `FUN_005422c8_0x5422c8` returns `0`

## Live PCSX2-MCP Plan

Use PCSX2-MCP to observe the real game at the same boot stage, then compare return values, memory writes, and SIF/IOP completion behavior against the recomp trace.

Primary live targets:

- stable recomp PC: `0x245720`
- suspect functions: `0x5422c8`, `0x5420c0`, `0x541760`, `0x541968`, `0x549680`
- suspect memory: `0x0061FC00`, `0x00620D50`, `0x00620D80`, `0x00621600`
- registers: `pc`, `ra`, `sp`, `gp`, `v0`, `a0`, `a1`, `a2`, `a3`, `s0`, `s1`, `s2`, `s3`

## Guardrails

- Gemini/PCSX2-MCP performs read-only live inspection.
- Codex edits runtime/recomp only after live evidence points to a minimal experiment.
- SIF/IOP changes stay env-gated until proven against live PCSX2 behavior.
- Do not launch PCSX2 fullscreen from automation.

## Checkpoint 2026-07-11 05:42 (pausa / registro)

- Objetivo parcial: manter recompilation pronta, com avanço de debug sem correr mais etapas automáticas nesta sessão.
- Status atual do runner: `classification=missing-function`, `Stable PC=0x246740` em `FUN_002466e0_0x2466e0`, render counters `dma=0 gif=0 gsw=0 vif=0`.
- Evidência do travamento: `[dispatch:first-bad-pc] bad=0x42eb90`.
- Mapeamento ativo de stubs faltantes: `work\link\partial\missing_functions.partial.manifest.csv` ainda traz 9 endereços em `batch_0015`:
  - 0x002A4AE0, 0x002A4B98, 0x002A4C18, 0x002A4C68, 0x002A4D68, 0x002A4D78, 0x002A4DC0, 0x002A4E08, 0x002A4F40
- Estado dos objetos: esses símbolos ainda não têm `.o` compilado em `work\compile\ghidra\batch_0015\obj`.
- Registrado por solicitação do usuário: parada momentânea para descanso.
- Próximo passo ao retomar: compilar `batch_0015` (syntax + object), relinkar (`10_link_partial_runner`), rerodar `11_run_partial_runner` + `14_run_boot_trace` + `15_auto_boot_probe`.

## Checkpoint 2026-07-14 10:00 (Investigação Gemini)

- **Status:** Auditoria de retomada e diagnóstico do pipeline de linkagem concluídos com sucesso.
- **Descobertas:** O runner travou no PC `0x2b4488` devido a problemas de package/texturas. O build do `batch_0015` está pendente de 9 objetos, o que impede a linkagem do runner parcial.
- **Documentação:** Nova auditoria detalhada criada em `docs\GEMINI_RECOMP_STATUS_2026-07-14.md`.
- **Ações Imediatas Recomendadas:**
  1. Compilar stubs: `09_compile_generated_batch.bat batch_0015 250 object`
  2. Relincar runner: `10_link_partial_runner.bat`
  3. Rodar boot probe: `15_auto_boot_probe.bat 6 payload1m3skip5a`

## Checkpoint 2026-07-22 07:35 (pausa / pendente)

- Objetivo parcial: testar o menor passo seguro antes de continuar rumo ao render funcional.
- Teste feito: compilacao direta de 1 funcao faltante do `batch_0015`.
- Achado de ambiente: `g++`/`cc1plus` falhava sem mensagem quando `C:\msys64\ucrt64\bin` nao estava no `PATH`.
- Correcao usada no teste: prefixar o comando com `$env:PATH='C:\msys64\ucrt64\bin;' + $env:PATH`.
- Resultado OK: gerado `work\compile\ghidra\batch_0015\obj\sub_002A4AE0_0x2a4ae0.o`.
- Ainda pendente: 8 objetos do `batch_0015`:
  - `sub_002A4B98_0x2a4b98.o`
  - `sub_002A4C18_0x2a4c18.o`
  - `sub_002A4C68_0x2a4c68.o`
  - `FUN_002a4d68_0x2a4d68.o`
  - `FUN_002a4d78_0x2a4d78.o`
  - `sub_002A4DC0_0x2a4dc0.o`
  - `FUN_002a4e08_0x2a4e08.o`
  - `FUN_002a4f40_0x2a4f40.o`
- Proximo passo ao retomar: compilar os 8 objetos restantes com o `PATH` ajustado, relinkar (`10_link_partial_runner.bat`) e depois tentar avancar o boot probe/render.

## Checkpoint 2026-07-28 (auditoria Claude + handoff Gemini)

- **Achado:** os 8 objetos pendentes do `batch_0015` (listados no checkpoint anterior) **já foram compilados** — timestamp `2026-07-28 00:17`, summary CSV com 250/250 linhas, exit code 0. O checkpoint anterior está desatualizado nesse ponto.
- **Achado:** já houve uma tentativa de relink hoje às 00:17 que **não completou** — `work\logs\10_link_partial_runner_driver.log` só tem a linha de início, `work\logs\10_link_partial_runner.log` está vazio, e `mc3_partial.exe` continua com timestamp de 11/07. Causa ainda não diagnosticada (script pode ter sido interrompido antes de logar).
- Gemini recebeu um novo plano hoje (`docs\RECOMP_PLAN_2026-07-28.md`), auditado em `docs\AUDIT_RECOMP_PLAN_2026-07-28.md` (score 6.5/10 — diagnóstico do vtable+0x24/texture.zip é bom, mas a etapa de recompilar `batch_0015` estava obsoleta).
- Handoff ativo para Gemini: `docs\GEMINI_HANDOFF_2026-07-28.md` — 3 tarefas: (1) destravar o relink (não recompilar batch_0015 de novo), (2) causa-raiz do `texture.zip` handle inválido, (3) **pedido novo do usuário**: investigar e mapear a função de reprodução de vídeo/FMV do jogo para poder pular todos os vídeos (logos/cutscenes) — só investigação por enquanto, sem patch cego.
- Próximo passo ao retomar: ler o handoff de 28/07, confirmar se o relink terminou e qual o novo Stable PC do boot probe.

## Checkpoint 2026-07-28 01:54 (relink confirmado, gate não mudou)

- **Gemini executou a Tarefa 1 do handoff e teve sucesso real** (verificado por mim, não só relatado): `mc3_partial.exe` relinkado às 01:05, `missing stub functions = 0` (antes eram 9), `15811` funções registradas, `168089` aliases de PC. Gemini ficou sem quota (`Individual quota reached`) logo depois, no meio do teste do `11_run_partial_runner.bat`.
- **Eu retomei e rodei o boot probe** (`15_auto_boot_probe.bat 8 payload1m3skip5a`) contra o exe novo. Resultado: **Stable PC continua `0x2b4488`** em `sub_002B4438_0x2b4438`, counters idênticos (`dma=2 gif=0 gsw=0 vif=3`). **O relink do batch_0015 não moveu o gate** — essas 8 funções não estavam no caminho crítico do boot atual, mas o relink ainda era necessário (mantinha o manifest/exe desatualizados).
- **Nota (corrigida):** não encontrei `handle=0xffffffff`/`texture.zip` no `work\logs\14_run_boot_trace.log` de hoje, mas confirmei a origem: veio de inspeção **live via PCSX2-MCP** no jogo real, registrada em `docs\SESSION_2026-07-10_PCXS2_MCP_SID44.md` (linhas 105-112) — não é alucinação nem doc-drift, é evidência real só que não aparece no trace do recomp porque o runner nativo trava em `0x2b4488` antes de alcançar esse ponto do fluxo. Válido para orientar a Tarefa 2, mas o vínculo causal entre `0x2b4488` (recomp) e a falha de `texture.zip` (live) ainda não foi provado — só ambos aparecem "perto" na linha do tempo do boot.
- Próximo passo ao retomar: Tarefa 2 do `docs\GEMINI_HANDOFF_2026-07-28.md` — investigar estaticamente `sub_004FAED8_0x4faed8`/`sub_004F9A68_0x4f9a68` e as flags `0x629f40/41/4c` no código gerado do recomp, e comparar com o provider real via PCSX2-MCP (`0x619f58`, `0x4f9760`, backend table `0x617fc0`) para confirmar se é o mesmo caminho. Tarefa 3 (skip de vídeo) segue pendente, ainda não investigada.

## Checkpoint 2026-07-29 (gate moveu; plano de 10 etapas + guarda de regressão)

- **Progresso real:** Stable PC saiu de `0x2b4488` e agora estabiliza em **`0x5a8908`** (`sub_005A8898_0x5a8898`, caller único `sub_004BD488`). O loop novo chama `func_398400` (backend open), `sub_003B14D0`, `sub_004F9A68` (provider) — confirma que o bloqueio atual É a frente provider/package. Counters seguem `dma=2 gif=0 gsw=0 vif=3`.
- Gemini produziu: `SEMA_17_INVESTIGATION_2026-07-28.md` (concluído: não injetar SignalSema(17), produtor é a própria `sub_005420C0`), `PLAN_PHASE_PROVIDER_2026-07-28.md` (gates A-D), `INVESTIGATION_BATCH_PLAN_2026-07-29.md` (PRD Ralph em `.agents\tasks\` — **ainda não executado**, `.ralph\progress.md` não existe).
- **Novo plano mestre operacional: `docs\PLAN_10_STEPS_2026-07-29.md`** — 10 etapas com teste de aceite cada, integrando os planos da Gemini + lane FMV + critério de vitória (`gif/gsw > 0`).
- **Nova automação:** `20_verify_boot_state.bat` + `tools\Verify-BootState.ps1` — guarda de regressão (exe não-stale, 0 stubs, classificação, PC esperado/progrediu, string de experimento no exe, check `real-render-traffic`). Baseline atual: `20_verify_boot_state.bat 0x5a8908` → PASS.
- Próximo passo ao retomar: etapas 2 e 3 do plano de 10 etapas (anatomia do loop `0x5a8908` + mapa de produtores de `0x629F44`) — só leitura, paralelizáveis via Gemini/Ralph.

## Checkpoint 2026-08-07 (AUDITORIA CRÍTICA — o probe não mede)

**Leia `docs\STATUS_2026-08-07_AUDIT.md` antes de qualquer coisa.**

- **Achado que muda tudo: o boot probe não é determinístico.** 5 corridas do mesmo binário, mesmo modo (`595`), mesma duração deram **5 Stable PCs distintos e 4 classificações distintas** (`unknown-loop`, `missing-function` x2, `render-started` x2). Uma corrida devolveu Stable PC `0x3` (endereço inválido) e ainda assim foi classificada `render-started`. Evidência: `work\boot_probe\repeat_baseline_20260807_20260807_013345.md`.
- **Consequência:** o critério "Stable PC mudou = progresso", usado como base de decisão dos lotes 13→21, estava medindo ruído. O estado `0x5a8908 / dma=2 vif=3` que os relatórios de 28/07 a 03/08 tratam como "o estado do projeto" é apenas **um dos cinco resultados possíveis** — reproduzi ele na run 5 de 5.
- **Não há vitória visual.** `gif=0 gsw=0` em 100% das corridas de hoje (11 no total). Nada foi renderizado.
- Gap de dispatch `0x42eb48` confirmado: `sub_0042EB08_0x42eb08.cpp` (regenerado 01/08) tem casos para `0x42EB24/28/2C/84/90/CC` mas **não** para `0x42EB48`. O patch manual de 17/06 cobria `0x42eb48` e `0x42eb90`; a regeneração apagou metade. Aparece como `first-bad-pc` em 100% das corridas. **Não é a causa da não-determinância** — é dívida separada.
- **Nova automação:** `21_probe_repeat.bat N modo label [ENV=V]` + `tools\Probe-Repeat.ps1` — roda N probes, agrega e declara se o Stable PC é utilizável como métrica. Use N≥5 em todo experimento a partir de agora.
- `20_verify_boot_state.bat` retorna **FAIL** hoje (classification=missing-function) — a guarda está funcionando corretamente.
- **Handoffs criados:**
  - `docs\HANDOFF_2026-08-07_A_DETERMINISM.md` — **bloqueador de tudo**, achar e eliminar a fonte de variação + corrigir o classificador.
  - `docs\HANDOFF_2026-08-07_B_DISPATCH_0x42EB48.md` — fechar o gap e impedir que regeneração apague patches manuais (paralelizável).
  - `docs\HANDOFF_2026-08-07_C_PROVIDER.md` — frente provider **travada** até A entregar; tarefas de leitura C1/C2 liberadas.
- Próximo passo ao retomar: Handoff A. Não abrir frente nova antes de fechar a medição.

## Checkpoint 2026-07-28 ~06:04 (Gemini — gate desbloqueado)

- **GATE MOVEU:** Stable PC saiu de `0x2b4488` → `0x2455f0` em `sub_00245568_0x245568`.
- **Causa-raiz confirmada (Tarefa 2):** O experimento `MC3_SIF_EXPERIMENT_REQ4_620D80_STATUS=1` **já existia** no modo `req4` do probe mas o último probe registrado tinha sido rodado com `payload1m3skip5a` (sem o `req4`). Ao rodar `15_auto_boot_probe.bat 8 595` com o modo `pollsid59c595ret2mode9payload1m3skip5areq4`, o request `0x4→0x620d80` passou a retornar `value=1` e o gate `0x2b4488` foi desbloqueado.
- **Análise da flag `0x619F40`:** Confirmado que é a flag de inicialização do provider de pacotes. Escrita por `FUN_004fa7a8_0x4fa7a8` (`sb $a0, -0x60C0($v1)`). Lida por `sub_004FAED8_0x4faed8` no boot do provider.
- **Tarefa 3 (vídeo/FMV):** Nenhum arquivo `.pss/.str/.mpg/.bik` visível no código gerado — confirma que vídeos estão dentro dos pacotes. `kMc3MovieCommitCallback = 0x00541348` e `kMc3MovieReplyCallback = 0x005413F0` são os callbacks de vídeo no `SIF.cpp`. Investigação mais detalhada pendente.
- **Novo gate:** `sub_00245568_0x245568` @ `0x2455f0` — loop `bne $v0, $s0` onde `$s0=2`, chamando `FUN_005420C0(1)` repetidamente. `FUN_005420C0` precisa retornar 2. Loop interno depois em `label_245608` chama `func_5424A8` esperando retorno == 1.
- **Próximo passo ao retomar:** Investigar `FUN_005420C0_0x5420c0` — o que ela verifica para retornar 2? É um estado de inicialização de sistema de áudio/render/subsistema? Comparar com PCSX2-MCP live. Depois olhar `func_5424A8` que é o segundo wait do mesmo boot step.

## Checkpoint 2026-08-01 (Investigação Etapas 2 e 3 Concluída)

### Continuidade do lote — 2026-08-01 06:09

- `sub_005420C0` observado retornando `0x6` no loop `0x2455f0`, que exige `0x2`.
- Experimentos env-gated `req4ret2` e `req4ret2ret1` avançaram pelos gates `0x245734` e `0x546d60`.
- Corrigido o dispatcher interno de `sub_0042EB08` para o retorno `0x42eb90`; batch `0036` e relink passaram com `0` stubs.
- Probe de `06:09:14–06:09:27` chegou a `0x5424c8` (`sub_005424A8`); verificação passou, mas `gif=0 gsw=0`.
- Detalhes e próximo comando: `docs\SESSION_2026-08-01_BATCH_CONTINUATION.md`.
- `06:10:15–06:10:28`: novo probe chegou a `0x238924` (`sub_002388F8`); verificação passou, `gif=0 gsw=0`.
- `06:12:58–06:13:18`: lote de 20s chegou a `0x5494e0` (`sub_00549488`); verificação passou. Trace mostra ciclo de `WaitSema` em `0x549640`, sem tráfego GIF/GS.
- `06:14:16–06:14:46`: repetição de 30s regressou a `0x245734`; verificação passou, mas os hacks env-gated ainda não são estáveis por timing.
- `06:18:59–06:19:13`: experimento `req4ret2ret1a8` avançou para `0x5419a0` (`FUN_00541968`); verificação passou. Gate agora aguarda `0x61fbb4` zerar.

- **Investigação da Etapa 2 (Anatomia do Loop `0x5a8908`):**
  - O spin-wait ocorre entre `0x5a8908` e `0x5a891c` (`b 0x5a8908`).
  - **Instrução/Branch decisivo de saída:** `0x5A88F0`: `beqz $v0, 0x5a8908`.
  - **Condição:** Exige que `func_4FA398` (`0x4FA398`) retorne `$v0 != 0`. Se retornar `0`, o fluxo entra em spin-wait perpétuo.
- **Investigação da Etapa 3 (Mapa de Globais do Provider):**
  - Mapeado o endereçamento MIPS real: base `0x00620000 - 0x60C0 = 0x00619F40` (e não `0x629F44`).
  - **Leitura:** `sub_004FAED8_0x4faed8` em `0x4faee8` (`lbu $v1, -0x60C0($v0)`). Aborta se `0x00619F40 == 0`.
  - **Escrita:** `FUN_004fa7a8_0x4fa7a8` em `0x4fa7b8` (`sb $a0, -0x60C0($v1)`).
- **Documentação gerada:** [LOOP_0x5A8908_ANATOMY.md](file:///e:/Emuladores/Sony/mc3recomp/docs/LOOP_0x5A8908_ANATOMY.md)

## Checkpoint 2026-08-02 07:46 BRT - ASSETS.DAT bridge batch 20

- The real `ASSETS.DAT` loader is linked into the final partial runner.
- Final runner: `work/link/partial/mc3_partial.exe`, timestamp `2026-08-02 07:45:55`, size `463806014` bytes.
- `libz.dll.a` is included at link time; `zlib1.dll` is beside the runner and imported by the executable.
- The missing-function manifest has only its header: zero missing stubs.
- The virtual adapter is restricted to `SLUS_213.55`, `MC3_ASSET_BRIDGE=1`, exact path `fonts/mcloadstrings.strtbl`, and DAT record type `0x000241FF`.
- Physical ABI corrected to `0x3984C0` open, `0x398610` close, `0x3986D8` seek, `0x398730` write, and `0x398788` read.
- Synthetic DAT, real DAT, virtual-handle, corrected-ABI, and fallback tests pass. Final full-suite retries exposed only existing VBlank/preemption timing flakes (`267/268`, `267/268`, `266/268`).
- Final 8-second baseline: stable PC `0x4F9760`, no asset markers, `dma=0 gif=0 gsw=0 vif=0`.
- Final 8-second bridge probe: stable PC `0x39923C`, no asset markers, `dma=0 gif=0 gsw=0 vif=0`.
- Retention and visual gates did not pass. The bridge remains disabled by default.
- Architecture correction: logical asset resolution is at `0x4F9760 -> 0x4FB0D8`; the physical file ABI is too low to observe the logical asset request first.
- Next exact step: instrument `0x4FB0D8`, capture bounded guest request data, and route only a proven exact `mcloadstrings` request into the existing loader.
- Full evidence: `docs/MC3_ASSET_BRIDGE_BATCH20_2026-08-02.md`.
- Rollback source snapshot: `work/checkpoints/assets_loader_20260802_072651`.

## Checkpoint 2026-08-03 16:48 BRT - logical resolver trace batch 21

- Added an MC3-only, env-gated, bounded trace wrapper for guest function `0x004FB0D8`.
- The wrapper preserves execution and calls the original exactly once; it does not connect DAT data or alter provider/semaphore state.
- Primary verification: `269/269` tests after one unrelated semaphore timing flake.
- Relinked runner: `work/link/partial/mc3_partial.exe`, timestamp `2026-08-03 16:45:43`, size `463827301` bytes, zero missing stubs.
- Baseline 8-second probe: stable PC `0x429C78`, `dma=2 gif=0 gsw=0 vif=3`.
- Trace 8-second probe: stable PC `0x4FAED8`, `dma=0 gif=0 gsw=0 vif=0`, 40 resolver entries.
- Real direct strings were provider extensions: `.tex`, `.xtex`, `.tga`, `.bmp`, `.ipu`, `.spr`.
- No `mcloadstrings`, `smallspace`, `fonts/`, `strtbl`, or `0x3CB70` appeared.
- Architecture correction: `0x4FB0D8` handles provider extension registration/selection, not the full logical asset filename.
- No visual victory: `gif=0` and `gsw=0`; no recomp frame yet.
- Next exact step: trace `0x4FAED8` plus the legitimate writer `0x4FA7A8` and prove why provider activation is unavailable before connecting any DAT asset.
- Full evidence: `docs/MC3_LOGICAL_RESOLVER_BATCH21_2026-08-03.md`.
- Rollback checkpoint: `work/checkpoints/logical_resolver_20260803_1630`.

## Checkpoint 2026-08-09 - encerramento do dia

- O experimento `opcode2B/host0:` foi rejeitado: ligado, deu `0/5` frames e travou mais cedo em `0x54A3xx/0x54A4xx`.
- O código e os testes experimentais foram removidos; build oficial e suíte `ps2x_tests` passaram.
- Um probe curto revelou que `work/link/partial/mc3_partial.exe` ainda é o binário antigo (`2026-08-09 02:18`, `463856802` bytes) e ainda contém o experimento.
- A tentativa de relink excedeu 120 segundos e não atualizou o executável. O runner foi encerrado; nenhum PCSX2 ficou aberto.
- Resultado visual honesto permanece: `gif=0`, `gsw=0`, nenhuma imagem do recomp.
- Próximo passo exato: concluir `10_link_partial_runner.bat fast`, confirmar novo timestamp e ausência de `MC3_EXPERIMENT_OPCODE2B_HOST0_RESPONSE` no binário, então rodar apenas um probe baseline curto com o gate ausente.
- O fluxo confiável de abertura/captura no PCSX2 está em `docs/PCSX2_MCP_LAUNCH_AND_CAPTURE_2026-08-09.md`.


## Checkpoint 2026-08-13 03:10 (binário limpo; bloqueio determinístico identificado)

**Mudança de ambiente:** o checkout mudou de `E:\Emuladores\Sony\mc3recomp` para `E:\Games\Emuladores\Sony\mc3recomp`. Docs e logs antigos (inclusive `latest_status.md` gerado antes de hoje) ainda citam o caminho velho. `cmake` NÃO está no PATH nem em Program Files/msys64 — bloqueia rebuild de runtime (não bloqueou hoje: a lib já estava limpa).

### 1. Binário stale purgado (bloqueio de 09/08 resolvido)

- O exe de `09/08 02:18` ainda continha o experimento rejeitado `MC3_EXPERIMENT_OPCODE2B_HOST0_RESPONSE` (2 ocorrências), enquanto `libps2_runtime.a` de `09/08 02:23` já estava limpa. O exe era **5 min mais antigo que a lib**.
- **Todo probe rodado entre 09/08 e hoje testou código experimental rejeitado. Essas medições não valem.**
- Relink concluído hoje: exe `13/08 03:01`, `463854922` bytes, experimento = **0 ocorrências**, `MC3_DISPATCH_BUDGET` presente.
- Causa do fracasso anterior: o link leva ~3 min (02:58→03:01) e a tentativa de 09/08 morreu num timeout de 120s.

### 2. Gate A2 (budget determinístico): calibrado, mas NÃO entrega determinismo

Aceite N=10 rodado pela primeira vez. Resultados:

| Budget | Falhas de evidência (marker=no/timeout) | Stable PCs distintos | Render |
|---|---|---|---|
| 100.000 | 5/10 | 7 | 0/10 |
| **25.000** | **0/10** | **4** | 0/10 |

- Budget **25.000 é o valor calibrado**: 10/10 corridas atingem o marcador sem timeout.
- **O budget resolve só a fronteira de amostragem, não o interleaving.** Ainda há 4 PCs distintos em 10 corridas. Menos divergência a 25k (4) que a 100k (7) confirma que a variação vem do racing acumulado entre threads reais do host, não da amostragem.
- Conclusão: determinismo real exige serializar a execução das threads guest — mudança arquitetural no runtime, não um ajuste de script. **A2 permanece FAIL.**
- Ganho real: o classificador novo pegou um `invalid-pc` (o antigo chamaria de `render-started`).

### 3. Bloqueio determinístico atual: semáforo de I/O de arquivo nunca sinalizado

Com binário limpo e budget 25k, 9/10 corridas param na mesma região e **todas** classificam `semaphore`:

- PC modal `0x54a0ac` (5/10) em `sub_0054A080_0x54a080`; demais: `0x54a188` (2), `0x54a3c4` (2), `0x3985d8` (1).
- Bloqueio: `WaitSema tid=3 sid=5`, emitido de `ra=0x398b28` → `sub_00398B18_0x398b18`.
- `sid=5` é criado em `ra=0x398a98` com `init=0 max=16` — semáforo de **completion**, criado pelo próprio módulo de I/O físico de arquivo (mesma vizinhança do ABI documentado: open `0x3984C0`, close `0x398610`, read `0x3986D8`, seek `0x398730`, stat `0x398788`).
- **`SignalSema` nunca ocorre para sid=5.** O trace registra 19 SignalSema, para sids 7, 8, 10, 16, 29, 37 e 40 — nenhum é o 5.

Leitura: o módulo de arquivo cria o semáforo de conclusão, emite a operação e espera. A conclusão nunca chega. Isso conecta a frente provider a um mecanismo concreto — não é "ponteiro global vazio", é **completion de I/O que o runtime não produz**.

**NÃO injetar `SignalSema(5)`.** Vale a regra estabelecida na investigação do sema 17: achar o produtor legítimo primeiro.

- Handoff: `docs\HANDOFF_2026-08-13_IO_COMPLETION_SID5.md`
- Próximo passo exato: identificar o produtor legítimo da conclusão de `sid=5` (ver handoff).

## Checkpoint 2026-08-17 (alpha 102404 com símbolos completos; novo plano mestre)

- **Achado que muda a estratégia:** o ISO do alpha de out/2004 (`MIDNIGHT CLUB 3 DUB PS2 ALPHA BUILD 102404\`) contém `MC.MAP` (linker map completo, ~19.250 símbolos C++ demanglados com endereço+tamanho+objeto de origem) e `MC.SYM`. Já extraídos junto com o ELF `SLUS_123.45`. Engine identificado: AGE (Angel Game Engine).
- Símbolos que batem direto nos bloqueios atuais: `coreFileWaitCreateSema`/`coreFileSignalSema` (o par do sid=5), `coreFileMethods` (o ABI físico 0x3984C0…), `datAssetManager*`/`zipFile` (a frente provider), `mcAudioRpcMgr`/`sndRpcManager` (lado cliente do RPC → SCREAM.IRX).
- **Decisão registrada: NÃO recomeçar o recomp do zero.** Os bloqueios provados são do runtime/processo (SIF hardcoded, scheduler não-determinístico, sem caminho até frame), não do código gerado.
- **Novo plano mestre: `docs\PLANO_2026-08-17_ALPHA_SYMBOLS.md`** — Fase 0: importar MC.MAP no Ghidra e diffar alpha→retail para nomear o boot path (fecha a Tarefa 1 do handoff sid=5 sem chute); Fase 1: reescrever a camada SIF como protocolo genérico (proibido novo `else if` por payloadAddr); Fase 2: scheduler cooperativo (determinismo); Fase 3: primeiro frame. Contingência: se o diffing casar mal, trocar o alvo do recomp para o ELF do alpha (símbolos completos).
- **Higiene urgente:** `.git\` está VAZIO — não há repositório nem versionamento. `git init` + `.gitignore` + commit inicial é o primeiro passo prático. `cmake` segue fora do PATH.
- Próximo passo ao retomar: Fase 0 do plano de 17/08 (script de import do MC.MAP + Version Tracking no Ghidra).

## Checkpoint 2026-08-17 (noite) — Fase 0 executada: 8.815 funções do retail nomeadas

- Repo público no ar: `github.com/cloudalister/mc3r` (docs+pipeline+tools, sem conteúdo do jogo) + fork `github.com/cloudalister/PS2Recomp` branch `mc3` (28 arquivos de runtime commitados). Roadmap de automação em `ROADMAP.md`.
- **`tools/port_symbols.py` (Python puro) casou alpha→retail: 8.815 pares (55,7% do retail)** — 6.695 por hash de bytes mascarados + 2.120 por propagação de callgraph. Saída: `work\exports\retail_symbol_port.csv`. Relatório: `docs\SYMBOL_PORT_REPORT.md`.
- **Todos os gates históricos têm nome agora.** O bloqueio do boot é a pilha SCE CDVD/FS sobre SIF RPC: `0x5422C8`=sceCdRead, `0x541968`=sceCdSync, `0x5424A8`=sceCdSeek, `0x5420C0`≈sceCdDiskReady (o "retorno 2" = SCECdComplete), `0x54A080`=sceFsInit (onde o boot para hoje), `0x549680`=sceSifCheckStatRpc. Protocolo público (ps2sdk/PCSX2), não proprietário.
- **Handoff sid=5 respondido:** `0x398A60`=ipcCreateSemaEx cria, `0x398B18`=ipcWaitSema espera, e o produtor legítimo é **`coreFileSignalSema` = retail `0x398450`**, acionado pela completion `coreRaw*` que o runtime nunca produz. Provider = `zipFile::` (`0x4F9760`=zipOpen, `0x4FB0D8`=Open, `0x4FAED8`=Locate).
- Consequência para a Fase 1: implementar semântica cdvdfsv/fileio padrão no runtime (referência: fonte do PCSX2 + ps2sdk), não reverse de protocolo. Os requests descartados (0x1/0xFF/0x9/0x22) são comandos cdvd padrão a confirmar contra o PCSX2.
- Pendente da Fase 0: import do MC.MAP no Ghidra (JDK 21 em instalação), nomes de dados/globais via MC.SYM, melhorias de matcher (vizinhança/sequência).
