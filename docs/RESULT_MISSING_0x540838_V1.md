# Resultado — passo 10: a classe "missing depois da regeneração" (0x540838)

Executa `docs/HANDOFF_FASE1_MISSING_0x540838.md` do início ao fim. Data: 2026-08-18. Branch
`mc3` (fork local, sem push), submódulo `PS2Recomp`. **Resultado misto, honesto**: a classe
inteira do `bad=0x540838` foi identificada, fechada na geração e verificada 3/3 determinístico
— mas o **gate `0x245718` não se moveu**. Investigação mostra que os dois sintomas eram
independentes: `0x540838` travava uma thread cooperativa paralela (sceUsbKb), não a thread
principal parada em `0x245718`. Ver seção "Por que o gate não se move" para a cadeia completa
de evidência.

## Identidade de `0x540838`

Não tem nome alpha. A faixa retail inteira `0x5407C0`–`0x541178` (entre `sceUsbKbSync`
`0x540720` e `sceUsbKbCnvRawCode` `0x541178`) está **sem correspondência** em
`work/exports/retail_symbol_port.csv` — nenhuma função ali bateu com o SDK alpha por hash nem
por callgraph. `0x540838` é código dentro dessa faixa não-portada, parte de uma função maior
que o Ghidra original tinha dividido em duas (`FUN_005407d0` 0x5407d0–0x540834 e
`FUN_00540890` 0x540890–0x540E04, ver `work/exports/SLUS_213.55.ghidra.csv`) e que a passagem
whole-program do recompiler já mesclava numa função só (`sub_005407D0_0x5407d0`,
0x5407d0–0x540f20) por causa de outros alvos já descobertos — mas sem nunca ter descoberto
**esses 5 alvos específicos**. Pela posição (entre `sceUsbKbSync`/`CnvRawCode`, chamada por
uma thread que a trace mostra nascida do handler usbkb 0x80000211) é quase certamente um
handler interno de layout/charset de teclado do driver `sceUsbKb`, mas sem decomp nomeado do
alpha para confirmar — não inventei um nome.

## Por que ficou fora — mecanismo confirmado por trace + leitura de código

Trace ao vivo (`MC3_DETERMINISTIC=1 MC3_DISPATCH_BUDGET=25000`), linha exata do crash:

```
[dispatch:first-bad-pc] bad=0x540838 ra=0x540814 sp=0x19fc30 gp=0x67f070 v0=0x540838
v1=0x61fb44 a0=0x0 a1=0x19fd30
trace=...-> 0x540720 -> 0x5469e0 -> 0x5407d0 -> 0x540838
```

`v0=0x540838` foi lido de `v1=0x61fb44` — um **jump table real em `.data`** (`0x61FB40` +
índice×4), consumido por `jalr $v0` em `0x54080c`, dentro de `sub_005407D0_0x5407d0`. O
disasm confirma o idioma exato (`work/generated/ghidra/sub_005407D0_0x5407d0.cpp`,
pré-fix, 0x5407e4–0x54080c):

```
lw    $v1, 0x90($s0)      ; v1 = índice bruto, válido em [1,5]
addiu $v0, $v1, -1        ; v0 = v1 - 1   <- COPIA decrementada, só para o bounds-check
sltiu $v0, $v0, 5         ; v0 = (v0 <u 5)
...
lui   $v0, 0x62
sll   $v1, $v1, 2         ; v1 <<= 2      <- usa o índice ORIGINAL, não a cópia
addiu $v0, $v0, -0x4C0    ; v0 = 0x61FB40 (base da tabela)
addu  $v1, $v1, $v0
lw    $v0, 0($v1)
jalr  $v0
```

