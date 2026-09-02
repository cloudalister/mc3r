# As sondas de semáforo estavam cegas na janela investigada — 2026-08-31

Sessão seguinte ao handoff `HANDOFF_2026-08-31_SESSAO_FRESCA.md`. Fecha os dois itens que
aquele handoff deixou anotados e não feitos, e um deles derruba uma conclusão viva.

## 1. A coluna do CSV: a alegação estava certa

Verificada linha a linha em `work/exports/retail_symbol_port.csv`:

- 8.815 linhas.
- Coluna 2 (`retail_old_name`): **42** têm nome real, todas de kernel (`AddIntcHandler`,
  `RemoveDmacHandler`, `SetAlarm`...). As outras 8.773 são só o rótulo `FUN_` do Ghidra.
- Coluna 4 (`alpha_name`): **100% preenchida**.

Confirmado também o caso concreto: `0x4323E8` é `datStreamer::Close(unsigned int)` na coluna
4 e `FUN_004323e8` na coluna 2.

## 2. `work/scratch/resolve_symbols.py` — o resolvedor

Fecha a armadilha de vez: qualquer script que precise de nome chama isto e não escolhe coluna.
Combina duas fontes, porque nenhuma sozinha basta:

| fonte | dá | cobre |
|---|---|---|
| nomes de arquivo do corpus (`<rótulo>_0x<entrada>.cpp`) | **fronteiras** exatas de função | 15.812 (todas) |
| `retail_symbol_port.csv`, coluna 4 | **nomes** reais | 8.815 (55,7%) |

Só o CSV não delimita função, então endereço dentro de uma função não portada era atribuído à
função nomeada anterior — que pode estar longe. Era assim que `0x431F98` aparecia como "depois
de `datStreamer::ValidateHandle` +0x1F8".

Ligado ao `find_divergence.py`: a linha de `pc` agora sai com o nome embaixo.

## 3. O worker tem nome: `datStreamer::Worker(void *)`

`FUN_00431E00`, a função central de toda a investigação, estava sem nome porque o port a
recusou: alpha `0x3F4080` tem 812 bytes, retail tem 736, e o port exige tamanho compatível.
Nas duas builds ela fica entre `ValidateHandle` e `Read`, na mesma ordem, com os vizinhos de
tamanho idêntico. Está em `OVERRIDES` no resolvedor, com a evidência ao lado.

Duas leituras corrigidas por isso:

- **`0x431F98` é `datStreamer::Worker +0x198`.** A sonda do "laço de transferência" estava
  dentro do worker, não numa função vizinha.
- **`0x432BA8` é `memcpy +0x88`**, não código do streamer. O "PC parado perto de `0x432ba8`"
  do handoff é uma amostra caindo dentro do `memcpy`.

As três "sem nome" do handoff continuam sem nome próprio — o MC.MAP tem um buraco ali — mas
são caracterizáveis por vizinhança: `0x3986D8` e `0x398788` na família `coreRaw*` (entre
`coreFileSignalSema` e `coreRawOpenFile`), `0x245680` na região `psxCdCache::*` (logo antes de
`psxCdCache::RawRead`). O resolvedor marca essas regiões entre colchetes, para não confundir
hipótese com nome.

## 4. O achado: toda sonda de semáforo se esgota antes do segundo pedido

O handoff mandava auditar as outras sondas atrás de tetos como o de 64 do `mcFlash::Update`.
Existem, e um deles invalida uma conclusão viva.

Em `catch_xfer_r2` (ramo ruim, 20.877 linhas), o **segundo dequeue está na linha 20.722**:

| sonda | teto | n | última emissão |
|---|---:|---:|---:|
| `CreateSema` | 128 | 128 | linha 2.726 |
| `WaitSema:wake` | 512 | 512 | linha 3.813 |
| `SignalSema` | 512 | 507 | linha 3.835 |
| `WaitSema:block` | 512 | 512 | linha 13.848 |
| `PollSema` | 512 | 512 | linha 16.202 |

**As cinco estão mudas na janela inteira do segundo pedido de streaming.** A de `SignalSema`
cala 16.887 linhas antes do evento.

Portanto a leitura de que "a sinalização de semáforo é idêntica nos dois ramos" não se sustenta:
ela foi tirada de uma janela em que o instrumento estava desligado. É a mesma armadilha nº 2 do
handoff — teto de amostragem que mente por omissão — em outra sonda.

Os contadores são `static std::atomic<uint32_t>` globais em
`PS2Recomp/ps2xRuntime/src/lib/Kernel/Syscalls/Sync.cpp`, não por thread nem por sid.

## 5. Controle que a leitura do handoff ainda passa

O worker travar de verdade não é artefato de log cortado. Em `catch_xfer_r2` o segundo dequeue
é no tick 19.740 e a execução segue até o tick **23.580** — 64 segundos de jogo — sem `done` e
sem `park`. O handoff está certo nesse ponto.

## 6. O que mudou no binário

Os quatro tetos de `boot-trace` de semáforo em `Sync.cpp` subiram de 512 para 20.000
(`sigLog`, `blockLog`, `wakeLog`, `pollLog`), com a razão no comentário. Lib reconstruída, exe
relinkado, exe mais novo que a lib.

Nada mais foi tocado: os tetos de `RUNTIME_LOG` continuam onde estavam, e as outras sondas com
teto (VU1 em 256, GS em 64, MFIFO em 64, `recover` em 4096) seguem intactas — são de
subsistema que não está sob investigação agora, e estão listadas aqui para a próxima auditoria.

## 7. Armadilha nova, minha, para o próximo não repetir

O discriminador barato do handoff é `busy=0x2`. **No log ele sai `busy=0x00000002`**, com
zeros à esquerda. Procurar por `busy=0x2` devolve zero em toda execução e faz um ramo bom
parecer ruim. Classifiquei três execuções ao contrário até conferir o formato bruto.

Padrão correto:

```bash
grep -c 'busy=0x00000002' run.stderr
```

## 8. O que a próxima bateria responde

Com os tetos levantados, uma bateria com o mesmo protocolo mostra, na janela do segundo
pedido, quem sinaliza o quê e quem fica bloqueado em qual sid — que é exatamente o dado que
faltava para separar "worker não é escalonado" de "worker roda e não conclui".

## 9. Inventário completo dos tetos — a auditoria que o handoff pediu

Varredura dos 77 sítios de emissão `boot-trace:` em `PS2Recomp/ps2xRuntime/src`, cruzada com
a contagem real em `catch_xfer_r2.log.stderr` (ramo ruim, dequeue nº 2 na linha 20.722 de
20.877). O cruzamento importa: só o código dá falso positivo, porque guarda com escape
(`|| changed`, `|| (n % 512) == 0`) não é teto rígido — `sceSifSetDma` tem `< 128u` no fonte e
emitiu 1.059 vezes, `present-upload` tem `< 8u` e emitiu 74.

**Dezesseis sondas atingiram o teto e estavam mudas na janela do segundo pedido:**

| sonda | teto | última emissão | linhas de cegueira |
|---|---:|---:|---:|
| `CreateSema` | 128 | 2.726 | 17.996 |
| `ee-timer2` | 128 | 3.510 | 17.212 |
| `vblank-tick` | 512 | 4.221 | 16.501 |
| `vif1-direct` | 128 | 6.319 | 14.403 |
| `vu1-transform` | 192 | 7.349 | 13.373 |
| `vu1-branch` | 256 | 8.753 | 11.969 |
| `vif1-packet-write` | 256 | 9.649 | 11.073 |
| `vu1-packet-write` | 256 | 10.720 | 10.002 |
| `vu1-mulq` | 256 | 10.262 | 10.460 |
| `vu1-vf20-write` | 256 | 11.003 | 9.719 |
| `vu1-q-write` | 256 | 11.251 | 9.471 |
| `intc-stat-latch` | 4.096 | 11.230 | 9.492 |
| `gs-primitive` | 256 | 12.462 | 8.260 |
| `vu1-xgkick` | 128 | 12.511 | 8.211 |
| `dmac-start` | 32 | 12.542 | 8.180 |
| `gs-field-toggle` | 4.096 | 15.264 | 5.458 |

Mais as cinco de semáforo da seção 4, que naquele log ainda estavam em 512/128.

