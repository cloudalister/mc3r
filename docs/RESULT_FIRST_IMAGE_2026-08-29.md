# RESULT — primeira imagem do jogo saindo do recompilado — 2026-08-29

## Resultado

**O motor gráfico funciona ponta a ponta.** A tela legal do Midnight Club 3 foi exportada
como PNG a partir do recompilado, com logo, kanji, texto legal e aviso Dolby legíveis.

Isso encerra a dúvida que o projeto carregava havia semanas: `gsPrims`/`gifPk*` não eram
tráfego abstrato — são a imagem correta do jogo.

Ainda **sem prova de modelo 3D de carro**.

## Como foi obtido

O runtime já possuía a facilidade `MC3_FRAME_DUMP` (`ps2_runtime.cpp:252`), que exporta o
frame de apresentação como imagem quando `gsPrims` passa de `MC3_FRAME_DUMP_MIN_PRIMS`.
Ela existia antes desta sessão e não estava sendo usada.

Driver criado: `work/scratch/Run-FrameDump.ps1`.

Capturas em `work/captures/`:

- `frame_20260829_dump.png` — frame de apresentação, **imagem correta**
- `frame_20260829_dump_ctx0.png` / `_ctx1.png` — dumps por contexto, com o mesmo conteúdo
  **repetido ~4x na horizontal e entrelaçado**, assinatura clássica de stride/pitch errado
  na leitura por contexto. Não afeta o frame de apresentação; fica registrado como defeito
  separado do dump por contexto.

## Consertos desta sessão

Cinco funções que o jogo chamava e não existiam.

**`0x24A368`** — não era endereço no meio de bloco, e sim **prólogo de função**
(`nop` em `0x24a364`, `addiu $sp,$sp,-0x10` em `0x24a368`). O Ghidra fundiu duas funções na
faixa `0x24a2a8-0x24a3e0` (`mcCullable::SetClippingAndSphereTest`). Conserto: `case`+`label`
(classe `0x5B92E0`); `tools/Generate-PartialRegister.ps1:64` emitiu o alias sozinho.

**`0x5BB170`, `0x5BB178`, `0x5BB220`, `0x5BD030`** — acessores-folha de 2-3 instruções que o
Ghidra não delimitou por virem colados em outras funções. Decodificados palavra a palavra do
ELF retail:

```
0x5BB170   jr $ra / addiu $v0, $a0, 0x54      ->  return this + 0x54
0x5BB178   lw $v0, 0x134($a0)                 ->  v0 = *(this+0x134)
           jr $ra / lwc1 $f0, 0x270($v0)          f0 = *(v0+0x270)
0x5BB220   jr $ra / addiu $v0, $a0, 0x40      ->  return this + 0x40
0x5BD030   jr $ra / addiu $v0, $zero, 1       ->  return 1
```

Escritos à mão em `work/generated/ghidra/`, adicionados a `work/index/functions_index.csv`
**e** a `work/exports/boundary_port.csv`, para que a próxima regeneração completa os produza
pelo caminho oficial. Não se re-rodou `04_run_recomp.bat` porque isso regeneraria os 15.8k
arquivos e apagaria a instrumentação manual acumulada em várias sessões.

Script: `work/scratch/add_leaf_accessors.py`.

**Resultado:** `recover-pc` do dispatcher de **71 → 0**; zero PCs ausentes. Primeira vez que
o jogo executa sem o dispatcher pular chamada nenhuma.

## Input funcionando

Primeira vez que uma tecla atravessa até o guest. Com janela visível (headless cria a janela
com `FLAG_WINDOW_HIDDEN`, que nunca recebe foco), `Enter` chega ao pad do jogo:

```
mc3-guest-pad-read  read=15  data2=0xf7 data3=0xbf  start=1
mc3-iopad-state     poll=15  buttons=0x00000840    start=1
```

Até 11 publicações numa corrida. Com Start, o jogo sai de `0x322FFC` (onde ficava parado sem
input) e avança até `0x41D188`.

Consequência: **não é necessário** o plano B de expor `setPadOverrideState` (`Pad.cpp:821`).
O caminho real funciona.

## Estado da apresentação — em aberto

