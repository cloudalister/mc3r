# Handoff — passo 19: anatomia completa do laço `0x245720` (a segunda condição)

## Contexto mínimo

`docs/RESULT_FASE2D_RPC_TICK_V1.md`: medição sã (10/10, budget 100k), diskready=2 entregue
5x por corrida, boot toca `0x542230`/`0x5494e0` e retorna ao laço `0x245720`
(`sub_00245680`, `psxCdCache`). `sceCdRead` nunca dispara. Existe uma segunda condição no
laço que ninguém mapeou. Pistas históricas (checkpoint 28/07 no `PS2_PROJECT_STATE.md`):
o laço externo exige retorno `2` de `sub_005420C0(1)`; um laço interno em `label_245608`
chama `func_5424A8` esperando retorno `1` — e `0x5424A8` = **`sceCdSeek`** no symbol port.

## Objetivo

Mapear TODAS as condições de saída do laço `sub_00245680` com o decomp nomeado (o `.cpp`
gerado honesto + alpha decomp), identificar qual(is) não são satisfeitas hoje e por quê
(retorno errado? completion de seek nunca entregue? flag global?), e satisfazê-las pelo
caminho legítimo — até `sceCdRead` disparar ao vivo.

## Método

1. Anatomia estática (barato): ler `work/generated/ghidra/sub_00245680_0x245680.cpp` e
   `sub_005420C0_0x5420c0.cpp` honestos + `sceCdSeek`/`sceCdSync`/`sceCdNcmdDiskReady` no
   alpha decomp. Desenhar o fluxo: condição por condição, com endereço e o que cada uma
   testa (retornos, globais, semas). Registrar no RESULT antes de mexer em qualquer coisa.
2. Trace dirigido: instrumentação mínima (fresh-entry, nunca antes do switch de resume —
   armadilha documentada no passo 6) nos pontos de decisão do laço; 1 corrida; confrontar
   com a anatomia.
3. Para cada condição insatisfeita: implementar a resposta/efeito legítimo (provável:
   completion do `sceCdSeek` — fno/estrutura no decomp; ou intr/callback de N-cmd via
   `_sceCd_c_cb_sem` — o produtor é o callback registrado pelo próprio jogo).
4. 1 corrida = 1 prova; iterar até `sceCdRead` disparar (bytes conferidos vs ISO ao vivo) e
   o laço sair. Seguir o gate. M4 = parar, confirmar 3x, reportar imediatamente.

## Aceite

Anatomia documentada (todas as condições nomeadas) + `sceCdRead` fno=1 disparando ao vivo
com bytes reais + gate estável fora de `0x245720`.

## Regras

As do `STATUS.md`/`WORKFLOW.md` + build (find_stale=0 pré-relink; parallel_compile p/ muitos
`.o`; relink nunca concorrente; PATH MSYS2; env via `$env:`; budget 100000; janela 90s).
Sem env-gate; sem SignalSema injetado; sem chute; scheduler intacto. Suíte se mudar tracked.
Commits locais SEM push; resultado em `docs/RESULT_LOOP_245720_V1.md`. Limite ~5 condições
implementadas sem o laço sair = parar e reportar a anatomia completa com evidência.
