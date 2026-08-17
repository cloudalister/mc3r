# Auditoria e Status da Recompilação do Midnight Club 3 (MC3)

**Data:** Terça-feira, 14 de julho de 2026  
**Autor:** Gemini CLI  
**Objetivo:** Registro detalhado do ponto onde a recompilação e execução pararam.

---

## 1. Resumo Curto
O pipeline de recompilação do Midnight Club 3 (`SLUS_213.55`) está em estado parcial e foi pausado para descanso em **11/07/2026 às 05:42**. Embora o boot probe tenha atingido a classificação **`render-started`** (com contadores de DMA e VIF ativos), a execução do executável nativo parcial (`mc3_partial.exe`) está presa em um loop de espera ocupada (spin lock) no endereço **`0x2b4488`** devido a falhas no subsistema de arquivos/pacotes ao tentar abrir arquivos de texturas (como `texture.zip` e subarquivos). Atualmente, a recompilação automatizada via script está interrompida por causa de **9 funções do `batch_0015`** cujos objetos `.o` ainda não foram compilados, causando a falha do script de linkagem rápida (`10_link_partial_runner.bat`).

---

## 2. Evidências com Paths Absolutos

- **Diretório do Workspace:**  
  `D:\ARQUIVO_TARS\Emuladores\Sony\mc3recomp`
- **Registro do Último Estado do Projeto:**  
  `D:\ARQUIVO_TARS\Emuladores\Sony\mc3recomp\PS2_PROJECT_STATE.md`
- **Log do Último Boot Probe (Render Ativo):**  
  `D:\ARQUIVO_TARS\Emuladores\Sony\mc3recomp\docs\BOOT_PROBE_STATUS.md`
- **Mapeamento de Funções Ausentes do Lote 15:**  
  `D:\ARQUIVO_TARS\Emuladores\Sony\mc3recomp\work\link\partial\missing_functions.partial.manifest.csv`
- **Código-fonte Onde a Execução Está Presa:**  
  `D:\ARQUIVO_TARS\Emuladores\Sony\mc3recomp\work\generated\ghidra\sub_002B4438_0x2b4438.cpp`
- **Log da Falha de Relinkagem do Runner:**  
  `D:\ARQUIVO_TARS\Emuladores\Sony\mc3recomp\work\logs\12_trace_driven_compile_20260711_053213.log`

---

## 3. Tabela de Achados

| Parâmetro Técnico | Valor / Estado | Caminho do Arquivo Relacionado / Detalhe | Nível de Certeza |
|---|---|---|---|
| **Classificação do Probe** | `render-started` | `docs\BOOT_PROBE_STATUS.md` | Absoluta |
| **Contadores de Render** | `dma=2`, `gif=0`, `gsw=0`, `vif=3` | Registrado em logs de execução e status do probe | Absoluta |
| **Ponto Crítico de Loop** | `0x2b4488` (Vtable slot `+0x24`) | `work\generated\ghidra\sub_002B4438_0x2b4438.cpp` | Alta |
| **Último PC Estável** | `0x2b4488` | Chamador `FUN_003b34c0_0x3b34c0` | Alta |
| **Estado do Runner Parcial** | Falha de linkagem | `work\logs\10_link_partial_runner_driver.log` | Absoluta |
| **Pendências do Build (Obj)**| 9 stubs ausentes no lote 15 | `work\compile\ghidra\batch_0015\obj\` | Absoluta |
| **Falha de E/S Low-Level** | Retorno `handle=0xffffffff` | Ocorre ao tentar abrir `texture.zip` em `0x4f9760` | Alta |

---

## 4. Riscos/Dúvidas
- **Hangs no Build:** O script `Generate-PartialRegister.ps1` é muito lento ao varrer milhares de arquivos com `Select-String` no PowerShell, gerando falsos timeouts (como o limite de 5 minutos excedido) se o lote estiver inconsistente.
- **Acoplamento SIF/IOP:** O spin lock em `0x2b4488` pode ser uma consequência direta de requisições de IOP/SIF (`0x701b40` e `0x620d80` com `sid=44` em `WaitSema`) não respondidas, e não apenas de lógica faltante na EE.

---

## 5. Próximo Passo Recomendado

Para resolver as pendências e avançar:

1. **Compilar os stubs do `batch_0015` em modo de objeto:**
   ```bat
   09_compile_generated_batch.bat batch_0015 250 object
   ```
2. **Forçar a relinkagem limpa do runner nativo parcial:**
   ```bat
   10_link_partial_runner.bat
   ```
3. **Rodar o boot probe com suporte a traces para verificar a saída do loop em `0x2b4488`:**
   ```bat
   15_auto_boot_probe.bat 6 payload1m3skip5a
   ```
