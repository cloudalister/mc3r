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

## Continuação — build incremental e split 0x5b9080

Data: 2026-08-24

O pipeline incremental foi corrigido. O problema era o gerador atualizar o
mtime de todo o corpus, enquanto `find_stale.py` tratava isso como mudança real.
Agora `tools/find_stale.py` e `tools/parallel_compile.py` usam
`work/exports/compile_manifest.json`, com SHA-256 do C++ e chave de toolchain.
`tools/seed_compile_manifest.py` cria o baseline somente depois de
`Missing 0 / Stale 0`.

Validação do conserto:

- baseline atual: 15.811/15.811 objetos, falhas 0;
- manifesto: 15.811 entradas;
- após a regeneração, `find_stale.py`: Missing 0, Stale 0;
- `parallel_compile.py`: `candidates: 0`, `to compile: 0`, manifesto preservado;
- `register_functions.partial.cpp` continua em ciclo separado e foi recompilado
  explicitamente antes do relink.

O split `0x5b9080` foi regenerado, mapeado `588/588`, compilado e relinkado.
Probe determinístico `500000`/120 s:

- `bad=0x1a5278`, `0x5b92d8` e `0x5b9080`: zerados;
- novo dominante: `bad=0x1a8e10` (2 ocorrências);
- secundários observados: `bad=0x5cd0f8` (8) e `bad=0x5d3638` (2);
- `gifPkTotal=0`, `gsPrims=0`, `gsPixels=0`;
- encerramento: `game-thread-return pc=0x432b60`, tick `6058`.

Fila proposta, cada lote com sanity `+1` e stop visual:

1. `0x1a8e10`, owner `sub_001A8DA0 (0x1a8da0–0x1a8e28)`; esperado: zerar o
   novo plateau imediato de 2 hits.
2. `0x5cd0f8`, owner `sub_005CC8C8 (0x5cc8c8–0x5cd1c0)`; esperado: remover
   8 hits e revelar a próxima fronteira dominante.
3. `0x5d3638`, owner `sub_005D3428 (0x5d3428–0x5d3678)`; esperado: remover
   2 hits restantes dessa região.

Esses endereços são candidatos provados por instrução/owner gerado; ainda não
foram adicionados ao CSV.

## Continuação — primeiro lote incremental real

Data: 2026-08-24

O lote `0x1a8e10` foi adicionado ao CSV e regenerado com `589/589` entry points
mapeados. O build hash-aware identificou exatamente `1` owner stale e o
compilou em `1 s`; não houve recompilação do corpus. O registro parcial foi
regenerado/recompilado separadamente, seguido de relink.

Probe determinístico `500000`/120 s:

- `bad=0x1a8e10`: zerado;
- novo dominante: `bad=0x5cd0f8` (8 ocorrências);
- `bad=0x5d3638`: 2 ocorrências;
- `gifPkTotal=0`, `gsPrims=0`, `gsPixels=0`;
- encerramento: `game-thread-return pc=0x432b60`, tick `1698`.

Durante a validação, o manifesto foi corrigido para fazer merge das entradas
existentes; um lote não pode substituir as 15.811 fontes pelo seu subconjunto.
O manifesto final foi re-semeado com `15811` entradas e `find_stale.py` voltou a
`Missing 0 / Stale 0`.

Próximo lote recomendado: `0x5cd0f8` no owner `sub_005CC8C8`; expectativa:
remover 8 hits e revelar a próxima fronteira. Depois, `0x5d3638` em
`sub_005D3428`, expectativa de remover 2 hits.

## Continuação — split 0x5b92d8 e novo avanço

Data: 2026-08-24

O entry point explícito `0x005B92D8` foi regenerado com sanity `587/587`
mapeados. Após `Generate-PartialRegister.ps1`, recompilação do registro
parcial e relink, o probe confirmou:

- `bad=0x1a5278`: `0`;
- `bad=0x5b92d8`: `0`;
- novo `bad=0x5b9080`: `1` ocorrência;
- término por `dispatch-budget-reached`, `pc=0x3afb30`, tick `5458`;
- `gifPkTotal=0`, `gsPixels=0`; `gsPrims` apareceu em uma amostra, sem
  critério visual completo.

A compilação foi `15811/15811`, falhas `0`; stale `0/0`; relink serial OK.
A suíte ficou `277/278`, somente a flake conhecida de VU0 macro mappings.

