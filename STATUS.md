# STATUS — fonte única de verdade (≤1 página, sobrescrever sempre)

Atualizado: **2026-09-03** — o jogo desenha, carrega assets e lê o controle. O que não anda é
a **máquina de estados** (M3).

## 📌 Ponto de parada (retomar daqui)

O boot chega até a **tela legal do frontend**, desenhada corretamente, e para ali.
Os cinco contadores de transição sobem para `3/1/3/2/3` nos primeiros segundos e **congelam por
38 mil ticks**, enquanto o render continua e o pad é lido 532 vezes.

- Foto do estado atual: `work/captures/frame_autostart_20260903.png`
- Entrada no frontend: `mcGameState::EnterStateMC3Frontend@0x1A5B08`, por volta do tick 6540
- Vocabulário da máquina de estados (tabela de nomes em `.rodata`, a partir de `0x497dfa`):
  `frontend`, `garage`, `mc3frontend`, `movie`, `race`, `race editor`

## Onde o projeto está, em 3 linhas

- A montanha gráfica **foi vencida**: `gifPk1≈606k`, `gsPrims≈1M`, `gsPixels≈1G`, imagem legível.
- A cadeia de input **fecha ponta a ponta**, inclusive headless (`MC3_PAD_AUTOSTART`).
- Falta o jogo **decidir trocar de tela** — é o único bloqueio entre hoje e uma tela nova.

## A escada, medida (detalhe em `docs/CAMINHO_ATE_O_FRAME.md`)

| M0 kernel | M1 IOP/SIF | M2 assets | M3 estados | M4 GIF | M5 GS | M6 present |
|---|---|---|---|---|---|---|
| ✅ | ✅ | ✅ | 🔨 **aqui** | ✅ | ✅ | ⚠️ PNG sai certo, **janela preta** |

## Fechado em 2026-09-03 (não reabrir)

1. **Trava pós-menu: inversão de ordem de travas.** `WaitSema` entrava `token → mutex`; o
   caminho de despertar fazia `mutex → token`. Capturada em log (tid=1 com `sema225->m`
   esperando o token; tid=8 com o token esperando esse mutex) e corrigida em seis pontos por
   `guestCvWaitReleasingToken`. Validada em 4 × 20 min sem reincidência.
   → `docs/RESULT_SEMA_PROBE_BLIND_2026-08-31.md` seções 30 e 31.
2. **Input em headless nunca existiu, e agora existe.** A janela headless é criada com
   `FLAG_WINDOW_HIDDEN`: ela nunca ganha foco, então nenhuma tecla chegava e
   `padmanStartPublishes` era 0 em toda bateria. `MC3_PAD_AUTOSTART` entrega START pelo mesmo
   latch do teclado. **227 STARTs entregues não moveram a tela** — a hipótese "só espera Start"
   está morta. → `docs/RESULT_PAD_AUTOSTART_2026-09-03.md`.
3. **`-skipintro` não existe neste retail.** Busca literal nos 5.264.872 bytes do ELF:
   `skipintro`/`qload`/`menuDebug` = 0 ocorrências. Vieram dos símbolos do alpha.
   Não construir o override de `0x614400` para eles. → `docs/RESULT_BOOT_ARGS_V1.md`, adendo.

## Próximos alvos, em ordem

1. **Tipo de pad (barato).** `ioPadStates=4,4,0,0` (`kPadTypeDigital`) contra
   `ioPadAttachPhases=7,7,0,0`. Verificar se o frontend exige DualShock e descarta pad digital.
2. **Máquina de estados do frontend (fundo).** O que a função de update espera para sair da
   tela legal. Ancorar pela tabela de nomes em `0x497dfa` e por `0x1A5B08`/`0x1A71C8`/`0x1A78E0`.
3. **Janela preta.** O despejo usa as mesmas duas chamadas da apresentação e sai correto;
   a janela não. Só bloqueia *ver* o jogo, não a investigação.
