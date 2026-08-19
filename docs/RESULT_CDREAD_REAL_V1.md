# Resultado — leitura de CD real (Fase 1, passo 16)

Executa `docs/HANDOFF_FASE1_CDREAD_REAL.md`. Data: 19/08/2026. Branch `mc3` (fork local,
sem push), submódulo `PS2Recomp` commit `85945ba` (base `289e4dd`, Fase 2c aceita). Docs no
repo raiz.

## Resumo (3 linhas)

Achado maior desta sessão: o binário usado para medir o boot (`mc3_partial.exe`) estava
linkado com objetos de código de jogo **de até 41 dias atrás** (7 de julho a 5 de agosto),
enquanto o gerador foi corrigido e todo o código foi regerado em 18/08 — corrigido
recompilando os batches afetados. Com o binário honesto, o gate `0x245720` (loop de
`sceCdRead` dentro de `psxCdCache::RawRead`) **não caiu** nesta sessão: o boot trava antes
de emitir a chamada SIF real de `sceCdRead` (fno=1), num mecanismo de um subsistema
diferente (RPC sid `0x8000059c`, provavelmente o módulo de áudio, "depois do CD" na própria
tabela de `docs/SIF_PROTOCOL.md`) já documentado como não resolvido em julho
(`MASTER_PLAN_TITLE_SCREEN.md`: "fila de comandos 0x704200 sem consumidor"). O trabalho de
CD em si avançou: o sid do N-cmd estava errado (`0x80000596`, nunca usado pelo binário
retail — corrigido para `0x80000595`, confirmado por trace+decomp), o backend de leitura
real do ISO (`readCdSectors`) nunca estava conectado ao runner de verdade (só nos testes) —
corrigido — e uma prova permanente byte-a-byte contra o ISO real foi adicionada à suíte.

## Achado 1 — binário stale (bloqueio pré-existente, não deste handoff)

### Evidência

`work/generated/ghidra/*.cpp` (código gerado, fonte de verdade após a correção do
formatter/jump-table de 18/08 — `RESULT_FORMATTER_RESUME_V1.md`, "95 gaps fechados em 80
funções, repo inteiro") tem **15812 arquivos**, todos regerados em 18/08 03:26 (verificado
por mtime). Os objetos compilados em `work/compile/ghidra/*/obj/*.o` (o que estava
efetivamente linkado em `mc3_partial.exe`) estavam **desatualizados em 15809/15812 casos**
— a maioria de 04-05/08, e as funções centrais da cadeia de CD/SIF investigada aqui
(`sub_00549680`, `FUN_005422C8`≈`sceCdRead`, `FUN_00541760`≈`_sceCd_ncmd_prechk`,
`sub_00548BC8`, `sub_00549488`, `sub_0054D6A0`, `sub_00547608`, `FUN_00541968`,
`sub_0054D570`) datavam de **08/07** — o objeto de `sub_00549680` ainda continha uma string
de trace `"[boot-trace:sub_00549680:entry]"` de um experimento de julho que **não existe em
nenhum lugar do código-fonte atual** (nem em `PS2Recomp/`, nem em
`work/generated/ghidra/sub_00549680_0x549680.cpp`, que hoje é um recompile fiel sem
instrumentação nenhuma) — prova direta de que o binário rodava código órfão, não o gerador
atual.

Isso significa que **toda medição de boot feita nesta máquina desde a regeneração de 18/08,
incluindo potencialmente a aceitação da Fase 2c, mediu comportamento de objetos antigos**
para qualquer função fora do conjunto específico recompilado por aquele passo (80 funções).
Não valido/invalido a Fase 2c aqui — fora de escopo deste handoff — mas registro o achado
porque bloqueava diretamente a leitura de trace deste passo.

### Causa raiz da falha de compilação (achado secundário)

