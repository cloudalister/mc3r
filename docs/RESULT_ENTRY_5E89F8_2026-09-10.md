# Restauração da entrada5e89f8 — 10/09/2026

## Nota de desenho05:56: captura futura sem novo latch

Subagente indicou APIs existentes de captura, mas afirmou erroneamente
independencia de BOOT_TRACE. Principal confirmou chamada LogBootTraceFrame
somente em if(bootTrace...)3437-3439. Nao reutilizar aquela conclusao.
Se necessario, hook opt-in em UploadFrame apos copyLatchedHostPresentationFrame
bem sucedido (1253+), usando scratch/dimensoes/FBs que ja vao para textura.
Isso captura o MESMO snapshot apresentado, sem novo latch/copiaGS e sem
contextFB. Gate por tempo monotonic/count max6, nenhum campo novo no ABI,
validar scheduler separado com testes e bytes/dimensoes antes de ExportImage.
Nao implementado nem compilado agora; quiet control segue rodando intacto.

## Atualizacao05:54: pulsos sem cobertura; controle de instrumentacao em curso

Pulse1800s terminou05:32:21 pelo limite (1802.926s/CPU838.9375s), sem marker
da folha ou erro unimplemented. Captura principal inspecionada: titulo MC3
legivel, nao perfil/menu confirmado. Ultimas observacoes4.609Mprims,
66title/frontendTicks,198UIupdates,2722guestPadReads; classificacao mc3intro
nao define sozinha tela real. Resultado nao prova que Start ou geometria
causaram o nao-alcance; apenas pulsos nao reproduziram caminho manual.

Auditoria headless: runtime1530-1539 apenas FLAG_WINDOW_HIDDEN; janela existe,
audio inicializado, mesmo upload/draw/latch no loop. Inputmanual nao recebe
foco, mas autoStart atua pelo latch normalmente. Sem condicao funcional
encontrada que explique diferenca alem de visibilidade/entrada.

Proximo controle: mesmo exe/lib,1800s,hold30/period30/delay45, GSbridge e
ENTRY_COPY_TRACE1, somente BOOT_TRACE passa1->0. Label quiet_20260910_0555
(prefixo entry_5e89f8_),inicio05:53:49,PID25788/session51904. Fim06:23:49.
Frame dump atual depende de BOOT_TRACE: nao esperar imagem desta run nem
usar ausencia como falha. Objetivo e cobertura da folha/novo erro com
instrumentacao pesada desativada. Resultado ainda pendente, sem alegar ganho.

## Atualizacao05:03: primeiro resultado inconclusivo para a folha

0426: timeout901.5s (04:40:33), CPU474.90625s, sem fechamento natural, exitCode
null porque o harness encerrou ao limite. Zero marcadores integros da folha
e zero erros Called unimplemented: ausencia de erro SEM coverage nao valida
correcao. Campos de frame intercalados: ultima observacao3.972529Mprims,
uiInputUpdates45, guestPadReads2750, title/frontendTicks15. Ha16marcadores
frontend-action-edge; nao afirmar que Start segurado impediu TODAS as bordas.

Captura principal inspecionada mostra logo/titulo MC3 legivel sobre padrao
escuro, nao memory card ou perfil. Dump foi perto da amostra1513517prims;
nao retrata fim da run. Contexto0 usaFB64 versus displayFB0, imagem fatiada;
comparar bases diferentes nao prova corrupcao do buffer apresentado.

Novo Analyze-EntryCoverage.js resume logs somente leitura com ressalvas de
interleaving. Subagente economico auditou Start; fonte faz ciclos hold+period,
e hold600000 anterior mantinha Start por10min. Falta de cobertura pode ser
tempo/estado/entrada; teste nao localizado ainda. Para aproximar apertar e
soltar, harness recebeu parametros dos knobs EXISTENTES, defaults intactos.

Run entry_5e89f8_pulse_20260910_0504 iniciou realmente05:02:18,1800s,
PID42852/session43420; mesmo exe/lib e flags, hold30s/solto30s/delay45s,
dump3500000prims. Nao e A/B de performance: duracao/captura diferentes e
sequencia manual original desconhecida. Teste de cobertura/entrada apenas.
Previsao de fechamento05:32:18. Sem alteracao do codigo do jogo nesta rodada.

## Atualizacao04:26: executavel validado; rodada de900s em andamento

Relink-Entry5e89f8 EXIT0; marker novo no exe e timestamps contra objetos/lib
PASS. Exe15b7251765cc562fe194d942a01db272397367b22209317e37cca8497d174c37;
lib inalterada a21022d6fd98ab73480dd70851ffa949fd83431ef3a5ee66eacdf6cb7671527f.
Probe entry_5e89f8_bridge_20260910_0426, sessao51516,900s, headless,
BOOT_TRACE1/GS_IRQ_BRIDGE1/ENTRY_COPY_TRACE1, dump a partir de1500000prims.
Usa Start automatizado existente (nao reproduz sequencia manual exata).
Captura unica pode preceder a funcao recuperada: checar ordem/coverage antes
de atribuir qualquer mudanca visual. Resultado/exitcode ainda PENDENTES.
Cloud confirmou que vai dormir; continuar ate09:30 sem desligar computador.

## Atualizacao04:22: registro verificado; motivo interno de parada identificado

