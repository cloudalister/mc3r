# Build incremental do MC3

Data: 2026-08-24

## Problema encontrado

`04_run_recomp.bat` reescreve os C++ gerados e atualiza todos os mtimes.
`find_stale.py` comparava somente mtime, então uma mudança em um único owner
fazia `parallel_compile.py` recompilar 15.811 objetos.

## Solução

`tools/find_stale.py` e `tools/parallel_compile.py` agora usam
`work/exports/compile_manifest.json`, com SHA-256 do C++ e uma chave explícita
dos flags/toolchain. Mtime mais novo, sozinho, não torna um objeto stale se o
conteúdo e a chave de compilação não mudaram.

Após o ciclo integral atual terminar, o manifesto é criado com:

```text
python tools/seed_compile_manifest.py
```

Esse comando só aceita `Missing 0` e `Stale 0`. Nos ciclos seguintes, o fluxo é:

```text
04_run_recomp.bat
python tools/find_stale.py
python tools/parallel_compile.py
python tools/find_stale.py
Generate-PartialRegister.ps1
recompilar register_functions.partial.o
10_link_partial_runner.bat fast
```

O primeiro ciclo depois da regeneração ainda é o baseline completo; os próximos
devem recompilar apenas owners cujo SHA-256 mudou, mais o registro parcial. O
manifesto não cobre `register_functions.cpp`, que tem ciclo próprio e deve ser
regenerado/recompilado explicitamente antes do relink.

## Próximos lotes

O lote atual é `0x5b9080`, comprovado dentro de `sub_005B8E08`. Depois do probe,
o script deve extrair o novo `bad=` dominante e o próximo owner deve ser provado
no Ghidra/native analyzer antes de entrar no CSV. Cada lote deve conter uma
fronteira, com sanity de `+1`, sem semântica inventada.

Critérios de parada por lote:

- `bad` anterior zerado ou não repetitivo;
- novo PC nomeado ou novo bloqueio documentado;
- `find_stale.py` Missing 0 / Stale 0;
- `gifPkTotal > 0` e `gsPrims > 0`: parar e reportar;
- `gsPixels > 0`: parar imediatamente como primeiro framebuffer.

Resultado visual continua separado da cobertura estrutural: atualmente o boot
avançou, mas `gifPkTotal=0` e `gsPixels=0`.
