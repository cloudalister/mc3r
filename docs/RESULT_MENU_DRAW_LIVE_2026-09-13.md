# Leitura viva da rota de desenho - 2026-09-13

Atualizacao09:11: coleta posterior a ativacao concluida no probe seguinte.
Recursos identificados corrigindo sinal do ADDIU:65ACEC MemCard,65AE24
MenuOptionScreen. Ver RESULT_MENU_TRANSITIONS_2026-09-13.md antes de retomar.

## Resultado

Probe menu_draw_20260913_a encerrado pelo limite de720s (721s reais).
Mesmo executavel imutavel menu-entry, SHA256
dfae148e105033eba268e398fe02f3a7ca0572ac4d67e26612c20ef60918a5e5.
MENU_ENTRY_FIX, GS_IRQ_BRIDGE e STQ ON; host clock/depth OFF.
START30s pressionado/30s solto apos45s. Headless, sem janela, sem escrita guest.
Nenhuma nova melhoria visual: captura3 escura/geometria corrompida, menu ilegivel.

Ultima leitura viva08:54:30: estado pedido+E0=40, atual+D8=41, node368=6.
Ultimo bootframe intacto depois disso: titleFlags974 (titulo inativo), tick39360,
prims3690309, titleUpdate73, node368=5. Nao ha leitura posterior que confirmeD8=40.
Portanto titulo voltou a desativar, mas a coleta DEPOIS da ativacao do painel
seguinte ficou pendente. Nao apresentar o pedido40 como estado atual40.

## Evidencia coletada

Titulo17261A0 -> filho1726350, vtable631C40, Render422698, flags647.
Gate bits0+9 aberto; group+58=1. Lista1701A90 percorrida ate sentinela,
um membro177ABD0/vtable631BA8/flags591/Render5CC940, gate aberto.
Repetido em guest_8,guest_9,guest_final e guest_last.

Painel seguinte1725D50 ainda inativo(flags462) -> filho1725EA0,
vtable631C40/Render422698, flags135 (bit9 desligado), group+58=1.
Lista17019E0, um membro17788B0/vtable631BA8/flags78/Render5CC940.
Esse gate fechado ANTES da ativacao nao prova defeito: nao forcar flags.

422698 verifica+44 bit0 e+58 bit0, percorre lista circular em+48,
e encaminha node+C a4262D8, que chama slot28. Nao slot1C.
5CC940 e um retorno jr ra no codigo gerado, nao um emissor GS; sem registro
explicito na tabela fonte. Isso por si so nao prova funcao faltante defeituosa.
O desenho efetivo pode pertencer a outra rota/componente da interface.

Construtor exato: sub37E070 grava62BDE0 em37E09C apos37F5F8.
Cadeia base37F5F8 ->580D10 ->41F518 ->41F5D0;
41F6A8 grava em this+48 o objeto retornado via41F9E8. Sao evidencias de fonte,
nao rastreamento executado do construtor nesta coleta.

## Ferramentas e limites

Read-MenuGuest.ps1 aceita ProbeReceipt com PID, caminho, ticks UTC e hash do
executavel. Preserva modo legado; leitura rejeita identidade diferente.
Percurso do grupo limitado a64 links, detecta repeticao, valida limites RAM.
activePanelCandidates continua filtrado por bit0; nextPanelCandidates inclui
o painel conhecido ainda inativo. JSON depth8 preserva os membros.
Leituras nao atomicas. Uma tentativa cedo demais rejeitou identidade do titulo
antes da construcao; nenhuma amostra invalida foi gravada.
Sem recompilacao/relink durante o probe. Processo15872 encerrado e ausencia verificada.

Artefatos <scratch-dir>/mc3-menu-draw-20260913/run:
receipt.json, guest_2..9.json, guest_final.json, guest_last.json, analysis.json,
logs com meta/result e tres capturas apresentadas. Nao sobrescrever.

Proximo passo: observar a rota compartilhada Render3404D0 na passagem5->0->6->5
e coletar o grupo1725EA0 apos ativacao. Preferir diagnostico dirigido a estados;
o limite fixo de12min terminou logo apos desativar o titulo neste run.
