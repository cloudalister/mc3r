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

## Requests hoje descartados pelo runtime (causa-raiz de 13/08)

| request | size | hipótese atual |
|---|---|---|
| `0x0` | 4/8 | FILEIO OPEN ou fno 0 de servidor custom |
| `0x1` | 0x90/0x80 | **não bate com FILEIO CLOSE** (response de 144B) → provável LGDEV/cdvd |
| `0x9` | 4 | FILEIO DOPEN ou custom |
| `0x22` | 4 | fora da tabela FILEIO → custom (LGDEV) |
| `0xFF` | 8 | handshake/init de servidor custom |

Regra: nenhuma dessas hipóteses vira código sem confirmação por (a) dispatch table do IRX ou
(b) captura PCSX2. Nada de valor plausível.

## Como confirmar (automação)

1. **Dispatch do IRX**: importar `SYSTEM\LGDEVW.IRX` (e `SCREAM.IRX`) no Ghidra headless; achar
   `sceSifRegisterRpc(server_id, func, ...)`; extrair server id e o switch(fno) do handler. Isso dá
   a tabela completa de fnos + tamanhos de struct do lado que responde.
2. **Captura PCSX2**: `docs\PCSX2_MCP_LAUNCH_AND_CAPTURE_2026-08-09.md` — dump do buffer de
   resposta real para cada (servidor, fno) no mesmo ponto do boot.
3. Implementar em `SIF.cpp` (fork PS2Recomp, branch mc3): dispatcher por servidor → fno →
   handler que preenche a struct inteira no payload do request.

## Critério de pronto da fase 1

Boot limpo com `mc3-iop-response-unhandled` = 0, `sid=5` sinalizado via `coreFileSignalSema`
(retail `0x398450`) pelo caminho de completion real, medido com
`MC3_DETERMINISTIC=1 MC3_DISPATCH_BUDGET=25000` e `21_probe_repeat.bat 10`.
