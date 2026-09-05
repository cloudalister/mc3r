# STATUS — fonte única de verdade (≤1 página, sobrescrever sempre)

Atualizado: **2026-09-05, auditoria Codex** — o jogo desenha e o frontend progride muito
devagar. **10,4 s é VIF acumulado dividido por voltas, não duração total de quadro.**
O diagnóstico de causa única ainda não está demonstrado. Ver
`docs/RESULT_RENDER_AUDIT_2026-09-05.md` para correções e próximo experimento.

## 📌 Ponto de parada (retomar daqui)

O boot chega à **tela legal do frontend**, desenhada corretamente, e fica nela.
Há progresso lento de animação. As hipóteses de input abaixo já foram investigadas;
isso não elimina todo possível defeito nem fecha a contabilidade de tempo.

**A conta ainda incompleta** (corrida de 900 s, `probe_isocache_20260905`):

- O histórico reporta **13 voltas em 900 s (15 minutos)**. Inclui boot, portanto
  nem 900/13 é uma medição de quadro em regime estável.
- `vifMs` = 134,9 s ÷ 13 voltas = **10,4 s de VIF por volta**, usando totais da corrida.
  Isso não explica os 900 s. A identidade inversa 13 × 10,4 não prova causalidade.
- A animação de câmera do frontend **avança** (`fe6AC` percorre 0, 6, 8, 15, 21, 23) e precisa de
  muitos quadros para terminar. Não foi observada sua conclusão nas corridas citadas.

Despacho de estado, para orientação: tabela de saltos em `0x638120`, indexada por
`mcGameState->state` (campo `+0x04`). Estado 7 = `mc3frontend` → braço `0x1A2718` → `func_1A32B0`.
Medimos `gsState=7`, então cada volta chama a árvore do frontend exatamente uma vez.

- Foto do estado atual: `work/captures/frame_autostart_20260903.png`
- Vocabulário dos estados (`.rodata` a partir de `0x497dfa`): `frontend`, `garage`,
  `mc3frontend`, `movie`, `race`, `race editor`

## Onde o projeto está, em 3 linhas

- A montanha gráfica **foi vencida**: imagem legível, `gsPrims≈1M`, `gsPixels≈1G`.
- Há correções e hipóteses eliminadas em kernel, IOP, assets e input; isso não prova ausência de defeitos.
- Há custo gráfico alto. ~68 mil primitivas por volta é uma razão entre totais, ainda sem
  delimitar quadros reais. Prioridade: fechar a medição e testar desperdícios concretos.

## A escada, medida (detalhe em `docs/CAMINHO_ATE_O_FRAME.md`)

| M0 kernel | M1 IOP/SIF | M2 assets | M3 estados | M4 GIF | M5 GS | M6 present |
|---|---|---|---|---|---|---|
| ✅ | ✅ | ✅ | 🔨 **aqui** | ✅ | ✅ | ⚠️ PNG sai certo, **janela preta** |

## Modelo de custo do quadro (a base de qualquer otimização)

Réguas de fase são **inclusivas** (`vifMs` contém `vu1Ms`, que contém o raster do XGKICK); as
subtrações exigem o mesmo caminho e janela. `rasterMs` global inclui outros PATHs, então
`vu1Ms-rasterMs` não isola GIF/GS. Os pesos abaixo são o modelo histórico, ainda não
uma partição demonstrada de quadro real; **variam com a cena**.

| fatia exclusiva | corrida do frontend | corrida mais cedo |
|---|---:|---:|
| rasterizador | 56% do quadro | 12% |
| VU1 fora do raster | 23% | — |
| VIF1 fora do VU1 | 21% | — |

Custos unitários, que se repetem nas duas: **~30-86 µs por primitiva**, **~60-106 ns por pixel**,
**~120 mil chutes de VU1 por corrida**. O interpretador do VU1 em si é barato (88 ciclos por
chute); o caro é o caminho **GIF/GS entre o XGKICK e o `drawPrimitive`** (~152 µs por chute).

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

## Fechado em 2026-09-04/05 (não reabrir)

4. **A árvore do frontend roda 18 vezes em 20 min** — e é consequência do custo por quadro, não
   causa. `gsState=7`, fila de comandos vazia, `mc3FeView` existe e sua animação avança.
   → `docs/RESULT_M3_TITLE_EXIT_2026-09-04.md` seções 4-5.
5. **Bug real corrigido: varredura de debug sem gate no árbitro do GIF.** `submit()` e `drain()`
   varriam o pacote inteiro duas vezes cada, atrás de valores mágicos, sem ninguém ler — quatro
   varreduras por pacote, 120 a 350 mil pacotes por corrida. O gate (`MC3_COPY_ARB_SUBMIT` /
   `MC3_COPY_ARB_DRAIN`) estava previsto e faltando. → seção 15.
6. **A bancada de medição não resolve menos de ~16%.** Tempo fixo e orçamento fixo dão 23-55% de
   dispersão com o mesmo binário. O que funciona é **janela de trabalho** (diferença entre dois
   marcos de `gsPrims`), implementada em `tools/Measure-RenderCost.ps1`. → seções 17-18.

## Aberto em 2026-09-05 (a pista mais quente)

