# Sessao de continuidade do lote — 2026-08-01

Timezone: America/Sao_Paulo

## Resultado verificado

- `04:00:30`: objeto de `sub_0042EB08_0x42eb08.cpp` compilado no `batch_0036`.
- `05:59:31`: relink passou, `15811` funcoes registradas e `0` stubs faltantes.
- `06:00:21–06:00:31`: `req4nosid` confirmou o loop em `0x2455f0`; retorno observado de `5420C0`: `v0=0x6`, esperado pelo chamador: `0x2`.
- `06:05:12–06:05:22`: experimento env-gated `req4ret2` avancou para `0x245734`, o loop que exige `5422C8 == 1`.
- `06:06:59–06:07:08`: `req4ret2ret1` avancou para `0x546d60`, mas revelou um retorno interno ausente em `0x42eb90`.
- `06:08:33`: `sub_0042EB08` recebeu o alvo interno `0x42eb90` no dispatcher; relink passou com `168090` aliases e `0` stubs.
- `06:09:14–06:09:27`: novo probe avancou para `0x5424c8` (`sub_005424A8`); verificacao passou. GIF/GS continuam `0`, entao ainda nao e aceite visual.
- `06:10:15–06:10:28`: o mesmo lote avancou novamente para `0x238924` (`sub_002388F8`); verificacao passou. Counters atuais: `dma=0 gif=0 gsw=0 vif=2`.
- `06:12:58–06:13:18`: lote de 20s avancou para `0x5494e0` (`sub_00549488`); verificacao passou. Counters: `dma=2 gif=0 gsw=0 vif=3`.
- `06:14:16–06:14:46`: repeticao de 30s regressou a `0x245734`; verificacao passou nesse estado, mas confirmou que os gates env-gated ainda sao sensiveis ao timing.
- `06:16:57–06:17:18`: lote de 20s avancou para `0x54258c`, retorno de `sub_005424A8` com `v0=0`; o chamador espera `1`.
- `06:18:59–06:19:13`: experimento `req4ret2ret1a8` liberou esse retorno e avancou para `0x5419a0` (`FUN_00541968`); verificacao passou.

## Checkpoint 06:20:19-06:21:20

- Lote grande de 60s permaneceu estavel em `0x5419a0`; verificacao estrutural passou, `gif=0 gsw=0`.
- Trace env-gated preparado para medir `0x61fbb4/0x61fb94` e o retorno de `FUN_00549680`.

## Estado atual

### Resultado do trace focalizado 06:28:11-06:28:44

- Recompilacao direta de `FUN_00541968` e fast relink passaram.
- Probe de 8s ficou em `0x5419a8`; no inicio `fbb4=0`, depois `0x54241c` grava `fbb4=1`.
- A partir dai `fbb4=1` permanece por mais de 246000 polls; `fb94=0` e `FUN_00549680` nao e alcancada.
- O bloqueio real esta no produtor de `fbb4`, antes do `5419a8`; nao e o callback que deveria limpar a flag.

### Experimento skip-latch 06:30:35-06:31:12

- `MC3_EXPERIMENT_5422C8_SKIP_LATCH=1` manteve `fbb4=0`, mas nao liberou o boot: 20s ficou estavel em `0x5419a8`, `gif=0 gsw=0`.
- Resultado: a flag e necessaria para o fluxo interno; remover a gravação nao e correção. O próximo alvo e o retorno/estado após `FUN_00549680`, não um bypass permanente.

### Progresso provider 06:34:00-06:40:55

- Bypass diagnostico dos gates anteriores chegou a `0x2b4488`, depois o trace do provider confirmou objeto `0x6772f0`, vtable `0x6321e0`, metodo `0x429fc0`.
- `sub_00429FC0` retorna `v0=0` porque a flag `0x619f40` esta `0`; o provider nao foi inicializado. Nenhum GIF/GS apareceu.
- Trace foi adicionado ao metodo provider e o fast relink passou. Proximo alvo: caminho `FUN_00447928 -> FUN_003c8cf8 -> FUN_004faa10`, que contem o escritor da flag `0x619f40`.

