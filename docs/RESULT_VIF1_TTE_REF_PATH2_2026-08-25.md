# Resultado VIF1 TTE/REF e PATH2 - 2026-08-25

## Resultado

Foi removida a origem causal dos grandes triangulos/faixas que dominavam o framebuffer.

Com `CHCR.TTE=1`, o DMAC deve entregar ao VIF1 os 8 bytes superiores de **toda** tag DMA antes do payload. O runtime fazia isso apenas para tags com payload local (`CNT/NEXT/CALL/RET/END`) e omitia a parte superior de `REF/REFE`.

No MC3, essas tags externas guardam o comando `DIRECT` na parte superior e o GIF packet no endereco referenciado. Sem o `DIRECT`, o parser VIF1 interpretava o GIFtag/payload como VIFcodes. A assinatura observada era:

- falso `DIRECT cmd=0xd0001d00`, com `declaredQw=0x1d00`;
- packet truncado enviado ao PATH2;
- vertices e estados aleatorios no GS;
- grandes triangulos/faixas coloridas no framebuffer.

## Correcao

- `ps2_memory.cpp`: transferencia da parte superior da tag separada do payload e aplicada a todo ID quando `VIF1 CHCR.TTE` esta ativo;
- tags `REF/REFE` agora preservam o `DIRECT` antes do payload externo;
- tags sem TTE nao recebem implicitamente os 8 bytes superiores;
- nova regressao cobre `REFE + TTE + DIRECT + payload externo`;
- testes antigos que dependiam de tag-transfer agora declaram TTE explicitamente.

Nao houve clamp/filtro de vertices, `SignalSema` injetado, mudanca de scheduler ou correcao semantica por env gate.

## Validacao

- suite completa: `283/283`;
- boot deterministico/headless de 1.200.000 dispatches;
- falsos/truncados `DIRECT`: `0`;
- estado tardio: `gifPk1=78052`, `gifPk2=42804`, `gsPrims=162356`, `gsPixels=16973824`;
- `DISPFB1=0x11000` permaneceu estavel.

Evidencias:

- `work/evidence/mc3_vif1_tte_ref_fix.png`: captura inicial, quadro verde/preto sem geometria gigante;
- `work/evidence/mc3_vif1_tte_ref_fix_late.png`: captura apos 100.000 primitivas, quadro cinza uniforme;
- SHA-256 tardio: `1149f7dd8ec4a08ce910b061dd4d961bb27286ba353d646277d9d05390241c86`.

Ainda nao ha logo/menu/carro reconhecivel. O gate visual final continua aberto.

## Proxima fronteira

O PATH1 recebe GIF packet formalmente valido em `VU1[0x1530]`:

- 208 bytes;
- EOP presente;
- 4 loops, 3 registradores por loop.

Porem o buffer e repetido sem vertices uteis: XYZ permanece em sentinelas equivalentes a `(0,0)` e `(4095.94,4095.94)`. O proximo lote deve provar se a origem e:

1. UNPACK VIF1 que alimenta a microprograma;
2. instrucao/branch ausente ou incorreta no interpretador VU1;
3. estado de pipeline Q/P/flags nao preservado corretamente.

Primeiro passo exato: instrumentar as escritas em `VU1[0x1530..0x1600]` e correlacionar a ultima instrucao VU1 que altera cada qword antes do XGKICK.
