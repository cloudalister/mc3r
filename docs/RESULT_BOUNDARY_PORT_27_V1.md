# RESULT — Passo 27: port de fronteiras alpha → retail (V1)

Data: 2026-08-23  
Base do projeto: `a6a4f10`  
Commit de implementação raiz: `457e9ba`  
Commit do PS2Recomp: `337e8a8`  
Estado: **ACEITE DO PASSO 27 — boundary corrigida e plateau do tokenizer superado; ainda sem imagem/render real**

## Resultado executivo

O diagnóstico do handoff foi confirmado. `0x4f9918` não era um slot de tabela perdido: é o início retail de `zipRead`, colado pelo Ghidra dentro do owner `sub_004F95F8`. As fronteiras verdadeiras foram portadas do `MC.MAP` alpha somente quando duas âncoras vizinhas já casadas provaram o mesmo delta.

O portão global medido bateu exatamente: **595** símbolos alpha tinham delta idêntico dos dois lados, âncoras a menos de `0x2000` e início ainda desconhecido pelo Ghidra. A validação individual aceitou **585** e rejeitou **10** que não formavam um split seguro dentro de owner conhecido. A regeneração adicionou apenas **541 registros novos**, todos vindos da lista configurada; os outros 44 aceitos já estavam registrados por descobertas internas anteriores.

Na corrida determinística final:

- `bad=0x4f9918`: **0**;
- qualquer `bad=`: **0**;
- 17 leituras de CD, incluindo conteúdo de `Dave / ASSETS.DAT` além do header;
- PC final `0x547a20`, dentro de `sceTtyWrite`, com parada somente pelo budget de 100.000 dispatches;
- `gifPkTotal=0`, `gsPrims=0`, `gsPixels=0`.

Portanto o plateau do tokenizer foi superado, mas **continua não existindo nada na tela**.

## Prova da região zipFile

Âncora reproduzida antes da implementação:

```text
zipFile::internalRead alpha  0x4b2bb8
zipFile::internalRead retail 0x4f9c78
delta                        0x470c0
```

Aplicação do mesmo delta aos vizinhos do `MC.MAP`:

| Alpha | Retail portado | Função | Resultado |
|---:|---:|---|---|
| `0x4b2850` | `0x4f9910` | `zipCreate` | emitido |
| `0x4b2858` | `0x4f9918` | `zipRead` | emitido |
| `0x4b2888` | `0x4f9948` | `zipWrite` | emitido |
| `0x4b2890` | `0x4f9950` | `zipSeek` | emitido |
| `0x4b2988` | `0x4f9a48` | `zipSize` | emitido |

O resultado foi 5/5 com os slots retail previamente observados.

## Ferramenta e validação

Foi criado `tools/port_boundaries.py`. Para cada símbolo do `.text` alpha, ele:

1. localiza as âncoras casadas imediatamente anterior e posterior;
2. exige delta idêntico e span entre âncoras menor que `0x2000`;
3. descarta inícios já conhecidos pelo CSV do Ghidra;
4. exige endereço retail alinhado a 4 e dentro de `.text` executável do ELF;
5. exige que o alvo esteja estritamente dentro de um owner gerado existente;
6. exige que `alvo + tamanho alpha` não ultrapasse o fim do owner.

Saída final do script:

```text
alpha_text_functions=16154
matched_anchors=8815
ghidra_known_starts=15812
same_delta_missing_starts=595
accepted_boundaries=585
rejected_boundaries=10
zip_5=0x004F9910,0x004F9918,0x004F9948,0x004F9950,0x004F9A48
```

Os dez rejeitados estão em `work/exports/boundary_port_rejected.csv`, todos com o motivo `not a size-safe split inside an existing owner`. Nenhum deles foi alimentado ao gerador.

O artefato solicitado foi gerado em `work/exports/boundary_port.csv`, com 585 linhas de dados e as colunas:

```text
retail_addr,size,alpha_name,delta,anchor_lo,anchor_hi
```

## Integração por configuração

Não foi adicionada heurística nova em `code_generator.cpp`.

O PS2Recomp recebeu a opção `[general].extra_entry_points`, apontando para o CSV. O carregador resolve caminho relativo ao TOML, valida o cabeçalho/endereço e deduplica a lista. O recompiler mapeia cada endereço configurado para um owner já decodificado e usa o mecanismo existente de resume entries.

