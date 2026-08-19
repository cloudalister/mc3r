# Handoff — passo 17: o servidor "disco pronto" (sid 0x8000059c) — o último degrau antes da leitura

## Contexto mínimo

Base: binário 100% honesto (19/08 04:43), boot determinístico 5/5 em `0x245720`
(`sub_00245680`/`psxCdCache`). O bloqueio imediato, já identificado no
`RESULT_CDREAD_REAL_V1.md`: `sub_005420C0` consulta o servidor RPC **`0x8000059c`**
(família cdvd diskready/status; docs de julho: "queue `0x704200` sem consumidor") e precisa
que o resultado leve o loop a receber `2` (`SCECdComplete` — disco pronto). O runtime nunca
responde esse servidor. A leitura por LBA do ISO real já está implementada e testada
byte-a-byte, esperando o boot alcançá-la.

## Objetivo

O servidor `0x8000059c` responde com semântica real ("disco PS2 DVD presente e pronto"), o
loop de `sub_005420C0` recebe `2`, `psxCdCache::RawRead` finalmente dispara `sceCdRead`
(fno=1) ao vivo, e os primeiros setores reais do ISO chegam ao guest.

## Método

1. Trace honesto (1 corrida, 90s, binário novo): capturar o que chega para `0x8000059c`
   (fno, send size, recv size) e o que `sub_005420C0` faz com a resposta (decomp dele +
   `sceCdNcmdDiskReady` no `alpha_decomp_sce.txt` — a assinatura fno=0xe, recv=4B já foi
   cruzada no passo 16).
2. Implementar no dispatcher SIF (mesma infra por (sid, fno)): resposta de disco pronto —
   valores do decomp/ps2sdk (`SCECdComplete=2`; tipo de disco PS2 DVD se consultado). Sem
   env-gate.
3. 1 corrida = 1 prova. Se o read disparar: verificar bytes-vs-ISO ao vivo (o teste
   permanente já cobre offline). Seguir o gate; budget com parcimônia se avançar fundo.
4. M4 (`gifPackets>0` E `gsPrims>0`) = PARAR, `21_probe_repeat` 3x confirmar, reportar
   imediatamente. `gsPixels>0` = anotar tudo (primeiro framebuffer).

## Aceite

`sub_005420C0` sai do loop (retorno 2 visto no trace), `sceCdRead` fno=1 dispara ao vivo com
bytes reais, gate sai de `0x245720`.

## Regras

As do `STATUS.md`/`WORKFLOW.md`. **Antes de qualquer relink: `tools/find_stale.py` tem que
dar 0** (regra nova); recompilar `.o` afetados com `tools/parallel_compile.py` se forem
muitos; relink nunca concorrente com compilação; PATH MSYS2; janela 90s; env via `$env:`;
CPU limpa; suíte se mudar tracked; commits locais SEM push; resultado em
`docs/RESULT_DISKREADY_059C_V1.md`.
