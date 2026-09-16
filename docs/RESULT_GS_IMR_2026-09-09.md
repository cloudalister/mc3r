# MC3 — completar máscara GS após retomada06:08

## Fechado06:21 — candidato à correção delimitado

Rodada finalizada06:20:22 pelo timeout controlado:601,0294792s parede,
216,53125sCPU (133,640625user/82,890625kernel), sem saída precoce.
Consulta após conclusão:0processos mc3_partial. Nenhuma correção de
comportamento aplicada; automação antiga continua pausada.

56registros GS válidos,0inválidos. FINISH n256 na linha9841 com contadores
dispatches0/enters0. IRQ tick32768 linha9700 tinha241FINISH, máscara INTC
ffffffff e um handler habilitado. SyscallIMR n256 linha9822 mantevefc00
baixo, old/new iguais; primeiro valorff00 foi substituído porfc00 antes do
primeiroFINISH. Sem eventos ImrWrite MMIO observados. A amostragem não prova
ausência de toda mudança transitória entre registros; prova configuração
liberada nos pontos observados e ausência de entrega no mecanismo medido.

258esperas completas,257notificações pareadas, todas005295dc:1(watchdog).
Total244,8722344s;CV223,0693106s;token21,8014223s. Aviso aceito→CVout
0,006..0,1966ms. Nenhum remetente5282bc observado. Os tempos são parede,
não CPU. Nenhum ganho de velocidade/FPS/boot visual alegado.

Conclusão: produção FINISH confirmada, configuração de liberação confirmada
nas amostras e nenhuma entrega causa0 observada, coerentes com a lacuna
estática. Próximo passo é um teste de correção opt-in da entrega real, com
sincronização adequada, CSR/IMR e reconhecimento cobertos. Não há razão
para encurtar o watchdog ou sinalizar diretamente o semáforo.

Lote autorizado pelo novo `go`; acompanhamento antigo permanece pausado.
Sonda passiva apenas: GsPutIMR/iGsPutIMR (evento8:new,old) e inicialização
dos registros GS (evento9). Nenhuma ponte IRQ nem sinal forçado.

Baseline work/patches/legal_phase_baseline_20260909_060851; header/parser
anteriores copiados explicitamente. Gate0/1 PASS, parser PASS, runtime326/326
PASS. Relink35062 PASS. Rodada600s gs_imr_r1_20260909 iniciada, ainda em
andamento ao escrever esta seção; números finais pendentes.

## Primeiras observações (provisórias)

Reset0 observado. Syscall escreve `100000000ff00`, depois `5282600000fc00`.
Os32bits baixos mudam deff00 parafc00; bit9 passa de1 para0. Os bits altos
são registrados como o runtime os calcula de a1, sem corrigir ABI neste lote.
Não confundir esses valores brutos com um novo defeito comprovado.

Proveniência do meta: início06:10:20,600s configurados,
exe `e6c008ac748ae07b04af4d5aace31293ff63cd223eb20c6b1755f7cae40888de`,
lib `c914e83d82b9bc96e7cc3cae3373c5d306e662b5d026d9c04ea859c5eba3a34f`.
Primeira liberação registrada ns50956267316500; primeiro FINISH
ns51063591456500:107324,14ms depois. O syscall seguinte conserva fc00 nos
bits baixos e informa o mesmo valor baixo anterior. A configuração liberada
precede os eventos, não surge apenas após o último alarme da rodada.

Referência primária consultada: [PCSX2 GS.h](https://github.com/PCSX2/pcsx2/blob/master/pcsx2/GS.h)
define FINISHMSK no bit9; [Gif_FinishIRQ](https://github.com/PCSX2/pcsx2/blob/master/pcsx2/Gif_Unit.cpp)
condiciona entrega a FINISH pendente e máscara desativada. Usado para conferir
semântica do bit, sem copiar implementação. A atribuição local depende do log.

## Critérios de fechamento

Conferir resultado/meta, reset/mudanças de máscara, FINISH posterior, contadores
de entrega e remetentes de semáforo. Amostragem primeira8/potências de2 não
substitui snapshot final; contadores observados são limites inferiores.
Interleaving pode fragmentar outros logs; contar registros inválidos e não
assumir completude apenas porque parser aceitou parte das linhas.

## Desenho do próximo teste de correção (não implementado)

- Entrega baseada em evento FINISH real, status pendente e máscara GS/INTC;
  não acordar semáforo diretamente e não encurtar o watchdog.
- Estado de comunicação entre GS e dispatcher deve pertencer à instância
  do runtime e ser sincronizado; não usar os contadores globais da sonda
  como estado de emulação nem ler CSR/IMR brutos de outra thread.
- Toda escrita relevante precisa atualizar esse estado, inclusive syscall
  GsPutIMR, MMIO32/64, reconhecimento CSR e reset. Testar evento mascarado,
  desbloqueio posterior, reconhecimento, novo FINISH e isolamento de instâncias.
- Usar mecanismo existente de callback em contexto seguro, sem chamada
  reentrante enquanto estiver segurando o mutex do GS. Gate experimental
  desligado por padrão permite comparar o mesmo binário ligado/desligado.
- Critério funcional: remetente5282bc observado, watchdogs reduzidos nas
  esperas equivalentes, sem perda de progresso/crash. Comparar duração por
  espera e cobertura; total agregado menor sozinho pode significar menos trabalho.
- Boot visual e FPS continuam exigindo teste próprio; não são consequência
  automaticamente comprovada pela correção da entrega de um evento.