Na configuração retail local:

```toml
extra_entry_points = "E:/Games/Emuladores/Sony/mc3recomp/work/exports/boundary_port.csv"
```

Log da regeneração:

```text
Loaded 585 configured extra entry point(s)
Mapped 585 of 585 configured extra entry point(s) to known owners.
Collected 97566 resumable entries across 13551 owners.
```

Dois testes novos cobrem carregamento relativo/deduplicação do CSV e rejeição de endereço inválido. A suíte passou a ter 275 testes.

## Sanity da regeneração

Contagem de registros únicos em `register_functions.cpp`:

| Métrica | Quantidade |
|---|---:|
| Antes | 92.602 |
| Depois | 93.143 |
| Delta real | **+541** |
| Candidatos configurados | 585 |
| Já presentes antes | 44 |
| Configurados ausentes depois | 0 |
| Novos fora da configuração | 0 |

O delta é pequeno e totalmente explicável: `585 - 44 = 541`. Não houve explosão de milhares de falsos positivos.

## Regeneração, compilação, link e testes

- `04_run_recomp.bat`: concluído com os 585 entrypoints configurados.
- O gerador atual reescreve os C++ e atualiza seus mtimes; por isso `parallel_compile.py` recompilou o corpus inteiro: **15.811/15.811**, falhas 0, cerca de 2.049 segundos.
- `tools/find_stale.py`: **Missing 0, Stale 0**.
- Relink final: sequencial, com MSYS2 no `PATH`, concluído em `work/link/partial/mc3_partial.exe`.
- O registro parcial final contém `0x4fa368` e os cinco endereços zip portados.
- Suíte final: **275/275** em `work/logs/pass27_tests_postlink_retry3.log`.

Duas tentativas da suíte deram 274/275 somente no flaky já conhecido `sceGsSyncV waits on VBlank and reports interlaced field parity`; o retry final ficou verde.

### Correção de validação do relink

O primeiro relink foi feito com `fast`. Esse modo reaproveitou `register_functions.partial.cpp` antigo, portanto a medição seguinte ainda mostrou `bad=0x4f9918`. Essa medição foi **invalidada e descartada**, pois não continha os aliases recém-gerados.

Foi então executado o relink normal, que regenerou o registro parcial e confirmou explicitamente:

```text
0x4f9910 -> sub_004F95F8
0x4f9918 -> sub_004F95F8
0x4f9948 -> sub_004F95F8
0x4f9950 -> sub_004F95F8
0x4f9a48 -> sub_004F9980
0x4fa368 -> sub_004FA0D8
```

Somente as corridas posteriores a esse relink são usadas como evidência funcional.

## Corrida determinística válida

Ambiente e comando:

```powershell
$env:MC3_DETERMINISTIC='1'
$env:MC3_DISPATCH_BUDGET='100000'
.\14_run_boot_trace.bat 90
```

Duas execuções válidas acabaram sendo feitas: a primeira comprovou o avanço; a segunda repetiu o mesmo resultado para preservar o log depois que `21_probe_repeat` sobrescreveu o arquivo canônico. O log preservado é `work/logs/pass27_deterministic_100k_final.log`.

| Sinal | Resultado final |
|---|---|
| `bad=0x4f9918` | 0 |
| `bad=0x4fa368` | 0 |
| qualquer `bad=` | 0 |
| leituras `mc3-cdvd-rpc kind=read` | 17 |
| `zipOpen` literal | não apareceu |
| `flag619f40` literal | não apareceu |
| `ASSETS.DAT` literal | não apareceu; conteúdo confirmado pelos LBAs e bytes `Dave` |
| PC estável final | `0x547a20`, owner `0x547900` = `sceTtyWrite` |
| parada | `[boot-trace:dispatch-budget-reached] budget=100000` |
| timeout | não |
| `gifPk1/2/3` máximo | 0 / 0 / 0 |
| `gsPrims` máximo | 0 |
| `gsPixels` máximo | 0 |

LBAs únicos lidos:

