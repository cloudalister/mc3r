# Handoff — passo 13: a divergência na profundidade nova (Fase 2b)

## Autorização

Este handoff É o "dono do scheduler": `DeterministicScheduler.cpp` e a fiação de VBlank/INTC
dos passos 4-5 estão no escopo. A regra "sem tempo de host no caminho determinístico"
continua absoluta.

## Contexto mínimo

Passo 12 (`docs/RESULT_SEMA_CONTRACT_V1.md`): o fix do contrato de semáforos (correto,
provado) foi revertido porque, com o boot alcançando profundidade nova, o probe deu 10/10
válidas mas **2 Stable PCs** (`0x548e70`×6, `0x245720`×4). Nenhuma linha do scheduler foi
tocada — a corrida é latente, exposta agora. Sem resolver isso, nenhum progresso futuro é
mensurável (voltamos ao problema pré-Fase 2, uma camada mais fundo).

## Suspeitos priorizados (do coordenador, verificar em ordem)

1. **Fiação VBlank/INTC dos passos 4-5**: `latchIntcStatBit` (INTC_STAT) e
   `toggleGsFieldBit` (CSR.FIELD) — são acionados de onde? Se qualquer um deles roda a partir
   de uma thread/host-tick fora do tick determinístico (`runOneVBlankTick`), a fase do VBlank
   relativa ao progresso guest varia por corrida → threads acordam em ordens diferentes.
   O RESULT do passo 4 menciona "corrida entre a thread do VBlank e a guest" — isso sugere
   que existe uma thread de VBlank host. Em modo determinístico ela deveria estar subordinada
   ao tick do scheduler, não ao relógio.
2. Pontos de troca novos alcançados pelo boot profundo que não estão na lista de yields
   determinísticos da Fase 2 (`docs/FASE2_SCHEDULER_DESIGN.md`).
3. Ordem de fila com prioridades iguais na região nova.

## Método

1. **Reaplicar localmente o fix dos semáforos** (está no RESULT do passo 12; ele é
   pré-requisito para alcançar a região — não commitá-lo como final até o aceite).
2. Capturar 2 corridas completas com trace de eventos do scheduler (handoffs, wakes, VBlank
   ticks, sema ops — habilitar/estender o trace determinístico se preciso): uma que termina
   em `0x548e70`, outra em `0x245720` (rodar até obter uma de cada).
3. **Diff evento-a-evento**: primeiro ponto onde as sequências divergem = a corrida. Analisar
   o que decidiu diferente (ordem de wake? fase de VBlank? iteração de mapa não-ordenado?).
4. Corrigir deterministicamente (subordinar ao tick/contagem; ordenar por (prioridade, ordem
   de criação); nunca relógio).
5. Aceite: `21_probe_repeat.bat 10 probe fase2b_v1` → **1 Stable PC, 10/10 válidas**, com o
   fix dos semáforos aplicado. Aí sim: commitar AMBOS (fix da divergência + fix dos semáforos
   + remoção da flag `MC3_SEMA_EXPERIMENT_POLL_RETURNS_SID`), suíte completa, e seguir o gate
   (M4 = parar, confirmar 3x, reportar).

## Aceite

1 Stable PC em 10/10 com o contrato de semáforos correto aplicado e permanente.

## Regras

As do `STATUS.md`/`WORKFLOW.md`. PATH MSYS2; `.o` afetados; relink ≥6 min; CPU limpa durante
probes (lição do passo 12: um grep órfão contaminou uma batelada); commits locais sem push;
resultado em `docs/RESULT_FASE2B_DIVERGENCE_V1.md`.
