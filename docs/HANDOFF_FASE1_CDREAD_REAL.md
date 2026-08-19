# Handoff — passo 16: a leitura de CD de verdade (gate `0x245720`)

## Contexto mínimo

Fase 2c aceita (`docs/RESULT_FASE2C_V1.md`): boot determinístico 10/10 em `0x245720`, 7x
mais rápido, semáforos com contrato correto. `0x245720` é o loop de `sub_00245680`
(`psxCdCache`) esperando `sceCdRead`/`sceCdSync` completarem — o gate de julho, agora
alcançado com toda a infraestrutura correta por baixo. O handler cdvd fno=1 do passo 1
(`RESULT_CDVD_DISPATCH_V1.md`) nunca foi exercitado e a completion nunca foi validada.

## Objetivo

`sceCdRead` lê setores reais e completa: bytes do disco chegam ao buffer do guest, a
intr-data (0x90, `_sceCd_rd_intr_data`) é preenchida, `sceCdSync` enxerga a conclusão pelo
caminho legítimo (callback/sema que o decomp de `sceCdSync`/`sceCdCbfunc_num` mostra), e o
loop `0x245720` avança. Fonte dos setores: o pedido é por **LBA** — resolver contra o layout
real: preferir ler direto do ISO original (`Midnight Club 3 - DUB Edition Remix.iso` na
raiz, ISO9660, setor 2048B; um seek+read simples) para que QUALQUER LBA válido funcione,
em vez de mapear arquivo a arquivo do `extracted_iso\`.

## Método

1. Trace (1 corrida, 90s): o que acontece hoje na chamada — `mc3-cdvd-rpc kind=read` dispara?
   Com quais args (lba, nsectors, buffer, mode)? O que falta: resposta, intr-data, callback?
2. Decomp dirigido: `sceCdRead`/`sceCdSync`/`_sceCd_ncmd_prechk` no
   `alpha_decomp_sce.txt` — o layout exato do send (0x18) e da intr-data, e COMO a conclusão
   é sinalizada (`sceCdCbfunc_num`/`_sceCd_c_cb_sem` — visíveis no decomp do passo 1).
3. Implementar no handler fno=1: ler os setores do ISO (backend host novo e pequeno:
   open uma vez, seek lba*2048, read n*2048 — cuidado com modos de setor 2340/2352 se o
   `mode` pedir), escrever no buffer guest, preencher intr-data, produzir a conclusão pelo
   caminho que o cliente registrou. Sem env-gate.
4. 1 corrida = 1 prova; seguir o gate. Os DATs vão começar a ser lidos de verdade —
   se o boot avançar muito, subir o budget com parcimônia (anotar).
5. M4 (`gifPackets>0` E `gsPrims>0`) = PARAR, `21_probe_repeat.bat 3 probe m4_confirm`,
   reportar imediatamente. `gsPixels>0` = anotar commit/env/comando (primeiro framebuffer).

## Aceite

Trace mostrando: read com LBA real → bytes reais no buffer guest (amostrar e conferir contra
o ISO) → conclusão legítima → gate sai de `0x245720`.

## Regras

As do `STATUS.md`/`WORKFLOW.md` (economia). PATH MSYS2; `.o` afetados; relink ≥6 min; janela
90s nas medições; CPU limpa; commits locais SEM push; resultado em
`docs/RESULT_CDREAD_REAL_V1.md`, honesto, mesmo parcial.
