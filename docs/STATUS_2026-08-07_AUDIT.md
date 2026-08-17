# Auditoria de estado — MC3 Recomp — 2026-08-07

Autor: Claude (Opus 5). Método: reexecutei tudo antes de afirmar. Nenhum número aqui vem de doc anterior sem eu ter reproduzido.

## Conclusão em uma frase

**O boot probe não é determinístico, e isso invalida o critério de sucesso usado nos últimos ~10 lotes de trabalho.** Cinco corridas idênticas produziram cinco Stable PCs diferentes e quatro classificações diferentes. Nada foi "consertado" ou "quebrado" nos últimos dias no sentido que os relatórios sugerem — estávamos medindo ruído.

## A evidência

Cinco corridas consecutivas, mesmo binário, mesmo modo (`595`), mesma duração (8s), nenhuma variável de ambiente:

| Run | Classification | Stable PC | First bad PC | Counters |
|---:|---|---|---|---|
| 1 | unknown-loop | `0x54c29c` | — | dma=0 gif=0 gsw=0 vif=0 |
| 2 | missing-function | `0x2469b0` | `0x42eb48` | dma=0 gif=0 gsw=0 vif=0 |
| 3 | missing-function | `0x545660` | `0x42eb48` | dma=0 gif=0 gsw=0 vif=0 |
| 4 | render-started | `0x3` | `0x42eb48` | dma=0 gif=0 gsw=0 vif=2 |
| 5 | render-started | `0x5a8908` | `0x42eb48` | dma=2 gif=0 gsw=0 vif=3 |

Relatório bruto: `work\boot_probe\repeat_baseline_20260807_20260807_013345.md`. Reproduzível com `21_probe_repeat.bat 5 595 <label>`.

Antes disso eu já tinha rodado 6 corridas avulsas no mesmo dia: `0x1a0e84`, `0x3985d8`, `0x546d60`, `0x246708`, `0x546d60`, `0x246758`. Nenhuma repetiu o valor da anterior de forma confiável.

### O que isso significa na prática

- **`Stable PC` isolado não é evidência.** A run 5 reproduziu exatamente `0x5a8908` + `dma=2 vif=3` — o estado que os relatórios de 28/07 a 03/08 tratam como "o estado do projeto". Ele é **um dos cinco resultados possíveis**, não o estado.
- **Comparação "antes vs depois" com n=1 é inútil.** Um experimento que "moveu o PC" pode não ter feito nada; um que "não moveu" pode ter funcionado. Todas as decisões de reter/descartar experimento tomadas por esse critério precisam ser reavaliadas.
- **A run 4 devolveu Stable PC `0x3`** — endereço sem sentido, e ainda assim foi classificado `render-started`. O classificador aceita lixo.
- O único sinal estável em 4 das 5 corridas (e em 100% das 6 avulsas) é `first-bad-pc = 0x42eb48`.

## Onde estamos de fato

**Não há vitória visual.** `gif=0` e `gsw=0` em todas as corridas de hoje, sem exceção. O critério declarado do projeto — algo aparecer na tela — não foi atingido e não chegou perto. A tela rosa continua sendo framebuffer fallback.

O que existe de sólido, acumulado pelos lotes anteriores (isso continua válido, é análise estática e leitura live, não depende do probe):

- Mapa dos globais do provider e do lifecycle: `0x619F40` (flag), `0x619F44` (primary), `0x619F4C` (fallback), backend slots `0x618020/0x618024 = 0x617F88`.
- Snapshot PCSX2 real preservado: primary `0x629F44=0x5C0C40`, fallback `0x629F4C=0x41F9B0`, cadeia `0x618020 -> 0x619F58 -> 0x4F9760`.
- Correção de arquitetura do lote 21: `0x4F9760 -> 0x4FB0D8` é **registro/seleção de extensão** (`.tex`, `.xtex`, `.tga`, `.bmp`, `.ipu`, `.spr`), não o request do nome lógico. Isso desmente a leitura anterior e evita conectar `ASSETS.DAT` cedo demais.
- Semáforo 17: produtor correto identificado (`sub_005420C0`, em `0x54223C` e `0x542290`). Decisão de **não** injetar sinal está certa e deve ser mantida.
- Instrumentação `MC3_TRACE_PROVIDER` e `MC3_TRACE_LOGICAL_RESOLVER` existem, são env-gated e reversíveis.

## O gap de dispatch `0x42eb48`

`work\generated\ghidra\sub_0042EB08_0x42eb08.cpp` (regenerado em 01/08 06:08) tem, no `jr $ra` de `0x42EB40`, um switch de jump target com os casos `0x42EB24`, `0x42EB28`, `0x42EB2C`, `0x42EB84`, `0x42EB90`, `0x42EBCC` — **e nenhum caso para `0x42EB48`**. Não existe `label_42eb48`; o código em `0x42eb48` só é alcançável por fall-through.

O handoff de 2026-06-17 registra que um patch manual adicionou casos para `0x42eb48` **e** `0x42eb90`. O arquivo atual tem só o `0x42eb90`. Metade do patch se perdeu na regeneração.

**Cuidado com a interpretação:** em 28/07 o `first-bad-pc` era `0x42eb90` e o probe classificava `render-started`. Hoje é `0x42eb48`. Ou seja, o `0x42eb90` foi de fato resolvido e o bloqueio andou para o próximo endereço da mesma função — comportamento esperado. Isso **não** é a causa da não-determinância, e provavelmente não é a causa da ausência de render. É uma dívida real a pagar, não a bala de prata.

## Ferramentas novas desta auditoria

| Ferramenta | Uso | Para quê |
|---|---|---|
| `21_probe_repeat.bat N modo label [ENV=V]` | `21_probe_repeat.bat 5 595 baseline` | Roda N probes, agrega, e declara se o Stable PC é utilizável como métrica naquele modo |
| `20_verify_boot_state.bat` | guarda de regressão | Hoje retorna **FAIL** (classification=missing-function) — está funcionando como deveria |

## O que eu recomendo parar de fazer

1. **Parar de rodar probe único e tirar conclusão.** Substituir por `21_probe_repeat.bat` com N≥5 em todo experimento.
2. **Parar de tratar "Stable PC mudou" como progresso.** O critério de aceite precisa virar `gif>0 ou gsw>0` (render real) ou uma métrica agregada estável.
3. **Parar de abrir frente nova antes de fechar a medição.** Os lotes 13→21 abriram provider, asset bridge, logical resolver e FMV em paralelo, todos avaliados por um instrumento que não mede. Fechar o instrumento primeiro.

## Handoffs derivados

- `docs\HANDOFF_2026-08-07_A_DETERMINISM.md` — **bloqueador de tudo.** Descobrir e eliminar a fonte de não-determinismo.
- `docs\HANDOFF_2026-08-07_B_DISPATCH_0x42EB48.md` — fechar o gap de dispatch e impedir que regeneração apague patches manuais de novo.
- `docs\HANDOFF_2026-08-07_C_PROVIDER.md` — continuar a frente provider, **travada** até A entregar.
