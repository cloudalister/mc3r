# Teste visual manual — Cloud — 10/09/2026

## Fechamento observado03:57 — crash ainda não confirmado

Cloud relata que tentou clicar e o programa fechou; suspeita de crash.
PID36624 ausente às03:57:39. Logstdout final atualizado03:57:06 termina com
unload de texturas/shader e INFO: Window closed successfully. stderr termina
com chamadas não implementadas5e89f8 e PS2 Thread Exit de várias threads.

NÃO classificar PS2 Thread Exit como falha fatal: Helpers/Runtime.h lança
essa exceção quando thread está terminated; também faz parte da parada.
run emps2_runtime.cpp:3501 reage a WindowShouldClose com requestStop.
Há sinais de cleanup, mas motivo que disparou saída não foi registrado com
BOOT_TRACE0. Não afirmar clique causou crash, nem provar saída saudável.
Sessão92321 saiu0: é o HELPER de lançamento, não exitcode do jogo.

Get-WinEvent indisponível por módulo PowerShell; fallback wevtutil consultou
Application,IDs1000/1001/1002,última1h,EventData exato mc3_partial.exe: nenhum
resultado,exit0. Ausência nesta consulta limitada não descarta falha.
Registrar exitcode real e motivo de saída no próximo harness controlado.

Pista concreta independente: chamada não implementada0x5e89f8,
ra0x340250,sp0x19f980,gp0x67f070,a0x016ddf40,hostTid2 repetida no final.
Register_functions tem5e8980/a4/b8/d4/e0 mas busca não encontrou5e89f8;
há fonte FUN_005e8980_0x5e8980.cpp. Não assumir que incluir alias resolverá:
verificar bytes/limites reais, semântica, chamador e retorno esperado primeiro.
Não relacionar ao clique, à corrupção gráfica ou à criação de perfil sem prova.

Teste manual terminou. Nenhum relançamento automático nesta resposta.
O lote após04h pode seguir sem conflito com essa janela, até09h30, conforme
autorização vigente. Preservar oito prints, logs e metadados; não tocar saves.

## Atualização03:52 — possível tela de criação de perfil após checagem

Cloud relata longa permanência na nova imagem e suspeita de limite/transição
após memory card. Print08 preservada sem alteração:
work/captures/manual_20260910_cloud_08_possible_profile.png.

Inspeção da imagem original mostra texto central muito escuro com prefixo
CREATE PRO..., além de fundo escuro/pontos luminosos e região inferior cinza.
Hipótese: interface de criação de perfil. Texto incompleto não confirma o
título inteiro, escolha selecionada ou qualquer criação/gravação de perfil.
Não classificar como mera textura, travamento ou menu funcional sem evidência.

A tela mudou desde CHECKING MEMORY CARD, mas isso não prova sucesso de uma
operação do cartão. Permanência numa interface pode ser espera por input,
não limite da execução. Enter entregue ao guest antes não prova navegação
ou capacidade de confirmar esta tela. Evitar confirmação às cegas e preservar
saves/cartões. Próximo diagnóstico: identificar tela ativa e seleção, separar
interface aguardando usuário de renderização ilegível ou execução bloqueada.

Processo36624 ainda Responding03:51:50,CPU1064,40625s; não prova avanço
interno. Auditoria limitada dos últimos64KB de cada log não achou marcador
de perfil/cartão ou erro/fatal que confirme essa hipótese; ausência nesse
recorte não é ausência global. Sem build, input injetado ou interrupção.

## Atualização03:47 — checagem de memory card visível

Cloud relata que pressionou Enter repetidamente e então apareceu a tela de
memory card. Print07 preservada em
work/captures/manual_20260910_cloud_07_memory_card.png. Texto parcialmente
legível inclui CHECKING MEMORY CARD; fundo ainda fragmentado/escuro. Não
completar palavras cortadas como se fossem integralmente legíveis.

Marco visual confirmado: chegou à interface de checagem do cartão nessa
mesma sessão, além dos frames ilegíveis. Associação temporal com Enter é
forte pista de resposta a input, mas sem teste controlado não prova causalidade
de cada tecla nem confirma que a tela anterior era o menu principal.
Não confirma leitura/gravação de save, existência/formatação de cartão ou
conclusão da checagem. Não declarar boot/gameplay resolvidos.