`tools/Compile-GeneratedBatch.ps1` (e invocações diretas de `g++`) falhavam **silenciosamente**
(exit 1, zero texto de erro) quando `C:\msys64\ucrt64\bin` não estava no `PATH` do processo
que spawna `g++`/`cc1plus`: `cc1plus.exe: error while loading shared libraries: libmpfr-6.dll:
cannot open shared object file`. O DLL existe (`C:\msys64\ucrt64\bin\libmpfr-6.dll`), só não é
encontrado porque `cc1plus.exe` mora em `ucrt64\lib\gcc\...\` (diretório irmão, não no PATH de
busca de DLL do Windows a menos que `ucrt64\bin` esteja no `PATH` do processo). Confirma a nota
"PATH MSYS2 sempre" do handoff — mas o gotcha específico (que a falha é muda, sem nenhum
stderr) não estava documentado; deixo aqui para o próximo executor não perder tempo.

### Correção

Recompilados `batch_0053` e `batch_0054` (501 funções, as duas que cobrem toda a cadeia
DiskReady/prechk/read investigada) com `PATH` corrigido: **500/501 na primeira passada**, 1
falha (`FUN_005476d0`) foi *internal compiler error: Segmentation fault* transitório do
`cc1plus` (gcc 16.1.0 MSYS2) sob carga — sucesso limpo numa segunda tentativa isolada.
Relink (`10_link_partial_runner.bat fast`) confirmado: a string órfã de `sub_00549680`
desapareceu do exe (`grep -c "549680:entry" mc3_partial.exe` → `0`). Trace pós-correção
(exe honesto) reproduz **exatamente a mesma contagem e sequência de eventos SIF** do trace
pré-correção (56 `sceSifSetDma`, mesmos sids/fnos/payloads) — ou seja, o comportamento
observável desta cadeia específica não mudou com objetos frescos (as funções recompiladas
eram funcionalmente equivalentes às antigas para este caminho de boot), mas a evidência
agora é honesta e a regra "exe mais novo que a lib" não basta sozinha — falta também "objeto
de jogo mais novo que o gerador" pra próximas sessões.

## Achado 2 — trace do estado atual (antes das mudanças de código de CD)

Trace de 90s (`MC3_DETERMINISTIC=1 MC3_DISPATCH_BUDGET=25000`), binário já honesto (achado 1
corrigido):

- `mc3-cdvd-rpc kind=init sid=0x80000592 fno=0x0` — 1x, igual ao passo anterior (aceito).
- **`mc3-cdvd-rpc kind=read` (fno=1): 0x, igual ao passo anterior.** O cliente N-cmd nunca
  chega a emitir a chamada real de `sceCdRead`.
- Binds observados (`cmd=0x80000009`) além de `init`: `0x80000593` (S-cmd, fno=0x22 não
  reconhecido — fora de escopo), **`0x80000595`** (client em `0x620D50`, com uma call
  subsequente `fno=0xe recv=4B send=0` — assinatura exata de `sceCdNcmdDiskReady` no decomp:
  `sceSifCallRpc(client,0xe,0,0,0,recvAddr,4,0)`), e `0x8000059c` (client em `0x6faed0`,
  retentado 5x com `fno=0 send=4 recv=4`, nunca satisfeito, sempre caindo no fallback
  genérico de zero-fill).
- Depois da 5ª tentativa de `0x8000059c`, **nenhuma outra chamada SIF acontece pelo resto
  dos 90s** — o boot fica preso num spin puro (`vblank-tick`=512, `frame`=17-34 conforme a
  corrida) sem produzir mais tráfego SIF, e cai no gate `0x245720` de sempre por esgotamento
  de orçamento (`dispatch-budget-reached budget=25000`).

### Identificação de `0x8000059c` (leitura do código gerado fresco, não decomp alpha)

Cross-referenciando `alpha_decomp_sce.txt` com o código gerado **fresco** e confirmado
compilado (`work/generated/ghidra/FUN_00541760_0x541760.cpp`, `sub_00548C78_0x548c78.cpp`):

- `FUN_00541760` é `_sceCd_ncmd_prechk` (estrutura idêntica ao decomp alpha: sema `fba8`
  em `0x61FBA8`, cache `fbbc` em `0x61FBBC`, e o laço de bind em `0x80000595` client
  `0x620D50` checando o flag de conclusão em `+0x24` = `0x620D74`). Esse laço **já é
  satisfeito hoje** pelo handler genérico de bind (`SIF.cpp`, grava `1` em `auxAddr+0x24`
  para qualquer bind com `requestId != 0`) — por isso o bind de `0x80000595` só aparece
  1x no trace (sucesso na primeira tentativa), não em loop.
- `sub_00548C78`, chamado por ambos os caminhos (rápido/lento) de `_sceCd_ncmd_prechk`
  **antes** do teste de `fbbc`, não toca nenhum sid de RPC — é inicialização de infraestrutura
  SIF local (registra handlers de `SIF_CMD` 8/9/0xA/0xC via `func_548800`, consulta/grava
  registradores SIF via `sceSifGetReg`/`sceSifSetReg`), guardado por uma flag de "já rodou"
  (`0x621870`) — não é a origem de `0x8000059c`.
- `grep` por `0x59c` no código gerado aponta para **`sub_005420C0`** — já citado em
  `BRAIN.md:470` (achado de julho, pré-símbolos): "`59c` made `sub_005420C0` return `v0=1` in
  the early loop, but the outer boot loop still did not exit". Não é `_sceCd_ncmd_prechk` nem
  parte da cadeia de `sceCdRead`; é um subsistema separado. `docs/SIF_PROTOCOL.md` já
  classificava esse tipo de tráfego pós-cdvd como o módulo de áudio custom
  (`SCREAM.IRX`/`LGAUD.IRX`, "depois do CD", fnos ainda não extraídos).

**Conclusão**: o gate atual não é mais o protocolo de CD em si (que está corrigido e pronto
pra ser exercitado assim que o boot chegar lá) — é um subsistema diferente, sequenciado
*antes* da chamada de leitura na ordem de boot desta build, cujo bloqueio já estava
documentado e sem solução em julho (fila `0x704200` sem consumidor). Resolvê-lo é trabalho
de um handoff próprio, não deste.

## Implementação (decomp-dirigida, sem chute)

Arquivo: `PS2Recomp/ps2xRuntime/src/lib/Kernel/Stubs/SIF.cpp` (dispatcher `handleCdvdRpc`) e
`PS2Recomp/ps2xRuntime/src/lib/ps2_runtime.cpp` (`configureIoPathsFromElf`).

1. **Sid do N-cmd corrigido**: `kMc3CdvdNcmdSid` de `0x80000596` (nunca usado pelo binário
   retail, vinha de uma tabela documentada mas não verificada em `SIF_PROTOCOL.md`) para
   `0x80000595` (confirmado por trace + pelo código gerado fresco de
   `_sceCd_ncmd_prechk`/`sceCdNcmdDiskReady`, achado 2 acima). Mantido
   `kMc3CdvdNcmdSidLegacyAlias = 0x80000596` como fallback caso outro caminho de código
   ainda use o valor antigo — nenhum uso observado nesta sessão.
2. **`sceCdNcmdDiskReady` (fno=0xe) reconhecido explicitamente**: antes caía no fallback
   genérico de zero-fill (`mc3-rpc-response-fallback`); agora tem um ramo próprio no
   dispatcher cdvd (`kind=diskready` no trace), documentado com o layout exato do decomp
   (`sceSifCallRpc(client,0xe,0,0,0,recvAddr,4,0)`, send=0/recv=4B). O byte de resposta
   continua neutro (`0`, que já era o valor efetivo antes) — a mudança é só reconhecimento
   e observabilidade, não comportamento.
3. **`sceCdRead` (fno=1)**: layout do send de 0x18 bytes (`_sceCd_ncmdsdata`: `+0x0` lsn,
   `+0x4` sectors, `+0x8` buf, `+0xc..+0xe` bytes de modo, `+0x10`/`+0x14` ponteiros para
   `_sceCd_rd_intr_data`/`_sceCd_Read_cur_pos`) já estava implementado corretamente desde o
   passo 1 (`RESULT_CDVD_DISPATCH_V1.md`) e **não foi alterado** — só o sid que o roteia
   estava errado, o que explica por que nunca disparava. Continua zerando os 0x90 bytes de
   `_sceCd_rd_intr_data` (TODO documentado, `_sceCd_cd_read_intr` fora do decomp exportado) e
   limpando `_sceCd_c_cb_sem` (não é `SignalSema()`, é a flag SDK simples que `sceCdSync`
   faz polling) pelo caminho já aceito.
4. **Backend de leitura real do ISO conectado ao runner** (a lacuna real do handoff):
   `readCdSectors` (`Kernel/Stubs/Helpers/Support.h`) já sabia ler de `IoPaths::cdImage` via
   `seek(lbn*2048)+read`, mas **esse campo nunca era configurado fora dos testes** — o
   runner de verdade (`14_run_boot_trace.bat`, `21_probe_repeat.bat`) nunca setava
   `cdImage`, então qualquer LBN não previamente registrado por `sceCdSearchFile` falhava
   sempre. `configureIoPathsFromElf` agora sonda `elfDirectory.parent_path() /
   "Midnight Club 3 - DUB Edition Remix.iso"` (a raiz do projeto, um nível acima de
   `extracted_iso\`) e configura `cdImage` incondicionalmente se o arquivo existir — sem
   env-gate, sem afetar máquinas/CI sem o ISO (silenciosamente não faz nada). Confirmado no
   trace: `[boot-trace:mc3-cd-image] path=...\Midnight Club 3 - DUB Edition Remix.iso`.

## Verificação bytes-vs-ISO

Não foi possível observar `kind=read` disparando ao vivo nesta sessão (achado 2). Em vez de
inventar uma prova ad-hoc, foi adicionado um **teste permanente** à suíte
(`ps2xTest/src/ps2_runtime_io_tests.cpp`, `"sceCdRead bytes match the real retail ISO when
present"`): procura o ISO real subindo até 6 diretórios a partir do cwd do binário de teste
(pula limpo, sem falhar, se não encontrar — máquinas sem o ISO continuam verdes), configura
`cdImage` para ele, chama `ps2_stubs::sceCdRead` pedindo o LBN `0x10` (descritor de volume
primário ISO9660 — sempre não-zero em qualquer disco válido, ao contrário do LBN 0), e
compara os 2048 bytes escritos no buffer guest contra uma leitura direta do host no mesmo
offset (`lbn*2048`) do mesmo arquivo. **Resultado: passou** — os bytes batem exatamente. Isso
exercita o mesmo backend (`readCdSectors`) usado tanto por `ps2_stubs::sceCdRead` (CD.cpp)
quanto pelo handler cdvd N-cmd (SIF.cpp) — é a prova de que a leitura real funciona
corretamente assim que for alcançada, não uma alegação sem verificação.

