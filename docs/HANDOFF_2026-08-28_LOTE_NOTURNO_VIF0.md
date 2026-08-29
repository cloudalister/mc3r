# Handoff — Lote noturno autônomo: canal DMA 0 (VIF0)

**Janela**: início imediato → **desligamento às 03:00 de 2026-08-28**.
**Modo**: auto-planejamento e auto-aprovação dentro do envelope da seção
"Envelope de autonomia". O humano está dormindo — não existe ninguém para
responder pergunta. Dúvida fora do envelope = parar, documentar, seguir para a
fase de encerramento.

---

## Contexto mínimo

Estado provado na sessão de 2026-08-28 01:00–01:40 (duas corridas headless):

- `0x5B92E0` está atravessado. Corrida de 1800 s com **zero** funções ausentes.
- A tela legal termina naturalmente e o frontend avança: worker legal sinaliza,
  thread 7 sai, thread 8 nasce, `datStreamer::Close` completa corretamente.
- **PC estável atual: `0x3A01C8`**, dentro de `sub_003A0130_0x3a0130`
  (batch_0028). Estável do tick ~36300 até 66360.

Leituras obrigatórias (só estas):

1. `PS2_PROJECT_STATE.md` — os dois últimos checkpoints de 2026-08-28.
2. `PS2Recomp/ps2xRuntime/src/lib/ps2_memory.cpp` — função `writeIORegister`,
   faixa `0x10008000..0x1000F000` (começa na linha ~915) e o bloco de conclusão
   de GIF/VIF1 (linhas ~1478-1510).
3. `PS2-Programming-Docs/` — capítulo do DMAC (canal 0 / VIF0) e do VIF.

---

## O bloqueio, em código

`sub_003A0130` monta e dispara uma transferência DMA no **canal 0 (VIF0)** e
espera a conclusão:

```
0x3A0180  v1 = 0x005F29D0                  ; endereço fonte
0x3A0188  a1 = lhu [0x005F29C0]            ; quantidade de quadwords
0x3A0190  sw v1 -> 0x10008010              ; D0_MADR
0x3A0198  sw a1 -> 0x10008020              ; D0_QWC
0x3A01A8  sw 0x100 -> 0x10008000           ; D0_CHCR: STR=1, MOD=0 (normal), DIR=0
0x3A01C8  lw  $v0, 0($v1)                  ; $v1 = 0x10008000
0x3A01CC  andi $v0, 0x100
0x3A01DC  bnez $v0, 0x3A01C8               ; while (D0_CHCR & STR)
```

**O caso observado é o mais simples possível**: modo normal (`MOD=0`), sem
DMAtag, sem chain, `CHCR = 0x100`.

Causa provada no runtime, em `ps2_memory.cpp`:

- `writeIORegister` intercepta o start de DMA para toda a faixa
  `0x10008000..0x1000F000`, mas só existe caminho de conclusão para:
  - `0x1000D000` (fromSPR) — limpa STR na linha ~982
  - `0x1000A000` (GIF) — limpa STR na linha ~1500
  - `0x10009000` (VIF1) — limpa STR na linha ~1506
- **Não existe `VIF0_CHANNEL` no arquivo.** O canal 0 escreve STR=1 e nada nunca
  limpa. Daí o laço infinito.
- Complemento: os **registradores** do VIF0 (`0x10003800..0x100039FF`) também são
  stub — a linha ~909 só incrementa `m_vifWriteCount` e retorna `true`. Os do
  VIF1 (`0x10003C00+`) são modelados de verdade.

---

## Escopo

### Fazer

Implementar o **canal DMA 0 (VIF0)** com semântica fiel de hardware, no mínimo
para o modo normal:

1. Ler `D0_MADR` (`0x10008010`) e `D0_QWC` (`0x10008020`).
2. Consumir as `QWC` quadwords a partir de `MADR` (transferência real, não
   descarte cego — os bytes devem ser lidos e entregues a um destino explícito:
   FIFO/buffer do VIF0 no runtime).
3. Avançar `MADR` em `QWC * 16`, zerar `D0_QWC`.
4. Limpar o bit STR (`0x100`) de `D0_CHCR`.
5. Levantar o bit do canal 0 em `D_STAT` (`0x1000E010`), com a mesma lógica de
   máscara/bit 31 já usada por `raiseDStatChannel`.
6. Modo chain (`MOD=1`): implementar se o tempo permitir; se não, tratar de forma
   **neutra e explícita** — não completar, logar `[boot-trace:dmac-vif0-chain-todo]`
   com `tadr`, e registrar como pendência no RESULT. Nunca fingir conclusão de um
   modo que não foi implementado.
