# Handoff — Fase 1, passo 2: servidor 0x80000211 (sceUsbKb) no dispatcher

Identificação fechada: o bind `sceSifBindRpc(0x6939a0, 0x80000211, 0)` está em `sceUsbKbInit`
(ver `work/exports/alpha_decomp_sce.txt`, seção `sceUsbKbInit @ 004f4f58`). O servidor
`0x80000211` é o RPC de teclado USB (`sceUsbKb*`, módulo `USBKB.IRX` que o jogo carrega).
Os requests que o runtime descarta hoje (`request=0x1 size=0x90`, e possivelmente
`0xFF`/`0x9`/`0x0` — conferir no trace o sid de cada um) devem em boa parte ser desse servidor.

## Escopo

Estender o dispatcher criado no passo 1 (`handleCdvdRpc`/infra `g_mc3RpcClientSid` em
`PS2Recomp/ps2xRuntime/src/lib/Kernel/Stubs/SIF.cpp`, commit `e85cf73`) com handlers do
servidor `0x80000211`. Semântica-alvo: **teclado ausente/nenhum conectado**, respondida de
forma completa e coerente com o que o cliente decompilado espera ler. Nada além do usbkb neste
passo.

## Fontes de verdade (nesta ordem)

1. `work/exports/alpha_decomp_sce.txt`: `sceUsbKbInit`, `sceUsbKbGetInfo`, `sceUsbKbSync`,
   `sceUsbKbRead`, `sceUsbKbSetArrangement`, `sceUsbKbCnvRawCode` — extrair fno, tamanhos de
   send/recv e quais campos o cliente lê depois do retorno (ex.: contagem de teclados,
   flags de status). O que o cliente nunca lê pode ficar zerado.
2. O trace real: `work/logs/14_run_boot_trace.log` + os logs do probe `cdvd_dispatch_v1` —
   confirmar quais (sid, fno, size) chegam de fato no boot.
3. ps2sdk (`ee/rpc/usbkeyboard`) como referência cruzada de nomes/semântica, se precisar.

## Regras (as mesmas do passo 1, sem exceção)

- Dispatch por (sid, fno); payloadAddr é só destino de escrita.
- Sem env-gate novo, sem SignalSema injetado, sem chute de bytes (campo desconhecido = TODO +
  valor neutro/zero).
- Remover da cadeia legada apenas os braços que este handler substitui.

## Validação

1. Build alvos `ps2_runtime ps2x_tests` (build dir `PS2Recomp\out\build` já configurado;
   PATH: cmake portátil na raiz, ninja do VS2022, g++ do msys64 — ver
   `docs/RESULT_CDVD_DISPATCH_V1.md` para os comandos exatos usados no passo 1).
2. Suíte de `PS2Recomp\out\build`: esperado ≥266/269 (flake VBlank conhecido); falha nova em
   SIF = parar e reportar.
3. Relink `10_link_partial_runner.bat fast` (timeout ≥6 min), conferir timestamp.
4. Probe `MC3_DETERMINISTIC=1` `MC3_DISPATCH_BUDGET=25000` `21_probe_repeat.bat 10 595 usbkb_v1`.
5. Comparar com `cdvd_dispatch_v1` (relatório em `work\boot_probe\`): métrica principal =
   contagem de `mc3-iop-response-unhandled` por (request,size) antes/depois — os do usbkb
   devem zerar; distribuição de PCs comparada como distribuição, nunca corrida única.
   `gif>0`/`gsw>0` segue sendo bônus, não expectativa.

## Entregáveis

- Commit local no fork branch `mc3`, mensagem simples, sem push.
- `docs/RESULT_USBKB_V1.md`: fno table extraída do decomp, diff resumido, suíte, probe
  antes/depois (inclusive negativo), pendências.
