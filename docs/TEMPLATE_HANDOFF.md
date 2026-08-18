# Template de handoff (o formato que funcionou em 17/08 — usar sempre)

Um handoff é um contrato: escopo cercado, fontes de verdade, aceite mensurável. Os três
passos da Fase 1 e a Fase 2 saíram deste formato em um dia; os 2 meses anteriores, sem ele,
não saíram do lugar. Copiar a estrutura abaixo para `docs/HANDOFF_<FASE>_<NOME>.md`.

---

# Handoff — <título curto do objetivo>

## Contexto mínimo
2-5 linhas: o que mudou desde o último passo e por que este é o próximo. Links só para o que
o executor VAI abrir (regra: ≤5 leituras obrigatórias).

## Escopo
O que fazer — e, tão importante, **o que explicitamente NÃO fazer** nesta tarefa.

## Fontes de verdade (em ordem)
1. decomp nomeado / symbol port (fatos do jogo)
2. trace real da sessão (fatos do runtime)
3. referência externa (ps2sdk/PCSX2) só como cruzamento
Proibido inventar o que não estiver em 1-3.

## Regras não-negociáveis
Repetir as 5 de `STATUS.md` + as específicas da tarefa. Repetição é proposital: o executor
não tem o histórico na cabeça.

## Validação
Passo a passo com comandos exatos e ambiente (`STATUS.md` → seção Ambiente). SEMPRE terminar
com: **1 corrida determinística = prova; probe 3x = confirmação final.**

## Aceite
Uma frase binária, mensurável no trace/probe. Ex.: "Stable PC determinístico sai de X" —
nunca "melhorar", "avançar", "investigar".

## Critérios de parada
- vitória do passo (o aceite)
- vitória maior inesperada (ex.: gif>0) → parar tudo e documentar estado exato
- timebox/limite de tentativas → parar e documentar a cadeia do bloqueio (também é entregável)

## Entregáveis
Commits locais no fork branch `mc3` (sem push — o coordenador revisa e sobe) +
`docs/RESULT_<NOME>.md` honesto (inclusive negativo): o que fez, evidência antes/depois,
pendências.

---

## Esqueleto do prompt do agente executor (lições aprendidas)

Incluir SEMPRE no prompt, além do link do handoff:

1. "Execute docs/HANDOFF_X.md do início ao fim — leia primeiro."
2. Bloco de ambiente de build copiado do STATUS.md (evita redescoberta).
3. **"Trabalhe de forma contínua com poll ativo — NUNCA pause 'esperando notificação'; em
   toda espera longa (build/relink/probe) rode loop de checagem a cada ~60s até terminar."**
   (Sem isso o agente para no meio — aconteceu 3x em 17/08.)
4. Relink: timeout ≥6 min (o link leva ~3; timeout curto matou o binário em 09/08).
5. Suíte roda com CWD = `PS2Recomp\out\build` (paths relativos dos testes).
6. "Ao final me retorne: <lista exata dos itens do relatório>" — o agente reporta o que se
   pede, não o que acha relevante.