- Gate atual sob o probe de continuidade: `0x5419a0`.
- Classificacao: `render-started`.
- Counters: `dma=0 gif=0 gsw=0 vif=3`.
- Ultimo bloqueio: `PollSema` no semaforo `15`, com retorno `-419`.
- O trace de uma execucao chegou a mostrar `WaitSema` acordando semaforos sucessivos (`128+`) no retorno `0x549640`; isso indica a fila SIF sendo recriada/consumida em ciclo, nao uma funcao ausente.
- Em `0x5419a0`, `FUN_00541968` aguarda `0x61fbb4` zerar; esse campo e escrito como `1` por `FUN_005422c8` em `0x54241c` e precisa ser limpo pelo caminho `FUN_00549680`.
- O ajuste permanente desta sessao foi apenas o dispatcher interno de `0x42eb90`.
- Os retornos `5420C0 -> 2` e `5422C8 -> 1` continuam somente como experimentos env-gated; nao sao correcoes aceitas.

## Proximo comando exato

`15_auto_boot_probe.bat 20 req4ret2ret1a8`

Depois: investigar `FUN_00541968_0x541968.cpp` e `FUN_00549680_0x549680.cpp`, especialmente quem limpa `0x61fbb4`.
## Checkpoint 2026-08-01 07:10 BRT — ISO asset containers confirmed

- A ISO local contém os arquivos físicos reais `ASSETS.DAT` (1,444,214,784 bytes), `STREAMS.DAT` (1,025,642,496), `TEXTURE.DAT` (794,839,040) e `BANKS.DAT` (52,967,424).
- Os cabeçalhos foram lidos diretamente: `ASSETS.DAT`/`TEXTURE.DAT`/`BANKS.DAT` começam com `Dave`; `STREAMS.DAT` começa com `Hash`. Portanto, a hipótese antiga de `texture.zip` fica oficialmente descartada.
- O ELF confirma os caminhos `cdrom0:\assets.dat`, `cdrom0:\texture.dat`, `cdrom0:\STREAMS.DAT` e `cdrom0:\BANKS.DAT`.
- A resolução de `cdrom0:` no runtime aponta para a pasta do ELF (`extracted_iso`), então os arquivos estão no lugar esperado.
- Trace adicional em `FUN_00447928` não apareceu no probe de 8 s; o caminho que marca `0x619f40` não está sendo alcançado antes do loop em `0x2b4488`. Relink passou; probe classificou `render-started` por causa dos bypasses, mas continuou sem GIF/GS (`dma=2 gif=0 gsw=0 vif=3`).

**Estado:** evidência de mídia suficiente; próximo alvo é descobrir o chamador/registro indireto de `FUN_00447928` ou a inicialização equivalente, sem criar arquivo falso nem depender do PCSX2.

## Checkpoint 2026-08-01 07:14 BRT — tabela de callback

- A ELF contém duas referências físicas a `0x00447928`, em tabelas nos offsets `0x4847E8` e `0x4927D0`; a segunda está cercada por `0x447CF8`, `0x447DB8`, `0x447DD8` e `0x447DF8`, confirmando uma tabela de callbacks/rotinas.
- Instrumentei `FUN_00206638` e `sub_00447CF8`; nenhum dos dois foi executado no probe atual. Logo, o bloqueio acontece antes da cadeia de registro, ou a tabela é chamada por dispatch indireto ainda não reproduzido.
- Relink e probe passaram; estado continuou em `0x2b4488`, `gif=0`, `gsw=0`.
- O segundo registrador direto, `sub_00206548`, também não entrou no probe. A falha está antes desses dois caminhos ou no dispatch de thread/rotina que os seleciona.

## Checkpoint 2026-08-01 07:19 BRT — gate anterior ao registro

- A cadeia foi refinada: `sub_001A12D0` só chama `sub_00206548` se o global `0x00619318` estiver preenchido; se estiver nulo, pula todo o registro.
- O probe também não entrou em `sub_001A12D0`, então o próximo bloqueio está antes dessa rotina. O gate explica por que `0x447928` e `0x619f40` nunca aparecem, sem indicar ainda qual valor deveria ser gravado em `0x619318`.
- Relink/probe continuam verdes estruturalmente, mas sem render real: `0x2b4488`, `gif=0`, `gsw=0`.

