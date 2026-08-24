# RESULT — Passo 30: MCMAN handshake

Data: 2026-08-23

## Diagnóstico e mudança

A corrida do passo 29 misturava dois servidores. O trace confirmou:

- 0x80000100/0x80000101: PADMAN; as mensagens capturadas foram "libpad: Module version mismatch".
- 0x80000400: MCMAN, com bind seguido de fno=0xfe, receive de 0x0c bytes.

O decomp de sceMcInit lê três palavras da resposta (DAT_00696f40, DAT_00696f44, DAT_00696f48) e rejeita versões abaixo de 0x20a e 0x20e. Implementei no dispatcher por (sid,fno) uma resposta de 12 bytes: resultado 0, versão A 0x20a e versão B 0x20e.

O trace gerado foi [boot-trace:mc3-memcard-rpc] kind=mcman-init sid=0x80000400 fno=0xfe, result=0x0, versionA=0x20a, versionB=0x20e.

Não houve env-gate, SignalSema injetado ou mudança no scheduler.

## Validação

- Runtime compilado com sucesso (ps2_runtime).
- find_stale.py: Missing 0, Stale (mtime) 0.
- Relink fast sequencial concluído.
- Suíte: primeira execução 277/278, falha conhecida de paridade intercalada em sceGsSyncV; retry 278/278.
- Corrida determinística: MC3_DETERMINISTIC=1, MC3_DISPATCH_BUDGET=500000, MC3_BOOT_TRACE=1, timeout 180 s.
- Resultado: game-thread-return, último frame tick 4260, PC 0x1a2408.
- Depois do handshake, PCs passam por 0x432..., 0x4b... e 0x55..., terminando em 0x1a2408; não retornaram ao plateau 0x1b15xx.
- gifPk1/2/3, gsPrims, gsPixels: todos 0 nessa corrida. M4 não ocorreu.
- Probe 3x: PCs 0x42e738, 0x433254, 0x4f97b8; todos sem render.

## Próxima fronteira

Após mcman-init, o trace ainda registra chamadas MCMAN fno=0x14, fno=0x1 e fno=0xd no fallback neutro. O passo 30 prova a saída do loop de inicialização, mas ainda não prova a semântica completa de cartão ausente ou cartão formatado vazio, nem imagem na tela.

Próximo passo recomendado: casar esses três fnos com as funções sceMc* no decomp e preencher somente os campos que o cliente lê, começando pelo retorno de sceMcGetInfo/sceMcSync; repetir a medição antes de tocar em render.

## Artefatos

- timeline: work/exports/longrun_timeline.md
- log combinado: work/logs/14_run_boot_trace.log
- suíte retry: work/logs/pass30_suite_retry.log
- probe 3x: work/boot_probe/repeat_memcard30_20260823_061130.md

## Continuação — MCMAN fno=0x1

Data: 2026-08-24

O agente read-only confirmou no retail que o callback `0x543308` consome os campos
`+0x00`, `+0x04` e `+0x90` da estrutura compartilhada. Implementei somente essa
resposta no dispatcher MCMAN, usando os buffers retail confirmados:

- shared: `0x6fb440`, tipo `2`, clusters livres `0x2000`, formato `1`;
- resposta RPC: `0` em `payloadAddr`;
- `fno=0x14` e `fno=0xd` permaneceram semântica neutra.

O handler também passou a emitir uma linha própria de trace com request, port/slot,
ponteiros de saída e campos escritos. Não houve env-gate, SignalSema injetado ou
alteração do scheduler.

### Validação da continuação

- `ps2_runtime`: compilou e linkou.
- `find_stale.py`: Missing `0`, Stale `0`.
- relink fast serial: OK, `work/link/partial/mc3_partial.exe`.
- suíte: `277/278`; única falha foi a flake conhecida de paridade em `sceGsSyncV`.
- probe `100000`: encerrou no orçamento antes de alcançar MCMAN; não foi usada como
  evidência negativa.
- probe determinística `500000`, `MC3_BOOT_TRACE=1`: duas chamadas observadas de
  `kind=mcman-get-info`, ambas com `wrote=1`, `type=0x2`, `free=0x2000`,
  `format=0x1`, `result=0x0`.
- após o primeiro `fno=0x1`, o trace avançou até uma chamada `fno=0xd`; não houve
  retorno ao plateau anterior `0x1b15xx` nessa corrida.
