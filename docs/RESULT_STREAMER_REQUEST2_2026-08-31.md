# RESULT — a causa raiz: a segunda requisição de streaming nunca conclui — 2026-08-31

> **Nomes reais** (coluna `alpha_name` do `retail_symbol_port.csv`, quarta coluna — a
> segunda é só o `FUN_` do Ghidra):
>
> | endereço | nome |
> |---|---|
> | `0x320B38` | `mcFlash::Update(bool, bool, float)` |
> | `0x320C60` | `mcFlash::UpdateLoading(bool)` |
> | `0x42E8A0` | `datPaging::EndStream(datStreamerInfo&, bool)` |
> | `0x430C90` | `datRscBuilder::EndStream(datStreamerInfo&, bool)` |
> | `0x4323E8` | `datStreamer::Close(unsigned int)` |
> | `0x398C60` | `ipcSleep(unsigned int)` |
> | `0x4320E0` | `datStreamer::Read(unsigned, void*, unsigned, unsigned, ipcSemaTag*)` |
> | `0x4225D8` | `uiMaster::Update(void)` |
> | `0x33A710` | `mcMenuShell::AnyListsActive(bool)` |
> | `0x339278` | `mcMenuShell::ChangeState(MenuStates)` |
> | `0x259D60` | `mcLight::GetColor(const Vector3&, Vector3&)` |
>
> Em português: **o jogo trava na tela de carregamento**, esperando um recurso que nunca
> termina de chegar, e por isso a troca para o menu nunca acontece.


> **Hipótese descartada depois (2026-08-31, medida):** o laço de transferência do worker em
> `0x431f98` (`s1 -= s0; bnez s1`, que só termina se o restante bater exatamente zero) não
> é o culpado. Sonda ali dispara **zero** vezes nos dois desfechos — aquele caminho não é
> executado.


## Resultado

**O worker de streaming desenfileira duas requisições nos dois desfechos, e no desfecho
ruim conclui apenas a primeira.** A segunda fica pendente para sempre; o `busy` da entrada
de pool que ela ocupa nunca zera; a thread que espera esse `busy` dorme indefinidamente; e
toda a fase do jogo que vem depois dela nunca começa.

Separação perfeita em 5 execuções:

| marcador | ruim (3) | bom (2) |
|---|---:|---:|
| `mc3-datstreamer-read` | 2 | 2 |
| `mc3-streamer-worker-dequeue` | 2 | 2 |
| **`mc3-streamer-worker-done`** | **1** | **2** |
| `mc3-streamer-worker-park` | 2 | 3 |

A sequência é idêntica nos dois até o fim:

```
park 1 -> read 1 (handle=0, dest=0x01ea6600, offset=0x15000) -> dequeue 1
       -> done 1 (entry=0x006771e0) -> park 2
       -> read 2 (handle=1, dest=0x01d28700, offset=0x170800) -> dequeue 2
       -> [bom] done 2 (entry=0x006771f0) -> park 3
       -> [ruim] nada
```

E `entry=0x006771f0`, que o desfecho bom conclui no `done 2`, é **exatamente** a entrada
de pool que a outra thread fica esperando.

## O laço de espera, lido

Não é spin cego. É polling com sono:

```asm
0x432444:  lw    $v0, 0xC($s0)     # v0 = entry->campo_0C
0x432448:  beqz  $v0, sai          # se zerou, sai
0x432450:  jal   func_398C60       # dorme
0x432454:  addiu $a0, $zero, 0xA   # (delay) argumento = 10
0x432458:  lw    $v0, 0xC($s0)     # rele
0x43245c:  bnez  $v0, volta        # ainda ocupado, dorme de novo
```

`while (entry->campo_0C != 0) dorme(10);` — o campo fica em `0x6771fc`.

## O que acontece depois do `dequeue 2`, nos dois lados

| | ruim | bom |
|---|---:|---:|
| linhas restantes no log | 167 | 3.133 |
| `mc3-cdvd-rpc` | 18 | — |
| `sceSifSetDma` | 19 | — |
| `mc3-vtcall` | 0 | 192 |
| `mc3-camblend-ratio` | — | 349 |

No desfecho ruim a leitura **é emitida**: continuam saindo `mc3-cdvd-rpc` e `sceSifSetDma`
depois do dequeue. O que não volta é a conclusão. No bom, o `done 2` destrava tudo e a
fase inteira roda.

## Correção de uma leitura errada, no caminho

Cheguei a afirmar que o semáforo da requisição era sinalizado e a thread acordava, com
base em três linhas de `sid=155` (0x9b, o valor que aparece como `sema=` na requisição).
Errado: aquelas linhas estão em **3071–3088**, no boot, e o `dequeue 2` está na linha
**20788**. Casei pelo número sem olhar o tempo. Não há relação; a coincidência é que
existe um semáforo de id 155 usado cedo no boot.

## Onde isto encaixa nas regras do projeto

A regra 2 — **nunca injetar `SignalSema`, conclusão só pelo produtor legítimo** — é
exatamente o que impede o atalho aqui. Zerar `0x6771fc` na marra, ou sinalizar a conclusão
à mão, destravaria a thread e produziria um jogo que parece funcionar escondendo o defeito.

E a regra 1 — **despacho SIF por (server, fno), `payloadAddr` nunca é chave** — é o
território onde a resposta provavelmente está: a conclusão da segunda leitura tem de vir
pela via SIF/CDVD, e não vem.

## Próximo passo

Comparar, entre um desfecho e outro, o par (server, fno) e o ciclo de vida das requisições
CDVD emitidas depois do `dequeue 2`. As 18 `mc3-cdvd-rpc` do desfecho ruim são a evidência
mais próxima: se elas repetem o mesmo pedido, é retentativa sem resposta; se avançam, a
resposta chega e é a entrega ao worker que se perde.

## Nota de medição

Modo janela roda **8,6× mais devagar** que headless: 207 s de relógio para 24 s de tempo
de jogo, contra ~1 tick por 1/60 s em headless. Qualquer comparação que misture os dois
modos em base temporal é inválida. Os contadores de desfecho não mudam — eles são função
do ramo, não da duração — mas o tempo para chegar neles muda por quase uma ordem de
grandeza.
