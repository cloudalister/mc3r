# Auditoria M4-M5 (caminho de render) — SÓ LEITURA

Executa `docs/HANDOFF_AUDIT_M4M5_RENDER.md` do início ao fim. Data: 2026-08-17. Nenhuma linha
de código foi alterada, nenhum build/relink/probe foi rodado — só leitura de runtime
(`PS2Recomp/ps2xRuntime`), decompilação read-only via Ghidra headless (`-noanalysis`, projeto
`work/mc2recomp`, programa `SLUS_213.55`) e grep no `work/exports/retail_symbol_port.csv`.

## Resumo executivo (o achado que muda a régua)

A hipótese de partida do projeto (`docs/CAMINHO_ATE_O_FRAME.md`: "M4-M5 são a segunda
montanha... peças prontas no runtime, nunca exercitadas de verdade") está **parcialmente
errada para menos**: o runtime não tem só peças soltas — **a cadeia inteira DMA→VIF1→VU1→GIF→GS
já está ligada ponta a ponta em código, sem nenhum env-gate experimental**, algo que só se
confirma lendo o wire-up central:

```cpp
// PS2Recomp/ps2xRuntime/src/lib/ps2_runtime.cpp:664-678
m_gs.init(gsVram, ..., &m_memory.gs());
m_gifArbiter.setProcessPacketFn([this](const uint8_t *data, uint32_t size)
                                { m_gs.processGIFPacket(data, size); });
m_memory.setGifArbiter(&m_gifArbiter);
m_memory.setVu1MscalCallback([this](uint32_t startPC, uint32_t itop)
                             { m_vu1.execute(m_memory.getVU1Code(), PS2_VU1_CODE_SIZE,
                                             m_memory.getVU1Data(), PS2_VU1_DATA_SIZE,
                                             m_gs, &m_memory, startPC, itop, 65536); });
m_memory.setVu1MscntCallback([this](uint32_t itop)
                             { m_vu1.resume(...); });
```

VIF1 MSCAL/MSCNT chama de verdade o interpretador VU1; VU1 XGKICK chama de verdade o
`GifArbiter`; o `GifArbiter` chama de verdade `GS::processGIFPacket`; `GS::processGIFPacket`
decodifica GIFtag PACKED/REGLIST/IMAGE de verdade e chama `vertexKick` → um rasterizador de
software real (scissor, alpha test, blending com PABE, texturing CT32/CT16/T4/T8, FBMSK) que
escreve pixels em VRAM. Nada disso está atrás de `getenv("MC3_...")` — é caminho de produção,
não experimento (grep confirma: zero ocorrências de `MC3_`/`getenv` nos 8 arquivos do escopo).

Isso **não** significa que M4/M5 estão prontos — significa que a "segunda montanha" é mais
estreita do que o documentado: os gaps reais são pontuais (Z-test ausente no rasterizador,
algumas funções EFU do VU1 são no-op, um punhado de stubs `sceDma*`/`sceVu0*` fora do caminho
crítico) e o bloqueio maior continua sendo **o jogo nunca chega a programar o canal DMA2/GIF**
porque o boot trava em M1/M2 (`0x5a8908`, ver `STATUS.md`) — confirmado pelo próprio contador
`gifCopyCount` só incrementar quando o canal DMA 0x1000A000 recebe uma transferência real
(`ps2_memory.cpp:1086-1130`), e por `docs/MASTER_PLAN_TITLE_SCREEN.md` já ter registrado uma
corrida com `dma=2 vif=3 gif=0 gsw=0` — ou seja, mesmo com atividade em DMA/VIF1, o canal GIF
nunca foi programado pelo jogo até hoje.

---

## Pergunta 1 — qual é o caminho mínimo do primeiro frame de menu/loading?

**Resposta curta: não é path3 puro nem exige VU1.** É escrita direta de GIFtag num ring buffer
de scratchpad (equivalente a path3/GIF direto), envelopada por um par de funções que fazem o
papel de "PreDraw/Draw" — que **não existem com esse nome** no jogo.

Evidência (decompilação read-only, `SLUS_213.55`, endereços retail):

1. **Boot único** (`FUN_005a87a8` ← `FUN_004bd3e0@0x4bd3e0`) chama `FUN_00528ca0@0x528ca0`
   (init de GS/DMA, caller único), que roda **uma vez**: `sceGsResetGraph@0x544de8` →
   `sceDmaReset@0x546290` → `sceDmaPutEnv@0x546370` → **`sceGsSetDefDBuff@0x5453b0`** (monta os
   dois `DISPENV`/`DRAWENV` via `sceGsSetDefDispEnv`/`sceGsSetDefDrawEnv`/`sceGsSetDefClear`) →
   registra handlers de VBlank (`AddIntcHandler`) → `gfxPipeline::InitFade@0x527a90`.
   **Isso responde "double buffer via `sceGsSetDefDBuff`?" — sim, mas só uma vez no boot**, não
   por frame.
2. **Por frame**, o flip não chama `sceGsSetDefDBuff` de novo: `gfxPipeline::SubmitFrame@0x52a1b0`
   chama `gfxPipeline::gfxGsPutDispEnv@0x529bd0`, que escreve **direto** nos registradores
   privilegiados do GS (`PMODE`, `SMODE2`, `DISPFB1/2`, `DISPLAY1/2`, `BGCOLOR`) — sem VIF, sem
   GIF, sem VU1. Isso bate com o runtime: `PS2Memory::writeIORegister` incrementa `gsWriteCount`
   exatamente para escritas de MMIO nesses registradores privilegiados
   (`ps2_memory.cpp:678-702`), separado do caminho de pacote GIF.
3. **Wrappers de frame**: `ageBeginDraw@0x52d710` → `gfxPipeline::BeginFrame@0x5295f0` (+
   `gfxPipeline::Clear@0x52a400` opcional); `ageEndDraw@0x52d7c0` → HUD de debug opcional →
   `gfxPipeline::EndFrame@0x529f90` → `SubmitFrame`. Chamados de dentro de um dispatcher de
   estado (`FUN_001a23a8@0x1a23a8`, sem nome correlacionado no port) que **também chama
   `mcGame::PreUpdate@0x1a28a8` e `mcGame::PostUpdate@0x1a2938`** lado a lado com
   `ageBeginDraw`/`ageEndDraw`. `BeginFrame`/`EndFrame`/`SubmitFrame` **não chamam**
   `gfxGeometry`, `RenderVIF1Packets_RefDMA` nem `lowPsxGfx::DoMicrocode` — só mexem em
   semáforos, alarme de vsync, viewport, cache flush e nos registradores GS.
4. **Path 2D (menu/HUD/texto)**: `gfxPipeline::Blit2D@0x52ad20`/`0x52afb8` e
   `gfxPipeline::BlitText@0x52b1f0` montam o pacote **direto** num ring buffer compartilhado em
   scratchpad EE (`DAT_700005ac`, faixa `0x70000000`+) com uma GIFtag fixa de sprite
   (`0x1003400600000001`), **sem `gfxGeometry::AddPacket`, sem `RenderVIF1Packets_RefDMA`, sem
   `DoMicrocode`**. Ou seja: **um frame mínimo de menu (`BeginFrame`→`Blit2D`/`BlitText`→
   `EndFrame`) não força VU1** — é GIF direto a partir de scratchpad.
5. **Path 3D (geometria)**, só entra quando há geometria real (carros/pista/partículas):
   `gfxGeometry::BeginPackets@0x1edb38` → `AddPacket@0x1eeae0` → `EndPackets@0x1eec30` e
   `RenderVIF1Packets_RefDMA@0x1c7fa8` constroem tags DMA modo `REF` (id=3) apontando pra
   buffers VIF1 pré-montados — **esse** é o caminho que depende de VU1 via `DoMicrocode`.

**Cruzamento com o runtime**: o mecanismo "GIFtag pré-montado em scratchpad, DMA'd via path3"
já é suportado hoje — `PS2Memory::processPendingTransfers` tem um branch dedicado
`p.fromScratchpad` que lê de `m_scratchpad` e chama `submitGifPacket(GifPathId::Path3, ...)`
(`ps2_memory.cpp:1111-1119`). Isto é, o mecanismo exato que o path 2D do menu usa já tem
correspondente no lado runtime — não é um gap de M4 para o menu, é só nunca ter sido exercitado
porque o jogo não chega lá.

**mcGame::PreDraw / mcGame::Draw**: confirmado (`grep -i` nas 8816 linhas do CSV) que **não
existem**. A dupla real é `gfxPipeline::BeginFrame@0x5295f0`/`EndFrame@0x529f90`, envelopada por
`ageBeginDraw@0x52d710`/`ageEndDraw@0x52d7c0`.

---

## Pergunta 2 — tabela de gaps por elo

| Elo | Arquivo(s) auditado(s) | Status | Motivo |
|---|---|---|---|
| DMAC ch1 (VIF1)/ch2 (GIF) — submissão | `Kernel/Stubs/DMA.cpp` | ⚠️ | `sceDmaSend/SendI/SendM/SendN` (linhas 202-220) e `sceDmaSync/SyncN` (222-230) **implementados de verdade** (escrevem CHCR/MADR/QWC/TADR reais via `PS2Memory::writeIORegister`, que dispara processamento de chain real). `sceDmaReset`/`GetEnv`/`PutEnv`/`PutStallAddr`/`GetChan` também implementados. TODO puro: `sceDmaCallback`(44), `sceDmaDebug`(49), `sceDmaLastSyncTime`(72), `sceDmaPause`(77), `sceDmaRecv/RecvI/RecvN`(160/165/170), `sceDmaRestart`(199), `sceDmaWatch`(234) — nenhum desses está no caminho crítico de M4 (são callback/debug/pause, não usados pelo `RenderVIF1Packets_RefDMA` da Pergunta 1). |
| DMAC — processamento de chain/tags | `ps2_memory.cpp` (fora do escopo pedido, mas é quem de fato move os bytes) | ✅ | `processPendingTransfers`/`enqueueTransfer` decodificam tags DMA (REF/CNT/scratchpad) e alimentam VIF1/GIF; `gifCopyCount`/`vifWriteCount`/`dmaStartCount` só incrementam com tráfego real (`ps2_memory.cpp:826,1095,1116,1127,746,808`). |
| VIF1 comandos | `ps2_vif1_interpreter.cpp` (575 linhas) | ✅ | **Todos** os opcodes do escopo pedido implementados: NOP/STCYCL/OFFSET/BASE/ITOP/STMOD/MSKPATH3/MARK (141-189), FLUSHE/FLUSH/FLUSHA como no-op correto (190-193, sem timing a modelar), **MSCAL/MSCALF/MSCNT chamam de verdade os callbacks para o VU1** (194-230), STMASK/STROW/STCOL (231-256), **MPG copia microcódigo real pra `m_vu1Code`** com a regra NUM==0→256 instruções (257-276), **DIRECT/DIRECTHL entregam pacote pro GIF Path2** com suporte a imagem contínua entre chamadas (277-311, 83-112), **UNPACK completo** com todos os formatos (V4-32/16/8, V3-*, V2-*, V1-*, V4-5), masking por STMASK, row/col fill, modo add/write (312-569). Nenhum TODO/stub encontrado no arquivo. |
| VU1 — execução de microcódigo | `ps2_vu1.cpp` (1278 linhas) + `include/runtime/ps2_vu1.h` | ⚠️ | Decode completo de upper (FMAC: ADD/SUB/MUL/MADD/MSUB/MAX/MIN em todas as variantes bc/q/i, ITOF0/4/12/15, FTOI0/4/12/15, CLIP, ABS, MULA, OPMULA — linhas 169-624) e lower (LQ/SQ/ILW/ISW/IADDIU/ISUBIU, FCEQ/SET/AND/OR, FSEQ/SET/AND/OR, FMAND/EQ/OR, branches B/BAL/JR/JALR/IB*, IADD/ISUB/IADDI/IAND/IOR, MOVE/MR32/MFIR/MTIR/RNEXT/RGET/RINIT, LQI/SQI/LQD/SQD, DIV/SQRT/RSQRT — linhas 644-930). **XGKICK real** (1159-1258): decodifica a cadeia de GIFtags na VU mem e entrega pro `GifArbiter` via `PS2Memory::submitGifPacket(Path1,...)`. XTOP/XITOP implementados (1259-1270). **Gaps concretos**: EFU `ESADD`(1121)/`ERSADD`(1123)/`WAITQ`(1119)/`WAITP`(1145)/`EATAN`(1147) são **no-op silencioso** (`return;` sem tocar `p`/`q`); `EEXP`/`ESIN`/`ECOS`/`ESUM` **nem têm case label** — caem no `default: return;` (1155); `ELENG`/`ERCPR`/`ERLENG`/`MFP`/`DIV`/`SQRT`/`RSQRT` são reais. **Flags MAC nunca são calculadas** — `m_state.mac` só é *lido* (linhas 807/815/823 via FMAND/FMEQ/FMOR), nunca escrito por nenhuma instrução aritmética — logo `FMAND`/`FMEQ`/`FMOR` sempre operam sobre `mac=0`. Sem modelagem de pipeline (Q/P são escritos "instantâneos", não com a latência real do hardware) — aceitável para não-cycle-accurate, mas é uma simplificação, não um TODO documentado no código. |
| VU0 (macro mode, chamado da EE, não é o VU1 do render) | `Kernel/Stubs/VU.cpp` (584 linhas) | ⚠️ | ~19 de 40 funções `sceVu0*` são `TODO_NAMED` puro (ex.: `sceVu0MulMatrix`(354), `sceVu0RotMatrix`(407), `sceVu0ClipAll`(160), `sceVu0InversMatrix`(293), `sceVu0RotTransPers`(475/480), `sceVu0ViewScreenMatrix`(582), `sceVu0ecossin`(9)). As implementadas (`AddVector`, `SubVector`, `ApplyMatrix`, `CopyMatrix/Vector`, `Normalize`, `OuterProduct`, `InnerProduct`, `ITOF*/FTOI*Vector`, `RotMatrixX/Y/Z`, `TransposeMatrix`, `UnitMatrix`) fazem cálculo real, não são casca. **Importante**: isto é a biblioteca utilitária de VU0 macro-mode chamada pela EE (não é o interpretador VU1 nem faz parte do caminho DMA→VIF1→VU1→GIF) — impacta lógica de jogo (física, câmera) que pode chamar essas funções, não o desenho em si. Prioridade menor que os itens acima para M4/M5. |
| GIF paths 1/2/3 (arbitragem) | `ps2_gif_arbiter.cpp` (132 linhas) + `.h` | ✅ | `submit()`/`drain()` implementados com a regra real de prioridade (Path1 > Path2 > Path3, exceto "DIRECTHL não pode preemptar PATH3 IMAGE" — comentário e `stable_sort` em 84-96); detecta pacote de imagem por `flg==2` (34-43); **ligado de ponta a ponta** em `ps2_runtime.cpp:665-667` a `GS::processGIFPacket`. Sem TODO. |
| GS — registradores privilegiados/contexto | `ps2_gs_gpu.cpp` (2336 linhas) + `.h` (323 linhas) | ✅ | `processGIFPacket` decodifica GIFtag **PACKED/REGLIST/IMAGE** completos (1109-1211, com PRE-bit setando PRIM automaticamente). `writeRegister`/`writeRegisterPacked` cobrem **todos** os registradores do enum `GSRegId` do escopo (PRIM, RGBAQ, ST, UV, XYZF2/3, XYZ2/3, TEX0×2, CLAMP×2, FOG, TEX1/TEX2×2, XYOFFSET×2, PRMODECONT/PRMODE, TEXCLUT, SCISSOR×2, ALPHA×2, TEST×2, FRAME×2, ZBUF×2, FBA×2, BITBLTBUF/TRXPOS/TRXREG/TRXDIR/HWREG, PABE, TEXFLUSH, SCANMSK, FOGCOL, DIMX, DTHE, COLCLAMP, MIPTBP1/2×2, TEXA, SIGNAL/FINISH/LABEL — linhas 1472-1780). `vertexKick` (1925-2003) implementa os **7 tipos de primitiva** (POINT/LINE/LINESTRIP/TRIANGLE/TRISTRIP/TRIFAN/SPRITE) com a regra correta XYZ2-dispara-desenho vs XYZ3-só-enfileira (1530, 1550), e chama o rasterizador real. Zero TODO/FIXME no arquivo. |
| GS — rasterização | `ps2_gs_rasterizer.cpp` (1048 linhas) + `.h` | ⚠️ | `drawPrimitive`/`drawSprite`/`drawTriangle`/`drawLine`/`writePixel` (248-1048) são um **rasterizador de software real**: scissor test (393-395), alpha test com todos os `ATST` (95-121), alpha blending com seletores A/B/C/D e `FIX` e regra `PABE` (465-514), `FBMSK` (516, 527-531, 539-544), correção `FBA` (517-522), texturing com `TFX`/CLUT/`TEXA` color-key para CT32/CT16/T4/T8 (556-... , `applyTexa` 36-64), decode/encode PSMCT16/32 e endereçamento de VRAM via `ps2_gs_psmct16.h`/`psmct32.h`/`psmt4.h`/`psmt8.h`. **Gap concreto e real**: **não há Z-test nem Z-write em lugar nenhum do arquivo** (`grep` por `ztst`/`zbuf`/depth não encontra nada em `writePixel`; `ctx.zbuf` — presente na struct `GSContext` — nunca é lido pelo rasterizador). Qualquer cena 3D com geometria sobreposta desenha em ordem de submissão (sem profundidade), não em ordem de profundidade — bug visual esperado em qualquer coisa além de UI plana. |
| `Kernel/Stubs/GS.cpp` (SDK sce*) | `Kernel/Stubs/GS.cpp` (1898 linhas) | ✅ | 46 funções (`sceGifPk*`, `sceGs*`, `sceVif1Pk*`), **zero `TODO_NAMED`**. `sceGsSetDefDBuff` (1270-1327) monta a struct `GsDBuffMem` real (PMODE/SMODE2/DISPFB/DISPLAY/GIFtag/DRAWENV com Z) e escreve na memória guest — bate com a chamada real do jogo em `0x5453b0` (Pergunta 1). `sceGsResetGraph`, `sceGsSetDefDispEnv/DrawEnv/DrawEnv2/Clear`, `sceGsSyncV/SyncPath`, `sceGszbufaddr`, `sceGsSwapDBuff(Dc)`, `sceGifPkOpenGifTag/AddGsAD/AddGsData/CloseGifTag/Ref/RefLoadImage`, `sceVif1PkOpenGifTag/OpenDirectCode/CloseDirectCode/Call/...` todos implementados. |

Legenda rápida: ✅ = implementado e ligado ao resto da cadeia; ⚠️ = maioria implementada, gap
nomeado e localizado; ❌ = ausente. **Nenhum item do escopo pedido caiu em ❌** — o pior caso
encontrado é "parcial com gap preciso" (Z-test do rasterizador, EFU do VU1, ~metade dos
utilitários `sceVu0*`).

---

## Pergunta 3 — microprogramas VU1 no boot

**Achado**: não existe um "microprograma de menu" separado. O que o boot registra (via
`FUN_003b5c78@0x3b5c78` ← `FUN_003b2f80@0x3b2f80`, guardado por flag de execução única
`DAT_00618958`) são **12 microprogramas de shader de pintura/luz de carro**, via
`rmcShader::AddMicrocode@0x2aeac0`:

| nome | endereço do blob | tamanho aprox. (qwords) |
|---|---|---|
| noise_pointlight_dc | 0x5F8ED0 | 770 |
| noise_cn_pointlight_dc | 0x5F5DA0 | 786 |
| noise_cn_lighttexgen_dc | 0x5F2D10 | 776 |
| carpaint_3pass_dc | 0x604640 | 587 |
| cpv_distort_vtx_dc | 0x609860 | 770 |
| city_reflect_ci | 0x606B00 | 725 |
| skinned_fresnel | 0x5FBF00 | 528 |
| texgen_fresnel_dc | 0x600210 | 519 |
| light_texgen_dc | 0x60E9A0 | 523 |
| distort_dc | 0x60C890 | 528 |
| carbon_fiber_dc | 0x602290 | 570 |
| specular2_dc | 0x5FE010 | 543 |

Os 12 blobs **compartilham o mesmo prólogo binário** (primeiras dezenas de bytes idênticas
entre si, incluindo um byte `0x4A` no offset consistente com o opcode VIFcode **MPG**) —
provavelmente derivados de um template comum de shader de carro, não 12 programas
independentes. **Ressalva do agente que decompilou**: não foi feito decode instrução-a-
instrução dos 12 blobs (fora do escopo desta tarefa); a classificação é por nome/prólogo, não
por leitura de opcode.

**O interpretador VU1 atual executaria eles?** Parcialmente, com risco concentrado num ponto:
os nomes (`fresnel`, `distort`, `noise_*`, `specular2`) são exatamente o tipo de shader que
tende a usar `ERCPR`/`ELENG`/`ERLENG` (recíproco/comprimento — **implementados**, ver Pergunta
2) mas também, dependendo do algoritmo de fresnel/specular usado, pode chamar `EEXP` (curva
exponencial de specular) ou `ESIN`/`ECOS` (ondulação de `noise_*`) — **essas quatro não têm
case label no interpretador e caem em no-op silencioso** (`ps2_vu1.cpp:1155`), o que produziria
resultado visual errado (não um crash) se o microprograma realmente as usar. Sem decodificar os
12 blobs instrução a instrução não dá pra confirmar se usam essas 4 EFU ou só as já
implementadas — **isso é a próxima pergunta concreta a responder antes de gastar esforço em
VU1**, não uma suposição a resolver aqui (regra do projeto: decomp nomeado ou captura, não
chute).

O consumo real do upload acontece em `lowPsxGfx::DoMicrocode@0x526d08` (recebe
`begin`/`end`/`callback`, monta uma tag DMA REF sobre o range do pacote VIF/GIF pré-montado com
`MPG` embutido) — tem dezenas de callers espalhados por gameplay/partículas/HUD 3D/carros, ou
seja, é a rotina genérica de troca de contexto VU1, não uma chamada única de boot.

---

## Pergunta 4 — esforço por gap (S/M/L) e ordem de ataque

Pressuposto: esta estimativa vale **depois** que M2/M3 destravarem o jogo até o ponto em que ele
de fato programa o canal DMA2/GIF pela primeira vez — nenhum gap abaixo pode ser validado com
tráfego real antes disso.

| Gap | Tamanho | Por quê | Ordem |
|---|---|---|---|
| Validar path 2D do menu contra tráfego real (`Blit2D`/`BlitText` → scratchpad → Path3) | **S** | Mecanismo já existe nos dois lados (jogo e runtime, ver Pergunta 1); é validação/depuração de offset e formato de GIFtag contra o primeiro `gif>0` real, não código novo. | **1º** — é o candidato mais provável a produzir o primeiro pixel real (não depende de VU1). |
| Z-test/Z-write no rasterizador (`ps2_gs_rasterizer.cpp`) | **M** | `ctx.zbuf` já existe na struct e o endereçamento de VRAM para outros PSM já está resolvido (`ps2_gs_psmct16/32.h`) — é "ligar mais um teste igual ao alpha test", não inventar infraestrutura. Só passa a importar quando geometria 3D sobreposta aparecer (depois do menu). | 3º |
| EFU faltantes no VU1 (`EEXP`/`ESIN`/`ECOS`/`ESUM`) + flags MAC nunca computadas | **M** | Isolado (switch/case novo em `execLower`, `ps2_vu1.cpp` em torno da linha 1155) mas exige a referência de hardware (`VU_Users_Manual`/`vu-instruction-manual` em `PS2-Programming-Docs\`) para as fórmulas de aproximação corretas — e só vale a pena depois de decodificar os 12 blobs de carpaint (Pergunta 3) pra confirmar que são usadas. | 4º — depende de decodificar os blobs primeiro (ver abaixo). |
| Decodificar instrução-a-instrução os 12 microprogramas de carpaint/shader | **S** | É leitura (mesmo script `ExportSceDecomp.java`-like, ou um disassembler VU1 simples sobre os blobs já localizados) — não é código de runtime, é descobrir se o gap acima (EFU) realmente bloqueia algo visível. | 2º — barato e decide se o item EFU vale a pena. |
| Completar `sceDma*` fora do caminho crítico (`Callback`/`Debug`/`Pause`/`Recv*`/`Restart`/`Watch`) | **S** cada | Nenhum é usado pelo caminho de render identificado na Pergunta 1; só vale se algum bloqueio futuro citar um deles nominalmente. | sob demanda |
| Completar `sceVu0*` faltantes (~19 funções) | **M** no total, **S** cada | Não é o caminho de render (é VU0 macro-mode chamado da EE para física/câmera/animação) — só priorizar se um gate de gameplay citar uma delas nominalmente. | sob demanda, fora do escopo M4/M5 |
| `resolveDmaChannelBase`/chain DMA em geral | — | Já ✅, sem ação necessária. | — |

**Honestidade da régua**: a "segunda montanha" descrita em `docs/CAMINHO_ATE_O_FRAME.md` **não é
maior que o projeto até aqui** — é bem menor do que o texto atual sugere. O trabalho real
restante depois de M2/M3 é validação dirigida por tráfego real (que gap aparece primeiro no
trace) mais dois itens pontuais e bem localizados (Z-test, EFU do VU1) — não uma reescrita do
subsistema gráfico. Recomendação: **atualizar `docs/CAMINHO_ATE_O_FRAME.md`** para refletir que
M4/M5 têm runtime funcionalmente ligado, não "peças nunca exercitadas" — isso muda a expectativa
de esforço passada para quem entra no projeto depois.

---

## Metodologia e limitações

- Três frentes paralelas, só leitura: (A) `ps2_vif1_interpreter.cpp`/`ps2_vu1.cpp`/
  `Kernel/Stubs/DMA.cpp`/`Kernel/Stubs/VU.cpp`; (B) `ps2_gif_arbiter.cpp`/`ps2_gs_gpu.cpp`/
  `ps2_gs_rasterizer.cpp`/`Kernel/Stubs/GS.cpp`; (C) decomp/Ghidra do lado jogo. As frentes A e B
  foram disparadas como sub-agentes em background; após ~10 minutos sem retorno (limiar definido
  pelo coordenador desta sessão), o próprio orquestrador refez a leitura direta de A e B —
  **as evidências de A/B citadas acima vêm de leitura direta arquivo:linha**, não de relatório de
  sub-agente. A frente C (Ghidra) completou via sub-agente e suas evidências (endereços
  retail/nomes) foram cruzadas com o CSV e com o comportamento do runtime.
- Ghidra headless rodou 3x com `-noanalysis` (sem re-análise, projeto não fica travado/alterado),
  scripts extras de decompilação ficaram fora do repo (pasta de scratch da sessão), não foram
  commitados — só o `.txt` de saída foi usado como evidência textual, descartado depois de citado
  aqui.
- Não foi possível (fora do escopo pedido) decodificar instrução-a-instrução os 12 blobs de
  microcódigo VU1 do boot — ver Pergunta 3, marcado como próximo passo barato (S).
- Toda afirmação sobre o runtime tem arquivo:linha citado acima; toda afirmação sobre o jogo tem
  endereço/nome citado. Onde não foi possível confirmar (ex.: se os 12 blobs usam EFU), isso está
  marcado explicitamente como incerto — não foi inventado.

## Commits

Só este relatório, no repo principal, branch `mc3`, sem push (coordenador revisa e sobe).