## Checkpoint 2026-08-01 20:23 BRT - sid46 thread gate

- A thread `id=4` entra em `0x1F70E0` com argumento `0x2E`, que `FUN_001F70E0` copia para `$s2` e usa diretamente em `WaitSema($s2)`.
- Portanto, o `sid=46` observado não é criado dentro da thread: ele é criado pelo chamador antes de `StartThread`; a thread só espera por ele.
- Depois do wake, a thread consulta `0x614D7E` e só então chama `0x398B40/0x398C20`; nenhum desses passos é alcançado no probe.
- O trace não mostra `SignalSema(46)` nem envelope SIF com semáforo `46`. Isso elimina a hipótese de um simples atraso do loop e aponta para o produtor ausente da inicialização do worker.
- Não foi aplicado bypass nem sinalização sintética.

**Próximo alvo:** mapear o chamador de `StartThread` (`0x398B88`, retorno `0x398BFC`) e o objeto de parâmetros produzido por `0x4329B0`, para descobrir qual evento deveria sinalizar `0x2E`.

## Checkpoint 2026-08-01 20:18 BRT - SIF request ownership

- Corrigido o procedimento de compilacao: adicionar `C:\\msys64\\ucrt64\\bin` ao `PATH` permite que o `g++` encontre `cc1plus`; o lote `0054` foi recompilado e o fast relink passou.
- Trace novo em `sub_00549488` mostrou o request que antes parecia anonimo: `a0=0x701880`, `a1=0xFF`, `t0=8`, `t1=0x700DC0`, `t2=8`, retornando pelo `SIF` como `request=0xFF payload=0x700DC0 size=8`.
- O request `0x4 -> 0x620D80` completa corretamente e acorda o semaforo `45`; ele nao e mais o bloqueio atual.
- Depois disso, o sistema cria `sid=46/47`, inicia a thread `id=4` em `0x1F70E0` com `arg=0x2E`, e ela bloqueia em `WaitSema sid=46 ra=0x1F7150`.
- Respostas ainda nao modeladas no trace: `0xFF -> 0x700DC0`, `0x0/0x9 -> 0x701B40`, `0x1 -> 0x6F9000` e `0x1 -> 0x6FC780`. Isso orienta a proxima investigacao, mas ainda nao justifica um valor sintetico.
- Probe de 20s: `render-started`, PC estavel `0x2B4488`, `dma=2 gif=0 gsw=0 vif=3`; sem grafico visivel.
- A instrumentacao `MC3_TRACE_SIF_REQUEST` ficou env-gated no codigo gerado para o proximo lote.

**Proximo alvo:** identificar o produtor do `sid=46`/thread `0x1F70E0` e comparar o conteudo esperado dos retornos SIF antes de qualquer experimento novo.

## Checkpoint 2026-08-01 08:56 BRT - backend continuation

- Trace de 60s: o primeiro backend retorna com `ctx->pc=0x54A188`, dentro de `sub_0054A080`, antes de qualquer entrada observada em `0x3988F8`.
- `0x54A188` e um loop de limpeza da fila em `0x701680..0x701880`, seguido por `WaitSema`; nao e stub ausente nem prova de falha no callback.
- Relink continua verde: 15.811 funcoes, 168.090 aliases internos e 0 stubs ausentes.
- Probe de 60s: `render-started`, PC estavel `0x2B4488`, `dma=2 gif=0 gsw=0 vif=3`; ainda sem grafico visivel.
- A tentativa de recompilar a instrumentacao de `0x54A080` foi bloqueada pelo toolchain local: o `g++` encontra o driver, mas nao encontra/executa `cc1plus`; o codigo diagnostico foi removido.

**Proximo alvo:** recuperar compilador funcional ou seguir pelo trace existente `0x54A188 -> 0x5469C0/0x5469E0`, sem bypass permanente.

## Checkpoint 2026-08-01 23:28 BRT - caminho secundario nao alcancado

