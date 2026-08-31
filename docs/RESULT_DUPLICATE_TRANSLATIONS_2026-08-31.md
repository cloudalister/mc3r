# RESULT — 23,6% das funções geradas são tradução duplicada — 2026-08-31

## Resultado

**3.712 das 15.757 funções geradas estão inteiramente contidas dentro de outra**, ou seja
traduzem as mesmas instruções do jogo duas vezes, em dois arquivos, cada um com sua
própria tabela de retomada. São **990,6 KB** de código do jogo com tradução dupla — o ELF
tem 5,26 MB, então quase 19% do jogo.

Sobreposição parcial: **zero**. É sempre contenção limpa, e sempre o mesmo padrão — um
`FUN_xxxxxx` do Ghidra dentro de um `sub_XXXXXX` do port de símbolos, começando algumas
dezenas de bytes depois:

| interna | intervalo | externa | intervalo | bytes duplicados |
|---|---|---|---|---:|
| `FUN_002e5c10` | 0x2e5c10-0x2e90a8 | `sub_002E5BF8` | 0x2e5bf8-0x2e90a8 | 13.464 |
| `FUN_003090c0` | 0x3090c0-0x30bf20 | `sub_00309018` | 0x309018-0x30bf20 | 11.872 |
| `FUN_002d5430` | 0x2d5430-0x2d7fe4 | `sub_002D5390` | 0x2d5390-0x2d7fe8 | 11.188 |

Duas fontes de símbolo produzindo entradas diferentes para o mesmo código, e o gerador
tratando cada uma como função independente.

## Como apareceu

Não foi procurado. Apareceu porque uma instrumentação não disparava.

Rastreando o que separa os dois desfechos do jogo, cheguei ao portão do
`mc3-menu-change`: a chamada `jal func_339278` em `0x33acdc`, alcançada se
`estado(-0x6500($s7)) == 3` ou `campo+4 do objeto == 7`. Instrumentei as duas condições
em `sub_0033A710` (0x33a710-0x33af88), que contém aqueles endereços.

**As sondas nunca dispararam.** Nem no desfecho ruim, nem no bom — e o bom comprovadamente
executa a chamada logo depois delas. A instrumentação estava no binário (a string aparece
duas vezes no `.exe`, e o `.exe` é mais novo que o fonte), então não era build velho.

A explicação é que `FUN_0033a838` (0x33a838-0x33af88) traduz as mesmas instruções, e o
caminho que importa entra por ela. Sondar uma cópia não sonda o código que roda.

- `work/scratch/audit_overlapping_functions.py` → `work/exports/audit_overlapping_functions.md`

## O que isto significa, e o que ainda não se sabe

Certo:

- **Instrumentar exige achar a cópia que executa**, ou instrumentar as duas. Custou uma
  noite de sondas mudas e quase custou uma conclusão errada — de novo.
- **Custo de binário.** Um `mc3_partial.exe` de 278 MB carrega ~1 MB de código do jogo
  traduzido em dobro, mais o inchaço de código nativo correspondente.

Não medido, e portanto não afirmado:

- **Se as duas cópias podem executar alternadamente.** Para saber, é preciso olhar o
  registro de funções (`register_functions`), não os intervalos — o registro é que decide
  qual tradução atende cada endereço de entrada. As sondas com sufixo `-b` na segunda
  cópia respondem isso empiricamente.
- **Se isto contribui para o não-determinismo.** É tentador ligar as duas coisas, e é
  exatamente o tipo de salto que já me fez errar duas vezes nesta investigação. Duas
  traduções da mesma função, cada uma com sua tabela de retomada, é uma hipótese
  plausível de divergência — não é evidência.
- **Se as correções chegaram nas duas cópias.** Chegaram: `fix_cop1_corpus.py` varre
  `work/generated/ghidra/*.cpp` inteiro e casa pela codificação de 32 bits, então as duas
  traduções do mesmo `rsqrt.s` foram corrigidas. Isto é dedução do método do script, e
  vale confirmar por amostragem.

## Estado da investigação do desfecho

O que se sabe até agora, e sobreviveu a verificação:

1. O desfecho ruim é o jogo **vivo** — blend de câmera, `logf`/`powf`/`expf`, interrupções
   e quadros continuam — porém `mc3-menu-change` nunca dispara, e nada que dependa dele
   acontece: nem desenho de modelo, nem DMA VIF0, nem saída.
2. `sub_0033A710` **não é entrada** no desfecho ruim (0 entradas em 2 corridas) e é entrada
   no bom (1 e 2 entradas em 2 corridas). Amostra pequena, mas os dois lados batem.
3. O portão em si ainda não foi observado, porque as sondas estavam na cópia errada.

Descartado no caminho, e registrado para não voltar: o livelock em `FUN_0054cb58` não é o
mecanismo (ver `RESULT_BRANCH_STALL_0x54CB58_2026-08-31.md`), e o blend de câmera não é o
portão — ele roda igual nos dois desfechos, 828 chamadas no bom contra 1.708 no ruim, e a
diferença é só que no ruim ele é a única coisa acontecendo.
