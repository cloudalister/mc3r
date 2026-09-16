# Quatro entradas do menu recuperadas + probe20min — 2026-09-15

## Build

tools/Build-MenuLeaf4Entries.ps1 (molde de Build-MenuPairEntries.ps1), fontes
tools/mc3_menu_leaf4_entries.cpp e tools/mc3_menu_leaf4_entries_tests.cpp.
Bytes conferidos nos PT_LOAD do ELF antes do build:

| Entrada | ELF | Semantica |
| --- | --- | --- |
| 5CC940 | 03e00008 00000000 | jr ra; nop (render do membro 17788B0, RA42630C) |
| 5BA3D8 | 03e00008 00000000 | jr ra; nop (RA211690) |
| 5BA338 | 8c82006c 34420002 03e00008 ac82006c | lw v0,6C(a0); ori 2; sw no delay slot |
| 5BB228 | 8c820144 03e00008 c4400270 | lw v0,144(a0); lwc1 f0,270(v0) no delay slot |

Executavel <scratch-dir>/mc3-menu-leaf4-20260915/bin/mc3_partial.exe
SHA c2ffba612b9f01365d2b533bc188113106ec85aafdd3d09c011ab9e7746abf90.
Prior (menu-pair) SHA783551ac... preservado; runtime ca699895... inalterado.
240 casos por configuracao MC3_MENU_ENTRY_FIX OFF/ON, todos PASS: decodificador
independente (agora com nop/ori/sw), contexto inteiro e 32MB RAM, registradores
com metade alta nao-zero, bits float incluindo NaN/inf/subnormal e 0xFFFFFFFD,
ponteiros sobrepostos, regressao das seis entradas anteriores.

## Probe

menu_leaf4_20260915_a, 06:05:48–06:25:50, mesmos parametros dos probes de 13/09
e 15/09 05:28. 1202s, parado pelo limite, sem saida espontanea. 209 snapshots,
178 pos-ativacao, estados 1/41/40/37/40, final 40, gates abertos (igual).
Leitor terminou com Read failed quando o runner foi parado (padrao conhecido).

Avisos "not found": 5CC940 178 -> 0, 5BB228 9 -> 0, 5BA3D8 9 -> 0, 5BA338 6 -> 0.
Restam somente 5BA440 x7 (RA211690) e 37E4D0 x1 (RA37EA28).
Nenhum "Called unimplemented".

**Imagem mudou.** Capturas 3 e 4 (05:15 e 05:20 de jogo) nao mostram mais a tela
PRESS START: logo subiu para o canto superior esquerdo e aparece a placa grande
do painel seguinte, vazia, com OK/BACK. Nos probes anteriores as capturas 3/4
eram PRESS START. As duas capturas desta rodada sao iguais entre si, entao a
tela fica parada nessa pose: nao ha prova de menu utilizavel. Faixas brancas
continuam nas capturas (na janela ao vivo o usuario nao as ve; provavel
artefato da captura). Nao atribuir a mudanca a uma entrada especifica sem teste
controlado.

## Proximo

- 5BA440: wrapper de chamada virtual (addiu sp; sd ra; lw v1,8(a0);
  lw v0,C(v1); jalr v0; ld ra; jr ra; addiu sp). Precisa despacho real.
- 37E4D0: lui v0,61; lw v1,7ADC(v0); lw a0,C(v1); lw v0,C(a0); jr ra;
  sb zero,21B(v0).
- Separado: placa cortada na diagonal na janela ao vivo e FPS baixo.
