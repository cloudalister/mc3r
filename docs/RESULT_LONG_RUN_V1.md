# Resultado â€” Passo 25: corrida longa de diagnÃ³stico

Data: 2026-08-22. Projeto: `mc3recomp`. Sem alteraÃ§Ã£o de cÃ³digo e sem commit.

## Escopo e honestidade da mediÃ§Ã£o

Comando executado na corrida vÃ¡lida:

```text
MC3_DETERMINISTIC=1
MC3_DISPATCH_BUDGET=5000000
MC3_BOOT_TRACE=1
14_run_boot_trace.bat 900
```

O wrapper aceitou o budget, ofereceu janela de 900 s e nÃ£o registrou timeout. O trace terminou pelo prÃ³prio limite determinÃ­stico de 5.000.000 dispatches, antes de consumir a janela inteira. O artefato usado neste resultado Ã© `work/logs/14_run_boot_trace.log`, com 11.242 linhas e 720.815 bytes; a leitura foi feita exclusivamente por script.

Nota operacional: uma tentativa inicial de chamar `Boot-Probe.ps1` sem `-Mode analyze` executou acidentalmente uma probe curta de 10 s e sobrescreveu o primeiro trace longo. Ela nÃ£o Ã© usada como evidÃªncia. A corrida longa foi refeita com os mesmos parÃ¢metros; este documento usa somente o segundo trace longo Ã­ntegro.

## Resumo executivo

- O jogo inicializou dados reais e avanÃ§ou atÃ© carregamento/tokenizaÃ§Ã£o de assets: `mcCarConfig::mcCarConfig`, `memset`, `zipFile::Init`, `datBaseTokenizer` e `rmcShaderTemplate::Load` aparecem na timeline resolvida pela tabela retail.
- Foram observadas 9 leituras lÃ³gicas de CD e 9 linhas `read-bytes`, todas com `readOk=1`.
- `flag619f40`, `zipOpen`, `ASSETS.DAT`, `mcGame::Execute`, `gfxPipeline::BeginFrame` e `sceGsSyncV` nÃ£o apareceram no log textual nem como funÃ§Ã£o amostrada nos frames.
- `gifPk1`, `gifPk2`, `gifPk3`, `gsPrims` e `gsPixels` permaneceram zero. NÃ£o houve M4 e nÃ£o houve primeiro framebuffer.
- O fim foi causado pelo orÃ§amento determinÃ­stico, nÃ£o por timeout. O PC final foi `0x433d70`, resolvido como `datBaseTokenizer::SkipComment(void)` pela funÃ§Ã£o retail mais prÃ³xima abaixo.

## Linha do tempo

O script percorreu 834 linhas de frame, amostrando a cada 60 frames e adicionando mudanÃ§as de funÃ§Ã£o. `t` Ã© `tick/60`; a funÃ§Ã£o Ã© a entrada retail mais prÃ³xima abaixo do PC em `work/exports/retail_symbol_port.csv`.

| t (s) | PC | FunÃ§Ã£o resolvida | gifPkTotal | gsPrims | gsPixels |
|---:|---:|---|---:|---:|---:|
| 0,02 | `0x001a0008` | antes do primeiro sÃ­mbolo | 0 | 0 | 0 |
| 2 | `0x004adc3c` | `mcCarConfig::mcCarConfig(void)` | 0 | 0 | 0 |
| 3 | `0x00432aa0` | `memset` | 0 | 0 | 0 |
| 4 | `0x00246758` | `iopManager::InitClass(void)` | 0 | 0 | 0 |
| 5 | `0x005a88e4` | `memHeap::InitClass(...)` | 0 | 0 | 0 |
| 6 | `0x004faaf4` | `zipFile::Init(const char *, Stream *)` | 0 | 0 | 0 |
| 7 | `0x0042e738` | `debug_memory_fill(void *, int)` | 0 | 0 | 0 |
| 8 | `0x00433f44` | `datBaseTokenizer::GetToken(char *, int)` | 0 | 0 | 0 |
| 10 | `0x002b4d3c` | `rmcShaderTemplate::Load(datTokenizer &)` | 0 | 0 | 0 |
| 11 | `0x00433d70` | `datBaseTokenizer::SkipComment(void)` | 0 | 0 | 0 |
| 24 | `0x002b4d3c` | `rmcShaderTemplate::Load(datTokenizer &)` | 0 | 0 | 0 |
| 124 | `0x00433d70` | `datBaseTokenizer::SkipComment(void)` | 0 | 0 | 0 |
| 208 | `0x002b4d28` | `rmcShaderTemplate::Load(datTokenizer &)` | 0 | 0 | 0 |
| 322 | `0x00433d70` | `datBaseTokenizer::SkipComment(void)` | 0 | 0 | 0 |
| 535 | `0x00433d70` | `datBaseTokenizer::SkipComment(void)` | 0 | 0 | 0 |
| 720 | `0x00433d70` | `datBaseTokenizer::SkipComment(void)` | 0 | 0 | 0 |
| 825 | `0x00433d70` | `datBaseTokenizer::SkipComment(void)` | 0 | 0 | 0 |

