# RESULT TTY 28 V1

Data: 2026-08-23

Projeto: `<project-root>`

Handoff: `docs/HANDOFF_FASE1_TTY_28.md`

## Resultado executivo

O passo 28 removeu os cinco `TODO_NAMED` de `TTY.cpp`, capturou a saída real
do jogo e avançou o boot para além de dois halts consecutivos:

1. `sceTtyWrite` retail aguardava o ciclo DECI2, não chamava diretamente o
   stub de `TTY.cpp`;
2. depois de o ciclo DECI2 funcionar, o jogo informou que `lgdev.irx` estava
   sendo reportado como `0.00.000` e entrou voluntariamente em
   `lgDevInit: system halted.`;
3. a resposta RPC exata verificada no próprio retail
   (`sid=0x046D046D`, `fno=0xC`, `recv+4=0x010B2400`) fez a versão ser
   aceita como `1.11.036`;
4. a corrida final não estabilizou em halt: terminou pelo orçamento em
   `0x55F868`, dentro de `datParser::AddRecord`, depois de passar por
   parser, inflate e novas leituras reais do CD.

Não há framebuffer ainda. `gifPkTotal=0`, `gsPrims=0` e `gsPixels=0`
em todas as medições.

O aceite foi **parcial**: o avanço além de `sceTtyWrite` e a interpretação
foram comprovados, mas a corrida final produziu apenas 2 linhas TTY reais
(7 somando as três iterações), abaixo das 10 exigidas. Não foram duplicadas
linhas artificialmente para satisfazer a contagem.

## Correção do diagnóstico inicial

O PC `0x547A20` está dentro da função retail `sceTtyWrite`
(`0x547900`), gerada em
`work/generated/ghidra/sub_00547900_0x547900.cpp`. Essa implementação envia
o texto por `Deci2Call`; ela não passa pelo stub C++ homônimo.

Portanto:

- implementar `TTY.cpp` era necessário para completar a semântica normal do
  runtime e eliminar as exceções dos cinco stubs;
- isso sozinho não poderia liberar o boot observado;
- o bloqueio causal era o callback DECI2 ausente, já apontado no apêndice do
  resultado do passo 27.

## Implementação

### Cinco stubs TTY

Arquivo: `PS2Recomp/ps2xRuntime/src/lib/Kernel/Stubs/TTY.cpp`.

- `sceResetttyinit`: não lança; retorna sucesso;
- `sceTtyHandler`: não lança; retorna sucesso;
- `sceTtyInit`: inicializa sem gate e retorna o valor esperado pelo cliente;
- `sceTtyRead`: respeita `fd` e tamanho; sem entrada disponível retorna 0;
- `sceTtyWrite`: aceita stdout/stderr, lê exatamente `len` bytes da memória
  guest, preserva NUL embutido, normaliza controles para log seguro e prefixa
  cada linha com `[tty] fd=N`.

`rg TODO_NAMED TTY.cpp`: zero ocorrências.

### Ciclo DECI2 mínimo

Arquivo: `PS2Recomp/ps2xRuntime/src/lib/Kernel/Syscalls/System.cpp`.

Foi implementado somente o contrato usado pelo retail:

- operação 1 abre endpoint e guarda protocolo, user data e handler;
- operação 3 marca envio pendente;
- operação 4 chama o handler guest com eventos 3 e 4;
- operação -6 consome exatamente os bytes solicitados e envia o payload TTY
  para o log;
- o reset do kernel limpa o estado DECI2.

Não há escrita direta no busy flag do jogo, `SignalSema` injetado, alteração
de scheduler ou gate novo. `MC3_BOOT_TRACE` controla apenas observabilidade.
O próprio handler guest realiza a transição de conclusão.

### Versão lgDev

Arquivo: `PS2Recomp/ps2xRuntime/src/lib/Kernel/Stubs/SIF.cpp`.

A iteração 2 mostrou:

```text
[tty] fd=1 lgDevInit: wrong version of lgDev.irx!
[tty] fd=1 lgDevInit:  liblgdev.a is version 1.11.036
[tty] fd=1 lgDevInit:  lgdev.irx is version 0.00.000
[tty] fd=1 lgDevInit: system halted.
```

O caller retail `lgDevInit` em
`work/generated/ghidra/sub_00531E38_0x531e38.cpp` prova o contrato:

- bind: `sid=0x046D046D`;
- call: `fno=0xC`, recv de `0x240` bytes;
- leitura: word em `recv+4`;
- valor aceito: `0x010B2400`, impresso como `1.11.036`.

O dispatcher SIF agora zera os campos desconhecidos e escreve somente esse
word comprovado. O trace final confirmou:

```text
[boot-trace:mc3-lgdev-rpc] kind=version sid=0x46d046d fno=0xc payload=0x6f6740 size=0x240 version=0x10b2400
```

## Testes adicionados

Três testes permanentes foram adicionados:

1. os cinco stubs TTY, incluindo `fd`, tamanho exato, NUL embutido, ausência
   de overread e leitura sem input;
2. ciclo DECI2 open/request/poll/send com eventos 3 e 4 e conclusão pelo
   handler guest;
3. bind/call lgDev pelo caminho `sceSifSetDma`, verificando status neutro,
   versão em `recv+4` e zero nos campos não conhecidos.

Os três passaram em todas as execuções observadas.

## Validação de build

| Etapa | Resultado |
|---|---|
| Build `ps2_runtime` + `ps2x_tests` | OK |
| Objetos gerados | 15811 cpp / 15811 obj |
| `find_stale.py` | missing=0, stale=0 |
| Relink fast, sequencial, MSYS2 primeiro no PATH | OK, abaixo de 6 min |
| Runner | `work/link/partial/mc3_partial.exe` |

Suíte:

- antes do ajuste lgDev: **277/277**;
- depois do teste lgDev: total **278**;
- estado final repetido: **277/278**, com uma única falha, sempre a flaky
  histórica `sceGsSyncV waits on VBlank and reports interlaced field parity`
  (`second interlaced sceGsSyncV should report odd field`);
- os testes TTY, DECI2 e lgDev passaram;
- log final: `work/logs/pass28_suite_final.log`.

Não declaro a suíte final totalmente verde.

## Três iterações do boot

Ambiente em todas as corridas:

```text
MC3_DETERMINISTIC=1
MC3_DISPATCH_BUDGET=100000
MC3_BOOT_TRACE=1
14_run_boot_trace.bat 90
```

| Iteração | TTY | Resultado causal | Fim |
|---:|---:|---|---|
| 1 | 0 | os stubs TTY não são o caminho do retail; DECI2 não concluía | `0x547A20`, dentro de `sceTtyWrite` |
| 2 | 5 | DECI2 liberado; jogo revelou versão lgDev `0.00.000` e halt explícito | `0x531FE8`, loop de `lgDevInit` |
| 3 | 2 | versão `1.11.036` aceita; mensagem `EZ Wheel Wrapper v3.02`; parser e CD continuam | orçamento em `0x55F868`, `datParser::AddRecord` |

Logs preservados:

- `work/logs/pass28_tty_iteration1.log`;
- `work/logs/pass28_tty_iteration2.log`;
- `work/logs/pass28_tty_iteration3.log`.

## Saída TTY final

Arquivo exigido: `work/exports/tty_boot.txt`.

```text
[tty] fd=1 liblgdev version 1.11.036, built on Sep 15 2004 at 16:27:15
[tty] fd=1 EZ Wheel Wrapper v3.02
```

Contagem da corrida final: **2**.

Contagem real acumulada nas três iterações: **7**.

Interpretação:

- a ausência de `wrong version` e `system halted` na terceira corrida prova
  que o gate lgDev foi vencido;
- `EZ Wheel Wrapper v3.02` é a inicialização subsequente do subsistema de
  volante, não um erro;