```text
0x10, 0x105, 0x106, 0x107, 0x108, 0x109,
0x14e5be, 0x14e5bf, 0x14e64f,
0x6f06c, 0x6f06d, 0x6f070,
0x14e6a0, 0x14e6b0, 0x14e6c0, 0x14e6d0, 0x14e6e0
```

`0x14e5be` contém o header `Dave`; `0x14e5bf` e os demais setores altos provam leitura do conteúdo de `ASSETS.DAT` além do header. O boot avançou ainda até um PC nomeado novo, `sceTtyWrite`, antes de consumir o budget.

## Probe 3x

Comando: `21_probe_repeat.bat 3 probe boundary27`.

| Run | Classificação | PC | Função/região | `bad=` | Render real |
|---:|---|---:|---|---|---|
| 1 | `unknown-loop` | `0x1a0138` | trampoline inicial | nenhum | não |
| 2 | `semaphore` | `0x54bbc4` | `sceSifSearchModuleByName` | nenhum | não |
| 3 | `counters-moved` | `0x4fab1c` | `zipFile::Init` | nenhum | não |

Os probes eram não determinísticos e curtos, com timeout de 8 segundos; por isso os PCs estáveis diferiram. Em 3/3, `gifPkTotal=0`, `gsPrims=0` e `gsPixels=0`. Relatório: `work/boot_probe/repeat_boundary27_20260823_010653.md`.

## Veredito

Os dois critérios do Passo 27 foram atendidos:

1. `bad=0x4f9918` zerou;
2. o tokenizer deixou o plateau e houve leitura real de conteúdo de `ASSETS.DAT`, além de avanço até novo PC nomeado.

O marco visual M4 **não** foi atingido: `gifPkTotal>0 && gsPrims>0` nunca ocorreu. Também não houve primeiro framebuffer (`gsPixels=0`). O projeto continua sem tela, e o novo ponto de investigação fica depois da carga de assets, na região observada de `sceTtyWrite`/sincronização por semáforo, não mais em `zipRead`.

## Regras preservadas

- nenhum `SignalSema` foi injetado;
- nenhum env-gate foi criado;
- scheduler e runtime ficaram intactos;
- nenhum endereço alpha foi usado diretamente no retail sem prova de delta;
- `code_generator.cpp` não recebeu heurística nova;
- nenhum push foi feito;
- `STATUS.md` não foi alterado.

## Artefatos

- `tools/port_boundaries.py`
- `work/exports/boundary_port.csv`
- `work/exports/boundary_port_rejected.csv`
- `work/checkpoints/pass27/register_functions.before.cpp`
- `work/generated/ghidra/register_functions.cpp`
- `work/logs/04_run_recomp.log`
- `work/logs/pass27_tests_postlink_retry3.log`
- `work/logs/pass27_deterministic_100k_final.log`
- `work/boot_probe/repeat_boundary27_20260823_010653.md`

## Reavaliação pós-Passo 27 — próximo passo (2026-08-23)

Investigação feita sobre o log determinístico preservado e o código retail/runtime, sem nova alteração de código. A conclusão anterior de que o próximo ponto estava genericamente em “`sceTtyWrite`/sincronização por semáforo” pode agora ser estreitada: o bloqueio imediato é o ciclo DECI2 de envio do TTY, que o runtime trata como sucesso sem executar os efeitos necessários.

### Cadeia causal comprovada

| Evidência | Leitura |
|---|---|
| O trace termina repetidamente em `pc=0x547a20`, `ra=0x547a2c` | É o laço de polling dentro de `sceTtyWrite` (`0x547900`) |
| `sceTtyWrite` grava `1` em `0x6FE2DC`, chama `sceDeci2ReqSend` e repete `sceDeci2Poll` enquanto esse busy for diferente de zero | A saída depende de uma conclusão assíncrona DECI2; não é espera de semáforo |
| `sceTtyInit` abre o protocolo `0x210` com estado `0x6FE2D0` e handler retail `0x547768` | O jogo já fornece estado e callback legítimos para concluir o envio |
| O handler `0x547768`, no evento `3`, chama a operação DECI2 `-6` para enviar bytes e reduz o campo restante em `estado+4` | Retornar zero sem consumir bytes mantém o envio pendente |
| O mesmo handler, no evento `4`, limpa `estado+0xC` somente quando `estado+4 == 0` | Essa é a escrita legítima que libera `sceTtyWrite` |
| `ps2_syscalls::Deci2Call`, em `System.cpp:900`, ignora operação e parâmetros e sempre retorna `KE_OK` (`0`) | `open`, `reqsend`, `poll` e `ExSend` aparentam sucesso, mas nenhum handle/handler/fila avança e nenhum callback é chamado |

