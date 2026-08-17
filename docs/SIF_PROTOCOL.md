# Protocolo SIF/IOP do MC3 — spec em construção (2026-08-17)

Objetivo: substituir a cadeia de `else if` por payloadAddr fixo (ver
`ROOT_CAUSE_IOP_RESPONSE_LAYER_2026-08-13.md`) por handlers por (servidor, fno) que escrevem a
struct de resposta completa no endereço vindo do request.

## Servidores RPC que o boot usa

Evidência do trace (`14_run_boot_trace.log`): `sceSifSetDma` com cmd `0x80000009` (bind) /
`0x8000000A` (call). Com os símbolos portados (`SYMBOL_PORT_REPORT.md`), o boot path é
`sceCdInit → sceCdDiskReady → sceCdRead/sceCdSync → sceFsInit → ...` + os módulos custom.

| Servidor | Lado IOP | Lado EE (nomeado) | Status |
|---|---|---|---|
| `0x80000001` FILEIO | rom0/IOPRP280 | `sceFsInit` (retail `0x54A080`) | fnos padrão (tabela abaixo) |
| `0x80000592/595/596` cdvd init/S-cmd/N-cmd | IOPRP280 | `sceCdInit/sceCdRead/sceCdSync/...` | protocolo público (ps2sdk libcdvd) |
| custom Angel "LGDEV" | `SYSTEM\LGDEVW.IRX` | família `coreRaw*` (região `0x3984xx-0x398xxx`) | **fnos a extrair do IRX** |
| custom áudio | `SYSTEM\SCREAM.IRX`/`LGAUD.IRX` | `mcAudioRpcMgr`/`sndRpcManager` | depois do CD |
| pad/mc | `PADMAN/MCMAN/MCSERV` | scePad*/sceMc* | depois |

## FILEIO — fnos padrão (ps2sdk `common/include/fileio-common.h`)

`0x0`=OPEN `0x1`=CLOSE `0x2`=READ `0x3`=WRITE `0x4`=LSEEK `0x5`=IOCTL `0x6`=REMOVE `0x7`=MKDIR
`0x8`=RMDIR `0x9`=DOPEN `0xA`=DCLOSE `0xB`=DREAD `0xC`=GETSTAT `0xD`=CHSTAT `0xE`=FORMAT
`0xF`=ADDDRV `0x10`=DELDRV. Structs de request/response com tamanhos: fileio-common.h
(open=260B, read_arg=24B + read_data=48B, lseek=16B, getstat=264B...).

## Evidência dura: o cliente SCE decompilado com nomes (2026-08-17)

`work\exports\alpha_decomp_sce.txt` — 179 funções `sce*`/`ipc*`/`coreFile*`/`psxCdCache*` do
alpha decompiladas pelo Ghidra **com os nomes e até os globais internos do MC.MAP**
(`_sceCd_rd_intr_data`, `_sceCd_ee_read_mode`, ...). Gerado por
`tools\ghidra\ExportSceDecomp.java`. É a referência primária para implementar os handlers.

Confirmado nesse decompilado:

- `sceCdInit`: bind `0x80000592`, depois `sceSifCallRpc(fno=0, send=4B, recv=0x10)`.
- `sceCdRead`: `sceSifCallRpc(cliente_ncmd, fno=1, async, send=0x18)` com buffer de resposta
  de **0x90 bytes** (`_sceCd_rd_intr_data`) — **é exatamente o `request=0x1 size=0x90` que o
  runtime descarta hoje.** O handler atual escreve 4 bytes onde a intr-data tem 144.
- Binds vistos no boot: `0x80000592` (cdvd), `0x80000001` (fileio), `0x80000400` (padman),
  `0x80000100/0x80000101` (memcard), `0x80000701` (usbkb), `0x80000211` (a identificar).
- Descartado: LGDEVW.IRX é driver Logitech (volante/headset), não file server.
- Bônus: `sceMpeg*`/`sceIpu*` decompilados = a lane de FMV/skip de vídeo tem referência pronta.

## Requests hoje descartados (causa-raiz de 13/08) — leitura atualizada

| request | size | leitura |
|---|---|---|
| `0x1` | 0x90 | resposta N-cmd de `sceCdRead` (`_sceCd_rd_intr_data`, 0x90 bytes) — confirmado |
| `0x1` | 0x80 | variação da mesma família (conferir no decomp: `sceCdSeek`/`sceCdGetToc`) |
| `0x0` | 4/8 | init handshake (fno=0) de um dos servidores |
| `0x9`, `0x22`, `0xFF` | 4-8 | mapear pelo decomp da função chamadora (olhar `ra` no trace) |

Regra mantida: nada vira código sem casar o callsite no decomp ou capturar no PCSX2.

## Como fechar cada handler (automação)

1. **Decomp nomeado** (`alpha_decomp_sce.txt`): para cada função sce*, extrair (bind id, fno,
   tamanho de send, tamanho/estrutura de recv) — o cliente descreve o protocolo inteiro.
2. **Captura PCSX2** (conteúdo dos bytes, quando a semântica não for óbvia):
   `docs\PCSX2_MCP_LAUNCH_AND_CAPTURE_2026-08-09.md`.
3. Implementar em `SIF.cpp` (fork PS2Recomp, branch mc3): dispatcher por servidor → fno →
   handler que preenche a struct inteira no payload do request.

## Critério de pronto da fase 1

Boot limpo com `mc3-iop-response-unhandled` = 0, `sid=5` sinalizado via `coreFileSignalSema`
(retail `0x398450`) pelo caminho de completion real, medido com
`MC3_DETERMINISTIC=1 MC3_DISPATCH_BUDGET=25000` e `21_probe_repeat.bat 10`.
