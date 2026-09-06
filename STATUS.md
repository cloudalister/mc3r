# STATUS — fonte única de verdade (≤1 página, sobrescrever sempre)

Atualizado: **2026-09-06, 07:29, latencia separada (Astra)**.
323/323 testes. Rodada601s:34 esperas curtas completas somaram9,147s,
8,070s recuperando permissao de executar; pior caso769ms nessa etapa.
Espera inicial272s foi ANTES do sinal (token apenas0,206ms).
Bloqueio final: alarme0703e019/SID22 armado, sem callback observado por122,5s.
Proximo: rastrear fila/worker/token ANTES da entrada desse callback.
Nao mudar scheduler nem forcar sinal. Apenas2 writes iniciais,42b150 nao usada;
sem menu/FPS aceitos. Processo encerrado. Ver docs/RESULT_SEMA_LATENCY_2026-09-06.md.

Checkpoint anterior07:04:
Sonda focada:9/9 alarmes sinalizaram e acordaram. Pedidos10ms levaram57..739ms,
ate477ms DEPOIS do retorno da sinalizacao. Isso nao prova causa no scheduler:
somam3,302s, separados da espera inicial347,6s. Travamento218s nao reproduzido.
322 testes gerais +teste da sonda passaram. Rodada601s:42b150 usada85vezes,
5 recoveries restantes (5bb238/5bb268), animacao14. Sem menu/FPS aceitos.
Proximo: medir sinal->retomada/token e investigar separadamente espera inicial.
Sem mudanca de comportamento do jogo; processo encerrado. Ver
`docs/RESULT_TIMER_WAIT_2026-09-06.md`.

Checkpoint anterior06:23:
322/322 gerais +37 casos nativos passaram, incluindo24 comparacoes com ELF e
dois caminhos42bf00->42b150. Runtime3fb78c5; exe atualizado e medido por601s.
Esta rodada NAO chamou42b150 (contador0): ficou antes da animacao, aguardando
SID21/RA5476b0 por218,8s no ultimo registro. Zero bad nao prova cadeia corrigida.
Sem menu/FPS aceitos; processo encerrado. Proximo: MC3_TIMER2_TRACE existente,
correlacionar criacao/entrega do alarme com sinal do semaforo; nao forcar sinal.
Ver `docs/RESULT_LIST_ENTRY_2026-09-06.md`.

Checkpoint anterior05:57:
Quatro retornos exatos e tres entradas para corpos ja gerados reconectados.
322/322 testes gerais +11 casos dos objetos reais passaram. Rodada601s:
zero avisos dos sete destinos; quatro retornos usados12 vezes cada; animacao17.
Ainda256 recoveries impressos (limite). Primeiro novo alvo42b150, chamado de
42bf00; depois5bb238/5bb268. Sem menu ou ganhoFPS comprovado; jogo encerrado.
Proximo: restaurar42b150 conforme ELF e testar ramo nao vazio de42bf00.
Ver `docs/RESULT_ENTRY_BATCH_2026-09-06.md`.

Checkpoint anterior04:50:
5c3a48 restaurada conforme ELF, inclusive o zero devolvido na instrucao de delay.
321/321 testes; rodada601s: correcao executada2372 vezes, nenhum bad5c3a48.
Animacao18; ainda256linhas de recovery (limite), primeiro alvo5b9990.
Sem aceite de menu nem ganhoFPS comprovado. Nenhum MC3 ficou rodando.
Proximo: auditar lote limitado das entradas restantes (501268/5012c0/42bf00),
restaurando apenas semantica comprovada; sem retornos genericos ou alterar rede.
Ver `docs/RESULT_ZERO_RETURN_2026-09-06.md`.

Checkpoint anterior03:21:
2300d0 restaurada conforme ELF (`jr ra; nop`), owner recompilado, registro
regenerado e exe relinkado.320/320 testes; rodada601s semcrash, animação13.
2300d0 não reaparece no log; primeiro alvo ausente agora5b9990. Ainda256linhas
de recovery (limite), portanto sem aceite de menu nem ganhoFPS comprovado.
Próxima prioridade: demais entradas verificadas, especialmente5c3a48, cuja
instrução de delay devolve ZERO e não é NOP. Não usar retornos genéricos.
Ver `docs/RESULT_VERIFIED_LEAF_2026-09-06.md`.

