# RESULT — Passo 26: tabela de ponteiros do zipFile (V1)

Data: 2026-08-22  
Base do projeto: `0e861c9`  
Base do PS2Recomp: `be749a5`  
Estado: **PARCIAL — rejeitado no sanity check; nenhum gerado foi compilado**

## Resultado executivo

O limite fixo de span `<= 0x100` foi confirmado como a razão pela qual a tabela legítima `coreFileMethods`, em `.data`, não promove os corpos internos do `zipFile`. Foi experimentada uma substituição estrutural, sem trocar o limite por outro número mágico: cada alvo precisava ser executável, alinhado, pertencer a um owner recompilado e cair em uma fronteira de corpo reconhecível; a agrupação contígua `+8` permaneceu.

Os testes sintéticos passaram, inclusive uma tabela legítima com span maior que `0x100` e um caso negativo de ponteiros contíguos que não formam tabela. Porém, no ELF real o filtro ainda aceitou **1001 grupos ancorados e 1290 alvos dentro de owners**. Esse conjunto não é um delta pequeno nem explicável para os cinco entrypoints esperados. Conforme a trava obrigatória do handoff, o trabalho foi interrompido antes de compilar gerados, relinkar ou executar o jogo.

Não há aceite funcional neste passo. `bad=0x4f9918`, plateau do tokenizer, `zipOpen`, `flag619f40`, leitura do conteúdo de `ASSETS.DAT`, GIF e GS não foram reavaliados com um binário novo.

## Diagnóstico confirmado

A tabela retail conhecida é:

| Tabela | Endereço em `.data` | Span observado | Alvos ausentes esperados |
|---|---:|---:|---|
| `coreFileMethods` do `zipFile` | `0x619f58` | `0x2e8` | `zipCreate 0x4f9910`, `zipRead 0x4f9918`, `zipWrite 0x4f9948`, `zipSeek 0x4f9950`, `zipSize 0x4f9a48` |

O estado de entrada do passo continuava compatível com o handoff: `zipRead` não tinha registro e o trace anterior caía repetidamente em `bad=0x4f9918` durante o tokenizer.

## Mudança experimental — rejeitada e revertida

A implementação experimental:

- removeu o critério global `maxTarget - minTarget <= 0x100`;
- validou cada alvo por alinhamento e seção executável;
- exigiu owner recompilado conhecido, ou fronteira exata já conhecida;
- reconheceu início de corpo interno apenas em padrões estruturais de retorno/delay slot;
- manteve a contiguidade `+8` da tabela;
- usou índice ordenado de owners somente para reduzir o custo da busca.

Ela não foi mantida porque a validação individual ainda era permissiva no corpus real. O patch rejeitado está preservado apenas como evidência em `work/checkpoints/pass26/rejected_generator.patch`; o submódulo foi restaurado ao conteúdo exato de `be749a5` e ficou sem diff.

Nenhum `SignalSema` foi injetado, nenhum env-gate foi criado, nenhum endereço alpha foi portado, e o scheduler não foi alterado.

## Testes do gerador

Foram adicionados experimentalmente e executados:

1. tabela legítima com span maior que `0x100`, contendo alvos válidos e rejeitando alvos executáveis sem owner/fronteira;
2. caso negativo com sequência contígua de ponteiros para código, mas sem uma fronteira válida que a ancore como tabela.

Com a tentativa ainda aplicada, a suíte chegou a **275/275** no retry. Duas execuções separadas deram **274/275** por uma falha intermitente já observada em `sceGsSyncV` (`second interlaced ... odd field`); os testes novos do gerador passaram nessas execuções. Como a implementação foi rejeitada no ELF real, os testes experimentais também foram revertidos e permanecem apenas no patch arquivado.

## Sanity check da regeneração

Referências de entrada:

- baseline registrado pelo handoff: `96974 -> 97025` no passo 24;
- `register_functions.cpp` atual: 5.927.094 bytes, timestamp `2026-08-22 04:21:46`;
- cópia anterior: mesmo tamanho e mesmo timestamp;
- contagem auxiliar atual: 92.602 registros únicos pelo critério do script local.

Tentativas realizadas:

| Tentativa | Resultado |
|---|---|
| filtro amplo sem span | abortada após mais de 14,5 minutos, antes de qualquer escrita |
| validação estrutural com busca linear de owner | abortada após mais de 10 minutos, antes de qualquer escrita |
| mesma validação com índice de owners | o processo atingiu o diagnóstico real e terminou com `-1073741819` (`0xC0000005`); o `.bat` reportou sucesso indevido para esse código negativo |

Linha decisiva do diagnóstico, em `work/logs/pass26_direct_count.log`:

```text
[data-pointer-tables] anchored=1001 owner-targets=1290 boundary-targets=0
```

Sanity final:

- entrypoints novos efetivamente gerados/registrados: **0**;
- candidatos pré-promoção: **1290**, vindos de **1001 grupos/tabelas ancorados**;
- tabela explicável esperada neste passo: **1**, `coreFileMethods @ 0x619f58`, com **5** alvos;
- arquivo gerado alterado: **não**;
- lista completa das 1001 tabelas: não materializada, pois o gate mandava parar assim que o falso-positivo em massa fosse constatado.

O acesso inválido ocorreu depois de a descoberta excessiva já estar provada. Não foi atribuído causalmente sem depurador/backtrace e não muda a reprovação do filtro.

## Etapas deliberadamente não executadas

Por falha no sanity check, não foram executados:

- `parallel_compile.py` dos gerados;
- `find_stale.py` final;
- relink fast;
- suíte final sobre artefatos regenerados;
- corrida determinística com `MC3_DISPATCH_BUDGET=100000`;
- probe 3x;
- qualquer confirmação de render.

Isso evita compilar e testar um conjunto contaminado por falsos positivos.

## Evidências preservadas

- `work/checkpoints/pass26/04_run_recomp.before.log`
- `work/checkpoints/pass26/register_functions.before.cpp`
- `work/checkpoints/pass26/04_run_recomp.aborted-wide.log`
- `work/checkpoints/pass26/04_run_recomp.aborted-linear-owner.log`
- `work/checkpoints/pass26/rejected_generator.patch`
- `work/logs/pass26_direct_exit.log`
- `work/logs/pass26_direct_count.log`

## Conclusão e próximo passo recomendado

O span mágico não pode ser substituído apenas por “alvo dentro de owner + aparência de início de corpo”: isso ainda promove candidatos em massa. A próxima tentativa precisa provar a tabela no nível do uso/owner da própria `.data` — por exemplo, relacionando o grupo a referências reais que carregam aquela vtable/method table — antes de promover individualmente os alvos executáveis. O caso `coreFileMethods @ 0x619f58` deve continuar sendo o positivo real, sem criar exceção por endereço e sem enfraquecer o filtro global.

Até existir esse discriminador, o Passo 26 permanece **parcial e sem avanço de boot comprovado**.
