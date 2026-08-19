# Resultado — passo 19: anatomia do laço `0x245720` (Fase 1 completa; Fase 2-4 não executadas)

Executa `docs/HANDOFF_FASE1_LOOP_245720_ANATOMY.md`. Data: 19/08/2026. Branch `mc3` (fork
local, sem push). Nenhum arquivo de código tocado nesta sessão — só leitura de decomp honesto
(`work/generated/ghidra/*.cpp`) e do dispatcher SIF já commitado (`PS2Recomp/.../SIF.cpp`).

## Resumo (3 linhas)

Mapeei a cadeia de chamadas completa do laço `sub_00245680`/`0x245720` até o ponto exato em que
`sceCdRead` (fno=1) seria disparado, com endereço-por-endereço. Achado central: **a condição de
saída do laço externo não é `sub_005420C0` (que só roda por efeito colateral, retorno
descartado) — é `FUN_005422c8` (0x5422c8-0x5424a8) retornar `1`**, e essa função tem **3 portões
sequenciais**, cada um capaz de travá-la em `0` (mantendo o laço preso). Não tracei ao vivo nem
implementei nada — a anatomia sozinha já é grande o suficiente pra registrar antes de mexer, e o
próximo passo exige instrumentação nova em 3 pontos diferentes (não 1), o que fica pro próximo
ciclo. Resultado: anatomia completa e verificada por decomp, sem chute, aceite do handoff (que
exige `sceCdRead` disparando + bytes vs ISO) **não alcançado nesta sessão**.

## Correção a um dado do passo 17/18

`docs/RESULT_DISKREADY_059C_V1.md`/`RESULT_FASE2D_RPC_TICK_V1.md` tratam `0x245734: bne $v0,$s0`
como se `$v0` viesse de `sub_005420C0`. **Não vem.** Releitura linha-a-linha de
`work/generated/ghidra/sub_00245680_0x245680.cpp` (0x245680-0x24578c) mostra:

- `0x245718`: `jal func_5420C0` (a0=0) — retorno (`$v0`) **nunca é lido** depois desta chamada;
  o próximo uso de `$v0` só acontece depois da call seguinte.
- `0x245720-0x245730`: monta `a0=$s2, a1=$s5, a2=$s4, a3=$s3+$s1` e `jal func_5422C8` — **este**
  é quem produz o `$v0` comparado em `0x245734: bne $v0,$s0(=1) → volta pra 0x245718`.

