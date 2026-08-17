# Port de símbolos alpha 102404 → retail — 2026-08-17

Ferramenta: `tools/port_symbols.py` (Python puro, sem Ghidra). Etapa 1: hash MD5 de bytes
mascarados (imediatos de `lui`/load/store/addiu/ori e alvos de `j`/`jal` zerados), match só
quando único dos dois lados. Etapa 2: propagação por callgraph — em cada par casado com o mesmo
número de `jal`s, o k-ésimo alvo do alpha vota no k-ésimo alvo do retail; aceita sem conflito e
com tamanho compatível; itera até estabilizar.

## Números

- alpha (MC.MAP, só `.text`): 16.154 funções nomeadas
- retail (export Ghidra): 15.812 funções
- **casadas: 8.815 (55,7% do retail)** — 6.695 por hash exato, 2.120 por callgraph
- saída: `work\exports\retail_symbol_port.csv` (fica fora do repo público, junto com o MC.MAP)

## Os endereços que seguravam o projeto, agora com nome

| Retail | Nome | Como |
|---|---|---|
| `0x5422C8` (gate de 01/08) | `sceCdRead` | hash |
| `0x541968` | `sceCdSync` | hash |
| `0x5424A8` | `sceCdSeek` | hash |
| `0x5420C0` ("precisa retornar 2") | entre `sceCdInit` e `sceCdRead` → família sceCd; semântica bate com `sceCdDiskReady` (retorna `SCECdComplete=2` com disco pronto) | vizinhança |
| `0x549680` | `sceSifCheckStatRpc` | hash |
| `0x54A080` (onde o boot para hoje, 5/10) | `sceFsInit` | hash |
| `0x398B18` (wait do sid=5) | `ipcWaitSema(ipcSemaTag *)` | callgraph, 13 votos |
| `0x398A60` (cria o sid=5) | `ipcCreateSemaEx(bool, int)` | hash |
| **`0x398450`** | **`coreFileSignalSema(int)` — o produtor legítimo do sid=5** | vizinhança/hash |
| `0x3984C0/0x3986D8/...` (o "ABI físico") | família `coreRaw*` (`coreRawOpenFile` em ~0x398830) | vizinhança |
| `0x4F9760` | `zipFile::zipOpen(const char*, bool)` | hash |
| `0x4FB0D8` | `zipFile::Open(const char*)` | hash |
| `0x4FAED8` | `zipFile::Locate(const char*)` | callgraph |
| `0x4FA7A8` ("escritor da flag do provider") | `zipCompressNameHeap(...)` | hash |
| `0x245568` (loop que espera o retorno 2) | região `psxCdCache::*` (`psxCdCache::RawRead` em `0x245790`, `psxCdCache::Init` no alpha) | vizinhança |
| `0x2B4438` (gate antigo) | `rmcShaderTemplate::Load(int, const char*)` | hash |
| `0x5A8898` (spin de 29/07) | região `memHeap::Begin` | vizinhança |
| `0x4BD488` | região `mcHeap::Begin` | vizinhança |
| `0x447928` | região `sndAudioManager::Start` | vizinhança |

## O que isso muda

1. **O bloqueio do boot é a pilha SCE de CDVD/FS sobre SIF RPC** — `sceCdInit`,
   `sceCdDiskReady`, `sceCdRead`, `sceCdSync`, `sceFsInit`. Isso é **protocolo público e
   documentado** (ps2sdk libcdvd/cdvdfsv; PCSX2 implementa o lado IOP em `CDVD/`). Não é
   protocolo proprietário da Rockstar. A Fase 1 do roadmap muda de "descobrir um protocolo"
   para "implementar semântica conhecida": os requests que o runtime descarta são os comandos
   cdvdfsv/fileio padrão (o modo `595` do probe já era o server id S-cmd `0x80000595` visto em
   trace). Referência primária para cada struct de resposta: fonte do PCSX2 + ps2sdk.
2. **Handoff sid=5 respondido**: a cadeia é `ipcCreateSemaEx` (cria, init=0) →
   `ipcWaitSema` (bloqueia) → `coreFileSignalSema` (retail `0x398450`) deveria sinalizar quando
   a operação `coreRaw*` completa. O runtime cumpre a operação de arquivo de forma síncrona mas
   nunca aciona o caminho de completion que chama `coreFileSignalSema` — coerente com a
   causa-raiz de 13/08 (respostas IOP descartadas). Corrigindo a camada cdvd/fs RPC, a
   completion volta a existir e o sema é sinalizado pelo produtor legítimo, sem injeção.
3. **"Provider" = `zipFile`**: as flags `0x619F4x` são estado interno do `zipFile`/
   `datAssetManager`, inicializado depois que o CD funciona. Não atacar direto — destravar o
   CDVD primeiro.
4. As funções `psxCdCache`, `memHeap::Begin`, `mcHeap::Begin`, `sndAudioManager::Start` nos
   gates antigos confirmam: tudo que travou nos últimos 2 meses era consequência da mesma
   causa (CD/FS não funcional), vista de ângulos diferentes.

## Limites e próximos incrementos do matcher

- 55,7% cobre o núcleo do boot; o restante são inlines pequenos, overloads ambíguos e código
  que mudou entre out/2004 e o retail.
- Melhorias possíveis: desempate por vizinhança de endereço; match por sequência (funções
  adjacentes entre dois pares casados); usar `MC.SYM` para dados/globais (as flags `0x619F4x`
  ganham nome também).
- O relatório de vizinhança dos gates está reproduzível com o snippet no fim de
  `tools/port_symbols.py` (ou rodando o matcher de novo).