Um print do usuário mostrou a janela **preta** enquanto havia conteúdo renderizado. A
investigação disso produziu dados e uma retratação:

- Trace novo `[boot-trace:present-upload]` em `UploadFrame`: dimensões corretas
  (`w=640 h=448`, `scratch=1146880`) e **`nonZeroPx` crescendo de 0 até 142.556** de 286.720
  pixels. **A apresentação recebe conteúdo.**
- Portanto a hipótese "a captura vem preta da origem" está **refutada**. Ela foi formulada a
  partir das 8 primeiras amostras do boot, quando o framebuffer legitimamente ainda era
  preto, e extrapolada indevidamente.
- Divergência que permanece e não foi explicada: `displayFbp` reportado pela apresentação é
  `0x0` **em toda a corrida**, enquanto o registrador `dispfb1` do GS chega a `0x11000`. O
  conteúdo aparece mesmo assim.

**Não está estabelecido** se a janela ainda fica preta com o binário atual. O print é
anterior ao conserto das quatro folhas. Falta observação direta.

## Erros de diagnóstico desta sessão

Quatro afirmações minhas foram derrubadas pelo dado seguinte, todas pelo mesmo padrão —
tratar evidência parcial ou amostra não representativa como conclusão:

1. **`-O0` como gargalo dominante da lentidão.** Medido: ganho de ~20%, não ordem de
   magnitude. O subagente havia marcado a estimativa como não medida.
2. **`-skipintro`/`-garage` como atalho legítimo do jogo.** Não existem no ELF retail
   (`PARAM_` = zero ocorrências); `argc` é sempre 0 em retail. O agente havia marcado como
   não confirmado e eu repassei como fato.
3. **`gsPrims=704397` como baseline.** Vinha de execução com 71 chamadas puladas.
4. **A correção do item 3.** Concluí que as quatro folhas eram fantasmas do caminho quebrado;
   elas eram reais e estavam à frente — só não eram alcançadas sem input. Comparei duas
   corridas que diferiam em duas variáveis e atribuí tudo a uma.
5. **"A apresentação recebe buffer preto"** — refutado pelo próprio trace corrigido.

O antídoto foi sempre o mesmo: ir à fonte primária (ELF, disassembly, log cru, pixel). O
`MC3_FRAME_DUMP`, que resolveu a questão central do dia, já existia no runtime.

**Regras que saem daqui:**

- O MC.MAP do alpha é fonte de pistas, nunca de fatos sobre o retail. Induziu erro duas vezes
  nesta semana.
- Antes de afirmar causa, ir à fonte primária.
- Não extrapolar de amostra de boot inicial para o estado geral.

## Defeitos na própria instrumentação (corrigidos)

- A primeira versão do trace de apresentação re-disparava só quando `w/h/scratch` mudavam —
  que nunca mudam. Só produziu amostras do boot. Corrigido para disparar em mudança de
  `displayFbp`/`sourceFbp` e de bucket logarítmico de `nonZeroPx`.
- `std::hex` vazava entre chamadas concorrentes, produzindo linhas como `w=280 h=1c0`.
  Corrigido salvando/restaurando `std::cerr.flags()`.
- Traces concorrentes no `std::cerr` não são atômicos; linhas de threads diferentes se
  intercalam (`present-upload n=2 intcStat=0x80c`). Não corrompe dado, mas atrapalha parsing.

## Próximos passos

1. Confirmar por observação direta se a janela ainda fica preta no binário atual.
2. Explicar `displayFbp=0x0` versus `dispfb1=0x11000`.
3. Instrumentar a camada `rmc*` — `rmcModel::Draw` (`0x002A9918`), `DrawCpv` (`0x002A9A88`),
   `rmcCarModel::Init` (`0x002F6C48`). A instrumentação atual está na camada `gfx*`, e a
   evidência de execução aponta para `rmc*`, então "zero `mc3-gfx-*`" nunca mediu nada.
4. Corrigir o stride do dump por contexto.

Sem SignalSema injetado, sem env-gate novo, sem mudança de scheduler/dispatcher/SIF, sem
escrita direta em estado de jogo, sem PCSX2 e sem push.
