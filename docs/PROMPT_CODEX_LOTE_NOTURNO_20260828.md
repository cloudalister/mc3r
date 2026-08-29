# Prompt para colar no Codex (lote noturno 2026-08-28)

Copiar o bloco abaixo inteiro.

---

Execute `docs/HANDOFF_2026-08-28_LOTE_NOTURNO_VIF0.md` do início ao fim. Leia o
handoff primeiro, inteiro, antes de tocar em qualquer arquivo.

Você está operando **sozinho, sem supervisão humana**, de agora até 03:00 de
2026-08-28. Não existe ninguém para responder pergunta. Auto-planeje e
auto-aprove **apenas** dentro da seção "Envelope de autonomia" do handoff.
Qualquer coisa fora dele: pare, escreva no RESULT o que faria e por quê, e siga
para o encerramento.

Repo raiz: `E:\Games\Emuladores\Sony\mc3recomp`

Ambiente de build (não redescobrir):

```
toolchain:  C:\msys64\ucrt64\bin           (prefixar no PATH antes de compilar)
cmake:      C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe
build dir:  PS2Recomp\out\build
suíte:      PS2Recomp\out\build\ps2xTest\ps2x_tests.exe   (CWD = PS2Recomp\out\build)
build runtime:  work\scratch\build_runtime_watch.bat
relink:         10_link_partial_runner.bat fast      (timeout ≥ 6 min, sempre)
probe:          work\scratch\run_gfx_probe.bat 900 20260828_vif0 headless
```

Regras de execução:

1. **Poll ativo, sempre.** Em toda espera longa (build, relink, probe) rode loop
   de checagem a cada ~60 s até terminar. NUNCA pause "esperando notificação" —
   isso já travou agentes neste projeto três vezes.
2. **Relink com timeout ≥ 6 min.** Timeout curto já matou o binário aqui.
3. **Suíte roda com CWD = `PS2Recomp\out\build`** (os testes usam paths
   relativos).
4. **Os portões são de relógio, não de progresso.** Se um portão do cronograma
   estourar, abandone a fase e vá para o encerramento. Não estenda.
5. **Sem `git push`.** Commits locais apenas.
6. **Desligamento às 03:00 é inegociável**, mesmo com fase incompleta. Faça a
   checklist de 02:58, escreva o RESULT com o ponto exato de parada, e execute
   `Stop-Computer -Force`.

Ao final, antes de desligar, deixe escrito em
`docs/RESULT_VIF0_DMA_2026-08-28.md`:

1. O que foi implementado no canal DMA 0 (VIF0), com diff resumido.
2. Saída da suíte de testes (números exatos).
3. PC estável antes e depois (`0x3A01C8` é o antes).
4. Contadores de render antes e depois (`gifPk1`, `gifPk2`, `gsPrims`,
   `gsPixels`).
5. Todos os traces `[boot-trace:dmac-vif0]` coletados, com o conteúdo dos
   quadwords.
6. Se algum trace `mc3-gfx-*` disparou (hoje: nenhum).
7. Pendências explícitas: modo chain, interpretação de VIFcode, VU0.
8. Se falhou: a cadeia exata do bloqueio. Resultado negativo é entregável.