Consequência prática: **toda a instrumentação de gráficos (VU1, VIF1, GS) e de interrupção
está desligada na janela do segundo pedido de streaming.** Qualquer comparação entre ramos
feita a partir desses marcadores, nessa fase da execução, está comparando silêncio com
silêncio. Isso não invalida os contadores agregados de `frame` (`gsPrims`, `gifPk*`), que são
lidos do estado e não da sonda.

Só os quatro tetos de semáforo foram levantados. Os outros dezesseis ficam registrados aqui e
devem ser levantados **um subsistema por vez, quando aquele subsistema for a pergunta** — subir
todos de uma vez multiplica o log e torna a bateria mais lenta sem responder nada.

Reproduzir o inventário: a varredura está descrita acima e é curta o bastante para refazer;
o cruzamento com log é o que separa teto rígido de guarda com escape.

## 10. Bateria com os tetos levantados — 6 × 420 s, rótulo `semawin`

Primeira medição com as sondas de semáforo enxergando. O que ela estabelece e o que não.

**Os tetos novos funcionam.** `SignalSema` emitiu 19.852 vezes contra as 512 de antes: o teto
antigo escondia cerca de 8,8× da atividade de sinalização.

**Seis de seis caíram no ramo ruim** (`busy=0x00000002` ausente em todas). Com o binário
anterior a proporção observada foi 1 bom em 3. Amostras pequenas demais para afirmar que a
instrumentação deslocou a corrida — 1/3 contra 0/6 não separa nada — mas fica registrado.

**Só uma das seis chegou a ter um segundo dequeue.** As outras cinco terminam com `deq1`/
`done1` e nada mais. Os 420 s acabam bem em cima do momento em que o segundo pedido sairia da
fila: as execuções terminam entre os ticks 19.380 e 22.560, e o segundo dequeue, quando
acontece, cai entre 19.380 e 22.320.

### O controle que faltava: quanto tempo o desfecho bom precisa

Medido em tick de jogo, não em linha de log — densidade de log difere entre execuções e
comparar linhas seria enganoso.

| execução | ramo | `deq2` | janela após `deq2` | `done2` |
|---|---|---:|---:|---|
| `catch_xfer_r1` | bom | tick 19.380 | — | **240 ticks (4,0 s)** |
| `catch_xfer_r2` | ruim | tick 19.740 | **3.840 ticks (64 s)** | nunca |
| `stall_semawin_r1` | ruim | tick 22.320 | **60 ticks (1,0 s)** | nunca |

**O desfecho bom conclui o segundo pedido em 4 segundos de jogo.** A `catch_xfer_r2` observou
64 segundos sem `done` — 16× a folga necessária. A trava do handoff é real e sobrevive ao
controle.

A `semawin_r1`, ao contrário, **não prova nada sobre conclusão**: um segundo de janela é um
quarto do que o desfecho bom leva. Toda execução de 420 s está sujeita a isso.

### O worker não está parado

Na `semawin_r1` a thread do worker (tid=5) registrou **10.803 bloqueios de semáforo** ao longo
da execução, com os sids ciclando pela faixa inteira e sendo realocados — padrão de
cria-espera-sinaliza-libera por operação. Depois do segundo dequeue ela bloqueia em sete sids
distintos e crescentes; para bloquear num sid novo, foi acordada do anterior.

Isso enfraquece a hipótese principal do handoff, de que **a thread do worker não estaria sendo
escalonada** depois do dequeue. Ela é escalonada e faz syscall o tempo todo. O que ela não faz
é chegar ao `done`.

Ressalva de força: a janela pós-dequeue nessa execução é de 1 segundo e cobre só sete
bloqueios. O padrão está claro, o volume dentro da janela não.

### Correção de uma atribuição minha

Atribuí a janela curta da `semawin_r1` ao log maior. Os números não sustentam: `semawin_r1`
chegou ao tick 22.380 em 420 s e `catch_xfer_r2` ao 23.580 no mesmo tempo, 5% de diferença. O
que varia é **quando** o segundo dequeue ocorre (ticks 19.380, 19.740 e 22.320 nas três), não
o custo da instrumentação.

### Cobertura das sondas na janela, em `semawin_r1`

| sonda | emitiu | cobre a janela |
|---|---:|---|
| `WaitSema:block` | 11.111 | sim, até a última linha |
| `PollSema` | 949 | sim |
| `SignalSema` | 19.852 | não, esgotou 3.430 linhas antes |
| `WaitSema:wake` | 20.000 | não, esgotou |

Por isso os quatro tetos subiram de novo, para 200.000, antes da bateria de 1200 s: em execução
longa os 20.000 se esgotam a ~40% do log.

## 11. Bateria de 1200 s — o jogo passa da tela de carregamento

Três execuções, rótulo `semalong`, tetos de semáforo em 200.000.

**As três concluíram o segundo pedido e entraram no menu.** Reprodutível, 3 de 3:

| | `deq2` | `done2` após | `menu-change` | `gsPrims` | `gsPixels` |
|---|---:|---:|---:|---:|---:|
| `semalong_r1` | tick 22.740 | 480 ticks (8,0 s) | 1 | 1.008.035 | 1.042.142.727 |
| `semalong_r2` | tick 24.840 | 480 ticks (8,0 s) | 1 | 1.005.085 | 1.032.541.676 |
| `semalong_r3` | tick 23.940 | 360 ticks (6,0 s) | 1 | 1.007.848 | 1.042.011.655 |

Contra as de 420 s: `menu-change=0` e `gsPrims` ~690.000. **+46% de primitivas.**

`mc3-menu-change` é o `mcMenuShell::ChangeState` — a função que a hipótese descartada nº 4 do
handoff registrava como "nem é entrada no desfecho ruim". Ela é entrada aqui, uma vez por
execução, e o PC final fica em `swfSCRIPTOBJECT::GetGlobal`, na camada de script da UI.

### O que isso corrige na metodologia, e o que não corrige

**Não** desmente a trava. A `catch_xfer_r2` observou 3.840 ticks após o `deq2` sem `done2`,
oito vezes a folga que estas execuções precisaram. Aquela execução travou de verdade.

**Corrige a contagem.** O marcador `busy=0x00000002` só discrimina ramo em execução que
*chegou* ao `deq2`. Execução cortada antes disso produz log idêntico ao de uma travada — e
cinco das seis execuções de 420 s nunca chegaram lá. Classificá-las como "ramo ruim" mistura
"não chegou" com "travou".

Refazendo a conta só com execuções de janela conclusiva (≥500 ticks após o `deq2`):

| execução | veredito |
|---|---|
| `catch_xfer_r1` | bom |
| `catch_xfer_r2` | **travou** (3.840 ticks sem `done2`) |
| `semalong_r1`, `r2`, `r3` | bom |

**Quatro bons, uma travada.** As outras sete execuções examinadas são inconclusivas, não ruins.
A frequência do desfecho ruim vinha sendo superestimada por contar execução curta demais como
evidência.

### Confundimento que fica em aberto

A bateria longa mudou **duas** variáveis ao mesmo tempo: duração 420 s → 1200 s e tetos de
semáforo 20.000 → 200.000. A explicação por duração tem apoio mecânico — cinco das seis curtas
nem alcançaram o `deq2`, e o `deq2` cai entre os ticks 22.700 e 24.800 enquanto as curtas
terminam entre 19.400 e 22.600 — mas separar as duas exige uma bateria de 1200 s com os tetos
antigos. Fica anotado, não afirmado.

### O que a próxima sessão deve fazer com isto

1. **Toda bateria daqui em diante precisa de pelo menos 1200 s por execução.** Abaixo disso a
   execução termina antes do segundo pedido e o resultado não classifica nada.
2. Reproduzir a travada da `catch_xfer_r2` com janela longa: é o único caso conclusivo de
   trava e agora há instrumentação para observá-lo.
3. A bateria de controle 1200 s × tetos antigos, para desfazer o confundimento acima.

## 12. Controle de duração — 3 × 1200 s com os tetos antigos

O confundimento da seção 11 desfeito. Binário idêntico ao da bateria de 420 s (tetos de
semáforo em 20.000, não 200.000); a única variável que muda é a duração.

| | `deq2` | janela após | `done2` | `menu-change` | `gsPrims` | desfecho |
|---|---:|---:|---|---:|---:|---|
| `semactl_r1` | tick 24.840 | **42.300 ticks (705 s)** | nunca | 0 | 703.599 | **travou** |
| `semactl_r2` | tick 23.520 | — | 360 ticks (6,0 s) | 1 | 1.173.155 | bom |
| `semactl_r3` | tick 23.220 | — | 300 ticks (5,0 s) | 1 | 1.120.554 | bom |