7. Adicionar trace passivo `[boot-trace:dmac-vif0]` com `madr`, `qwc`, `chcr` e os
   **primeiros 2 quadwords** do pacote (hex), limitado a 32 ocorrências. Isso é o
   insumo para o próximo lote descobrir se o pacote é MPG (upload de
   microprograma VU0) ou UNPACK.

### NÃO fazer

- **NÃO** limpar STR sem consumir os dados. Isso é gate semântico e está proibido.
- **NÃO** implementar interpretação de comandos VIF0 nem VU0 nesta tarefa. O
  destino pode ser um buffer/FIFO com TODO documentado. Interpretar VIFcode é
  outro lote.
- **NÃO** tocar em scheduler, dispatcher, SIF, ou no caminho VIF1/GIF que já
  funciona.
- **NÃO** criar env-gate novo. Nada de `MC3_EXPERIMENT_*`.
- **NÃO** atacar as 5 regiões não analisadas (`0x501208`, `0x5C5718`, `0x5CCCA8`,
  `0x5CCD28/30/38`, `0x5CCE60/68`). Ficam para o próximo lote — exigem criação de
  função no Ghidra e não cabem nesta janela.
- **NÃO** fazer corrida com janela visível. Headless sempre. A corrida com
  `Enter` exige humano acordado e está fora desta janela.
- **NÃO** abrir PCSX2.
- **NÃO** dar `git push`. Commits locais apenas.

---

## Fontes de verdade (em ordem)

1. Decomp/symbol port do jogo e o disassembly gerado em `work/generated/ghidra/`.
2. Trace real das corridas desta noite
   (`work/logs/gfx_probe_20260828_stream1.log.stderr`).
3. `PS2-Programming-Docs/` (DMAC/VIF) — referência de hardware.

Proibido inventar comportamento que não esteja em 1-3.

---

## Regras não-negociáveis

1. Dispatch SIF por (servidor, fno) — `payloadAddr` nunca é chave.
2. Nunca injetar `SignalSema` — conclusão só pelo produtor legítimo.
3. Sem chute de bytes — decomp nomeado ou captura; incerto = TODO + neutro.
4. Sem env-gate experimental novo; scheduler da Fase 2 congelado.
5. Vitória visual = `gifPackets(total) > 0` **e** `gsPrims > 0` + framebuffer.
   Nada além disso conta como imagem.
6. Exe relinkado tem que ser mais novo que a lib — conferir timestamp antes de
   medir.

---

## Ambiente (fixo desta máquina)

```
g++/toolchain:  C:\msys64\ucrt64\bin        (prefixar no PATH antes de compilar)
cmake:          C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe
build dir:      PS2Recomp\out\build
suíte:          PS2Recomp\out\build\ps2xTest\ps2x_tests.exe   (CWD = PS2Recomp\out\build)
relink:         ~3 min  → timeout ≥ 6 min, sempre
```

Comandos exatos:

```bat
work\scratch\build_runtime_watch.bat
```

```bat
10_link_partial_runner.bat fast
```

```bat
work\scratch\run_gfx_probe.bat 900 20260828_vif0 headless
```

---

## Desvio de medição (intencional e declarado)

`STATUS.md` exige `MC3_DETERMINISTIC=1` + `MC3_DISPATCH_BUDGET=25000` em toda
medição. **Este lote não usa isso**, e a razão precisa constar no RESULT: a tela
legal consome ~490 iterações de script e o frontend só é alcançado por volta do
tick 33000, muito além de qualquer budget de 25000 dispatches. A medição desta
janela é a corrida longa wall-clock headless, igual às duas corridas de hoje.
Isso é comparabilidade com as corridas de hoje, não abandono da regra.

---

## Cronograma com portões duros (relógio, não progresso)

O relógio manda. Se um portão estourar, **abandonar a fase e ir para o
encerramento** — não estender, não "só mais uma tentativa".

| Horário | Portão |
|---|---|
| até **02:15** | VIF0 implementado, `build_runtime_watch.bat` verde, suíte de testes verde. Se falhar → `git checkout` das mudanças do runtime, documentar e pular direto para 02:45. |
| até **02:25** | `10_link_partial_runner.bat fast` concluído, exe mais novo que a lib, manifesto de stubs só com cabeçalho. |
| **02:25** | Disparar `run_gfx_probe.bat 900 20260828_vif0 headless`. Poll ativo a cada 60 s. |
| até **02:45** | Probe encerrado e log analisado. |
| 02:45 – 02:57 | Escrever `docs/RESULT_VIF0_DMA_2026-08-28.md` + commits locais. |
| **02:58** | Verificação final de encerramento. |
| **03:00** | Desligar o PC. |

**Poll ativo obrigatório**: em toda espera longa (build, relink, probe), rodar
loop de checagem a cada ~60 s até terminar. Nunca pausar "esperando notificação".

