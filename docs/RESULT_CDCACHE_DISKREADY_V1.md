# Resultado — passo 11: gate `0x245718` NÃO é diskready/cdvd (achado negativo, honesto)

Data: 2026-08-18. Executor: Claude (Sonnet 5). Handoff: `docs/HANDOFF_FASE1_CDCACHE_DISKREADY.md`.

## Resumo (1 linha)

O trace mostra que o gate `0x245718` **não chama nenhuma função SIF/cdvd** — é um `PollSema`
de kernel cujo valor de retorno está com contrato errado (bug pré-existente, não relacionado a
CD); a causa real mora dentro do arquivo que a Fase 2 (scheduler determinístico, aceita hoje)
lista como ponto de troca de contexto, então **não foi corrigida aqui** (regra do
`WORKFLOW.md`: bug em camada congelada vai pro RESULT, não pra dentro de outro handoff). Zero
linhas de código mudaram. Zero commits.

## O que o handoff assumia vs. o que o trace mostrou

O handoff (e `SYMBOL_PORT_REPORT.md`/`STATUS.md`) descrevia `0x245718` como o loop de
`psxCdCache::RawRead` esperando `sceCdDiskReady`/`sceCdNcmdDiskReady` retornar `2`
(`SCECdComplete`), com `0x5420C0` identificado como `sceCdDiskReady` — mas essa identificação
já estava marcada como **"vizinhança"** (heurística não confirmada) em
`docs/SYMBOL_PORT_REPORT.md` linha 34. Este passo fez a confirmação empírica que faltava, e ela
contradiz a heurística.

### Trace 1 — estado atual (sem mudança nenhuma), prova do bloqueio

`MC3_DETERMINISTIC=1 MC3_DISPATCH_BUDGET=25000 MC3_BOOT_TRACE=1`, `14_run_boot_trace.bat 30`,
log completo em `work/logs/14_run_boot_trace.log` (ignorado pelo git, `work/`).

- PC estável: `0x245718`, `ra=0x245734`, **1571 ticks** até `dispatch-budget-reached`
  (budget=25000), determinístico (mesma trajetória o tempo todo).
- Único evento `mc3-cdvd-rpc` no log inteiro: `kind=init sid=0x80000592 fno=0x0` (o init do
  passo 1, já implementado, 2 ocorrências — nada relacionado ao gate). **Nenhuma** linha
  `mc3-cdvd-rpc kind=read`, nenhuma chamada a `sceCdRead`/`sceCdNcmdDiskReady` via SIF em
  nenhum momento da corrida.
- Nas ~1500 iterações do loop, o único syscall repetido é:
  ```
  [boot-trace:PollSema] tid=1 sid=15 count=0->0 ret=-419 experiment=0 pc=0x5469f0 ra=0x54178c
  [boot-trace:PollSema] tid=1 sid=17 count=0->0 ret=-419 experiment=0 pc=0x5469f0 ra=0x542114
  ```
  (`-419` = `KE_SEMA_ZERO`, `Sync.cpp:63`). Nenhum `SignalSema` correspondente aparece depois
  da criação inicial — os semáforos nunca são re-sinalizados nesta janela.

### Decomp/gerado confirmando a identidade real da função

- `work/generated/ghidra/sub_00245680_0x245680.cpp` (0x245680–0x24578C): a função que contém
  `0x245718` faz `jal func_5420C0` com `a0=0`, e em `0x245734` faz
  `bne $v0,$s0(=1), volta pra 0x245718` — ou seja, o loop é `while (func_5420C0(0) != 1)`. Isso
  bate com a forma do loop citado no handoff, mas o corpo de `func_5420C0` não tem nenhum
  `sceSifSetDma`/`sceSifCallRpc` — só chamadas a `PollSema`/`SignalSema` e a funções de
  render/DMA (`func_549488`, citada em `docs/MASTER_PLAN_TITLE_SCREEN.md` como parte da cadeia
  de render, não de CD).
- `work/generated/ghidra/sub_005420C0_0x5420c0.cpp` (0x5420c0–0x5422C8): em `0x542100` chama
  `func_5414A8` (== `coreFileWaitCreateSema`-like, ver abaixo); em `0x54210C` (`ra=0x542114`)
  chama `PollSema_0x5469f0(sid = *0x61FBB0)`; em `0x542114` relê o mesmo global e compara
  (`bne $v1,$v0 → 0x542248`); no braço de "não bate" (`0x542244`/`0x542248`), monta
  `$a0 = $s2 ^ 8` (`$s2` é o próprio parâmetro `0` da função) `= 8` (≠0), então o `movz`
  seguinte **não** dispara e a função retorna sempre `6` — o valor que o loop externo trata como
  "ainda não pronto". Ou seja: `func_5420C0(0)` só retorna `1` (e sai do loop) quando
  `PollSema(...)` devolver exatamente o **id do semáforo**, não `KE_OK`.
