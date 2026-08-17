# Handoff B — Gap de dispatch `0x42eb48` e proteção contra regeneração — 2026-08-07

**Prioridade: alta, independente do Handoff A.** Pode rodar em paralelo (lane separada, só toca um arquivo gerado + tooling).

## O problema, com precisão

`work\generated\ghidra\sub_0042EB08_0x42eb08.cpp`, regenerado em 01/08 06:08, tem em `0x42EB40` um `jr $ra` cujo switch de jump target cobre:

```
case 0x42EB24u  case 0x42EB28u  case 0x42EB2Cu
case 0x42EB84u  case 0x42EB90u  case 0x42EBCCu
```

Falta `0x42EB48`. Não existe `label_42eb48` no arquivo — o código em `0x42eb48` (linha ~116) só é alcançável por fall-through, nunca por retomada de dispatch.

Resultado: `[dispatch:first-bad-pc] bad=0x42eb48` em 100% das corridas medidas hoje.

## Histórico que importa (não repita o erro)

- O handoff de **2026-06-17** registra um patch manual em exatamente este arquivo, adicionando casos para `0x42eb48` **e** `0x42eb90`.
- O arquivo atual tem só `0x42eb90`. **Metade do patch foi apagada pela regeneração de 01/08.**
- Em 28/07 o `first-bad-pc` era `0x42eb90`; hoje é `0x42eb48`. Isso confirma que resolver um gap revela o próximo — é progresso normal, não regressão nova.

**Expectativa calibrada:** fechar `0x42eb48` provavelmente vai revelar o próximo endereço da cadeia, não fazer o jogo renderizar. Faça pelo valor de tirar ruído do trace, não esperando a vitória.

## Tarefa B1 — Fechar o gap

Seguir o padrão já usado no projeto (`0x42eb48`/`0x42eb90`/`0x540838`): adicionar o `case` e o `label_` correspondentes, sem inventar semântica nova e sem tocar no resto da função.

Depois — **e isto é obrigatório**, é o gotcha que já custou horas em 08/07:

```bat
09_compile_generated_batch.bat batch_0036 100 object
10_link_partial_runner.bat fast
20_verify_boot_state.bat
```

`sub_0042EB08` está em `batch_0036` (confirmado: `work\compile\ghidra\batch_0036\obj\sub_0042EB08_0x42eb08.o`).

**Aceite:** `21_probe_repeat.bat 5 595 dispatch_fix` — o `first bad PC` precisa deixar de ser `0x42eb48` em todas as corridas. Se virar outro endereço, documente qual: é o próximo item da fila, não uma falha.

## Tarefa B2 — Impedir que aconteça de novo (o ponto principal)

O gap voltou porque a regeneração sobrescreve edições manuais sem aviso. Enquanto isso não for resolvido, qualquer patch em arquivo gerado é temporário e vai reaparecer como bug fantasma daqui a semanas.

Escolher **uma** abordagem e implementar:

1. **Registro de patches** (recomendada): um arquivo `work\patches\generated_resume_labels.csv` listando `função, PC alvo, motivo, data`. Um script `tools\Apply-ResumeLabels.ps1` reaplica todos após qualquer regeneração, e falha ruidosamente se algum não puder ser aplicado. Vantagem: o patch vira dado versionável, não conhecimento tácito num handoff de junho.
2. **Corrigir o gerador**: descobrir por que ele emite `case` para `0x42EB90` mas não para `0x42EB48`, sendo que ambos são alvos de dispatch observados. Se o gerador souber emitir todos os PCs internos alcançáveis, o patch manual deixa de existir. Vantagem: resolve na raiz. Custo: maior.
3. **Detecção**: um check que compara os `[dispatch:first-bad-pc]` observados contra os labels existentes e acusa gaps antes de virar bug. Mais barato, mas é remendo — não impede a perda, só avisa.

**Aceite:** simular uma regeneração do `sub_0042EB08_0x42eb08.cpp` e provar que o patch sobrevive (opção 1), que nasce correto (opção 2), ou que é detectado (opção 3).

## Tarefa B3 — Auditar quantos outros gaps existem

`13526` dos `15812` arquivos gerados têm `switch (ctx->pc)`. Os outros `2286` podem estar corretos (sem PC interno alcançável) ou ter o mesmo buraco silencioso.

Cruzar os PCs que já apareceram como `bad=` em todos os logs históricos (`work\boot_probe\*.log`, `work\logs\*.log`) contra os labels existentes nos arquivos gerados. Produzir a lista de gaps conhecidos.

**Entregável:** `docs\DISPATCH_GAPS_AUDIT.md` com a lista, ordenada por frequência de ocorrência nos logs.

## O que NÃO fazer

- Não registrar todo `ctx->pc` como alias. Já foi tentado e **crashou o runner** (exit `-1073741571`, checkpoint de 17/06). PCs internos arbitrários precisam de label correspondente.
- Não regenerar o arquivo "para ficar limpo" antes de ter B2 pronto — você perde o patch de novo.
- Não editar nada além de `sub_0042EB08_0x42eb08.cpp` e o tooling novo.
