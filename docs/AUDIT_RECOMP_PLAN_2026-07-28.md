# Auditoria do Plano Gemini — `RECOMP_PLAN_2026-07-28.md`

Autor da auditoria: Claude (Sonnet 5), 2026-07-28.
Objeto auditado: `docs\RECOMP_PLAN_2026-07-28.md`.
Método: não confiei nas alegações do plano — reexecutei os checks contra o estado real do filesystem antes de pontuar.

## Veredito rápido

**Score: 6.5/10.** Diagnóstico da causa-raiz (Etapa 4, vtable+0x24 / texture.zip) é bom e específico. Mas as Etapas 1–2 partem de um estado **desatualizado**: o plano manda recompilar o `batch_0015` como se ainda faltassem 8 objetos, quando na verdade **os 8 já foram compilados** (verificado abaixo). Isso não quebra nada se alguém rodar a Etapa 1 de novo (é idempotente, só perde tempo), mas mostra que o plano foi escrito sem checar o filesystem atual — só releu o `PS2_PROJECT_STATE.md` (checkpoint 07-22) sem validar contra a realidade em 07-28.

## O que verifiquei (fatos, não suposições)

1. **`batch_0015` está 100% compilado.**
   - `work\compile\ghidra\batch_0015\obj\` contém os 8 objetos que o plano lista como pendentes (`sub_002A4B98_0x2a4b98.o`, `sub_002A4C18_0x2a4c18.o`, `sub_002A4C68_0x2a4c68.o`, `FUN_002a4d68_0x2a4d68.o`, `FUN_002a4d78_0x2a4d78.o`, `sub_002A4DC0_0x2a4dc0.o`, `FUN_002a4e08_0x2a4e08.o`, `FUN_002a4f40_0x2a4f40.o`), todos com timestamp **2026-07-28 00:17**.
   - `work\compile\ghidra\batch_0015\batch_0015.object.summary.csv` tem 250 linhas de dados, todas com exit code `0`. **Nenhuma falha.**
   - Conclusão: **Etapa 1 do plano já está feita.** Rodá-la de novo não quebra nada (idempotente), mas é trabalho desperdiçado se prescrito como "próximo passo".

2. **Já houve uma tentativa de relink hoje, e ela não completou.**
   - `work\logs\10_link_partial_runner_driver.log` tem uma única linha: `Link partial MC3 runner - 28/07/2026 0:17:39` — ou seja, o script rodou logo após o fim da compilação, mas o log não tem nem a etapa `GENERATE` nem `LINK_ONLY` reportadas.
   - `work\logs\10_link_partial_runner.log` (log interno do `Link-PartialRunner.ps1`) está **vazio (0 bytes)**.
   - `work\link\partial\mc3_partial.exe` continua com timestamp **2026-07-11 05:42** — não foi regerado.
   - `work\link\partial\register_functions.partial.cpp` e `missing_functions.partial.cpp` são de **2026-07-14** — não foram regenerados hoje, então o manifest de missing-functions ainda lista os 9 endereços do `batch_0015` como faltantes, o que agora é falso.
   - Não há processo `g++`/`ld` rodando agora — não é uma etapa "travada em execução", é uma tentativa que parou/foi interrompida antes de escrever qualquer log.
   - **Isso é a evidência mais acionável que o plano da Gemini não tinha**: a Etapa 2 (relink) já foi tentada e falhou silenciosamente. Não adianta só rodar `10_link_partial_runner.bat` de novo sem entender por quê o `GENERATE` (que chama `tools\Generate-PartialRegister.ps1`) não deixou rastro.

3. **`Link-PartialRunner.ps1` já hardcoda o path do g++** (`C:\msys64\ucrt64\bin\g++.exe` — linha 3), então o problema de `PATH` que a Gemini cita na Etapa 1 (para o `cc1plus` do compile ad-hoc) **não se aplica à etapa de link**. Bom identificar isso para não perder tempo "corrigindo" um PATH que já está resolvido no script de link.

4. **Etapa 4 (causa-raiz) é o ponto forte do plano.** A hipótese — vtable slot `+0x24` de `0x6d557c` retorna null porque o provedor de pacotes falha ao abrir `texture.zip` (handle `0xffffffff`) — é específica, aponta para funções e globals concretos (`sub_004FAED8_0x4faed8`, `sub_004F9A68_0x4f9a68`, flags `0x629f40/41/4c`), e é consistente com a metodologia anti-alucinação do projeto (comparar com PCSX2 real via MCP antes de promover qualquer fix). Isso está alinhado com `docs\MASTER_PLAN_TITLE_SCREEN.md` (regra: nada vira permanente sem evidência live).

## Lacunas do plano

- Não verificou o estado real do build antes de prescrever a Etapa 1 (deveria ter rodado `dir` / conferido o summary.csv).
- Não notou que já existe uma tentativa de link falha de hoje — perde a chance de diagnosticar a causa do log vazio (possível: `Generate-PartialRegister.ps1` crashou, terminal fechado antes de terminar, ou exceção do PowerShell engolida antes do primeiro `>>`).
- Não menciona nada sobre pular os vídeos/FMV do jogo — pedido explícito do usuário para hoje. Ver handoff abaixo.

## Recomendação para quem for validar/rodar

Não repita a Etapa 1. Vá direto para: (a) diagnosticar por que o relink de 00:17 não gerou log, (b) rodar o relink completo (não-fast, já que o manifest de missing-functions está desatualizado) em primeiro plano observando stdout/stderr diretamente, (c) só então rodar o boot probe.
