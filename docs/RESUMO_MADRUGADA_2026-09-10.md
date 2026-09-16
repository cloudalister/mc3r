# MC3 — balanço da madrugada de 10/09/2026

Encerramento 09:46: automação `mc3-investiga-o-at-6h` confirmada PAUSED no
primeiro disparo após 09:30. Nenhum processo mc3_partial encontrado. Nenhuma
nova rodada, fechamento de janela, desligamento ou reinício executado.
Esta anotação substitui o estado “ainda ativa” registrado às 09:02 abaixo.


Atualizado às 08:58, Brasília. Diagnóstico e mudanças locais reversíveis.

### Fechamento de artefatos às 09:02

Atlas privado atualizado com sucesso: https://mc3-atlas-cloud.iixyzutwo.chatgpt.site/
Versão 6, fonte `5c36ad2f45804e91360df2f8af6e546c8f1cb329`, publicação
`appgdep_6aa29be3e8948191b30dec0ad3830c42` succeeded às 09:00:49.
Build do site e validação do catálogo de 15812 entradas passaram. Helpers Node
falharam por ambiente Windows; build npm existente e packager oficial bash
concluíram. Nenhuma dependência alterada. Sem nova janela/QA de navegador durante
o trabalho em segundo plano; acesso verificado privado para uma única conta.

Snapshot adicional de 344 arquivos copiados e verificados por SHA256, mais
diffs binários root/runtime, em
`<scratch-dir>\mc3recomp-backups-20260910_0750\closing_sources_0901`.
Inclui owners/registries ignorados, headers, ferramentas, documentos, metadados
da última rodada e seis PNGs; não duplica stdout/stderr grandes nem binários.
Os acréscimos documentais posteriores ao snapshot permanecem no projeto.
Automação existente ainda ativa somente até o fechamento das 09:30; ao próximo
disparo respeitar o limite, sem reiniciar rodadas longas já concluídas.

## Resultado em poucas palavras

O jogo ultrapassou uma chamada ausente que encerrava a execução. Também
encontramos um erro real no cálculo das texturas. Ainda assim, a imagem segue
quebrada: não temos menu utilizável, criação de perfil ou corrida confirmados.
O teste manual de Cloud continua sendo a evidência de checagem de memory card;
o texto posterior “Create Pro...” não prova que um perfil foi criado.

## O que foi comprovado

- Folha 0x005e89f8 recuperada das instruções ELF; 64 casos do código real passam.
  Não apareceu nos marcadores das novas rodadas: validação em jogo pendente.
- Folha 0x005cd758 recuperada: retorna a0 + 0xec com semântica ADDIU original.
  Sete casos passam. Duas rodadas posteriores atingiram 16384 chamadas, sem
  repetir o erro de função ausente que interrompera o controle anterior.
- Captura do quadro efetivamente apresentado agora funciona sem BOOT_TRACE,
  limitada a seis imagens, sem sobrescrever capturas existentes.
- Interpolação STQ de triângulos tinha erro matemático. Com fixture corrigida,
  contrato exigido + correção OFF: 328/329; comportamento legado OFF: 329/329;
  contrato exigido + correção ON: 329/329. Falha inicial de fixture não conta
  como prova do defeito. A correção permanece experimental e OFF por padrão.

## Última rodada

`stq_correct_capture_20260910_0756`: 07:56:19–08:31:22, 2103.3388474 s de parede,
1533.75 s CPU. O limite do harness encerrou a rodada; exitedBeforeLimit=false,
exitCode=null. Não classificar como crash ou saída natural.

16 marcadores íntegros de 5cd758 (até 16384 chamadas), 24 marcadores STQ
(até 4194304 triângulos com Q variável), nenhum marcador observado de 5e89f8
e nenhum erro observado de função não implementada. Logs intercalados exigem
cautela: ausência de marcador não é prova universal de ausência de execução.

Seis capturas apresentadas, todas ok=1. A sexta ainda mostra faixas brancas/ciano
e cenário deformado. PNG5 tem o mesmo contador de primitivas do controle OFF,
mas isso não prova igualdade de todo o estado do jogo. Sem conclusão sobre FPS.

Executável: `work/link/partial/mc3_partial.exe`
SHA256: `f76cd5f0ecbd4af7b4f2dc7a441b75d1049d3f29f358d0dcb871a5f4041a0f57`.
Biblioteca: `PS2Recomp/out/build/ps2xRuntime/libps2_runtime.a`
SHA256: `0377ebdf5b1788e2d9f5d04e563ca78062f3cc8d21414b7b187affe7769b7d7b`.
Relink, marcadores e timestamps verificados antes da rodada.
GS_IRQ_BRIDGE=1 e GS_STQ_INTERPOLATION=1 usados apenas no experimento;
ambos os gates continuam OFF por padrão. Nenhuma alteração de saves/cards.

## Próximo lote: uma superfície defeituosa, não mais sondas espalhadas

1. Escolher uma faixa/triângulo reproduzível nas capturas tardias.
2. Captura numérica limitada no caminho GS → raster: origem/ordem do comando,
   tipo de primitiva, XYZ/XYOFFSET, STQ, modo FST, textura/CLUT e destino.
   Incluir somente o estado necessário para reproduzir aquele desenho.
3. Reproduzir isoladamente e determinar: os vértices já chegam deformados,
   o acesso à textura está errado, ou o desenho/composição corrompe a saída?
4. Só então corrigir uma causa com teste discriminante e comparação visual.

Não priorizar scheduler por intuição; não alterar XYOFFSET/alpha ou forçar
sinais sem evidência. Fechamento ao clicar não foi reproduzido como crash do
Windows: os logs anteriores mostram o caminho interno de parada por missing.

## Preservação e retomada

`work/` é ignorado pelo Git. Os owners gerados precisam de cópia explícita;
git diff do repositório principal sozinho não os preserva.
Backups de owners/registries em `work/patches/legal_phase_baseline_20260910_064330`
e `restored_0653`; baseline anterior `..._040727` também preservado.
`..._074832` é INCOMPLETO por falta de espaço: não usar como rollback completo.

Dois binários de backup 064330 foram movidos, com hashes conferidos, para
`<scratch-dir>\mc3recomp-backups-20260910_0750`.
Esse diretório também contém os binários pré-STQ, fontes pré-STQ e patch runtime.
Ver `BINARY_BACKUPS_MOVED.md` dentro de 064330. Nada de saves/assets foi apagado.

Resultados: `work/logs/probe_stq_correct_capture_20260910_0756.log.*`.
Imagens privadas: `work/captures/present_stq_correct_capture_20260910_0756_*.png`.
Detalhes e comandos: RESULT_ENTRY_5E89F8, RESULT_LATE_CAPTURE_5CD758 e
RESULT_STQ_INTERPOLATION, todos de 2026-09-10 em docs.

Sem processo mc3_partial ativo no fechamento da auditoria. Nenhuma nova rodada
longa antes do limite das 09:30. Automação deve ser pausada ao atingir o limite;
não há autorização atual para desligar/reiniciar o computador.
