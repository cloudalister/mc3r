# MC3 - pausa solicitada por Cloud, 2026-09-06 08:09

Trabalho encerrado por hoje. Retomar somente quando Cloud pedir.
Nenhum mc3_partial em execucao na verificacao final. Nenhum monitor agendado.
Nao abrir jogo automaticamente ao ler este checkpoint.

## Resumo da sessao

O jogo ainda nao foi aceito como jogavel. Fizemos restauracoes limitadas de
entradas ausentes e depois separamos problemas de espera por medicao.
Nao ha ganho de FPS, menu ou corrida comprovados nesta entrega.

### Codigo restaurado e validado

- 2300d0: retorno exato jr ra/nop, registro e relink. Relatorio:
  RESULT_VERIFIED_LEAF_2026-09-06.md; commit raiz5ef8507.
- 5c3a48: retorno com ZERO na instrucao de delay, nao um NOP generico.
  RESULT_ZERO_RETURN_2026-09-06.md;719af85.
- 5b94f0/5b94f8/5b9990/5b9998: quatro retornos exatos.501268/5012c0/42bf00:
  entradas reconectadas a corpos existentes. RESULT_ENTRY_BATCH_2026-09-06.md;
  c474611.322 testes gerais +11 casos nativos naquela etapa.
- 42b150: corpo de29 instrucoes, comparado com ELF em24 casos e dois caminhos
  reais do chamador42bf00.37 casos nativos totais naquela bateria.
  RESULT_LIST_ENTRY_2026-09-06.md;c488be9. Foi exercitado85 vezes numa rodada
  posterior e67 na ultima; rodada com contador0 nao vale como aceite.
- Destinos5bb238/5bb268 continuam candidatos independentes, NAO corrigidos.
  Nao confundir com a investigacao do relogio e nao usar retornos genericos.

### O que as sondas separaram

1. Espera inicial: centenas de segundos ANTES do sinal. Na ultima rodada foram
   257,446s, mas recuperar a permissao de executar levou apenas0,1693ms.
   O relogio continuava avancando durante essa espera. Produtor ainda em aberto.
2. Retomada dos alarmes curtos: contencao pela permissao compartilhada de
   execucao confirmada em outra rodada, ate769,211ms.34 esperas completas
   somaram9,147s, com8,070s nessa etapa. NAO explica os601s inteiros.
3. Alarme armado sem callback: rodada sema_latency terminou com SID22,
   alarme0703e019,122,5s esperando. Rota real e Timer2 guest, NAO SetAlarm host.
4. Ultima rodada: tick25856 do worker de interrupcoes nao termina por pelo
   menos153,882s.24 snapshots repetem cause11,pc/lastLookup54cc08,ageMs0.
   O codigo percorre uma lista, cede e retoma. Ciclo/corrupcao NAO provados.
   Os dois alarmes curtos dessa rodada completaram; a espera final e OUTRA:
   SID43/RA529790,dispatch1a2728. Nao generalizar para todos os boots.

Relatorios detalhados, com hashes, comandos e ressalvas:

- RESULT_TIMER_WAIT_2026-09-06.md (17d382c)
- RESULT_SEMA_LATENCY_2026-09-06.md (4c06318)
- RESULT_IRQ_PROGRESS_2026-09-06.md (b7565eb)

## Estado exato deixado

- Raiz antes deste fechamento:b7565eb; submodulo PS2Recomp:8f580b6.
- 324/324 testes passaram na ultima execucao, depois do link terminar.
- Exe medido:work/link/partial/mc3_partial.exe.
- SHA256 exe:4ac3c3408afe9aa05d9a222e29b4f052c7c73f30f803fa7480f790759f8290d1.
- SHA256 lib:0b95748db0dcb0d7170a0ef1887d95cdd824b5ae73e44e7a20f78d3bb3ee67e6.
- Ultima rodada:irq_progress_astra_20260906,601,3939244s; final08:03:57.
- Logs:work/logs/probe_irq_progress_astra_20260906.log.{stderr,stdout,meta,result.json}.
- Ultima cobertura:42b150Calls67;6 writes frontend,2 atualizacoes da animacao.
- Instrumentacao opt-in:MC3_TIMER_WAIT_TRACE=1, com snapshots via MC3_WAIT_PROFILE=1.
- Ultimas alteracoes sao diagnosticas. Nenhuma mudanca de scheduler, sinais,
  rede, regras do timer ou matematica. Nenhum push nesta sequencia.
- Fontes geradas anteriores vivem em work/generated/ghidra e sao ignoradas
  pelo Git: preservar pasta local. Reproducao e validacao nos relatorios/ferramentas
  de cada lote; nao assumir que apenas clonar commits reconstroi todos os owners.

## Primeiro passo quando retomarmos

Ler STATUS.md e RESULT_IRQ_PROGRESS_2026-09-06.md, verificar delta do Git.
Ler tambem RESULT_BRANCH_STALL_0x54CB58_2026-08-31.md: a hipotese de que esse
laco explicava TODO desfecho ruim ja foi retirada. Nao repetir essa conclusao.

Investigar FUN_0054cb58_0x54cb58.cpp, label54cc08: capturar a2 e proximo no
na propria thread, com detector limitado de repeticao; comparar instrucoes e
delay slots com ELF. Identificar lista e escritores reais antes de atribuir
corrupcao. Nao ler contexto guest por outra thread, cortar lista, forcar retorno
ou sinal. Separar esse laco da espera inicial e da espera final SID43.

Depois: testes, relink absoluto, confirmar string/hash/mtime no exe, rodada
limitada sem janela, conferir processo encerrado. Evidencia de uma rodada nao
e aceite visual nem comparacao de desempenho.

Tudo pronto para continuar daqui, sem refazer os lotes ja concluidos.