---

## Envelope de autonomia (o que pode sem perguntar)

**Pode**: editar `ps2_memory.cpp` e outros fontes do runtime dentro do escopo;
compilar; rodar a suíte; relinkar; rodar probes headless; ler e filtrar logs;
criar arquivos em `work/scratch/` e `docs/`; fazer commits locais; reverter as
próprias mudanças.

**Não pode**: `git push`; apagar logs, capturas ou artefatos existentes; editar
histórico de `PS2_PROJECT_STATE.md` (só append); tocar na ISO ou em
`extracted_iso/`; abrir emulador; instalar dependência nova; mudar
scheduler/dispatcher/SIF; criar env-gate.

Fora do envelope = parar, escrever no RESULT o que faria e por quê, seguir para o
encerramento.

---

## Aceite

Frase binária: **o PC estável determinístico deixa de ser `0x3A01C8` e o laço
`while (D0_CHCR & 0x100)` não reaparece no trace.**

Resultado negativo também é entregável: se o PC continuar em `0x3A01C8`, o RESULT
deve trazer a cadeia exata (valor de `D0_CHCR` lido, se o trace `dmac-vif0`
disparou, o que o pacote continha).

---

## Critérios de parada

- **Vitória do passo**: o aceite acima.
- **Vitória maior inesperada**: se `gifPk*` e `gsPrims` voltarem a crescer depois
  do teardown da tela legal, ou se qualquer trace `mc3-gfx-*` disparar — parar
  tudo imediatamente, salvar o log, documentar o estado exato. Isso seria a
  primeira evidência de modelo sendo carregado/desenhado e não pode ser perdida.
- **Portão de relógio estourado**: encerrar a fase, documentar.
- **Suíte de testes vermelha**: reverter a mudança do runtime, documentar. Não
  seguir para relink com suíte quebrada.

---

## Entregáveis

1. `docs/RESULT_VIF0_DMA_2026-08-28.md` — honesto, inclusive negativo. Deve
   conter: o que foi implementado, diff resumido, saída da suíte, PC estável
   antes/depois, contadores de render antes/depois, os traces `dmac-vif0`
   coletados, pendências explícitas (modo chain, interpretação VIFcode, VU0).
2. Commits locais pequenos no fork branch `mc3`, mensagem de uma linha. **Sem push.**
3. Um bloco appendado em `PS2_PROJECT_STATE.md` no formato dos checkpoints
   existentes.
4. `STATUS.md` **não** deve ser sobrescrito — quem faz isso é o coordenador com o
   humano acordado.

---

## Encerramento e desligamento (03:00)

Às 02:58, verificar e registrar em `work/logs/lote_noturno_20260828.log`:

- [ ] `docs/RESULT_VIF0_DMA_2026-08-28.md` existe e não está vazio
- [ ] checkpoint appendado em `PS2_PROJECT_STATE.md`
- [ ] `git status` limpo ou com commits locais feitos (nada perdido)
- [ ] nenhum processo `mc3_partial.exe` rodando
- [ ] nenhum build/link em andamento (`ld.exe`, `g++.exe`, `cmake.exe`)

Se algum processo ainda estiver rodando, encerrar antes de desligar:

```powershell
Get-Process mc3_partial, ld, cmake -ErrorAction SilentlyContinue | Stop-Process -Force
```

Desligar às 03:00, com o comando exato:

```powershell
Stop-Computer -Force
```

**O desligamento não pode ser adiado.** Se às 02:58 uma fase estiver incompleta,
ela fica incompleta: documentar o ponto exato de parada no RESULT e desligar
mesmo assim. Trabalho perdido é recuperável; a máquina ligada a noite toda sem
supervisão não é o combinado.

---

## Próximo lote (não fazer hoje — só registrar)

1. **5 regiões não analisadas**: `0x501208` (184 hits), `0x5C5718` (45),
   `0x5CCCA8` (8), `0x5CCD28/30/38` (17), `0x5CCE60/68` (3). Todas caem em vãos
   entre funções recompiladas — exigem criação de função no Ghidra e geração, não
   resume case. São corpos de método virtual chamados via `jalr $v0` a partir do
   sistema de propriedades da UI (vtable `0x6327F8`).
2. **Interpretação de VIFcode do VIF0 + VU0**, guiada pelo conteúdo do pacote que
   o trace `dmac-vif0` capturar hoje.
3. **Corrida com janela visível** para pressionar `Start` — exige humano.
   Headless cria janela com `FLAG_WINDOW_HIDDEN` (`ps2_runtime.cpp:1001`) e o pad
   é lido por `IsKeyDown` (`Kernel/Stubs/Pad.cpp:160`), então janela oculta nunca
   recebe foco.
