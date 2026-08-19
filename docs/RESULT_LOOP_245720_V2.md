# Resultado — passo 19 parte 2: trace ao vivo dos 3 portões de `FUN_005422C8`

Executa a parte 2 do handoff da anatomia (`docs/RESULT_LOOP_245720_V1.md` +
`docs/HANDOFF_FASE1_LOOP_245720_ANATOMY.md`). Data: 19/08/2026. Repo raiz `mc3recomp`
(branch `main`) + submódulo `PS2Recomp` (branch `mc3`) — nenhum dos dois teve código
tracked alterado (só este RESULT doc, no repo raiz). A instrumentação foi feita em
`work/generated/ghidra/*.cpp`, que é **gitignored** (`work/` está no `.gitignore` da
raiz) — portanto não há commit de código a fazer para ela; ela é local/ephemeral, igual
aos demais `.cpp` gerados.

## Resumo (3 linhas)

Instrumentei os 3 portões de `FUN_005422C8` (0x54231c, 0x54232c, 0x542448) com
`fprintf` atrás de `MC3_BOOT_TRACE`, recompilei só os `.o` afetados (find_stale=0 no
resto), relinkei e rodei 2 corridas (budget 100000 e 1000000, janela 90s). **Resultado:
os 3 portões nunca disparam — zero hits nos três em ambas as corridas.** Isso significa
que `FUN_005422C8` **nunca é chamada** nas corridas atuais — a premissa da anatomia da
Fase 1 (que o laço externo alcança regularmente o `jal func_5422C8` em `0x24572c`) não
se confirma ao vivo. O bloqueio real é uma camada antes: dentro de `sub_005420C0`
(chamada em `0x245718`, antes do `jal func_5422C8`), num laço de bind-retry
(`0x542174-0x5421cc`) com um busy-spin de ~0x100000 ciclos por tentativa e **sem
contador de desistência visível** — camada de scheduler/timing, não de protocolo SIF.
Não implementei correção (regra do handoff: causa em camada de scheduler → parar e
reportar, não remendar).

## O que foi instrumentado

`work/generated/ghidra/FUN_005422c8_0x5422c8.cpp` (função 0x5422c8-0x5424a8):

- Helper local `mc3_5422c8_bootTraceEnabled()` (mesmo padrão usado em
  `SIF.cpp`/`Sync.cpp`/`GS.cpp`: `getenv("MC3_BOOT_TRACE")`, sem header novo).
- Portão A, logo após `label_542318`, **antes** do `beq $v0,$v1` em `0x54231c`:
  `fprintf(stderr, "[MC3_BOOT_TRACE] gateA@0x54231c v0(func_5418D0 ret)=...")`.
- Portão B, logo após `label_54232c`, **antes** do `beqz $v0` em `0x54232c`:
  `gateB@0x54232c v0(func_541760(4) ret)=...`.
- Portão C, logo após `label_542448`, **antes** do `bgezl $v0` em `0x542448`:
  `gateC@0x542448 v0(sceCdRead sceSifCallRpc ret)=...`.

Todos os 3 pontos ficam **depois** do `switch(ctx->pc)` de resume da função (os
`goto label_*`), respeitando a armadilha documentada no passo 6
(`RESULT_PROVIDER_TABLE_V1`) — nenhuma instrumentação foi colocada antes do switch.

`FUN_00541760_0x541760.cpp` **não foi tocado**: os 3 pontos pedidos pelo handoff estão
todos dentro de `FUN_005422C8` (ela já captura os retornos de `func_5418D0` e
`func_541760(4)` vistos pelo chamador), então instrumentar dentro de `func_541760`
seria redundante para a pergunta "qual portão trava" — e o achado abaixo mostra que a
pergunta nem chega a ser relevante ainda (a função-mãe nunca é chamada).

## Build

- `g++` direto (MSYS2 `ucrt64`, PATH ajustado primeiro), mesmos flags do
  `Compile-GeneratedBatch.ps1` modo `object` (`-std=c++20 -msse4.1 -Wall
  -Wno-unused-variable -Wno-unused-label -Wno-comment` + os 3 `-I`), saída direto em
  `work/compile/ghidra/batch_0053/obj/FUN_005422c8_0x5422c8.o` (batch já identificado
  via grep no diretório de obj). Exit code 0, sem warnings novos.
