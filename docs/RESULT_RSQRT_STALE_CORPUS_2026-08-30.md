# RESULT — `RSQRT.S`: o gerador foi corrigido e o binário nunca soube — 2026-08-30

## Resultado

**450 dos 451 `rsqrt.s` do jogo estavam errados no binário, e o gerador já estava certo
desde 29/08.** A correção existia; nunca foi propagada. `RSQRT.S` é a instrução de
normalização de vetor, então toda normalização que o jogo faz — iluminação, física,
câmera — vinha de uma raiz quadrada do registrador errado.

```
// 0x1bc418: 0x4600b096  rsqrt.s     $f2, $f22, $f0
ctx->f[2] = 1.0f / sqrtf(ctx->f[22]);            <- o que estava compilado
ctx->f[2] = FPU_RSQRT_S(ctx->f[22], ctx->f[0]);  <- correto: fd = fs / sqrt(ft)
```

O binário tirava a raiz de `fs` — o registrador do numerador — e descartava `ft`, que é o
operando de verdade. É a mesma forma do bug do `sqrt.s` consertado ontem, incluindo a
capacidade de produzir `NaN` quando o registrador errado calha de ser negativo.

## Como passou despercebido

Não foi um erro de leitura do manual. Foi uma correção que ficou órfã:

| data | o que aconteceu |
|---|---|
| 2026-08-24 | o corpus em `work/generated/ghidra` foi gerado |
| 2026-08-29 | `726f311` corrige `RSQRT.S` no gerador |
| 2026-08-30 | o binário ainda roda o código de 24/08 |

`04_run_recomp.bat` não é re-rodado porque apagaria a instrumentação manual acumulada em
várias sessões. Correção no gerador, portanto, **não chega ao jogo** — precisa de
propagação explícita, como a que o `fix_sqrt_operand.py` fez ontem para o `sqrt`.

O `sqrt` só chegou porque foi descoberto e propagado no mesmo dia. O `RSQRT` foi
corrigido num commit de checkpoint grande (`726f311`, "accumulated runtime work") e a
propagação nunca entrou na lista.

## A auditoria de ontem não pegaria isso

A auditoria de operandos desta manhã leu o **gerador** e concluiu, corretamente, que
todos os campos estavam certos. Ela presumia que o corpus correspondia ao gerador. Não
correspondia. O buraco não estava em nenhum dos dois: estava entre eles.

A varredura que pegou compara o texto gerado com o que o gerador **atual** emitiria para
a mesma palavra de 32 bits, comparando os índices `ctx->f[...]` em vez do texto, para não
tropeçar em espaço em branco:

| instrução | no corpus | divergentes | % |
|---|---:|---:|---:|
| `RSQRT.S` | 451 | **450** | 99,8% |
| `C.EQ.S` | 924 | 1 | 0,1% |
| as outras 18 | 75.892 | 0 | 0% |

A divergência aparente de `C.EQ.S` é o bloco de instrumentação manual do `logf`
(`sub_0041D0B0`, 0x41d1a0), não diferença de tradução.

E o escopo é fechado, não amostral: `726f311` mudou **uma única linha** de
`code_generator.cpp`. Aquela linha era todo o passivo.

- `work/scratch/audit_corpus_vs_generator.py` → `work/exports/audit_corpus_vs_generator.md`

## O que foi mudado

Propagação por `work/scratch/fix_cop1_corpus.py`: **9.811 instruções em 1.105 arquivos,
zero anomalias**. O script não confia no texto escrito — para cada linha candidata lê a
codificação de 32 bits do comentário, deriva `fd`/`fs`/`ft` dos campos, e só reescreve se
a linha atual for exatamente o que o gerador antigo teria emitido para aquela codificação.
Zero anomalias significa que todas as 9.811 batiam; nenhuma instrumentação manual foi
tocada.

| mudança | instruções |
|---|---:|
| `RSQRT.S` → `FPU_RSQRT_S(fs, ft)` | 450 |
| `DIV.S` → `FPU_DIV_S_HW` | 1.826 |
| acumulador `f[31]` → `fpu_acc` | 7.535 |

Junto foi a correção estreita do modelo de valores da FPU que a auditoria defendeu, e que
o usuário aprovou. O R5900 não tem `NaN` nem infinito — o travamento de ontem foi um `NaN`
que naquele hardware não poderia existir. Três operações passam a seguir o hardware:

- `SQRT.S` de negativo devolve `sqrt(|x|)`, não `NaN`
- `RSQRT.S` tira a raiz de `|ft|` e satura com divisor zero
- `DIV.S` por zero satura em ±`Fmax` (3,4028235e38) em vez de virar infinito, com o sinal
  vindo dos bits de sinal dos dois operandos — a forma anterior,
  `copysignf(INFINITY, f[fs] * 0.0f)`, errava o sinal quando o divisor era zero negativo

`ADD`/`SUB`/`MUL` e a saturação geral do modelo `ps2Float` continuam IEEE. Mudar isso
altera todo float do jogo e portanto toda medição já feita — é decisão de escopo, não
correção pontual.

O acumulador do COP1 saiu de `ctx->f[31]` para `ctx->fpu_acc`. Não conserta nada
observável hoje: a ordem que causaria dano não ocorre em nenhuma função gerada. Custa um
`float`.

## Medição: o que já se sabe e o que ainda não

**A primeira execução da bateria de referência contradiz o número do handoff.** Em 1800 s,
`gsPrims` = 703.599 e `gsPixels` = 256.036.663 — praticamente os valores **pré-correção**
do `sqrt` (704.397 / 257.216.311), e não os pós (1.004.584 / 1.088.137.517). O PC
dominante foi `0x322ffc`, 60 de 60 quadros, nem o `0x41D188` de antes nem o `0x1D3990` de
depois.

Uma execução ainda não é distribuição, e faltam quatro. Mas já dá para dizer o que ela
custa: **o salto de +43%/+323% atribuído ao `sqrt` pode ter sido dispersão.** Era n=1 dos
dois lados. O sumiço do `NaN` continua de pé — aquilo é qualitativo e reproduzível. O
ganho de render é que está sob suspeita.

Confusão possível que ainda não foi separada: a execução de referência de ontem foi em
janela, e a bateria roda em `MC3_HEADLESS=1`. A variável só liga `FLAG_WINDOW_HIDDEN`
(`ps2_runtime.cpp:1082`) e o contexto GL continua vivo, mas isso não foi medido — é
hipótese, não conclusão.

## Estado

- Gerador e runtime: `7aa06d1` no submódulo.
- Corpus: propagado, `COMPILE_KEY` subiu para `v3-cop1fpu` para invalidar o manifesto
  inteiro (o `find_stale.py` não rastreia headers — sem isso, dois headers mudados
  passariam batido e o build sairia inconsistente).
- Pipeline da noite armado (`work/scratch/Run-NightPipeline.ps1`): espera a bateria de
  referência, reconstrói a lib, recompila os ~15,9 mil objetos, relinka, e roda a segunda
  bateria comparável.
- Comparar ao acordar: `work/exports/battery_day20260830.md` contra
  `work/exports/battery_day20260830_cop1fix.md`.