**A duração era o driver, não os tetos.** Com os tetos antigos e 1200 s, duas de três alcançam
o menu. O teto que eu levantei não teve papel no desfecho — o que também significa que a
instrumentação mais pesada **não** está deslocando a corrida, ao contrário do que eu suspeitei
na seção 10.

**E a trava foi reproduzida com margem definitiva.** A `semactl_r1` rodou **42.300 ticks —
705 segundos de tempo de jogo — após o segundo dequeue, sem `done2`.** O desfecho bom conclui
em 300 a 480 ticks. São ~120× a folga necessária, contra os 8× do melhor caso anterior. Não há
mais leitura alternativa possível: a trava é real e é indefinida.

### Assinatura barata e exata do desfecho travado

As três execuções travadas terminam em **`gsPrims=703599`**, o mesmo número até o último
dígito. Nenhuma outra execução, de nenhuma bateria, chega nesse valor:

| execução | `gsPrims` final | desfecho |
|---|---:|---|
| `catch_xfer_r2` | **703.599** | travou |
| `stall_semawin_r1` | **703.599** | travou |
| `stall_semactl_r1` | **703.599** | travou |
| `catch_xfer_r1` | 732.894 | bom, cortado aos 420 s |
| `semalong_r1..r3` | 1.005.085 – 1.008.035 | bom |
| `semactl_r2..r3` | 1.120.554 – 1.173.155 | bom |

O desfecho travado **congela** a renderização em 703.599 primitivas. O bom passa por esse valor
e continua. Isso é discriminador melhor que o `busy=0x00000002`: é contador lido do estado, não
sonda com teto, e não depende de a execução ter chegado a lugar nenhum específico — basta ela
ter passado do ponto.

A execução travada fica em `FUN_00322fd8 +0x24`; a boa, em
`mcParticleFogMgr::DrawAllParticles +0xA4`.

### Frequência do desfecho, refeita

Só execuções com janela conclusiva:

- **Boas: 6** — `catch_xfer_r1`, `semalong_r1/r2/r3`, `semactl_r2/r3`
- **Travadas: 3** — `catch_xfer_r2`, `semactl_r1`, `semawin_r1`
- **Inconclusivas: 6** — nunca chegaram ao segundo dequeue

**Cerca de uma trava a cada três execuções conclusivas.** Não "5 de 7 ruins".

Ressalva sobre a `semawin_r1`: a janela direta dela é de 60 ticks, curta demais para provar
trava por observação. Está classificada como travada pela assinatura `gsPrims=703599`, que é
corroboração forte mas indireta.

### Estado da instrumentação

Os tetos voltaram para 200.000 depois do controle, já que ele mostrou que não alteram o
desfecho e a observabilidade maior é útil. Lib reconstruída, exe relinkado.

## 13. O que o worker faz durante a trava — livelock, não deadlock

A `semactl_r1` tem `WaitSema:block` cobrindo parte da janela. Isso responde a pergunta central
do handoff anterior.

Bloqueios de semáforo entre `deq2` e `done2`:

| execução | desfecho | bloqueios da tid=5 | sids distintos |
|---|---|---:|---:|
| `semactl_r2` | bom | **9** | 9 |
| `semactl_r3` | bom | **18** | 18 |
| `semactl_r1` | travou | **8.426** | 234 |

**O desfecho bom serve o segundo pedido em 9 a 18 operações bloqueantes.** O travado faz 8.426
e não chega ao fim — 500 a 900× mais, ciclando por 234 sids que são criados e destruídos.

Isso é **livelock, não deadlock**: a thread do worker não está presa num semáforo nem deixando
de ser escalonada. Ela executa milhares de ciclos espera/acorda e não converge. A hipótese
principal do handoff anterior — "a thread do worker não está sendo escalonada" — está
descartada.

Taxa medida, por faixa de tick após o `deq2`: 1.240, 1.460, 1.398, 1.455, 1.446, 1.377
bloqueios por faixa de 1.420 ticks. **Constante**, cerca de um por tick. Não é progresso lento
que fosse terminar com mais tempo; é giro estável.

### Quase-erro que vale registrar

Os bloqueios da tid=5 cessam no tick 33.360 enquanto a execução segue até 67.140, e a leitura
imediata seria "o worker gira 142 s e depois para de vez". **É a sonda cegando, não o worker
parando.** A última emissão da tid=5 é a de número 19.936 — a última do log inteiro — contra o
teto de 20.000. Os 563 s seguintes não foram observados.

Detalhe de contagem que confunde: `grep -c` devolve 20.000 e a varredura por ocorrência devolve
19.936. A diferença são emissões truncadas pela intercalação de threads, que o `grep` conta como
linha e o regex estrito descarta. Para julgar teto, o número que vale é o do `grep`.

### O que fica estabelecido e o que não

- **Estabelecido:** por 8.520 ticks (142 s) após o `deq2`, o worker gira a taxa constante sem
  convergir, e `done2` nunca sai até o tick 67.140.
- **Não observado:** o que ele faz nos 563 s seguintes.

Para fechar, falta uma execução travada capturada com os tetos em 200.000. A `semalong`
(1200 s, tetos 200.000) deu bom 3 de 3 e não pegou trava. Com ~1 trava a cada 3 execuções
conclusivas, uma bateria de 1200 s com os tetos altos deve capturar uma. Detector barato para
saber se pegou, sem esperar o fim: `gsPrims` final igual a **703599**.

## 14. O laço do worker, identificado: `DelayThread` em poll rápido

Refinamento da seção 13, do mesmo log (`semactl_r1`), sem bateria nova.

**Os 8.426 bloqueios da tid=5 vêm todos do mesmo sítio: `ra=0x5476b0`, que é
`DelayThread +0xA8`.** 19.415 de 19.421 bloqueios registrados na execução inteira têm esse
`ra` (os seis restantes são linhas truncadas pela intercalação). O runtime implementa
`DelayThread` com um semáforo temporário, e é por isso que o `sid` **incrementa exatamente 1**
em 93% das transições consecutivas, dando a volta no espaço de 256: cada iteração cria um
semáforo novo.

Cadência medida: **mediana de 61 bloqueios por tick**, em 143 ticks distintos. Não é um sleep
longo — é poll com atraso curto, ~61 iterações por quadro.

E não é I/O: na mesma janela houve **24** `mc3-cdvd-rpc` contra 8.473 bloqueios, cerca de 350
bloqueios por operação de CD. O worker não está esperando o disco; está girando.

### A cadeia causal, fechada

O marcador do lado do `Close`, com a linha inteira:

```
mc3-4323e8-progress] stage=0x00432458 loop=16 block=0x00000001 index_v0=0x00000000
  poolBase=0x006771e0 poolEntry=0x006771f0 busy=0x00000001 current=0x00000002
  mask=0x00000010 flag=1 ra=0x00432458 sp=0x0019fc70
```

`busy=0x00000001` na entrada `0x006771f0` e **nunca zera**. O `sp=0x0019fc70` situa esse laço
na pilha da thread principal, não na do worker — são dois laços distintos, em duas threads:

1. **Worker (tid=5):** poll com `DelayThread`, ~61 vezes por quadro, sem convergir.
2. **Thread principal:** `datStreamer::Close` polando `busy` na entrada do pool, que fica em 1.

A ordem causal é essa: o worker não completa o segundo pedido, então `busy` não zera, então o
`Close` não retorna. O laço da thread principal é **consequência**, não causa — e foi o que se
vinha investigando como se fosse a causa.

### O que ainda não se sabe

**O que o worker está polando.** `WaitSema:block` registra `pc` e `ra` do kernel
(`WaitSema`, `DelayThread`), não o quadro do jogo que chamou. Para isso é preciso sonda dentro
do `datStreamer::Worker` (`0x431E00`–`0x4320E0`) nas arestas de retorno do laço — as duas cópias,
pela armadilha nº 4 do handoff.

Correção de leitura minha na seção 13: descrevi 234 sids "criados e destruídos" como se fossem
do trabalho do worker. São semáforos temporários de `DelayThread`. O número de sids distintos
não mede trabalho nenhum; mede quantas vezes o worker dormiu.

## 15. Existe uma segunda trava, depois do menu — e meu discriminador não a via