A distribuiÃ§Ã£o dos 834 frames foi: `datBaseTokenizer::SkipComment` 713, `rmcShaderTemplate::Load` 55, `datBaseTokenizer::GetToken` 48, e 1 ocorrÃªncia de cada `mcCarConfig`, `memset`, `iopManager::InitClass`, `memHeap::InitClass`, `zipFile::Init`, `debug_memory_fill` e `strcasecmp`. O plateau final Ã© uma tokenizaÃ§Ã£o repetitiva, nÃ£o o loop principal de gameplay/render.

## Leituras do CD

Contagem: 9 linhas `kind=read` e 9 linhas `kind=read-bytes`; 9 LBAs Ãºnicos. Todas as leituras tiveram `readOk=1`.

| LBA | OcorrÃªncias | Setores |
|---:|---:|---:|
| `0x10` | 1 | 1 |
| `0x105`â€“`0x109` | 5 | 1 cada |
| `0x14e5be` | 1 | 1 |
| `0x14e5bf` | 1 | 144 |
| `0x14e64f` | 1 | 93 |

O log nÃ£o imprime o literal `ASSETS.DAT`, mas os trÃªs LBAs finais sÃ£o o mesmo intervalo de dados de assets/Dave identificado no passo anterior. Portanto: leitura real confirmada; marcador textual do nome do arquivo, nÃ£o.

## Gates, loop e render

| EvidÃªncia | Resultado |
|---|---|
| `flag619f40` | 0 ocorrÃªncias |
| `zipOpen` | 0 ocorrÃªncias; `zipFile::Init` apareceu em t=6 s |
| `ASSETS.DAT` literal | 0 ocorrÃªncias |
| `mcGame::Execute` | 0 ocorrÃªncias |
| `gfxPipeline::BeginFrame` | 0 ocorrÃªncias |
| `sceGsSyncV` | 0 ocorrÃªncias; nÃ£o repetiu |
| `gifPk1/2/3` | sempre 0 |
| `gsPrims` | sempre 0 |
| `gsPixels` | sempre 0 |
| `dma` | 2 a partir de t=5 s |
| `vif` | 3 a partir de t=5 s |

`dma=2` e `vif=3` sÃ£o atividade de transporte; nÃ£o sÃ£o prova de imagem. O gate pedido (`gifPkTotal>0` e `gsPrims>0`) nÃ£o foi atingido, entÃ£o nÃ£o houve parada antecipada M4. `gsPixels>0` tambÃ©m nÃ£o apareceu.

## Onde parou

Marcadores finais do log:

```text
[boot-trace:dispatch-budget-reached] budget=5000000 pc=0x433d70 ra=0x433d78
[boot-trace:loop-exit] tick=49554 stop=1 activeThreads=0 gameThreadFinished=1 pc=0x433d70 ra=0x433d78
[boot-trace:game-thread-return] pc=0x433d70 ra=0x433d78
[boot-trace:shutdown] activeThreads=0 gameThreadFinished=1
```

NÃ£o houve `timeout reached`. Houve 3 `WaitSema:block`; o Ãºltimo foi `tid=4 sid=67`, mas o shutdown ocorreu depois do orÃ§amento e nÃ£o hÃ¡ evidÃªncia suficiente para classificar o fim como deadlock de semÃ¡foro. TambÃ©m houve 70 menÃ§Ãµes de `bad=0x4f9918` e 69 `dispatch:recover-pc` para esse mesmo endereÃ§o, com fallback para `0x3994bc`; Ã© ruÃ­do/recovery repetido durante a carga, nÃ£o o motivo terminal observado.

## Nova calibraÃ§Ã£o proposta

Para a prÃ³xima mediÃ§Ã£o, manter os trÃªs env-vars e subir juntos budget e janela:

```text
MC3_DETERMINISTIC=1
MC3_DISPATCH_BUDGET=20000000
MC3_BOOT_TRACE=1
14_run_boot_trace.bat 3600
```

Isso dÃ¡ 4x o headroom de dispatch e uma janela de 60 minutos, coerente com o fato de a corrida atual ter consumido o budget ainda dentro do plateau de `datBaseTokenizer`. O critÃ©rio de conclusÃ£o deve ser sair desse plateau e observar `mcGame::Execute`/`gfxPipeline::BeginFrame`/`sceGsSyncV`, ou atingir `gifPkTotal>0` e `gsPrims>0`; budget novamente atingido sem avanÃ§o nÃ£o deve ser chamado de travamento. Se 20M ainda terminar no mesmo tokenizer, a calibraÃ§Ã£o seguinte deve dobrar para 40M/7200 s, sem alterar cÃ³digo.

## Artefatos e reprodutibilidade

- Trace: `work/logs/14_run_boot_trace.log`
- stdout: `work/logs/14_run_boot_trace.log.stdout`
- stderr: `work/logs/14_run_boot_trace.log.stderr`
- SÃ­mbolos usados: `work/exports/retail_symbol_port.csv`
- Commit observado: `5f788f592d37f0695285294d60efd869f2a1abc3`
- `git status --short`: limpo apÃ³s a remoÃ§Ã£o dos parsers temporÃ¡rios.

