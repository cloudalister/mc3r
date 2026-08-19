# Resultado: Fase 2b Round 2

**Data encerramento**: 2026-08-19 01:42:58  
**Status**: Interrompido por falha do host (2x) + evidência inconclusa  
**Branch/submódulo**: mc3 (repositório principal e PS2Recomp)

## Resumo Executivo

Round 2 visava validar contrato de semáforos (retorno sid) integrado ao VBlank tick. Medições v3 e v4 mostraram divergência persistente em 3 PCs distintos da família esperada (0x548e70, 0x245720 + terceiro mutante por run); revert de Sync.cpp foi necessário; re-medição baseline falhou por timeout universal (marker ausente) — inviável tirar conclusão.

**Recomendação**: Redesenho da integração VBlank→tick pelo coordenador (round 3).

## Medições e Artefatos

### Fase 2b v3 — repeat_fase2b_v3_20260818_232911.md
- **Timestamp**: 23:29:52 de 2026-08-18
- **Modo**: probe | 10 runs | 20 segundos por run
- **PCs distintos**: 4
  - 0x548e70 (counters-moved, 3x)
  - 0x245720 (counters-moved, 2x)
  - 0x432aa0 (counters-moved + semaphore)
  - 0x4add24 (semaphore, 1x)
- **Falhas de evidência**: 7/10 (marker ausente ou timeout)
- **Classificação**: Não determinístico neste modo

### Fase 2b v4 — repeat_fase2b_v4_20260819_000827.md
- **Timestamp**: 00:08:41 de 2026-08-19
- **Modo**: probe | 10 runs | 30 segundos por run
- **PCs distintos**: 3
  - 0x548e70 (counters-moved, 5x)
  - 0x245720 (counters-moved, 3x)
  - 0x4aea04 (semaphore, 1x)
- **Falhas de evidência**: 2/10 (timeout)
- **Classificação**: Não determinístico; menor taxa de falha que v3

### Revert Check inválido — repeat_revert_check_20260819_001447.md
- **Timestamp**: 00:14:47 de 2026-08-19
- **Modo**: probe | 5 runs | 8 segundos por run
- **Resultado**: 5/5 timeout — **inválido (host em colapso)**
- **PC único**: 0x1a0138 (unknown-loop)
- **Motivo descarte**: CPU/memória esgotados durante medição anterior

### Revert Check Limpo — repeat_revert_check_clean_20260819_014211.md
- **Timestamp**: 01:42:58 de 2026-08-19
- **Modo**: probe | 5 runs | 8 segundos por run
- **Resultado**: 5/5 timeout com marker=no — **inválido**
- **PC único**: 0x1a0138 (unknown-loop)
- **Diagnóstico**: Dispatch-budget não foi ativado (marker=no); código saiu do loop esperado. Sugere binário não corresponde ao estado revertido ou máquina ainda em regime degradado.

## Estado Git Final

### Repositório principal (mc3recomp)
```
On branch mc3
Changes not staged for commit:
  modified:   PS2Recomp (modified content, reverted)
  modified:   docs/EXPLICA_VISUAL.md (novo doc anterior)

Untracked files:
  docs/EXPLICA_VISUAL.html
```

### Submódulo PS2Recomp
```
On branch mc3
Working tree clean
```

**Ação realizada**: `git checkout -- ps2xRuntime/src/lib/Kernel/Syscalls/Sync.cpp` — revert byte-a-byte do contrato de semáforos (remoção do retorno sid + gate experimental MC3_SEMA_EXPERIMENT_POLL_RETURNS_SID).

## O que Era o Diff do Sync.cpp

**Mudanças revertidas:**
1. Remoção de função `isMc3PollSemaReturnSidExperimentEnabled()` (gate experimental)
2. Em `iSignalSema()`: mudança de `setReturnS32(ctx, KE_OK)` para `setReturnS32(ctx, sid)` com comentário de auditoria
3. Em `iSignalSema()`: adição de `bool signaled` para desacoplar scheduler do contrato de retorno
4. Em `iSignalSema()`: mudança de `if (ret == KE_OK && isMc3DeterministicModeEnabled())` para `if (signaled && isMc3DeterministicModeEnabled())`
5. Em `iSignalSema()`: adição de bloco final com `if (signaled) { ret = sid; }` — retorno de sid em lugar de KE_OK

**Justificativa original** (do diff): Contrato auditado em RESULT_SEMA_CONTRACT_V1.md — EE kernel real retorna sid, não KE_OK, confirmado por call site (PollSema); resto da família por consistência.

## Discussão

- **V3 vs V4**: V4 mostrou melhora em convergência (3 PCs vs 4, falhas reduzidas de 7 a 2), mas ainda longe da esperado (marker=yes, timeout=no).
- **Revert Check**: Impossível validar. Host colapsou em 00:14; CPU recuperou-se parcialmente em 01:42, mas binário linkado ainda comporta-se anomalamente (timeout universal, marker ausente).
- **Terceiro mecanismo de corrida**: Análise anterior (handoff passo 13) suspeitava de "3º mecanismo não isolado" além dos 2 do VBlank. V3/V4 reforçam isso: semaphore PC (0x4add24, 0x4aea04) diverge entre runs, sugerindo fator dinâmico não coberto por deterministic mode + dispatch-budget.

## Próximos Passos (Round 3)

1. **Redesenho VBlank→tick**: Coordenador deve revisar integração entre VBlank interrupt, tick counter, e scheduler — possível sincronização por evento (evento de tick gerado por VBlank, consumido pelos mecanismos de espera).
2. **Isolamento do 3º mecanismo**: Se redesenho não tratar scheduling diferencial de semáforos vs outras wait-primitives, fazer novo round 2b com gating experimental em ambas as famílias.
3. **Re-limpeza de máquina**: Antes de round 3, validar boot completo (boot_fast) e rodada de revert_check com marker=yes, timeout=no em todas as 10 runs.

## Artefatos Gerados Este Round

- docs/RESULT_FASE2B_ROUND2_V1.md (este arquivo)
- Nenhum novo commit (revert completado, estado limpo)