Bateria `semahang`, 4 × 1200 s com os tetos em 200.000. **Não capturou trava de streaming**:
as quatro fizeram `deq=2/done=2` e alcançaram o menu. Mas duas delas travaram assim mesmo.

### O critério certo é o tempo plano, não o valor

Afirmei na seção 12 que `gsPrims=703599` era discriminador do desfecho travado. **É
discriminador da trava de *streaming*, não de trava em geral** — e me fez classificar duas
execuções travadas como boas. O critério que serve é **há quanto tempo o `gsPrims` fica
plano**: execução sadia cortada fica plana 0–6 s (só a cauda), execução travada fica 366–706 s.

Reclassificando as 19 execuções de todas as baterias por esse critério:

| veredito | n | característica |
|---|---:|---|
| saudável, cortada pelo limite de tempo | 15 | `gsPrims` ainda subindo no fim |
| **travou no streaming** | 2 | `done2` nunca sai, congela em **703.599** |
| **travou depois do menu** | 2 | `done2` sai, menu alcançado, congela em 714.492 e 800.606 |

As duas travas de streaming (`catch_xfer_r2`, `semactl_r1`) congelam no mesmo número até o
último dígito. A `semawin_r1` também terminou em 703.599 com `done=1`, coerente com essa trava,
mas foi cortada 1 s depois e não prova nada sozinha — na seção 12 eu a contei como travada, o
que era forçar a evidência.

### A trava nova

`semahang_r1` e `semahang_r4` completam o segundo pedido de streaming, entram no menu, e então
a renderização **para**: `gsPrims` congela em 714.492 (tick 25.020) e 800.606 (tick 37.020) e
fica plano por 706 s e 366 s. Os ticks continuam avançando — o emulador roda, as threads rodam,
e o GS não recebe mais nada.

O valor de congelamento **não** é fixo entre execuções, ao contrário da trava de streaming.
Isso sugere um ponto de falha que depende de onde a execução estava, não de um estágio fixo.

### Consequência para o que já estava escrito

- O detector barato da seção 12 continua válido **para a trava de streaming** e só para ela.
  Para triagem geral use tempo plano do `gsPrims` acima de ~60 s.
- A contagem "6 boas, 3 travadas" da seção 12 não se sustenta: das 19 execuções, 15 foram
  cortadas enquanto ainda progrediam — não são prova de sucesso, são inconclusivas quanto a
  travar mais tarde. O que se pode afirmar é **4 travas em 19 execuções**, duas de cada modo.
- A `semalong` e a `semactl` que contei como "alcançaram o menu" de fato alcançaram; nenhuma
  delas travou dentro da própria janela. Isso continua de pé.

### O que isso muda no plano

A trava de streaming e a trava pós-menu são fenômenos distintos e precisam de investigação
separada. A de streaming tem causa localizada (worker em poll de `DelayThread`, seção 14). A
pós-menu não tem nada ainda: falta saber se o GS para de receber, se o produtor para de gerar,
ou se alguma thread trava antes disso.

Primeira medida barata para a próxima sessão: numa execução travada pós-menu, ver se
`gifPk1/gifPk2` também congelam junto com `gsPrims` — se congelarem, o problema é antes do GS;
se continuarem subindo, é no GS.

## 16. A trava pós-menu: o laço principal do jogo para de submeter DMA

Medida barata da seção 15, feita no log que já existia.

Em `semahang_r1`, no tick ~25.920, **todos os contadores congelam no mesmo instante**:

| contador | valor congelado |
|---|---:|
| `dma` | 29.583 |
| `gifPk1` | 357.205 |
| `gifPk2` | 140.157 |
| `gsPrims` | 714.492 |
| `gsPixels` | 280.453.755 |

Numa execução sadia (`semahang_r2`) os cinco sobem juntos e continuamente.

**O problema é antes do GS.** O DMA não é emitido — não há trabalho chegando. O pipeline de
renderização não está quebrado, está sem alimentação. E os ticks seguem avançando até 67.320,
ou seja, o emulador roda; quem parou foi o convidado.

### Onde ele para

O PC dominante nas execuções travadas pós-menu fica em `0x1A2760` e `0x1A2748`, presente em
**60 de 60 quadros amostrados**. Os dois endereços caem em `mcGame::Execute(void) +0x3B8` e
`+0x3A0` — 24 bytes de distância, o mesmo laço interno.

O nome saiu pelo mesmo método do `datStreamer::Worker`: alpha `0x1A19D8`, 1156 bytes, contra
1280 no retail, imediatamente antes de `mcGame::PreUpdate` (retail `0x1A28A8` / alpha
`0x1A1E60`) nas duas builds. A diferença de tamanho é o que fez o port de símbolos recusar o
par — **é a segunda função central desta investigação que estava sem nome exatamente por esse
motivo**, o que sugere revisitar a regra de compatibilidade de tamanho do `port_symbols.py`.

Registrado em `OVERRIDES` no `resolve_symbols.py`.

### Estado das duas travas

| | trava de streaming | trava pós-menu |
|---|---|---|
| onde | `datStreamer::Worker`, poll de `DelayThread` | `mcGame::Execute +0x3A0..0x3B8` |
| sintoma | `done2` nunca sai, `busy` fica em 1 | DMA para, todos os contadores congelam |
| valor de congelamento | fixo, 703.599 | variável (714.492, 800.606) |
| ocorrências | 2 de 19 | 2 de 19 |

São dois laços em duas funções diferentes, em fases diferentes da execução. Nada indica, por
ora, que tenham a mesma causa.

### Próximo passo para cada uma

- **Streaming:** sonda dentro do `datStreamer::Worker` (`0x431E00`–`0x4320E0`) nas arestas de
  retorno do laço, nas duas cópias traduzidas, para ver o que ele pola.
- **Pós-menu:** desmontar `mcGame::Execute` em torno de `+0x3A0`–`+0x3B8` e identificar a
  condição do laço. É o laço principal do jogo, então a condição provavelmente espera um
  subsistema que parou — e o `dma` congelado diz que o produtor de display list é candidato.

## 17. O laço da trava pós-menu mede tempo pelo COP0 Count, que o runtime nunca avança

Análise estática do corpus, sem bateria.

Os dois PCs quentes das execuções travadas pós-menu, desmontados:

```asm
0x1a2748:  jal   func_1A2938        # mcGame::PostUpdate(void)
...
0x1a2760:  b     0x1a2788           # incondicional
0x1a2788:  addiu $a0, $zero, 0x3
0x1a278c:  lw    $v1, 0x4($v0)
0x1a2790:  bnel  $v1, $a0, 0x1a2848 # segue adiante só se [v0+4] == 3
0x1a2798:  mfc0  $v0, Count         # <-- contador de ciclos do EE
0x1a279c:  subu  $v0, $v0, $s3      # delta = Count - marca_anterior
0x1a27a0:  bltz  $v0, 0x1a27b8
0x1a27a8:  mtc1  $v0, $f2
0x1a27ac:  cvt.s.w $f2, $f2         # delta vira float
```

Não é spin cego: é **cálculo de tempo decorrido**, num estado específico (`[v0+4] == 3`).

### O defeito

`ctx->cop0_count` aparece em **exatamente três lugares** em todo o `PS2Recomp`:

| lugar | o que faz |
|---|---|
| `ps2_runtime.h:102` | a declaração |
| `code_generator.cpp:1911` | `mfc0`: `SET_GPR_S32(ctx, rt, (int32_t)ctx->cop0_count)` |
| `code_generator.cpp:1961` | `mtc0`: `ctx->cop0_count = GPR_U32(ctx, rt)` |

**Nada no runtime jamais o incrementa.** Ele é zero-inicializado e só muda se o próprio
convidado escrever nele. Logo `mfc0 $v0, Count` devolve sempre o mesmo valor, e o
`subu $v0, $v0, $s3` da linha seguinte dá **delta zero em todo quadro**.

Qualquer código do jogo que meça tempo por COP0 Count vê o tempo parado.

### Por que isso não quebra o jogo inteiro

O caminho só é alcançado quando `[v0+4] == 3`. O resto do jogo usa temporização por vsync,
que funciona — daí a maioria das execuções progredir normalmente e renderizar mais de um
milhão de primitivas. Quando a execução entra nesse estado 3, ela passa a depender de um
relógio que não anda.

