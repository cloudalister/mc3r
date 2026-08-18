# Handoff — Fase 1, passo 3: destravar o gate único `0x5a8908` (frente fileio/provider)

Contexto novo que muda o método: com a Fase 2 aceita (`docs/RESULT_FASE2_SCHED_V1.md`), o boot
em `MC3_DETERMINISTIC=1` para **sempre** em `0x5a8908` — o spin da região `memHeap::Begin`
esperando `func_4FA398` (cadeia provider/`zipFile`) retornar !=0. Não existe mais distribuição:
**uma corrida = uma prova.** Use isso: cada mudança é validada com 1 corrida determinística
(e o `21_probe_repeat 3` só como confirmação final).

## Objetivo

Fazer o boot atravessar `0x5a8908`. A hipótese de trabalho (symbol port + causa-raiz 13/08): o
provider não inicializa porque a pilha de arquivo SCE não funciona — `sceFsInit` (servidor
FILEIO `0x80000001`) e/ou os reads do cdvd nunca completam, o completion `coreFileSignalSema`
(retail `0x398450`) nunca roda, `zipFile::zipOpen` nunca abre os `.DAT`.

## Método (dirigido por trace, não por palpite)

1. **Uma corrida determinística com trace completo** (`14_run_boot_trace.bat` ou o modo de
   trace do probe, com `MC3_DETERMINISTIC=1 MC3_DISPATCH_BUDGET=25000`). Extrair, na ordem do
   boot: todos os eventos `mc3-iop-response-unhandled` restantes (agora a métrica é limpa —
   bloco A da Fase 2), todos os binds, e a cadeia exata que leva ao spin `0x5a8908`
   (quem chama `func_4FA398`, o que ela testa, qual global falta).
2. Para cada (sid, fno) unhandled na rota crítica, na ordem em que aparecem:
   - identificar a função cliente no decomp (`work/exports/alpha_decomp_sce.txt`; se faltar
     função, regenerar com filtro maior via `tools/ghidra/ExportSceDecomp.java`);
   - implementar handler no dispatcher (mesma infra dos passos 1-2), semântica real:
     FILEIO usa os fnos/structs padrão documentados em `docs/SIF_PROTOCOL.md` (open/close/
     read/lseek...) e o backend de arquivo host que o runtime já tem (`FileIO.cpp` /
     `CD.cpp` — os `.DAT` estão em `extracted_iso\`);
   - **1 corrida determinística**: o gate moveu ou o próximo unhandled apareceu? Registrar e
     iterar.
3. O completion do coreFile: quando um read/open completar de verdade, verificar no trace se
   `coreFileSignalSema` roda e o `sid=5` (ou equivalente da sessão) é sinalizado **pelo caminho
   legítimo**. Se o cliente registra callback de conclusão e o runtime não o chama, implementar
   a entrega do callback — não o sinal direto.

## Critérios de parada

- **Vitória do passo:** Stable PC determinístico sai de `0x5a8908` e estabiliza em outro ponto
  mais adiante (novo gate = novo achado, documentar qual função nomeada é).
- **Vitória grande (não exigida):** `gif>0`/`gsw>0` — se acontecer, PARAR TUDO e documentar o
  estado exato (env, commit, comando) antes de qualquer outra mudança.
- Timebox: se após ~6 handlers novos o gate não mover, parar e documentar a cadeia completa do
  bloqueio com evidência (isso também é entregável).

## Regras (inalteradas)

- Dispatch por (sid, fno); payloadAddr só destino. Sem env-gate novo. Sem SignalSema injetado —
  completion sempre pelo produtor legítimo (callback/caminho do cliente).
- Sem chute de bytes: struct incerta = capturar no PCSX2
  (`docs/PCSX2_MCP_LAUNCH_AND_CAPTURE_2026-08-09.md`) ou TODO + valor neutro documentado.
- Scheduler da Fase 2 congelado (qualquer suspeita de bug nele = reportar, não remendar).
- Suíte ≥266/269 modo padrão; relink timeout ≥6 min; commits locais no fork `mc3` sem push.
- Resultado em `docs/RESULT_FILEIO_GATE_V1.md`: sequência de handlers adicionados, trace do
  gate antes/depois de cada um, estado final honesto.
