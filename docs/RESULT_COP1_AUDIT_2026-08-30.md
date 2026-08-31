# RESULT — auditoria das instruções COP1 — 2026-08-30

## Resultado

**O `sqrt.s` era o único.** Varridas 303.152 instruções COP1 do corpus gerado, em 25
opcodes distintos, nenhuma outra lê um campo de operando errado. O item 1 do handoff
está fechado, e fechado por evidência, não por leitura.

A auditoria encontrou outras duas coisas, ambas fora da classe "campo de operando":

1. O acumulador do COP1 é emulado em `$f31`, que é um registrador real. Estruturalmente
   errado, **mas não exercitado** por este jogo. Higiene, não urgência.
2. O modelo de valores da FPU é IEEE-754 do hospedeiro. O R5900 não é IEEE-754: **não
   tem NaN nem infinito**. Esta é a classe de defeito que causou o congelamento de
   ontem. A correção do `sqrt` removeu uma instância; a classe continua aberta.

> **Adendo, mesma noite.** Esta auditoria leu o *gerador* e presumiu que o corpus
> correspondia a ele. Não correspondia. Uma segunda varredura, comparando o texto
> gerado com o que o gerador atual emitiria, achou 450 de 451 `RSQRT.S` divergentes:
> uma correção feita no gerador em 29/08 nunca foi propagada ao binário. O buraco não
> estava no gerador nem no corpus, e sim entre os dois.
> Ver `docs/RESULT_RSQRT_STALE_CORPUS_2026-08-30.md`.

## Como foi medido

Duas varreduras independentes sobre os 43.741 arquivos gerados (1,2 GB), lendo a
**palavra crua** de 32 bits do comentário que o gerador emite em cada instrução:

```
// 0x259dd0: 0x46060304  c1          0x60304
```

Ler a palavra, e não o texto, é deliberado. O texto vem do Rabbitizer
(`r5900_decoder.cpp:184`), que imprime `c1 0x......` justamente para as instruções que
não conhece — inclusive `sqrt.s`. O desassemblador textual é cosmético, só entra em
comentário, e não é confiável para identificar instrução. O decodificador semântico do
projeto (`r5900_decoder.cpp:769`) não extrai operandos: só marca metadados. Os operandos
saem do decode genérico de campos, que está correto — `ft = rt`, `fs = rd`, `fd = sa`.

- `work/scratch/audit_cop1_operands.py` → `work/exports/audit_cop1_operands.md`
- `work/scratch/audit_cop1_acc_collision.py` → `work/exports/audit_cop1_acc_collision.md`

## 1. Nenhum outro operando errado

O critério é o mesmo que derrubou o `sqrt.s`, e é estatístico, não teórico:

> Um campo lido pelo gerador que vale **0 em todas as codificações**, enquanto um campo
> que ele ignora **varia**, não é um operando. É um campo que o montador deixou zerado.

Aplicado a todos os opcodes presentes no corpus, nenhum casa com essa assinatura. As
duas linhas que merecem nota:

| instrução | ocorrências | fd | fs | ft | gerador lê | leitura |
|---|---:|---|---|---|---|---|
| `SQRT.S` | 1.772 | 26 val | **const 0** | 18 val | `ft` | correção de ontem confirmada no corpus |
| `ADDA.S` | 3 | const 0 | const 0 | const 1 | `fs, ft` | 1 codificação só; degenerescência sem significado com n=3 |

O `ADDA.S` aparece três vezes, sempre na mesma codificação (`ACC = $f0 + $f1`). Com uma
amostra dessas, "campo constante" não distingue bug de coincidência. Não é evidência de
nada, nos dois sentidos.

Todo o resto — `MUL.S` (61.894), `ADD.S` (37.366), `SUB.S` (26.722), `DIV.S` (5.121),
`MADD.S`, `MSUB.S`, `RSQRT.S`, `MAX.S`, `MIN.S`, as 16 comparações — lê campos que
variam de verdade, tipicamente por 20 a 32 valores distintos.

**Resultado negativo, e é o resultado bom.** A hipótese do handoff era que, se o `sqrt`
passou despercebido, outras teriam passado. Não passaram.

## 2. O acumulador do COP1 mora em `$f31`

`R5900Context` (`ps2_runtime.h:129`) tem `float f[32]` e `fcr31`. Não tem acumulador da
FPU. O VU0 tem o seu (`vu0_acc`, linha 66); o COP1 não. O gerador resolve isso escrevendo
o ACC em `ctx->f[31]` — que é o `$f31` do jogo:

