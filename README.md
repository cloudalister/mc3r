# mc3r

Recompilação estática de Midnight Club 3: DUB Edition Remix (PS2, SLUS_213.55) para PC, usando um fork do [PS2Recomp](https://github.com/cloudalister/PS2Recomp).

Este repo não contém ISO, assets, nem código gerado a partir do binário do jogo. Os scripts esperam sua própria cópia do jogo na raiz do checkout.

- **`STATUS.md` — comece aqui** (estado atual, uma página, sempre atualizado)
- `docs/CAMINHO_ATE_O_FRAME.md` — a régua de progresso M0-M6 e por que ainda não há imagem
- `docs/WORKFLOW.md` — como o projeto opera; `docs/TEMPLATE_HANDOFF.md` — formato das tarefas
- `PS2_PROJECT_STATE.md` — changelog histórico (append-only)
- `NN_*.bat` + `tools/` — pipeline (extração → export ghidra → recomp → compile → link → boot probe)

Estado: boot determinístico desde 17/08 (para sempre no mesmo gate), serviços IOP respondendo um a um; ainda sem imagem — a distância real está medida na régua do `CAMINHO_ATE_O_FRAME.md`.
