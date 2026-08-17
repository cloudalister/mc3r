# Handoff — Fase 1, passo 1: handler cdvd mínimo por (servidor, fno)

Escopo deste handoff: **só** o servidor cdvd (`0x80000592` e o cliente N-cmd), fnos de init (0) e
read/sync (1). Nada de fileio, áudio, pad, mc. Nada de mexer no scheduler (isso é Fase 2).

## Leitura obrigatória antes de codar

1. `docs/ROOT_CAUSE_IOP_RESPONSE_LAYER_2026-08-13.md` — por que o else-if por payloadAddr fixo
   não converge. **É proibido adicionar mais um else-if por endereço fixo.**
2. `docs/SIF_PROTOCOL.md` — spec e evidência.
3. `work/exports/alpha_decomp_sce.txt` — decompilado nomeado. Funções-chave: `sceCdInit`
   (bind `0x80000592`, call fno=0 send=4 recv=0x10), `sceCdRead` (fno=1, send=0x18, resposta
   assíncrona de 0x90 bytes em `_sceCd_rd_intr_data`), `sceCdSync`, `sceCdNcmdDiskReady`,
   `_sceCd_ncmd_prechk`. Os offsets do send/recv estão no próprio decomp — extrair de lá, não
   inventar.
4. `PS2Recomp/ps2xRuntime/src/lib/Kernel/Stubs/SIF.cpp` — a camada atual (cadeia de else-if,
   linhas ~820-935) e como as respostas chegam/são entregues hoje.

## O que construir

Em `SIF.cpp` (fork `PS2Recomp`, branch `mc3`):

- Um dispatcher `handleCdvdRpc(requestId/fno, payloadAddr, payloadSize)` chaveado por
  **(servidor, fno)** — o `payloadAddr` é sempre o destino da escrita, nunca a chave.
- fno 0 (init): responder o handshake com a struct que `sceCdInit` espera (0x10 bytes — layout
  no decomp; o que não for derivável do decomp, preencher com o que faz o cliente prosseguir e
  marcar TODO com o campo em dúvida).
- fno 1 (read): completar a leitura usando o backend de leitura de ISO que o runtime já tem
  (procurar por quem serve `sceCdRead`/CD hoje em `CD.cpp`/`FileIO.cpp`), escrever a intr-data
  de 0x90 bytes no buffer indicado pelo request e produzir o caminho de completion que o
  cliente espera (callback/sema que `sceCdSync` verifica — está no decomp de `sceCdSync`).
- Remover da cadeia antiga os braços que esse dispatcher substitui; o resto da cadeia fica
  intacto por enquanto.
- Sem env-gate novo. O dispatcher é o caminho padrão. (Os env-gates antigos não cobertos ficam
  como estão neste passo.)

## Validação (nesta ordem)

1. Build: cmake portátil `cmake-3.30.5-windows-x86_64\bin\cmake.exe`, ninja do VS2022
   (`C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja`),
   g++ do `C:\msys64\ucrt64\bin` no PATH. Build dir: `PS2Recomp\out\build` (não recriar do
   zero — já configurado). Alvos: `ps2_runtime ps2x_tests`.
2. Suíte: `ps2x_tests` rodada de `PS2Recomp\out\build` (CWD importa). Esperado ≥266/269
   (flakes de VBlank conhecidos); qualquer falha nova relacionada a SIF/CD = parar e reportar.
3. Relink: `10_link_partial_runner.bat fast` (leva ~3 min; NUNCA usar timeout menor que 6 min).
   Conferir timestamp novo do `work\link\partial\mc3_partial.exe`.
4. Probe: `MC3_DETERMINISTIC=1`, `MC3_DISPATCH_BUDGET=25000`,
   `21_probe_repeat.bat 10 595 cdvd_dispatch_v1`.
5. Comparar com o baseline de 17/08 (`work\boot_probe\repeat_baseline_20260817_181511.md`):
   o que se espera ver se funcionou: queda/zeramento das linhas
   `mc3-iop-response-unhandled` para request 0x1/0x0 no trace, e mudança na distribuição de
   PCs. **Atenção: a medição é não-determinística (9 PCs/10 runs no baseline) — comparar
   distribuições, nunca uma corrida isolada.** `gif>0`/`gsw>0` seria vitória, mas não é
   esperado neste passo.

## Regras

- Não injetar SignalSema em nada.
- Não "chutar" bytes de resposta: campo desconhecido = TODO documentado + valor neutro.
- Commit local no fork (branch mc3) com mensagem simples; **não fazer push** — o coordenador
  revisa e sobe.
- Registrar resultado (mesmo que negativo) em `docs/RESULT_CDVD_DISPATCH_V1.md`: diff resumido,
  suíte, probe antes/depois, unhandled antes/depois.
