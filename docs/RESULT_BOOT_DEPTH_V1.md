# Resultado — passo 22: diagnóstico de profundidade + causa raiz do gate de bind-retry

Continuação do `docs/RESULT_CDREAD_PARAMS_V1.md` (marco: `sceCdRead` lê certo,
LBA 16 byte-exato; boot passou dos gates `0x245720`/`0x5a8908`; novo estágio de
bind-retry no cliente `0x6faed0`, sid `0x8000059c`, 3 PCs distintos nas
corridas rápidas do passo 21). Data: 19/08/2026. Repo raiz `mc3recomp` (branch
`main`) + submódulo `PS2Recomp` (branch `mc3`).

## Resumo (3 linhas)

Corrida de diagnóstico (`MC3_DISPATCH_BUDGET=1000000`, 300s, determinística)
confirma que os "3 PCs distintos" do passo 21 eram **artefato de amostragem**
(passo 18-like), não instabilidade real: `pc=0x245718` domina 279/293 amostras
de frame a partir do tick 420 até o fim dos 300s — trava real, não variação.
Instrumentei `FUN_00541760_0x541760` (a "gateB" da cadeia `sceCdRead` →
`func_5422C8`) e achei a causa: depois do primeiro bind bem-sucedido (cliente
`0x620d50`, `func_5492B8` retorna 0), toda chamada seguinte cai num caminho de
falha permanente guardado por um contador em `0x61FB90` (`-0x470` de uma base
`$62xxxx`) que fica `<=0` e nunca é reabastecido — campo **diferente** dos que
o fix do passo 20 cobriu (`0x61FBB4`/`0x61FBD8`). Não apliquei fix (seria
chute — falta achar o produtor/`SignalSema` desse campo específico, fora do
escopo de decomp já feito nesta passada).

## Parte 1 — Diagnóstico de profundidade

Corrida: `MC3_DETERMINISTIC=1 MC3_DISPATCH_BUDGET=1000000 MC3_BOOT_TRACE=1`,
janela 300s, `14_run_boot_trace.bat 300`. Log: `work/logs/14_run_boot_trace.log`
(32004 linhas).

- **sceCdRead (RPC real, `kind=read`)**: dispara **1 única vez** em toda a
  corrida de 300s — `lsn=0x10` (o mesmo LBA 16/PVD já confirmado no passo 20).
  Nenhum outro LBA é lido. O jogo **não está streamando** além do primeiro
  setor.
- **Cadeia Dave/provider**: não observada — sem menção a `flag619f40`, abertura
  de `ASSETS.DAT` ou `zipOpen` no log inteiro (grep vazio). Não alcançada.
- **Onde estabiliza**: `pc=0x245718` (o laço de `sub_00245680`/`func_5422C8` já
  mapeado no passo 20) domina as amostras de frame a partir do `tick=420`
  (~7s de simulação guest) até o fim dos 300s: **279 de 293** amostras totais
  de frame têm esse PC exato. O contador de `sema` no log de
  `sif-command-compat` (cliente `aux=0x6faed0`, `cmd=0x8000000a`,
  sid=`0x8000059c`) cresce monotonicamente (`sema=9` → `sema=4417+`) durante
  toda a trava — ou seja, o laço continua rodando e reemitindo a mesma
  chamada de diskready-status indefinidamente, nunca progride.
- **gifPk1/2/3, gsPrims, gsPixels**: zerados em **todas** as 293 amostras de
  frame (`gifPk1=0 gifPk2=0 gifPk3=0 gsPrims=0 gsPixels=0`). Nenhum M4, nenhum
  M5 isolado desta vez.
- **Os 3 PCs do passo 21 eram artefato, não trava real**: a corrida
  determinística de 300s mostra 1 único PC dominante e estável
  (`0x245718`) por >270 amostras seguidas — mesmo padrão do "passo 18": o
  Probe-Repeat rápido (8s wall-clock, sem determinismo) estava capturando
  pontos diferentes dentro do **mesmo** ciclo repetitivo (gateA → gateB →
  `sceSifSetDma` → diskready-status → `sif-command-compat`), não 3
  comportamentos distintos do jogo.

## Parte 2 — Causa raiz (decomp nomeado, sem chute)

`sub_00245680` (`0x245718`-`0x245734`) chama `func_5422C8` (`sceCdRead`
retail) em loop `while (v0 != 1)`. Fonte:
`work/generated/ghidra/sub_00245680_0x245680.cpp:230-284`.

