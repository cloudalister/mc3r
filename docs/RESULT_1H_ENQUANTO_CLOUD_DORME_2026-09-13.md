# Bloco de uma hora - MC3 - 2026-09-13

Periodo autorizado:09:49:30 ate10:49:30 America/Sao_Paulo.
Estado deste registro: investigacao e validacoes concluidas; fechamento10:38.
Bloco encerrado antes do limite de uma hora: outro probe de15min ultrapassaria
o prazo. Desligamento autorizado sera solicitado apos a preservacao abaixo.

## Resultado confirmado ate aqui

Primeiro teste conjunto de MC3_MENU_ENTRY_FIX e MC3_FRAME_HOST_CLOCK, ambos ON,
usando o mesmo executavel imutavel menu-entry. A captura apresentada numero3
mostra logo Midnight Club3 e PRESS START BUTTON legiveis, alem de OK/BACK.
Persistem faixas brancas e defeitos na imagem; menu seguinte jogavel nao confirmado.
Esta captura prova conteudo visivel nesta execucao, nao equivalencia visual com
PS2 nem ganho de desempenho. Camera/animacao variam; imagens em tempos distintos
nao sao comparacao pixel A/B. O estado guest e a captura nao sao atomicos.

Captura:<scratch-dir>/mc3-menu-combined-20260913/run/captures/present_menu_combined_20260913_a_3.png

## Teste combinado encerrado

- Inicio09:59:37; parada deliberada10:11:55 apos3 capturas e evidencia posterior
  a ativacao. PID47664 e leitor41528 conferidos por caminho/horario/recibo.
  Harness concluiu em741s, exit=-1 decorrente da parada; leitor exit1 por parada.
- Executavel SHA256:dfae148e105033eba268e398fe02f3a7ca0572ac4d67e26612c20ef60918a5e5.
  Biblioteca:ca699895bee6b3cf6907f4e75e37099a9c55d35aeac187cca87fa2586d1c6dd6.
  Bridge/STQ ON, depth OFF; headless; START30s pressionado/30s solto, atraso45s.
-118 amostras validas,95 com D8=40 e painel1725D50 ativo. D8=37 tambem observado.
  Final D8=40, titulo974/inativo, filho1725EA0 flags647 e membro17788B0 flags591
  com portas de desenho abertas. Nao repetir a investigacao dessas flags.
- Wrapper16D6710 +9 mudou naturalmente0->1. Movie177F230, header fps256=3840
  (15fps), acumulador passou a avancar. Antes da liberacao, estava0.0166666675.
  Delta final0.0399938971 e rawDelta7.269843; isso nao significa60fps reais.
- Artefatos completos em <scratch-dir>/mc3-menu-combined-20260913/run:
  meta, logs, receipt.json, stop.json, final_guest.json, analysis-transitions.json,
 118 snapshots e capturas. Probes anteriores preservados.

## Investigacao e verificacoes

1. MenuOptionScreen65AE24 passa por320848 ->20B198 ->20AFB0: propriedade tipada.
  320A88 ->20B1D0 consulta propriedade. Nao sao emissao visual direta.
2. Owner*(617980)+6B4 aponta wrapper;3212D0 instala3204A8;321208 grava byte+9.
  322FD8 chama320B38 comf12=-1. Combyte+9 ativo, usa618E54; caso contrario zero.
  20ACD0 acumula delta e executa20B538 a cada256/fps256 segundos.
3. Fixture tools/menu_animation_clock_tests.cpp compila20ACD0 real, substitui
   somente consumidores posteriores por contadores. A30fps:100 deltas7/65535
   geram0 passos;313 geram1;100 deltas1/60 geram50;100 deltas.0399939 geram119.
  53 anotacoes de instrucao conferidas com ELF. Nao testa renderizacao.
4. Emissor concreto:320638 instala callback70F1BC=3203B8 (pacotes de textura).
  210870/210DD0 ->2102A8 ->530208 configura os buffers de posicao/cor/UV;
  2101A0 escreve quatro vertices por quad usando matriz6B5250 e escala70F1B0/B4.
   Esse caminho e separado da animacao de predios. Sua execucao real ainda sera
   observada no probe diagnostico seguinte; nao basta o grafo estatico.
