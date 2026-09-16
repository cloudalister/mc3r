# Menu: titulo ativo, relogio zerado e experimento isolado

## Resultado confirmado antes do experimento

Cloud esclareceu que a cena e uma animacao dentro do jogo, com cameras e
predios. Capturas em fases diferentes nao sao um A/B visual. O menu utilizavel
ainda nao foi confirmado; a captura 3 conserva as faixas brancas.

O observador procurava a vtable errada: 62AA70. O construtor retail 362F60
grava 62AA68, e o Update esta no slot24. Corrigimos somente o observador e
adicionamos flags e contador de entrada no manipulador de mensagens. Teste
do ELF e suite331/331 com BOOT_TRACE OFF/ON passaram. titleObj=0 nos logs do
observador anterior nao prova ausencia do titulo.

Probe A foi encerrado deliberadamente apos320s para corrigir esse observador.
Probe B executou716.526s,CPU626.906s, de06:54:32 a07:06:29,PID52252.
O exit-1 foi nosso encerramento documentado, nao um crash. Tres capturas.
Configuracao: headless, bridge/STQ ON, depth OFF, START30s pressionado/30s
solto apos45s, BOOT_TRACE/FE_WRITE/PHASE_TIMING ON, sondas graficas OFF.

Ultimo frame integro:tick38520,prims5365671,title17261a0,flags975,Update150,
mensagens79,input150,StartPublishes465,gsState7,queuecount0,title130=0.0325818,
frameDelta=0.000106813. fe6AC chegou a-1: a camera pode terminar sem liberar
o titulo. Contador de mensagens nao identifica sozinho o codigo da mensagem
nem prova que START foi aceito. Filtramos127frames e rejeitamos440 corrompidos
por intercalacao de stdout/stderr; nao misturamos campos de linhas distintas.

## Leitura direta e caminho causal

Read-MenuGuest.ps1 usa somente OpenProcess READ/QUERY e ReadProcessMemory,
confere PID/caminho/inicio do probe e duas assinaturas de32bytes do ELF para
identificar RDRAM. Nao suspende, anexa debugger nem escreve memoria. Amostras
separadas nao sao snapshot atomico. Leu apenas campos do convidado.

Duas amostras,07:03:55 e07:06:12: titulo+F8=0, titulo+FC=16ddf40,
node+368=5, panel1702f50/state1, rawDelta618E58=0, savedCount6D6C88=0,
deltaMin=.0001,deltaMax=.04,timeScale1. Timers do titulo continuaram crescendo
lentamente. Essas amostras estao em run_b/live_guest_1.json e live_guest_2.json.

- Handler3630B0 exige flags&1 e mensagemC0000BB8/C0000BCC; chama slotB8.
- SlotB8=380AD8 exige titulo+F8==0 e chama587DC0(titulo+FC).
- 587DC0 retorna node+368==0. O valor5 observado bloqueia essa condicao.
- Aceitando,363118 chama339DA8 com estado40. Nao forcamos essa chamada.
- Update363320 acumula618E20 em130; depois30s tenta outra transicao, sujeita
  a3224F8. Nao confundir esse caminho automatico com aceitação de START.

433490 calcula o delta a partir de COP0 Count em4334B4, subtrai o valor salvo
em6D6C88 e multiplica por float31690453 (~1/294912000). Ha clamp, quantizacao,
escala e modos de replay antes da publicacao618E20. O runtime declara Count
mas nao o avanca. A anotacao historica ja descrevia essa falta; agora temos
rawDelta0 medido e reproducao do valor exato na propria rotina gerada.

Fixture frame_clock_tests.cpp executa433490 com campos controlados, isolando
somente hooks de gravacao/replay. Count parado produz7/65535=0.000106813;
Count+4915200 produz0.0166629;100ms sao limitados a0.0399939 pelo codigo retail.
Nao alteramos constantes, limite, fila, flags ou estado do titulo para esse teste.

## Experimento concluido: relogio avanca, menu ainda bloqueado

MC3_FRAME_HOST_CLOCK e OFF por padrao. Somente as leituras Count em433490 e
433AE0 usam um relogio steady_clock compartilhado quando a opcao esta ON.
Preserva modulo32bits e taxa derivada da constante retail. Nao modifica
ctx->cop0_count nem outras leituras COP0. E um experimento de tempo de frame
baseado no host, nao emulacao completa/ciclo-exata de CPU ou correcao aceita.

Dois objetos novos ficam em C:, substituidos apenas na resposta de link da
copia experimental; os objetos e executavel originais em E: permanecem intactos.
300/16 instrucoes anotadas conferem com ELF. Fixture OFF/ON passou;331/331
testes gerais OFF/ON passaram. Novos campos passivos:rawDelta,savedCount,
titleF8,titleNode,titleNode368.

Probe frame_clock_20260913_a iniciado07:09:36,PID47864,session24961,cap900s.
Encerrado deliberadamente07:16:22 apos405.730s,CPU356.172s;exit-1documentado,
duas capturas. Mesma configuracao deB, com MC3_FRAME_HOST_CLOCK=1.
Ultimo frame integro tick20940/prims2555960: title130=1.53643,Update39,
frameDelta=.0399939,rawDelta13.9703,savedCount2784172094,node3685,F8=0,
mensagens20. O relogio e o acumulador avancaram; nao liberaram o menu.
Os quadros mudam com a animacao; nao representam um A/B visual exato.

Leitura direta07:13:22: node16ddf40/vtable628878/flags975,estado368=5,
byte42D=0,42C=0. A tabela retail652BF0[5] aponta34098C, que exige42D==10
para zerar368 em3409A0. Update33FEB0 deveria incrementar42D inclusive de0
para1 (beq em340060 vai340080, NAO pula o incremento).

Seguimento: o teste com registro realmente compilado confirmou que33FEB0
estava sobrescrito por sub33FD80, cuja entrada nao despacha33FEB0. A rotina
Render3404D0 termina corretamente registrada apesar de sobrescritas
intermediarias no fonte. Ver RESULT_MENU_ENTRY_2026-09-13.md. Nao atribuir
o estado5 exclusivamente ao relogio. Experimento de relogio permanece OFF.

## Artefatos e identidade

Base: <scratch-dir>/mc3-menu-20260913

- B exe32be831f6a6eef95e7327f45c2f8a756a16b8228d186ae599c01613de5c0a75d
- B lib1241189183ddd1191a395bb1743b8a192616b0162eb1de21408a316ae7cc13a3
- B run_b/analysis_final.json, logs/meta/result/stop e capturas preservados.

Experimento: <scratch-dir>/mc3-frame-clock-20260913

- Exe611a77f851ce95b712d313b3ad23cf0678343a2f739d9179349920662d637c21
- Lib8dc5c770d00b7f74d53ad14bd0707f87b54c012a73d5d5c2118c373d4f6b97bd
- bin/VERIFIED.json, tests/PASS_clock.json, baseline/ e obj/ preservados.
- baseline/ps2_runtime.cpp e o observadorB anterior aos novos campos.

Rollback: deixar MC3_FRAME_HOST_CLOCK ausente ou0. Nao houve janela visivel,
edicao de save, salto de intro, commit ou publicacao.