Dentro de `FUN_005422c8_0x5422c8` (`sceCdRead`), antes de montar o payload de
envio (já documentado no passo 20), há dois gates sequenciais:

```
0x542310: jal func_5418D0            -> "gateA"
0x54231c: beq $v0, 6, ...             -> early-return se v0==6
0x542324: jal func_541760(a0=4)       -> "gateB"
0x54232c: beqz $v0, label_542464      -> SE v0==0, PULA a montagem/envio
                                          do payload inteiro e retorna 0
```

Fonte: `work/generated/ghidra/FUN_005422c8_0x5422c8.cpp:91-190`. Ou seja:
`sceCdRead` só chega a montar e enviar o RPC de leitura real se `gateB`
(`func_541760(4)`) retornar não-zero. Se `gateB==0`, `FUN_005422c8` retorna
`v0=0` sem nada acontecer, e o laço externo (`v0 != 1`) tenta de novo —
infinitamente.

Instrumentei `FUN_00541760_0x541760` (arquivo
`work/generated/ghidra/FUN_00541760_0x541760.cpp`) em 3 pontos:

1. `0x541808` — leitura do campo "já vinculado" (`-0x444($s2)`).
2. `0x54185c` — retorno de `func_5492B8` (a rotina de bind/criação usada
   quando o campo acima é `-1`, i.e. ainda não vinculado).
3. `0x5418ac` — checagem final antes de sair do laço de retry interno.

Corrida de confirmação (90s, determinística, budget 100k — mesmo perfil do
passo 20): `work/logs/14_run_boot_trace.log`.

```
[MC3_BOOT_TRACE] gateB-already-bound-flag@0x541808 v0=-1
[MC3_BOOT_TRACE] gateB-bind@0x54185c v0(func_5492B8 ret)=0 (0x0) a0(client)=0x620d50
[MC3_BOOT_TRACE] gateB-retry-check@0x5418ac v0=1
[MC3_BOOT_TRACE] gateB-already-bound-flag@0x541808 v0=0
```

Achado: o caminho de `0x541808`/`func_5492B8` **só dispara 2 vezes em toda a
corrida** (bind inicial, bem-sucedido: `client=0x620d50`, retorno `0`,
`retry-check` final `v0=1` = sucesso). Isso confirma que **o bind em si
funciona** e não é o gargalo — é consistente com o fix de "slot-release" do
passo 20.

O problema está em outro ramo da mesma função, que não passa por
`0x541808`: em `0x541790`, se `beq $v1,$v0` (comparação de duas leituras de
semáforo via `PollSema`, offsets `0x62xxxx-0x458` e `0x62xxxx-0x470`) **não**
for tomado — o que passa a ser o caso em toda chamada após o bind inicial —,
o código lê `v1 = *(v0 - 0x470)` (endereço retail `0x61FB90`, base
`$v0=0x620000`) e:

- se `v1 <= 0` (`blez`): retorna `0` imediatamente (`label_5417f8`,
  `work/generated/ghidra/FUN_00541760_0x541760.cpp:122-135`);
- senão: chama `func_548490` (rotina de log/erro, endereço de string
  `0x672730`/`0x672708` — sugestivo de mensagem de erro do SDK) e **também**
  retorna `0` incondicionalmente logo em seguida
  (`work/generated/ghidra/FUN_00541760_0x541760.cpp:168-182`, o `b` em
  `0x5417b8` força `v0=0` no delay slot antes de pular pro epílogo).

Ou seja: **os dois sub-caminhos de `0x541798` em diante sempre retornam 0**
depois do primeiro bind. Isso bate exatamente com o padrão observado: `gateB`
retorna `0` em toda chamada subsequente ao bind inicial, `sceCdRead` nunca
mais monta o payload, e o laço de `sub_00245680` gira para sempre.

O campo relevante é `0x61FB90` (retail) — um contador/semáforo que decresce
até `<=0` e nunca é reabastecido no trecho decompilado até aqui. **Este é um
campo diferente** dos dois que o fix do passo 20 (`RESULT_CDREAD_PARAMS_V1.md`)
tratou: `_sceCd_c_cb_sem` (`0x61FBB4`) e `sceCdCbfunc_num` (`0x61FBD8`). A
suspeita do handoff (segundo pool/outro campo, não coberto pelo slot-release
do passo 20) **está confirmada**: é um terceiro campo, ainda sem produtor
mapeado.