Isso casa com o sintoma da seção 16: o laço principal continua girando e chamando
`mcGame::PostUpdate`, mas o estado nunca avança, nada novo é submetido, e `dma`, `gifPk*`,
`gsPrims` e `gsPixels` congelam todos no mesmo instante enquanto os ticks seguem.

### Força da evidência

**Verificado:** o runtime não avança `cop0_count`; o laço lê Count e deriva delta dele; os PCs
quentes das duas execuções travadas pós-menu caem nesse trecho, em 60 de 60 quadros amostrados,
contra 5–10 de 60 nas sadias.

**Não verificado:** que zerar o delta seja *a* causa da trava. Falta confirmar que o estado 3 é
onde as execuções travadas param, e que fazer o Count andar as destrava. É hipótese com apoio
forte, não conclusão.

### Como testar, e por que não fiz agora

Fazer `cop0_count` avançar é mudança de comportamento que atinge **toda** temporização do jogo,
não só este laço — é decisão de escopo, não passo investigativo. O teste barato que a precede:
sonda no `0x1a2798` registrando o valor de `Count`, de `$s3` e do delta, para confirmar que o
delta é sempre zero e que a execução travada fica ali.

## 18. A hipótese do COP0 Count está falsificada — e a trava pós-menu ficou localizada

Bateria `cop0gate`, 4 × 1200 s, com duas sondas em `mcGame::Execute`: uma no portão
(`0x1a2788`, dispara nos dois ramos) e outra no trecho do Count (`0x1a2798`).

A r1 caiu travada (PC dominante `0x1a2760` em 60/60 quadros, `gsPrims=800606`), as outras
três sadias. Amostras:

| execução | portão | trecho do Count |
|---|---:|---:|
| r1 (travada) | 7 | **0** |
| r2, r3, r4 (sadias) | 18, 17, 21 | **0** |

**O trecho do COP0 Count nunca executa.** O portão mostra por quê: `state=0x00000007` em toda
amostra, das quatro execuções. O desvio exige `state == 3`, que nunca acontece.

### Falsificada, e o que sobra de pé

A previsão registrada era "delta sempre zero, `n` subindo nas travadas". O delta nunca foi
calculado, então a hipótese **cai**.

O que ela deixa confirmado: as amostras trazem `count=0x00000000` e `mark_s3=0x00000000` em
todas as execuções. **`ctx->cop0_count` é de fato sempre zero** — o defeito da seção 17 é real
e continua valendo como defeito. Só não é o que trava o jogo.

E derruba junto a leitura de "laço em `mcGame::Execute`" da seção 16: o portão executa **7
vezes** na execução travada inteira. Se o código roda 7 vezes e o PC fica lá 60 de 60 quadros,
a thread não está girando — **está parada**.

### Onde ela para, de verdade

`ra=0x001a2760` nas amostras aponta o `jal` em `0x1a2758`, que é **`ageEndDraw(void)`**
(`0x52D7C0`). E os últimos eventos da thread principal na execução travada:

```
WaitSema:block] tid=1 sid=44 ... ra=0x529690    <- gfxPipeline::BeginFrame +0xA0
WaitSema:block] tid=1 sid=58 ... ra=0x398b28    <- ipcWaitSema +0x10   (ultimo)
SignalSema]     tid=8 sid=58 count=0->1 ret=58  <- DEPOIS do bloqueio
```

Depois desse bloqueio, na linha 103.821 de 104.311: **zero wakes para a tid=1, zero eventos de
qualquer tipo da tid=1**, e um `SignalSema` no mesmo sid vindo da tid=8.

**A trava pós-menu é a thread principal bloqueada em `ipcWaitSema`, no caminho de desenho, com
um sinal para aquele semáforo chegando depois e a thread nunca acordando.**

### Correções de leitura, minhas

1. `count=0->1` no `SignalSema` **não** é o defeito. É o comportamento normal de semáforo
   contador: `SignalSema` faz `count++` e `cv.notify_one()`, e o esperador tem predicado
   `count > 0 || deleted || forced || terminated` re-checado sob o mesmo mutex. Não é wakeup
   perdido clássico. Cheguei a ler assim e estava errado.
2. **Sid não é estável entre execuções.** Comparei o sid=58 da travada com o sid=58 de uma
   sadia antes de notar que as linhas de `CreateSema` diferem (`attr=0x3` contra `0x620000`) —
   são semáforos diferentes. Toda análise de sid tem de ficar dentro de uma execução.

### Candidatos que sobram, nenhum verificado

- Outro esperador consumiu o `count` antes da tid=1. O log do bloqueio diz `waiters=0` no
  momento em que ela entrou, mas isso é registrado antes do `sema->waiters++`.
- A tid=1 acordou do `cv` e ficou presa **depois**, no destrutor de
  `PS2Runtime::GuestExecutionReleaseScope`, que envolve a espera e reobtém um token global de
  execução do convidado. Isso explicaria não haver `WaitSema:wake` — ele é registrado depois
  do escopo fechar.

O escalonador determinístico está **fora**: depende de `MC3_DETERMINISTIC`, que a bateria não
seta, então o caminho `DetSchedMarkReadyWaitingOnSema` não roda.

### Próximo passo

Sonda no `WaitSema` registrando a saída do `cv.wait` **antes** do fecho do
`GuestExecutionReleaseScope`, e o valor de `sema->waiters` no momento do sinal. Isso separa os
dois candidatos em uma bateria.

## 19. A trava pós-menu é o token global de execução, não o semáforo

Bateria `cvscope`, 4 × 1200 s, com três marcadores novos: `WaitSema:cvout` emitido **dentro**
do `GuestExecutionReleaseScope`, logo após o `cv.wait` retornar; `WaitSema:scopeout` emitido
**depois** do escopo fechar; e `waiters` lido sob o mutex no `SignalSema`.

A r1 travou (`gsPrims=744333` congelado por 618 s). Os últimos eventos da thread principal:

```
WaitSema:block]  tid=1 sid=47 count=0 waiters=0 ra=0x398b28   <- ipcWaitSema
WaitSema:cvout]  tid=1 sid=47 count=1 waiters=1               <- ACORDOU
(nenhum WaitSema:scopeout para a tid=1, ate o fim do log)
```

**O lado do semáforo funcionou.** O sinal chegou, `count=1`, o predicado foi satisfeito, e o
`cv.wait` retornou. A thread morre **entre o `cvout` e o `scopeout`** — isto é, dentro de
`~GuestExecutionReleaseScope()`, que chama `PS2Runtime::reacquireGuestExecution`.

Esse destrutor faz, por `depth` vezes:

```cpp
m_guestExecutionWaiters.fetch_add(1u, ...);
m_guestExecutionMutex.lock();     // <-- aqui
m_guestExecutionWaiters.fetch_sub(1u, ...);
```

`m_guestExecutionMutex` é um mutex **global** que serializa a execução do convidado, no estilo
de um GIL. A thread principal fica presa nesse `lock()`.

### Não é fome de lock

A hipótese natural seria starvation: outra thread pegando e soltando o mutex em laço apertado.
Os dados dizem que não. Depois do `cvout` da tid=1, nas 634 linhas restantes:

| marcador | n |
|---|---:|
| `frame` | 619 |
| `SignalSema` | 4 |
| `WaitSema:wake` | 4 |
| `WaitSema:cvout` / `:scopeout` / `:block` | 2 cada |

**Todas as threads do convidado emudecem.** O que continua emitindo é o tracer de quadro, que
roda do lado do host. As tid=5 e tid=8 completam um ciclo `cvout`→`scopeout` cada — ou seja,
reobtêm o token — e depois somem.

Ou seja: alguém reobteve o token de execução e não o soltou mais. Não é disputa, é retenção.

### O que está estabelecido

- A thread principal acorda do semáforo corretamente e trava reobtendo o token global.
- Depois disso nenhuma thread do convidado progride; só o host segue.
- A `pc` da linha de frame fica em `0x1a2760` com `activeThreads=7` até o fim.

### O que não está

**Quem** segura o token e **por quê**. As candidatas são as tid=5 e tid=8, que foram as últimas
a reobtê-lo. Se uma delas entrou em laço do convidado que não faz syscall, ela segura o mutex
indefinidamente. Existe uma contramedida — `shouldPreemptGuestExecution()` solta o token a cada
64–100 arestas de retorno — então o caso interessante é um laço em que essa checagem não é
alcançada.

### Correções e ressalvas