O ciclo atual é, portanto:

```text
sceTtyWrite: busy=1
  -> Deci2Call(op=3 / reqsend): retorna 0, não agenda envio
  -> Deci2Call(op=4 / poll): retorna 0, não chama o handler
  -> busy continua 1
  -> volta a 0x547a20 até acabar o dispatch budget
```

Há uma segunda falha que apareceria mesmo se apenas o callback fosse ligado: a operação `-6` também retorna zero hoje. Nesse caso o handler seria executado, mas consumiria zero bytes, manteria `estado+4 > 0` e o evento `4` ainda não limparia o busy. O conserto precisa cobrir o ciclo mínimo inteiro, não só disparar o callback.

### O semáforo 84 não é o bloqueio do TTY

O `sid=84` pertence ao thread 5, iniciado em `entry=0x42b668`. O log mostra alternância contínua de `WaitSema:wake` e `SignalSema` com retornos em `0x398b28/0x398b50`: esse worker IPC está rodando e acordando, não parado aguardando um sinal ausente. Ele também não referencia o busy `0x6FE2DC` usado pelo TTY.

Os frames em `0x42e738` anteriores ao plateau pertencem ao corpo de `debug_memory_fill` (`0x42e6f0`), não a uma rotina de saída de texto. A partir do tick 540, o PC principal fica estável em `sceTtyWrite`. Assim, não há evidência para injetar `SignalSema`; o caminho causal observado é DECI2.

### Próximo passo recomendado: Passo 28 — conclusão DECI2/TTY

Implementar no runtime um backend DECI2 mínimo e genérico para o fluxo realmente exercitado, mantendo estado por handle e usando o callback registrado pelo guest:

1. `op=1` (`sceDeci2Open`): registrar protocolo, ponteiro de estado e handler, retornando um handle não negativo estável;
2. `op=3` (`sceDeci2ReqSend`): marcar pedido de envio pendente para o handle;
3. `op=4` (`sceDeci2Poll`): avançar o pedido invocando o handler guest com os eventos de envio/conclusão;
4. `op=-6` (`sceDeci2ExSend`): aceitar os bytes pedidos e retornar a quantidade consumida, permitindo ao próprio handler zerar o restante e depois o busy.

A invocação deve reutilizar o mecanismo já existente `rpcInvokeFunction`/`GuestExecutionScope`, não escrever diretamente em `0x6FE2DC`. Antes do probe, adicionar testes focados em `ps2_runtime_kernel_tests.cpp` para `open -> reqsend -> poll -> ExSend -> completion`, incluindo handle inválido e handler ausente. Um trace limitado sob o `MC3_BOOT_TRACE` já existente deve registrar operação, handle, quantidade e uma prévia limitada do payload TTY; isso confirma qual mensagem levou ao primeiro `sceTtyWrite` sem criar env-gate novo.

Não fazer:

- `WRITE32(0x6FE2DC, 0)` direto;
- forçar `sceDeci2ReqSend` a falhar só para escapar do loop;
- injetar `SignalSema`;
- criar override específico de MC3 ou novo env-gate.

### Aceite sugerido do Passo 28

- testes novos provam registro de handler, consumo de bytes e callback de conclusão;
- suíte completa permanece verde;
- trace mostra `0x6FE2DC: 0 -> 1 -> 0` pelo handler retail `0x547768`;
- a corrida determinística de 100k sai de `0x547a20` sem qualquer `bad=`;
- registrar o próximo PC estável, novas leituras e `gifPk1/2/3`, `gsPrims`, `gsPixels`;
- se `gifPkTotal>0 && gsPrims>0`, parar, confirmar 3x e reportar como marco visual.

Não é necessário gastar outra corrida longa antes desse trabalho: trace e código já explicam deterministicamente o plateau atual. Isso resolve o bloqueio causal mais próximo, mas não garante tela por si só; após sair dele, o próximo plateau deve ser medido novamente.