O heurístico de `numCases` em `CodeGenerator::collectInternalBranchTargets`
(`PS2Recomp/ps2xRecomp/src/lib/code_generator.cpp`) que decide quantas entradas de tabela
escanear em `.rodata` procurava um `sltiu`/`slti` cujo `rs` fosse **literalmente** o mesmo
registrador depois deslocado pelo `sll` (o índice usado para montar o endereço da tabela). Aqui
o bounds-check roda sobre uma **cópia decrementada** (`$v0 = $v1-1`), não sobre `$v1` — a busca
por igualdade literal de registrador nunca batia, `numCases` ficava `0`, o bloco que varre
`.rodata` (linha ~1032 antes do fix) nunca rodava, e **nenhuma das 5 entradas da tabela**
(0x540838, 0x540890, 0x540E08, 0x540E58, 0x540E78) virava candidato a entry point — logo
nenhuma ganhava `case` no switch de dispatch nem `label_`, e qualquer despacho batendo
exatamente nelas falhava `hasFunction()` → `[dispatch:first-bad-pc]`.

Mesma família do mecanismo já fechado no passo 9 (`docs/RESULT_FORMATTER_RESUME_V1.md`,
idioma `lui`+`addiu` cross-função): compilador usa um idioma que os heurísticos estáticos do
gerador não previam. Idioma diferente, sintoma idêntico ("código real, gerador nunca viu o
alvo").

## O fix — na geração, não patch manual

`PS2Recomp/ps2xRecomp/src/lib/code_generator.cpp`,
`CodeGenerator::collectInternalBranchTargets`, bloco de detecção de `numCases`: quando a busca
direta (`sltiu`/`slti` com `rs == unshiftedIndexReg`) falha, tenta um segundo padrão — busca um
`ADDIU` que copie `unshiftedIndexReg` para outro registrador (`addiu $copyReg,
unshiftedIndexReg, imm`), e repete a busca de `sltiu`/`slti` contra `copyReg`. O deslocamento da
cópia (`-imm`) vira o **índice inicial** do laço de varredura — crítico, não é só destravar
`numCases`: a faixa válida real era índice `1..5`, não `0..4`; um fix ingênuo que só zerasse o
`numCases` sem ajustar o início teria lido os slots errados da tabela (off-by-one silencioso).
Downstream (checagem de seção/`instructionAddresses`) já filtra qualquer leitura de tabela
espúria, então over-matching aqui é seguro — mesmo racional já documentado no fix do passo 9.

Teste novo em `PS2Recomp/ps2xTest/src/code_generator_tests.cpp` ("rodata jump table with a
decremented bounds-check copy still scans every entry") — reproduz o idioma exato (cópia
decrementada bounds-checked, índice original deslocado), com tabela sintética de 6 slots (um
"veneno" no slot 0 que só vazaria se o índice inicial estivesse errado) e verifica as 5 entradas
reais descobertas E que o veneno não aparece.

## Fechando a classe — regeneração completa, diff byte-a-byte

Rebuild do `ps2_recomp.exe` (MSYS2 g++, mesmo compilador do build principal) → regeneração do
corpus inteiro (`04_run_recomp.bat`, TOML `work/exports/SLUS_213.55.ghidra.toml`, 15812
arquivos) → `diff -rq` contra snapshot pré-fix: **0 arquivos novos/removidos, exatamente 2
arquivos com conteúdo diferente**:

- `sub_005407D0_0x5407d0.cpp` — os 5 `case`/`label_` novos (0x540838, 0x540890, 0x540E08,
  0x540E58, 0x540E78), confirmando as 5 entradas da tabela (índice 1..5) recuperadas de uma
  vez.
- `FUN_004fa2b8_0x4fa2b8.cpp` — **não relacionado**: perdeu a instrumentação diagnóstica manual
  do passo 9 (`MC3_TRACE_PROVIDER`, sem mudança de comportamento) porque regeneração sobrescreve
  o arquivo inteiro. Restaurada byte-a-byte (diff contra o backup pré-fix = idêntico) antes de
  compilar.

Ou seja: **nesta ELF, a classe "0x540838" tem exatamente 1 função-dona e 5 entradas** — não
uma dúzia espalhadas. O manifest `work/link/partial/missing_functions.partial.manifest.csv`
já estava vazio (0 linhas, só header) **antes e depois** — o bug nunca foi visível pro linker
(nunca houve símbolo faltando em tempo de build); é um buraco de dispatch em tempo de execução,
não de link.

## Achado extra (fora do "caso", dentro da "classe" de correção necessária)

Fechar o `0x540838` expôs uma **colisão de registro pré-existente**: o alvo `0x540890` (uma das
5 entradas novas da tabela) é, por coincidência, o **endereço de início real** de uma função
separada já reconhecida pelo Ghidra (`FUN_00540890_0x540890`, registrada como função top-level
independente). `tools/Generate-PartialRegister.js` faz um scan regex cego
(`case 0x...: goto label_...`) sobre **todos** os `.cpp` gerados e registra cada match como
alias, escritos **depois** de todos os registros top-level no `register_functions.partial.cpp`
— então qualquer alias cujo endereço colida com o início real de outra função sequestra
silenciosamente essa função em `PS2Runtime::m_functionTable` (ordem de `unordered_map`, o
último `registerFunction()` vence).

Auditoria pós-fix no corpus inteiro: **450 colisões desse tipo já existiam antes desta sessão**
(não causadas por este fix — são endereços que já eram simultaneamente `case` interno de uma
função E início real de outra, latentes desde sempre no pipeline). Corrigido de forma geral em
`tools/Generate-PartialRegister.js`: aliases são filtrados contra o conjunto de endereços
top-level registrados **antes** de escrever o `.cpp`/manifest — comparação numérica canônica
(não string; o CSV do índice tem zero-padding, a captura do regex não, então uma comparação
ingênua de string nunca batia). Resultado: `167728` aliases (de `168178` brutos, `450`
descartados por colidir com função real), `0x540890` volta a resolver para
`FUN_00540890_0x540890` (confirmado lendo `register_functions.partial.cpp` gerado). Sem essa
correção, o fix de `0x540838` teria **introduzido** uma regressão silenciosa em `0x540890`.

## Trajetória do gate

Relink (`10_link_partial_runner.bat`, sem `fast`): `15811` funções top-level (inalterado),
`167728` aliases internos (era `168173`; líquido +5 das novas entradas da tabela, -450 das
colisões filtradas), `0` missing stubs.

Trace pós-fix (`MC3_DETERMINISTIC=1 MC3_DISPATCH_BUDGET=25000`, `14_run_boot_trace.bat 30`):
**zero ocorrências de `[dispatch:first-bad-pc]`** (era 1 por corrida, sempre `bad=0x540838`).
`work/logs/14_run_boot_trace.log` mostra a thread que antes crashava (a mesma que cria
`sceUsbKb`, IDs 2/3 via `start-thread-request`) agora terminando corretamente — `thread-exit`
duas vezes — e `docs/BOOT_PROBE_STATUS.md` (atualizado automaticamente pelo probe) mostra essa
thread bloqueada num `WaitSema` limpo (`tid=3 sid=5 count=0`) em vez de crashar.

`21_probe_repeat` (via `tools/Probe-Repeat.ps1 -Runs 3 -Mode probe -Seconds 45` — o wrapper
`21_probe_repeat.bat` usa 8s fixos, insuficiente agora que o processo não crasha mais e corre
mais tempo antes do marcador de budget; mesma limitação já registrada em
`RESULT_FORMATTER_RESUME_V1.md`, aqui contornada passando `-Seconds` maior direto pro script):

| Run | Stable PC | First bad PC | Marker | Timeout |
|---|---|---|---|---|
| 1/2/3 | `0x245718` (idêntico) | `-` (nenhum) | yes | no |

3/3 determinístico, `Falhas de evidência determinística: 0`. `bad=0x540838` confirmado **fora**
das 3 corridas.

### Por que o gate não se move

`0x245718` está dentro de `sub_00245680_0x245680`, num `jal func_5420C0` que a trace mostra
executado repetidamente por uma thread de serviço por-vblank — **a thread principal do jogo**,
distinta das threads 2/3 (nascidas via `start-thread-request` em `0x5473b8`/`0x431e00`) que são
quem batia em `0x540838`. As duas coisas rodavam em paralelo desde antes desta sessão: o gate
`0x245718` já aparecia idêntico na primeira corrida capturada **antes** de qualquer mudança
(mesmo `pc`/`ra`, mesmo padrão de frame), e continua idêntico depois — a thread do usbkb
crashava "ao lado", sem travar a principal. O achado desta sessão é negativo mas honesto: o
`bad=0x540838` **não era** a causa do gate `0x245718`; era um sintoma paralelo, mais alto (mais
fácil de ver no log) mas causalmente desconectado. `0x245718` continua bloqueado por algo não
identificado nesta sessão — registrado aqui para o próximo handoff em vez de forçar uma
conclusão que a evidência não sustenta.

## Régua de render (M4)

`gifPk1=0 gifPk2=0 gifPk3=0 gifPkTotal=0 gsPrims=0 gsPixels=0 dma=2 vif=3 gif=0 gsw=0` —
inalterada nas 3 corridas do probe. **M4 não alcançado** (precisa `gifPackets>0` E
`gsPrims>0`) — `21_probe_repeat.bat 3 probe m4_confirm` não se aplica, nada a reportar
imediatamente.

## Suíte e commits

`ps2x_tests.exe` (`PS2Recomp/out/build`, rebuild completo após o fix, +1 teste novo = 271
total): 4 corridas — `269/270`, `270/270`, `270/270`, depois com o teste novo `270/271`,
`271/271`, `271/271`. A única falha observada (1 corrida) foi a mesma flaky histórica já
documentada (`sceGsSyncV waits on VBlank and reports interlaced field parity`, timing —
`RESULT_GSYNCV_METRICS_V1.md`); a suíte de `VU0 macro mappings` não falhou em nenhuma corrida
desta sessão. Sempre ≥266/269 — dentro da regra do `STATUS.md`, sem regressão nova.

Nenhum env-gate novo, nenhum `SignalSema` injetado, scheduler intocado (Fase 2 congelada),
nenhum chute de bytes (todo endereço veio de trace ao vivo + leitura de disasm/CSV, nunca
inventado).

Commits locais (sem push):
- Submódulo `PS2Recomp` (branch `mc3`, commit `4d58deb`):
  `ps2xRecomp/src/lib/code_generator.cpp` (fix do heurístico de `numCases`),
  `ps2xTest/src/code_generator_tests.cpp` (teste de regressão novo).
- Repo raiz: `tools/Generate-PartialRegister.js` (filtro de colisão alias-vs-função-real),
  ponteiro do submódulo `PS2Recomp`, `docs/BOOT_PROBE_STATUS.md` (atualizado automaticamente
  pelo probe tooling ao medir — não editado à mão), este RESULT doc.
- Não versionado (é `work/`, gitignorado): `work/exports/*` regenerado localmente,
  `work/generated/ghidra/*` regenerado (15812 arquivos), `work/link/partial/*` relinkado,
  `work/boot_probe/repeat_missing_540838_fix_*.md` (relatórios do probe).

## Aceite

**Parcial**: `bad=0x540838` não ocorre mais (confirmado 3/3 determinístico) — **alcançado**.
Zero missing functions no manifest — **alcançado** (e já estava assim antes; o bug nunca foi
de link). Gate sai de `0x245718` — **não alcançado**; investigação mostra que os dois sintomas
eram independentes (thread usbkb paralela vs. thread principal), então fechar a classe
`0x540838` não tinha por que mover esse gate especificamente — achado registrado para a próxima
sessão em vez de forçado. Achado extra fechado no processo: 450 colisões alias-vs-função-real
pré-existentes no pipeline de registro, agora filtradas de forma geral.
