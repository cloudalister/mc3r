# mc3r

Recompilação estática de Midnight Club 3: DUB Edition Remix (PS2, SLUS_213.55) para PC, usando um fork do [PS2Recomp](https://github.com/cloudalister/PS2Recomp).

Este repo não contém ISO, assets, nem código gerado a partir do binário do jogo. Os scripts esperam sua própria cópia do jogo na raiz do checkout.

- `PS2_PROJECT_STATE.md` — log de checkpoints (ler os últimos primeiro)
- `docs/PLANO_2026-08-17_ALPHA_SYMBOLS.md` — plano atual
- `ROADMAP.md` — roadmap de automação
- `NN_*.bat` + `tools/` — pipeline (extração → export ghidra → recomp → compile → link → boot probe)

Estado: ainda não renderiza nada. O boot trava na camada SIF/IOP; o plano atual ataca isso com os símbolos do protótipo de outubro/2004.
