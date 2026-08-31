# RESULT — a bifurcação dos dois desfechos, localizada em uma chamada — 2026-08-31

## Resultado

**Os dois desfechos se separam numa única chamada: `jal func_320B38` em `0x323024`.**

No desfecho bom ela retorna e a execução segue. No desfecho ruim ela **não retorna**, e
tudo o que vem depois — iluminação, laço de despacho virtual, desenho de modelo, DMA do
VIF0, troca de menu — simplesmente nunca acontece.

```asm
0x323020:  sb    $v0, 0xC($s0)     # obj->campo_0C = 1
0x323024:  jal   func_320B38       # <- a bifurcacao
0x323028:  addiu $a2, $zero, 0x1   # (delay slot)
0x32302c:  lw    $v1, 0x3C($s0)    # <- o desfecho ruim nunca chega aqui
```

Argumentos da chamada: `a0 = obj->campo_6B4`, `a1 = 1`, `a2 = 1`, `f12 = 1.0f`.

## A evidência

A instrumentação de estágios em `FUN_00322fd8` já existia. Os dois desfechos percorrem
**exatamente os mesmos estágios com exatamente os mesmos valores** até `0x323024`:

| estágio | ruim | bom |
|---|---|---|
| `0x322fd8` | v0=`0x00610000` | v0=`0x00610000` |
| `0x322ffc` | v0=`0x016d671a` | v0=`0x016d671a` |
| `0x323010` | v0=`0x00000001` | v0=`0x00000001` |
| `0x323024` | flag=01, v0=`0x00000001` | flag=01, v0=`0x00000001` |
| `0x32302c` | — | v0=`0x00000002` |
| `0x323084` | — | v0=`0x00000003` |
| `0x323094` | — | v0=`0x016d6f00` |
| `0x3230cc` | — | v0=`0x016f5b60` |

E o desfecho ruim nunca produz uma segunda amostra: a função é entrada uma vez, avança
até a chamada, e para. `0x32302c` é o endereço de retorno daquela chamada (o `jal` está
em `0x323024`, o delay slot em `0x323028`), então não alcançá-lo é não retornar.

Isso também explica o `pc=0x322ffc` que o amostrador de quadro reporta no desfecho ruim,
60 de 60 quadros: `0x322ffc` é o endereço de retorno de um `jal` anterior, em `0x322ff4`.
O PC do guest fica parado ali porque a thread está presa mais abaixo.

## O que sobra da fase, no desfecho ruim

Só o blend de câmera. Chamadores distintos de `powf`, mesma duração de corrida:

| origem | bom | ruim |
|---|---:|---:|
| `0x1faf30` (blend de câmera) | 368 | 40 |
| `0x259ca8` (`mcLight::GetColor`) | 39 | **0** |
| `0x259e0c` (`mcLight::GetColor`) | 24 | **0** |
| `0x2b6544` (helper de escala) | 1 | **0** |

A iluminação nunca roda. É a mesma `mcLight::GetColor` de `0x259D60` onde o NaN do `sqrt`
foi rastreado ontem — só que agora o problema não é o valor que ela calcula, é ela nunca
ser chamada.

E o laço de despacho virtual em `FUN_004225d8`, que no desfecho bom dispara 192 vezes para
alvos variados (`0x420f38`, `0x33a838`, `0x33feb0`, `0x34ad68`…), dispara **zero** vezes.

## Como foi encontrado

Subindo a cadeia de chamadas pelo `$ra`, um degrau por vez, cada degrau custando uma
batelada de corridas:

```
func_339278 (mc3-menu-change)
  <- sub_0033A710 / FUN_0033a838   (as duas traducoes duplicadas)
     <- FUN_004225d8               (jalr $v0, metodo virtual, vtable[slot 9])
        <- ...                     (aqui o rastro por $ra ficaria caro)
```

O último degrau não foi subido por sonda nova, e sim de graça: comparando **quais
marcadores existem** em cada log e ordenando pela primeira ocorrência. O primeiro evento
exclusivo do desfecho bom era a própria sonda do vtable; um passo antes dela, no log, o
amostrador de estágios de `FUN_00322fd8` já mostrava os dois ramos separando.

## O que estava escondendo isso

`FUN_00320b38` tinha instrumentação de progresso — e ela emitia rastros **idênticos** nos
dois desfechos, 64 amostras cada, terminando no mesmo estágio. Parecia evidência de que a
função se comporta igual. Era um teto:

```c
if (g_mc3320b38TraceEmitCount >= 64u) return;
```

O teto se esgotava antes da chamada que interessa. Levantado para 4000.

## Hipóteses descartadas no caminho

Três, e vale registrar todas, porque cada uma parecia boa:

1. **Livelock em `FUN_0054cb58`.** Duas threads girando em caminhada de lista encadeada.
   Instrumentado com deteccão de ciclo: em quatro corridas do desfecho ruim a sonda não
   disparou uma vez. O laço nem é alcançado. Vinha de uma única corrida de 1800 s.
2. **O blend de câmera não converge.** Roda igual nos dois desfechos, ciclando `s4` de 1 a
   4 com o ratio decaindo. A diferença é só que no ruim ele é a única coisa acontecendo.
3. **O portão do `mc3-menu-change`.** Três condições (`estado==3` ou `campo4==7`, depois
   `campo_E0 != 1`). Nenhuma chega a ser avaliada no desfecho ruim — a função nem é
   entrada — e quando são, passam: `fieldE0=41` contra a condição `!= 1`.

## Próximo passo

Achar onde dentro de `func_320B38` a execução para. Com o teto em 4000 a instrumentação
existente passa a cobrir a chamada de `0x323024`, e o estágio em que o rastro do desfecho
ruim termina é a resposta.

## Nota de método

Duas armadilhas custaram caro nesta madrugada, as duas específicas de recompilador com
retomada por PC:

- **Instrumentar uma instrução não garante observá-la.** A função é retomada pelo
  despacho no meio do corpo. Sondas em `0x33acac` ficaram mudas em corridas que
  comprovadamente executam a chamada quatro instruções depois, porque o guest reentrava
  em `label_33accc`, entre as duas. Sonda confiável é em entrada de função ou em ponto de
  junção.
- **23,6% das funções geradas têm tradução duplicada**, então sondar uma cópia pode não
  sondar o código que roda. Ver `RESULT_DUPLICATE_TRANSLATIONS_2026-08-31.md`.