5. Observer diagnostico copiado2101A0:32 casos da rotina real conferem transformacao
   afim; versoes com/sem observador deixam contexto inteiro,32MB RAM e16KB scratch
   identicos.54 anotacoes conferidas no ELF. So leitura direta RAM/scratch e logs
   limitados a2048 registros; nenhum acesso MMIO ou escrita adicional guest.

## Alteracoes e limites

### Probe de vertices encerrado e novo bloqueio concreto

menu_vertex_20260913_a iniciou10:13:42 e terminou10:28:39, apos896.50s,
CPU801.73s, antes do cap1200s. O processo retornou0, mas NAO foi sucesso:
stderr registra "Error: Called unimplemented function at address0x5bb268",
RA0x22524c, a0=0x16b9880; cadeia final225698 ->225200 ->5BB268.
Leitor terminou com Read failed apos o processo fechar;178 amostras preservadas,
155 pos-ativacao; ultimo snapshot10:28:34,D8=40,titulo inativo, gates abertos.
Nao houve parada forcada deste runner. activeThreads=0 no encerramento runtime.

750 registros de vertices validos,33 linhas parciais/intercaladas rejeitadas;
ultimo ordinal2678784. Sem divergencias da formula afim ou dos incrementos dos
ponteiros. FaixaX44.258..984.498,Y-1025.276..886.124,Z0. Coordenadas fora da tela
nao foram consideradas defeito por si so (animacao/rolagem). Algumas amostras
tardias usam matrizes correspondentes a folhas de texto da arvore observada.
O limite2048 nao foi atingido; amostragem nao cobre todos os vertices.

Fixture530208+2101A0 -> VIF passou:4 vertices,cores eUV preservados, Q=1,
QWC14, callbacks MSCAL2 depois MSCAL0.182+54 anotacoes conferidas com ELF.
VU microcode/GS nao executados neste teste. Sem nova correcao grafica especulativa.

5BB268 foi encontrada dentro do bloco amplo5BAEF8, mas nao tem entrada propria
no registro nem trampolim de entrada naquele owner. ELF confirma exatamente
03E00008 (jr ra),24020002 (v0=2 no delay slot). Build-Leaf5BB268.ps1 prepara
copia do registro completo com esta unica entrada e objeto separado, usando
base menu-entry sem observer. Fontes/objetos/registro originais preservados.
Validacao e relink concluiram10:35:47. Tres chamadas pelo registro COMPLETO
com MC3_MENU_ENTRY_FIX OFF e ON (6 verificacoes) passaram:retorno2,RA correto,
demais campos do contexto preservados. Executavel pronto em:
<scratch-dir>/mc3-leaf-5bb268-20260913/bin/mc3_partial.exe
SHA256:a6f93b7e4305d67cd98a5086dcea1d2d13ea6ded3dbe881f4a72d2d890b0ed7a.
Biblioteca imutavel:ca699895bee6b3cf6907f4e75e37099a9c55d35aeac187cca87fa2586d1c6dd6.
Build-Leaf5BB268.ps1,mc3_leaf_5bb268.cpp e mc3_leaf_5bb268_tests.cpp preservam
a implementacao e sua reproducao. O registro alterado esta apenas na copia C:.
Nao sera possivel repetir o caminho de15 minutos antes do horario de fechamento.

Analyze-MenuState.js agora extrai missingFunctions explicitamente; validado
nos dois logs:zero no combinado anterior, uma5BB268 no probe de vertices.
Um exitCode0 do harness nao deve ser usado como prova de boot bem-sucedido.

### Caminho de desenho e arvore viva

320FD0 configura contexto ortografico e chama20AF38 ->20B5C0 ->20D420.
20D420 testa bit5 de instance+6C, percorre child+74/sibling+78 e, nas folhas,
chama (*(instance+4)->vtable+0C). Enderecos ELF:624974 ->20F208,
624A64 ->210DD0,624A94 ->210870. Registros relevantes terminam no owner
canonico;20EBF8 e retorno vazio real, com entrada explicita no owner20EBC8.
Nao repetir a hipotese de alias incorreto nesses enderecos sem evidencia nova.

