# Probe de 20 minutos com 5BB260/5CD768 — 2026-09-15

05:28:41–05:48:42 local. PID26484 parado pelo limite (exitedBeforeLimit=false,
exitCode=null); sem saida espontanea. 1202,0s parede; 1212,6s CPU.
Nenhum mc3_partial ativo no fim.

Executavel <scratch-dir>/mc3-menu-pair-20260913/bin/mc3_partial.exe
SHA783551ac50f250c10c088eebf09683f6cd8a30796c164376fef71c7906bcb4b6 (conferido no
receipt pelo processo vivo). Mesmos parametros do probe de 13/09 21:39:
entry-fix/host-clock/bridge/STQ ON, depth OFF, headless, QuietBootTrace,
START 60s periodo/45s atraso/30s hold, captura apresentada.
Artefatos <scratch-dir>/mc3-menu-pair-20260913/run
(logs, captures, snapshots, receipt.json, transitions-final.json).

Leitor Read-MenuGuest.ps1 -UiTree -WatchSeconds1195: 207 snapshots, 0 rejeitados;
terminou com exit1 por Read failed quando o runner foi parado (mesmo padrao de
13/09, nao e falha do probe).

## Resultado

| Endereco | Linhas com o endereco 13/09 | 15/09 |
| --- | ---: | ---: |
| 5BB260 | 3496 | 0 |
| 5CD768 | 824 | 0 |
| 5CC940 | 238 | 356 |
| 5BB228 | 11 | 19 |
| 5BA3D8 | 22 | 27 |
| 5BA440 | 10 | 15 |
| 5BA338 | 7 | 12 |
| 37E4D0 | 1 | 2 |

(Contagem bruta de linhas que citam o endereco em stdout+stderr; serve para
comparar as duas rodadas, nao e contagem de chamadas.)

Avisos "not found" restantes nesta rodada: 5CC940 178 (todos RA42630C),
5BB228 9 (RA469EA8), 5BA3D8 9 (RA211690), 5BA338 6 (RA211890/20DCF8),
5BA440 5 (RA211690), 37E4D0 1 (RA37EA28). Nenhum "Called unimplemented".

- As duas entradas recuperadas sumiram dos avisos: ~4300 linhas -> 0.
- Estados do painel 1/41/40/37/40, final 40, titulo inativo, painel ativo,
  child 647 e membro 17788B0 flags591 com gate aberto — igual a 13/09.
- 4 capturas; terceira/quarta identicas em conteudo a 13/09: logo, PRESS START
  BUTTON, OK/BACK legiveis, faixas brancas no topo. Sem ganho visual, menu
  completo NAO aceito.
- Membro 17788B0 tem render=5CC940, que e exatamente o lookup ausente mais
  frequente agora (RA42630C). No ELF e `jr ra; nop`, logo recuperar nao deve
  mudar o desenho por si, mas remove o recovery do caminho de render do membro.

## Proximo

Recuperar 5CC940 e 5BA3D8 (ambos `jr ra; nop`) e 5BA338 (OR2 em this+6C) no
molde de Build-MenuPairEntries.ps1, com fixture OFF/ON antes do probe. 5BB228
depois; 5BA440 exige corpo completo. As faixas brancas nao vem desses lookups
(presentes antes e depois); investigar separadamente.