## Build e suíte

- `ps2_runtime`/`ps2x_tests` (cmake --build, PATH MSYS2 corrigido): OK a cada mudança
  (3 rebuilds incrementais nesta sessão).
- Suíte completa (272 testes agora, +1 do teste novo), de `PS2Recomp\out\build`:
  - 1ª rodada (antes do teste novo, após o fix de sid): **270/271** — falha isolada:
    `sceGsSyncV waits on VBlank and reports interlaced field parity`, o flake de timing de
    VBlank em modo não-determinístico já documentado em `RESULT_FASE2C_V1.md` e sessões
    anteriores, não relacionado a SIF/CD.
  - 2ª rodada (com o teste novo, após o fix de cdImage): **272/272**, limpo, incluindo o
    teste novo do ISO real. Nenhuma falha nova, nenhuma falha relacionada a este handoff.

## Relink

`10_link_partial_runner.bat fast` via PowerShell, 3x nesta sessão (uma por mudança de
runtime lib). Exe sempre mais novo que a lib, checado a cada relink:
- Batches recompilados: `work\compile\ghidra\batch_0053` e `batch_0054` → relink →
  `mc3_partial.exe` 2026-08-19 03:17:59 (518.656.274 bytes).
- Fix de sid (SIF.cpp): → relink → 03:23:37 (518.657.527 bytes).
- Fix de cdImage (ps2_runtime.cpp): → relink → 03:26:49 → 03:29:54 (518.672.473 bytes, após
  ajustar o log pra `std::cerr` gated por `MC3_BOOT_TRACE` em vez de `RUNTIME_LOG`, que é
  no-op fora de build `_DEBUG`).