Checkpoint anterior02:20:
Nova sonda:319/319 testes; rodada601s encerrou sem crash, animação11.
Principal esperou sinal de conclusão por pelo menos361,9s e depois avançou.
**256 linhas de recovery (limite do log)**: já ocorriam no controle anterior.
Primeiro destino2300d0 é função válida `jr ra; nop` no ELF, ausente do catálogo/
registro. Isso não prova que ela cause a lentidão; demais destinos exigem auditoria.
Prioridade: corrigir entradas ausentes comprovadas e validar sem fallback antes
de aceitar o menu. Ver `docs/RESULT_MAIN_WAIT_2026-09-06.md`. Sem ganhoFPS provado.

Checkpoint anterior:
Mapa de cobertura por sistema (auditoria06/09): `docs/MAPA_DE_PROGRESSO.md`.
55,7% do catálogo tem nome associado; isso **não** mede quanto do jogo funciona.
Controle900s com mesmo binário e menos logs: rede coincide com422/429s de espera
pelo token na fase tardia. Sonda nova600s: destino real001b84e8,468 chamadas
completas, média411ms de parede;318/318 testes. **Sem ganho de FPS comprovado.**
Nessa última rodada a animação não avançou e a espera pelo token parou de crescer:
é necessário identificar a espera interna da principal antes de atribuir tudo à rede.
Ver `docs/RESULT_WAIT_QUIET_2026-09-06.md`. Não alterar scheduler nem desligar rede.

Resultado anterior:
Rodada901,67s completou: depois da abertura, **352,67 dos381,30s de espera pelo token
coincidiram com a thread de rede (92,5%)**. Não é92,5% do tempo total nem prova de bug
do scheduler. Corrigido também crash de diagnóstico que lia contexto já destruído.
**317/317 testes; zero caps; animação21; imagem900k quase preta, menu não aceito.**
Ver `docs/RESULT_WAIT_OWNERS_2026-09-05.md`. Próximo: controle com logs reduzidos e
medição da chamada interna do gerenciador de rede; não desativar a thread.

Histórico do lote anterior — identificado e corrigido um erro no
**FSAND**, que zerava VI1 em vez de escrever em VI7 e prendia o bloco 0x2820..0x2868.
O teste reduzido passou de atingir 65.536 ciclos a terminar em dez. **313/313 testes**.
Rodada corrigida901s: **82 caps**, contra15.852 no probe anterior901s; sem prova de
ganho de FPS (animação18 vs21). **Imagem pontual ainda preta; boot/menu não aceitos.**
Lote seguinte: contrato **XTOP/TOP vs XITOP/ITOP corrigido** (runtime031f584).
Captura inicial confirmou bloco48 com header14, mas leitura errada em338 com zero.
O mesmo caso termina em934 ciclos corrigido, antes65536; oito replays e316/316 testes
passaram. Rodada corrigida901,51s: **zero caps**, animação18 (igual à anterior),
940.100 primitivas. **Sem ganho de FPS provado; imagem700k preta, menu não aceito.**
Captura posterior900k executada no lote de espera acima, sem alterar scheduler.
Ver `docs/RESULT_VIF_INPUTS_2026-09-05.md`.
Ver `docs/RESULT_VU1_BUDGET_2026-09-05.md`.
**10,4 s é VIF acumulado dividido por voltas, não duração total de quadro.**
O diagnóstico de causa única ainda não está demonstrado. Ver
`docs/RESULT_RENDER_AUDIT_2026-09-05.md` para correções e próximo experimento.

## 📌 Ponto de parada (retomar daqui)

Historicamente houve **tela legal do frontend desenhada corretamente**. Nas rodadas
recentes, a captura pontual em700k é preta e não aceita o boot visualmente.
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

- Houve imagem legível historicamente; no último lote,940.100 primitivas e imagem700k preta.
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