4. **Pausa de 35,9 s** vista na r4 da validação (recuperou sozinha, `gsPrims` plano nos ticks
   25380–25620). Item aberto, não urgente.

## Como medir

```bat
rem trava/retenção de token: 4 corridas de 20 min, captura em 30 s de retenção
powershell -File tools\Catch-WaitSemaPhase.ps1 -MaxRuns 4 -Seconds 1200 -Label <rotulo>

rem foto do que está na tela (dispara ao passar de <N> primitivas)
powershell -File work\scratch\Run-FrameDump.ps1 -Seconds 900 -Label <rotulo> -Headless -MinPrims 150000

rem entregar START sem janela com foco (período em ms; 30 s de atraso por padrão)
set "MC3_PAD_AUTOSTART=1500"
set "MC3_PAD_AUTOSTART_DELAY_MS=45000"
```

Rebuild do runtime + relink (≈2 min + ≈2 min):

```bat
work\scratch\build_runtime_watch.bat
10_link_partial_runner.bat fast
```

**Modo `595` está APOSENTADO para medição** (`docs/RESULT_FILEIO_GATE_V1.md`).

## Regras que não se negociam

1. Dispatch SIF por (servidor, fno) — `payloadAddr` nunca é chave.
2. Nunca injetar `SignalSema` — completion só pelo produtor legítimo.
3. Sem chute de bytes — decomp nomeado ou captura PCSX2; incerto = TODO + neutro.
4. Scheduler da Fase 2 congelado; sem env-gate experimental novo para *estado de jogo*
   (diagnóstico passivo atrás de env, como `MC3_PAD_AUTOSTART`, é permitido e deve deixar rastro).
5. Vitória visual = `gifPackets(total)>0` **e** `gsPrims>0` + framebuffer (`docs/RENDER_METRICS.md`).
6. Não linkar por cima de falha de compilação — `10_link_partial_runner.bat` aborta sozinho se
   `work/exports/parallel_compile_failures.log` não estiver vazio.

## Mapa de referência (o que ler para quê)

| Preciso de... | Doc |
|---|---|
| a escada de progresso e onde estamos | `docs/CAMINHO_ATE_O_FRAME.md` |
| a trava de travas e sua correção | `docs/RESULT_SEMA_PROBE_BLIND_2026-08-31.md` §30-31 |
| input em headless e o que ele provou | `docs/RESULT_PAD_AUTOSTART_2026-09-03.md` |
| boot args, layout do crt0 e por que `-skipintro` não serve | `docs/RESULT_BOOT_ARGS_V1.md` |
| o corredor de boot e os nomes de estado | `docs/RESULT_COPY_TO_FRONT_PIPELINE_2026-08-25.md` |
| o protocolo SIF e o que já responde | `docs/SIF_PROTOCOL.md` |
| nome de qualquer endereço do retail | `work/exports/retail_symbol_port.csv` + `docs/SYMBOL_PORT_REPORT.md` |
| código decompilado nomeado do SDK | `work/exports/alpha_decomp_sce.txt` |
| o que cada contador de render mede | `docs/RENDER_METRICS.md` |
| como operar o loop de trabalho | `docs/WORKFLOW.md` |
| histórico completo (append-only, não é entrada) | `PS2_PROJECT_STATE.md` |

## Ambiente (fixo desta máquina)

JDK: `jdk-21.0.12+8\` (JAVA_HOME p/ Ghidra headless) · CMake: VS2022
`Common7\...\CMake\CMake\bin` · Ninja: VS2022 `Common7\...\CMake\Ninja` · g++:
`C:\msys64\ucrt64\bin` · build dir: `PS2Recomp\out\build` · relink ~2-3 min (timeout ≥6 min) ·
suíte roda de `PS2Recomp\out\build`.
Repos: `github.com/cloudalister/mc3r` + fork `github.com/cloudalister/PS2Recomp` branch `mc3`.
