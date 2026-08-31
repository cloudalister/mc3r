# Handoff — a duração da bateria estava mascarando o resultado — 2026-08-31 (madrugada/manhã)

Continuação de `HANDOFF_2026-08-31_SESSAO_FRESCA.md`. Detalhe completo, com números e
controles, em `RESULT_SEMA_PROBE_BLIND_2026-08-31.md`.

## O de mais consequência

**Com 1200 s por execução o jogo passa da tela de carregamento e entra no menu, 3 vezes em 3.**
O segundo pedido de streaming conclui em 6–8 s de jogo, `mcMenuShell::ChangeState` é entrada,
`gsPrims` vai a ~1.006.000 contra ~690.000 nas execuções de 420 s (+46%), e o PC final fica em
`swfSCRIPTOBJECT::GetGlobal`.

**Toda bateria daqui em diante precisa de 1200 s ou mais por execução.** Com 420 s, cinco de
seis execuções terminam **antes** de o segundo pedido sair da fila. O log delas é
indistinguível do de uma execução travada, e foi contado como ramo ruim durante semanas.

## O que isso muda e o que não muda

Não desmente a trava: a `catch_xfer_r2` observou 3.840 ticks após o segundo dequeue sem
`done2`, oito vezes a folga necessária. Aquela travou de verdade.

Muda a contagem. Só execução que **chegou** ao segundo dequeue pode ser classificada pelo
`busy`. Refeita a conta com janela conclusiva: **4 boas, 1 travada, 7 inconclusivas** — não
"5 de 7 ruins". A frequência do desfecho ruim vinha superestimada.

## Armadilhas novas, todas custaram tempo aqui

1. **O discriminador `busy` sai zero-padded no log: `busy=0x00000002`.** Procurar `busy=0x2`
   devolve zero sempre e faz execução boa parecer ruim.
2. **Teto de sonda mente por omissão, e há muitos.** Dezesseis sondas atingem o teto e ficam
   mudas antes do segundo dequeue — VU1, VIF1, GS e interrupção inteiras. Inventário completo
   na seção 9 do RESULT. As de semáforo estão em 200.000; o resto continua baixo.
3. **Guarda com escape não é teto.** `sceSifSetDma` tem `< 128u` no fonte e emite 1.059 vezes,
   por causa de um `||`. Cruzar fonte com contagem real de log antes de afirmar teto.
4. **Nome de função: usar `work/scratch/resolve_symbols.py`.** Ele resolve por intervalo
   combinando fronteiras do corpus com a coluna 4 do CSV. Não escolher coluna na mão.

## Correções ao registro anterior

- `FUN_00431E00` é **`datStreamer::Worker(void *)`**. O port o recusou por diferença de
  tamanho (812 no alpha, 736 no retail).
- `0x431F98` é `datStreamer::Worker +0x198` — a sonda do "laço de transferência" estava dentro
  do worker o tempo todo.
- `0x432BA8` é `memcpy +0x88`, não código do streamer.
- A leitura de que "a sinalização de semáforo é idêntica nos dois ramos" saiu de janela com o
  instrumento desligado e não se sustenta.
- A hipótese de que o worker não estaria sendo escalonado fica enfraquecida: a thread dele
  registrou 10.803 bloqueios de semáforo numa execução, com sids ciclando.

## Próximos passos, em ordem

1. **Bateria de controle: 1200 s com os tetos antigos.** A bateria longa mudou duração *e*
   tetos ao mesmo tempo. A explicação por duração tem apoio mecânico, mas o confundimento
   não foi desfeito.
2. **Reproduzir a travada com janela longa.** A `catch_xfer_r2` é o único caso conclusivo de
   trava e agora há instrumentação para observá-lo.
3. Com o menu alcançado, reavaliar o que ainda bloqueia o frame visível.

## Estado do repositório

19 commits nesta linha de trabalho (de `67fab96` a `5c654ed`), 5 deles desta sessão.
Árvore limpa, submódulo com os tetos em 200.000, exe relinkado e mais novo que a
lib. Nada enviado ao remoto.