**Não apliquei fix.** Achar o que deveria incrementar/`SignalSema` esse campo
(provavelmente o callback de conclusão de leitura de CD, disparado após o
`readOk=1` do único `sceCdRead` que já rodou) exige decompilar mais funções
(candidatas: a rotina apontada por `intr_data=0x620c80`, ou o handler de
interrupção do CDVD) — não fiz isso aqui por respeitar o limite de honestidade
"sem chute de bytes": eu tenho o campo e o sintoma, não o produtor. Ver
"Próximo passo recomendado".

## Régua de render (M0-M6)

Sem M4. `gifPk1=0 gifPk2=0 gifPk3=0 gsPrims=0 gsPixels=0` em todas as 293
amostras de frame da corrida de diagnóstico de 300s. Nenhum `gsPixels`
isolado. M4 não alcançado — não se aplica o protocolo de "parar tudo".

## Suíte

`ps2x_tests.exe` (272 testes), executado diretamente (nenhum `.cpp` sob
`PS2Recomp/` foi tocado neste passo — só arquivos gerados em
`work/generated/ghidra/`, fora da árvore que `ninja ps2x_tests` reconstrói;
`ninja` confirmou "no work to do"): **271 passed, 1 failed**
(`VU0 macro mappings cover all S1/S2 enums`) — o mesmo flake pré-existente já
registrado em `RESULT_CDREAD_PARAMS_V1.md` como não relacionado a mudanças de
código (não removido, não investigado de novo aqui — fora de escopo, mesma
conclusão de "ruído" do passo 20).

## Build

- `find_stale.py` antes do rebuild: `Missing: 0, Stale (mtime): 0`.
- Editei só `work/generated/ghidra/FUN_00541760_0x541760.cpp` (3 blocos de
  trace `fprintf` sob `MC3_BOOT_TRACE`, sem mudança de lógica/bytes). Depois
  do edit, `find_stale.py`: `Stale (mtime): 1` (o próprio arquivo).
- Recompilei só esse `.o` via `tools/parallel_compile.py` (lê
  `stale_only.csv`, que já continha apenas essa 1 entrada) — MSYS2 `ucrt64`
  no PATH primeiro. `DONE total=1 failures=0`.
- Relink via `10_link_partial_runner.bat fast` (não concorrente, sequencial
  após a recompilação). `mc3_partial.exe` confirmado mais novo que o `.o`
  tocado (timestamp).

## Probe-Repeat 3x

**Não executado neste passo.** Nenhum fix de comportamento foi aplicado
(só instrumentação de trace) — não há mudança de gate para confirmar
estabilidade. Rodar `21_probe_repeat.bat 3 probe boot_depth_v1` só faria
sentido depois que um fix real (produtor do campo `0x61FB90`) for aplicado.
Recalibração de budget/janela: o diagnóstico de 300s/1M confirma que 90s/100k
(o padrão do STATUS.md) já é suficiente para alcançar e estabilizar no gate
atual (`tick=420`, ~7s de sim guest, muito antes do teto de 90s/100k) — **não
recalibrar** o padrão, ele já é mais que suficiente.

## Commits

- Submódulo `PS2Recomp`: nenhuma mudança (arquivos gerados ficam em
  `work/generated/ghidra/`, fora do submódulo).
- Repo raiz (`mc3recomp`, branch `main`): `work/generated/ghidra/FUN_00541760_0x541760.cpp`
  (instrumentação de trace, 3 pontos) + este RESULT doc — commit local, sem
  push.

## Próximo passo recomendado

1. Achar o produtor do campo retail `0x61FB90` (candidatos: a rotina de
   callback de interrupção do CDVD apontada por `intr_data=0x620c80`
   documentada no passo 20, ou o handler que processa `readOk=1` depois do
   único `sceCdRead` que já rodou). Decompilar essas funções nomeadas antes de
   tocar em qualquer lógica.
2. Uma vez identificado o que deveria escrever/`SignalSema` nesse campo, a
   correção provável é do mesmo tipo do passo 20: o host não está emitindo a
   notificação de conclusão que o guest espera nesse campo específico — não é
   um env-gate nem um chute de bytes, é mapear o protocolo real.
3. Depois do fix: `14_run_boot_trace.bat 90` (determinístico, budget 100k) +
   `21_probe_repeat.bat 3 probe <nome>` para confirmar estabilidade 3x antes
   de fechar o passo.
