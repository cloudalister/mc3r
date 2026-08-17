# Roadmap — automação de ponta a ponta

Objetivo final: uma imagem na tela vinda do runner nativo (`gif>0`/`gsw>0` + dump de framebuffer). Tudo abaixo roda headless e sem intervenção, exceto onde marcado.

Base: `docs/PLANO_2026-08-17_ALPHA_SYMBOLS.md`. Regras permanentes: medição sempre com `MC3_DETERMINISTIC=1` + `MC3_DISPATCH_BUDGET=25000` + `21_probe_repeat.bat 10`; nunca injetar SignalSema; captura real antes de inventar valor.

## Fase 0 — símbolos do alpha 102404 (em andamento)

O protótipo de out/2004 traz `MC.MAP` (~19.250 funções com nome demanglado, endereço, tamanho e objeto de origem) e `MC.SYM`. Já extraídos do ISO junto com o ELF `SLUS_123.45`.

| # | Passo | Automação |
|---|---|---|
| 0.1 | JDK 21 + `analyzeHeadless` do ghidra_12.1 funcionando | `22_alpha_symbols.bat check` |
| 0.2 | Importar o ELF do alpha no projeto Ghidra e aplicar o MC.MAP (script `tools/ghidra/ImportMc3Map.py`) | `22_alpha_symbols.bat import` — headless, valida contagem de símbolos aplicados |
| 0.3 | Exportar assinaturas (bytes mascarados + features de callgraph) do alpha nomeado e do retail | `22_alpha_symbols.bat export` |
| 0.4 | Casar alpha→retail (hash exato mascarado → refinamento por vizinhança de callgraph) e gravar `work/exports/retail_symbol_port.csv` | `23_port_symbols.bat` |
| 0.5 | Relatório `docs/SYMBOL_PORT_REPORT.md`: cobertura por região + nomes dos endereços críticos (0x398B18, produtor do sid=5, provider, clientes SIF) | gerado pelo 23 |

Aceite da fase: ≥60% das funções do boot path retail nomeadas, e resposta com nome para o handoff sid=5. Se o casamento vier ruim, decisão registrada no plano: mudar o alvo do recomp para o ELF do alpha.

## Fase 1 — camada SIF vira protocolo

Proibido: novo `else if` por payloadAddr fixo, novo env-gate experimental de SIF.

| # | Passo | Automação |
|---|---|---|
| 1.1 | Capturar no PCSX2 real as respostas IOP para os requests descartados (0x1/0x90, 0xFF/0x8, 0x9, 0x22) | `24_capture_iop_responses.bat` via PCSX2-MCP, sem fullscreen; dumps em `work/iop_captures/` |
| 1.2 | Com os nomes da fase 0, ler o lado cliente (`mcAudioRpcMgr`, `sndRpcManager`, `coreFile*`) e escrever o spec por servidor em `docs/SIF_PROTOCOL.md` | manual assistido (leitura de decompilado) |
| 1.3 | Reescrever `SIF.cpp`: handler por (servidor, requestId) que escreve a struct completa no endereço vindo do request | código no fork PS2Recomp, branch mc3 |
| 1.4 | Apagar env-gates experimentais antigos | idem |
| 1.5 | Regressão: boot com zero `mc3-iop-response-unhandled` e sid=5 sinalizado pelo produtor real | `21_probe_repeat.bat 10` + verificação no trace |

Plano B se algum servidor não fechar em HLE: interpretador R3000 rodando os IRX reais da ISO (LLE do IOP). Só entrar com evidência de que o HLE não fecha.

## Fase 2 — determinismo

Trocar as threads guest (`std::thread`) por scheduler cooperativo (uma thread host, troca em WaitSema/syscall bloqueante). Aceite: 10/10 probes com o mesmo Stable PC. Depois disso o boot probe vira teste de regressão de verdade.

## Fase 3 — primeiro frame

Auditar o caminho VIF1→VU1→GIF→GS do runtime (`ps2_vif1_interpreter`, `ps2_vu1`, `ps2_gif_arbiter`, `ps2_gs_rasterizer`) contra o que `mcGame::PreDraw` (nomeado) realmente usa. Vitória: `gif>0`, `gsw>0` e PNG do framebuffer salvo pelo probe.

## Loop autônomo (Ralph)

Os lotes longos rodam como lanes do Ralph (`.agents/ralph` + PRDs em `.agents/tasks/`), com `.ralph/guardrails.md` valendo sempre:

- lane A (fase 0): rodar 22→23, reler o relatório, refinar matcher até bater o aceite;
- lane B (fase 1): para cada request sem handler: capturar (24), spec, implementar, `21_probe_repeat 10`, comparar com baseline, commitar ou reverter;
- toda lane termina atualizando `PS2_PROJECT_STATE.md` com checkpoint datado e fazendo push.

Interativo por natureza (não automatizável): decisão alpha-como-alvo (fim da fase 0), aprovação do design do scheduler (fase 2).

## Ordem e dependências

0 → 1 → 3, com 2 entrando depois do primeiro aceite da fase 1 (protocolo correto muda o comportamento das threads; serializar antes calibraria sobre boot quebrado). Se a fase 1 empacar por medição ruidosa, adiantar a 2.
