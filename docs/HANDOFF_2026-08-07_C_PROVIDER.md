# Handoff C — Frente provider/package — 2026-08-07

**Status: TRAVADA.** Não execute experimento desta frente antes do Handoff A entregar um probe mensurável. Leia a seção "Por que está travada" antes de discordar.

## Por que está travada

O plano vigente (`docs\US008_MINIMAL_PROVIDER_COMPAT_EXPERIMENT.md`) define o aceite assim: reter o experimento se o trace alcançar `0x4FAA10`, publicar `0x619F40=1` e selecionar `0x618020 -> 0x619F58 -> 0x4F9760`; *"a later Stable PC alone is failure"*.

A parte do trace (alcançar `0x4FAA10`, publicar a flag) continua válida — é observação direta, não depende do probe. A parte que compara Stable PC não vale nada hoje: cinco corridas idênticas deram cinco PCs diferentes (`docs\STATUS_2026-08-07_AUDIT.md`).

Rodar o experimento agora produz um resultado que ninguém consegue interpretar, e o histórico do projeto mostra que resultados ambíguos viram documentos afirmativos.

## O que já está estabelecido (não refaça)

- Globais e lifecycle mapeados: flag `0x619F40`, primary `0x619F44`, fallback `0x619F4C`, backend slots `0x618020/0x618024 = 0x617F88`.
- Snapshot PCSX2 real: primary `0x629F44=0x5C0C40`, fallback `0x629F4C=0x41F9B0`, cadeia `0x618020 -> 0x619F58 -> 0x4F9760`. O retorno do open **não** foi capturado — continua sendo a lacuna live mais importante.
- Callbacks de request `0x541348` e `0x5413F0` identificados como distintos.
- **Correção do lote 21 (importante):** `0x4F9760 -> 0x4FB0D8` é registro/seleção de extensão (`.tex`, `.xtex`, `.tga`, `.bmp`, `.ipu`, `.spr`), **não** o request do nome lógico. Nenhuma das 40 chamadas traçadas continha `mcloadstrings`, `fonts/` ou `strtbl`. Não conecte `ASSETS.DAT` antes de observar o request de nome real.
- Instrumentação env-gated pronta e reversível: `MC3_TRACE_PROVIDER`, `MC3_TRACE_LOGICAL_RESOLVER`.
- Semáforo 17: produtor é `sub_005420C0` (`0x54223C`, `0x542290`). **Não injetar sinal.** Essa decisão está certa e é definitiva.

## Trabalho liberado agora (só leitura, não depende do probe)

Estas duas tarefas podem rodar em paralelo com o Handoff A, porque não usam o probe como instrumento de decisão:

### C1 — Traçar `0x4FAED8` e `0x4FA7A8`
Próximo passo exato apontado pelo lote 21. `0x4FAED8` é o helper chamado no início de `0x4FB0D8`; `0x4FA7A8` é o escritor legítimo de estado. Objetivo: provar **por que** a ativação do provider permanece indisponível.

Entregável: quais condições `0x4FA7A8` exige para publicar `0x619F40=1`, e qual delas falha. Com endereço e valor observado, não com hipótese.

### C2 — Fechar a lacuna live do PCSX2
No jogo real, capturar **o retorno do primeiro package open** — o dado que faltou em todas as sessões live até agora. Com o jogo no title screen: breakpoint na cadeia `0x618020 -> 0x619F58 -> 0x4F9760` e registrar o valor de retorno, além do conteúdo do provider node.

Isso é o que permite distinguir "o recomp falha porque o provider não existe" de "o provider existe mas o backend não serve o arquivo". Hoje o projeto não sabe qual dos dois é.

Entregável: tabela recomp vs live para `0x619F44`, `0x619F4C`, `0x619F40` e o retorno do open. Sem sessão live disponível, registrar como pendência — **nunca preencher com valor plausível**.

## Trabalho bloqueado até o Handoff A

- `MC3_EXPERIMENT_PROVIDER_INIT_RESPONSE=1` (escrever `1` na primeira palavra da resposta para request `0xFF`, payload `0x700DC0`, size `8`).
- Qualquer decisão de reter/descartar experimento baseada em Stable PC.
- Qualquer promoção de env-gate para default.

Quando A entregar, o aceite deste experimento passa a ser: `21_probe_repeat.bat 5 595 provider_off` vs `21_probe_repeat.bat 5 595 provider_on MC3_EXPERIMENT_PROVIDER_INIT_RESPONSE=1`, comparando **distribuições**, mais o critério de trace (`0x4FAA10` alcançado, `0x619F40=1` publicado) que já era o correto.

## Frente FMV

Continua sem função concreta identificada. Não há `.pss`/`.str`/`.mpg` soltos em `extracted_iso\` (70 arquivos, só CNF/NETGUI/SYSTEM) e nenhuma string de vídeo no ELF — o conteúdo é empacotado ou vai por IPU. A extensão `.ipu` **aparece** na lista de extensões registradas traçada no lote 21, o que liga a frente FMV à frente provider: sem provider, o `.ipu` não abre.

Consequência prática: **o skip de FMV não é um atalho para ver algo na tela.** Se o provider não serve arquivo nenhum, pular o vídeo não faz o menu aparecer — o menu também precisa de assets. Tratar FMV como frente secundária até o provider servir o primeiro arquivo com sucesso.

## Regras permanentes desta frente

- Nada de handle falso, provider forjado, `SignalSema` forçado ou patch amplo.
- Não conectar `ASSETS.DAT` antes de observar o request de nome lógico real.
- Não tocar na ISO original.
- Todo experimento env-gated, com rollback = desligar a variável.
- Nenhuma alegação de "gameplay" ou "renderizou" sem o usuário ver na tela. Contadores, hashes e endereços não provam gráfico.