Custos históricos nessas corridas: **~30-86 µs por primitiva**, **~60-106 ns por pixel**,
**~120 mil chutes de VU1 por corrida**. Os **88 ciclos por chute** descrevem a cena inicial,
não a cena posterior: nela foram observadas milhares de chamadas atingindo 65.536 ciclos.
O custo do caminho **GIF/GS entre o XGKICK e o `drawPrimitive`** não elimina essa nova pista.

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

## Aberto em 2026-09-05 (sonda de escritas e revisão do suposto ciclo)

**O ciclo de `fe6AC` alegado na seção 19 do histórico não foi demonstrado.** Releitura
cronológica de `probe_longcook_20260905`: **887 blocos completos, zero regressões, máximo e
último valor 40**. O histograma não prova `39 → 0`; linhas corrompidas foram descartadas.

Sonda passiva instalada em oito escritas de quatro owners, com objeto, origem, valor antigo/
novo, clipe e timers. A corrida `fe_writes_astra_20260905` mostra o mesmo objeto e clipe,
slot 10, **119 posições, duração 3**, timer avançando **0,033 por Update**. As primeiras
escritas são inicialização e progresso normal, sem reinício. Isso não prova que o boot
completo terminará; retira uma conclusão incorreta do caminho. Ver
`docs/RESULT_FRONTEND_WRITES_2026-09-05.md` e `tools/diagnostics/FRONTEND_WRITE_PROBE.md`.

**Origem da investigação do VU1 (antes da correção FSAND).** No lote Astra, 15.852 chamadas chegaram
a 65.536 ciclos, consumindo 94,3% dos ciclos VU contabilizados. No log antigo de 30 min:
30.169 chamadas, 96,8%. Foram usados blocos completos (271/577 amostras não zero).
O contador também admite término normal exatamente no último ciclo. A captura posterior
separou isso e encontrou o erro FSAND; restam82 caps de outra entrada no lote corrigido.
Não é percentual de tempo de parede. A conclusão histórica de zero estouros só valia para
a cena anterior; não elimina este caminho.

## Próximos alvos, em ordem

0. **Discriminar o custo interno do gerenciador de rede, dono da espera medida.**
   Primeiro controlar a interferência dos logs (`-QuietBootTrace -TraceWait`);
   depois medir callback em1f9608, destino emvtable+0x7c e retorno guest1f9610.
   Não desligar rede nem alterar scheduler/math por essa atribuição isolada.
   FSAND da entrada0x30 e contrato TOP/TOPS/ITOP/ITOPS da entrada0x60 foram corrigidos,
   com testes discriminantes e replay dos oito inputs reais. Não reabrir a mesma
   hipótese sem nova evidência. Usar `-FrameDumpMinPrims` na sonda para fotografar
   depois dos700k iniciais; uma imagem pontual preta não descreve toda a execução.
   Fechar tempo por volta real: parede, VIF e espera/execução.
   Não alterar scheduler. O gate de `GS::processGIFPacket` (`ps2_gs_gpu.cpp`) já foi
   relinkado no lote Astra; sua magnitude continua sem A/B validado.
1. **Refazer a medição do gate da seção 15** com `Measure-RenderCost.ps1`. O ganho anunciado
   (3,5x) veio do método ruim; o conserto se justifica pelo mecanismo, mas o número precisa ser
   refeito antes de ser citado.
2. **Caminho GIF/GS entre o XGKICK e o `drawPrimitive`** (~152 µs por chute). Maior item dentro
   do escopo do VU1 e o **menos investigado** — só foi aberto em 05/09.
3. **Rasterizador** (~60-106 ns por pixel). Uma a duas ordens de grandeza de folga em relação ao
   que a técnica permite. Maior fatia na tela do frontend.
4. **VIF1 fora do VU1.** Já respondeu a uma otimização em 30/08 (queda de 59%), então há
   precedente de que o estágio rende.
5. **Imagem/apresentação.** Houve PNG legal correto historicamente, mas os dumps pontuais
   recentes em700k primitivas também são pretos. Não reduzir tudo à janela do host.
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
| "todo VU1 é barato porque houve zero estouros no teste inicial" | **Conclusão invalidada para o frontend:** os logs longos mostram milhares de chamadas no teto. Ver lote Astra; o zero era restrito ao trecho inicial. |
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