Próxima fronteira: `0x5b9080` é instrução válida dentro do owner gerado
`sub_005B8E08`, cujo range nativo é `0x5b8e08–0x5b90d8`. O próximo passo é
portar somente esse split e repetir a mesma cadeia, incluindo a regeneração
obrigatória do registro parcial antes do relink.
 
## Continuação — lote incremental 0x5cd0f8

Data: 2026-08-24

O lote `0x5cd0f8` foi regenerado como entry point `590/590`. O hash-manifest
marcou exatamente um owner; `parallel_compile.py` compilou `1` objeto em `1 s`.
O registro parcial foi regenerado/recompilado e o relink foi concluído.

Probe determinístico `500000`/120 s:

- `bad=0x5cd0f8`: zerado;
- novo dominante: `bad=0x5d3638` (2 ocorrências);
- `gifPkTotal=0`, `gsPrims=0`, `gsPixels=0`;
- encerramento: `game-thread-return pc=0x4fd5c0`, tick `5814`.

Próximo lote: `0x5d3638`, owner `sub_005D3428`, expectativa de eliminar os
dois hits e revelar a próxima fronteira.

## Continuação — lote grande de 16 fronteiras

Data: 2026-08-24

Foi aplicado um lote de 16 entry points, todos validados previamente como
instrução válida dentro de owners gerados conhecidos. A regeneração confirmou
`606/606` mapeados: delta de entry points exatamente `+16`; o build hash-aware
marcou 15 owners, pois dois alvos (`0x5cd058` e `0x5cd068`) compartilham owner.
Os 15 objetos foram compilados em 2 s, com registro parcial separado.

Alvos do lote: `0x5d3638`, `0x4c53c8`, `0x4c17e0`, `0x4c3688`, `0x5dc148`,
`0x5cd068`, `0x5cd058`, `0x4cfbf0`, `0x5d4578`, `0x4c96a0`, `0x5d8810`,
`0x4bf7a8`, `0x4d6fc0`, `0x4d11a8`, `0x4c1a78`, `0x4cdbc8`.

Validação:

- `find_stale.py`: Missing 0, Stale 0;
- relink serial: OK;
- suíte: primeira `276/278`, retry `277/278`; somente flakes conhecidas de
  `sceGsSyncV` e VU0 macro mappings;
- probe determinístico `500000`/120 s: **nenhuma linha `bad=`**;
- `gifPkTotal=0`, `gsPrims=0`, `gsPixels=0`;
- encerramento: `game-thread-return pc=0x4fd5c0`, tick `6058`.

Interpretação: o conjunto de plateaus conhecidos foi removido. O próximo
passo recomendado é uma corrida longa determinística (`budget=5000000`, janela
de 15 min) para medir progresso real e localizar a próxima fronteira de
subssistema; não adicionar mais boundaries sem novo `bad` comprovado.

## Investigação posterior — bloqueio real após o lote de boundaries

Data: 2026-08-24

A corrida longa foi processada pelo script a partir de
`work/logs/14_run_boot_trace.log`. O resultado muda o diagnóstico: o jogo não
está parado esperando o cartão e não está simplesmente repetindo um `bad`.

Evidência terminal:

- antes do plateau, o canal do jogo registrou
  `[printf] Heap  overrun (116815248 bytes requested)` e
  `[printf] FATAL: Heap  overrun (116815248 bytes requested)`;
- o PC passou a `0x399048`, com `ra=0x399044`, e permaneceu nessa região até
  `dispatch-budget-reached budget=5000000`;
- `0x399048` pertence a `sub_00398FE8` (`0x398fe8–0x399064`), portado como
  `FinalQuitf(const char *, ...)` pela tabela de símbolos;
- o corpo contém `b 0x399048` em `0x39905c`, sem condição de saída. A única
  interrupção é a preempção do recompilador; portanto esse é o loop fatal
  esperado após `FinalQuitf`, não um semáforo de cartão;
- durante o plateau: `gifPk1=0`, `gifPk2=0`, `gifPk3=0`, `gsPrims=0` e
  `gsPixels=0`. Não há evidência de framebuffer ou de comandos GIF.

O caminho nomeado confirma a classe do erro: `sub_00398FE8` é chamado por
`FUN_0020e020`, que a portabilidade identifica como
`swfINSTANCE::operator new(unsigned int)`. Assim, o próximo bloqueio concreto
é uma alocação de aproximadamente 111 MiB rejeitada pelo heap, durante a
leitura/parsing dos dados que precedem o fatal. As linhas `bad=` restantes da
corrida são candidatas secundárias, mas não justificam liberar o loop fatal
sem primeiro medir o argumento de `operator new` e sua origem.

