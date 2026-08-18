# Resultado — Fase 1, passo 3: gate fileio/provider (`fileio_gate_v1`)

Executa `docs/HANDOFF_FASE1_FILEIO_GATE.md` do início ao fim. Data: 2026-08-17. Branch `mc3`
(fork local, sem push), submódulo `PS2Recomp`.

## Resumo executivo

O gate único determinístico **saiu de `0x5a8908` e avançou substancialmente**: 3 handlers novos
no dispatcher SIF (mesma infra dos passos 1-2, sem env-gate novo, sem `SignalSema` injetado)
levaram o boot de um spin em `sceSifSyncIop` (bem *antes* de `0x5a8908` na rota real) através de
todo o resto do handshake de reboot do IOP (`iopManager::InitClass`/`LoadModule`), até um **novo
gate estável e 100% reprodutível**: `0x528fa0`, um spin em `sceGsSyncV` dentro do pipeline
gráfico, com **`vif=2`** (primeira vez nesta investigação inteira que qualquer contador de DMA
sai de zero). `gif=0`/`gsw=0` ainda — não é a vitória grande, mas é a vitória do passo.

Achado colateral importante (seção 5): o modo `595` do `21_probe_repeat.bat` — o comando mandado
pelo handoff para validação — embute 11 env-gates de experimentos antigos e rejeitados. Eles
eram inofensivos enquanto o boot nunca chegava perto do código que tocam; agora que o boot vai
mais fundo, colidem com o caminho novo e produzem 7 PCs distintos em 10 corridas. Isso **não é
falha do scheduler da Fase 2** (que não foi tocado) nem dos handlers novos: com env limpo (modo
`probe`, sem os 11 flags), 10/10 corridas dão o mesmo `0x528fa0`, igual às 3 corridas do
`14_run_boot_trace.bat`. Ver seção 5 para a evidência completa.

## Contexto que mudou o método logo de cara

O handoff partiu da hipótese de que o gate determinístico atual era `0x5a8908` (documentado em
`docs/RESULT_FASE2_SCHED_V1.md`, medido via `21_probe_repeat.bat ... 595`). A primeira corrida
desta sessão (`14_run_boot_trace.bat`, que usa o modo de trace completo, não o modo `595`) já
mostrou o boot indo **além** de `0x5a8908`, travando antes disso em `0x246740`
(`sceSifSyncIop`, ver Handler 1). Ou seja: o modo `595` e o modo de trace completo não medem o
mesmo caminho de execução (achado da seção 5) — a Fase 2 foi aceita corretamente para o que
mediu (`595`), mas o gate "real" do boot determinístico já estava mais atrás do que o número
`0x5a8908` sugeria. Trabalhei a partir da evidência de cada corrida, não do número documentado.

## Handlers adicionados, em ordem

Todos em `PS2Recomp/ps2xRuntime/src/lib/Kernel/Stubs/SIF.cpp` (fork `mc3`), na função
`sceSifSetDma` (mesmo dispatcher dos passos 1-2) e em `sceSifGetReg`. Um único commit local:
ver seção 4.

### Handler 1 — completion do `sceSifResetIop` (cmd `0x80000003`)

- **Achado (trace):** o boot ficava preso em `0x246740`, dentro de `FUN_002466e0_0x2466e0`
  (`iopManager::InitClass`, `work/exports/retail_symbol_port.csv`), chamando `sceSifSyncIop`
  (`0x0054C000`, decompilado real, não stub) em loop enquanto ela retornasse `0`.
- **Decomp (`alpha_decomp_sce.txt` linhas 6167-6236):** `sceSifResetIop` faz
  `sceSifSetReg(4, 0x40000)` → `sceSifSetDma(...)` (cmd `0x80000003`, payload
  `"rom0:UDNL <path>"`) → se sucesso, `sceSifSetReg(4, 0x10000)` → `sceSifSetReg(4, 0x20000)`.
  `sceSifSyncIop` só retorna `1` quando `sceSifGetReg(4) & 0x40000 != 0` — bit que o próprio
  `ResetIop` nunca deixa setado (ele o limpa de volta para `0x10000`/`0x20000` na sequência
  acima). Na vida real, é o **IOP** que depois marca esse bit no SIF_STAT de hardware quando
  termina de rebootar — algo que este runtime, sem CPU do IOP, precisa emular.
