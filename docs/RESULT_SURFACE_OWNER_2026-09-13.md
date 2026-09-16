# MC3 — fechar a lacuna da sonda de superfície

Sessão autorizada por Cloud em 13/09/2026; janela máxima de 180 minutos iniciada
às 03:22:56 de Brasília. Rodada encerrada deliberadamente às03:54:11 após
atingir o critério mínimo de diagnóstico; não foi necessário consumir toda a janela.

## Conclusão

**Lacuna de observação fechada; gráficos ainda quebrados.** A sonda antiga
recusava CT16 e só começava em3M. A nova rodada identificou mudanças para
branco/ciano em2.227.445 e2.407.292 primitivas, CT16, dentro de drawPrimitive
ao copiar textura CT24. A terceira captura reproduziu as faixas. Os vértices
registrados da cópia são regulares; a causa anterior/completa da corrupção
ainda não está comprovada. Não houve correção gráfica funcional neste lote.

## Baseline e preservação

- Checkout: `<project-root>`.
- Raiz `4c106930b8461bc197dfdcbf1913c83222d95f58`, submódulo
  `2af51f7037eff0012b0c6a725ce64f33da948ca3`, ambos com trabalho local preservado.
- Nenhum runner ativo na reconciliação. A rodada de 10/09 terminou por timeout,
  não por crash confirmado; sem evidência posterior de runtime encontrada.
- E: começou com 296.312.832 bytes livres. Novos binários, build, temporários,
  capturas e logs ficam em `<scratch-dir>\mc3-surface-20260913`.
- Backup `baseline_v2/COMPLETE.json`: 16.202 arquivos, 929.956.541 bytes,
  cópias verificadas individualmente por SHA-256 e manifesto CSV. Inclui todos
  os 15.834 arquivos de fontes geradas, registries, headers, ferramentas,
  documentos, binários e patches dos dois repositórios.
- `baseline/` é tentativa incompleta: o PowerShell local não oferece Get-FileHash.
  O script foi corrigido para SHA-256 via .NET; a tentativa incompleta não foi apagada.
- Nenhuma movimentação/deleção de ISO, assets, saves ou arquivos antigos.
  O exe/lib/testes originais em E: continuam no lugar.

## Evidência anterior e escolha da observação

Foram inspecionadas as cinco PNGs de `surface_band_20260910_0955`:

| PNG | Tempo de captura | Primitivas | Observação |
|---|---:|---:|---|
| 1 | 60.009 ms | 256.991 | Tela legal do jogo |
| 2 | 360.010 ms | 941.781 | Cena muito escura |
| 3 | 660.017 ms | 1.265.975 | Região inferior malformada |
| 4 | 960.033 ms | 2.227.437 | Cena escura, sem a faixa branca/ciano superior da PNG5 |
| 5 | 1.260.044 ms | 4.257.869 | Faixas brancas/ciano superiores presentes |

A transição observada fica entre PNG4 e PNG5, sem provar seu instante exato.
O hook antigo exigia CT32/CT24 no FRAME ativo, FBP0, prim>=3M e mudança RGB
para branco/ciano. O próprio log anterior mostra FRAME `0x02080000` (CT16,
FBW8, FBP0). Esse formato era explicitamente rejeitado pelo leitor antigo.
Além disso, IMAGE/HWREG, cópias locais e clear não eram observados por ele.

A nova sonda observa o endereço físico CT16 de (256,85), FBP0/FBW8, antes/depois
de operações completas. A apresentação registra formato, origem, layout,
DISPFB1/2, campo, pixel host e pixel VRAM; FBP coincidente sozinho não basta.
O endereço é fixo e não é redirecionado silenciosamente para outro framebuffer.
O limiar da rodada é 2M, anterior à PNG4 histórica; isso é uma janela de
observação, não garantia de que a mesma cena ocorrerá na mesma contagem.

## Implementação diagnóstica

- `MC3_SURFACE_WATCH=1`, novo gate OFF por padrão. Não altera layout de GS ou
  PS2Memory, preservando ABI dos objetos guest já compilados.
- Leitura CT32/CT24/CT16/CT16S; alvo padrão CT16. Apenas um endereço, nenhuma
  sonda por pixel de todo o quadro, nenhum dump de VRAM/assets.
- Escritores: drawPrimitive, processImageData (IMAGE ou HWREG identificados),
  performLocalToLocalTransfer e clearFramebufferContext/clearActiveFramebuffer.
- Limite global: 32 transições candidatas; até cinco primeiras candidatas
  abaixo do limiar, um registro de armamento, 24 mapas e 16 amostras da
  apresentação com contadores por escritor. Geometria somente para draw selecionado.
- Contadores distinguem operação inválida, abaixo do limiar, RGB inalterado,
  cor não selecionada, candidato e candidato além do limite. São operações,
  não quantidade de pixels escritos. RGB igual pode incluir mudança de alpha.
- Uma mudança restaurada dentro da mesma operação pode passar despercebida.
  Outros escritores ainda podem existir; não afirmar cobertura universal.
