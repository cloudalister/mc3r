# MC3 — prioridades de 10/09/2026

## Encerramento 09:46

Automação da madrugada pausada no primeiro disparo após o limite das 09:30.
Nenhum mc3_partial ativo encontrado; nenhuma janela encerrada, nenhum teste
novo iniciado. Próximo lote depende de nova direção de Cloud e mantém o alvo
abaixo: localizar onde uma superfície passa a ser desenhada incorretamente.


## Estado corrente 08:58 — rodadas encerradas; preparar próxima investigação

Última rodada terminou às 08:31 por timeout, sem novo erro de função ausente.
5cd758 executou mais de 16 mil vezes; 5e89f8 continua sem cobertura observada.
Correção STQ comprovada em teste e exercitada no jogo, mas faixas persistem.
Prioridade seguinte: captura numérica limitada de uma superfície defeituosa,
com origem do comando, vértices, STQ, textura e destino de desenho; distinguir
dados já errados de erro ao desenhar antes de alterar outro subsistema.
Hoje: fechar documentação/mapa e preservar fontes; sem nova rodada longa.
Limite continua 09:30, sem desligar PC. Ver RESUMO_MADRUGADA_2026-09-10.md.


## Estado corrente07:57

Folha5cd758 validadaate16384chamadas; semnovomissing em35min. Graficosruins.
STQtriangulo tinha interpolacao incorreta confirmada emteste discriminante;
correcao experimentalOFFporpadrao e329/329comgateON. Rodadavisual ate~08:31.
Proximo: inspecionar sequencia/coverage, concluirsemalegarFPS/geometriafixada.
DiscoEbaixo; backupsbinariospropriosrealocadoscomhash emC, verRESULT_STQ.
Nenhum novoexperimento deve ultrapassar09:30. Prepararresumo/mapa ao fim.


## Estado corrente06:53

Quiet control encontrou outro missing5cd758 e encerrouEXIT0; folha original
restaurada/testada. Captura limitada independenteBOOT_TRACE implementada,
testada e primeiraPNGconfirmada. Nova run ate07:25, nao duplicar/build.
Prioridade: confirmar cobertura das folhas e analisar sequencia visual;
so depois escolher grafico vs proximo missing. Detalhes no RESULT_LATE_CAPTURE.


## Estado corrente05:54

Rodada de pulsos terminou sem cobertura da folha; captura ainda titulo.
Controle quiet em curso ate06:24, mesmo exe/input/duracao, BOOT_TRACE0.
Nao esperar PNG nessa rodada: captura atual acoplada ao trace. Se tambem
inconclusiva, proximo investimento e captura periodica limitada independente
de trace, para enxergar estado final; nao repetir outra rodada cega.
Identificadores/proveniencia no topo PS2_PROJECT_STATE e RESULT_ENTRY.

## Estado corrente05:03 (itens anteriores abaixo sao historicos)

Cloud dormiu e autorizou continuar ate09:30. Atlasv4 publicado04:13.
Folha ausente5e89f8 restaurada fielmente e64testes PASS; exe novo verificado.
Rodada900s terminou por limite, sem cobertura da folha, captura de titulo.
Prioridade agora e obter cobertura/estado final com entrada observavel:
rodada1800s em curso ate05:32, Start30s apertado/30s solto, sem mudar runtime.
Ha bordas frontend e leituras guest confirmadas; nao presumir ausencia de
input. Analisar resultado/captura antes de nova sonda ou conclusao visual.
Leia topo PS2_PROJECT_STATE e RESULT_ENTRY_5E89F8 para identificadores atuais.


Estado: alinhamento e investigação leve antes de Cloud dormir, por volta de04h.
Cloud definiu término09:30 em10/09/2026, America/Sao_Paulo. Continuação
programada a partir de04h, após fim do teste manual, até esse limite.
Autorização de desligamento de09/09 não se repete automaticamente hoje.

Teste manual autorizado e lançado nesta sessão com o mesmo binário/gateON,
janela visível, BOOT_TRACE0 e sem Start automático. Enter=Start com janela
focada. Label manual_gs_bridge_20260910_0328,PID36624; logs/meta emwork/logs.
Não interromper teste manual ativo nem iniciar outra instância. Automação
existente atualizada para madrugada até09h30, intervalo20min; antes04h leve.