Processo36624 vivo/Responding às03:47, CPU850,65625s. Nenhuma interrupção,
nova execução ou alteração de runtime. Usuário orientado a aguardar sem
pressionar mais comandos durante a checagem. Não apagar, recriar ou formatar
cartões/saves na investigação; se surgir prompt de formatação, parar para
decisão do usuário. Autonomia do MC3 não é autorização para destruir saves.

Próxima observação: a checagem termina, apresenta erro ou muda de tela?
Se persistir, correlacionar com requisição/resposta real do serviço de cartão,
sem presumir que o texto de tela implica erro nesse serviço. A deformação
gráfica continua sendo um problema independente a localizar.

Auditoria limitada encontrou no stdout mc3-guest-pad-read read731,
data2=0xf7,data3=0xff,start1; uiinput-pad sample209,buttons00000800,start1.
Portanto há registro de Start entregue/consumido pelo pipeline guest nesta
sessão. Distinguir entrega de input (evidência) de tecla causar esta tela
(correlação temporal), e de save bem-sucedido (não demonstrado).

## Atualização03:46 — hipótese de menu principal já ativo

Cloud suspeita que a tela atual seja o menu principal com opções, atribuindo
subjetivamente75% de confiança. Registrar como hipótese do usuário, não
probabilidade medida nem aceite de menu funcional. Print06 preservada em
work/captures/manual_20260910_cloud_06_possible_menu.png: fundo escuro,
pontos luminosos, região inferior cinza e faixas horizontais claras/ciano;
nenhum texto/opção legível confirma a identidade da tela.

Compatível com hipótese de frontend ativo e desenho inválido, a testar por
estado de menu/seleção e resposta causal ao input. Contagens antigas de entrada
no frontend não provam o estado atual. Proposta de teste manual simples:
janela focada, seta para baixo, soltar e observar som/mudança; ausência de
resposta não prova falta de menu, pois input/latência seguem inconclusivos.
MapeamentoDown confirmado em Kernel/Stubs/Pad.cpp:146; Start=Enter:160.
PID36624 permanece ativo e Responding03:46. Não fechar nem reiniciar teste.

## Atualização03:39 — progresso visual após preto; deformação persiste

Cloud confirma que a mesma execução permaneceu aberta e avançou visualmente
depois do trecho preto relatado antes. Não tratar preto como estado final
permanente nem a execução como parada global. Isso NÃO mede ganho de velocidade
contra versão anterior, não comprova menu utilizável nem funcionamento de input.

Três novas prints preservadas sem alteração emwork/captures:
- manual_20260910_cloud_03.png: grandes faixas ciano/brancas e triângulos,
  com fragmentos menores sobre fundo preto.
- manual_20260910_cloud_04.png: faixa estreita acinzentada, pequenos elementos
  triangulares/brilhantes; maior parte da imagem preta.
- manual_20260910_cloud_05.png: grandes superfícies claras/coloridas esticadas
  e faixas atravessando a área exibida.

O usuário descreve geometrias quebradas. As imagens confirmam deformação/
corrupção visual, mas não localizam a origem entre vértices/transformação,
texturas/memória, desenho e apresentação. Não escolher uma correção só por
semelhança com sintomas de outro emulador.

Enter foi pressionado várias vezes; efeito inconclusivo devido à lentidão.
Não marcar input como funcionando nem quebrado. Logs e imagens não têm
sincronização quadro-a-quadro; horário desta nota é recebimento, não captura.

Checagem03:39: PID36624 ainda vivo, janela Responding=True,CPU439,875s,
stderr2994157bytes e atualizado. Comparado à checagem03:33, processo consumiu
CPU e gerou mais log; só o relato/imagens sustentam avanço VISUAL. Não há
nova rodada, build, mudança de código runtime ou interrupção do teste.

Foco noturno mantido: capturar primeiro quadro inválido e seus dados/estado
para separar origem da deformação; desempenho e correção visual são critérios
separados. Observar captura tardia é agora mais relevante que esperar apenas
por desaparecimento dos créditos. Horário final09h30 permanece.

## Evidência nova recebida03:33

Teste manual iniciado03:27:22, label manual_gs_bridge_20260910_0328.
Mesmo exe/lib do A/B anterior; metadados emwork/logs. GateGS_IRQ_BRIDGE1,
HEADLESS0,BOOT_TRACE0,PHASE_TIMING1, sem Start automático. Não é comparação
de desempenho direta com rodada headless ou com logging diferente.