- `texRaw` na linha geometry contém TEST, ALPHA, CLAMP e TEX1, nessa ordem.
  É um rótulo diagnóstico; TEX0 decodificado aparece em `tex` e `clut`.

## Validação antes da rodada

- Build completo CMake/Ninja em C: com dependências locais existentes, mesmo
  compilador GCC 16.1 e RelWithDebInfo. Comandos de compilação de GPU,
  rasterizer e runtime foram comparados com compile_commands original: iguais.
- Fixture isolada: sonda antiga rejeita CT16 conhecido; nova lê corretamente.
  Parsing/limites, leitura sem mutação, CT32/24/16/16S e contabilidade negativa
  testados. Cinco escritores reais geraram cinco eventos de atribuição.
- OFF/ON: stdout com hashes de toda a VRAM após cada escritor e da imagem
  apresentada idêntico. Origem DBX diferente lê outro endereço como controle.
- O primeiro teste de apresentação usava 4x4, que o runtime substitui pela
  dimensão padrão. Fixture corrigida para 64x64, sem alterar comportamento.
  A primeira checagem do script usava Select-String posicional incorretamente;
  corrigida com parâmetros nomeados. Os eventos já estavam no stderr.
- Suíte completa OFF: 331/331; ON+bridge+STQ correto: 331/331.
  Evidência `tests/PASS_20260913_033732.json` e logs correspondentes.
- Parser de logs testado com a fixture real e registros intercalados/incompletos.
- Diff-check raiz/submódulo passou; revisão do único subagente econômico não
  identificou mutação de VRAM, mudança de layout ou deadlock evidente.
- Relink separado em C:, oito marcadores e datas conferidos; DLLs copiadas
  do mesmo toolchain e verificadas por hash. Proveniência em `bin/VERIFIED.json`.
- Novo exe SHA256:
  `d0c66999cfbf652d82f2725270d69a33ceacd7149ee8351599eb16000b0d638f`.
- Nova lib SHA256:
  `366228bd5772b4b72cda6d032d6d4582cee29d227acd2fe5d9292f3d5efb3faa`.
- Exe original preservado:
  `1d3bf49bbdc88f23b178978d6ea0797827848581d5e88fd2d6b35acbfca9ac0b`.

## Rodada discriminante — encerrada deliberadamente

`surface_owner_20260913_0345` começou realmente às **03:42:04**. Limite máximo1500s;
foi encerrada às03:54:11 pelo agente após três capturas e resultado discriminante.
Nome da rodada não é horário exato. PID56912; sessão48426. Headless, quiet, bridge+STQ ON,
entrada/captura apresentadas ON, Start30/30s com atraso45s. Sonda antiga ON e
nova ON; limiar2M. Nenhum outro runtime executado neste lote.

Logs/meta/resultado: `<scratch-dir>/mc3-surface-20260913/run/logs/`.
Capturas: mesma raiz `run/captures/`.

Primeira PNG apresentada ok=1, 60.018ms, 499.076 primitivas; ainda tela legal.
Primeiros registros confirmam DISPFB CT16, FBW8, FBP0, origem CRT1(0,0),
CRT2(0,1), modo de campo. A amostra host observada coincide com RGB da amostra
VRAM fixa, sem provar que isso vale para todos os campos/circuitos.
Processo ausente após encerramento. O arquivo `.stop.json` registra PID, caminho,
hora de criação verificados e motivo antes do Stop-Process. O harness registrou
726,8627765s de parede,708,4375s de CPU,exitedBeforeLimit=true,exitCode=-1.
**Esse código decorre do encerramento deliberado; não é crash ou saída natural.**

### Atribuição observada

A sonda armou exatamente em prim2.000.000, amostra válida/preta (`0x8000`).
O endereço CT16 é 99.464 bytes (`0x18488`), confirmado pelo caminho de cópia
da apresentação com FBP0/FBW8/PSM2/origem0,0. O mapa inicial prim0 usa outra
configuração e explicitamente não coincide; não foi tratado como correspondência.

| Evento | Primitiva anterior | Escritor | Caminho GIF | VRAM CT16 |
|---|---:|---|---:|---|
| 1 | 2.227.445 | draw | 2 | preto `8000` → branco `ffff` |
| 2 | 2.407.292 | draw | 2 | preto `8000` → ciano `ffe0` |

Ambos são sprites texturizados: FRAME0/8/CT16, TEX0 TBP2048/TBW8/CT24,
TW10/TH10, FST1/TME1/ABE1, cor128/128/128/128. Após XYOFFSET, os vértices
descrevem uma faixa vertical regular de32 pixels: (256,5;0,5) a (288,5;447,5),
UV fixo (256;0) a (288;447). Isso atribui a mudança observada a uma operação
de cópia/desenho, mas não prova se o erro nasceu nos bytes da textura, na
amostragem, blending ou em outro acesso da mesma operação.