## Onde estamos, conferido nesta sessão

- Checkpoint mais recente: fechamento09/09 07:46, após rodada visual de10min.
- Exe/lib de hoje têm os mesmos SHA256 registrados no RESULT_GS_IRQ_BRIDGE.
  Exe43fda6a719efdbfd2e299ee3a4769bc999c30c0618e54fce885eb5c33a0b567f;
  liba21022d6fd98ab73480dd70851ffa949fd83431ef3a5ee66eacdf6cb7671527f.
- Correção experimental MC3_GS_IRQ_BRIDGE continua desligada por padrão.
  Controle comparável: mediana da espera866,77ms OFF versus8,625ms ON;
  produtores pareados passam de watchdog para notificação normal. Não é FPS.
-328/328 testes passaram em cada modo ontem; não reexecutados nesta sessão.
- Captura nova apenas logo/avisos já vistos. Nenhum menu/corrida confirmado.
- Nenhum mc3_partial rodando; automação anterior PAUSED. Alterações locais
  preservadas, inclusive arquivos ainda sem commit. Não resetar nem limpar.
- Atlas publicado ontem na versão3. Hoje solicitado reabrir ao lado; retorno
  do aplicativo foi queued, não prova de painel já visível. Sem nova publicação.

## Prioridade1 — descobrir até onde o jogo realmente chega

ATUALIZAÇÃO03:57: teste manual encerrou após clique relatado. Crash não
confirmado: stdout fecha janela/recursos; Thread Exit não prova crash; consulta
Windows limitada sem evento correspondente. Próximo harness deve capturar
exitcode do processo JOGO, não só helper. Não reproduzir clique por hipótese.

Checagem barata prioritária antes de nova sonda/build: chamada faltante5e89f8
vista no log com RA340250. Auditar corpo/limites reais e chamador. Fonte
vizinha5e8980 e seus aliases não comprovam corpo correspondente. Se causal
e simples, restaurar comportamento fiel com testes; senão manter separado
da investigação visual. Não dar retorno inventado ou adicionar alias cego.

ATUALIZAÇÃO03:52: após memory card, screenshot08 tem prefixo escuro
CREATE PRO...; possível criação de perfil. Não há marcador de log que
confirme. Primeiro identificar tela/seleção ativa e espera legítima por input,
antes de chamar permanência de travamento. Não confirmar opções às cegas,
formatar cartões ou alterar saves. Ver relatório visual atualizado.

ATUALIZAÇÃO03:47: print07 confirma tela CHECKING MEMORY CARD após repetidos
Enter relatados por Cloud. É um marco visual novo, não prova menu principal
funcional ou save válido. Observar conclusão da checagem e resposta do serviço
de cartão se necessário, preservando integralmente saves. Não formatar/apagar
cartões nem forçar sucesso. Continuar diagnóstico da deformação gráfica.

ATUALIZAÇÃO03:39: mesma execução avançou VISUALMENTE após o preto segundo
Cloud e três novas prints; predominam triângulos/faixas/superfícies deformadas.
Não pressupor parada global. Enter foi usado, resposta inconclusiva. Consultar
o topo de RESULT_TESTE_VISUAL_CLOUD para as5imagens e limites do relato.
Objetivo imediato: localizar origem da deformação, mantendo lentidão como
problema separado; não inferir causa em transformação/textura/buffer sem prova.

ATUALIZAÇÃO03:33: Cloud testou e relatou saída dos créditos, seguida de
fragmentos/glitches e preto persistente. Prints preservadas no relatório
RESULT_TESTE_VISUAL_CLOUD_2026-09-10.md. Prioridade passa a ser localizar a
primeira imagem inválida durante essa transição: produção dos dados,
renderização ou apresentação, sem presumir menu3D ou causa. Demora e
corrupção visual são dois sintomas; corrigir uma espera não valida os dois.

