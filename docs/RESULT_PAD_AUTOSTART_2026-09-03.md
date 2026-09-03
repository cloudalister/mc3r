# Resultado: START entregue ao convidado em headless — e a tela legal não responde

Data: 2026-09-03

## Resultado

A corrente de input está **fechada ponta a ponta em headless**: 227 STARTs publicados, lidos
pelo convidado, e a tela legal do frontend **não avançou**. A hipótese "a tela só espera alguém
apertar Start" está morta com evidência, não por palpite.

## O que faltava, e por quê

Em headless a janela é criada com `FLAG_WINDOW_HIDDEN` (`ps2_runtime.cpp:1248`). Ela existe, e
por isso `IsWindowReady()` é verdadeiro e `latchPadHostInputEvents()` roda todo quadro — mas a
janela nunca recebe foco, então `IsKeyPressed(KEY_ENTER)` nunca vê nada. Nenhuma corrida headless
jamais teve como entregar um botão. Isso não estava registrado em lugar nenhum e explica por que
`padmanStartPublishes` ficava em 0 em todas as baterias.

## `MC3_PAD_AUTOSTART`

`PS2Recomp/ps2xRuntime/src/lib/Kernel/Stubs/Pad.cpp` ganhou um disparo sintético que entra pelo
**mesmo** `g_latchedHostButtons` que o Enter do teclado alimenta. Não inventa estado de
convidado, não mexe em escalonador, semáforo ou RPC.

| variável | efeito |
|---|---|
| `MC3_PAD_AUTOSTART` | período em ms entre toques (`1` vale 1500 ms; ausente ou `0` desliga) |
| `MC3_PAD_AUTOSTART_DELAY_MS` | atraso do primeiro toque, padrão 30000 ms |

Cada disparo deixa `[boot-trace:mc3-pad-autostart]` no log. Como `samplePadInputPacket` consome
um latch por pacote, cada disparo vira naturalmente um toque de um quadro.

## Medição

Corrida `probe_autostart_20260903`, headless, 900 s, toque a cada 1500 ms a partir dos 45 s.

```text
[boot-trace:mc3-padman-input] port=0 frame=22 buttons=0xfff7 start=1
```

`0xfff7` é o bit 3 zerado — START em lógica invertida, como o retail espera.

| medição | valor final |
|---|---:|
| STARTs publicados (`padmanStartPublishes`) | 227 |
| `guestPadReadCalls` / `ioPadPollCalls` | 532 / 532 |
| `ioPadUpdateCalls` / `ioPadAttachCalls` | 534 / 534 |
| `uiInputUpdateCalls` / `ioInputUpdateCalls` | 27 / 9 |
| tick final | 38.280 |
| `gsPrims` final | 817.965 |
| `enterMovie/enterFrontend/setMovie/setFrontend/layerTransition` | 3 / 1 / 3 / 2 / 3 |

A corrida passou muito além do tick ~6540 em que
`docs/RESULT_COPY_TO_FRONT_PIPELINE_2026-08-25.md` registra a entrada em
`mcGameState::EnterStateMC3Frontend@0x1A5B08`. Ou seja, **os 227 toques caíram com o frontend já
no ar**, não durante os filmes.

Os cinco contadores de transição não se moveram um dígito, e o despejo de quadro
(`work/captures/frame_autostart_20260903.png`) é pixel a pixel a mesma tela legal da corrida sem
input.

## Leitura honesta

O convidado recebe o botão e não reage. Isso derruba a explicação mais simples e reposiciona o
alvo: o frontend está no ar, lê o pad 532 vezes, chama `ioInputUpdate` 9 vezes — e sua máquina de
estados não avança. O que trava não é a falta de input.

Uma observação para quem pegar isto: `ioPadStates` fica em `4,4,0,0` enquanto
`ioPadAttachPhases` marca `7,7,0,0`. O estado 4 é `kPadTypeDigital`; a fase 7 é a que
`ioPad::Update@0x238808` exige para entrar no poll — e o poll de fato roda. Vale conferir se o
frontend exige DualShock (tipo 7) e descarta um pad digital.

## Próximas frentes

1. Por que a máquina de estados do frontend não avança com o pad lido e o input entregue.
2. A hipótese do tipo de pad acima — é barata de testar.
3. Argumentos de boot `-skipintro`/`-garage`
   (`docs/HANDOFF_2026-08-29_BOOT_ARGS_SKIPINTRO_GARAGE.md`), que contornam o frontend inteiro
   pelo atalho que a própria Rockstar deixou.