## Trajetória do gate

**`0x245720` não caiu.** Mesmo Stable PC do baseline aceito na Fase 2c, confirmado 3/3 em
`21_probe_repeat`-equivalente (`tools/Probe-Repeat.ps1 -Runs 3 -Mode probe -Seconds 90`,
relatório `work/boot_probe/repeat_cdread_real_v1_20260819_033206.md`): 1 Stable PC único,
`marker=yes timeout=no` em 3/3, `counters-moved` (dma=2, resto zerado), zero falhas de
evidência determinística. As mudanças deste passo não regrediram a Fase 2c nem introduziram
não-determinismo novo — só não foram suficientes para passar do bloqueio de `0x8000059c`.

## Régua de render (M0-M6)

Inalterada: `gifPkTotal=0`, `gsPrims=0`, `gsPixels=0`, `gif=0`, `gsw=0` em todas as corridas.
M4 não atingido, nada a confirmar/reportar como vitória de render.

## Commits

Submódulo `PS2Recomp`, branch `mc3`, **sem push**:
- `85945ba` — "cdvd: fix N-cmd sid (595 not 596), wire real ISO as cdImage backend, add
  real-ISO byte-match test" (3 arquivos: `SIF.cpp`, `ps2_runtime.cpp`,
  `ps2_runtime_io_tests.cpp`).

