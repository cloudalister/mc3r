# Transicao observada continuamente - 2026-09-13 09:11

## Resultado confirmado

Objetivo desta etapa concluido: capturar o filho DEPOIS da ativacao do painel40.
40 amostras validas, zero rejeitadas pelo analisador;21 com D8=40 e painel ativo.
Nao houve correcao nova no renderer nem melhora visual aceita.

Sequencia capturada em menu_transition_20260913_a:

- sample16: node368=0,counter42D=10,titulo ativo,D8=41.
- sample17/18: node368=6,pedidoE0=40,atualD8=41.
- sample19 (09:09:20): titulo inativo,D8=40,painel1725D50 ativo;
  filho1725EA0 flags135->647, bits0+9 abertos, group58=1.
- sample29: D8=37, confirmado tambem no read-only post_activation.json09:10:09.
- sample30..40: voltaD8=40; ultimo grupo tem membro17788B0 flags591,
  gate aberto, node368=0,counter10. final_guest.json confirma novamente.

O filho do painel nao fica permanentemente bloqueado pelas flags. Seu unico
membro nesta lista tem vtable631BA8/metodo28=5CC940 (retorno vazio no codigo
gerado). A abertura das flags nao prova emissao de comandos GS. Procurar a rota
visual efetiva, sem forcar essas flags ou substituir metodo vazio por desenho.
O ciclo40->37->40 ocorreu com START periodico. Nao foi isolada a causa da volta;
nao declarar regressao nem assumir que foi exclusivamente o START.

## Identidade dos recursos - correcao importante da investigacao

O ADDIU estende o sinal dos16 bits inferiores. LUI0x66 + ADDIU0xAE24 produz
0x65AE24, nao0x66AE24. Os enderecos66... citados em notas anteriores estavam
errados como referencias de recursos; aqueles dumps permanecem historicos.

Audit-MenuVtable.js agora verifica as quatro instrucoes no ELF que constroem
os enderecos MemCard/MenuOptionScreen antes de ler os nomes:

-37E0A0=3C050066,37E0A8=24A5ACEC ->65ACEC="MemCard".
  Usado por construtor37E070 do painel62BDE0 para criar componente via574518.
-37ED5C=3C050066,37ED64=24A5AE24 ->65AE24="MenuOptionScreen".
  Referenciado por Update37EC18 no caminho de estado37.
-65ACFC="KB_EnterSaveName",65AE35="savegamescreen",65AE44="showbar".

Isso identifica recursos de memoria/menu de opcoes no fluxo. Nao comprova uma
tela de opcoes visualmente legivel, perfil criado ou save realizado.

Tambem foi rejeitada a hipotese de gate extra node364==10:340990 carrega
imediato10 antes de340994 comparar42D. A leitura364 esta no delay slot do
branch-likely TOMADO se42D!=10, nao e outra comparacao.

## Instrumentacao e validacao

Read-MenuGuest.ps1 -WatchSeconds900: identidade PID/caminho/start ticks/hash
verificada uma vez, handle read/query apenas, localizacao RAM por duas
assinaturas ELF, leitura a cada2s e JSON novo apenas se estado/grupo mudar.
Percurso de grupos limitado a64 links; snapshots nao atomicos. O observador
nao altera input, flags, memoria guest ou arquivos de save.
Sintaxe PowerShell passou e o observador foi validado em processo real.
Analyze-MenuTransitions.js distingue E0 pedido/D8 atual e exige painel ativo
para classificar coleta posterior a ativacao;40 arquivos reais analisados.
Biblioteca/executavel nao recompilados nem relinkados; suite331 anterior nao
foi repetida porque esta etapa alterou apenas ferramentas de observacao.

## Execucao encerrada e artefatos

Executavel imutavel mc3-menu-entry-20260913/bin/mc3_partial.exe:
dfae148e105033eba268e398fe02f3a7ca0572ac4d67e26612c20ef60918a5e5.
Entry/bridge/STQ ON; host clock/depth OFF; START30s/30s apos45s; headless.
Cap960s; encerramento deliberado apos evidencia,803.049s no recibo,
806.261s no fechamento do harness, CPU727.406s. Exit-1 deliberado.
Reader56660 e runner60308 encerrados com identidade verificada;
as duas sessoes finalizaram e ausencia de runner foi confirmada.
Captura3 ainda mostra cena escura/geometria corrompida, sem UI legivel.

<scratch-dir>/mc3-menu-transition-20260913/run:
transitions/sample_0001..0040.json,analysis-transitions.json,post_activation.json,
final_guest.json,receipt.json,stop.json,audit-final.json,logs,captures e fontes.
Preservar junto aos artefatos anteriores; nenhum original E foi sobrescrito.

Proximo alvo: localizar o emissor visual de MemCard/MenuOptionScreen e seguir
seus comandos ate GS. A investigacao de gate pai/filho desta rota esta resolvida;
nao repetir outro boot longo apenas para provar flags abertas.