- `work/generated/ghidra/FUN_005414a8_0x5414a8.cpp` (0x5414a8–0x541560): cria (lazy, uma vez só)
  3 semáforos binários (`init=1,max=1`) guardados em globais `0x61FBA8/0x61FBAC/0x61FBB0` — bate
  exatamente com o `CreateSema` logado (`id=15..18`, `attr=0x620000`, `ra=0x541510/0x54151c/
  0x541528/0x541538`). Esse padrão (criar N semáforos lazy + resetar um contador de fila) é a
  assinatura de um "wait-create-sema" genérico de biblioteca — não é código específico de CD.

### O bug real: `PollSema` não devolve o id do semáforo no sucesso

`PS2Recomp/ps2xRuntime/src/lib/Kernel/Syscalls/Sync.cpp:466-502`:

```cpp
int ret = KE_SEMA_ZERO;
...
if (sema->count > 0) {
    sema->count--;
    ret = isMc3PollSemaReturnSidExperimentEnabled() ? sid : KE_OK;   // <-- aqui
}
```

Hoje (padrão, sem a flag) `PollSema` bem-sucedido devolve `KE_OK` (`0`). O binário do jogo
(código real, decompilado acima) espera exatamente o **id do semáforo** de volta — contrato
documentado do kernel PS2 real (`PollSema` retorna o sema id em sucesso, não `0`). Como `0` (ou
qualquer valor fixo) nunca é igual ao id real do semáforo (`15`/`17`/etc., que varia por jogo/
build), o binário sempre cai no ramo "não pronto" e o loop nunca sai — mesmo quando o `PollSema`
*decrementou de verdade* o semáforo (ele consome o `count` da primeira chamada bem-sucedida,
depois disso `count` fica em `0` para sempre, daí o `ret=-419` constante observado).

Esse comportamento de retorno já existe **parado atrás de uma flag** (`isMc3PollSemaReturnSidExperimentEnabled`,
env `MC3_SEMA_EXPERIMENT_POLL_RETURNS_SID`), adicionada no commit `62e5743` do fork PS2Recomp,
**antes** da Fase 2 (`b9b40d2`, hoje). Nunca foi promovida a permanente.

### Trace 2 — confirmação empírica (diagnóstico, não commitado, não é fix deste passo)

Rodei **uma corrida adicional só para confirmar a causa**, ligando a flag já existente
(código já presente no repo, nada novo escrito) `MC3_SEMA_EXPERIMENT_POLL_RETURNS_SID=1`, mesmo
`MC3_DETERMINISTIC=1 MC3_DISPATCH_BUDGET=25000`. Log:
`work/logs/14_run_boot_trace_diag_sema_experiment.log` (também ignorado pelo git — diagnóstico,
não artefato de código).

- O gate **cai imediatamente**: o trace de frame já mostra `pc=0x245720` (passou de
  `0x245718`) no primeiro tick amostrado (`tick=120`), contra 1571 ticks travado em `0x245718`
  no baseline.
- `PollSema` passa a devolver o id certo e o `count` para de vazar:
  ```
  [boot-trace:PollSema] tid=1 sid=15 count=1->0 ret=15 experiment=1 pc=0x5469f0 ra=0x54178c
  [boot-trace:SignalSema] tid=1 sid=15 count=0->1 ret=0 pc=0x5469c0 ra=0x5417f8
  [boot-trace:PollSema] tid=1 sid=17 count=1->0 ret=17 experiment=1 pc=0x5469f0 ra=0x542114
  [boot-trace:SignalSema] tid=1 sid=17 count=0->1 ret=0 pc=0x5469c0 ra=0x542244
  ```
  padrão saudável produtor/consumidor (sinaliza, consome, sinaliza de novo), não mais um
  contador zerado pra sempre.
- O boot avança para um bloqueio **novo e mais adiante**, dentro do mesmo bloco
  (`dispatch-budget-reached` em `pc=0x245720`/depois `pc=0x542230`, oscilando
  `PollSema`/`SignalSema` sid=15/17 em ritmo alto — consome o budget de dispatch muito mais
  rápido que o loop antigo por iterar de verdade em vez de girar em `-419`). `gif`/`gsw`/
  `gsPrims` continuam `0` — nenhuma vitória visual, nem esperada neste diagnóstico.

Esta corrida **não é o fix do passo** — é só a prova de causa, feita com código que já existia,
sem tocar em nada e sem deixar a flag ligada. Nenhum arquivo de código foi alterado nesta
sessão (`git status`/`git status` no submódulo `PS2Recomp`: limpos, nada a commitar).

## Por que não apliquei o fix aqui