- **Semântica implementada:** o dispatcher de `sceSifSetDma` reconhece `cmd == 0x80000003`
  (antes invisível — só `0x80000009`/`0x8000000A` tinham tratamento) e marca
  `g_sifIopRebootCompleted = true` quando o processa (o produtor legítimo é essa própria
  transferência SIF, tratada como conclusão imediata do "reboot virtual", consistente com o
  modelo síncrono já usado para bind/call). `sceSifGetReg(reg=4)` passa a fazer OR desse bit
  **sempre** (sem env-gate — os dois experimentos antigos equivalentes,
  `MC3_SIF_EXPERIMENT_STAGE2`/`MC3_SIF_EXPERIMENT_LATCH_REG4`, ficaram como fallback inerte,
  não removidos, não usados por padrão).
- **Resultado (1 corrida):** gate saiu de `0x246740` → avançou para `0x246a80` (novo spin, ver
  Handler 3).

### Handler 2 — fallback neutro para respostas RPC não reconhecidas

- **Achado (trace, após Handler 1):** o boot avançava por `iopManager::LoadModule`
  (`0x00246880`, `retail_symbol_port.csv`), fazia bind+call reais para dois servidores
  dinâmicos (`sid=0x80000003 fno=0x1`, `sid=0x80000006 fno=0xff`) — ambos já recebendo
  `signaled=1` do mecanismo genérico de bind/call — mas travava de novo em `0x246a80`, um loop
  que chama `sub_00246660` repetidamente enquanto o retorno for negativo, **sem gerar tráfego
  SIF novo** a cada iteração (evidência de que o bloqueio era conteúdo de resposta, não
  ausência de handshake).
- **Causa-raiz:** o dispatcher só escrevia um flag de "completo" (`auxAddr+0x24`) para
  `cmd=0x8000000A`; nunca preenchia o **payload de resposta em si** (`payloadAddr`/`payloadSize`,
  offsets `+0x28`/`+0x2C` do pacote — os mesmos já usados pelos dispatchers cdvd/usbkb). Bytes
  de pilha/heap reaproveitados, lidos como inteiro com sinal, podiam vir negativos e travar
  qualquer chamador que trate "resposta < 0" como falha — exatamente o padrão em
  `sub_0054BC40`/`FUN_0054b510` (decompilados, `work/generated/ghidra/`).
