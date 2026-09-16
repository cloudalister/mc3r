> Atualizacao 2026-09-13 07:33: saida interna do titulo destravada com MC3_MENU_ENTRY_FIX=1. Menu visual ainda corrompido. Nenhum probe ativo. Retomar por RESULT_MENU_ENTRY_2026-09-13.md e PS2_PROJECT_STATE.md antes dos passos historicos abaixo.

# MC3 — plano de diagnóstico gráfico para nova sessão

Preparado em 13/09/2026, Brasília. Escopo desta sessão: conferência e planejamento.
Nenhum build, execução do jogo, alteração funcional ou publicação do atlas feita
durante esta preparação. Janela proposta: 180 minutos a partir do início da nova
sessão, não compromisso de corrigir os gráficos nesse prazo.

## Base conferida hoje

Projeto: <project-root>.
O estado estava parado no cabeçalho “Active 10/09 09:55”. A rodada terminou:
`work/logs/probe_surface_band_20260910_0955.log.result.json`, em
10/09/2026 10:19:45, timeout do harness, wallSeconds=1502.3739775,
CPU=997.625, exitedBeforeLimit=false, exitCode=null. Não foi crash confirmado.
Não há mc3_partial ativo na conferência de 13/09.

Não localizamos evidências novas de execução em 11–13/09 nos documentos, logs
e capturas consultados. Há temporários do empacotamento do atlas de 13/09; isso
não é progresso do runtime. Se Cloud usou outra pasta/build, reconciliar primeiro.

### Progresso real acumulado

- Entrada/Start foi reconhecida e o teste manual chegou a CHECKING MEMORY CARD.
  “Create Pro...” depois disso é indício de tela de perfil, não perfil criado.
- Ponte experimental GS FINISH reduziu a mediana de uma espera específica de
  866,7722 ms para 8,625 ms no controle A/B de 09/09. Não é medição de FPS.
- Duas folhas ausentes recuperadas com 64 e 7 casos isolados. 5cd758 foi observada
  até 16384 chamadas em rodadas anteriores e até 8192 na última. 5e89f8 ainda
  não tem marcador observado nessas rodadas automáticas.
- Correção STQ tem teste discriminante e caminho exercitado no jogo; não eliminou
  as faixas. Última suíte documentada: 331/331 OFF e ON com sonda, em 10/09.
  São resultados históricos verificados nos registros, não suíte executada hoje.
- Última rodada: 5 PNGs apresentadas ok=1, 4.257.869 primitivas na quinta imagem,
  nenhum erro observado de função ausente. PNG5 inspecionada hoje: faixas e
  superfícies malformadas persistem. Menu utilizável/corrida não confirmados.

### O resultado pendente que muda a prioridade

Zero marcadores `[mc3-surface-write]` nos registros da última rodada; parser
retornou zero registros e zero rejeitados. Meta confirma MC3_SURFACE_PROBE=1.
Sonda escolhia um pixel (256,85), FBP0, somente CT32/CT24, após 3 milhões de
primitivas, mudanças RGB para branco/ciano durante drawPrimitive, limite32.
PNG5 ainda contém a faixa e informa displayFbp=0/sourceFbp=0.

Isso NÃO prova que o framebuffer esteja correto nem que os vértices sejam a
causa. O pixel pode já estar errado antes do início, não mudar de RGB, ser escrito
por IMAGE/HWREG/cópia fora de drawPrimitive, ou o mapeamento entre VRAM e imagem
apresentada não corresponder ao assumido. São hipóteses, não diagnósticos.

## Plano: 180 minutos, cinco etapas

### 1. Segurança e baseline — 20 minutos (0–20)

Conferir pasta/build mais recente com qualquer evidência nova de Cloud, processos,
git status root/submódulo e espaço. E: tinha 296.329.216 bytes livres (~283 MiB),
C: tinha 35.659.972.608 bytes livres na inspeção. Não começar build/relink nessas
condições sem capacidade suficiente para temporários e rollback.

Destinar novos artefatos grandes a uma pasta dedicada em C: quando os scripts
suportarem isso; qualquer movimentação deve ser explícita, recuperável, com
hashes/manifesto e só de artefatos próprios. Não limpar ISO/assets/saves, diretório
work inteiro ou temporários desconhecidos. Se precisar ampliar esse escopo, pedir
direção. Guardar fontes geradas ignoradas, registries, headers e diffs de ambos
os repositórios; um git diff da raiz não preserva tudo.

Saída: baseline identificado por SHA/configuração e plano de espaço viável.
Não gastar a janela inteira reorganizando disco; se bloqueado, seguir somente
com análise/replay que caiba, sem arriscar o executável existente.

### 2. Fechar o resultado antigo e localizar a lacuna — 35 minutos (20–55)

