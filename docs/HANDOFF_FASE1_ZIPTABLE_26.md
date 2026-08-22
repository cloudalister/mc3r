# Handoff — passo 26: a tabela do zipFile (span > 0x100) e o zipRead recusado

## Contexto mínimo

Diagnóstico do passo 25 (Codex, verificado pelo coordenador): o jogo NÃO está inicializando —
está em plateau. O parser (`rmcShaderTemplate` → `datBaseTokenizer` → `Stream::Read` →
`zipFile::zipRead` `0x4f9918`) chama `zipRead`, cai em função não registrada, entra em recovery
e repete. 132 ocorrências de `0x4f9918` no último trace; 69 chamadas de `zipRead` numa corrida.

Causa no gerador (`PS2Recomp/ps2xRecomp/src/lib/code_generator.cpp:867`):
`if (hasKnownBoundary && maxTarget - minTarget <= 0x100u)` — tabelas de ponteiros em `.data`
cujos alvos se espalham por mais de 0x100 são **descartadas inteiras**. A tabela
`coreFileMethods` do `zipFile` tem span `0x2e8`, então some. Entrypoints ausentes:

| Slot | Endereço | Função |
|---|---|---|
| +0x04 | `0x4f9910` | zipCreate |
| +0x08 | `0x4f9918` | **zipRead** |
| +0x0c | `0x4f9948` | zipWrite |
| +0x10 | `0x4f9950` | zipSeek |
| +0x1c | `0x4f9a48` | zipSize |

Os corpos existem (ex.: `work/generated/ghidra/sub_004F95F8_0x4f95f8.cpp:1268`); falta a porta
de entrada. Caller real: `work/generated/ghidra/sub_003993A8_0x3993a8.cpp:381`.

## Objetivo

Gerador reconhece tabelas legítimas independente do span; os 5 entrypoints ficam registrados
nos owners existentes; `bad=0x4f9918` some; o parser sai do plateau e o asset manager lê de
verdade os `.DAT`.

## Como corrigir (ressalvas do coordenador — não negociáveis)

1. **Não trocar 0x100 por outro número mágico.** Remover/relaxar o critério de SPAN e validar
   **cada alvo individualmente**: está em `.text` executável? cai em fronteira de instrução
   válida? é alcançável como corpo dentro de um owner conhecido? A agrupação por contiguidade
   (`+8`) já filtra tabela falsa; o span nunca foi um bom proxy.
2. **Sanity check da regeneração é obrigatório**: o delta de entry points tem que ser pequeno e
   explicável (referência: passo 24 foi 96974 → 97025). Se adicionar milhares, é falso-positivo
   — **parar e reportar**, não compilar.
3. Teste novo cobrindo tabela legítima com span > 0x100 (e um caso negativo: sequência de
   ponteiros que NÃO é tabela).

## Validação

Regenerar só os afetados → `tools/parallel_compile.py` se muitos → `python tools/find_stale.py`
= 0 → relink `10_link_partial_runner.bat fast` (nunca concorrente, timeout ≥6 min, PATH MSYS2
primeiro) → suíte completa (273) → 1 corrida determinística
(`$env:MC3_DETERMINISTIC='1'; $env:MC3_DISPATCH_BUDGET='100000'`, 90s) → `21_probe_repeat` 3x.

## Aceite

`bad=0x4f9918` = 0 no trace **e** saída do plateau do tokenizer (evidência: `zipOpen`/
`flag619f40 != 0`/leitura de conteúdo do `ASSETS.DAT` além do header, ou PC estabilizando em
região nova nomeada). M4 (`gifPkTotal>0` E `gsPrims>0`) = PARAR, confirmar 3x, reportar na hora;
`gsPixels>0` = anotar commit/env/comando (primeiro framebuffer da história).

## Regras

As do `STATUS.md`/`WORKFLOW.md`: sem env-gate novo; sem SignalSema injetado; sem chute de bytes;
endereço do alpha nunca vale no retail sem portar; scheduler intacto; commits locais SEM push
(coordenador revisa e sobe); resultado honesto em `docs/RESULT_ZIPTABLE_26_V1.md` mesmo parcial.
