# RESULT — as duas baterias, antes e depois das correções COP1 — 2026-08-30

## Resultado

**O que mudou não foi a média: foi qual desfecho o jogo escolhe.** O desfecho bom saiu de
1 corrida em 7 para 6 em 7, e o próprio desfecho bom subiu de teto.

| | antes (exe 05:49) | depois (exe 21:35) |
|---|---|---|
| desfecho bom | 1 de 7 | **6 de 7** |
| `gsPrims` no desfecho bom | 1.004.584 | **1.173.155** (+16,8%) |
| `gsPixels` no desfecho bom | 1.088.137.517 | **1.421.778.605** (+30,7%) |
| desfecho ruim (703.599) | 5 de 7 | 1 de 7 |
| corridas que encerram sozinhas | 1 de 7 | 6 de 7, entre 872 s e 1.098 s |
| `DrawSkinned` | 18 | 12 |
| dump de frame | nunca capturou | **capturou na 1ª tentativa** |

## O método, e por que ele importa aqui

A primeira bateria existiu para responder se o `+43%/+323%` atribuído ontem à correção do
`sqrt.s` era efeito ou dispersão. A resposta foi nenhuma das duas: **o jogo tem desfechos
discretos.**

Antes (mesmo binário, 7 corridas):

| desfecho | `gsPrims` | `gsPixels` | frequência |
|---|---:|---:|---|
| A | 703.599 | 256.036.663 | 5 de 7 |
| B | 1.004.584 | 1.088.137.517 | 1 de 7 |
| C | 821.883 | 601.142.745 | 1 de 7 |

O desfecho A repetiu **idêntico até o último dígito** cinco vezes. Isso não é ruído de
medição, é ramificação, e é determinístico dentro de cada ramo. E o desfecho B é
exatamente o número que o handoff atribuiu à correção do `sqrt`, saído do mesmo binário
das outras seis corridas. A corrida "antes" de ontem caiu em A, a "depois" caiu em B: os
dois binários têm os dois desfechos, então **aquele ganho de render não existiu.**

Depois (7 corridas):

| desfecho | `gsPrims` | `gsPixels` | frequência |
|---|---:|---:|---|
| B' | 1.173.155 | 1.421.778.605 | 6 de 7 |
| A | 703.599 | 256.036.663 | 1 de 7 |

O desfecho C desapareceu. O A sobreviveu, uma vez.

**A estatística agregada que o relatório calcula é enganosa nos dois lados** e está lá só
por completude: média de 1.079.244 com CV de 19,5% descreve a mistura de dois desfechos,
não uma distribuição. O número que significa alguma coisa é a frequência.

## O que foi mudado, e o que não dá para atribuir

Três mudanças entraram no mesmo binário, então o efeito **não está isolado**:

1. `RSQRT.S` — 450 dos 451 sítios calculavam `1.0f / sqrtf(f[fs])` em vez de
   `fs / sqrt(ft)`. O gerador estava certo desde 29/08; o corpus é de 24/08 e a correção
   nunca foi propagada. Ver `RESULT_RSQRT_STALE_CORPUS_2026-08-30.md`.
2. Correção estreita do modelo de valores da FPU: `SQRT.S` de negativo devolve
   `sqrt(|x|)`, `RSQRT.S` idem, divisão por zero satura em ±`Fmax`.
3. Acumulador do COP1 saiu de `ctx->f[31]` para `ctx->fpu_acc`.

Sendo honesto sobre a atribuição: a (3) é comprovadamente inerte neste jogo — a ordem que
causaria corrupção não ocorre em nenhuma função gerada. A (2) só dispara em raiz de
negativo e divisão por zero. Por eliminação a (1) é a candidata provável, mas isso é
inferência, não medição. Separar exigiria um binário por mudança.

## O que continua aberto

- **O não-determinismo não acabou.** O desfecho A ainda apareceu uma vez em sete. O que
  escolhe o ramo continua desconhecido, e enquanto continuar, toda comparação A/B do
  projeto é sorteio. Com contadores bit a bit idênticos dentro de cada ramo, isso é
  bissectável: comparar o trace de uma corrida A com o de uma B e achar o primeiro ponto
  de divergência.
- **`DrawSkinned` caiu de 18 para 12.** Sem explicação. Mais primitivas e menos chamadas
  de modelo com esqueleto ao mesmo tempo.
- **As corridas encerram sozinhas** em 872–1.098 s, em vez de bater o timeout de 1.800 s.
  Encerrar não é o mesmo que terminar bem; não foi investigado o que causa a saída.
- **O frame capturado não é uma cena reconhecível.** É o primeiro dump não-preto do
  projeto: um facho amarelo/branco em diagonal com um estouro magenta, sobre um fundo
  escuro com bandas diagonais. Prova que pixel chega ao framebuffer. Não prova que a
  imagem é a certa — as bandas diagonais no fundo inteiro são suspeitas.

`work/captures/frame_day20260830_cop1fix.png`, capturado com gatilho em 950.000
primitivas. O gatilho anterior, de 1.200.000, ficava acima do teto de todos os desfechos
e por isso nunca disparava — o dump preto de ontem foi hora errada, o de hoje de manhã foi
gatilho impossível.

## Dois defeitos de ferramenta encontrados no caminho

- `find_stale.py` decidia obsolescência como `hash_ok or o_mtime >= cpp_mtime`. A metade
  do mtime anulava a `COMPILE_KEY`: com a chave nova e dois headers alterados, 14.726 dos
  15.831 objetos reportavam OK. O link teria produzido um binário com metade dos objetos
  compilados contra a definição antiga de `R5900Context`, e ele rodaria e mediria como
  válido. Corrigido em `7904c16`.
- O passo do `cmake` no pipeline não punha `C:\msys64\ucrt64\bin` no `PATH`. O `c++.exe`
  morre no carregamento de DLL sem emitir diagnóstico, e o ninja só imprime `FAILED`.

Os dois foram pegos pelos guardas do pipeline, não pelo build.

## Números da recompilação

15.831 objetos, 2.507 s, zero falhas. Link em 46 s, `mc3_partial.exe` de 278.155.760
bytes às 21:35.