Até a amostra prim3.000.009: draw=3.000.009 operações, abaixo do limiar=2M,
inalteradas=1.000.001, não candidatas=6, candidatas=2, capped=0, invalid=0.
IMAGE=157.550 operações,112.414 abaixo do limiar e45.136 inalteradas;
HWREG/cópia local/clear=0 chamadas observadas. Sonda antiga: zero eventos.

Nesta rodada, as duas transições aconteceram antes do limiar antigo de3M e
em formato rejeitado pela sonda antiga. Isso explica concretamente sua lacuna,
sem afirmar identidade perfeita de timing/estado com a execução de10/09.

**Limite da apresentação:** DISPFB1=0x11000 e DISPFB2=0x80000011000 selecionam
CT16/FBW8/FBP0, origens(0,0)/(0,1). PMODE0x8067 ativa os dois circuitos,
MMOD1/ALP128; o runtime mistura canais por `dst + (src-dst)*128/255` com
aritmética inteira. Em campo par, PNG(256,85) combina VRAM(256,84) do CRT1 e
VRAM(256,85) do CRT2; em campo ímpar, usa linhas85/86. A sonda observa apenas
linha85. Igualdade de RGB com o pixel final não identifica exclusivamente o
escritor da outra contribuição. Próximo refinamento, se necessário, deve
acompanhar o par de linhas e os bytes da textura de origem, além do estado
completo de blending/ZBUF, sem atribuir a causa ao VU1 por aparência.

### Fechamento dos registros

`run/surface_analysis_final.json`: dois owners/draw e duas geometrias, uma
candidata precoce, um armamento,24 mapas,13 amostras apresentadas/65 linhas
de contadores; zero rejeitados, zero eventos da sonda antiga. Limite de owners32
não foi atingido. O mapa atingiu seu teto24; as amostras de apresentação não
são uma contagem final de todas as operações até o encerramento.

Última amostra de contagem, prim5.500.019: draw5.500.019,below2M,
unchanged3.500.011,nonCandidate6,candidates2,capped0,invalid0;
IMAGE258.138,below112.414,unchanged145.724,sem candidatos. HWREG/local-copy/
clear continuam sem chamadas observadas. Isso exclui mudanças líquidas desses
caminhos **no endereço e janela medidos**, não exclui uploads para outras
regiões/texturas nem mudanças restauradas dentro de uma operação.

Capturas apresentadas: PNG1(60.018ms/499.076prims),PNG2(360.028ms/2.123.386),
PNG3(660.032ms/5.288.487),todasok=1. Inspeção: legal → cena malformada sem
faixas superiores → mesmas faixas brancas/ciano. Não é confirmação de menu.
5cd758:14 marcadores,maior chamada4096;5e89f8:nenhum marcador observado;
STQ variável:24 marcadores,maior chamada4.194.304;nenhum erro de função
não implementada observado. Sem estimativa nova de FPS ou jogabilidade.

`Analyze-EntryCoverage.js` agora aceita a pasta de logs como terceiro argumento
e falha se os logs não existem, evitando que um caminho incorreto seja reportado
como zero cobertura. Também expõe `.stop.json` para distinguir término deliberado.

## Atlas e entrega

Projeto existente `progress/.openai/hosting.json`:
`appgprj_6aa071fd64c48191934c093a31ed2217`.
O get_site retornou **Sites project not found (404)**; list_sites retornou lista
vazia na conexão atual. Nenhum site substituto foi criado e audiência não foi
alterada. Publicação remota bloqueada por acesso/visibilidade da conexão;
não tratar como publicação concluída. Texto local atualizado em `progress/app/page.tsx`,
mantendo catálogo/porcentagens e funcionalidades. Build de produção do atlas PASS.
O lançador Sites `build-site.mjs` falhou no npm.cmd local (prefixo resolvido para
a pasta do projeto); o mesmo script `npm run build` passou via npm-cli.js absoluto:
`rtk proxy node "C:\Program Files\nodejs\node_modules\npm\bin\npm-cli.js" run build`.
Nenhuma dependência/lockfile/configuração foi modificada para esse contorno.
Sem nova inspeção no navegador ou abertura de janela; alteração foi de texto.

Fontes finais, patches, logs, capturas e hashes são preservados pelo fechamento
em `<scratch-dir>/mc3-surface-20260913/closing/`; nenhuma captura,
asset ou código do jogo foi enviado ao Sites. O trabalho encerra antes do teto
de180 minutos porque a fronteira de observação prevista foi alcançada e o
próximo experimento exige uma seleção nova de dados, não repetição desta rodada.

## Rollback

Os defaults continuam OFF. O executável original em E: não foi substituído.
Para reverter somente as mudanças deste lote, usar cópias prévias de
`baseline_v2` para os arquivos alterados (GPU header/cpp, rasterizer e harness),
preservando qualquer edição posterior. Não resetar os repositórios inteiros.
Os novos scripts/header/relatório são arquivos adicionais; mantê-los como
evidência não ativa a sonda. Build/runner em C: são artefatos separados.