**`fe6AC` cicla, nao converge.** `mc3FeView::CanTransition@0x3224F8` exige
`(s32)this+0x6AC < 0`. Numa corrida de 30 min (`probe_longcook_20260905`, 31 voltas da arvore do
frontend) o campo sobe ate 39, volta a 0 e recomeca — **nunca fica negativo**, e as transicoes
seguem em `3/1/3/2/3`. Rodar mais tempo nao termina a animacao.

`0x6AC` recebe `-1` em dois pontos de `mc3FeView::Update@0x322668` (`0x3226d8`, com
`this+0x680[this+0x6B0]` nulo; `0x322ca4`, fim da animacao de camera). **Proxima medicao:
instrumentar as escritas nesse campo (valor + PC de origem) numa corrida curta** — isso nomeia
quem reinicia o ciclo, em uma medicao so. → `docs/RESULT_M3_TITLE_EXIT_2026-09-04.md` secao 19.

## Próximos alvos, em ordem

0. **Fechar tempo por volta real**, separando parede, VIF e espera/execução do convidado.
   Não alterar scheduler. Há outra varredura de debug sem gate em
   `GS::processGIFPacket` (`ps2_gs_gpu.cpp`); preparar A/B isolado conforme auditoria.
1. **Refazer a medição do gate da seção 15** com `Measure-RenderCost.ps1`. O ganho anunciado
   (3,5x) veio do método ruim; o conserto se justifica pelo mecanismo, mas o número precisa ser
   refeito antes de ser citado.
2. **Caminho GIF/GS entre o XGKICK e o `drawPrimitive`** (~152 µs por chute). Maior item dentro
   do escopo do VU1 e o **menos investigado** — só foi aberto em 05/09.
3. **Rasterizador** (~60-106 ns por pixel). Uma a duas ordens de grandeza de folga em relação ao
   que a técnica permite. Maior fatia na tela do frontend.
4. **VIF1 fora do VU1.** Já respondeu a uma otimização em 30/08 (queda de 59%), então há
   precedente de que o estágio rende.
5. **Janela preta.** O despejo em PNG sai correto e a janela não. Só bloqueia *ver* o jogo.
6. **Pausa de 35,9 s** vista na validação de 03/09 (recuperou sozinha). Aberto, não urgente.

**Regra de trabalho para performance:** nenhuma otimização entra sem passar pelo
`Measure-RenderCost.ps1`, três corridas por binário, aceitando só o que exceder a dispersão que
o próprio script imprime.

## Becos sem saída fechados em 2026-09-03 (não repetir)

| hipótese | como morreu |
|---|---|
| "a tela só espera alguém apertar Start" | 227 STARTs de toque e 272 de botão **segurado**, entregues com o frontend no ar. Zero transições. |
| "o frontend recusa pad digital" | O `7` que libera o poll é o retorno do `ioPad::Attach`, não o campo `0x174`. `ioPadPollCalls=532`: o portão já estava aberto. |
| "o jogo é só lento, a corrida é que era curta" | 45 min, tick 67.431: `uiInputUpdate` sobe linearmente, transições imóveis. A taxa é constante, não acelera. |
| "a RAM baixa do runtime difere do console e fecha o portão" | `gateByte=0` em todas as amostras. Além disso o fluxo nem chega no byte. |
| "o laço principal não lê o pad porque falta o objeto de `0x617BCC`" | Verdade para **aquele** bloco, que é específico do intro: `EnterStateMC3Frontend@0x1A5B08` não chama `sub_00364720` nem nenhum criador de camada. O frontend tem caminho de input próprio, e ele roda. |
| "`-skipintro` pula a abertura" | As palavras não existem neste ELF (busca literal em 5.264.872 bytes). |
| "ninguém está registrado para consumir o input" | A tabela de callbacks em `0x715D28` é BSS e é no-op **no console também**: zero escritores no corpus, zero no `.data`. |
| "o `ipcSleep` da netManagerThread volta cedo e ela gira à toa" | 9 chamadas de `DelayThread` por segundo no processo inteiro, e `delayThreadCalls == setTimerAlarmCalls` em toda amostra. |
| "o microprograma do VU1 corre até o teto de ciclos" | 88,2 ciclos por chute e **zero** estouros de orçamento em 92.140 chutes. |
| "o nosso VIF1 decodifica MSCAL a mais" | `MSCAL` é 9,1% dos comandos decodificados e `UNPACK` 27,5% — mistura de fluxo real. O jogo chuta mesmo uma vez por primitiva. |
| "reaproveitar os buffers do árbitro do GIF" | Sem ganho medido; piorou dentro do ruído. Revertido. → seção 16. |

## Como medir

```bat
rem trava/retenção de token: 4 corridas de 20 min, captura em 30 s de retenção
powershell -File tools\Catch-WaitSemaPhase.ps1 -MaxRuns 4 -Seconds 1200 -Label <rotulo>

rem foto do que está na tela (dispara ao passar de <N> primitivas)
powershell -File work\scratch\Run-FrameDump.ps1 -Seconds 900 -Label <rotulo> -Headless -MinPrims 150000

rem custo de render com dispersao medida (SEMPRE use isto para A/B de performance)
powershell -File tools\Measure-RenderCost.ps1 -Label <rotulo> -Reps 3
rem   piso de ruido medido em 2026-09-05: ~16% nas reguas de raster.
rem   So aceite ganho que exceda a dispersao que o proprio script imprime.

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
