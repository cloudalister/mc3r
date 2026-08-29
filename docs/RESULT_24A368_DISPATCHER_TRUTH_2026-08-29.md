# RESULT — o conserto de `0x24A368` e o que ele revelou — 2026-08-29

## Resultado

**O conserto funcionou, e revelou que o "progresso" registrado antes era artefato do
dispatcher se recuperando de funções ausentes.** O estado que vinha sendo tratado como
baseline (`0x41D188`, `gsPrims=704397`) era alcançado com **71 chamadas de função puladas**.

Nenhum trace `mc3-gfx-*` disparou. **Continua sem prova de modelo 3D de carro.**

## O conserto

`0x24A368` era o PC ausente mais frequente (27 ocorrências). Não era endereço no meio de
bloco — é **prólogo de função**:

```
0x24a364:  nop                        ; alinhamento
0x24a368:  addiu  $sp, $sp, -0x10     ; prólogo
0x24a36c:  sd     $ra, 0x0($sp)
```

O Ghidra fundiu duas funções na faixa `0x24a2a8-0x24a3e0`
(`mcCullable::SetClippingAndSphereTest`), então quem chamava `0x24A368` caía em
"function not found".

Conserto: `case 0x24a368u: goto label_24a368;` mais o label no prólogo — mesma classe do
`0x5B92E0`. O `tools/Generate-PartialRegister.ps1:64` varre exatamente esse padrão e
emitiu o alias sozinho. Patch idempotente em `work/scratch/patch_24a368_resume.py`.

Relink completo (não `fast`, para regenerar o registro). `Missing stub functions: 0`.

## O que mudou — e o que isso significa

| | antes do conserto | depois |
|---|---|---|
| Funções ausentes | 5 distintas, 72 ocorrências | **zero** |
| `recover-pc` (dispatcher) | **71** | **zero** |
| PC final | `0x41D188` | `0x322FFC` |
| `gifPk1` | 348.988 | 348.558 |
| `gsPrims` | 704.397 | 703.599 |
| `gsPixels` | 257.216.311 | 256.036.663 |
| `End=1` | sim | sim |

`recover-pc` é o dispatcher tropeçando numa função ausente e saltando para `ra` — a função
pretendida **não executa**. 71 dessas por corrida significa que o jogo estava rodando
errado.

**Correção de baseline:** `gifPk1=348988` / `gsPrims=704397`, registrados em checkpoints
anteriores como o platô de referência, vieram de execução com 71 saltos indevidos. **Não
são baseline válido.** O baseline honesto passa a ser `gifPk1=348558` / `gsPrims=703599`,
com execução íntegra.

Contadores menores aqui representam **mais** correção, não menos progresso.

## Efeito colateral revelador

As outras quatro ausentes — `0x5BB170`, `0x5BB178`, `0x5BB220`, `0x5BD030` — **sumiram
sozinhas**, sem serem tocadas. Elas só eram alcançáveis pelo caminho quebrado que o
`recover-pc` produzia. Isso confirma que aquele ramo inteiro era espúrio.

Consequência prática: **não vale caçar PC ausente isoladamente**. Um conserto pode
eliminar vários, e um "ausente" pode ser sintoma de caminho errado, não de trabalho a
fazer.

## `0x3451E8` não trava

A instrumentação preexistente (filtrada por `ra == 0x322FFC`) mostra a função chegando a
`stage=0x003454c4`, quase no fim da faixa `0x3451e8-0x3454d8`, e retornando. Foram apenas
**4 chamadas** na corrida inteira — não é laço quente.

Cadeia: `FUN_001a32b0` → `FUN_00322fd8` → `0x3451E8`, que chama
`uiGroup::SetActiveState(bool)` (`0x0041F550`) e mais duas em `0x33A5A0` / `0x33A4B0`
(região de menu). Consistente com montagem de UI.

`pc=0x322FFC` aparecendo em 158/200 frames é o amostrador pegando o quadro mais externo
enquanto a thread guest está parada mais abaixo — não é laço em `0x322FFC`.

## Frente de boot args: encerrada

Verificado diretamente no ELF retail (5.264.872 bytes):

- `skipintro` (case-insensitive), `skip_intro`, `nointro`, `nomovie`, `PARAM_` →
  **zero ocorrências**.
- `garage` → 71 ocorrências, todas em tabela de nomes de layer:
  `"conditions\0ambients\0frontend\0garage\0mc3frontend\0mov..."`. São `mcLayer`, não
  parâmetros de linha de comando.
- `*(0x617F84) = 0x0065c50d` → `"cdrom0:\"`, confirmado de forma independente. O prefixo
  de path é constante compilada, **não** vem de `argv`.
- O bloco fallback `0x677080` está em **BSS** (filesz termina em `0x677074`), logo
  zero-inicializado: em retail `argc` é sempre **0**.

Os `PARAM_*` vieram do MC.MAP do **alpha build** e foram removidos no retail. O mecanismo
de boot args implementado pelo Codex está correto e sem regressão (corrida sem argumentos
reproduz o estado anterior no dígito), mas **não há uso retail para ele**.

**Regra que sai daqui:** o MC.MAP do alpha é fonte de pistas, nunca de fatos sobre o
retail. Esta é a segunda vez que ele induz erro — a primeira foram os endereços de gfx
removidos em `RESULT_ALPHA_GFX_TRACE_REMOVAL_2026-08-29.md`.

## Corrida com janela visível

Primeira corrida não-headless do projeto (`probe_20260829_janela`). Mesmo estado final
(`pc=0x322FFC`, `gsPrims=703599`), taxa ~33 ticks/s contra ~55 headless — custo de
renderizar em janela real.

`padmanStartPublishes=0`: nenhum Start foi publicado ao guest nesta corrida. Não há
evidência de que a tecla tenha sido pressionada; o caminho de input com janela visível
segue **não exercitado**.

## Próximos passos

1. Descobrir onde a thread guest está parada abaixo de `0x322FFC` — o PC amostrado é o
   quadro externo, não o ponto de bloqueio. Precisa de trace de pilha ou de estado de
   thread, não de mais instrumentação de entrada de função.
2. Instrumentar `rmcModel::Draw` (`0x002A9918`), `DrawCpv` (`0x002A9A88`) e
   `rmcCarModel::Init` (`0x002F6C48`). A instrumentação atual está na camada `gfx*`, e a
   evidência de execução aponta para a camada `rmc*`.
3. Exercitar Start com janela visível e confirmar `padmanStartPublishes > 0`.

Sem SignalSema injetado, sem env-gate novo, sem mudança de scheduler/dispatcher/SIF, sem
escrita direta em estado de jogo, sem PCSX2 e sem push.