Conclusão honesta: o boot avançou além do plateau do cartão e leu dados reais,
mas ainda não alcançou o pipeline gráfico. A tela continua vazia porque o
primeiro comando GIF nunca foi emitido.

Próximo lote recomendado, em ordem:

1. instrumentar apenas a entrada/retorno de `swfINSTANCE::operator new` e o
   caller imediato, registrando PC/RA, tamanho solicitado e os campos do
   registro de recurso que alimentaram o tamanho;
2. reproduzir com probe determinístico curta, sem alterar a semântica do heap;
3. comparar o tamanho/registro com o decomp e com os bytes do CD no LBA que
   antecede o fatal; corrigir somente a leitura/decodificação comprovadamente
   errada;
4. só depois tratar os `bad` que continuarem no caminho. Não portar a lista
   inteira observada na corrida longa.

Critério de parada permanece: se `gifPkTotal>0` e `gsPrims>0`, parar e
confirmar; `gsPixels>0` será o primeiro framebuffer. Nesta corrida, ambos
continuaram zero.

## Investigação do tamanho de heap — resultado do próximo lote

Data: 2026-08-24

Foi feita uma instrumentação temporária e isolada nas entradas de alocação e
em `FinalQuitf`, recompilando somente quatro objetos e relinkando o runner.
Os hooks foram removidos depois da coleta; o executável final voltou ao estado
sem esse diagnóstico extra. `find_stale.py` terminou com `Missing 0 / Stale 0`.

Resultado decisivo no log intermediário:

- o fatal entrou por `FinalQuitf` com `RA=0x3b01c4`;
- a chamada anterior veio de `memMemoryAllocator::Allocate(unsigned int,
  bool, const char *, int)`, no bloco `0x3b01bc` de
  `FUN_003afe40`;
- o tamanho passado ao formatador foi `0x6f67590`, exatamente
  `116815248` bytes;
- o decomp mostra que esse valor é o `s4`/argumento de tamanho usado na
  checagem de limite do allocator, não uma alocação normal de
  `swfINSTANCE::operator new`;
- as criações normais de `swfINSTANCE` observadas eram `size=0x80`, portanto
  não são a origem do overrun.

O caminho imediatamente anterior passa por chamadas de allocator em
`sub_003B1128`, `sub_003B14D0` e `sub_003B1630`; o valor corrompido precisa ser
seguido desde o produtor que alimenta o registrador de tamanho até
`0x3b16ac/0x3b1204`. A corrida também mostrou repetição de
`bad=0x597e28` antes do fatal, tornando esse o primeiro candidato estrutural a
auditar, mas ainda não há prova suficiente para portá-lo.

Próximo lote recomendado:

1. mapear o produtor do tamanho usado por `sub_003B1630` e os retornos de
   `0x597e28`, incluindo os valores de retorno antes da chamada a
   `memMemoryAllocator::Allocate`;
2. validar os bytes/estrutura de recurso que alimentam esse valor;
3. só corrigir a fronteira ou parser que produzir o `0x6f67590` com evidência
   direta; não aumentar o limite do heap e não ignorar `FinalQuitf`.

Estado visual permanece negativo: `gifPkTotal=0`, `gsPrims=0` e `gsPixels=0`.

## Rastreio do produtor de `0x6f67590` e `bad=0x597e28`

Data: 2026-08-24

O rastreio estrutural encontrou a ligação entre os dois sintomas:

- `bad=0x597e28` não é uma função isolada registrada; é o início de um corpo
  colado dentro de `sub_00597D98`, no intervalo `0x597d98–0x597ff0`.
  O prólogo começa em `sub_00597D98_0x597d98.cpp:216` e não existe alias de
  registro para esse PC;
- o corpo percorre uma tabela de callbacks/objetos (`0x597e60–0x597e88`),
  extrai um tipo com `& 0x7f` e despacha por uma tabela de ponteiros em
  `0x67xxxx` (`sub_00597D98_0x597d98.cpp:317–353`);
- o retorno de `0x597e28` volta ao dispatcher `sub_002B3600` através de um
  `jalr` (`sub_002B3600_0x2b3600.cpp:191`). O fallback do runtime usa
  `RA=0x2b369c`, exatamente o ponto de retorno desse callback;
- `0x2b3600` é `rmcShaderGroup::rmcShaderGroup(datResource &)`, portanto o
  caminho está no carregamento/construção de recurso de shader, não no cartão;