- A leitura de "laço em `mcGame::Execute`" (seção 16) e a hipótese do COP0 Count (seção 17)
  estão ambas descartadas. O `pc` congelado em `0x1a2760` é a thread **parada**, e o ponto onde
  ela parou é o retorno do `jal ageEndDraw` — mas a parada em si não é no jogo, é no runtime.
- O `SignalSema` agora registra `waiters`. Nas linhas que inspecionei ele aparece com
  `waiters=0`, mas eram sinais anteriores ao bloqueio da tid=1 — não confundir com o sinal que
  de fato a acordou, cujo efeito se lê no `cvout` (`count=1 waiters=1`).

### Próximo passo

Sonda em `reacquireGuestExecution`: registrar quando a espera pelo `lock()` passa de um limiar,
com o tid do esperador, e registrar em `releaseGuestExecution`/aquisição qual tid detém o token.
Isso nomeia o retentor em uma bateria.

## 20. A preempção só existe em branch para trás dentro da função — 72% do corpus não tem nenhuma

Investigação estática enquanto o lote roda.

O gerador emite a cessão do token em uma condição única
(`code_generator.cpp`, `emitInternalTarget`):

```cpp
if (target <= sourcePc && !isCallLikeEdge)
{
    ss << "if (runtime->shouldPreemptGuestExecution()) {";
    ...
}
```

Isto é: **branch para trás, interno à função, que não seja chamada.** Função sem branch para
trás não recebe cessão nenhuma.

Contagem no corpus compilado: **4.446 de 15.832 arquivos (28%) têm a checagem.** Os outros
11.386 nunca soltam o token por conta própria — dependem de fazer syscall para cedê-lo.

Nas funções centrais desta investigação:

| função | checagens |
|---|---:|
| `datStreamer::Worker(void *)` | 3 |
| `mcGame::Execute(void)` | 4 |
| `datStreamer::Close(unsigned int)` | 1 |
| **`FUN_00322fd8`** | **0** |
| **`sub_00322ED0`** (chamador dele) | **0** |

`FUN_00322fd8` é exatamente onde o `pc` da **trava de streaming** fica parado — `0x322ffc`,
em 60 de 60 quadros amostrados na `semactl_r1`. Ele e o chamador somam 32 `goto` e nenhum
branch para trás que o gerador reconheça, logo nenhuma cessão.

### Hipótese unificadora, ainda não testada

Se uma thread do convidado entra em laço cujo caminho não passa por nenhum branch para trás
intra-função, ela **retém o mutex global de execução indefinidamente** e as demais param — que
é exatamente o quadro medido na seção 19: todas as threads do convidado emudecem e só o tracer
do host segue.

Isso explicaria **as duas travas com um mecanismo só**, e não como dois defeitos separados:

- **pós-menu:** a thread principal acorda do semáforo e trava tomando o token (medido).
- **streaming:** o `pc` parado em `FUN_00322fd8`, função sem cessão, e o worker sem conseguir
  rodar para concluir o pedido — o que deixaria o `busy` em 1 por consequência, não por causa.

Ressalva séria: um laço que atravessa chamadas normalmente tem branch para trás em **alguma**
função da cadeia. A ausência nessas duas não prova que a cadeia inteira não cede. E as duas
travas podem continuar sendo coisas distintas.

### O que o lote decide

Bateria `holder`, 14 × 1200 s (~4h40), com `guestexec-wait` emitido **antes** do `lock()`,
carregando o dono naquele instante. A assinatura é `wait` sem `got`, e a linha nomeia o
retentor. Sondas confirmadas emitindo na primeira execução, com balanço casado.

Previsão registrada: nas travadas haverá pelo menos uma thread com `wait` sem `got`, e o
`owner=` apontará uma thread que não faz syscall desde então. Se o `owner` for `-1` (token
livre) a hipótese cai e o problema é no próprio mutex, não em retenção.

Análise pronta em `work/scratch/analyze_holder.py`.

### Correção à seção 20: o gerador está certo, e a função não tem laço

Contei os branches para trás **reais**, descartando os `case 0x...: goto label_...` do
despachante de retomada no topo de cada função — que meu primeiro teste contou como fluxo e
não são:

| função | branches para trás reais | cessões |
|---|---:|---:|
| `mcGame::Execute(void)` | 4 | 4 |
| `datStreamer::Worker(void *)` | 3 | 3 |
| `FUN_00322fd8` | 0 | 0 |
| `sub_00322ED0` | 0 | 0 |

**Batem exatamente.** O gerador aplica a regra corretamente; o `FUN_00322fd8` não recebe cessão
porque não tem laço nenhum, não porque foi esquecido. A insinuação da seção 20 de que a
ausência ali era suspeita está errada.

O que isso muda: o `pc` parado em `0x322ffc` na trava de streaming **não é uma thread girando
sem ceder** — é uma thread parada, igual à `0x1a2760` da trava pós-menu. Os dois quadros ficam
mais parecidos, não menos, mas a explicação deixa de ser "esta função não cede" e volta a ser
"alguém retém o token", com o retentor ainda sem nome.

A estatística dos 28% continua de pé como fato do corpus, e continua sendo o risco estrutural
que ela é. Só não aponta para estas duas funções.

## 21. O retentor tem nome: a previsão confirma

Lote `holder`, 14 × 1200 s. **Quatro travas, todas pós-menu** (`deq/done` 2/2 em todas as 14 —
nenhuma trava de streaming desta vez). Taxa de 4 em 14, coerente com o histórico.

Nas quatro, a assinatura prevista aparece: thread com `guestexec-wait` e sem `got` posterior, e
a linha nomeia o dono.

| execução | parada no lock | dono |
|---|---|---|
| r1 | tid=1 | **tid=5** |
| r2 | tid=5 | **tid=8** |
| r4 | tid=1 e tid=5 | **tid=8** nas duas |
| r14 | tid=1 → dono 5; tid=5 → dono 8 | cadeia 1→5→8 |

A r14 mostra a cadeia inteira: a thread principal espera a 5, que espera a 8. **A retenção é
sempre da tid=5 ou da tid=8**, e a previsão registrada em `8fda69b` se cumpre.

### O que a retentora estava fazendo

Últimos eventos bem formados da tid=8 na r2, em ordem:

```
guestexec-wait]  tid=8 owner=5 ...      -> pede o token
guestexec-got]   tid=8                  -> obtem
WaitSema:scopeout] tid=8 sid=35 count=1
WaitSema:wake]   tid=8 sid=35 ra=0x5476b0   (DelayThread)
WaitSema:wake]   tid=8 sid=6  ra=0x398b28   (ipcWaitSema)
SignalSema]      tid=8 sid=6 count=0->1 ra=0x398b50
(nada mais)
```

Ela **pega o token, faz trabalho de semáforo, sinaliza, entra em código do convidado e não
volta**. O token só é solto quando a função despachada retorna ou quando a thread faz syscall
bloqueante — nenhuma das duas acontece.

### O que foi descartado no caminho

- **Não é primitiva bloqueante esquecida.** `WaitSema` (`Sync.cpp:422`) e `WaitEventFlag`
  (`Sync.cpp:808`) têm `GuestExecutionReleaseScope`; a espera de vsync
  (`Interrupt.cpp:501`) também. As bloqueantes soltam o token corretamente.
- **Não é cessão que não cede.** O gerador emite `return;` dentro do
  `if (shouldPreemptGuestExecution())`, devolvendo ao laço de despacho, que envolve cada
  função em `GuestExecutionScope` — adquire antes de `fn(...)` e solta ao sair do escopo.
  O mecanismo está correto.

Sobra: a tid=8 está dentro de uma função do convidado que não retorna e não faz syscall.

### Armadilha de análise que quase estragou o resultado

A primeira leitura deu `tid=5114`, `tid=25265`, `tid=54124965` e `owner=-1` na maioria — e
`owner=-1` era justamente o ramo que falsificaria a hipótese. **Era corrupção de parser**: o
trace é escrito por várias threads sem trava e as linhas se intercalam no meio umas das outras,
fundindo campos (`tid=5` mais o `126` de outra linha vira `tid=5126`).

Duas correções foram necessárias, não uma:

1. **Casar linha inteira, ancorada em início e fim.** Fragmento intercalado não casa e sai da
   amostra. É a mesma disciplina do `find_divergence.py`.
