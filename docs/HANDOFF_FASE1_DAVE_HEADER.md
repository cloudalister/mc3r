# Handoff — passo 7: entregar o header "Dave" (o elo final do provider)

## Contexto mínimo

Passo 6 (`docs/RESULT_PROVIDER_TABLE_V1.md`): o provider fica preso em `"T:"` (devkit) porque
`func_4FAA10` compara 4 bytes de assinatura contra `"DAEV"/"Dave"` e nunca reconhece. O
coordenador confirmou: `extracted_iso\ASSETS.DAT` começa literalmente com `Dave` (magic do
formato DAVE da Angel). Logo: o jogo pede os primeiros bytes do DAT e o runtime devolve
vazio/errado. Consertar essa leitura deve virar o provider para o modo pacote (`0x619F58`),
destravar `0x5a8908` e deixar os assets carregarem.

## Objetivo

A leitura que alimenta `func_3993A8`/`func_4FAA10` passa a devolver os bytes reais do
`ASSETS.DAT` (e dos demais `.DAT` conforme pedidos), pelo caminho legítimo.

## Método (barato primeiro)

1. **Trace primeiro** (1 corrida, `MC3_BOOT_TRACE=1`): localizar o open/read da assinatura —
   qual device/path o jogo pede (`cdrom0:\ASSETS.DAT;1`? via fileio 0x80000001? via cdvd
   searchfile+read por LBA?) e qual handler atende hoje (e devolve o quê). O RESULT do passo 6
   já mostra a cadeia `CreateSema/WaitSema/SIF RPC` do open no backend `0x3984c0` — seguir ela.
2. Economia: para perguntas de decomp ("o que func_X faz"), usar `gemini -p` com o trecho
   extraído por grep/awk (nunca o arquivo inteiro), saída em `work/scratch/`; confirmar
   pistas com grep antes de codar. Ler `docs/WORKFLOW.md` seção economia.
3. Implementar a resposta correta no handler certo (fileio open/read com backend em
   `extracted_iso\`, ou cdvd searchfile→LBA→read servindo do próprio arquivo/ISO — o que o
   trace mostrar que o jogo usa). Os LBAs do ISO original diferem do filesystem extraído —
   se o jogo pedir por LBA, mapear via ISO real (`Midnight Club 3 - DUB Edition Remix.iso`
   na raiz) ou pelo layout do `extracted_iso` (documentar a escolha).
4. 1 corrida = 1 prova; seguir o gate. M4 (`gifPackets>0` E `gsPrims>0`) = parar, confirmar
   `21_probe_repeat.bat 3 probe m4_confirm`, reportar na hora.

## Aceite

`flag619f40` != 0 (provider de pacote ativo) OU gate sai de `0x5a8908` — com a leitura do
header servida de verdade (trace mostrando os bytes `44 61 76 65` entregues ao guest).

## Regras

As do `STATUS.md` + economia do `WORKFLOW.md`. Recompilar `.o` gerados afetados antes do
relink; suíte se houver mudança de código; commits locais sem push; resultado em
`docs/RESULT_DAVE_HEADER_V1.md`.