Sequência relatada pelo usuário, tempos aproximados sem marcação automática:

1. Cerca de23s para a primeira tela aparecer.
2. Créditos/avisos Rockstar levam quase ou mais de3min para terminar.
3. A imagem muda para algo que o usuário associa à transição/animação de menu.
   Primeira print: quase preto, região triangular avermelhada com faixas na
   direita inferior e pequenos fragmentos. Não permite identificar cena3D.
4. Após longa espera, imagem some e aparece ponto azul; depois outros pontos
   e glitches/fragmentos descritos pelo usuário.
5. Retorna ao preto e permanece assim até o limite de paciência do usuário.

Prints fornecidas preservadas, sem alteração:
- work/captures/manual_20260910_cloud_01.png
- work/captures/manual_20260910_cloud_02.png

Na primeira mensagem não foram informados tempos exatos dos passos3–5 nem
resposta ao Enter. A atualização03:39 acima complementa e supera o preto final.
A hipótese de menu montado em3D é do usuário, ainda não comprovada por estas
imagens. Não registrar menu ou corrida desbloqueados.

## O que muda no diagnóstico

Há relato de saída dos créditos e mudança da imagem; portanto não tratar
captura legal inicial como ponto final da execução. Agora existem dois
sintomas relevantes: demora grande e imagem inválida/ausente após abertura.
Podem compartilhar causa, mas ainda não sabemos. A ponte FINISH corrigiu
uma espera; isso não valida o conteúdo gráfico produzido ou apresentado.

Verificação03:33: PID36624 ativo, janela Responding=True, CPUacumulada223,06s,
stderr continua sendo escrito. Isso prova processo/janela vivos, NÃO prova
avanço do guest, taxa de quadros ou ausência de deadlock interno.

## Próximo diagnóstico escolhido

Na transição, distinguir: (A) comandos/dados gráficos já chegam inválidos,
(B) desenho fica inválido ao transformar/rasterizar/texturizar, (C) desenho
válido existe num buffer, mas o buffer errado/limpo é apresentado, ou (D)
produção deixa de avançar. Sintomas não selecionam uma causa sozinhos.

Usar captura tardia/limitada com identificação de etapa e buffer, ligada a
uma pequena amostra íntegra de contadores. Comparar quadro apresentado e
buffers de contexto com suas configurações; contexto bruto entrelaçado não
é por si só defeito. Primeiro reconciliar evidência existente, depois UMA
sonda dirigida se faltar informação. Não mudar render/scheduler sem prova.

Até04h continua alinhamento leve. Não interromper teste manual do usuário.
Pergunta sobre Enter respondida parcialmente03:39: pressionado repetidamente,
mas efeito não discernível; permanece inconclusivo, não exigir novo teste agora.

## Leitura limitada do log ativo

Auditoria econômica dos últimos64KB encontrou chamadas mc3-camblend-ratio /
mc3-mathf-* e avisos de função não encontrada5bb268/5bb238; nenhum fatal
nesse recorte. Não significa ausência de erros no log inteiro. Sem marcos
completos de apresentação nesse trecho, a atividade não comprova cena válida.
Busca nos docs confirma que esses dois destinos JÁ eram candidatos não
corrigidos em06/09 (RESULT_LIST_ENTRY, RESULT_ENTRY_BATCH e CHECKPOINT_FIM_DO_DIA).
Logo não apresentar como descoberta nova ou causa comprovada dos glitches.
Auditar seus chamadores/retornos é uma checagem barata antes de nova sonda
gráfica; não inventar implementação nem substituir por stub.
# Atualizacao 10/09 04:22 - caminho interno de encerramento encontrado

O handler que imprime Called unimplemented function chama requestStop logo
depois (ps2_runtime.cpp:2207-2222). Os cinco erros finais da rodada manual
sao5e89f8. Isso explica como uma funcao ausente pode encerrar o runner com
cleanup normal; nao comprova crash do Windows nem causalidade do clique.
BOOT_TRACE0 nessa rodada impede discriminar o motivo final pelo marcador.
Folha original5e89f8 restaurada/testada isoladamente, validacao no jogo pendente.
