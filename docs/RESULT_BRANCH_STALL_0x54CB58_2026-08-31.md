# RESULT — o que escolhe o desfecho: duas threads girando em lista encadeada — 2026-08-31

## Resultado

**O desfecho ruim é um livelock de duas threads em caminhada de lista encadeada**, nas
funções vizinhas `FUN_0054cb58` e `sub_0054CCE8`. O jogo não fica "mais lento" no desfecho
ruim: ele nunca troca de menu, nunca desenha modelo, nunca encerra.

```
[boot-trace:thread-heartbeat] id=8 steps=2097152 pc=0x54cc08 ra=0x54d4cc
```

- thread **8** para em `0x54cc08`, dentro de `FUN_0054cb58` (0x54cb58–0x54cce8) — 339 batimentos
- thread **5** para em `0x54cd18`, dentro de `sub_0054CCE8` (0x54cce8–0x54cd70) — 277 batimentos

As duas instruções são o mesmo padrão:

```asm
0x54cc08:  lw    $a2, 0x0($a2)     # a2 = a2->next
0x54cc0c:  beqz  $a2, +0xC         # sai quando a lista acaba

0x54cd18:  lw    $a1, 0x0($t0)     # a1 = t0->next
0x54cd1c:  beql  $a1, $zero, +0xA  # sai quando a lista acaba
0x54cd20:  sw    $t0, 0x4($a2)     # (delay slot) escreve de volta na lista
```

Caminhada de lista que nunca alcança o `NULL`, em duas threads ao mesmo tempo, e pelo
menos uma delas **escrevendo** na estrutura enquanto anda. Nas duas funções há, logo
acima, aritmética de tamanho com `sltu` e a constante `0x7333`, o que sugere busca em
lista de blocos livres de heap — mas isso é leitura de padrão, não símbolo: as duas
funções não têm nome no port.

## Como foi achado

O caminho óbvio não funciona, e vale registrar para ninguém repetir: **comparar os logs
linha a linha é inútil.** O trace é gravado por várias threads sem trava e as linhas se
intercalam no meio umas das outras —

```
... gifPk1=[boot-trace:CreateSema] tid=1 init=1 ...
```

— então duas corridas do **mesmo** desfecho divergem em 40.079 de 42.586 linhas. Pior: o
estado observável por tick também não serve. Duas corridas do mesmo desfecho já divergem
no **tick 9**, em PC amostrado e em ordem de eventos de kernel. As threads correm entre si
desde o primeiro décimo de segundo. Só o resultado final é determinístico.

O que funcionou foi abandonar o tempo como eixo e comparar **quais eventos acontecem**.
Marcadores presentes numa corrida e ausentes na outra:

| marcador | desfecho A | desfecho B |
|---|---:|---:|
| `mc3-menu-change` | — | 1 |
| `mc3-rmc-model-draw` | — | 35 |
| `mc3-rmc-model-drawcpv` | — | 36 |
| `mc3-rmc-model-drawskinned` | — | 12 |
| `dmac-vif0` / `-chain` | — | 30 / 32 |
| `mc3-42cc80` / `42ca90` / `42aaf8-progress` | — | 42 / 41 / 38 |
| `loop-exit`, `game-thread-return`, `shutdown` | — | 1 cada |
| `thread-heartbeat` | **616** | — |

Não é diferença de grau. O desfecho A não faz nada disso, e em troca emite 616 batimentos
de thread travada. No log do desfecho B o `mc3-menu-change` aparece na linha 21.089 e todo
o resto decorre dele; no log do desfecho A, praticamente no mesmo ponto (linha 20.981),
o que aparece é o primeiro `thread-heartbeat`.

## O que isto explica

O não-determinismo que o projeto persegue desde agosto. Não é ruído de medição nem
dispersão: é uma corrida entre threads sobre uma lista compartilhada, decidida de um jeito
ou de outro conforme o escalonamento. Por isso os contadores saem **idênticos até o último
dígito** dentro de cada ramo — o resultado de cada ramo é determinístico; o que é
sorteado é o ramo.

Também explica por que comparação A/B no projeto vinha produzindo conclusão falsa. O
`+43%/+323%` atribuído ontem à correção do `sqrt.s` era a corrida "antes" caindo no ramo
ruim e a "depois" no ramo bom, com os dois binários tendo os dois ramos.

## O que NÃO está provado

- **Não provei que a lista tem ciclo.** Provei que duas threads executam instruções de
  caminhada de lista e não terminam. Ciclo é a explicação mais simples; corrupção de
  ponteiro por escrita concorrente é outra.
- **Não identifiquei a estrutura.** `FUN_0054cb58` e `sub_0054CCE8` não têm símbolo. A
  leitura de heap vem do padrão de código, não de nome.
- **Não verifiquei se o ramo bom passa por estas funções.** Se passar, a diferença é só a
  corrida; se não passar, há um desvio antes. Os frames não amostram lá dentro.
- **n=1 para o ramo ruim neste binário.** Das 7 corridas da segunda bateria, só a `limpa3`
  caiu nele.
- **As corridas do ramo ruim do binário antigo não emitem `thread-heartbeat` nenhum**,
  apesar de terem contadores idênticos (703.599 / 256.036.663) e o mesmo PC de frame
  (`0x322ffc`). Mesmo desfecho aparente, sinal de instrumentação diferente. Não
  investigado.

## Próximo passo mais barato

Instrumentar `FUN_0054cb58` e `sub_0054CCE8` para registrar, a cada N iterações, o
ponteiro corrente e quantos nós já foram visitados. Se o ponteiro repetir, é ciclo, e aí a
pergunta vira quem fecha o ciclo. Se não repetir e a contagem explodir, é lista sendo
estendida por outra thread mais rápido do que esta a consome.

`work/scratch/find_divergence.py` faz a comparação de eventos e de estado por tick.

## Contexto

Achado na segunda bateria (binário de 21:35 com as correções COP1, `7aa06d1`), logs em
`work/logs/battery_day20260830_cop1fix_*`. Suíte em 309/309 depois das correções.