Ou seja o laço real é:
```
s0 = 1;
do {
    sub_005420C0(0);                          // 0x245718 — efeito colateral, retorno descartado
    v0 = FUN_005422C8(s2, s5, s4, s3+s1);      // 0x245720
} while (v0 != s0 /* == 1 */);                 // 0x245734
```
`sub_005420C0` não é decorativo (ele dirige a RPC "disk-ready status" `0x8000059c`/fno0, já
implementada, `SCECdComplete=2` — ver passo 17) mas o comentário do passo 17
(`docs/RESULT_DISKREADY_059C_V1.md` linha 57: "`sub_005420C0` sai do loop de retry desta
chamada") e o comentário em `SIF.cpp:1046-1048` ("...que lets `sub_005420C0`'s retry loop see
'disk present and ready' and exit") descrevem corretamente o **laço interno de `sub_005420C0`**
saindo do *seu próprio* retry (que existe, `0x542174-0x5421cc`, 17x) — mas isso é uma função
diferente do laço externo que trava em `0x245720`. Os dois fatos não se contradizem; só não é
`sub_005420C0` quem decide se o laço externo sai.

## Anatomia condição-por-condição

### Camada 1 — `sub_00245680` (0x245680-0x24578c), laço externo

| Endereço | O que testa | Satisfeita hoje? |
|---|---|---|
| `0x245734` `bne $v0,$s0(=1)` | `FUN_005422C8(...) == 1` | **Não** — é a condição travada; `FUN_005422C8` nunca retorna 1 nas corridas registradas (passo 17/18: boot sempre volta a `0x245720`). |

### Camada 2 — `FUN_005422c8` (0x5422c8-0x5424a8), 3 portões sequenciais

Todos os caminhos de retorno cedo (`v0=0`) mantêm a Camada 1 presa. Só há dois pontos que
retornam `1`: `0x542404`→`0x54246c`/`0x542480` (depois de emitir com sucesso a RPC fno=1) e
`0x541810`/`0x5418b0` **dentro** de `func_541760` (usado por outra chamada, não afeta o retorno
de `FUN_5422C8` diretamente — ver Camada 3).

- **Portão A — `0x542304-0x54231c`** (`andi $v0,$v0,1` do global `*(0x620000-0x448)`, depois,
  se bit0=0, `jal func_5418D0`; `0x54231c: beq $v0,6 → v0=0; return`):
  se o bit0 (`"já inicializado"`) não estiver setado, chama `func_5418D0` (ver Camada 3) e, **se
  o valor retornado for exatamente `6`, aborta a função inteira devolvendo `0`** — o laço externo
  fica preso. `6` bate com `SCECdNotReady` (ver `docs/RESULT_CDCACHE_DISKREADY_V1.md` e
  `alpha_decomp_sce.txt` — mesma constante citada no handler `handleCdvdNcmdDiskReady` do
  dispatcher). **Hoje o dispatcher (`SIF.cpp:1081-1108`, fno=`0xE`) escreve zero, não `6`** — em
  princípio esse portão específico não deveria estar travando (zero ≠ 6), mas isso só é confirmado
  ao vivo, não por leitura estática (depende de que caminho `func_5418D0`/`func_541760(2)`
  realmente percorre em tempo de execução).
- **Portão B — `0x542324-0x54232c`** (`jal func_541760` com `a0=4`; `0x54232c: beqz $v0 →
  v0=0; return` pulando pra `0x542464`): **se `func_541760(4)` retornar `0`, `FUN_5422C8` aborta
  sem NUNCA montar/emitir a RPC `fno=1` (sceCdRead)** — este é o portão mais provável de ser o
  culpado, porque ele guarda o próprio envio da chamada que o aceite do handoff pede
  (`sceCdRead` disparando). `func_541760` (ver Camada 3) retorna `0` sempre que seu próprio
  `PollSema` interno não devolver o id do semáforo esperado (mesmo contrato de retorno já
  identificado como bug histórico no passo 11, `docs/RESULT_CDCACHE_DISKREADY_V1.md` —
  `isMc3PollSemaReturnSidExperimentEnabled`), então este portão pode já estar resolvido (se o
  fix foi promovido) ou pode ser uma nova instância do mesmo padrão numa sid diferente — **não
  confirmado, precisa de trace**.
- **Portão C — `0x542440-0x542448`** (`jal func_549488` = `sceSifCallRpc(client=0x620d50,
  fno=1, mode=1, send=24B{lsn,sectors,mode}, sendsize=0x18, recv=0, recvsize=0)`; `0x542448:
  bgezl $v0` — sucesso salta pra `0x54246c`, senão zera as duas flags de "pendente"
  (`-0x428($s0)`, `-0x44c($s1)`), `SignalSema`, retorna `0`): **esta É a chamada de
  `sceCdRead`** — sinal/assinatura idêntica ao handler já implementado em `SIF.cpp:1110-1177`
  (`serverIsCdvdNcmd && fno==1u`, comentário cita exatamente `send=_sceCd_ncmdsdata/0x18B`, bate
  com `sendsize=0x18=24`). Se os Portões A/B nunca deixam o fluxo chegar aqui, o handler
  já-implementado de `sceCdRead` **nunca é executado** — explica por que o passo 17/18 nunca viu
  `kind=read` no trace apesar do handler existir e estar correto.

### Camada 3 — funções-portão

- **`func_5418D0`** (0x5418d0-0x541968): gate próprio em `func_541760(2)` (`0x5418dc-0x5418e4:
  bnez $v0`; se `func_541760(2)==0`, pula direto pro fim retornando `0` sem nunca montar a RPC).
  Se passar, monta e emite `sceSifCallRpc(client=$s0, fno=0xE, mode=0, send=0/0, recv=$s0-0x400,
  recvsize=4)` (0x5418f4-0x54191c) — **esta é a chamada de `sceCdNcmdDiskReady`** (fno=`0xE`,
  já mapeada em `SIF.cpp:1081-1108`, `kMc3CdvdNcmdDiskReadyFno`). Se a RPC falhar (`$v0<0`),
  `SignalSema` e retorna `0`; se suceder, lê o word de resposta pela alias não-cacheada
  (`0x541940-0x541954`, mesmo padrão `|0x20000000` de `sub_005420C0`) e **retorna esse valor
  bruto** — é esse valor que o Portão A compara contra `6`.
- **`func_541760`** (0x541760-0x5418d0): recebe `a0` (2 ou 4, propósito ainda não decodificado —
  provavelmente um "modo"/prioridade passado a `ReferThreadStatus`). Gate interno idêntico ao bug
  do passo 11: `jal func_5469F0` (`PollSema`) em `0x541784`, releitura do global `*(-0x458($s0))`
  em `0x54178c`, `beq $v1,$v0 → 0x5417c0` (sucesso) — **se `PollSema` não devolver exatamente o
  id do semáforo lido de volta do global, `func_541760` retorna `0` direto** (`0x541798-0x5417f8`,
  ambos os sub-ramos convergem em `v0=0`). No caminho de sucesso, chama
  `ReferThreadStatus(sid_area, buf)` (`func_5468A0`, 0x5417d4) e `func_541968(1)` (não lido nesta
  sessão — não crítico pro achado principal), decide `SignalSema`+retorno `0` OU segue para
  `func_548C78()` (mesma função de flag `-0x438`/`-0x444` usada em `sub_005420C0` e aqui) —
  se essa flag já estiver "pronta" (`>=0`), retorna `1` direto; senão entra num laço de bind
  (`func_5492B8`, sid **`0x80000595`** — different da `0x8000059c` da Camada 1/`sub_005420C0` —
  com delay-spin de ~`0x100000` iterações por tentativa, sem contador de desistência visível
  nesta função) até bind suceder ou a flag virar não-zero, aí retorna `1`.

### Sids envolvidos (para o próximo passo de trace)

| Sid | Fno | Papel | Handler em `SIF.cpp` |
|---|---|---|---|
| `0x8000059c` | `0x0` | "disk-ready status", dirigido por `sub_005420C0` (Camada 1, efeito colateral) | Implementado (`kMc3CdvdDiskReadyStatusSid`, linha 1041) — escreve `2` |
| `0x80000595` (bind, `func_5492B8` dentro de `func_541760`) | — | bind do cliente usado por `func_5418D0`/RPC fno=0xE | Não é um `handleCdvdRpc` fno — é a chamada de *bind*, tratada em outro lugar do dispatcher SIF (não lido nesta sessão) |
| `kMc3CdvdNcmdSid`/legacy alias | `0xE` | `sceCdNcmdDiskReady`, emitido por `func_5418D0` (Portão A) | Implementado (linha 1081) — zero-fill (`!= 6`) |
| `kMc3CdvdNcmdSid`/legacy alias | `0x1` | `sceCdRead`, emitido por `FUN_5422C8` (Portão C) | Implementado (linha 1110) — leitura real do ISO |

## Por que parei aqui (Fase 1, sem Fase 2-4)

O handoff pede anatomia completa registrada **antes** de tracear/implementar. A anatomia acima
já revelou que a suposição original do handoff ("`func_5424A8`=`sceCdSeek` esperando retorno 1")
está parcialmente certa em espírito — `FUN_005422c8` (que termina em `0x5424a8`, provavelmente a
origem da citação histórica "func_5424A8") é de fato quem o laço espera retornar `1` — mas o
mecanismo real tem **3 portões independentes**, não 1, e um deles (`func_541760`, chamado 2x com
parâmetros diferentes) tem o mesmo padrão de bug de contrato `PollSema` já documentado no passo
11. Confirmar qual portão trava ao vivo exige instrumentação em **3 pontos** (`0x54231c` valor de
retorno de `func_5418D0`; `0x54232c` valor de retorno de `func_541760(4)`; `0x542448` valor de
retorno do `sceSifCallRpc(fno=1)`) — trace fresh-entry-only nesses 3 pontos, não um só. Isso é o
próximo passo lógico (Fase 2 do handoff), mas não cabe com segurança no mesmo ciclo desta leitura
sem violar "1 corrida = 1 prova" com instrumentação ainda não escrita/revisada. Não implementei
nada, não fiz nenhuma corrida, não commitei nenhuma mudança de código.

## Aceite do handoff

**Não alcançado nesta sessão.** Entregue: anatomia completa condição-por-condição com endereços
(seções acima), incluindo a correção de que o laço externo é gated por `FUN_005422C8`, não por
`sub_005420C0` diretamente. **Não entregue**: trace dirigido, implementação de resposta faltante,
`sceCdRead` disparando ao vivo com bytes verificados, gate estável fora de `0x245720`, régua de
render, suíte, commits de código.

## Régua de render (M0-M6)

Sem mudança (nenhum código executado nesta sessão). `M4` não avaliado.

## Suíte

Não rodada — nenhum arquivo tracked mudou (só leitura).

## Commits

Nenhum commit de código. Este RESULT doc é o artefato novo desta sessão, repo raiz
(`mc3recomp`, branch `mc3`), pronto para commit local.

## Próximo passo recomendado

Handoff Fase 2, escopado à instrumentação dos 3 portões identificados aqui (não mais leitura):
1. Trace fresh-entry-only em `FUN_005422c8` capturando o valor de `$v0` logo após retornar de
   `func_5418D0` (em `0x54231c`, antes do `beq`) e de `func_541760(4)` (em `0x54232c`, antes do
   `beqz`) — descobrir qual dos dois é `0`/`6` ao vivo.
2. Se o Portão B (`func_541760(4)`) for o culpado e a causa for o mesmo contrato de retorno de
   `PollSema` do passo 11 — **não corrigir aqui**; é a mesma camada congelada (Fase 2 scheduler)
   que o passo 11 já recusou tocar. Precisa de handoff próprio para o dono do
   scheduler/kernel-sync, como o passo 11 já recomendou e o passo 18 não chegou a fazer.
3. Só depois de identificado e resolvido o portão real, `FUN_005422c8` chega em `0x542440`
   (`sceCdRead` fno=1) e o handler já implementado (`SIF.cpp:1110-1177`) finalmente roda —
   nenhuma mudança nova deveria ser necessária nesse handler, ele já lê o ISO de verdade.
