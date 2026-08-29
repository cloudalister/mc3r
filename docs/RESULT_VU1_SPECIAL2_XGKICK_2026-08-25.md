# MC3 recomp - VU1 SPECIAL2/XGKICK corrigido (2026-08-25)

## Resultado

O plateau em `gsPrims=754` foi explicado e removido sem alterar scheduler, sem injetar semaforo e sem gate semantico por variavel de ambiente.

Antes da correcao, o runtime interpretava qualquer lower opcode com `funct=0x3D` como `XGKICK`. O probe provou que esses eventos eram falsos:

- `addr=0x0`;
- primeiro suposto GIFtag `0x43a646de`;
- `firstNloop=18142`;
- `tags=256`, sem `EOP`;
- pacote fabricado de `4.648.448` bytes;
- nenhum registro `XYZ2/XYZF2` e `primDelta=0`.

Depois da correcao do decoder SPECIAL2, o PATH1 passou a ser valido:

- `XGKICK addr=0x1530`;
- GIFtag `0x3002c00500008004` / `0x3002400400008004`;
- `size=208`, `tags=1`, `EOP=1`;
- quatro registros desenhaveis por pacote;
- `primDelta=2` por pacote nos primeiros 128 probes.

No boot deterministico de 1.200.000 dispatches, o render avancou para:

- `gifPk1=117986`;
- `gifPk2=14659`;
- `gsPrims=262815`;
- `gsPixels=10372487`.

## Causa

Os lower opcodes `0x3C..0x3F` selecionam quatro tabelas SPECIAL2. A operacao final combina os dois bits baixos do seletor com os bits `10:6`. O runtime tratava `0x3D`, `0x3E` e `0x3F` como operacoes diretas; assim, instrucoes da tabela `0x3D` - incluindo MFIR - disparavam XGKICK falso.

O decoder agora usa:

```text
special2 = (instr & 0x3) | ((instr >> 4) & 0x7C)
```

Com isso, `XGKICK` so e executado para a operacao SPECIAL2 `0x6C`. MOVE, MR32, LQI/SQI, LQD/SQD, DIV/SQRT/RSQRT, MFIR/MTIR, MFP, XTOP e XITOP tambem foram remapeados para seus seletores compostos.

Referencia cruzada de implementacao: tabelas lower SPECIAL2 e leitura de `VI[Is]` do projeto PCSX2, em `pcsx2/VUops.cpp`.

## Evidencia visual

Foi adicionada uma regua observacional opcional `MC3_FRAME_DUMP_MIN_PRIMS`, sem efeito no guest. Com limiar de 20.000 primitivas, o dump ocorreu em:

- tick `7980`;
- `DISPFB1=0x11000`;
- `gifPk1=9176`, `gifPk2=1139`;
- `gsPrims=21058`, `gsPixels=4421855`.

Artefato: `work/evidence/mc3_vu1_20k_prims.png` (`512x448`, 10.297 bytes).

SHA-256: `cd9372134cfd4da0f249c6138948f4af31313deceb94274af1afa1566dc2bcc0`.

A imagem agora contem um grande poligono roxo sobre fundo preto. E uma mudanca visual causal em relacao ao frame anterior, mas ainda nao e logo/menu nem imagem correta.

## Validacao

- build do runtime/testes: OK;
- fast relink do runner parcial: OK;
- suite final em retry limpo: `282/282` (a primeira corrida repetiu apenas a falha intermitente conhecida de paridade em `sceGsSyncV`);
- `git diff --check`: sem erros; apenas avisos de normalizacao LF/CRLF;
- novo teste garante que MFIR SPECIAL2 nao envia pacote PATH1;
- os 128 primeiros XGKICK observados tinham framing valido e `primDelta=2`.

## Proxima fronteira

O proximo defeito ficou isolado na escrita/apresentacao do framebuffer:

- `DISPFB1` permanece coerente em `0x11000` ate aproximadamente `gsPrims=35581`;
- depois muda para valores impossiveis, primeiro `0x5fbdbdbd00070707` e depois `0x43a11cc178040156`;
- a geometria continua avancando, mas a apresentacao fica corrompida.

Proximo probe causal: correlacionar cada escrita de `DISPFB1` com o caminho de origem (GIF A+D versus registrador privilegiado), o endereco GS decodificado e os 128 bits do payload que produziram a primeira transicao invalida. Nao corrigir por clamp ou filtro: identificar primeiro a origem do write.
