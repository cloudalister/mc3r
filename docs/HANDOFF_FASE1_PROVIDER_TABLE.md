# Handoff — passo 6: a tabela do provider e o `a0=7` (gate 0x5a8908, causa final)

## Contexto mínimo

Passo 5 (`docs/RESULT_MAINLOOP_DRAW_V1.md`): boot determinístico 3/3 em `0x5a8908`
(`LOOP_0x5A8908_ANATOMY.md`), agora com causa candidata: a lookup da tabela de providers
recebe `a0=7` (inteiro pequeno) onde se esperaria ponteiro/handle válido, então `func_4FA398`
retorna 0 para sempre. A frente `zipFile`/`datAssetManager` inteira está nomeada
(`SYMBOL_PORT_REPORT.md`) e o decomp existe (`alpha_decomp_sce.txt` + regenerável com filtro
`datAsset|zip|Stream|coreFile` se precisar).

## Objetivo

Fazer `func_4FA398` retornar !=0 pelo caminho legítimo: entender o que o `7` é, o que
registra providers na tabela, e por que o registro não aconteceu — e corrigir a causa
(provável: alguma resposta IOP/arquivo ainda incompleta na cadeia `zipFile::zipOpen` →
`coreRaw*` → cdvd read fno=1, que nunca foi exercitado de verdade).

## Método

1. Decomp dirigido: `func_4FA398` (retail) ↔ correspondente alpha nomeado; de onde vem `a0=7`
   (constante? campo de struct? retorno de outra função?); quem escreve a tabela
   (`datAssetManagerHierNew`? `zipFile::Init`? `coreFileStandard`?).
2. Trace: nos logs da corrida, o que aconteceu com as tentativas de `zipFile::zipOpen`/
   `sceCdRead` antes do spin? O read fno=1 do passo 1 dispara agora? Completa? A intr-data
   de 0x90 é consumida?
3. Corrigir na camada certa (runtime responde errado → consertar resposta; jogo espera
   side-effect de completion → entregar pelo caminho legítimo). Mesma disciplina.
4. 1 corrida = 1 prova; iterar. Se o gate mover, seguir o novo gate até a régua de render
   (`gifPackets`/`gsPrims`) sair de zero OU novo bloqueio mapeado.

## Aceite

Stable PC sai de `0x5a8908` com evidência da causa (não por contorno). M4 (`gifPackets>0` E
`gsPrims>0`) = parar, confirmar `21_probe_repeat.bat 3 probe m4_confirm`, reportar na hora.

## Regras

As do `STATUS.md`. Lembretes: recompilar `.o` gerados afetados antes do relink (relink fast
não recompila); modo probe limpo; commits locais sem push; resultado em
`docs/RESULT_PROVIDER_TABLE_V1.md`.
