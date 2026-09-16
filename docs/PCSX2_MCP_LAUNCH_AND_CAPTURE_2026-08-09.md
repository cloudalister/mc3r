# PCSX2 MCP - lancamento e captura MC3

Estado validado em 2026-08-09.

## Caminhos locais

- PCSX2 MCP: `<old-project-root>\external\PCSX2-MCP\PCSX2-MCP-v1.0.0-win64\PCSX2-MCP-v1.0.0-win64\pcsx2-qt.exe`
- ISO: `<old-project-root>\Midnight Club 3 - DUB Edition Remix.iso`
- DebugServer: `127.0.0.1:21512`

## Lancamento confiavel no Windows

`Start-Process -ArgumentList` quebrou as aspas do caminho da ISO. O metodo validado usa `ProcessStartInfo.Arguments` e `[char]34`:

```powershell
$iso = '<old-project-root>\Midnight Club 3 - DUB Edition Remix.iso'
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = '<old-project-root>\external\PCSX2-MCP\PCSX2-MCP-v1.0.0-win64\PCSX2-MCP-v1.0.0-win64\pcsx2-qt.exe'
$psi.Arguments = '-- ' + [char]34 + $iso + [char]34
$psi.UseShellExecute = $true
[void][System.Diagnostics.Process]::Start($psi)
```

Confirmar que iniciou o jogo, nao apenas o menu:

```powershell
$p = Get-Process pcsx2-qt | Select-Object -First 1
(Get-CimInstance Win32_Process -Filter ('ProcessId=' + $p.Id)).CommandLine
$p | Select-Object Id, MainWindowTitle
```

Aceite: titulo `Midnight Club 3 - DUB Edition Remix` e linha de comando contendo `-- "...iso"`.

## Conexao e captura

1. Conectar no DebugServer, porta `21512`, modo `debug`.
2. Armar watchpoint de escrita em `0x00700DC0-0x00700DC7`, tipo `write`, acao `break`.
3. Continuar a execucao.
4. Quando parar, capturar memoria em `0x00700DC0`, registradores, backtrace e disassembly do PC/RA.
5. Para o primeiro uso, trocar o watchpoint para `read` no mesmo intervalo.

## Evidencia atual

- DebugServer conectou com sucesso.
- Watchpoint de escrita foi armado em `0x00700DC0-0x00700DC7`.
- Objetivo: capturar o ponteiro real devolvido pelo opcode `0x2B` para `host0:` e o objeto apontado, sem escrever memoria nem forcar sucesso.

## Pegadinhas

- `16_pcsx2_mcp_status.bat` ainda aponta para um drive `D:` ausente; nao confiar nele ate corrigir a configuracao.
- Sem `--` antes da ISO, o PCSX2 abre apenas o menu ou interpreta o caminho como parametro.
- Nao escrever `1` em `0x700DC0`: o jogo espera um ponteiro real.
- Todo comando de terminal do projeto deve passar por `rtk` ou `rtk proxy`.
