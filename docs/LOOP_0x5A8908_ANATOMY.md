# Anatomia Estática do Loop `0x5a8908` & Mapa do Provider

**Data:** 2026-08-01  
**Autor:** Antigravity (Gemini 3.6 Flash / Pair Programming)  
**Objetivo:** Cumprir Etapas 2 e 3 do `PLAN_10_STEPS_2026-07-29.md` (Investigação estática do gate `0x5a8908` e mapeamento de escritas/leituras do provider).

---

## 1. Etapa 2: Anatomia Estática do Loop `0x5a8908`

### Funções Analisadas
- [sub_005A8898_0x5a8898.cpp](file:///e:/Emuladores/Sony/mc3recomp/work/generated/ghidra/sub_005A8898_0x5a8898.cpp)
- [sub_004BD488_0x4bd488.cpp](file:///e:/Emuladores/Sony/mc3recomp/work/generated/ghidra/sub_004BD488_0x4bd488.cpp) (Caller único)

### Fluxo de Execução de `sub_005A8898_0x5a8898`

1. **`0x5a88a4`**: Chamada `jal func_398400`.
2. **`0x5a88ac`**: `beqz $v0, 0x5a8924`
   - Se `func_398400` retornar `0`, o código pula o loop inteiro e sai via `0x5a8924` (`jal func_5290F0` e `jr $ra`).
3. **`0x5a88b4`**: Chamada `jal func_3B14D0` (passando `$a0 = 0x24`).
4. **`0x5a88bc`**: Chamada `jal func_4F9A68` (passando `$a0 = $v0`).
5. **`0x5a88dc`**: Chamada `jal func_42F9F0`.
6. **`0x5a88e8`**: Chamada `jal func_4FA398`.
7. **`0x5a88f0`**: `beqz $v0, 0x5a8908`
   - **Branch Crítico de Bloqueio:** Se `func_4FA398` retornar `0`, pula para `0x5a8908`.
   - Se `func_4FA398` retornar diferente de `0`, executa `jal func_429650` (`0x5a88f8`) e depois pula para `0x5a8924` (`b 0x5a8924`), saindo da função com sucesso.
8. **`0x5a8908` - `0x5a891c`**: Loop Infinito Spin-Wait!
   - `0x5a891c`: `b 0x5a8908` (loop incondicional repetindo em `0x5a8908` se `shouldPreemptGuestExecution()` não interromper).

### Instrução de Branch Exata que Sai do Loop
- **Endereço:** `0x5A88F0`
- **Instrução MIPS:** `beqz $v0, 0x5a8908` (`0x10400005`)
- **Condição de Saída:** `$v0 != 0` retornado por `func_4FA398` (`0x4FA398`).

---

## 2. Etapa 3: Mapeamento dos Globais do Provider (`0x629F40` - `0x629F50`)

### Endereçamento Base MIPS
No código Ghidra/MIPS:
- `$v0 = LUI(0x62)` $\rightarrow$ Base `0x00620000`.
- `$v1 = LBU -0x60C0($v0)` $\rightarrow$ `0x00620000 - 0x60C0 = 0x00619F40`.

*Nota de Correção:* Os endereços do provider estão na faixa **`0x00619F40` - `0x00619F50`** (e não `0x629F44`).

### Leituras Mapeadas
- **`sub_004FAED8_0x4faed8.cpp`**:
  - `0x4faee8`: `lbu $v1, -0x60C0($v0)` (Lê `0x00619F40`).
  - Se `0x00619F40 == 0`, a função aborta em `0x4faf4c` sem inicializar o sub-provedor.

### Escrituras Mapeadas
- **`FUN_004fa7a8_0x4fa7a8.cpp`**:
  - `0x4fa7b8`: `sb $a0, -0x60C0($v1)` (Escreve `$a0` em `0x00619F40`).
  - Esta é a função de inicialização do provider de pacotes (`MC3_SIF_EXPERIMENT_REQ4_620D80_STATUS=1` aciona esta frente).

---

## 3. Conclusão & Próximos Passos
O gate `0x5a8908` é um spin-wait causado pelo retorno `0` da função `func_4FA398` em `0x5a88f0`. Para o runner progredir:
1. `func_4FA398` precisa retornar um ponteiro/status válido (`!= 0`).
2. A etapa 4 do plano (`MC3_TRACE_PROVIDER=1`) deve instrumentar `0x4FA398` e `0x4FAED8` para diagnosticar qual estrutura interna está incompleta.
