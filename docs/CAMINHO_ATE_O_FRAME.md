# O caminho até o primeiro frame — e por que a tela ainda é rosa/preta

Este doc responde a pergunta mais importante do projeto: **"por que eu ainda não vejo o jogo?"**
— e define a régua pública de progresso. Toda sessão futura se localiza nesta escada.

## Por que você vê o que vê

- **Tela rosa**: é a cor de limpeza/lixo do buffer da janela do runner. Significa "a janela
  existe, mas o GS (chip gráfico emulado) nunca escreveu um pixel". Não é bug novo — é o
  estado esperado enquanto `gif=0 gsw=0`.
- **Tela preta**: mesma coisa, com o buffer zerado em vez de lixo.
- **Crash/trava**: o boot morre num gate de inicialização antes de chegar perto de desenhar.
  Desde a Fase 2, ele para **sempre no mesmo lugar** (hoje: `0x5a8908`, esperando o sistema
  de arquivos/assets funcionar).

A verdade estrutural: **um jogo de PS2 só desenha depois de uma cadeia longa funcionar
inteira**, e o recomp precisa reconstruir cada elo dela no PC. A tela rosa não é "quase lá
com um defeito" — é "os elos 1-2 de 7 estão sendo construídos agora".

## A escada (M0→M6)

| # | Marco | O que destrava | Estado |
|---|---|---|---|
| M0 | Kernel EE: threads, semáforos, syscalls | o binário roda | ✅ + determinístico (Fase 2, 17/08) |
| M1 | Serviços IOP respondem (SIF RPC) | CD, arquivo, pad, som existem | 🔨 **em curso** — cdvd init ✅, usbkb ✅, fileio/completion ← estamos aqui |
| M2 | Assets carregam (`zipFile` abre os `.DAT`, provider inicializa) | gate `0x5a8908` atravessado; jogo tem dados | ⬜ próximo |
| M3 | Main loop roda (`mcGame::Execute`), máquina de estados do jogo gira | jogo "vivo" sem imagem | ⬜ |
| M4 | Tráfego de render: DMA→VIF1→VU1→GIF ativo | **`gif>0` pela primeira vez na história** | ⬜ exige auditar VU1/VIF1 do runtime |
| M5 | GS rasteriza: framebuffer com conteúdo | **primeira imagem real (dump PNG)** | ⬜ runtime tem `ps2_gs_rasterizer`, nunca exercitado |
| M6 | Present: framebuffer na janela | a tela deixa de ser rosa | ⬜ |

Regra de leitura: **cada marco só vale com o anterior determinístico.** O erro dos meses
antigos foi tentar enxergar M5 pulando M1-M2 com hacks — o PC "andava" e nada era real.

## Por que a escada agora anda mais rápido que antes

1. Símbolos (17/08): cada gate novo nasce com nome — diagnóstico em minutos, não semanas.
2. Determinismo (Fase 2): uma corrida = uma prova — experimento custa 1 boot, não 10.
3. Protocolo público: M1 é implementar manual conhecido (SCE SDK), não decifrar segredo.

## Aviso de expectativa (honesto)

M1-M2 são semanas de trabalho metódico. M4-M5 são a segunda montanha do projeto (VU1 é um
coprocessador vetorial com microcódigo próprio) — têm peças prontas no runtime, nunca
exercitadas de verdade. O primeiro pixel real provavelmente será um **dump PNG do framebuffer
em M5**, não a janela — e isso é vitória igual: é a prova de que a cadeia inteira funciona.
