# RESULT — Passo 30: MCMAN handshake

Data: 2026-08-23

## Diagnóstico e mudança

A corrida do passo 29 misturava dois servidores. O trace confirmou:

- 0x80000100/0x80000101: PADMAN; as mensagens capturadas foram "libpad: Module version mismatch".
- 0x80000400: MCMAN, com bind seguido de fno=0xfe, receive de 0x0c bytes.

O decomp de sceMcInit lê três palavras da resposta (DAT_00696f40, DAT_00696f44, DAT_00696f48) e rejeita versões abaixo de 0x20a e 0x20e. Implementei no dispatcher por (sid,fno) uma resposta de 12 bytes: resultado 0, versão A 0x20a e versão B 0x20e.

O trace gerado foi [boot-trace:mc3-memcard-rpc] kind=mcman-init sid=0x80000400 fno=0xfe, result=0x0, versionA=0x20a, versionB=0x20e.

Não houve env-gate, SignalSema injetado ou mudança no scheduler.

## Validação

- Runtime compilado com sucesso (ps2_runtime).
- find_stale.py: Missing 0, Stale (mtime) 0.
- Relink fast sequencial concluído.
- Suíte: primeira execução 277/278, falha conhecida de paridade intercalada em sceGsSyncV; retry 278/278.
- Corrida determinística: MC3_DETERMINISTIC=1, MC3_DISPATCH_BUDGET=500000, MC3_BOOT_TRACE=1, timeout 180 s.
- Resultado: game-thread-return, último frame tick 4260, PC 0x1a2408.
- Depois do handshake, PCs passam por 0x432..., 0x4b... e 0x55..., terminando em 0x1a2408; não retornaram ao plateau 0x1b15xx.
- gifPk1/2/3, gsPrims, gsPixels: todos 0 nessa corrida. M4 não ocorreu.
- Probe 3x: PCs 0x42e738, 0x433254, 0x4f97b8; todos sem render.

## Próxima fronteira

Após mcman-init, o trace ainda registra chamadas MCMAN fno=0x14, fno=0x1 e fno=0xd no fallback neutro. O passo 30 prova a saída do loop de inicialização, mas ainda não prova a semântica completa de cartão ausente ou cartão formatado vazio, nem imagem na tela.

Próximo passo recomendado: casar esses três fnos com as funções sceMc* no decomp e preencher somente os campos que o cliente lê, começando pelo retorno de sceMcGetInfo/sceMcSync; repetir a medição antes de tocar em render.

## Artefatos

- timeline: work/exports/longrun_timeline.md
- log combinado: work/logs/14_run_boot_trace.log
- suíte retry: work/logs/pass30_suite_retry.log
- probe 3x: work/boot_probe/repeat_memcard30_20260823_061130.md
