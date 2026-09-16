# Duas ultimas entradas ausentes do menu + probe20min — 2026-09-15

## Build

tools/Build-MenuLast2Entries.ps1, fontes tools/mc3_menu_last2_entries.cpp e
tools/mc3_menu_last2_entries_tests.cpp. Bytes conferidos no ELF:

- 5BA440 `27bdfff0 ffbf0000 8c830008 8c62000c 0040f809 00000000 dfbf0000 03e00008 27bd0010`:
  wrapper de chamada virtual. JALR segue o molde do corpus gerado
  (FUN_00211660: lookupFunction, retorno se pc != ra esperado).
- 37E4D0 `3c020061 8c437adc 8c64000c 8c82000c 03e00008 a040021b`:
  cadeia 617ADC->+C->+C e zera byte +21B no delay slot.

Exe <scratch-dir>/mc3-menu-last2-20260915/bin/mc3_partial.exe
SHA dc0375b7029cc17a8137979c70371f650ded5e8bdd152445639802ce57c7ca66.
Prior leaf4 SHA c2ffba61... preservado; runtime ca699895... inalterado.
288 casos por configuracao OFF/ON PASS (12 entradas x 8 padroes x 3 cenarios),
incluindo chamada real via registry a callee de teste em 0x7000, alvo nulo,
ponteiros auto-referentes e escrita sobre o proprio ponteiro global.
Nota: primeira tentativa abortou no build por redirecionar stderr do rtk
(2>&1 com ErrorAction Stop); diretorio parcial removido e build refeito limpo.

## Probe

menu_last2_20260915_a, 07:09–07:29, mesmos parametros. 1202s, parado pelo
limite. 177 snapshots, 151 pos-ativacao, estados 1/41/40/37/40 (igual).
Leitor terminou com Read failed no fim (padrao conhecido).

**Zero avisos "not found", zero recover-pc, zero "Called unimplemented".**
Todas as entradas ausentes do caminho do menu observado estao recuperadas.

Capturas 3/4 iguais ao probe leaf4: logo no alto a esquerda, placa grande do
painel seguinte com video de fundo, OK/BACK, sem itens de menu. Faixas brancas
continuam na captura. Menu utilizavel NAO aceito.

## Conclusao e proximo

O bloqueio restante do menu nao e mais funcao ausente. Proximos: por que a
placa do painel nao desenha itens (estado 40 / gates abertos, render 5CC940 e
jr ra;nop legitimo, entao o desenho dos itens vem de outro caminho), placa
cortada na diagonal na janela ao vivo, e FPS baixo.
