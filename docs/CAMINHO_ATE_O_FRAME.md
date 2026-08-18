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
| M4 | Tráfego de render: GIF recebendo pacotes | **primeiro tráfego real de desenho** | ⬜ cadeia JÁ LIGADA ponta-a-ponta no runtime (auditoria 18/08); menu 2D usa PATH3 direto, SEM VU1 |
| M5 | GS rasteriza: framebuffer com conteúdo | **primeira imagem real** | ⬜ rasterizador completo p/ 2D (falta Z-buffer, só relevante p/ 3D) |
| M6 | Present: framebuffer na janela | a tela deixa de ser rosa | ⬜ mecanismo já existe (janela raylib; o rosa É o fallback magenta de "sem frame") |

> Revisão 18/08 (auditoria `AUDIT_M4M5_RENDER.md`): a "segunda montanha" é menor que o
> estimado — nenhum elo está ausente; os gaps são pontuais (Z-buffer, 4 instruções EFU do VU1
> que só shaders 3D de carro usam, flags MAC). O caminho do menu (Blit2D→GIFtag→PATH3→GS)
> existe inteiro dos dois lados. Atenção: os contadores antigos `gif`/`gsw` medem as fatias
> erradas do tráfego — régua nova em implantação (passo 4).

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