- **Semântica implementada:** para `cmd == 0x8000000A` não servido por `handleCdvdRpc`/
  `handleUsbKbRpc` nem pelo Handler 3, zera `payloadAddr..+payloadSize` (limite `0x1000`) antes
  de marcar completo. É o valor neutro documentado pela regra do handoff ("campo desconhecido =
  TODO documentado + valor neutro"), nunca um chute de conteúdo real.
- **Resultado (1 corrida):** sozinho, não moveu o gate (o campo específico que travava o loop de
  `iopManager::LoadModule` não é o que este fallback zera — ver Handler 3). Mas é infraestrutura
  necessária: sem ele, toda resposta RPC não mapeada continua vazando lixo de pilha.

### Handler 3 — resposta da query de versão do kernel/módulo (`fno=0xFF`, recv de 4 bytes)

- **Achado (decomp, não chute):** `sub_0054B610_0x54b610` (chamada de dentro de
  `sub_0054BC40`, que por sua vez está em `iopManager::LoadModule`) compara os 4 bytes da
  resposta contra duas constantes **do próprio binário compilado** (não inferidas):
  - VA `0x00621854` → bytes `"2800\0"` (ASCII, lido diretamente do ELF —
    `extracted_iso/SLUS_213.55`, offset de arquivo `0x4818d4`, segmento `PT_LOAD` único,
    `filesz` cobre esse endereço — dado real, não hipótese);
  - VA `0x0062191c` → ponteiro para VA `0x00672ff0` → bytes `"....\0"` (o wildcard de versão
    convencional do ps2sdk, "aceita qualquer versão").
  Isso é o padrão bem conhecido do ps2sdk/homebrew SDK: `fno=0xFF` com recv de 4 bytes é a
  query "qual é a sua versão de kernel/módulo?" que muitos servidores RPC IOP customizados
  implementam antes do cliente confiar no módulo. Não é exclusivo deste jogo.
- **Semântica implementada:** para `cmd == 0x8000000A`, não servido por cdvd/usbkb,
  `requestId == 0xFF` e `payloadSize == 4`, escreve os bytes ASCII `"2800"` no payload (em vez
  do zero neutro do Handler 2, que teria sempre dado "não bate com nenhum dos dois valores
  aceitos"). `fno=0xFF` de tamanho diferente (ex.: o `size=0x8` do `sid=0x80000001`/FILEIO já
  visto no trace, linha `mc3-rpc-response-fallback`) continua caindo no fallback neutro do
  Handler 2 — não generalizei para todos os `fno=0xFF`, só para o formato de 4 bytes que o
  decomp confirma.
- **Resultado (1 corrida):** o gate saiu de `0x246a80` — o boot passou a processar mais eventos
  do mesmo `iopManager::LoadModule` (`sid=0x80000006` recebeu ainda `fno=0x0` e `fno=0x9`,
  ambos servidos pelo fallback neutro do Handler 2) e avançou **muito mais fundo**: chegou em
  código de `gfxPipeline` (`0x528xxx`-`0x529xxx`, `retail_symbol_port.csv`) e parou, estável, em
  `0x528fa0` — um spin em `sceGsSyncV` (`0x00545648`, `retail_symbol_port.csv`) dentro de uma
  função não nomeada `0x528ca0`-`0x5290f0` (logo antes de `gfxPipeline::Begin @0x5290f0`).
  `vif` passou de `0` para `2` — primeiro contador de DMA gráfico não-zero desta investigação.

## Trajetória do gate (PC do Stable PC determinístico, `14_run_boot_trace.bat`, mesma corrida = mesma prova)

| Etapa | Stable PC | Situação |
|---|---|---|
| Antes de qualquer mudança desta sessão (build da Fase 2, commit `c2ec958`) | `0x246740` | Spin em `sceSifSyncIop` — **já além do `0x5a8908` documentado**; ver nota da seção "Contexto" |
| Depois do Handler 1 | `0x246a80` | Spin em `iopManager::LoadModule` (retorno negativo do wrapper de RPC) |
| Depois do Handler 2 (sozinho) | `0x246a80` | Sem mudança — campo zerado não era o que este loop checava |
| Depois do Handler 3 | **`0x528fa0`** | Spin em `sceGsSyncV`, dentro do pipeline gráfico. `vif=2`. **Gate atual, estável.** |

Confirmação de estabilidade (`14_run_boot_trace.bat`, 3 corridas independentes, budget 25000):
todas as 3 pararam em `pc=0x528fa0 ra=0x528fa8`. Com budget `100000` (4x, diagnóstico avulso,
não é a medição oficial): mesmo PC — não é "falta de budget", é um spin real (`sceGsSyncV`
nunca retorna != 0 neste ponto).

## Estado final, honesto

- **Não é a vitória grande.** `gif=0`/`gsw=0` em todas as corridas desta sessão — nenhum frame.
- **É a vitória do passo:** o Stable PC saiu de `0x5a8908` (e do gate real anterior,
  `0x246740`, que nem tinha nome antes desta sessão) e estabilizou em `0x528fa0`, mais fundo no
  boot do que qualquer medição anterior documentada — a primeira vez que `vif` sai de zero.
- **Novo gate nomeado:** `0x528fa0`/`0x528fa8`, dentro da função não nomeada `0x528ca0`-
  `0x5290f0` (`work/generated/ghidra/FUN_00528ca0_0x528ca0.cpp`), chamando `sceGsSyncV`
  (`0x00545648`, `retail_symbol_port.csv` linha `sceGsSyncV`) em loop
  enquanto o retorno for `0`. Não investiguei a fundo *por que* `sceGsSyncV` nunca retorna
  `!= 0` aqui — é a fronteira nova para a próxima sessão (hipótese de trabalho: o VSync
  determinístico da Fase 2 usa um pseudo-participante de prioridade mínima que só é escolhido
  quando a fila de prontos esvazia de verdade; este loop é um busy-poll, não um
  `WaitSema`/`WaitEventFlag` verdadeiro, então pode nunca ceder o suficiente para o
  pseudo-participante de VBlank ser escolhido — **hipótese, não verificada**, e não mexi no
  scheduler para testar isso, por estar congelado por regra).
- Nenhum `SignalSema` foi injetado. Toda conclusão de RPC continua vindo do próprio dispatcher
  SIF processando a transferência real (bind/call) ou, nos Handlers 1/3, da transferência
  administrativa (reset-iop) e da query de versão — sempre o "produtor legítimo" do evento SIF
  correspondente, nunca um sinal direto de semáforo do cliente.

## Seção 5 — achado colateral: `21_probe_repeat.bat ... 595` mede um caminho diferente agora

O handoff manda validar com `21_probe_repeat.bat 10 595 <label>`. Rodei exatamente isso após o
Handler 3:

```
21_probe_repeat.bat 10 595 fileio_gate_v1
-> 7 Stable PCs distintos em 10 corridas (0x3985f4, 0x5a8908 [4x], 0x432aa0, 0x429ff8, 0x54e13c,
   0x234614, 0x2b6ff4)
```

Isso pareceria "não-determinismo novo introduzido pelos handlers" — mas não é. `tools/Boot-
Probe.ps1` mapeia o modo `595` para `pollsid59c595`, que liga **11 env-gates de experimentos
antigos e rejeitados** de uma vez (`MC3_SIF_EXPERIMENT_LATCH_REG4`,
`MC3_SIF_EXPERIMENT_IOP_QUEUE`, `MC3_GS_EXPERIMENT_FIELD_BIT`,
`MC3_SIF_EXPERIMENT_CALLBACK_SIGNAL`, `MC3_SIF_EXPERIMENT_592_PAYLOAD`,
`MC3_SEMA_EXPERIMENT_POLL_RETURNS_SID`, `MC3_SIF_EXPERIMENT_59C_RESULT`,
`MC3_SIF_EXPERIMENT_595_COMPLETE`, `MC3_EXPERIMENT_5422C8_PASS_541760`,
`MC3_EXPERIMENT_704200_QUEUE_DRAIN`, `MC3_SIF_EXPERIMENT_CALLBACK_5413F0`). Eram inofensivos
enquanto o boot nunca alcançava o código que eles tocam (daí a Fase 2 ter aceitado 10/10 em
`0x5a8908` com esse mesmo modo). Agora que os handlers desta sessão destravam bem mais boot,
esses 11 flags passam a interferir de verdade — por exemplo `MC3_SIF_EXPERIMENT_IOP_QUEUE`
reescreve uma região fixa de memória (`seedMc3IopRequestQueueForExperiment`,
`kMc3IopRequestQueueArena=0x00701E00`) sempre que o registrador SIF 4 mostra o bit de stage-2
(que agora fica ligado o tempo todo, graças ao Handler 1) — uma escrita de memória do era
experimental competindo com o boot real.

**Prova de que isso não é bug novo nem do scheduler:**

```
21_probe_repeat.bat 10 probe fileio_gate_v1_cleanmode   (modo "probe" puro, sem nenhum dos 11 flags)
-> 10/10 corridas: Stable PC = 0x528fa0, vif=2, classificação counters-moved, todas com
   Dispatch budget marker=yes, Timeout reached=no. Determinismo perfeito.
```

Isso bate exatamente com as 3 corridas de `14_run_boot_trace.bat` (que também não liga esses
flags). Ou seja: **o boot determinístico em si é 100% estável em `0x528fa0`** — a variação em
`595` é dos 11 experimentos antigos colidindo com o caminho novo, não do trabalho desta sessão
nem do scheduler da Fase 2 (que não foi tocado, por regra).

Não mexi em `tools/Boot-Probe.ps1` nem no significado do modo `595` — está fora do escopo deste
handoff (que é sobre handlers do dispatcher SIF, não sobre a ferramenta de medição) e qualquer
mudança ali afeta comparações históricas de sessões anteriores. Deixo como recomendação
explícita para a próxima sessão: ou usar um modo de medição limpo (`probe`, sem os 11 flags)
como baseline daqui pra frente, ou podar `pollsid59c595` para não incluir os experimentos hoje
comprovadamente supérfluos (`MC3_SIF_EXPERIMENT_LATCH_REG4` virou redundante com o Handler 1,
por exemplo).

## Validação

Ambiente: `cmake-3.30.5-windows-x86_64\bin\cmake.exe`, ninja do
`C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja`,
g++ do `C:\msys64\ucrt64\bin`. Build dir `PS2Recomp\out\build` (existente, não recriado).

| Etapa | Resultado |
|---|---|
| Build (`ninja ps2_runtime ps2x_tests`) | OK, 3 vezes (1 por handler), sem erros/warnings novos |
| Suíte `ps2x_tests` | **269/269** nas 3 rodadas — nenhuma falha, nem a flaky histórica de VBlank apareceu desta vez |
| Relink (`10_link_partial_runner.bat fast`) | 3 vezes, sempre bem dentro do timeout de 6 min. Timestamp final do exe: **2026-08-17 23:43:21** (`work\link\partial\mc3_partial.exe`) |
| `14_run_boot_trace.bat` (`MC3_DETERMINISTIC=1 MC3_DISPATCH_BUDGET=25000`) | 3 corridas independentes após o Handler 3: `pc=0x528fa0 ra=0x528fa8` nas 3 |
| `21_probe_repeat.bat 10 595 fileio_gate_v1` (comando mandado pelo handoff) | 7 PCs distintos — ver seção 5 (causa identificada, não é regressão do trabalho desta sessão) |
| `21_probe_repeat.bat 10 probe fileio_gate_v1_cleanmode` (diagnóstico, mesmo binário, env sem os 11 flags legados) | **10/10 = `0x528fa0`**, determinismo perfeito |

Relatórios brutos: `work\boot_probe\repeat_fileio_gate_v1_20260817_234431.md` e
`work\boot_probe\repeat_fileio_gate_v1_cleanmode_20260817_234643.md`.

## Commits locais (submódulo `PS2Recomp`, branch `mc3`, sem push)

Um arquivo alterado: `ps2xRuntime/src/lib/Kernel/Stubs/SIF.cpp` (+138/-2). Commit:
`fileio: reset-iop completion + neutral RPC response fallback + kernel-version query response`
(ver `git log` no submódulo para o hash exato após o commit desta sessão).

## Próximos passos sugeridos (não executados nesta sessão)

1. Investigar por que `sceGsSyncV` (`0x00545648`) nunca retorna `!= 0` em `0x528fa0` — provável
   fronteira "VSync determinístico vs busy-poll", ver hipótese na seção "Estado final".
2. Limpar ou substituir o modo `595` de `21_probe_repeat.bat`/`Boot-Probe.ps1` (seção 5) antes de
   usá-lo como baseline de novo.
3. `sid=0x80000006`/`fno=0x0`/`fno=0x9` (vistos após o Handler 3, servidos hoje pelo fallback
   neutro do Handler 2) são bons candidatos a próximos handlers com semântica real, se o novo
   gate (`sceGsSyncV`) não depender deles.
