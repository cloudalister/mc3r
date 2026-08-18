# Handoff — passo 5: por que o main loop não desenha? (rumo a gifPackets>0)

## Contexto mínimo

Passo 4 (`docs/RESULT_GSYNCV_METRICS_V1.md`): o freeze de vsync foi corrigido (latch de
`INTC_STAT`) e o boot agora **executa o ciclo real de vsync** (PC circula em
`0x545674`/`0x546e70`/`0x528fa8`). Régua nova ativa (`docs/RENDER_METRICS.md`):
`gifPk1/2/3`, `gsPrims`, `gsPixels` — todos **0**. O jogo vive, mas não desenha.

## Objetivo

Descobrir O QUE o main loop está fazendo/esperando entre vsyncs, e destravar até a régua nova
sair de zero (`gifPackets>0` E `gsPrims>0`) — ou até mapear com evidência o bloqueio que
impede isso.

## Método (investigar antes de mexer)

1. **Mapa do loop vivo** (1 corrida com trace + budget maior se precisar): a partir do PC
   circulante e do symbol port (`work/exports/retail_symbol_port.csv`), reconstituir o call
   path do ciclo: quem chama o vsync? `mcGame::Execute`/`ageBeginDraw`/`gfxPipeline::BeginFrame`
   estão rodando? Ou o loop é um estado de espera anterior (loading? intro? cutscene?)?
   Instrumentação permitida: contadores/trace determinísticos baratos (mesmo padrão dos
   passos anteriores), NUNCA mudança de semântica só para "ver".
2. **A auditoria diz onde olhar** (`docs/AUDIT_M4M5_RENDER.md`): o menu 2D desenha via
   `Blit2D`→GIFtag→PATH3. Se `gfxPipeline::BeginFrame` roda mas `gifPk3=0`, o bloqueio está
   entre o Blit e o DMA (canal 2) — checar se o jogo programa o canal e o runtime processa.
   Se `BeginFrame` nem roda, o bloqueio é estado de jogo (ex.: esperando FMV de intro,
   áudio SCREAM, pad, memory card, streaming de assets).
3. Candidatos prováveis de espera (pela ordem, com base no que ainda não tem handler):
   - **FMV de intro** (`sceMpeg*`/IPU — o jogo pode estar tentando tocar `MC3INTRO.PSS`);
     decomp de `sceMpeg*` já existe em `alpha_decomp_sce.txt`. Skip legítimo é aceitável SE
     o próprio jogo tiver caminho de skip (ex.: flag de "video done") — documentar qual.
   - **Áudio SCREAM/LGAUD** (servidores RPC ainda sem handler — `mcAudioRpcMgr` pode bloquear
     o estado de boot).
   - **Pad** (`scePad*` — o jogo pode esperar pad "estável" antes de avançar de estado).
   - Streaming de assets (`zipFile` lendo os `.DAT` via cdvd read fno=1 — o read implementado
     no passo 1 nunca foi exercitado; agora pode ser).
4. Para cada bloqueio confirmado: handler/resposta com evidência (decomp → semântica real),
   1 corrida = 1 prova, iterar. Mesma disciplina dos passos 1-4.

## Aceite

`gifPackets(total)>0` E `gsPrims>0` numa corrida determinística — o momento M4. Nesse caso:
PARAR, anotar commit/env/comando, rodar `21_probe_repeat.bat 3 probe m4_confirm` e reportar
imediatamente. Se após ~6 destravamentos a régua seguir zerada: parar e documentar a cadeia
com evidência.

## Regras

As do `STATUS.md`, sem exceção. Atenção específica: relink `fast` NÃO recompila `.cpp` gerados
(achado do passo 4) — se tocar em resposta que muda comportamento de função gerada, recompilar
os `.o` afetados explicitamente antes de relinkar e conferir timestamps. Commits locais sem
push; resultado em `docs/RESULT_MAINLOOP_DRAW_V1.md`.