Nenhum objeto de código de jogo gerado (`work/generated`, `work/compile`) foi commitado —
são artefatos de build locais, fora do repo por regra (`WORKFLOW.md`: "código gerado do
ELF" não vai pro repo público).

Repo raiz (`mc3recomp`, branch `mc3`), **sem push**: este documento + ponteiro do submódulo,
commitados pelo executor.

## Bloqueios / limitações documentadas

1. **O bloqueio real que impede `sceCdRead` de disparar não é do protocolo cdvd** — é o
   subsistema em `sub_005420C0`/sid `0x8000059c` (provável módulo de áudio custom, "depois
   do CD" em `docs/SIF_PROTOCOL.md`), já sem solução desde julho
   (`docs/MASTER_PLAN_TITLE_SCREEN.md`: fila de comandos `0x704200` sem consumidor). Meu
   escopo era só CD; não implementei um handler para `0x8000059c` porque não há decomp
   nomeado dele (é `sub_` sem símbolo) e a regra do handoff proíbe chute — precisa de decomp
   dirigido próprio (nome, fnos, layout) antes de qualquer implementação.
2. **Achado do binário stale é mais amplo que este handoff**: 15809/15812 arquivos de código
   de jogo gerado estavam desatualizados em relação aos objetos linkados antes desta sessão.
   Só recompilei os 2 batches (501 funções) na cadeia de CD/SIF investigada aqui — o resto
   do projeto pode ter o mesmo problema em outras cadeias de função. Recomendo ao
   coordenador decidir se vale recompilar tudo (custo alto, tempo desconhecido para 15812
   arquivos) ou manter a prática de recompilar batches sob demanda quando a investigação
   tocar neles (como fiz aqui), documentando a regra "PATH MSYS2 sempre" com o gotcha da
   falha muda por DLL faltando.
3. **`_sceCd_cd_read_intr` (o handler real de conclusão do N-cmd) continua fora do decomp
   exportado** — os 0x90 bytes de `_sceCd_rd_intr_data` continuam neutros/zero (TODO), sem
   mudança desde o passo 1. Não foi possível validar contra hardware real ou captura PCSX2
   nesta sessão (fora de escopo/tempo).

## Avaliação frente ao critério de aceite do handoff

Aceite pedia: trace mostrando read com LBA real → bytes reais no buffer (amostrados contra o
ISO) → conclusão legítima → gate sai de `0x245720`. **Alcançado parcialmente**: o backend de
leitura está implementado, conectado ao ISO real, e provado byte-a-byte (novo teste
permanente, passou). O sid do N-cmd (bug real, não deste handoff) foi corrigido. **Não
alcançado**: o gate não caiu, porque o boot nunca chega a emitir a chamada de leitura nesta
janela — trava antes, num subsistema diferente e já conhecido como não resolvido. Resultado
honesto, conforme a regra do `WORKFLOW.md` ("resultado negativo é entregável").