- o overrun continua sendo emitido em `memMemoryAllocator::Allocate`, no
  bloco `0x3b01bc` de `FUN_003afe40`, com tamanho `0x6f67590`.

Interpretação: a hipótese mais forte agora é que o callback de recurso em
`0x597e28` está sendo recuperado incorretamente pelo fallback de PC. Isso pode
deixar o construtor de `rmcShaderGroup` com estado/ponteiro inválido e produzir
o tamanho absurdo que chega ao allocator. Ainda é uma hipótese causal forte,
não uma autorização para ignorar o fatal.

Próximo passo recomendado: portar somente `0x597e28` como split validado do
owner conhecido, com sanity `+1` e probe curta. Aceitação intermediária:
`bad=0x597e28` zerado e o tamanho do allocator deixando de ser
`0x6f67590`. Se o tamanho continuar, parar e investigar o próximo callback;
não aumentar o limite do heap e não transformar `FinalQuitf` em retorno normal.
## Lote seguinte — split explícito `0x597e28`

### Validação antes da execução

O endereço `0x597e28` foi validado como fronteira real dentro do owner
`sub_00597D98`, cujo intervalo é `0x597d98–0x597ff0`. Está alinhado em 4,
começa com `addiu $sp,$sp,-0x30` (prólogo válido), e o epílogo permanece dentro
do owner. Não há função Ghidra independente nem entrada anterior no CSV.

O gerador global permaneceu estável: `same_delta_missing_starts=595`,
`accepted_boundaries=585`, `rejected_boundaries=10`. A configuração recebeu
somente uma nova entrada, `0x00597E28,,,,,`, totalizando 607 linhas no CSV
(+1 em relação às 606 já existentes). Não foi inventado nome alpha, tamanho ou
delta.

### Regeneração e build

`04_run_recomp.bat` foi executado, mas o `ps2_recomp.exe` disponível estava
anterior ao suporte efetivo dessa configuração: não registrou `Loaded/Mapped`
nem gerou o alias. A fonte atual do submódulo contém o mecanismo correto, porém
esta máquina não possui `cmake`/`ninja` disponíveis para rebuildar o recompiler.

Para o teste local, o owner já gerado foi mantido e o registro parcial recebeu
temporariamente apenas o alias equivalente:

```text
runtime.registerFunction(0x597e28u, sub_00597D98_0x597d98);
```

O relink foi serial, com MSYS2 no PATH, e terminou com sucesso. O `find_stale.py`
terminou com `Missing 0 / Stale 0` (CSV stale vazio). Esta limitação de
toolchain fica explícita: o artefato correto de longo prazo é rebuildar o
recompiler e deixar o alias sair exclusivamente de `extra_entry_points`.

### Probe determinístico

Com `MC3_DETERMINISTIC=1`, `MC3_DISPATCH_BUDGET=100000` e
`MC3_BOOT_TRACE=1`, o probe de 120 s produziu 27 amostras até tick 1440.

- `bad=0x597e28`: **0 ocorrências**.
- `Heap overrun` / `FATAL`: **0 ocorrências** neste probe.
- PC amostrado: `0x1a0138 → 0x246130 → 0x55f868 → 0x432f20`.
- Leituras reais de CD: presentes, incluindo `0x10`, `0x105–0x109`,
  `0x14e5be–0x14e64f` e `0x6f06c–0x14e6f0`.
- Mensagens do jogo: `libpad: Module version mismatch`, versão de
  `libpad.a/padman.irx`, aviso de leak de semáforo e versões do `liblgdev`.
- Métricas: `gifPk1=0`, `gifPk2=0`, `gifPk3=0`, `gsPrims=0`, `gsPixels=0`.

O fim foi derivado do trace: o orçamento foi atingido e, logo depois, o game
thread retornou; o loop encerrou com `gameThreadFinished=1` e todos os threads
ativos chegaram a zero. Não é evidência de render nem de framebuffer.

### Conclusão e próximo passo

O lote resolveu o bloqueio estrutural do callback `0x597e28` e eliminou o
plateau/fatal observado anteriormente. O projeto ainda não colocou pixels na
tela. O próximo lote deve investigar o primeiro bloqueio nomeado após
`0x432f20`/`0x55fcdc`, priorizando a semântica do subsistema indicado pelo
trace (libpad/lgdev ou a próxima chamada de inicialização), com uma única
fronteira comprovada por vez. Não aumentar heap nem ignorar o fatal.

## Corrida longa seguinte — calibração de progresso

