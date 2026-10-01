# ASSET-PIPELINE.md — Como arte e som entram no jogo

> Complementa o [`ASSETS.md`](ASSETS.md) (o registro). Aqui ficam o **estilo**, as **fontes gratuitas**, o **template de prompt** e o **pós-processamento**.

---

## 1. Guia de estilo

| Regra | Valor |
|---|---|
| Resolução interna | 384×216 ([ADR-003](DECISIONS.md#adr-003)) |
| Tile | 16×16 |
| Personagem | frames 32×32 (MU-7 ocupa ~20×26 dentro do frame, pés na linha de base) |
| Filtro | **nearest** sempre; nada de anti-aliasing |
| Contorno | escuro, 1 px, em sprites de gameplay |
| Paleta | 12–16 cores por setor ([GDD-2.9 paleta](design/GDD.md#gdd-2-9-paleta)) |
| Luz | a estação é escura por padrão; sprites devem funcionar sob `CanvasModulate` escuro + `PointLight2D` |
| Tom | "uma estação bonita que ninguém está usando"; sem sangue |

### Paleta de referência (hex) por setor

| Setor | Base | Secundária | Destaque | Perigo |
|---|---|---|---|---|
| Núcleo Central | `#1B2B34` | `#2F4F5A` | `#5FD4C8` (ciano) | `#E0B43C` |
| Estufa | `#1E2A1C` | `#3F6B3A` (musgo) | `#E58FB4` (rosa) | `#B7D35A` (esporo) |
| UI / HUD | `#0B0F14` | `#D7E3E8` | `#5FD4C8` | `#D9534F` |

## 2. Fontes gratuitas (verifique a licença de CADA arquivo)

| Site | Bom para | Licença típica | Link |
|---|---|---|---|
| **Kenney** | tiles, UI, SFX, fontes | **CC0** (sem crédito obrigatório) | https://kenney.nl/assets |
| **itch.io** (filtrar "free" + "CC0") | tilesets sci-fi, sprites | CC0 / CC-BY / licença própria | https://itch.io/game-assets/free |
| **OpenGameArt** | tiles, música, SFX | CC0 / CC-BY / GPL (evitar GPL) | https://opengameart.org |
| **Freesound** | SFX, ambiências | CC0 / CC-BY (filtrar CC0) | https://freesound.org |
| **Pixabay** | música, SFX | Licença Pixabay (uso livre) | https://pixabay.com/music/ |
| **incompetech** (Kevin MacLeod) | música | CC-BY 4.0 (crédito obrigatório) | https://incompetech.com |
| **Daniel Linssen** | fontes pixel m5x7/m6x11 | livre com crédito | https://managore.itch.io |

**Aceito:** CC0, CC-BY (com crédito no README), Pixabay, licenças que permitem uso em jogo não comercial. **Recusado:** sem licença clara, "personal use only" ambíguo, GPL para arte, qualquer coisa "ripada" de jogo comercial.

## 3. Geração com IA — Gemini / Nano Banana Pro

### Template de prompt
```
Pixel art <o que é> for a 2D side-view sci-fi platformer set in an abandoned space station.
<descrição visual: forma, materiais, cores, humor>.
Style: 16-bit pixel art, crisp hard pixels, no anti-aliasing, limited palette of <N> colors (<cores>).
Layout: <grid de WxH pixel frames, colunas x linhas, o que cada linha/frame contém>.
Every frame the same size, subject centered, same baseline.
Solid flat magenta background (#FF00FF), no text, no labels, no grid lines, no watermark.
```

### Dicas que funcionam
- **Fundo magenta** (`#FF00FF`) é obrigatório: o agente remove automaticamente. IA de imagem raramente gera transparência de verdade.
- A IA **não respeita pixels exatos**: tudo bem. Peça a proporção certa; o agente redimensiona por nearest para o contrato.
- Gere **4 variações** e escolha a mais legível em tamanho pequeno.
- Para consistência, anexe a imagem já aprovada do MU-7 como referência nos prompts seguintes ("same art style as the attached image").
- Se vier com "grade" ou texto, peça de novo: "remove all text and grid lines".

## 4. Pós-processamento (feito pelo agente)

### 4.0 Folha com espaçamento irregular (o caso comum da IA)

A IA quase nunca devolve uma grade exata. Use o fatiador automático, que acha as linhas e os quadros pelo próprio conteúdo:

```bash
"$GODOT" --headless --path . -s res://tools/autoslice_sheet.gd -- \
  --in=~/Downloads/orbita-assets/SPR-MU7/raw.png \
  --out=assets/sprites/mu7/mu7_sheet.png \
  --frame-width=32 --frame-height=32 --columns=6
```

Ele imprime quantas linhas e quantos quadros achou — **confira contra o contrato do asset antes de aceitar**. O fundo magenta sai por família de cor (não por igualdade exata, senão fica franja rosa), a redução usa média (vizinho mais próximo vira chiado) e cada quadro é centralizado com os pés na linha de base, tomando a **linha 1 (idle) como referência de altura**.

**Regra de prompt aprendida:** peça explicitamente *"only the character, NO wall, NO floor, NO background object"* — quando a animação sugere cenário (escalar, apoiar), a IA desenha o cenário dentro do quadro e ele entra no jogo em duplicidade.


`tools/process_image.gd` (Godot headless, sem dependências):

```bash
"$GODOT" --headless --path . -s res://tools/process_image.gd -- \
  --in=~/Downloads/orbita-assets/SPR-MU7/raw.png \
  --out=res://assets/sprites/mu7/mu7_sheet.png \
  --key=FF00FF --frame=32x32 --grid=6x8 --palette=16
```

1. Remove o fundo magenta (tolerância para bordas).
2. Detecta a grade e redimensiona cada frame por nearest para o contrato.
3. Reduz a paleta (quantização simples) e alinha pés à linha de base.
4. Salva no caminho final; o agente abre com `godot-qa` para conferir.

Áudio: sem ffmpeg na máquina — prefira baixar **.ogg** ou **.wav**. MP3 também funciona no Godot 4. Loops: o agente marca `loop=true` no `.import` do arquivo.

## 5. Importação no Godot

- Texturas: filtro nearest vem do projeto (ADR-003); sem mipmaps.
- Sprite sheets: `SpriteFrames` (`.tres`) escrito pelo agente com `AtlasTexture` por frame.
- Tilesets: `TileSet` (`.tres`) escrito pelo agente ([F21](features/F21-construtor-fases-ascii.md)).
- Após colocar arquivos: `"$GODOT" --headless --path . --import`.
- Registre licença e autor no [`ASSETS.md`](ASSETS.md#creditos) **e** no `README.md`.
