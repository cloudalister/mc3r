# RESULT — o fundo da bifurcação: espera por flag que nunca libera — 2026-08-31

## Resultado

**O desfecho ruim é uma thread presa num laço de espera em `func_4323E8`, aguardando o
`busy` de uma entrada de pool que nunca chega ao estado que a libera.**

```
stage=0x432450 loop=11 block=1 index_v0=1
poolBase=0x006771e0 poolEntry=0x006771f0
busy=0x00000001 current=0x00000002 mask=0x00000010 flag=1
```

O laço alterna entre os estágios `0x432450` e `0x432458`, relendo `busy`.

| | desfecho ruim | desfecho bom |
|---|---|---|
| valores de `busy` observados | `0`, `1` | `0`, `1`, **`2`** |
| saída do laço | nunca (`loop` chega a 80+) | sai e segue para `0x4324b8` |

No desfecho bom o laço termina quando `busy` chega a `0` no estágio `0x432464`, e logo
adiante `busy` vale `2`. No ruim `busy` nunca passa de `1`.

## A cadeia completa, da bifurcação até o fundo

Cinco níveis, todos confirmados por instrumentação que já existia no projeto:

```
FUN_00322fd8
  0x323024  jal func_320B38        <- a bifurcacao: no desfecho ruim nao retorna
    0x320b64  jal func_320C60
      0x320e9c  jal func_42E8A0    (a0 = 0x6C2E10)
        0x42e8a8  jal func_430C90  (invólucro de 6 instrucoes)
          0x430cd0  jal func_4323E8
            laço em 0x432450 / 0x432458: espera busy da entrada 0x6771f0
```

Cada nível foi confirmado do mesmo jeito: o marcador de progresso do desfecho bom alcança
o endereço de retorno da chamada, e o do desfecho ruim não. Os endereços de retorno são
`0x32302c`, `0x320b6c`, `0x320ea4`, `0x42e8b0` e `0x430cd8`.

## O que isto não é

O processo **não morre**. Depois que a thread trava, o log segue com
`mc3-streamer-worker-dequeue`, `sceSifSetDma`, `sif-command-compat` e outros marcadores de
progresso. As outras threads continuam. É uma thread esperando um recurso.

E não é lentidão: no desfecho ruim a iluminação, o laço de despacho virtual, o desenho de
modelo e a troca de menu **nunca acontecem nenhuma vez**, porque toda essa fase está
abaixo da chamada que não retorna.

## O que fazer com isso, e o que não fazer

A regra 2 do projeto — **nunca injetar `SignalSema`, conclusão só pelo produtor legítimo**
— se aplica exatamente aqui. Forçar `busy` a zero destravaria a thread e produziria um
jogo que parece funcionar, escondendo o defeito real. A pergunta certa é **quem deveria
mudar o `busy` dessa entrada de pool, e por que não muda**.

Como `busy` transita `1 → 0 → 2` no desfecho bom, o produtor existe e funciona às vezes.
Isso é consistente com conclusão por interrupção ou por DMA, que é território de corrida —
e casa com o não-determinismo ser de escalonamento, não de dado.

## O que ainda não está medido

- **n=1 de cada lado** para os níveis mais profundos da cadeia. A comparação de `4323E8`
  saiu de uma corrida ruim e uma boa. Os níveis de cima têm mais amostras (2 ruins e 3
  boas), e todos concordam, mas o fundo precisa de repetição.
- **Quem escreve em `busy`.** Não rastreado. É o próximo passo, e não é caro: uma sonda
  de escrita no endereço `0x6771f0 + offset do busy` diz quem toca nele e quando.
- **O que `mask=0x10` e `current=2` significam.** Há aritmética de bitmask no laço que não
  foi lida.

## O que estava escondendo

`FUN_00320b38` tinha instrumentação com teto de 64 emissões, esgotado antes da chamada que
interessa. Os dois desfechos produziam 64 amostras idênticas terminando no mesmo estágio,
o que lia como "esta função se comporta igual nos dois". Teto levantado para 4000, e a
diferença apareceu na primeira corrida.

Vale como regra: **instrumentação com teto mente por omissão.** Um rastro que termina no
mesmo lugar nos dois lados pode ser evidência de igualdade ou de teto, e os dois casos são
indistinguíveis sem olhar o código da sonda.
