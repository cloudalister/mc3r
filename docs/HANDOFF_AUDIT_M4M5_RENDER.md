# Handoff — auditoria de prontidão M4-M5 (caminho de render), SÓ LEITURA

## Contexto mínimo

A escada do projeto está em `docs/CAMINHO_ATE_O_FRAME.md`. M1-M2 estão em curso em outro
handoff. Este handoff mede **antecipadamente** o tamanho da segunda montanha: o que falta no
runtime para M4 (tráfego DMA→VIF1→VU1→GIF) e M5 (GS rasteriza framebuffer). Nenhuma linha de
código é alterada aqui — o entregável é um relatório de gaps.

## Escopo

- LER (runtime, fork `PS2Recomp`): `ps2_vif1_interpreter.cpp`, `ps2_vu1.cpp`,
  `ps2_gif_arbiter.cpp`, `ps2_gs_gpu.cpp`, `ps2_gs_rasterizer.cpp`, `Kernel/Stubs/GS.cpp`,
  `Kernel/Stubs/DMA.cpp`, `Kernel/Stubs/VU.cpp` — para cada um: o que está implementado de
  verdade, o que é stub/TODO, o que nunca é chamado por ninguém (grep de callsites).
- LER (lado jogo, nomeado): decomp/disasm de `mcGame::PreDraw`, `mcGame::Draw` (se existir),
  e as funções `sceGs*`/`sceDma*`/`sceVif*` que eles chamam (regenerar decomp com
  `tools/ghidra/ExportSceDecomp.java` ampliando o filtro de prefixos se precisar — só leitura
  do projeto Ghidra `work/mc2recomp`, programa `SLUS_123.45`; ambiente no `STATUS.md`).
- Referência de hardware quando necessário: `PS2-Programming-Docs\` (VU_Users_Manual,
  vu-instruction-manual, GS_Users_Manual, EE_Users_Manual cap. DMAC/VIF).
- NÃO fazer: mudanças de código, builds, relinks, probes (outro handoff está medindo — CPU de
  medição é dele).

## Perguntas que o relatório responde

1. Qual é o caminho mínimo que o MC3 usa para desenhar o primeiro frame de menu/loading?
   (double buffer via `sceGsSetDefDBuff`? path3 direto? VU1 micro obrigatório já no menu?)
2. Para cada elo (DMAC ch1/ch2, VIF1 cmds, VU1 micro, GIF paths 1/2/3, GS regs/prims), o
   runtime: implementa ✅ / parcial ⚠️ (o que falta) / ausente ❌?
3. Quais microprogramas VU1 o jogo sobe no boot (VIF MPG) e o interpretador VU1 atual
   executaria eles? (amostrar os primeiros; instruções não suportadas = listar)
4. Estimativa de esforço por gap (S/M/L) e a ordem de ataque sugerida quando M2 fechar.

## Aceite

`docs/AUDIT_M4M5_RENDER.md` respondendo as 4 perguntas com evidência (arquivo:linha para cada
afirmação sobre o runtime; endereço/nome para cada afirmação sobre o jogo). Honestidade da
régua: se a conclusão for "a segunda montanha é maior que o projeto até aqui", escrever isso.

## Regras

Só leitura; sem commits além do próprio relatório (repo principal, sem push — coordenador
revisa); ambiente/regras gerais em `STATUS.md`.
