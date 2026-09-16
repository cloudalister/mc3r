# Duas entradas recuperadas — 22:39

5BB260 e 5CD768 implementadas em tools/mc3_menu_pair_entries.cpp.
Oito opcodes conferidos diretamente nos segmentos PT_LOAD do ELF antes do build.
5BB260 retorna a0+0x30 com wrap32 e extensao de sinal, em delay slot.
5CD768 carrega float667384 uma vez em f1, grava a1+4, copia bits para f0,
retorna gravando a1 no delay slot. Sem aritmetica float.

Build-MenuPairEntries.ps1 produziu variante isolada:
<scratch-dir>/mc3-menu-pair-20260913/bin/mc3_partial.exe
SHA256783551ac50f250c10c088eebf09683f6cd8a30796c164376fef71c7906bcb4b6.
Runtime SHAca699895bee6b3cf6907f4e75e37099a9c55d35aeac187cca87fa2586d1c6dd6.
Prior menu-missing exe SHA719502b45720a33d3e1299359d55db4ea439e77aa3c0cb70af25b4102573ec4e preservado.
Registro copiado inclui duas novas entradas e as quatro recuperadas anteriormente.
Respostas de link referenciam objetos anteriores imutaveis; preservar diretorios
menu-missing e leaf-5bb268 junto do novo artefato para reprodutibilidade.

## Validacao

126 casos por configuracao MC3_MENU_ENTRY_FIX OFF/ON:252 PASS.
Comparacao com decodificador restrito de instrucoes, contexto inteiro e32MB RAM.
Seis entradas, sete padroes float, tres cenarios por entrada. Inclui regressao
das quatro entradas anteriores, NaN quiet/signaling, infinito, subnormal, zero
negativo; bases que cruzam limite de sinal e wrap32 em5BB260; a1 sobreposto ao
global ou global-4 em5CD768; RA e delay slots.
Sem runner ativo durante compilacao; nao houve erro de build/teste.
Arquivos .stdout/.stderr e VERIFIED.json em diretorio da variante.

Nenhum novo teste dentro do jogo executado neste bloco. Os4336 avisos da rodada
anterior incluem3284 de5BB260 e781 de5CD768, mas lookup nao prova chamada efetiva.
A reducao desses avisos e qualquer efeito visual precisam de nova execucao.
Menu completo ainda pendente. Proximo passo: probe comparavel20min com capturas
e leitor de memoria, usando novo exe, entry/host-clock/bridge/STQ ON, depth OFF.