Usar logs e PNGs existentes antes de nova sonda. Comparar sequência PNG1–5 para
delimitar aparecimento da faixa. Rastrear a leitura apresentada até o endereço
VRAM correspondente; confirmar formato, stride, origem e coordenadas.
Revisar só os caminhos capazes de escrever esse endereço: drawPrimitive,
transferências locais/IMAGE/HWREG e composição/apresentação.

Saída: seleção justificada do ponto de observação e uma lista curta de caminhos
ainda não cobertos. Não concluir “VU1 errado” apenas pela aparência.

### 3. Observação pequena ou reprodução isolada — 45 minutos (55–100)

Preferir caso isolado se os dados existentes forem suficientes. Caso contrário,
estender a observação somente onde a etapa2 apontar: mostrar se a faixa já existe
ao armar, contar condições de elegibilidade e registrar mudança antes/depois do
endereço ou pequena região, incluindo a identidade do escritor.
Separar registro descartado por limiar/formato/coordenada de “nenhuma escrita”.
Limitar volume e evitar sondas por pixel em todo o quadro. Captura de VRAM/estado,
se indispensável, deve ser local privada, limitada e suficiente para um replay,
não uma coleção ilimitada de dumps.

Testar OFF/ON, limites, ausência de mutação e um escritor conhecido em cada
caminho acrescentado. Preservar defaults experimentais OFF.
Saída: prova de que a sonda consegue ver o caminho escolhido, ou teste isolado
que reproduza o defeito. Nenhuma correção especulativa para fazer a imagem sumir.

### 4. Uma rodada discriminante ou uma correção comprovada — 55 minutos (100–155)

Opção A, padrão: build/relink com hashes, strings e timestamps; uma rodada
headless de até25 minutos com capturas apresentadas e mesma configuração base.
Reservar o restante para coletar resultado e analisar quem escreveu a faixa.
Falha de build/teste bloqueia a execução. Não empilhar novas rodadas sem análise.

Opção B, somente se a causa já estiver comprovada e restarem pelo menos40 minutos
para implementação e validação completas: uma correção mínima, teste que falha
antes e passa depois, controles OFF/ON e comparação da mesma cena. Esta opção
substitui a expansão diagnóstica; não prometer correção + múltiplas rodadas.

Saída: proprietário do dado errado, divergência numérica reproduzida, ou resultado
negativo que elimine uma hipótese específica. “Rodou até timeout” não significa
menu aceito ou estabilidade geral.

### 5. Fechamento e entrega — 25 minutos (155–180)

Finalizar experimentos próprios, preservar logs/metas/fontes e documentar resultado,
limites, rollback e próximo teste. Atualizar PS2_PROJECT_STATE e atlas existente
com fatos comprovados; seguir Sites e preservar audiência privada. Não publicar
assets/código/capturas do jogo. Não aumentar porcentagem de jogabilidade por
testes passarem. Se não houver confirmação visual nova, escrever isso claramente.

## Critério de êxito do lote

Identificar uma fronteira concreta: dado já errado na chegada ao GS, cálculo ou
acesso à textura durante o desenho, transferência/cópia para o framebuffer, ou
apresentação. O mínimo útil é explicar por que a sonda anterior viu zero eventos
e validar uma medição que alcance o caminho faltante. Não garantir jogo corrigido.

## Fora do escopo

Otimização genérica de FPS, VIF/VU1 por ranking antigo, mudanças em scheduler sem
novo indício, ativar gates por padrão, pular introdução, sinal forçado, reduzir
watchdogs, apagar/formatar memory card, desligar PC ou retomar automação noturna.
Não iniciar tarefa em outra pasta/cópia sem reconciliar o baseline.

## Organização econômica

Exatamente um subagente econômico de investigação, com pergunta delimitada;
principal cuida de implementação/integração e não repete a mesma busca. Reutilizar
quando disponível. Scripts resumem logs; chat recebe resultado, risco e próximo
passo. Mudanças pequenas, preservando dirty worktree. RTK em todo comando.

## Handoff para a nova sessão

Copiar a mensagem abaixo após alinhar/aprovar o plano; criar a sessão não foi
executado nesta preparação:

> Retome MC3 em <project-root>. Leia integralmente
> docs/PLANO_GRAFICOS_NOVA_SESSAO_2026-09-13.md e execute o lote de diagnóstico
> proposto de 180 minutos. Comece pela reconciliação do baseline e espaço em disco.
> Não confunda o estado antigo “Active 10/09” com processo ativo. A rodada
> surface_band_20260910_0955 terminou com faixas presentes e zero eventos da sonda.
> Descubra a lacuna de observação antes de repetir sondas. Use exatamente um
> subagente econômico, preserve alterações e defaults OFF, teste/relink verificados,
> e atualize o mapa apenas com evidência. Sem reinstanciar a automação noturna,
> desligar PC ou mexer em saves. Se existir build mais recente em outra pasta,
> alinhe essa origem antes de modificar código.