- término: `game-thread-return`, PC `0x1a2408`, após o orçamento determinístico.
- render: `gifPkTotal` não comprovado como positivo junto com `gsPrims`; os frames
  registraram `gsPrims=0` e `gsPixels=0`. Portanto o critério de parada visual não
  foi atingido.

### Leitura honesta

`sceMcGetInfo` agora responde pela camada RPC com os três campos que o callback
retail realmente lê, e o jogo sai do primeiro uso neutro do MCMAN. A próxima
fronteira concreta é `fno=0xd` (`sceMcGetDir`), ainda fallback; o diretório vazio
deve ser implementado somente depois de capturar o caminho, endereço da tabela e
resultado esperado no cliente.

Artefato: `work/logs/14_run_boot_trace.log` e `work/logs/14_run_boot_trace.log.stderr`.

## Continuação — MCMAN fno=0xd e próxima fronteira

Data: 2026-08-24

O trace retail confirmou o pacote de `sceMcGetDir`:

- request `0x6faff0`, `port=0`, `slot=0`, `maxEntries=6`;
- tabela de saída `0x7e0b40`;
- caminho inline `/BASLUS-21355*` (palavras do guest: `0x5341422f`,
  `0x2d53554c`, `0x35333132`, `0x2a35`).

O comportamento já existente do stub host para diretório formatado sem
correspondências é resultado `0`. O dispatcher MCMAN passou a espelhar essa
semântica somente para esse protocolo: zera as 6 entradas solicitadas (64 bytes
cada), grava resultado `0` e registra `emptyTable=1`.

Validação dessa alteração:

- runtime compilado e relink serial OK;
- `find_stale.py`: Missing `0`, Stale `0`;
- probe determinística `500000`: `fno=0xd` respondeu `result=0x0`,
  `emptyTable=1`;
- o PC ainda atingiu `bad=0x1a5278`, portanto a resposta do cartão não é mais
  o bloqueio imediato;
- depois, o trace fica em `pc=0x1a2408`; `gsPrims=0` e `gsPixels=0`.

### Próxima fronteira comprovada

`0x1a5278` é exatamente o fim registrado pela tabela Ghidra para
`FUN_001a5238 (0x1a5238–0x1a5278)`, mas o artefato `native_analyzer` contém o
corpo contínuo `sub_001A5238` até `0x1a55d0`, começando em `0x1a5278` com
instrução válida. Portanto o próximo passo é portar essa fronteira como split
extra dentro do owner conhecido, seguindo o mecanismo de `boundary_port.csv`.
Não há evidência para implementar outro retorno MCMAN neste ponto.
 
## Continuação — validação do split 0x1a5278

Data: 2026-08-24

Foi adicionada somente a entrada explícita `0x001A5278` em
`work/exports/boundary_port.csv`. Não foi inventado delta, nome alpha ou
heurística em `code_generator.cpp`; os metadados ficaram vazios porque a prova
veio do owner gerado/native analyzer.

Sanity: `586` configurados, `586/586` mapeados, delta efetivo `+1`. O gerado
contém `case 0x1a5278`, `label_1a5278` e
`runtime.registerFunction(0x1a5278, sub_001A5238_0x1a5238)`.

Validação: `parallel_compile.py` terminou `15811/15811`, falhas `0`, em 2169 s;
`find_stale.py` deu Missing `0`, Stale `0`; relink serial MSYS2 OK. A suíte
deu `276/278` e depois `277/278`; restaram somente flakes conhecidas de VU0
macro mappings e `sceGsSyncV`.

No probe determinístico (`MC3_DISPATCH_BUDGET=500000`, 120 s),
`bad=0x1a5278` apareceu uma vez e não repetiu. O novo loop dominante foi
`bad=0x5b92d8` com `231` ocorrências. `gifPkTotal` nunca ficou positivo;
`gsPrims` chegou a `5`, mas `gifPk1/2/3=0` e `gsPixels=0`, portanto o critério
visual não foi atingido. O jogo terminou com `game-thread-return pc=0x1a2408`.

Próxima fronteira comprovada: `0x5b92d8` está dentro de
`sub_005B90D8 (0x5b90d8–0x5b99a8)`, com `jr $ra` e delay slot em `0x5b92dc`.
O próximo passo é portar somente esse split, repetir o sanity `+1` e testar;
não há base para alterar a semântica do cartão.