Leitura10:25:48, arvore viva1E98F20:76 nos, fila esgotada, profundidade limitada8.
Todos com bit5 aberto:48 containers20EBF8,20 folhas20F208 e8 folhas210DD0.
Bits altos CDCD... preservados no dado: nao interpretar toda a palavra como
enum valido nem escrever zero nela. Sao flags parciais de objeto.

As oito folhas de texto usam chunks de12 bytes + proximo em+0C, a partir de
instance+48; essa estrutura foi confirmada pela rotina20EA20. Leitura10:27:44:
1E9B3A0 -> "Press START button"; outras7 folhas -> "OK"/"Back".
Definicoes+8/+C vazias sao fallbacks; o texto efetivo esta nos chunks da instancia.
Esses textos batem com a captura3 do segundo probe. A passagem de D8=40/37 nao
equivale, portanto, a uma tela de opcoes visivelmente aceita. O proximo alvo e
correlacionar propriedade MenuOptionScreen e timeline desta arvore com o desenho.

Read-MenuGuest.ps1 -UiTree agora coleta ate128 nos/depth8, no maximo43 chunks
por folha de texto, com limites de RDRAM e deteccao de repeticao. Somente leitura.
display_root.json, display_tree.json, display_tree_text.json e
display_tree_chunks.json estao no artefato do probe de vertices.

O pacote530208 contem UNPACKs e MSCAL2/MSCAL0; a classificacao generica do
documento antigo AUDIT_M4M5_RENDER sobre blits2D diretos nao prova esse caminho.
No runtime atual, os dumps MC3_VU1_INPUT_TRACE filtram entryPC0x60/imm12;
nao capturam automaticamente MSCAL2. Nao repetir aquele replay esperando este
pacote sem adaptar a selecao e preservar novo binario/configuracao.

Novos tools/Read-GuestRoutine.js, Test-MenuAnimationClock.ps1,
menu_animation_clock_tests.cpp, menu_vertex_observer.h,
menu_vertex_observer_tests.cpp, Build-MenuVertexProbe.ps1,
Analyze-MenuVertices.js, menu_vif_packet_tests.cpp, Test-MenuVifPacket.ps1
e Preserve-SleepBlock.js.
Read-MenuGuest.ps1 passa a coletar o relogio/pausa da interface.
Observer e inserido somente em copia do owner no artefato C:, com objeto e
executavel separados. Nao substituir fontes/objetos gerados ou executaveis antigos.
Nao houve patch adicional de comportamento do renderer. Ambos opt-ins anteriores
continuam OFF por padrao; nao promover para default sem aceitacao visual.

## Fechamento

Todos os probes encerrados; testes terminados. Automacao
mc3-concluir-1h-e-desligar PAUSADA e confirmada no arquivo local.
Preservacao antes do desligamento:fontes atuais e manifesto dos tres conjuntos
de artefatos em <scratch-dir>/mc3-sleep-block-20260913.
Audit-final do leaf confirma registro original identico a copia anterior,
executavel menu-entry anterior inalterado,uma unica entrada5BB268 e testes OFF/ON.
Sintaxe dos cinco scripts PowerShell e quatro ferramentas JS novas/alteradas
conferida. Nenhum runner,leitor ou compilador MC3 permanece ativo.
Autorizacao explicita de Cloud:shutdown.exe /s /t 0, sem /f.
Registro da tentativa: <scratch-dir>/mc3-sleep-block-20260913/shutdown-request.json.
O retorno do comando sera registrado separadamente se a sessao ainda estiver viva;
nenhum desses registros prova que a maquina fisicamente apagou.

## Retomada exata

Usar o executavel leaf5BB268 acima, com entry/host-clock/bridge/STQ ON e depth OFF,
em novo diretorio C: e novo label. Repetir por tempo suficiente para atravessar
o ponto~15min e verificar que5BB268 deixou de encerrar o jogo. Nao reutilizar
saidas nem reconstruir executaveis antigos. Nao promover flags para default.
Depois correlacionar MenuOptionScreen na timeline com320FD0 e a arvore1E98F20.
As faixas brancas permanecem; antes de alterar VU/GS, capturar seu pacote concreto
MSCAL2, pois o replay antigo filtrado em0x60 nao representa esse caminho.
Primeiro passo humano (<2min):abrir este relatorio e a captura3 preservada.