Atualizacao04:24: tentativa inline subsequente passou -msse4.1 incorretamente
pelo PowerShell (argumento .1 separado); nenhum exe dessa tentativa foi usado.
Novo Relink-Entry5e89f8.ps1 usa array de flags, recompila registro e arquivo
de stubs, relinka e exige marker novo e mtimes contra os objetos. Execucao
de script usa Bypass somente no processo, sem mudar politica do Windows.
Sessao26932 chegou ao linker ld; aguardar exit0 e verificacoes finais.
Diff dos missing stubs e apenas comentario gerador/linha vazia (0 corpos),
mas foram recompilados por custo baixo para manter proveniencia direta.

Generate-PartialRegister terminou:15831 functions,168845 aliases,0 missing
stubs; Verify-Entry5e89f8 --register PASS. Compilando registro parcial; exe
ainda antigo. Primeira chamada direta g++ saiu1 sem diagnostico; repetida
com UCRT64/bin no PATH, como nos scripts existentes. Nao mascarar essa falha.

ps2_runtime.cpp:2207-2222 registra o erro exato de funcao nao implementada e
chama requestStop(). requestStop:3334 seta flag/notifica; loop testa parada e
faz cleanup, destructor fecha janela. Cinco erros5e89f8 ao fim da rodada
manual oferecem explicacao concreta de parada solicitada pelo runtime.
BOOT_TRACE estava0: sem marcador final separando clique/window-close de stop.
Portanto nao e prova de crash do Windows nem de que clicar causou a parada.
Proxima rodada com BOOT_TRACE1 e captura do exitcode real.

## Estado04:16: implementação e64testes isolados passaram; relink pendente

Autorização: lote até09h30, RTK, exatamente um subagente econômico reutilizado
para investigação. Principal implementa/valida, preservando alterações alheias.
Não há jogo rodando. Manual anterior fechou; crash não foi confirmado.

Backup antes de editar: work/patches/legal_phase_baseline_20260910_040727.
Inclui exe/lib, diffs, fonteowner/registros, cópias explícitas GS headers e
registro parcial/object/rsp. Objetoowner antigo não copiado separadamente;
para rollback recompilar fonteowner preservada e restaurar par exe/registro.

## Evidência original

Subagente extraiu5palavras via ELF32 LE/PT_LOAD (offset80,VA1a0000);
VA5e89f8 mapeia para offset448a78. Verificador independente falha se bytes
ou anotações divergirem do ELF. Palavras:

    5e89f8 78820330  lq v0,330(a0)
    5e89fc 7cc20000  sq v0,0(a2)
    5e8a00 78830340  lq v1,340(a0)
    5e8a04 03e00008  jr ra
    5e8a08 7ce30000  sq v1,0(a3) [delay slot]

Principal confirmou LQ=1e/SQ=1f em instructions.h e code_generator1524.
Não são instruções VU; modificam128bits de v0/v1. A primeira avaliação do
subagente não decodificou isso; não reutilizar aquela incerteza como semântica.
Função anterior termina jrra5e89f0/ajusteSP5e89f4. Entrada faltante é OUTRO
corpo, implementado sob label próprio no mesmo TU para reutilizar objeto.
Não é redirecionamento para prologue5e8980 nem retorno inventado.

## Mudança e testes

FUN_005e8980 recebe case5e89f8 e corpo separado fiel às5instruções. a1 não
é usado; v0/v1 são alterados; GPRs restantes preservados. Dois stores de16bytes
na ordem original. Segundo load ocorre APÓS primeiro store, importante para
buffers que se sobrepõem. Delay slot grava segundo bloco antes de retornarRA.
MC3_ENTRY_COPY_TRACE=1 opcional registra primeiras4chamadas e potências2,
sem modificar dados. Harness ganhou TraceEntryCopy; default diagnósticoOFF.

Verify-Entry5e89f8 compara palavras contraELF, comentáriosowner e case; após
geração também checa registro parcial. Test-Entry5e89f8 compila owner REAL e
executa64casos: dados128bits, sobreposição com segunda fonte, destinos iguais,
self-copy, memória inteira, GPRs, SP/RA e delay-slot. Caminho vizinho tem
sentinela abort somente no binário de teste, nunca no jogo. PASS antes/depois
da sonda. Não é teste de quadro final nem demonstração de melhoria de FPS.

## Chamador e limites

Em340248, chamada indireta de[s0+bc], com a2=sp+10,a3=sp,RA340250.
Leituras340394..39c consomem primeiro vetor;3403a0..3d4 fazem subtrações/
escala e3403f4..400 gravam saída[s1]. Ligação estática com cálculos de
componentes/transformação é plausível; efeito real dos glitches não provado.
Próximo: registro parcial, relink verificável, rodada controlada mostrando
execução real do corpo e observação visual. Ausência de warning sozinha
não comprova cobertura: usar marcador de chamadas completadas.

## Atlas

Versão4 publicada privadamente às04:13:06, deployment succeeded:
appgdep_6aa25867f0e8819181c4c275268a443f.
Fonte e82b60f567ad06e86b20d3a2e4e701812d758eed. Conteúdo: memória-card
visível e Start recebido, perfil hipotético, gráficos ruins/crash não confirmado.
Catálogo intacto; sem assets/código do jogo publicados. Build nativo existente
e check catálogo passaram. Wrappers novos de build/package falharam por
resolução npm/bash no Windows; usados npm run build e packager fornecido
via caminho absoluto MSYS, sem instalar dependências ou alterar plugin.
Handoff do painel solicitado; app respondeu queued, não prova refresh visual.