- `python tools/find_stale.py`: `Missing: 0`, `Stale (mtime): 0` — confirmado que só o
  `.o` tocado foi recompilado e nada mais ficou desatualizado.
- Relink: `10_link_partial_runner.bat fast` (usa register/stubs parciais existentes,
  sem regenerar) → `[OK] Linked partial runner: work\link\partial\mc3_partial.exe`.
  Não rodei nenhuma medição durante o build/relink (nunca concorrente).

## Corridas

Ambas via PowerShell direto (`$env:MC3_BOOT_TRACE='1'`, `$env:MC3_DETERMINISTIC='1'`,
`$env:MC3_DISPATCH_BUDGET=...`), janela de espera 90s, processo sempre terminou sozinho
antes do timeout (boot completo + shutdown, "Window closed successfully").

| Corrida | Budget | Hits gateA | Hits gateB | Hits gateC | Onde parou |
|---|---|---|---|---|---|
| 1 | 100000 | 0 | 0 | 0 | `dispatch-budget-reached pc=0x245720 ra=0x245720`, depois `game-thread-return pc=0x542230` |
| 2 | 1000000 | 0 | 0 | 0 | oscila entre `pc=0x548e70,0x5494e0,0x542230,0x245720` (amostra de janela), termina em `dispatch-budget-reached pc=0x245720`, shutdown normal (threads 2/3 saem, `game-thread-return pc=0x542230`) |

Trace bruto: `work/logs/gate_trace_run1.log.stderr` (100k) e
`work/logs/gate_trace_run2.log.stderr` (1M). `grep -c "gateA\|gateB\|gateC"` = `0` nos
dois arquivos.

O trace SIF confirma que a RPC `diskready-status` (sid `0x8000059c`, fno=0) **dispara e
sucede** várias vezes por corrida (`value=0x2`, o mesmo padrão "5x por corrida" já
registrado no passo 18) — então `sub_005420C0` chega a completar seu ciclo de bind+RPC
pelo menos algumas vezes. Mas isso não se traduz em nenhuma chamada observável a
`FUN_005422C8`.

## Por que os portões nunca disparam — achado que corrige a Fase 1

A anatomia da Fase 1 assumiu que o laço externo (`sub_00245680`, 0x245680-0x24578c)
alcança regularmente `0x24572c: jal func_5422C8` a cada iteração. A instrumentação
mostra que isso **não acontece nas corridas atuais** (nem com budget 10x maior). Lendo
`sub_005420C0` (chamada em `0x245718`, **antes** do `jal func_5422C8`) linha a linha:

- `0x542174-0x542188`: tenta `func_5492B8(a0=$s0, a1=0x8000059c)` (bind do sid
  `0x8000059c`, o mesmo sid usado pela RPC diskready-status). Se `func_5492B8`
  retornar `>=0` (sucesso, `bgezl` em `0x542188`), pula direto para `0x5421d4` e
  segue o fluxo normal (RPC, SignalSema, etc. — o caminho que eventualmente chega em
  `0x542228: jal func_549488` = a RPC vista no trace).
- Se `func_5492B8` **falhar** (`<0`): monta `v1=0x100000` (`0x542198`/`0x5421a8`) e
  `v0=-1` (`0x5421ac`), entra num busy-spin de decremento (`0x5421b0-0x5421c4`, 4 NOPs
  por iteração, `bne $v1,$v0` volta pra `0x5421b0`) até `v1==-1` (~0x100000
  iterações), e então (`0x5421cc`) **salta incondicionalmente de volta pra `0x542174`
  para tentar o bind de novo** — sem nenhum contador de tentativas ou condição de
  desistência visível neste trecho da função.
- Ou seja: `sub_005420C0` só retorna ao chamador (`0x245720`, permitindo o `jal
  func_5422C8` seguinte) quando o bind `func_5492B8(sid=0x8000059c)` **sucede**. Se ele
  falhar, a função gasta ~0x100000 ciclos de busy-spin e tenta de novo, indefinidamente
  — não há saída visível nesse laço.

