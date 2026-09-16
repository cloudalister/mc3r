# GS FINISH → INTC0 experimental — 09/09/2026

## Fechamento07:46 — desligamento solicitado

Visual terminou07:39:28,600,9883382s parede/205,265625s CPU, parada controlada.
820esperas completas,707avisos pareados todos normais5282bc. CV4,9170132s;
token110,2592415s. Uma linha inválida61867 no log ruidoso; amostragem e
intercalação limitam cobertura. Não comparar com desempenho quietON/OFF.
Captura única legal/logo já inspecionada, não comprova estado final ou menu.
Nenhum mc3_partial em07:45. Cloud pediu desligar após término; encerrar lote,
pausar heartbeat e solicitar desligamento Windows, sem novos experimentos.

## Controle OFF concluído — 07:33

Atlas publicado07:35:52, versão3, acesso proprietário privado preservado.
Commit8da55c5855a3c158b00d088a0578f7d3c0bbc0ba;
deployment appgdep_6aa1367db808819180c7cfd8d2a01939 succeeded.
Checks de catálogo, TypeScript e build passaram. Site informa correção
experimental/controle A-B e ausência de novo estágio visual confirmado;
catálogo e percentuais não alterados. Não abriu nova aba em tarefa de fundo.
Backup posterior: work/patches/legal_phase_baseline_20260909_073444,
incluindo cópias explícitas ps2_gs_irq_state.h e ps2_gs_finish_probe.h.

Captura visual inspecionada07:35: frame_gs_irq_bridge_visual_r1_20260909.png
mostra logo MC3 e avisos legais, conteúdo já observado historicamente. Não
confirma menu/corrida ou avanço visual. ctx0 mostra imagem entrelaçada/
repetida; não tratar buffer de contexto isolado como framebuffer final.
Dump é único por execução; não descreve necessariamente o estado final.

Mesmo executável e biblioteca do ON; comparação de metas confirmou mesmas
configurações, exceto gate e nomes dos arquivos. OFF terminou07:18:48,
601,0775326s de parede,105,046875s CPU. Foram86esperas completas e85avisos
pareados, todos do watchdog005295dc. CV73,7485211s; token31,1849242s;
medianaCV866,7722ms. ON: mediana8,625ms,682avisos normais em779esperas.
Isso confirma a mudança do produtor e da latência desta espera no controle
com o mesmo binário, não ganho de FPS nem boot resolvido. Coberturas distintas.

Rodada visual ON gs_irq_bridge_visual_r1_20260909 iniciada07:29,600s,
sessão34602, sem QuietBootTrace, limiar100000. Aguardar captura e término;
não comparar desempenho dessa rodada ruidosa com quietON/OFF.

## Primeiro resultado ON — analisado07:12

gs_irq_bridge_r1 terminou06:57:26,601,402105s parede/295,328125sCPU,
sem saída precoce. Nenhum MC3 ao retomar07:08.
Exe43fda6a719efdbfd2e299ee3a4769bc999c30c0618e54fce885eb5c33a0b567f;
liba21022d6fd98ab73480dd70851ffa949fd83431ef3a5ee66eacdf6cb7671527f.

779esperas completas;682notificações pareadas, todas RA005282bc, produtor
normal. Nenhum watchdog entre esses pares. TID4294967295 é a identidade
de runtime do contexto IRQ, não um thread guest identificado.
CV7,7229953s/token48,4122558s/total56,139324s. CV mediana8,625ms
(min0,0136/max258,3504), versus868,1495ms na rodada prévia gs_imr_r1.
Isso NÃO representa ganho100x de jogo/FPS: só a fase CV e com cobertura distinta.

Snapshot IRQ32768:780FINISH/780dispatch/780enter. Worker completou779voltas,
errors0/duplicates0, e sinalizouSID212; parede424,852s. A espera-alvo deixa
de dominar como antes, mas o boot ainda tem outros custos.

Controle OFF iniciado07:09 com MESMO executável e configuração equivalente,
incluindo limiar100000. Labelgs_irq_bridge_off_r1_20260909,600s. Aguardar
resultado antes de alterar executável ou começar outra execução.

### Captura: causa confirmada da ausência

MC3_BOOT_TRACE=0 (QuietBootTrace) impede a chamada LogBootTraceFrame em
ps2_runtime.cpp:3437–3439. O dump fica DENTRO dessa função. Portanto,
reduzir só FrameDumpMinPrims não era suficiente. Não atribuir a ausência
apenas ao contador de primitivas, como sugeriu uma auditoria incompleta.
Após controleOFF, fazer rodada visual separada SEM QuietBootTrace e com
limiar apropriado. Não comparar seus tempos diretamente com quietON/OFF.
Ainda não há imagem nova nem aceite visual/FPS.

## Implementação06:47, antes da rodada

Gate MC3_GS_IRQ_BRIDGE=1, desligado por padrão. FINISH real marca latch
atômico; máscara bit9 preserva pending enquanto bloqueado; leitura CSR bit1
usa esse estado no modo experimental; escrita W1C reconhece e limpa.
IMR syscall/MMIO32/64/128 e writeIORegister cobertos; CSRreset limpa
pending e máscara para7f00; inicialização segue estado inicial do runtime.
Tick IRQ existente despacha causa0 se elegível, respeitando dispatcher e
handler existentes. Não há chamada direta a SignalSema nem mudança de alarme.

O estado está num sidecar separado por endereço GSRegisters, com registro
protegido por mutex e remoção em PS2Memory destructor. Isso evita mudar
layout/tamanho de PS2Memory/GS/PS2Runtime usados por objetos gerados antigos.
O estado atômico combina pending+mask. O registro global só guarda os donos;
não há contador/latch de emulação compartilhado entre instâncias.
Vida útil pressupõe parada/join das threads antes da destruição da memória,
como o restante do runtime. Não é modelo completo de IRQ SIGNAL/GS hardware.

## Preservação e testes

Baseline work/patches/legal_phase_baseline_20260909_063907. Não reverter
mudanças antigas; runtime.patch contém diff anterior. Novo header
ps2_gs_irq_state.h deve ser preservado explicitamente nos próximos lotes.

Build63162 concluiu. Primeiras execuções67506/31510 se sobrepuseram:
off327/328 (teste de concorrência), on327/328 (teste lendo CSR bruto).
Não mascarar falhas. Atualizado teste para ler CSR pelo acesso guest, mantendo
asserts de FINISH e reconhecimento independente de SIGNAL. Rebuild concluiu.
Reexecuções SEQUENCIAIS:328/328 off e328/328 on. Falha de concorrência não
reproduziu na repetição isolada; não declarar causa comprovada da flutuação.
Testes novos cobrem masked/unmask/ack/reset/rearm/isolamento e FINISH real
viaGS, leituras32/64, ack32/64/128, unmask32 e writeIORegister.
Sonda CSR agora registra valor entregue ao guest, incluindo pending/FIELD.

## Pergunta da rodada

Comparar produtor5282bc vs watchdog5295dc, duração por espera e cobertura.
Captura usa limiar100000primitivas (antes700000, não atingido), alteração de
diagnóstico registrada no meta; uma captura não comprova progressão completa.
Não atribuir FPS ou boot resolvido sem evidência visual e comportamental.