- depois disso o jogo volta a carregar e interpretar dados, inclusive nova
  leitura de CD em `lsn=0x14E6F0`, 16 setores, `readOk=1`;
- o fim foi exclusivamente `dispatch-budget-reached`, sem `bad=`,
  `runtime_error` ou outro `TODO_NAMED` executado.

## Progresso e render

Na corrida final:

- tick 1020: entrada no fluxo lgDev/DECI2;
- antes do tick 1080: versão aceita e `EZ Wheel Wrapper v3.02`;
- ticks 1080–1800: PCs variam entre parser, inflate, memória e chamadas de
  recurso;
- tick 1800: orçamento de 100000 atingido em `0x55F868`;
- cinco threads ativas antes do encerramento controlado.

Métricas máximas:

```text
dma=2
vif=3
gifPk1=0
gifPk2=0
gifPk3=0
gifPkTotal=0
gsPrims=0
gsPixels=0
```

Não houve condição M4 e não existe primeiro framebuffer.

## Probe 3x

Comando:

```text
21_probe_repeat.bat 3 595 tty28
```

Relatório:
`work/boot_probe/repeat_tty28_20260823_044532.md`.

| Run | Classificação | PC | Nome/owner | bad | Render |
|---:|---|---|---|---|---|
| 1 | counters-moved | `0x4FC6C8` | `inflate_blocks` | - | não |
| 2 | counters-moved | `0x42E738` | `debug_memory_fill` | - | não |
| 3 | counters-moved | `0x4B2374` | owner `sub_004B2318`, entry registrada | - | não |

As três classificações são consistentes. PCs distintos aqui significam
trabalho real em andamento, não um plateau estável.

## TODO_NAMED observados

Contagem nos três traces: **0**. Nenhum novo stub explodiu depois do TTY.

## Commit local

Submódulo `PS2Recomp`:

```text
ca55442b3d8013a77f5460de69d756182d9ddd16
fix(kernel): implement TTY and DECI2 output
```

Sem push.

## Pasta confiável

A configuração global já contém:

- `approval_policy = "never"`;
- `sandbox_mode = "danger-full-access"`;
- projeto `<project-root>` com
  `trust_level = "trusted"`;
- sandbox Windows `elevated`.

Nenhuma mudança de configuração foi necessária. As falhas de escrita vistas
nesta sessão vieram do helper interno de sandbox do editor de patch, não da
ausência de confiança do projeto; os diffs foram aplicados pelo fallback local
`git apply` e verificados com `git diff --check`.

## Aceite

| Critério | Estado |
|---|---|
| Cinco `TODO_NAMED` do TTY implementados sem lançar | PASS |
| Bytes guest, fd e len respeitados | PASS |
| `[tty]` capturado e interpretado | PASS |
| Pelo menos 10 linhas TTY reais | **FAIL: 2 final / 7 acumuladas** |
| PC além de `sceTtyWrite` | PASS |
| Máximo de 3 iterações | PASS |
| Nenhum novo TODO executado | PASS |
| `find_stale=0` e relink | PASS |
| Suíte final integralmente verde | **FAIL: 277/278, flaky GS conhecida** |
| `gifPkTotal>0 && gsPrims>0` | FAIL / ainda sem render |

## Próximo passo recomendado

Não há evidência para outro patch curto agora. A corrida terminou pelo
orçamento enquanto o PC ainda percorria `datParser::Read`,
`datParser::AddRecord` e `inflate_blocks`.

O próximo passo deve ser novamente diagnóstico sem código:

```text
MC3_DETERMINISTIC=1
MC3_DISPATCH_BUDGET=5000000
MC3_BOOT_TRACE=1
janela máxima: 15 minutos
```

Processar o trace por script, amostrando PCs e nomes, leituras de CD,
`TODO_NAMED`, `bad=`, semáforos e métricas GIF/GS. O orçamento alto funciona
como teto; a janela de 15 minutos é o limite real. Só abrir novo handoff de
código se essa corrida revelar um plateau repetível ou uma mensagem concreta.
