# Handoff — passo 27: portar FRONTEIRAS de função do MC.MAP (mata a classe sem heurística)

## Por que o passo 26 morreu (e por que este é diferente)

Passo 26 tentou inferir tabelas de ponteiros em `.data` por heurística: relaxar o span deu
**1001 grupos / 1290 alvos** para 1 tabela e 5 alvos reais. O portão de sanidade rejeitou —
corretamente. Heurística sobre `.data` é chute.

**A causa real não é a tabela: é o Ghidra ter colado várias funções pequenas numa só.**
`0x4f9918` (zipRead) não é "entrada perdida de tabela" — é **início de função** que o Ghidra
não detectou, então virou miolo de `sub_004F95F8`.

E nós temos a verdade absoluta disso: o `MC.MAP` do protótipo traz **endereço + tamanho** de
cada função. Basta portar as fronteiras alpha→retail.

## A prova (feita pelo coordenador, reproduzível)

Âncora `zipFile::internalRead` (alpha `0x4b2bb8` ↔ retail `0x4f9c78`) → delta `0x470c0`.
Aplicando o delta nos vizinhos do MC.MAP:

| alpha | +delta = retail | função |
|---|---|---|
| `0x4b2850` | **`0x4f9910`** | zipCreate |
| `0x4b2858` | **`0x4f9918`** | **zipRead** (o bad= do plateau) |
| `0x4b2888` | **`0x4f9948`** | zipWrite |
| `0x4b2890` | **`0x4f9950`** | zipSeek |
| `0x4b2988` | **`0x4f9a48`** | zipSize |

Bate 5/5 com os slots que o passo 26 descobriu na tabela. Bônus na mesma região: `zipClose`
`0x4f9980`, `zipEnumFiles` `0x4f99c8`, ctor/dtor, `KillAll`.

## Escopo global medido (é o portão de sanidade deste passo)

Critério: para cada símbolo do MC.MAP, olhar as âncoras casadas (`retail_symbol_port.csv`)
imediatamente antes e depois; **só aceitar se o delta for idêntico dos dois lados** e as
âncoras estiverem a menos de `0x2000`. Resultado medido: **595 funções novas** (endereços que
o Ghidra não conhece como início de função), incluindo os 5 do zip.

**595 é o número esperado.** Se a implementação produzir ordem de grandeza diferente, algo está
errado — parar e reportar.

## O que fazer

1. `tools/port_boundaries.py`: implementar o critério acima (delta confirmado dos dois lados,
   âncoras próximas, alvo ainda não conhecido) → `work/exports/boundary_port.csv` com
   `retail_addr,size,alpha_name,delta,anchor_lo,anchor_hi`.
2. Validar cada candidato antes de emitir: endereço em `.text`, alinhado a 4, dentro de uma
   função existente (é split, não invenção), e o tamanho do MC.MAP não estourar o fim do owner.
   Descartar (e logar) o que não passar.
3. Alimentar o gerador com esses endereços como entry points — pelo caminho de configuração
   existente (TOML/CSV de export), **não** por heurística nova no `code_generator.cpp`. Se
   precisar de código, que seja "ler lista de entry points extra de arquivo".
4. Regenerar afetados → `parallel_compile.py` → `find_stale.py` = 0 → relink (PATH MSYS2,
   nunca concorrente, ≥6 min) → suíte (275).
5. Medir: 1 corrida determinística (`$env:MC3_DETERMINISTIC='1'; $env:MC3_DISPATCH_BUDGET='100000'`,
   90s) + `21_probe_repeat` 3x.

## Aceite

`bad=0x4f9918` = 0 **e** saída do plateau do tokenizer (evidência: `zipOpen`/`flag619f40 != 0`/
leitura de conteúdo do `ASSETS.DAT` além do header/PC novo nomeado).
M4 (`gifPkTotal>0` E `gsPrims>0`) = PARAR, confirmar 3x, reportar na hora. `gsPixels>0` = anotar
commit/env/comando (primeiro framebuffer da história).

## Regras

`STATUS.md`/`WORKFLOW.md`: sem env-gate novo; sem SignalSema injetado; sem chute; scheduler
intacto; commits locais SEM push; resultado honesto em `docs/RESULT_BOUNDARY_PORT_27_V1.md`
mesmo parcial. Se a lista de 595 quebrar o build de forma sistêmica, entregar primeiro só o
subconjunto da região do `zipFile` (os 5+4 provados acima) e reportar o resto.
