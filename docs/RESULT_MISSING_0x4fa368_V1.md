# Resultado — passo 24: missing-function 0x4fa368

Data: 2026-08-22. Projeto: mc3recomp. Sem commit/push nesta rodada.

## Evidência do ELF e do código

A tabela em `.data` foi confirmada no ELF retail `extracted_iso/SLUS_213.55`:

| Endereço .data | Ponteiro little-endian |
|---|---|
| `0x619fc8` | `0x004fa2b8` |
| `0x619fd0` | `0x004fa308` |
| `0x619fd8` | `0x004fa368` |
| `0x619fdc` | `0x004fa378` |
| `0x619fe4` | `0x004fa388` |

`0x004fa368` não existe como função em `work/exports/SLUS_213.55.ghidra.csv` nem em `retail_symbol_port.csv`. A sequência de bytes procurada `a0f34f00` não apareceu; o ponteiro observado é `68 a3 4f 00`.

O C++ gerado vizinho confirma:

- `0x4fa368: daddu v0,a1,zero`
- `0x4fa36c: lui v1,0x6f`
- `0x4fa370: jr ra`
- delay slot `0x4fa374: sw v0,0x408c(v1)`
- `0x4fa378` e `0x4fa388` são os dois callbacks seguintes
- `0x4fa398` é `zipFile::Init`

A classe comprovada tem 5 slots: 2 funções já conhecidas e 3 entry targets ausentes do mapa Ghidra.

## Fix no gerador

Alterados:

- `PS2Recomp/ps2xRecomp/src/lib/code_generator.cpp`
- `PS2Recomp/ps2xRecomp/include/ps2recomp/code_generator.h`
- teste em `PS2Recomp/ps2xTest/src/code_generator_tests.cpp`

O gerador agora coleta ponteiros alinhados de seções de dados e promove grupos compactos de tabela/callback que contêm um boundary de função conhecido. A classificação é cacheada por passe de descoberta; os alvos são enviados pelo caminho normal de entry points externos. Não houve SignalSema injetado, env-gate, alteração do scheduler ou patch manual do runtime.

O teste novo cobre ponteiro para meio de função, boundary no fim de função e palavra não-código.

## Regeneração e build

- Regeneração: `04_run_recomp.bat` concluída.
- Entry points resumíveis: `96974 -> 97025`.
- Owners: `13531 -> 13533`.
- Diff byte-a-byte do corpus: 20 arquivos C++.
- Objetos efetivamente recompilados: 18.
- `tools/parallel_compile.py`: 18/18, falhas 0.
- `python tools/find_stale.py`: Missing 0, Stale 0.
- `10_link_partial_runner.bat fast`: link concluído em `work/link/partial/mc3_partial.exe`.
- Suíte completa: 273/273.

O owner gerado `sub_004FA0D8_0x4fa0d8.cpp` passou a conter `case/label` para `0x4fa368`, `0x4fa378` e `0x4fa388`.

## Medição

Com `MC3_DETERMINISTIC=1` e `MC3_DISPATCH_BUDGET=100000`:

- Uma execução de `14_run_boot_trace.bat` foi concluída.
- Não apareceu `[dispatch:first-bad-pc]` nem `bad=0x4fa368` no log dessa corrida.
- O trace não alcançou evidência de `zipOpen`, `ASSETS.DAT` ou `flag619f40 != 0`.
- Contadores observados: `gifPkTotal=0`, `gsPrims=0`, `gsPixels=0`.

`21_probe_repeat.bat 3 probe missing_4fa368` não produziu prova determinística válida:

- as 3 corridas deram `marker=no` e `timeout=yes`;
- PCs estáveis divergentes: `0x4adc44`, `0x432aa0`, `0x223480`;
- `First bad PC: -` nas três;
- `gifPkTotal=0` e `gsPrims=0` nas três.

## Veredito

A classe de dispatch foi fechada na geração e o `bad=0x4fa368` não reapareceu no boot trace. Porém não há prova de asset manager aberto nem render real. Como `gifPkTotal=0` e `gsPrims=0`, a condição de vitória não foi atingida; a investigação deve parar aqui para este passo, sem forçar avanço.

Artefatos: `work/logs/14_run_boot_trace.log`, `work/boot_probe/repeat_missing_4fa368_20260822_043703.md`, `work/logs/10_link_partial_runner.log`.