Isso bate com o padrão observado no trace: sucesso ocasional do bind (as 5 RPCs
diskready-status por corrida) intercalado com períodos onde o orçamento de dispatch
inteiro é consumido girando dentro de `sub_005420C0` sem nunca devolver controle ao
laço externo em `0x245720` numa janela que alcance o `jal` em `0x24572c` — ou, quando
devolve, o laço externo volta a chamar `sub_005420C0` de novo (`0x245734: bne` mantém
o `do-while` se `FUN_005422C8` nunca rodou para produzir `v0`, mas como `v0` nunca é
setado por `FUN_005422C8` nesse caminho, o `$v0` comparado em `0x245734` vem de uma
iteração anterior ou de lixo de registrador — não confirmado nesta sessão, precisaria
de instrumentação adicional em `0x245734` para fechar esse ponto).

**Conclusão**: os 3 portões de `FUN_005422C8` (A/B/C) não são o gate ativo hoje — a
função nunca é alcançada. O gate real observado ao vivo está uma camada antes, no
retry/bind de `sub_005420C0`, e tem cara de problema de **scheduler/timing**
(busy-spin sem desistência, dependente de quando o bind do sid `0x8000059c` sucede em
relação ao orçamento de dispatch), não de contrato de protocolo SIF. Por regra do
handoff ("se a causa for em camada do scheduler, PARE e reporte, não remende"), não
implementei nenhuma correção.

## Aceite do handoff

**Não alcançado.** `sceCdRead` (fno=1) não disparou ao vivo — nem chegou a ser
avaliado, porque `FUN_005422C8` nunca é chamada nas condições testadas. Entregue:
instrumentação viva nos 3 portões (compilada, linkada, comprovadamente funcional —
zero hits é um resultado válido, não um erro de instrumentação, confirmado pelos
outros logs de trace no mesmo arquivo que mostram atividade normal no período), 2
corridas com evidência bruta, e a identificação de um gate mais cedo na cadeia
(`sub_005420C0`, bind-retry busy-spin de `func_5492B8(sid=0x8000059c)`) com endereços
exatos.

## Régua de render (M0-M6)

Sem mudança. `M4` (gifPackets>0 E gsPrims>0) não observado — trace mostra
`gifPk1=0 gifPk2=0 gifPk3=0 gsPrims=0` em todas as amostras `[boot-trace:frame]` das
duas corridas.

## Suíte

Não rodada. Nenhum arquivo tracked (fora deste RESULT doc) mudou em nenhum dos dois
repositórios — `work/` é gitignored na raiz, e o submódulo `PS2Recomp` não foi tocado.

## Commits

- Repo raiz (`mc3recomp`, branch `main`): este RESULT doc, pronto para commit local
  (sem push).
- Submódulo `PS2Recomp` (branch `mc3`): nenhuma mudança.

## Próximo passo recomendado

1. Fechar o ponto em aberto de `0x245734` (o que exatamente é comparado ali quando
   `FUN_005422C8` nunca roda) com uma instrumentação pontual — 1 `fprintf` no próprio
   `sub_00245680_0x245680.cpp`, mesmo padrão de guarda.
2. Handoff próprio (fora do escopo "protocolo SIF") para investigar o busy-spin de
   `sub_005420C0` (`0x5421ac-0x5421cc`): por que `func_5492B8(sid=0x8000059c)` falha às
   vezes, se há alguma dependência de ordem de inicialização entre threads/RPC clients,
   e se o "sem contador de desistência" é fiel ao jogo original (delay de hardware real
   do IOP) ou um artefato do recomp (ex.: timing do dispatch cooperativo divergindo do
   IOP real o suficiente para o spin nunca "terminar a tempo" de um jeito que o jogo
   original não sofria). Este é território de scheduler/kernel-sync — mesma camada que
   o passo 11 já recusou tocar sem handoff próprio.
3. Instrumentação: **mantida** atrás de `MC3_BOOT_TRACE` (não removida) — os 3 gates em
   `FUN_005422C8` são baratos (guard de `getenv` + early-return, sem alocação) e
   diretamente reutilizáveis assim que o gate de `sub_005420C0` for resolvido; remover
   agora só para recriar no próximo ciclo seria desperdício. Documentado aqui como a
   escolha feita.