```cpp
case COP1_S_ADDA:
    return fmt::format("ctx->f[31] = FPU_ADD_S(ctx->f[{}], ctx->f[{}]);", fs, ft);
```

No corpus: **21.042** instruções de acumulador contra **142** usos de `$f31` como
registrador comum. Os dois conjuntos são não vazios, então o endereço é compartilhado de
fato.

Mas conjunto não vazio ainda não é corrupção. Para haver dano, um uso real de `$f31`
precisa cair no meio de uma sequência com o ACC vivo:

```
escrita do ACC  ->  escrita real em $f31  ->  MADD/MSUB lê o ACC
```

Procurado dentro de cada função gerada: **zero ocorrências**. Só 22 arquivos contêm os
dois usos, e neles nunca se cruzam.

**Conclusão honesta:** a construção é frágil e deveria ganhar um `float fpu_acc` próprio,
mas não está quebrando nada hoje. Corrigir é higiene barata, não conserto urgente. O
alcance da busca é intrafunção; o ACC não sobrevive a chamada pela ABI, então é o escopo
certo, mas vale registrar o limite.

## 3. O que sobrou é maior: a FPU não é IEEE-754

`ps2_runtime_macros.h:553` em diante:

```c
#define FPU_ADD_S(a, b)  ((float)(a) + (float)(b))
#define FPU_DIV_S(a, b)  ((float)(a) / (float)(b))
#define FPU_SQRT_S(a)    sqrtf((float)(a))
```

É aritmética IEEE-754 do hospedeiro, direta. A FPU do R5900 não é:

| | R5900 | o que roda hoje |
|---|---|---|
| NaN | **não existe** | existe |
| infinito | **não existe** | existe |
| overflow | satura em ±3,4028235e38 (`0x7F7FFFFF`) | vira `inf` |
| `SQRT.S` de negativo | `sqrt(\|x\|)`, liga a flag de inválido | `NaN` |
| denormais | zerados | preservados |
| `C.UN`, `C.UEQ`, `C.ULT`… | nunca verdadeiras (não há NaN) | podem ser verdadeiras |

Isto não é purismo. É exatamente a causa do congelamento consertado ontem: um `NaN`
chegou a `logf` e o laço de Taylor, que sai em `soma == anterior`, nunca saiu. **Num
R5900 de verdade aquele NaN não podia existir.** A correção do operando removeu a origem
específica; a arquitetura continua permitindo que qualquer overflow futuro produza um
`inf`, e `inf - inf` produz `NaN` de novo, e o mesmo laço volta a travar.

### O risco é latente, não ativo

Sendo justo com a evidência: no log pós-correção de 900 s não há um único `NaN` ou `inf`.
As 2.971 chamadas de `powf` registradas têm todas argumentos sãos (`f12=0.1`,
`f13=373.183`…). O fogo de ontem está apagado. O que está aberto é a possibilidade de ele
voltar por outra porta, e essa possibilidade é estrutural.

## O que foi decidido

A escolha era entre duas frentes de tamanhos bem diferentes:

- **Estreita** — só onde o hardware comprovadamente não pode produzir o valor que o
  emulador produz: `SQRT.S` de negativo, `RSQRT.S` de negativo, divisão por zero. Fecha a
  classe de defeito que já travou este jogo, e não toca na aritmética de `ADD`/`MUL`.
- **Completa** — modelo `ps2Float` inteiro: saturação em `Fmax`, denormais zerados,
  comparações sem NaN. Fiel ao hardware, e muda todo número medido até aqui.

O usuário escolheu a **estreita, mais o acumulador próprio**. Implementada em `7aa06d1`,
junto com a correção do `RSQRT.S` que a segunda varredura desenterrou. A frente completa
fica em aberto: ela invalida toda comparação com medição anterior, e isso é decisão que
não se toma de passagem.

## Estado

- Auditoria: fechada, item 1 do handoff resolvido por evidência.
- Instrumentação de phase timing: commitada (`c6891e9`), já estava dentro do binário que
  a bateria mede.
- Bateria de 7 execuções de 1800 s em andamento desde 17:29 →
  `work/exports/battery_day20260830.md`, reescrito a cada execução.
- Correção estreita da FPU + `RSQRT.S` + acumulador: `7aa06d1`, propagadas ao corpus, a
  recompilar durante a noite.