Foi executada uma corrida determinística com `MC3_DISPATCH_BUDGET=5000000`,
`MC3_BOOT_TRACE=1` e timeout de 900 s. O log foi processado por
`tools/analyze_longrun.py` em `work/exports/longrun_next.md`.

- 323 frames, 17 janelas de dispatch, até tick 19500;
- não houve `bad=` nem heap fatal;
- LBAs continuaram avançando durante a corrida, alcançando a região
  `0x15a7xx`;
- o PC progrediu até estabilizar em `0x5268a0`, dentro de
  `sub_00526880`/região `lowPsxGfx`, por aproximadamente 4 milhões de
  dispatches;
- a função compara repetidamente os valores em `0x6f9030` e `0x6fd010`,
  atualiza o contador COP0 e retorna somente quando a condição muda;
- término derivado: orçamento atingido após plateau real de uma única PC;
- `gifPk1=0`, `gifPk2=0`, `gifPk3=0`, `gsPrims=0`, `gsPixels=0`.

Durante a análise foi corrigido um falso positivo do próprio parser: o log
teve interleaving entre uma linha `frame` e uma linha `dispatch-window`, que
formava o texto `gsPixels=03567e0`. O parser agora exige separador válido após
cada métrica; a corrida não produziu framebuffer.

### Próxima fronteira

Não há função ausente nem RPC MCMAN novo justificando um stub neste ponto. O
próximo diagnóstico deve rastrear quem produz/atualiza `0x6f9030` e `0x6fd010`
e confirmar se `sub_00526880` é espera legítima do `lowPsxGfx` ou se o contador
de sincronização não está sendo produzido. Só depois dessa prova cabe alterar
runtime; não portar `0x5268a0` como função nova, não aumentar budget/heap para
mascarar o plateau e não ignorar fatal.
## Rastreio do produtor do plateau `0x5268a0`

`0x5268a0` foi auditado estaticamente. Ele é o início do corpo de
`sub_00526880` (`0x526880–0x526900`), chamado por
`lowPsxGfx::SendBuffer` (`sub_00526900`) em `0x5269b8`. O loop lê `0x6f9030`
e `0x6fd010` e permanece em `0x5268a0` enquanto os valores diferem.

Busca estática dos acessos MIPS encontrou:

- `sub_00526710` (`lowPsxGfx::InitClass`) inicializa ambos os globais com o
  mesmo valor (`0x526808` e `0x526814`);
- `sub_003A0BC0` também lê/compara os mesmos endereços em outro wait;
- `sub_00526880` lê/compara os endereços no plateau;
- não apareceu escritor posterior recompilado para atualizar esses globais.

Conclusão: não há base para portar uma nova fronteira em `0x5268a0`. O
bloqueio provável é o produtor de completion da fila lowPsxGfx/DMAC/GS, ou
um evento de sincronização externo ao corpo recompilado. O próximo teste deve
observar a cadeia de DMA/VIF/GS e o estado dos dois globais na entrada do
wait, identificando o produtor legítimo. Não inserir escrita artificial,
`SignalSema`, avanço de contador ou env-gate.

## Probe temporário do owner `sub_00526880` — encerrado

Foi inserido um log temporário apenas na entrada de `sub_00526880`, limitado a
8 chamadas, registrando PC, `0x6f9030`, `0x6fd010`, `a0` e `a3`. O probe foi
determinístico, com `MC3_DISPATCH_BUDGET=100000`, `MC3_BOOT_TRACE=1` e timeout
de 120 s.

- O log não contém nenhuma linha `[diag-lowgfx]`: o owner não foi chamado nessa
  janela de 100k dispatches.
- O trace ainda mostrou `vif=3`, `dma=2`, mas `gifPk1/2/3=0`, `gsPrims=0` e
  `gsPixels=0`; portanto não há evidência de render.
- O PC amostrado avançou por outras regiões (`0x398390`, `0x4bc1ac`,
  `0x432aa0`, `0x3b16b4`, entre outras) e o processo terminou pelo orçamento,
  não por `bad`, heap fatal ou exceção do owner.

O hook temporário foi removido, o owner foi recompilado, o relink fast foi
concluído e `find_stale.py` terminou com `Missing: 0` e `Stale: 0`. Este probe
não prova que o plateau de 5M seja falso; prova somente que a janela curta não
alcança o corpo que contém a espera. O próximo lote deve instrumentar, de modo
temporário e observacional, a conclusão legítima de DMA/VIF/GIF e as transições
dos dois globais, em vez de alterar a espera ou forçar um valor.
