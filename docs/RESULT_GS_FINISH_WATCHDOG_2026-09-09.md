# MC3 — watchdog versus conclusão GS (09/09/2026, 05:00)

Encerramento06:04: prazo atingido, acompanhamento automático PAUSED confirmado
pelo aplicativo. Nenhum MC3/cc1plus encontrado; não foi necessário encerrar
processos. Nenhum experimento iniciado após06h. Retomada depende de nova direção.

## Resultado da sonda passiva — fechado 05:43

`gs_finish_r1_20260909` terminou às 05:30:32, após 601,0828756 s, encerramento controlado pelo harness; CPU214,09375 s. Nenhum MC3 ativo na consulta05:41. Nenhuma correção de comportamento aplicada.

- No snapshot IRQ32768 (linha9563), contador FINISH=206, despacho causa0=0 e entrada=0. Máscara de habilitação do runtime=ffffffff, um handler habilitado de causa0. São contadores até esse instante, não totais finais.
- O primeiro FINISH real aparece na linha2272. Portanto, nesta rodada o evento foi produzido; ausência de produção não explica sozinha a espera.
- 251 esperas concluídas, 250 notificações pareadas, todas do watchdog005295dc:1. Tempo agregado225,4414754 s; CV217,0786627 s; token8,3613791 s. Comparar cobertura antes de comparar totais: rodada anterior tinha258 conclusões. Não inferir ganho de desempenho.
- Analisador da sonda inicialmente aceitou29 linhas por exigir marcador no início. Oito eventos completos tinham prefixo de outra thread. Parser corrigido para localizar o marcador, teste de regressão PASS:37 eventos válidos, zero inválidos. Não alterou o binário da rodada.

### Lacuna da sonda: IMR por syscall

Nenhum ImrWrite observado. Isso NÃO prova máscara GS zero: `Kernel/Syscalls/System.cpp:199–214` implementa GsPutIMR/iGsPutIMR escrevendo diretamente `runtime->memory().gs().imr`, fora dos hooks MMIO desta sonda. A inicialização zera o registro, mas não autoriza presumir que permaneceu zero. A habilitação INTC observada é distinta da máscara GS.

write32 e write64 ESTÃO instrumentados; write128 MMIO delega em dois write64. A lacuna relevante confirmada é a escrita direta pelo syscall, não ausência de hook write32. O próximo lote deve incluir essa escrita antes de afirmar que os206 eventos exigiam IRQ sem máscara.

### Validação e proveniência

Baseline: work/patches/legal_phase_baseline_20260909_051614. Gate MC3_GS_FINISH_TRACE=1 registrado no meta. Unit gate0/1 PASS,326/326 runtime PASS, relink concluído e strings nova sonda/gate verificadas antes de rodar.

- exe SHA256: `6cb14a642d42120108ba8e3a000d0d8f2ea1343de277c54624318df4043aa72f`
- lib SHA256: `70f3cc7e6d44f767bb56d54230d174e566a4983b660394a4b3eaa5ab3a5fc253`

### Próximo lote delimitado

1. Preservar estado; completar observação GsPutIMR e reset, sem leitura extra concorrente do registro bruto.
2. Confirmar status/máscara e semântica IRQ antes de construir ponte experimental opt-in. Usar entrega INTC existente, sem SignalSema direto e sem reduzir alarme.
3. Validar gates/testes e rodada comparável, com autorização nova: observar produtor5282bc, quantidade de watchdogs e latência. Só depois avaliar boot visual/FPS.

Não abrir correção às05:43: restam menos de20min, insuficientes para implementar e validar esse comportamento com segurança. O acompanhamento até06h fica restrito a fechamento/documentação, sem novos builds/runs.

## Resultado medido

Rodada headless `legal_notify_r1_20260909`, encerrada às 04:41:12: 601,113 s de parede, 223,547 s de CPU. Das 258 esperas concluídas, 257 bloquearam. Todas as 257 notificações pareadas vieram de RA `005295dc`, TID de runtime 1. Isso não prova execução na thread principal do jogo.

Tempo agregado dessas esperas: 229,457 s; CV 223,058 s; retomada do token 6,398 s. São durações de espera, não custo de CPU.

## Interpretação sustentada pelo código

- `sub_005295F0` arma SetAlarm com 0x3480 = 13440 ticks e callback 0x5295b8.
- O runtime converte cada tick em 64 microssegundos: prazo de 860,16 ms, compatível com as esperas observadas. SetAlarm EE usa ticks H-SYNC; não confundir com a frequência do contador de 147,456 MHz. Não há evidência aqui para reduzir o prazo.
- `FUN_005295b8` marca 006f48cc e sinaliza o semáforo 006f48a8, retornando em 005295dc. É o caminho de timeout observado.
- `FUN_00528260` é outro produtor: verifica CSR GS & 2 (FINISH), reconhece o evento gravando 2 e sinaliza o mesmo semáforo, com retorno 005282bc. Esse remetente não apareceu na rodada.
- Registro confirmado em `FUN_00528ca0`: instruções 529040/529048 montam handler 00528260; chamada 52904c recebe causa **0**, definida no delay slot 529050. O registro anterior, causa 2, usa **5280b8**, não 528260. Não misturar esses registros.
- GS_REG_FINISH atualmente marca CSR bit 1; os pontos de despacho INTC inspecionados no runtime atendem causas 11, 2 e 3. A entrega da causa 0 é a lacuna candidata a testar.

## Limite da conclusão e próximo experimento

### Auditoria offline 05:13

Analisador reaplicado ao log fechado: 258 registros, zero linhas inválidas, 257 remetentes pareados, todos 005295dc:1. `Test-AnalyzeLegalSema.js` passou novamente. Proveniência da rodada, extraída do arquivo `.meta`:

- exe SHA256: `a0bf7624673938ce68108e1f22e89e59c37426a30f600667beadf243d8dd8df7`
- lib SHA256: `5d946fda2720fce708241cd0cceb4cbc4652ebb76bce89f1ce5f7bb6f539f645`

O log atual não mede a chegada efetiva de FINISH nem seu estado de máscara durante a espera. Ausência do remetente normal NÃO distingue ainda evento nunca produzido de evento produzido e não entregue. A lacuna estática no despacho é real nos pontos inspecionados, mas a atribuição do atraso exige esse elo dinâmico.

Próxima sonda mínima: contagem/timestamp de FINISH real, CSR/IMR, habilitação INTC causa0, tentativa de entrega e entrada/retorno do handler528260. Usar contadores limitados, sem despejar todos os pacotes. Primeiro preservar fontes/patch; testar gate desligado/ligado; conferir binário e configuração. A execução headless requer nova pergunta ao usuário conforme heartbeat atual. Nenhuma execução, compilação ou mudança de comportamento feita nesta auditoria.

Diagnóstico forte, ainda sem correção validada. Confirmar status/máscara e a entrega real do FINISH. Se implementada uma ponte experimental, respeitar CSR/IMR e INTC, usar despacho existente, nunca sinalizar o semáforo diretamente. Comparar retorno 5282bc versus 5295dc e latência numa rodada controlada. Não declarar ganho de FPS ou boot resolvido sem evidência.

Às 05:00, a consulta local não encontrou processo MC3 nem compilador g++/cc1plus ativo. Nenhuma nova execução foi iniciada durante esta atualização de status.
