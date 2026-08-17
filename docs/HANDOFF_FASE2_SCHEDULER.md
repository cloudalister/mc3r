# Handoff — Fase 2: scheduler cooperativo determinístico (+ higiene de log antes)

Dois blocos, nesta ordem. O primeiro é rápido e independente; o segundo é a maior mudança
arquitetural do projeto até aqui — por isso tem etapa de design obrigatória antes de codar.

## Bloco A (higiene, ~30 min): log legado de unhandled

Hoje o log `mc3-iop-response-unhandled` dispara mesmo quando o dispatcher novo
(`handleCdvdRpc`/`handleUsbKbRpc`) atendeu o evento — são camadas paralelas de diagnóstico, e
isso polui a métrica principal da Fase 1 (ver `docs/RESULT_USBKB_V1.md`, seção do delta 18→20).

Fazer: quando o dispatcher novo tratar um evento, o caminho legado não deve mais logar
`unhandled` para aquele evento (retorno/flag de "handled" propagado — não silenciar o log
inteiro; eventos realmente não tratados continuam aparecendo). Aceite: um boot de trace mostra
`mc3-iop-response-unhandled` == somente eventos sem handler novo; os pares atendidos aparecem
só como `mc3-cdvd-rpc`/`mc3-usbkb-rpc`. Commit separado.

## Bloco B: scheduler cooperativo

### Problema (evidência)

Threads guest são `std::thread` reais → interleaving do host decide o boot: 9-10 Stable PCs
distintos por 10 corridas em todos os baselines (17/08: `baseline_20260817`, `usbkb_v1`).
Diagnóstico formal: `docs/PROBE_NONDETERMINISM_ROOT_CAUSE.md` + checkpoint 13/08 no
`PS2_PROJECT_STATE.md`. Budget de dispatch não resolve (só amostragem).

### Direção da solução

Modo cooperativo ativado por `MC3_DETERMINISTIC=1` (a mesma variável já usada em toda medição —
vira ela finalmente fazendo o que o nome diz). Com a variável desligada, comportamento atual
intacto (rollback trivial). Não é env-gate de experimento SIF — é chave de modo do runtime.

- Uma thread host executa as threads guest cooperativamente (fibers do Windows ou corrotinas;
  escolher na etapa de design depois de ler o código).
- Troca de contexto SÓ em pontos determinísticos: `WaitSema`/`PollSema`, `SleepThread`,
  `SuspendThread`, waits de SIF/RPC, wait de VBlank/`sceGsSyncV`, `RotateThreadReadyQueue`,
  e término de thread. Nada de preempção por tempo do host.
- Fila de prontos: prioridade do guest (o kernel EE real é prioridade fixa + FIFO por nível);
  desempate por ordem de criação. Nenhuma decisão pode depender de relógio/timing do host.
- VBlank/timers: em modo determinístico, o "tempo" avança por contagem de eventos/dispatch
  (determinístico), não por relógio de parede. Ver como o runtime gera VBlank hoje e propor no
  design.

### Etapa 1 — design (obrigatória, antes de qualquer código)

Ler: `ps2xRuntime/src/lib/Kernel/Syscalls/Thread.cpp`, `Sync.cpp`, `Helpers/State.h`,
`ps2_runtime.cpp` (criação de threads, semáforos, VBlank, onde `std::thread` nasce e onde
bloqueia). Produzir `docs/FASE2_SCHEDULER_DESIGN.md`: inventário dos pontos de bloqueio/spawn,
mecanismo escolhido (fiber vs corrotina vs loop de estados), lista exata dos pontos de yield,
como VBlank avança, o que NÃO muda no modo padrão, e riscos (ex.: deadlock se algum completion
hoje depende de preempção real — citar o caso e o plano de detecção: watchdog por contagem de
dispatch, não por tempo).

### Etapa 2 — implementação

- Modo padrão (env off): zero mudança de comportamento; suíte `ps2x_tests` precisa continuar
  ≥266/269 como está.
- Modo determinístico: implementar conforme o design. Se a suíte tiver testes que exercitam
  preempção real, eles rodam no modo padrão (não adaptar teste para esconder bug do modo novo —
  se o modo novo trava um teste, isso é achado, documentar).

### Etapa 3 — validação

1. Build + suíte (modo padrão) ≥266/269.
2. Relink (`10_link_partial_runner.bat fast`, timeout ≥6 min).
3. `MC3_DETERMINISTIC=1` `MC3_DISPATCH_BUDGET=25000` `21_probe_repeat.bat 10 595 sched_v1`.
4. **Aceite da fase: 1 único Stable PC em 10/10 corridas, mesma classificação, 10/10 com
   evidência válida (marker presente, sem timeout).** Se der 2-3 PCs, documentar de onde vem a
   variação residual (provável fonte: algum ponto de troca fora da lista) — parcial é progresso,
   mas o aceite é 1.
5. Rodar também 10x com env off (label `sched_off_regression`) e comparar com `usbkb_v1`:
   distribuição semelhante = modo padrão intacto.

### Regras

- Sem SignalSema injetado; sem mexer nos handlers SIF (Fase 1 congelada durante esta fase).
- Commits locais no fork branch `mc3` (um para o Bloco A, um ou mais para o B), sem push.
- Resultado em `docs/RESULT_FASE2_SCHED_V1.md` — incluindo negativo/parcial, sem maquiar.
- Se travar em deadlock no modo novo: registrar o par (thread bloqueada, recurso esperado) com
  o trace, e parar — não contornar com sleep/timeout de host.
