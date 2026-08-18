# Workflow do projeto (como operar — humano e IA)

## O loop (1 passo = 1 ciclo completo)

```
STATUS.md (ler)
  → handoff (docs/TEMPLATE_HANDOFF.md)
    → 1 agente executor (Sonnet), poll ativo, commits locais
      → RESULT doc honesto
        → revisão do coordenador (diff: chaves proibidas, env-gates, time-deps)
          → push (fork + mc3r)
            → STATUS.md sobrescrito + checkpoint em PS2_PROJECT_STATE.md
```

Papéis: **coordenador** (pensa, escreve handoff, revisa, decide, atualiza STATUS) e
**executor** (implementa dentro do contrato). Um agente por handoff. Handoffs paralelos só
quando não disputam os mesmos arquivos nem a mesma medição (probe compete por CPU — nunca
medir durante build).

## Economia de tokens (camadas de execução)

- **Fable (coordenador)**: só pensa/revisa/decide — nunca executa tarefa longa.
- **Sonnet**: handoffs que mudam código. É onde vale gastar.
- **Haiku**: mecânica pura — rodar build/relink/probe, filtrar log em arquivo, grep — quando o
  handoff é só executar e coletar, sem julgamento.
- **Gemini CLI** (`gemini -p "..."`, cota Google, zero token Claude): leitura em massa e
  investigação exploratória — resumir decomp por função, varrer manuais, "onde olhar".
  **Regra dura**: saída do Gemini vai para arquivo e é tratada como pista não-verificada;
  nada vira código sem confirmação barata (grep/leitura pontual). Histórico: bom em
  investigação (relink 28/07), mas já produziu doc-drift (auditoria 14/07, nota 6.5).
- Handoffs devem entregar ao executor **insumos pré-filtrados** (trecho de decomp por função,
  trace filtrado em arquivo) em vez de mandar ler arquivos inteiros; polls de espera a
  90-120s; RESULT doc é o único artefato que o coordenador lê inteiro.

## Hierarquia de documentos (quem manda em quem)

1. **`STATUS.md`** — o presente. Uma página, sobrescrita a cada ciclo. Única porta de entrada.
2. **`docs/CAMINHO_ATE_O_FRAME.md`** — a régua M0-M6. Atualizar o marco quando mudar.
3. **Docs de fato** (`SIF_PROTOCOL.md`, `SYMBOL_PORT_REPORT.md`, design docs) — atualizáveis,
   sempre corrigidos no lugar (nunca "ver correção no doc Y").
4. **`RESULT_*.md`** — imutáveis depois de fechados (são evidência histórica).
5. **`PS2_PROJECT_STATE.md`** — changelog append-only. NÃO é porta de entrada; serve para
   auditoria ("quando descobrimos X?").

Regra anti-entropia: antes de criar doc novo, perguntar "isso é fato, resultado, handoff ou
status?" e colocar no lugar certo. Doc de investigação que virou obsoleto (pré-símbolos)
não se apaga — ganha uma linha no topo: `> Obsoleto desde 17/08 (símbolos). Ver X.`

## Medição (inegociável)

- `MC3_DETERMINISTIC=1` + `MC3_DISPATCH_BUDGET=25000` em toda medição.
- 1 corrida com trace = prova. `21_probe_repeat 3` = confirmação final de um passo.
- Nunca comparar corridas feitas com binários diferentes sem dizer o commit de cada um.
- Exe relinkado tem que ser mais novo que a lib (checar timestamp — incidente de 09-13/08).

## Git

- Executor: commits locais pequenos, mensagem simples em uma linha, sem push.
- Coordenador: revisa diff → push fork (`mc3`) e mc3r (`main`) juntos → checkpoint.
- Nada do jogo no repo público (ISO, assets, MC.MAP/SYM, código gerado do ELF, decomp).

## Quando algo dá errado

- Resultado negativo é entregável: RESULT doc com a cadeia do bloqueio e evidência.
- Suspeita de bug em camada congelada (scheduler, dispatcher aceito): reportar no RESULT,
  nunca remendar dentro de outro handoff.
- Medição estranha: primeiro reconferir binário/env (stale?), depois desconfiar do código.