- Instrumentacao env-gated nos quatro pontos (`0x371CC8`, `0x371C78`, `0x374540` e `0x1F7880`) nao registrou nenhuma entrada no probe de 20s.
- Os tres chamadores montam a mesma chamada `0x1F7880` depois de obter `obj+0x4B54` via `0x206880`; como nenhum entrou, o bloqueio esta antes desse grupo/dispatch, nao dentro da rotina que deveria chamar `sub_001F72A0(a0=1)`.
- Relink passou e a verificacao estrutural passou; o estado visual nao mudou: `PC 0x2B4488`, `dma=2 gif=0 gsw=0 vif=3`.

**Proximo alvo:** rastrear o dispatch que deveria entrar em `0x371CC8/0x371C78/0x374540`, priorizando os chamadores de `0x371C78` e `0x374540` e o estado retornado por `0x206880`.

## Checkpoint 2026-08-01 23:21 BRT - produtor sid46 condicionado por estado

- O trace env-gated confirmou que `sub_001F72A0` entra uma vez pelo caminho de inicializacao com `a0=0`, mas le `0x614B64=0` e desvia antes do `SignalSema(46)`.
- A rotina so sinaliza o semaforo quando uma chamada posterior encontra `0x614B64=1` e a condicao de estado em `0x614D7D` coincide; a primeira chamada cria os semaforos/threads e grava `0x614B64=1` ao final.
- O segundo chamador conhecido e `sub_001F7880 -> sub_001F73D0`, que chama `sub_001F72A0(a0=1)`, mas nenhuma entrada em `0x1F73D0/0x1F7880` apareceu no probe. Isso explica a ausencia de `SignalSema(46)` sem apontar para falha no SIF.
- Probe fresco: `render-started`, PC `0x2B4488`, `dma=2 gif=0 gsw=0 vif=3`; verificacao estrutural passou.

**Proximo alvo:** mapear por que `sub_001F7880` nao e alcancada no fluxo atual, partindo dos chamadores `0x371CC8`, `0x371C78` e `0x374540`, antes de qualquer bypass.

## Checkpoint 2026-08-01 22:52 BRT - parametros reais da CreateThread

- A instrumentacao env-gated `MC3_TRACE_THREAD_CREATE` foi compilada no objeto correto (`batch_0027`) e o fast relink passou; a duplicata acidental em `batch_0039` foi removida antes do relink.
- A estrutura criada por `FUN_00398B88` confirmou: `entry=0x1F70E0`, `arg=0x2E`, `gp=0x6B1040`, `pc=0x1000`, prioridade `6`. O `0x2E` e intencional e corresponde diretamente ao semaforo 46.
- O probe fresco de 20s continua estruturalmente verde: `render-started`, PC `0x2B4488`, `dma=2 gif=0 gsw=0 vif=3`; `20_verify_boot_state.bat 0x2b4488` passou, com `real-render-traffic` ainda pendente.
- Nao houve `SignalSema(46)` depois da criacao. O bloqueio permanece no produtor ausente do worker, nao na montagem da thread nem no request `0x4` (que acorda o semaforo 45).

**Proximo alvo:** mapear quem deveria sinalizar o semaforo 46 a partir dos campos/objetos usados por `0x1F70E0`, sem sintetizar sinal nem retorno SIF.

## Checkpoint 2026-08-01 07:53 BRT - provider BSS

- Corrigida a leitura anterior: a tabela `0x617F88` possui `fn0=0x398830`; ele lê corretamente os slots físicos `0x617FC0=0x3984C0`, `0x617FC4=0x398610` e `0x617FD4=0x3987E0`.
- O slot `0x711D40` é BSS no ELF e permanece zero no runner. `sub_00399308` chama o primeiro método, mas aborta antes do callback global; por isso retorna `0`, `4FAA10` não roda e `0x619F40` não muda.
- Trace de 30s e relink passaram: PC estável `0x2B4488`, counters `dma=2 gif=0 gsw=0 vif=3`.
- Override experimental `MC3_EXPERIMENT_711D40_FN=0x3988F8` foi usado apenas como diagnóstico; não é correção aceita e não produziu render GIF/GS neste lote.
