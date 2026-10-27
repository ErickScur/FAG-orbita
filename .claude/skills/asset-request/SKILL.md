---
name: asset-request
description: Cria ou atualiza a ficha de um asset do ÓRBITA no docs/ASSETS.md — contrato técnico, opção gratuita (link + licença verificada) e/ou prompt de IA (gerado pelo próprio agente via skill gen-image; Gemini como fallback) — e, quando o arquivo bruto existir, mede, pós-processa e integra no jogo. Use quando uma feature precisar de arte/som/fonte, quando o usuário pedir "prompts dos assets", "onde baixo X", ou disser que baixou/gerou um asset (imagem, zip, mp3, wav).
---

# asset-request — Do pedido ao asset integrado

Leia antes: `docs/ASSETS.md` (registro e contratos), `docs/ASSET-PIPELINE.md` (estilo, paleta,
fontes gratuitas, template de prompt, §4 fatiador).

## A. Criar a ficha
1. **ID**: `SPR-`, `TIL-`, `BG-`, `UI-`, `FX-`, `MUS-`, `SFX-` + nome curto. Verifique se já existe.
2. **Contrato**: caminho final `assets/...`, dimensões exatas (tile 16, sprite 32, tela 384×216),
   linhas × quadros, **proporção total esperada da folha** (ex.: 6 quadros 32×32 numa linha =
   6:1), loop (áudio).
3. **Opção gratuita**: Kenney, itch.io (filtro CC0), OpenGameArt, Freesound (CC0), Pixabay. Link
   direto e licença **conferida na página**. Nada sem licença clara (regra dura 10).
4. **Opção IA**: prompt em inglês pelo template do ASSET-PIPELINE §3 — fundo magenta `#FF00FF`,
   grade e contagem de quadros explícitas, **formas grossas** (detalhe fino vira mancha ao reduzir
   para 32 px — a 1ª aranha teve metade dos pixels semitransparente), paleta do setor, "no text,
   no grid lines". Tileset: base de **brilho médio** (o motor escurece a cena).
5. Linha no índice do ASSETS.md (prioridade A/B/C, feature) + ficha. Status `pendente` ou
   `placeholder`. Garanta o placeholder: `"$GODOT" --headless --path . -s res://tools/make_placeholders.gd`.

## B. Obter o arquivo
- **Arte por IA: gere você mesmo** com a skill `gen-image` (`tools/gen_image.sh`, geração de
  imagem do Codex CLI). É o caminho padrão desde 2026-10-27; o humano só aprova no jogo.
- **Grátis (Kenney, itch.io…)** ou **música/som**: entregue ao humano uma lista curta por
  prioridade: ID → "baixe daqui (licença X)" e onde salvar.
- Fallback, se o Codex não estiver disponível: "cole este prompt no Gemini" e onde salvar.

## C. Integrar o que chegou

### C.1 Medir antes de fatiar (a lição mais cara da integração)
Geração por IA **quase nunca** bate o contrato: a porta veio com 5 quadros em vez de 7; a planta
mais larga que o quadro; a aranha em proporção 2,26:1 num quadro 2:1 (cortada nas bordas **sem
aviso**); o tileset da Estufa em 10×5 em vez de 8×4; os objetos em 2:1 em vez de 6:1.
1. **Read na imagem** e conte linhas e quadros com os próprios olhos.
2. Meça largura × altura e compare a **proporção** com a do contrato. Divergiu → o layout é outro.
3. Não bateu e não dá para remontar sem inventar quadro? **Recuse** e devolva ao humano um prompt
   corrigido. Forçar o encaixe custa mais caro depois.
4. Nome de arquivo com espaço (`tileset estufa.png`) vai entre aspas no shell. Zip se descompacta
   no **scratchpad**, nunca no projeto; procure a licença dentro dele antes de qualquer coisa.

### C.2 Pós-processar
- Folha irregular: `tools/autoslice_sheet.gd` (ASSET-PIPELINE §4.0), com `--fit=contain` quando a
  proporção do desenho difere da do quadro. Confira a contagem que ele imprime contra o contrato.
- Chave de magenta por **"magentice"** (`(r+b)/2 − g`, ~245 no fundo e ~0 numa silhueta) mais o
  *unmix* `F = (C − K·(1−a))/a`. Distância euclidiana deixa franja rosa (F49). Meça: pixels
  semitransparentes e pixels de franja, antes e depois.
- Colar faixa sobre tile: `blend_rect`, nunca `blit_rect` (copia o alfa e abre buraco; foi o topo
  de toda superfície de piso da Estufa, e nenhuma screenshot mostrou, F47).
- Parallax largo: confira onde o assunto cai **depois** do `scroll_scale` na largura da fase; role
  a tira se preciso (o planeta-alvo da F49 nunca apareceria).

### C.3 Ligar no jogo
1. `SpriteFrames`/`TileSet`/cena apontam ao **caminho final** (troca de uma linha, ADR-005).
2. Tileset novo: **coordenadas cruas de atlas** (`LevelBuilder.ONE_WAY_TILE`,
   `MagneticWall.TILE_COLUMN/ROW`, `SecretWall.tile_column/row`) são contrato com a arte; rode
   `tests/test_level_tileset.gd`, que confere papel por papel (F47).
3. Arte de personagem animado: confira no jogo que a animação **toca** (guarda `is_playing()`,
   ver `godot-pitfalls` > Animação).
4. `tools/gates.sh` e `godot-qa` com uma captura do asset no jogo.

### C.4 Áudio
- Normalize por **RMS**, não por pico: um pacote com pico ≈ −1 dBFS tinha 21 dB de diferença de
  volume percebido entre arquivos (F52).
- Variações `nome_1..N` são resolvidas **por grupo**: o conjunto inteiro no diretório definitivo
  primeiro, placeholder só depois. Arquivo direto esquecido no placeholder sombreava as variações
  novas — som velho no jogo, sem erro (F52).
- Música de fase: confira a emenda do loop pelas amostras do começo e do fim (faixa de IA vem com
  fade nas pontas). MP3 importa direto no Godot 4; não há ffmpeg na máquina.
- Arquivo com 0 bytes = download falhou; não use, peça de novo.

### C.5 Registrar
ASSETS.md: status `integrado`, autor/licença nos créditos; espelhe no `README.md`. Commit:
`art(F<id>): <asset>` ou `audio(F<id>): <asset>`.

## Testes de asset que existem (rode depois de trocar arte)
`tests/test_level_tileset.gd`, `tests/test_asset_resolver.gd`, `tests/test_light_crowding.gd`,
`tests/test_asset_fringe.gd` (reprova franja magenta **semitransparente** em `assets/sprites`,
`tiles` e `ui`: a linha `dash` do MU-7 carregou 155 px de rastro roxo da demo até a F31 porque a
animação nunca tocava; rosa desenhado de propósito, como as flores da Estufa, é opaco e passa).
Teste de asset nunca usa como cobaia um asset real "ainda sem arte final": ele quebra na entrega
da arte (aconteceu três vezes, F49). O resolvedor hoje usa a cobaia sintética
`assets/placeholder/sprites/_sem_arte/fixture.png` — mantenha assim.
