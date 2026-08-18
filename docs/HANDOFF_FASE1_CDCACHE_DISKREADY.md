# Handoff — passo 11: disco pronto (`psxCdCache` @ 0x245718, o gate de julho)

## Contexto mínimo

Gate determinístico atual: `0x245718`, loop do `psxCdCache` (antes de `psxCdCache::RawRead`
`0x245790`). É o gate histórico de julho: o loop espera a família `sceCdDiskReady`/status
retornar `2` (`SCECdComplete`). O dispatcher cdvd (passo 1) responde init (fno=0); diskready/
status nunca foi implementado — era mascarado por env-hacks `ret2` nos experimentos de julho
(hoje aposentados). Decomp nomeado disponível: `sceCdNcmdDiskReady`, `sceCdSync`,
`sceCdGetError`, `sceCdMmode`, `sceCdInit` em `work/exports/alpha_decomp_sce.txt`.

## Objetivo

O caminho cdvd de "disco pronto" responde de verdade (semântica: disco sempre presente e
pronto — o "drive" é o `extracted_iso\`), o loop `0x245718` avança, `psxCdCache::RawRead`
dispara o `sceCdRead` fno=1 (nunca exercitado), e as leituras de DAT completam com bytes
reais, com a completion entregue pelo caminho legítimo (callback/intr-data/sema do cliente,
como o decomp de `sceCdSync`/`_sceCd_cd_read_intr` mostrar).

## Método

1. Trace: qual chamada exata o loop faz (`sceCdNcmdDiskReady`? via RPC com qual (sid,fno)?
   leitura de global de status?) e o que o runtime devolve hoje. Decomp da função guest
   confirmando o que ela testa.
2. Implementar no dispatcher a resposta real (disco: pronto, tipo: PS2 DVD — `sceCdMmode`
   pode ser consultado; valores no decomp/ps2sdk). Sem env-gate.
3. Quando `RawRead`/`sceCdRead` dispararem: servir os bytes do arquivo/LBA pedidos a partir de
   `extracted_iso\` (se o pedido for por LBA absoluto, resolver pelo ISO original na raiz ou
   documentar o mapeamento), preencher a intr-data (0x90, layout no decomp do passo 1) e
   entregar a completion pelo produtor legítimo.
4. 1 corrida = 1 prova; seguir o gate. Atenção especial: a partir daqui os assets carregam de
   verdade — se o boot avançar muito, aumentar `MC3_DISPATCH_BUDGET` com parcimônia (e anotar)
   para não confundir "budget esgotado" com gate.
5. M4 (`gifPackets>0` E `gsPrims>0`) = parar, confirmar `21_probe_repeat.bat 3 probe
   m4_confirm`, reportar imediatamente. Se `gsPixels>0` também: anotar TUDO (commit/env/
   comando) — é o primeiro conteúdo de framebuffer da história do projeto.

## Aceite

Gate sai de `0x245718` com trace mostrando diskready→read→bytes reais→completion legítima.

## Regras

As do `STATUS.md` + economia do `WORKFLOW.md`. PATH MSYS2; recompilar `.o` afetados; relink
≥6 min; suíte se mudar tracked (base atual: 271 testes, 1 flake documentado); commits locais
sem push; resultado em `docs/RESULT_CDCACHE_DISKREADY_V1.md`.