2. **Decidir por ordem, não por contagem.** Com linhas descartadas, `wait_n > got_n` deixa de
   valer — sobra comparar a linha do último `wait` com a do último `got`. Contando, a r2
   aparecia como "nenhuma thread parada"; por ordem, ela mostra a tid=5 parada com dono 8.

O `owner=-1` que restou (r14, tid=15) é da linha 67.390 de 134 mil — evento antigo, não o
deadlock final.

### Próximo passo, já em execução

Sonda `ownerPc`: o laço de despacho grava o PC de cada função que executa, por thread, e a
linha `guestexec-wait` passa a carregar **onde o dono está**, não só quem é. Bateria `ownerpc`,
7 × 1200 s, rodando.

## 22. As threads criadas rodam por outro laço de despacho

Bateria `ownerpc`, 7 × 1200 s: duas travas (692 s e 354 s de `gsPrims` plano). A assinatura da
retenção reaparece — tid=1 e tid=5 paradas no lock, dono tid=8 — mas o campo novo saiu
**`ownerPc=0x000000`** em todas, e `selfPc` só funcionou para a tid=1.

Motivo: **há dois laços de despacho.** O de `ps2_runtime.cpp:2502`, que eu instrumentei, e o de
`Thread.cpp:481`, por onde correm as threads criadas — exatamente as tid=5 e tid=8, que são as
retentoras. A sonda estava no laço errado para o caso de interesse.

Os dois usam `GuestExecutionScope` corretamente, cada um envolvendo a chamada da função
recompilada. Não é aí o defeito.

### O que o laço das threads já dizia, de graça

`Thread.cpp` tem um detector de spin embutido: conta despachos consecutivos no mesmo `pc` e
emite `[StartThread] id=N spinning at pc=0x...`. **Ele não dispara nenhuma vez nas execuções
travadas.**

Isso é informativo: a retentora **não está girando sobre despachos**. Se estivesse, o laço
iteraria e o detector veria o mesmo `pc` repetido. Ela está presa **dentro de uma única chamada
de função recompilada que nunca retorna** — e é por isso que o token nunca é solto, já que o
escopo só fecha quando `step(...)` retorna.

### Correção instalada

O registro do `pc` despachado agora acontece nos dois laços. Detalhes que custaram tempo:

1. A função de registro estava no **namespace anônimo** de `ps2_runtime.cpp`, o que lhe dá
   linkage interna e a torna invisível para `Thread.cpp`. Movida para escopo global.
2. A declaração `extern` estava em escopo de bloco **dentro de um namespace**, o que declara
   `ps2_syscalls::Ps2RecordDispatchPc` — símbolo que não existe. Movida para escopo de arquivo.
3. Nada disso passa por header: pôr a declaração em `ps2_runtime.h` obrigaria a recompilar os
   15.831 arquivos do corpus por causa de uma função de diagnóstico.

Um erro meu de processo: o `grep` que eu usava para checar o link casava com a palavra `ERROR`,
então a cadeia seguia e o commit acontecia **com o exe não linkado**. O padrão certo é casar a
linha de sucesso, não filtrar por uma palavra que aparece nos dois casos.

### Bateria em curso

`ownerpc2`, 8 × 1200 s, com o registro nos dois laços. A linha `guestexec-wait` deve agora
trazer `ownerPc` real, nomeando a função em que a retentora entra e não sai.

## 23. Correção de método: a assinatura sozinha não valia; a duração vale

Bateria `holderpc`, 6 × 1200 s com a sonda corrigida: **nenhuma trava** (cinco sadias e uma
com 62 s de plano, no limiar). Mas ela expôs um vício no meu critério.

A assinatura que usei na seção 21 — thread com `guestexec-wait` e sem `got` posterior —
**aparece também em execução sadia**. É esperado: ao matar o processo no fim do tempo, quem
estiver esperando o token naquele instante fica com um `wait` sem par. Nas sadias `r1`, `r2`,
`r4` e `r5` desta bateria ela aparece, e na única com plano alto não aparece.

Refiz a verificação nas sadias do lote `holder` e a assinatura está lá também. **A conclusão
da seção 21 foi tirada de um artefato de fim de execução.**

### O que separa de verdade

Não a presença da espera, e sim **quanto tempo ela dura**. Numa trava a thread fica esperando
o resto da execução; numa sadia a espera é do último instante.

| execução | `gsPrims` plano | espera do tid=1 | dono |
|---|---:|---:|---|
| `holder_r1` | 218 s | **219 s** | tid=5 |
| `holder_r14` | 105 s | **106 s** | tid=5 |
| `holder_r4` | 287 s | **288 s** | tid=8 |
| sadias (7 de 14) | 0–6 s | 0 s | — |

**As duas medidas casam com 1 segundo de erro, em três execuções independentes.** São grandezas
obtidas por caminhos diferentes — uma do contador de primitivas, outra do relógio de espera do
mutex — e coincidirem nessa precisão três vezes não é acaso. A conclusão sobrevive, com um
critério melhor do que aquele com que foi tirada.

Ressalvas honestas: a `holder_r2` travou 579 s e **não** exibe a espera longa, e a sadia
`holder_r9` exibe 476 s de espera com dono `-1`. Nos dois casos a explicação provável é perda
de linha por intercalação — o log é escrito sem trava e linhas somem. O critério tem falso
negativo e falso positivo; o que o sustenta é a coincidência de três medições, não cada caso
isolado.

### Terceira camada da mesma armadilha

Foi preciso ainda um filtro de threads reais. Linha corrompida cria `tid` fantasma
(`tid=541`, `685`, `895`) com uma única espera e nenhum `got`, que o critério de duração lê
como espera eterna. Só entram na conta threads que aparecem em pelo menos 20 linhas `got` bem
formadas.

Esta é a terceira vez nesta investigação que a intercalação do log estraga uma análise —
primeiro fundindo campos, depois desequilibrando contagens, agora inventando threads. Qualquer
análise nova deste log precisa, desde o início: casar linha inteira ancorada, decidir por
ordem/duração e não por contagem, e filtrar tids por frequência.

### O que ainda falta

Uma trava capturada **com o `ownerPc` funcionando**. O lote `holder` tinha travas mas ainda não
tinha a sonda; o `ownerpc` tinha a sonda pela metade (só o laço principal); o `holderpc` tem a
sonda completa e validada — `netManagerThread::MainLoop`, `Stream::Open`, `zipHandle::Read`
saem com nome — mas não travou.

## 24. Causa raiz da trava pós-menu: aresta de chamada para trás sem cessão

Bateria `holderpc2`. A r1 travou (344 s de `gsPrims` plano) **com a sonda completa**, e os
últimos eventos de execução do convidado são:

```
guestexec-got]  tid=8
guestexec-wait] tid=5 owner=8 ownerPc=0x1f9610 selfPc=0x42b8c8 waiters=1 depth=1
```

Nada depois. `0x1F9610` é `netManagerThread::MainLoop(void) +0x50`, cuja entrada é `0x1F95C0`.
A tid=8 entra nessa função e não sai, segurando o token de execução do convidado.

### O defeito, no gerador

`sub_001F95C0` tem **duas** arestas para trás e **uma só** cessão:

| linha | aresta | cessão |
|---|---|---|
| 289 | `goto label_1f95e8` (laço comum) | **sim** |
| 405 | `goto label_1f95c0` (entrada da função) | **não** |

A da linha 405 vem disto:

```c
// 0x1f9670: 0xc07e570  jal  func_1F95C0     <- chamada da funcao para ela mesma
ctx->pc = 0x1F9670u;
SET_GPR_U32(ctx, 31, 0x1F9678u);             <- grava endereco de retorno
ctx->pc = 0x1F95C0u;
goto label_1f95c0;                           <- e salta para a entrada
```

E a regra do gerador, em `code_generator.cpp`:

```cpp
if (target <= sourcePc && !isCallLikeEdge)
{
    ... if (runtime->shouldPreemptGuestExecution()) { return; } ...
    goto label_...;
}
else
{
    goto label_...;      // <- sem cessão
}
```

**A exclusão `!isCallLikeEdge` é o defeito.** Ela existe para não ceder em chamada — o que faz
sentido quando a chamada é uma chamada. Mas quando o alvo cai dentro da própria função, o
gerador não emite chamada: emite `goto` para trás. O resultado é um **laço, com a cessão
suprimida pela regra que supunha que ali não haveria laço**.

