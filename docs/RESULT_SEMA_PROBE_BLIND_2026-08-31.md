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
