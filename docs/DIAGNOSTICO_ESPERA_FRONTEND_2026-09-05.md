# Proxima investigacao: demora entre atualizacoes reais

Adendo: a sonda de atribuicao de espera ao dono foi implementada posteriormente
no runtime54a3c97. Resultado e limites em `RESULT_WAIT_OWNERS_2026-09-05.md`.
O estado da entrega abaixo descreve esta auditoria inicial, antes dessa implementacao.

Auditoria apos o teste manual de Cloud, 2026-09-05, aproximadamente22:54.
Somente leitura do runtime/gerados/logs; nenhuma mudanca de comportamento,
build ou novo jogo iniciado. Um investigador economico revisou as fronteiras.

## Evidencias atuais

- Cloud relata que a versao corrigida permanece extremamente lenta.
- `work/logs/manual_20260905_224727.stdout` registra START recebido nos reads43/44,
  inclusive no consumidor ioPad (`start=1`). Nao prova resposta visual ou menu,
  mas confirma que esse input chegou ao guest. O log termina com janela fechada;
  nenhum processo MC3 estava ativo na consulta. `PS2 Thread Exit` durante esse
  encerramento nao foi tratado como prova de crash espontaneo.
- Ultimo bloco completo da rodada controlada TOP-fixed: raster34930ms,
  guest899027ms, guestWait401630ms, guestExec497271ms, VU51978ms, VIF77843ms.
  Parede901.5107757s, CPU agregada426.359375s. Contadores sao snapshots, nao
  necessariamente coletados no mesmo instante do encerramento do processo.
- IMPORTANTE: `addGuestSplit` fica em `PS2Runtime::dispatchLoop`, chamado pelo
  GameThread em `run()`. A busca no runtime encontrou essa unica chamada do
  dispatchLoop. Nao chamar esses totais de soma da execucao de todas as sete
  threads. O intervalo wait mede aquisicao do GuestExecutionScope antes de fn;
  exec mede parede dentro de fn, incluindo possiveis bloqueios internos.
- Os401.630s sao uma pista direta de espera da execucao principal, NAO prova
  de defeito do scheduler nem de quem reteve o token. Nao somar VIF+VU+raster:
  os escopos sao inclusivos e o raster global pode incluir outros caminhos.

## Por que os traces existentes nao atribuem essa espera

`guestexec-wait/got` em ps2_runtime.cpp fica na REAQUISICAO depois de liberar
temporariamente o token. Nao cobre integralmente a aquisicao inicial que alimenta
guestWaitMs. Contar essas mensagens ou ordenar donos por frequencia nao explica
os401s: faltam duracoes e cobertura, e ha intercalacao de linhas entre threads.

## Fronteira concreta para a proxima sonda

Owner: `work/generated/native_analyzer/sub_001A23A8_0x1a23a8.cpp`.
PC1a2720 chama1a32b0 com retorno1a2728. Medir apenas essa chamada mede UMA etapa;
o ciclo completo deve ser medido de uma passagem1a2720 ate a proxima, incluindo
o trabalho posterior e esperas. O hook precisa sobreviver a retornos ao dispatcher
e filtrar contexto/thread/objeto; nao confundir retorno C++ com retorno guest.
O lookup global nao recebe o contexto e nao captura o fallback direto: preferir
marcas passivas no owner, preservando instrucoes guest e os destinos existentes.

Coletar no mesmo intervalo, de forma opt-in e limitada:

1. Parede por ciclo e por etapa1a32b0; nunca chamar host tick de quadro do jogo.
2. CPU da thread principal e processo (se disponivel); deltas dos contadores
   VIF/VU/raster com rotulos inclusivos, e contagem de Updates/primitivas.
3. Duracao da aquisicao inicial do token versus reaquisoes e retencoes por dono.
   Apenas medir; nao alterar mutex, ordem de locks, timers ou scheduler.
4. Se a espera se concentrar no caminho GS, medir separadamente a espera e o
   trabalho sob m_stateMutex na apresentacao e no processamento de pacotes.

Outro consumidor confirmado do mutex GS: UploadFrame chama latch/copy na thread
da janela. latchHostPresentationFrame e copyLatchedHostPresentationFrame usam
m_stateMutex, assim como processGIFPacket. Existe compartilhamento real, mas
ainda NAO ha duracao que autorize atribuir a lentidao a essa disputa.

## Ajuda humana util

Cloud pode enviar uma captura ou video curto dizendo o que aparece e se muda ao
pressionar Enter. Isso distingue imagem congelada/preta de animacao muito lenta;
nao substitui os cronometros nem exige ferramentas tecnicas do usuario.

## Estado da entrega

Fronteiras e lacunas identificadas; a nova sonda por ciclo AINDA NAO foi implementada
ou executada. Nao ha novo ganho, causa unica ou menu aceito neste lote. Continuar
com um experimento pequeno de atribuicao antes de escolher outro conserto.
