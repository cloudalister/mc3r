# O caminho até o primeiro frame — e por que a tela ainda é rosa/preta

Este doc responde a pergunta mais importante do projeto: **"por que eu ainda não vejo o jogo?"**
— e define a régua pública de progresso. Toda sessão futura se localiza nesta escada.

## Por que você vê o que vê

**Revisão 2026-09-03 — esta seção envelheceu e foi reescrita.** O jogo desenha. O que segue
descreve o estado medido hoje; a redação anterior (tela rosa = "GS nunca escreveu um pixel")
valia até agosto e não vale mais.

- **A imagem existe e é legível.** `work/captures/frame_autostart_20260903.png` mostra a tela
  legal do MC3 — logo, kanji, texto GameSpy, aviso Dolby — com `gsPrims≈1M` e `gsPixels≈1G`.
- **A janela do runner, porém, sai preta.** O despejo em PNG usa as mesmas duas chamadas da
  apresentação e produz imagem correta, enquanto a janela não. É defeito próprio de M6, e o
  único motivo de hoje só enxergarmos o jogo por PNG.
- **Não há mais trava de boot.** O gate `0x5a8908` foi atravessado em 18/08; a trava pós-menu
  que sobrou depois disso foi capturada e corrigida em 03/09 (inversão de ordem de travas,
  `docs/RESULT_SEMA_PROBE_BLIND_2026-08-31.md` §30-31).
- **O que não anda é a decisão de trocar de tela.** O jogo entra no frontend uma vez e sua
  máquina de estados congela ali, com o render girando e o pad sendo lido.

A verdade estrutural continua valendo, só que do outro lado: a cadeia longa **funciona**
ponta a ponta até desenhar. O elo que falta não é gráfico, é de estado.

## A escada (M0→M6)

| # | Marco | O que destrava | Estado |
|---|---|---|---|
| M0 | Kernel EE: threads, semáforos, syscalls | o binário roda | ✅ determinístico (Fase 2, 17/08) + trava de travas corrigida (03/09) |
| M1 | Serviços IOP respondem (SIF RPC) | CD, arquivo, pad, som existem | ✅ CD lê a ISO byte-a-byte; PADMAN publica e o convidado lê |
| M2 | Assets carregam (`zipFile` abre os `.DAT`, provider inicializa) | gate `0x5a8908` atravessado; jogo tem dados | ✅ 18/08 (o `sprintf` mudo era a causa) |
| M3 | Main loop roda (`mcGame::Execute`), máquina de estados do jogo gira | jogo "vivo" trocando de tela | 🔨 **estamos aqui** — entra no frontend uma vez e congela em `3/1/3/2/3` |
| M4 | Tráfego de render: GIF recebendo pacotes | **primeiro tráfego real de desenho** | ✅ `gifPk1≈606k` |
| M5 | GS rasteriza: framebuffer com conteúdo | **primeira imagem real** | ✅ `gsPrims≈1M`, `gsPixels≈1G`, tela legal legível em PNG |
| M6 | Present: framebuffer na janela | ver o jogo sem depender de PNG | ⚠️ o despejo sai certo, a **janela sai preta** — defeito aberto |

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

*Escrito em agosto:* "M1-M2 são semanas de trabalho metódico. M4-M5 são a segunda montanha do
projeto. O primeiro pixel real provavelmente será um **dump PNG do framebuffer em M5**, não a
janela — e isso é vitória igual."

*Conferido em 03/09:* aconteceu exatamente assim. M1, M2, M4 e M5 caíram; o primeiro pixel
real veio mesmo por PNG, e a janela continua preta. A montanha restante não é gráfica: é a
máquina de estados de M3, mais o defeito de apresentação de M6.

O aviso novo, no mesmo espírito: **desenhar não é jogar.** Ter imagem prova que a cadeia
inteira funciona uma vez; um jogo rodando exige que ela funcione sessenta vezes por segundo
enquanto o estado muda. É outro tipo de trabalho, e ele começa agora.
