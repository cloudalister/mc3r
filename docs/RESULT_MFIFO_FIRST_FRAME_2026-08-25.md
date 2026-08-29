# MC3 recomp — primeiro framebuffer técnico (2026-08-25)

## Resultado

O gate visual histórico foi atingido pela primeira vez no runner nativo:

- `gifPkTotal > 0`: `gifPk1=14`, `gifPk2=75`, `gifPk3=0`;
- `gsPrims=754`;
- `gsPixels=2240388`;
- frame exportado em `work/evidence/mc3_first_frame.png` (`640x448`, 12.919 bytes);
- SHA-256: `17e67bfd2631438eecf75b41680c43c089a7436d0eeb0f1326cd81197f4fe564`.

Este é um framebuffer real, mas ainda não é uma tela legível: a imagem está quase toda preta, com linhas e triângulos coloridos esparsos. Portanto, o marco técnico de render foi atingido; paridade visual/menu ainda não.

## Causa provada do plateau `0x5268a0`

Os endereços comparados por `sub_00526880` não são globais `0x6f...`:

- `0x10009030` = `VIF1.TADR`, consumidor;
- `0x1000D010` = `fromSPR.MADR`, produtor.

O runtime não implementava o canal `fromSPR`, não respeitava a retenção/reinício do drain quando o MFIFO fica vazio e ainda apagava `CHCR.STR` ao ler o registrador. Assim, o produtor não avançava de modo consumível e o jogo acabava preso no controle de espaço do ring.

O contrato foi confirmado no EE User's Manual 6.0:

- `D_CTRL.MFD=10` seleciona VIF1 como drain do MFIFO;
- `fromSPR` é o source e VIF1/GIF é o drain;
- quando `Dd_TADR == D8_MADR`, o drain é retido sem limpar `STR`;
- `REFE` encerra a chain e não possui endereço de próximo tag;
- `D_RBOR`/`D_RBSR` definem base e máscara do ring.

Referência: <https://usermanual.wiki/Pdf/EEUsersManual.1748563585.pdf>, seções 5.4 a 5.6 e registradores `D_CTRL`, `D_RBOR`, `D_RBSR`.

## Mudanças causais

Em `PS2Recomp/ps2xRuntime`:

- implementação de DMA `fromSPR` scratchpad → RDRAM;
- avanço e wrap de `MADR`/`SADR`;
- wrap byte a byte pelo ring `D_RBOR`/`D_RBSR`;
- retenção do VIF1 quando `TADR == fromSPR.MADR`;
- reinício automático do drain quando o produtor publica dados;
- manutenção de `STR` e ausência de completion enquanto o MFIFO está vazio;
- remoção do auto-clear artificial de `CHCR.STR` em leitura;
- `REFE` mantém `TADR` no tag terminal;
- exportação observacional opcional de PNG via `MC3_FRAME_DUMP` após render real.

Não houve `SignalSema` injetado, alteração no scheduler nem correção semântica escondida por env gate. `MC3_FRAME_DUMP` apenas salva evidência visual.

## Validação

- suíte: `281/281` em retry limpo;
- objetos gerados: `Missing=0`, `Stale=0` em `15.811` C++/OBJ;
- fast relink: OK;
- boot: saiu do plateau, consumiu continuamente pacotes MFIFO e atingiu GIF/GS;
- PNG: `ok=1`, `640x448`.

Comando do probe:

```powershell
$env:MC3_DETERMINISTIC='1'
$env:MC3_DISPATCH_BUDGET='1200000'
$env:MC3_BOOT_TRACE='1'
$env:MC3_FRAME_DUMP='E:\Games\Emuladores\Sony\mc3recomp\work\evidence\mc3_first_frame.png'
.\14_run_boot_trace.bat 300
```

## Próxima fronteira

Após o primeiro lote, `gifPk1` continuou crescendo (observado até `720`) e `gifPk2` chegou a `85`, mas `gsPrims`/`gsPixels` ficaram parados em `754`/`2240388`. A próxima investigação deve explicar por que os pacotes PATH1 posteriores não viram novas primitivas e por que o framebuffer resultante está geometricamente corrompido. Alvos principais: saída VU1/XGKICK, framing de GIF tag e seleção/apresentação do framebuffer.

