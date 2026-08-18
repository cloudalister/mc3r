# Handoff — passo 10: a função ausente `0x540838` (e a classe "missing depois da regeneração")

## Contexto mínimo

Passo 9 (`docs/RESULT_FORMATTER_RESUME_V1.md`) derrubou o `0x5a8908`; o boot agora para
determinístico (3/3) em `0x245718` com `bad=0x540838` — dispatch para função não-implementada.
Pelo symbol port, `0x540838` está na região `sceUsbKb` (entre `sceUsbKbSync` `0x540720` e
`sceUsbKbCnvRawCode` `0x541178`). Hipótese: a regeneração do passo 9 (que descobriu novos
entry targets) expôs funções que nunca entraram no conjunto gerado/compilado/registrado.

## Objetivo

`0x540838` (e QUALQUER outra função na mesma condição) implementada pelo caminho normal do
pipeline — gerada, compilada, registrada — e o gate segue adiante.

## Método

1. Identificar a função: decomp/disasm de `0x540838` no retail (Ghidra `work/mc2recomp`,
   `SLUS_213.55` — só leitura) + equivalente alpha nomeado. É `sceUsbKb*` interna? handler?
2. Por que ficou fora: está no `SLUS_213.55.ghidra.csv`? No manifest de missing
   (`work/link/partial/missing_functions.partial.manifest.csv`)? A regeneração de 80 arquivos
   do passo 9 criou referências novas sem gerar os alvos? Documentar a mecânica.
3. **Fechar a classe, não o caso**: listar TODOS os `bad=`/missing atuais (trace + manifest) e
   gerar/compilar/registrar todos de uma vez (o pipeline 08/09/10 já faz isso em lote).
4. Relink, 1 corrida = 1 prova, seguir o gate. Se voltar a cair em região `sceUsbKb`, lembrar:
   o handler usbkb do runtime responde "0 teclados" — a função guest pode só precisar existir
   para retornar erro limpo.
5. M4 (`gifPackets>0` E `gsPrims>0`) = parar, confirmar `21_probe_repeat.bat 3 probe
   m4_confirm`, reportar imediatamente.

## Aceite

`bad=0x540838` não ocorre mais; zero missing functions no manifest; gate sai de `0x245718`.

## Regras

As do `STATUS.md` + economia do `WORKFLOW.md`. PATH MSYS2 sempre; recompilar `.o` afetados;
relink ≥6 min; suíte se mudar código tracked; commits locais sem push; resultado em
`docs/RESULT_MISSING_0x540838_V1.md`.