Consequência: a thread gira dentro de `netManagerThread::MainLoop` sem nunca devolver o token,
e todo o resto do convidado — inclusive a thread principal, no `ageEndDraw` — congela. Isso
explica o quadro inteiro da seção 19 em diante: o semáforo funciona, a thread acorda, e morre
esperando um token que o dono nunca solta.

### Por que as seções anteriores não viam

A contagem "branches para trás == cessões" da correção à seção 20 batia nas quatro funções que
examinei porque nenhuma delas tinha aresta de chamada para trás. É um caso que só aparece em
função que chama a si mesma, ou que salta para trás por `jal`.

### O que isto ainda não estabelece

- **Se a tradução dessa recursão está correta em si.** O `goto` para a entrada não empilha
  quadro: o `ra` é gravado em `$31` mas a função reentra por cima do próprio estado. Se o
  jogo esperava recursão de verdade, a semântica está errada além da cessão. Não verifiquei.
- **Quantas funções do corpus têm o mesmo padrão.** A varredura ficou para depois para não
  disputar I/O com a bateria em curso.
- **Se a trava de streaming tem a mesma causa.** Nada aqui a liga a ela.

### Correção candidata, não aplicada

Emitir a cessão sempre que `target <= sourcePc`, inclusive em aresta de chamada, já que nesse
caso o gerador produz `goto` e não chamada. Antes de aplicar convém checar o item 1 acima: se a
tradução da recursão estiver errada, ceder o token trata o sintoma e deixa o defeito.

## 25. Bateria fechada: as duas travas são da mesma thread

`holderpc` e `holderpc2`, 12 execuções ao todo, **2 travas**.

Critério final, e o melhor até agora: **quanto tempo de jogo passa depois da última espera de
token**. Numa trava o convidado emudece e os quadros continuam; numa sadia a última espera
coincide com o corte e não há tempo depois.

| execução | `gsPrims` plano | mudo depois | dono | `ownerPc` |
|---|---:|---:|---:|---|
| `holderpc2_r1` | 344 s | **344 s** | tid=8 | `netManagerThread::MainLoop +0x50` |
| `holderpc_r6` | 62 s | **63 s** | tid=8 | `netManagerThread::UpdateStatistics +0x1E4` |
| outras 10 | 0–5 s | 0–6 s | vários | — |

As duas medidas são independentes — uma do contador de primitivas, outra do relógio de espera —
e casam nas duas travas.

**As duas retenções são da tid=8, e as duas caem no `netManagerThread`.** Isso restringe muito o
alvo: não é um defeito espalhado pelo corpus, é uma thread específica que não devolve o token.

Confirmação do defeito na `MainLoop` (`sub_001F95C0`): 2 arestas para trás, **1 delas vinda de
`jal`**, e 1 cessão. A aresta de chamada é a que fica sem ceder.

### Erro de script que atrasou a leitura

O primeiro critério de duração pareava `wait` e `got` comparando **tick**, não ordem de linha.
Quando os dois caem no mesmo tick — que é exatamente o caso no instante do travamento — o
`got` anterior invalidava o `wait` seguinte e a trava aparecia como espera de 0 s. Foi o que fez
a `holderpc2_r1` passar por sadia numa primeira leitura, e provavelmente também a
`holder_r2` da seção 23. Parear por ordem; usar tick só para medir idade.

### Ressalva que continua valendo

Ver `ownerPc=0x1F9610` no fim de uma execução **não** indica trava: aparece em execuções sadias
também, porque a `MainLoop` roda o tempo todo. O que separa é o silêncio depois.

### Estado para decidir o próximo passo

- **Causa provável, localizada:** aresta de chamada para trás sem cessão, em função do
  `netManagerThread`, thread que retém o token nas duas travas capturadas.
- **Não verificado:** se a tradução dessa recursão está correta além da cessão; quantas funções
  do corpus têm o padrão; se a trava de streaming tem a mesma origem.

## 26. A correção não resolveu: `ownerPc` não é onde a thread está

Bateria `yieldfix`, 2 × 1200 s com a correção da aresta compilada e confirmada no binário
(o manifesto confirma que o objeto veio da versão corrigida, e a função tem 2 cessões).

**A trava reproduziu idêntica:** `yieldfix_r1`, 234 s de `gsPrims` plano, 235 s de silêncio,
dono tid=8, `ownerPc=0x1F9610` — a mesma `netManagerThread::MainLoop +0x50`.

### O erro de leitura

`ownerPc` é o PC que o **despachante** procurou, ou seja, a função mais externa que a thread
está executando. Chamadas dentro do código recompilado são chamadas C++ diretas, não passam
pelo despachante. Então a thread pode estar **muitos quadros abaixo**, dentro de qualquer
função da árvore de chamadas da `MainLoop`.

Eu tratei "a função despachada é a `MainLoop`" como "a thread gira dentro da `MainLoop`". A
evidência nunca disse isso. A aresta sem cessão que achei na `MainLoop` era real, mas não há
nada que a ligue ao ponto onde a thread efetivamente trava.

### O teste de mecanismo também estava mal desenhado

Contei `guestexec-got` da tid=8 antes e depois: 30,6 / 17,8 / 22,8 por minuto contra
14,3 / 34,3. Sem diferença, faixas sobrepostas. Mas o marcador só dispara em
`reacquireGuestExecution`, depois de syscall bloqueante; a cessão corrigida passa por `return`
ao despachante e por `enterGuestExecution`, **que não tem sonda**. O contador que escolhi não
podia mostrar o efeito, existindo ele ou não.

### O que fica

- **A correção do gerador continua certa** por mérito próprio: aresta para trás emitida como
  `goto` sem cessão é laço que não cede, e isso é defeito real em 27 funções. Fica aplicada.
- **Ela não é a causa desta trava.** A causa continua desconhecida.
- **O que se sabe da retentora:** tid=8, sempre; função despachada `netManagerThread::MainLoop`
  ou `UpdateStatistics`; presa dentro de uma chamada que não retorna; nenhum syscall depois.

### Próximo passo, agora com a sonda certa

Falta o PC **de dentro** do convidado, não o do despacho. O contexto da thread (`ctx->pc`) é
atualizado pelo código recompilado a cada instrução traduzida, então amostrá-lo do lado de fora
— por exemplo, quem espera o token lê o `ctx` do dono — diz em que função a retentora está de
verdade, e não só por onde ela entrou.

## 27. O PC vivo também não discrimina — e por quê

Bateria `livepc`, 6 × 1200 s, com o `ctx->pc` do dono sendo lido pelo esperador. Uma trava
(r1, 72 s), e o campo novo saiu **`ownerLivePc=0x5469E0`**, que é `WaitSema`.

Teste de especificidade, que faltou nas rodadas anteriores: esse mesmo valor aparece **1.287
vezes na travada, 1.222 e 1.017 nas sadias**. Não discrimina nada.

A causa é estrutural: `ctx->pc` é escrito pelo código recompilado a cada instrução traduzida.
Quando a thread entra num stub do runtime, o campo **congela no endereço do syscall** e fica
lá enquanto o C++ executa. Ler esse campo de fora responde "o dono está dentro de um syscall",
que é verdade quase sempre, para qualquer thread.

### O que isso ainda assim estabelece

**A retentora não está girando em código do convidado.** Ela está parada dentro de um stub do
runtime, e segura o token enquanto isso. Isso muda o alvo: não é laço traduzido, é caminho de
runtime que bloqueia sem devolver o token.

Reforça, aliás, o resultado negativo da seção 26 — a correção da aresta de cessão não podia
resolver, porque o problema nunca esteve em laço de código gerado.

### Terceira tentativa de localização, e o que ela usa

`pc` congela no syscall, mas o `ra` do contexto do convidado nomeia **quem chamou** o syscall.
Campo `ownerRa` adicionado e compilado.

Antes de tratar qualquer valor dele como localização, o mesmo teste tem de ser feito: contar
quantas vezes o endereço aparece em execução sadia. Duas vezes seguidas eu tomei por
localização um campo que estava em toda parte — `ownerPc` na seção 24 e `ownerLivePc` aqui.

### Alternativa, se o `ra` também não discriminar

Deixar de inferir pelo último registro e detectar a retenção enquanto acontece: gravar o
instante em que o token é adquirido e ter uma verificação periódica que dispare quando ele
estiver retido por mais de alguns segundos, despejando dono, `pc`, `ra` e `sp` naquele momento.
Isso separa retenção real de leitura de fim de log, que é a confusão que atrapalhou desde a
seção 21.