`PS2Recomp/ps2xRuntime/src/lib/Kernel/Syscalls/Sync.cpp` é exatamente o arquivo que
`docs/HANDOFF_FASE2_SCHEDULER.md` nomeia como dono dos "pontos determinísticos de troca de
contexto": **"Troca de contexto SÓ em pontos determinísticos: `WaitSema`/`PollSema`, ..."** — e
o commit da Fase 2 (`b9b40d2`, aceito **hoje**, critério "1 único Stable PC em 10/10") mexeu
pesado nesse mesmo arquivo (`SignalSema`/`WaitSema` ganharam lógica de scheduler determinístico
diretamente ao lado do `PollSema` que este passo precisaria mudar).

`docs/WORKFLOW.md`, seção "Quando algo dá errado":

> Suspeita de bug em camada congelada (scheduler, dispatcher aceito): reportar no RESULT, nunca
> remendar dentro de outro handoff.

Mudar o contrato de retorno do `PollSema` — mesmo sendo, por evidência forte, um bug de
correção (não uma escolha de design) — altera o comportamento observável exatamente num dos
pontos de troca de contexto que a Fase 2 acabou de validar com um critério de determinismo
apertado (1/10 PCs). Isso pertence a um handoff próprio, escopado, que revalide o aceite da
Fase 2 depois da mudança — não a este handoff de cdvd/diskready, cujo escopo (dispatcher SIF)
nem é o arquivo certo para o bug real.

## O que isso significa pro dispatcher cdvd (fno=0xE / diskready)

Não implementei nenhuma resposta nova em `handleCdvdRpc` (SIF.cpp) para `sceCdNcmdDiskReady`
(fno `0xE`, decomp `alpha_decomp_sce.txt:1887-1913`) porque **essa chamada nunca acontece nesta
janela de boot** — o gate que bloqueia hoje (`0x245718`) não é `psxCdCache`/CD; é anterior e
não relacionado. Escrever um handler para um fno que nunca dispara seria código morto não
verificável (viola a regra "sem chute" — não dá pra confirmar byte a byte um caminho que a
execução real nunca alcança). Se/quando o gate de semáforo for resolvido (fora deste handoff) e
o boot avançar até `psxCdCache::RawRead`/`sceCdRead` de verdade, aí sim a resposta de diskready
e a leitura real de `extracted_iso\` fazem sentido — o dispatcher `handleCdvdRpc` já está
pronto para receber esse novo braço `(kMc3CdvdNcmdSid, fno=0xE)` quando esse dia chegar; os
insumos (decomp de `sceCdNcmdDiskReady`, `sceCdRead`, `sceCdSync`) continuam válidos e não
mudaram.

## Aceite do handoff

**Não alcançado** — mas por achado negativo válido, não por falta de trace. O handoff pedia
"trace primeiro" exatamente para este cenário: a premissa (gate = diskready) não sobreviveu ao
trace. Gate `0x245718` **não saiu** (nem deveria sair por este passo — a causa real é de outra
camada).

## Régua de render (M0-M6)

`gifPk1/2/3=0`, `gsPrims=0`, `gsPixels=0` em ambas as corridas (baseline e diagnóstico). Sem
mudança de marco. M4 não se aplica.

## Suíte

Não rodada — nenhum arquivo tracked mudou (nem no repo principal, nem no submódulo
`PS2Recomp`). `git status` limpo nos dois antes e depois deste passo.

## Commits

Nenhum commit de código. Este RESULT doc é o único artefato novo, no repo principal
(`mc3recomp`, branch `mc3`), pronto pra commit local pelo executor conforme a convenção do
projeto.

## Recomendação para o próximo handoff

Handoff novo, escopado, para o dono do scheduler/kernel-sync (não para SIF/cdvd):

1. Promover `isMc3PollSemaReturnSidExperimentEnabled()` (`Sync.cpp:12-16,484`) de experimento
   parado a comportamento padrão incondicional — `PollSema` bem-sucedido devolve o `sid`, não
   `KE_OK`. Verificar se `WaitSema`/`ReferSemaStatus`/outras primitivas de semáforo têm o mesmo
   contrato ppara não deixar uma inconsistência parecida em outro lugar (não auditado aqui, fora
   de escopo deste passo).
2. Revalidar o aceite da Fase 2 depois da mudança: `21_probe_repeat.bat 10 595 <label>` com
   `MC3_DETERMINISTIC=1 MC3_DISPATCH_BUDGET=25000`, critério "1 único Stable PC em 10/10" —
   porque a mudança altera o valor observado num ponto de troca de contexto que o design da
   Fase 2 depende.
3. Depois disso, medir de novo se o boot chega em `psxCdCache::RawRead`/`sceCdRead` de verdade;
   só então este handoff (`HANDOFF_FASE1_CDCACHE_DISKREADY.md`) volta a fazer sentido tal como
   escrito.