Pergunta: após corrigir a entrega de FINISH, qual etapa deixa de avançar
corretamente e onde o conteúdo visual fica inválido ou deixa de aparecer?

1. Reutilizar logs fechados, separar campos íntegros de linhas intercaladas.
   Montar uma linha do tempo: bootPhase, dono da execução, leituras de arquivos,
   trabalho gráfico e entrada. PC repetido sozinho não prova travamento.
2. Confirmar o ponto final visual. O dump atual em ps2_runtime.cpp é uma única
   tentativa por processo, depende de BOOT_TRACE e de limiar de primitivas;
   portanto a imagem inicial não mostra o resto da execução.
3. Se logs não bastarem, escolher UM diagnóstico: captura tardia usando opção
   existente quando adequada, ou captura periódica limitada e opt-in. Não
   prometer que um limiar de primitivas corresponde a minutos de parede.
4. Critério de saída: último marco confirmado, primeiro marco ausente e qual
   evidência distingue carregamento lento, espera ou imagem não apresentada.

## Prioridade2 — medir só o bloqueio restante

- Se leituras avançam, medir taxa/progresso e quem as aguarda; não alterar
  carregador só porque zipHandle::Read aparece numa amostra.
- Se espera pela vez de executar domina, identificar dono e seção responsável;
  não somar fases sobrepostas como se fossem tempo exclusivo.
- Se estado interno avança e imagem não muda, investigar apresentação.
- Só instrumentar o ramo sustentado pelos dados. Não reabrir a hipótese do
  alarme perdido já resolvida no alvo, nem otimizar rasterizador sem nova prova.

## Prioridade3 — correção pequena, somente com causa localizada

Preservar patch e novos arquivos antes da edição; uma hipótese por lote.
Gate reversível, testes dirigidos e suíte proporcional, build/relink com
hash/mtime/string verificados. Rodadas sequenciais equivalentes ON/OFF quando
necessárias. Sem sinalizar semáforo artificialmente ou encurtar watchdog.
Se causa continuar incerta, entregar diagnóstico localizado e próximo teste,
não uma alteração especulativa. Não habilitar experimental por padrão agora.

## Economia e comunicação

- Um subagente econômico, leitura limitada e pergunta concreta; agente principal
  integra resultados. Reutilizar o mesmo agente, sem equipe permanente.
- Scripts analisam logs; modelo recebe resumo e trechos pequenos. Sem releitura
  integral de históricos, recompilações por hábito ou testes simultâneos.
- Checkpoint por resultado, falha ou decisão. Site recebe marcos confirmados,
  não cada comando; percentuais do catálogo separados de jogabilidade.
- Autonomia futura restrita ao MC3: sem publicar código/assets do jogo, mexer
  em outros projetos, fechar apps alheios ou desligar PC por autorização antiga.

## Leituras leves desta sessão

Analyze-FrontendBoot no log visual fechado:363amostras íntegras de posição,
posição observada0;367amostras de VU, último197040648ciclos e0capHits;
nenhuma escrita FE reconhecida. Isso não comprova ausência total de transição:
campos podem estar inativos ou linhas intercaladas. Não é indicação para
alterar VU ou forçar a posição FE.

Auditoria limitada do final do stderr (6.122.325bytes), conferida pelo principal:
tick22140/pc4fe124,gsPrims2247048,gsPixels810823471,padReads0,
bootPhase=mc3intro; linha interrompida em frameDelta, não anexar campos de
outra amostra como se fossem dela. Frame íntegro anterior22080 tem
gsPrims2236176,introActive0,titleUpdateCalls0,canTransitionCalls0,
enterFrontendCalls1,setFrontendCalls2,guestPadReadCalls1640.
Logo há chamadas de entrada no frontend E leitura de controle; padReads0
sozinho NÃO significa que o guest nunca leu controle. O rótulo mc3intro não
prova que nenhuma transição ocorreu. Confirmar semântica/ordem desses marcos.
Contadores gráficos avançam; não prova menu novo. A primeira pergunta é
reconciliar os marcos de introdução/frontend com imagens tardias, não corrigir
controle ou declarar deadlock total. Não inferir falha a partir de zeros isolados.
