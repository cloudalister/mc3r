# MC3 — atribuição da faixa a uma primitiva, 10/09/2026

## Resultado reconciliado em 13/09/2026

A rodada abaixo NÃO está mais ativa. Terminou 10/09 às10:19:45 pelo timeout do
harness:1502.3739775s de parede,997.625s CPU,exitedBeforeLimit=false,exitCode=null.
Cinco PNGs apresentadas ok=1; última com4257869primitivas ainda tem faixas,
inspecionada em13/09. Meta confirma sondaON,bridgeON,STQON,BOOT_TRACE0.
Zero registros surface-write e zero rejeitados pelo parser. 5cd758 observado até
8192chamadas,STQ variável até4194304,nenhum missing observado;5e89f8 não observado.
Resultado negativo da atribuição, não prova de ausência de erro ou vértices bons.
Investigar limiar temporal, endereço/mapeamento e escritores fora de drawPrimitive.
Plano próximo: PLANO_GRAFICOS_NOVA_SESSAO_2026-09-13.md. Seções abaixo são históricas.


Novo lote autorizado por “go”, após encerramento da automação noturna.
Não reativar a automação anterior nem inferir nova janela de trabalho noturna.

## Pergunta

Qual primitiva muda o ponto (256,85), dentro da faixa branca/ciano observada
na PNG5 da rodada STQ, no framebuffer 0? Seus vértices já descrevem uma faixa,
ou a cor errada surge com geometria plausível?

## Sonda limitada, sem correção adicional

`MC3_SURFACE_PROBE=1`, default OFF. Em drawPrimitive, lê um pixel antes/depois,
somente CT32/CT24, FBP 0, após 3 milhões de primitivas. Registra no máximo 32
mudanças de RGB cujo verde e azul finais sejam >=192. Não modifica VRAM.
Parâmetros diagnósticos MC3_SURFACE_X/Y/FBP/MIN_PRIMS têm parsing e limites.
O orçamento é por processo; nenhum dump de assets/VRAM completo ou arquivo novo
é criado pelo runtime. Uma linha por evento reduz interleaving, sem garantir
atomicidade de outros produtores do stderr.

Registra caminho GIF, índice anterior de primitiva, modo/contexto, FRAME,
TEX0/CLUT/TEXCLUT/TEXA, TEST/ALPHA/CLAMP/TEX1/ZBUF/máscara, XYOFFSET, scissor,
vértices decodificados e posição usada pelo raster, STQ, UV e cores.
Não guarda os bytes originais do pacote GIF: não é replay completo.

Limites: não cobre IMAGE/HWREG, PSM16 ou cópias fora de drawPrimitive. Branco/ciano
é candidato, não prova de erro. Mudança neste framebuffer não prova apresentação
final; é preciso correlacionar com capturas. Zero eventos não elimina o defeito.
Strip/fan são mantidos em vertexKick depois de cada draw, não no rasterizer.

## Validação antes do jogo

- Backup pré-alteração: <scratch-dir>/mc3recomp-backups-20260910_0750/before_surface_probe.
  344 cópias verificadas por hash + patches root/runtime; sem sobrescrever anterior.
- Build ps2x_tests: PASS. Suíte OFF: 331/331, log 095315.
- Suíte bridge+STQ+sonda ON: 331/331, log 095320; dois eventos de integração,
  inclusive sprite ciano conhecido, sem alteração dos pixels esperados.
- Testes de parser/VRAM: overflow, limites, leitura sem mutação, modo não suportado,
  mudança só de alpha e filtragem de cor. Cap fixo 32.
- Relink concluído e quatro strings verificadas no exe; mtime exe >= lib.
- Exe SHA256: 1d3bf49bbdc88f23b178978d6ea0797827848581d5e88fd2d6b35acbfca9ac0b.
- Lib SHA256: bbc15317a462af128d0523973fe00cb9dcd14c44f90cddabb5d28731214aed87.

## Rodada em andamento

`surface_band_20260910_0955`, limite 1500 s, headless/quiet, GSbridge+STQ ON,
Start 30 s/30 s com atraso 45 s, entrada-trace e captura apresentada ligados.
Sessão 89383. Metadados/resultado reais em work/logs/probe_surface_band_20260910_0955.log.*.
Não duplicar runner, recompilar ou relinkar enquanto ativo.
Ainda não há conclusão visual nova nesta etapa.
