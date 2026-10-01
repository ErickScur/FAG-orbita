---
id: F05
title: Pipeline de assets & placeholders
status: done
scope: demo
block: 0
priority: P0
rubric: ["Efeitos visuais/sonoros"]
depends_on: ["F01", "F06"]
unblocks: ["F03", "F04", "F07", "F12", "F15", "F18", "F21"]
estimate: 2.5h
last_updated: 2026-09-19
---

# F05 — Pipeline de assets & placeholders

## 1. Contexto e objetivo

Com 3 dias de prazo, nenhuma feature pode esperar arte ou som ([ADR-005](../DECISIONS.md#adr-005)). Esta feature cria a esteira completa de assets, 100% via Godot headless (não há Python/PIL nem ffmpeg na máquina):

1. **`tools/make_placeholders.gd`** gera todos os PNGs e WAVs placeholder com o **contrato final** (dimensões, grade de frames) do [`ASSETS.md`](../ASSETS.md), a partir de um manifesto JSON.
2. **`tools/process_image.gd`** pós-processa a arte bruta que o humano baixar ou gerar no Nano Banana Pro: remove o fundo magenta `#FF00FF`, recorta, redimensiona com *nearest*, reduz a paleta e fatia o sheet.
3. **`AssetResolver`** faz o código apontar sempre para o caminho final e cair no placeholder se o definitivo ainda não existe — trocar arte vira "copiar arquivo".
4. **`assets/ui/theme.tres`** + fonte pixel **UI-FONT**: aparência única de toda a UI.
5. Texturas **FX-LIGHT** (definitivas, geradas) e a partícula `spark_burst` — base dos efeitos visuais.

Serve ao pilar visual "a luz é informação" ([GDD-2.9](../design/GDD.md#gdd-2-9-visual)) e mantém o jogo apresentável mesmo só com placeholders.

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.9 Estilo visual](../design/GDD.md#gdd-2-9-visual) · [GDD-2.9 Paleta por setor](../design/GDD.md#gdd-2-9-paleta) · [GDD-2.9 Efeitos sonoros](../design/GDD.md#gdd-2-9-sfx) · [GDD-2.8 HUD](../design/GDD.md#gdd-2-8-hud)
- **Parâmetros:** `Balance.TILE_SIZE` (tiles 16 px) ([GDD-P](../design/GDD.md#gdd-p)) · `Balance.VISION_RADIUS_ON` (referência de escala da luz radial)
- **Ajustes:** [AJ-001](../design/GDD.md#gdd-ajustes)
- **ADRs:** [ADR-003](../DECISIONS.md#adr-003) · [ADR-005](../DECISIONS.md#adr-005) · [ADR-007](../DECISIONS.md#adr-007)
- **Assets:** todas as fichas do [`ASSETS.md`](../ASSETS.md) (contratos)

## 3. Critério de avaliação atendido

**Efeitos visuais/sonoros** ([ENTREGAS §3.2](../ENTREGAS.md#rubrica)): a F05 entrega a infraestrutura (texturas de luz, partícula de faíscas, SFX placeholder audíveis) que F18/F20/F29 usam em cena. Durante a apresentação o avaliador vê faíscas ao coletar itens e o halo de luz da lanterna — ambos nascem aqui. Indiretamente viabiliza todos os itens visuais da Demo.

## 4. Escopo

### Inclui
- `tools/placeholders.json` (manifesto) + `tools/make_placeholders.gd` (gera PNG e WAV).
- `tools/process_image.gd` (CLI de pós-processamento) + `scripts/core/image_ops.gd` (lógica pura testável).
- `scripts/core/asset_resolver.gd` (`class_name AssetResolver`).
- `assets/ui/theme.tres` com estilos de `Button`, `Label`, `Panel`, `PanelContainer`, `ProgressBar`, `HSlider`, `CheckBox`, `OptionButton`.
- Integração da fonte **UI-FONT** (depois da 🧑 ação humana) em `assets/fonts/ui_font.ttf` e no `theme.tres`; `project.godot` → `gui/theme/custom="res://assets/ui/theme.tres"`.
- `assets/fx/light_radial.png` (256×256) e `assets/fx/light_cone.png` (256×128) gerados — definitivos.
- `scenes/fx/spark_burst.tscn` (+ `.gd`): `CPUParticles2D` one-shot reutilizável.

### Não inclui
- Arte definitiva de qualquer sprite/tileset/fundo (humano, via `ASSETS.md`).
- Layout final do atlas de tiles (dono: [F21](F21-construtor-fases-ascii.md); aqui só um layout proposto no manifesto).
- Conversão de áudio (MP3 → OGG): arquivos baixados já devem ser `.ogg`/`.wav`; Godot importa `.mp3` também, então basta mudar a extensão no `AudioManager` se necessário.
- Shaders de pós-processamento (CRT, glitch) — Final.
- Fonte monoespaçada separada (`ui_font_mono.ttf`) — a Demo usa a mesma fonte; Final.

## 5. Critérios de aceite

- [x] `"$GODOT" --headless --path . -s res://tools/make_placeholders.gd` cria **todos** os arquivos do manifesto em `assets/placeholder/…` com as dimensões do contrato e sai com código 0; rodar de novo sobrescreve sem erro (idempotente) — saída `GENERATED 20 files`.
- [x] Após `--import`, `AssetResolver.texture("res://assets/sprites/mu7/mu7_sheet.png")` retorna a textura placeholder **192×320** (contrato de 10 linhas do `ASSETS.md`, ver [ADR-F05-004](#adr-f05-004)); ao existir o definitivo, retorna o definitivo sem mudar código (`test_asset_resolver.gd`).
- [x] `AssetResolver.audio("res://assets/audio/sfx/ui_confirm.ogg")` retorna o WAV placeholder audível (`test_audio_falls_back_to_placeholder_wav`).
- [x] `process_image.gd` com `--in=<png com fundo magenta>` gera PNG com fundo transparente, tamanho exato `grid × frame`, sem pixels intermediários (nearest) e com ≤ `--colors` cores opacas — bruto de 12 762 cores → `192x320 cores=16`, 0 pixels magenta restantes.
- [x] `--slice` grava um PNG por frame (`<out>_<linha>_<coluna>.png`) além do sheet — 60 frames + o sheet.
- [x] Toda UI sem override usa o `theme.tres` (screenshot `f05_theme`: `Button` com foco ciano, `Button` desabilitado, `HSlider`, `CheckBox`, `OptionButton`, `ProgressBar`).
- [~] Com a fonte instalada, a string "ÓRBITA ÁÃÇÉÊÍÓÔÕÚ áãçéêíóôõú" aparece nítida (sem antialias) e sem glifo faltando — **pendente da 🧑 ação humana**; com a fonte padrão do Godot todos os acentos aparecem (screenshot `f05_theme`), mas com antialias.
- [x] `spark_burst.tscn` instanciado e `emit()` mostra ~12 partículas que somem e depois o nó se libera sozinho (screenshot `f05_sparks`).
- [x] `docs/ASSETS.md`: fichas continuam `placeholder` com o caminho do arquivo gerado; FX-LIGHT → `final`; UI-FONT segue `pendente` até a ação humana.
- [x] Portões do `/CLAUDE.md` §6 verdes (import limpo, 91 testes, 7 cenas no smoke).
- [x] Sem comentários no código; nada 3D.

## 6. Definição técnica

### Cenas e scripts
```
tools/placeholders.json
tools/make_placeholders.gd        extends SceneTree
tools/process_image.gd            extends SceneTree
scripts/core/image_ops.gd         class_name ImageOps (static, lógica pura)
scripts/core/asset_resolver.gd    class_name AssetResolver (static)
assets/ui/theme.tres
assets/fonts/ui_font.ttf          (após ação humana)
assets/fx/light_radial.png, assets/fx/light_cone.png
assets/placeholder/**             gerados (versionados, são pequenos)
scenes/fx/spark_burst.tscn (+ spark_burst.gd)
tests/qa/scenes/theme_probe.tscn
```

### Manifesto `tools/placeholders.json`
Caminhos relativos a `res://assets/`; o placeholder vai para `res://assets/placeholder/<path>`, exceto `"final": true` (vai direto ao caminho final).
```json
{
  "images": [
    {"id": "SPR-MU7", "path": "sprites/mu7/mu7_sheet.png", "frame": [32, 32], "grid": [6, 8], "shape": "robot", "color": "#5B6F82", "accent": "#5FE3E0"},
    {"id": "SPR-SR3", "path": "sprites/enemies/sr3_sheet.png", "frame": [32, 16], "grid": [4, 3], "shape": "oval", "color": "#D9822B"},
    {"id": "SPR-SPORE", "path": "sprites/fx/spore.png", "frame": [8, 8], "grid": [4, 1], "shape": "circle", "color": "#9BCB6ACC", "accent": "#E58FB5"},
    {"id": "SPR-TERMINAL", "path": "sprites/world/terminal_sheet.png", "frame": [32, 32], "grid": [5, 1], "shape": "box_screen", "color": "#4A5561", "accent": "#5FE38A"},
    {"id": "SPR-DOCK", "path": "sprites/world/dock_sheet.png", "frame": [32, 48], "grid": [5, 1], "shape": "frame", "color": "#3A4652", "accent": "#5FE3E0"},
    {"id": "SPR-DOOR", "path": "sprites/world/door_sheet.png", "frame": [16, 48], "grid": [7, 1], "shape": "bar_stripe", "color": "#6B737B", "accent": "#E8C15A"},
    {"id": "SPR-PICKUPS", "path": "sprites/pickups/pickups_sheet.png", "frame": [16, 16], "grid": [4, 5], "shape": "diamond_rows", "rows": ["#4FA3FF", "#E0525A", "#5FE38A", "#E8C15A", "#A36BE0"]},
    {"id": "SPR-PLATFORM", "path": "sprites/world/moving_platform.png", "frame": [48, 8], "grid": [1, 1], "shape": "rect_border", "color": "#6B737B"},
    {"id": "SPR-PLANT", "path": "sprites/world/grow_plant_sheet.png", "frame": [32, 64], "grid": [6, 1], "shape": "grow", "color": "#4F8A3C", "accent": "#E58FB5"},
    {"id": "SPR-PROPS", "path": "sprites/props/props_sheet.png", "frame": [32, 32], "grid": [6, 1], "shape": "rect_index", "color": "#56606A"},
    {"id": "SPR-BOTANICO", "path": "sprites/npc/botanico_sheet.png", "frame": [16, 16], "grid": [6, 1], "shape": "circle", "color": "#CFE8C0", "accent": "#F2D27A"},
    {"id": "TIL-CORE", "path": "tiles/core_tiles.png", "frame": [16, 16], "grid": [8, 4], "shape": "tileset", "color": "#2E5B5E", "accent": "#7FD6C8"},
    {"id": "TIL-GREENHOUSE", "path": "tiles/greenhouse_tiles.png", "frame": [16, 16], "grid": [8, 4], "shape": "tileset", "color": "#3D5A2E", "accent": "#E58FB5"},
    {"id": "BG-SPACE-FAR", "path": "backgrounds/space_far.png", "frame": [384, 216], "grid": [1, 1], "shape": "stars", "color": "#05080C", "seed": 1},
    {"id": "BG-SPACE-MID", "path": "backgrounds/space_mid.png", "frame": [384, 216], "grid": [1, 1], "shape": "nebula", "color": "#1A2A3A00", "seed": 2},
    {"id": "BG-SPACE-NEAR", "path": "backgrounds/space_near.png", "frame": [384, 216], "grid": [1, 1], "shape": "debris", "color": "#10161C", "seed": 3},
    {"id": "UI-LOGO", "path": "ui/logo.png", "frame": [192, 48], "grid": [1, 1], "shape": "logo_blocks", "color": "#BFEFF0"},
    {"id": "UI-HUD", "path": "ui/hud_sheet.png", "frame": [16, 16], "grid": [8, 2], "shape": "rect_index", "color": "#7FD6C8"},
    {"id": "FX-LIGHT", "path": "fx/light_radial.png", "frame": [256, 256], "grid": [1, 1], "shape": "radial", "final": true},
    {"id": "FX-LIGHT-CONE", "path": "fx/light_cone.png", "frame": [256, 128], "grid": [1, 1], "shape": "cone", "final": true}
  ],
  "audio": [
    {"id": "MUS-MENU", "path": "audio/music/menu.wav", "kind": "drone", "hz": 55, "seconds": 4.0, "noise": 0.15},
    {"id": "MUS-CORE", "path": "audio/music/core.wav", "kind": "drone", "hz": 65, "seconds": 4.0},
    {"id": "MUS-GREENHOUSE", "path": "audio/music/greenhouse.wav", "kind": "drone", "hz": 73, "seconds": 4.0},
    {"id": "SFX-PACK", "path": "audio/sfx/ui_confirm.wav", "kind": "beep", "hz": 880, "seconds": 0.12}
  ]
}
```
A lista de áudio contém **uma entrada por nome** da tabela [SFX-PACK](../ASSETS.md#sfx-pack) (`step_metal_1..3`, `step_soil`, `jump`, `land`, `interact`, `terminal_breaker`, `power_on`, `power_off`, `log_pickup`, `pickup`, `damage`, `low_integrity`, `flashlight`, `door_open`, `reactor_alarm`, `ui_move`, `ui_confirm`, `ui_back`, `sr3_shutdown`, `spores`, `plant_grow`), com `hz` distinto e `seconds` entre 0,08 e 0,4 (loops: 1,0).

Layout proposto do atlas de tiles (8×4, a [F21](F21-construtor-fases-ascii.md) pode alterar no manifesto e no gerador): linhas 0–1 = 16 variações de borda do sólido por bitmask 4-dir (`N=1, E=2, S=4, W=8`, índice → `col = i % 8`, `row = i / 8`); linha 2 = one-way, fundo de parede, janela, grade, cano H, cano V, luz de teto, faixa de perigo; linha 3 col 0 = parede magnética (listras amarelas), resto reservado.

### `make_placeholders.gd`
- `extends SceneTree`; em `_initialize()` lê o manifesto, para cada imagem cria `Image.create_empty(w*cols, h*rows, false, Image.FORMAT_RGBA8)`, desenha a `shape` em cada célula (variação de brilho por linha/coluna para distinguir frames), `DirAccess.make_dir_recursive_absolute` e `save_png`. `logo_blocks` desenha "ÓRBITA" com um alfabeto de blocos 5×7 embutido. Áudio: `AudioStreamWAV` `FORMAT_16_BITS`, `mix_rate 22050`, mono, seno (+ ruído opcional) com envelope de ataque/decay, `save_to_wav`. Imprime `GENERATED <n> files` e `quit(0)`; erro de escrita → `quit(1)`.

### `process_image.gd` (CLI)
```
"$GODOT" --headless --path . -s res://tools/process_image.gd -- \
  --in=/Users/BRScurPaEr/Downloads/orbita-assets/SPR-MU7/raw.png \
  --out=res://assets/sprites/mu7/mu7_sheet.png \
  --crop=0,0,1024,1365 --key=FF00FF --tolerance=0.18 \
  --frame=32x32 --grid=6x8 --colors=16 --slice
```
Ordem: carregar (`Image.load_from_file`) → `--crop` opcional → `ImageOps.chroma_key` → `ImageOps.resize_nearest(grid*frame)` → `ImageOps.reduce_palette(colors)` (ignora alpha 0) → `save_png` → `--slice` grava frames. Imprime o tamanho final e número de cores; argumentos inválidos → mensagem de uso e `quit(2)`.

### `ImageOps` (lógica pura)
```gdscript
static func chroma_key(img: Image, key: Color, tolerance: float) -> Image
static func resize_nearest(img: Image, width: int, height: int) -> Image
static func reduce_palette(img: Image, max_colors: int) -> Image
static func slice(img: Image, frame: Vector2i) -> Array[Image]
static func count_opaque_colors(img: Image) -> int
```
`reduce_palette`: quantiza cada pixel opaco para 5 bits/canal, conta frequência, fica com as `max_colors` mais frequentes e mapeia cada pixel para a mais próxima (distância euclidiana RGB). Determinístico e suficiente para pixel art.

### `AssetResolver`
```gdscript
class_name AssetResolver
extends RefCounted

const ASSETS_ROOT := "res://assets/"
const PLACEHOLDER_ROOT := "res://assets/placeholder/"

static func placeholder_path(final_path: String) -> String
static func texture(final_path: String) -> Texture2D
static func audio(final_path: String) -> AudioStream
```
`audio` tenta `final_path`, depois o mesmo nome com `.wav`/`.ogg`/`.mp3`, depois o placeholder `.wav`. Não encontrado → `null` (quem chama avisa).

### `theme.tres` (paleta de UI — ADR-F05-002)
Fundo `#05080C`, painel `#0E1A20`, borda `#2E5B5E`, texto `#CFE8E4`, destaque/foco `#7FD6C8`, desabilitado `#56606A`, perigo `#E0525A`, alerta `#E8C15A`. `StyleBoxFlat` sem cantos arredondados, borda 1 px, `content_margin` 4/2. Botão com foco: borda `#7FD6C8` + texto destacado (navegação por teclado/controle visível). `default_font` = `ui_font.ttf`; `default_font_size` definido por screenshot (m5x7 costuma ser nítida em 16).

Importação da fonte (`ui_font.ttf.import`): `antialiasing=0`, `hinting=0`, `subpixel_positioning=0`, `generate_mipmaps=false`, `multichannel_signed_distance_field=false`.

### `spark_burst.tscn`
```
SparkBurst (CPUParticles2D, script spark_burst.gd)
  emitting=false, one_shot=true, amount=12, lifetime=0.4, explosiveness=1.0,
  direction=(0,-1), spread=180, initial_velocity 30..80, gravity (0,200),
  scale_amount 1..2, color #7FD6C8 (sobrescrevível)
```
`spark_burst.gd`: `func emit(at: Vector2, tint: Color = Color("#7FD6C8")) -> void` posiciona, colore, `emitting = true`, conecta `finished` → `queue_free`.

### Autoloads / sinais do EventBus
- Nenhum.

### Input actions / camadas de colisão
- Nenhuma.

## 7. Assets necessários

| Asset id | Uso nesta feature | Placeholder |
|---|---|---|
| Todos do [`ASSETS.md`](../ASSETS.md) | Gerados pelo manifesto | Formas na paleta do setor (manifesto acima) |
| [UI-FONT](../ASSETS.md#ui-font) | Fonte do tema | Fonte padrão do Godot até a ação humana |
| [FX-LIGHT](../ASSETS.md#fx-light) | Luz radial e cone | Definitivo = gerado |
| [SFX-PACK](../ASSETS.md#sfx-pack) | Beeps por nome | Seno por nome |

## 8. 🧑 Ação humana

> 🧑 **AÇÃO HUMANA — Baixar a fonte pixel m5x7** (≈ 3 min)
> **Por quê:** a fonte é um arquivo de terceiros hospedado no itch.io, que exige um clique de download no navegador; o agente não consegue baixar sozinho.
> 1. Abra **https://managore.itch.io/m5x7** no navegador.
> 2. Clique no botão **Download Now**.
> 3. Na janela que pede um valor ("Name your own price"), clique no link cinza **No thanks, just take me to the downloads**.
> 4. Na página seguinte, clique **Download** ao lado de **m5x7.ttf**.
> 5. No Finder, crie a pasta `Downloads/orbita-assets/UI-FONT/` (Finder → Downloads → ⌘⇧N para nova pasta; crie `orbita-assets` e dentro dela `UI-FONT`).
> 6. Arraste o arquivo `m5x7.ttf` de **Downloads** para dentro de `orbita-assets/UI-FONT/`.
> **Pronto quando:** o arquivo existe em `~/Downloads/orbita-assets/UI-FONT/m5x7.ttf` (o Finder mostra o ícone de fonte). · **Avise o agente com:** "Fonte UI-FONT baixada."
>
> *Se o agente avisar que faltam acentos:* repita com **https://kenney.nl/assets/kenney-fonts** → botão **Download** (gratuito, CC0) → descompacte o `.zip` (duplo clique) → copie `Kenney Pixel.ttf` para a mesma pasta `UI-FONT/`.

Depois da confirmação, o agente copia para `assets/fonts/ui_font.ttf`, grava o `.import` com os parâmetros da seção 6, registra autor (Daniel Linssen), licença ("free to use, credit appreciated") e link no `ASSETS.md` e no `README.md`.

## 9. Plano de execução

- [x] **Passo 1** — Testes `tests/test_image_ops.gd` e `tests/test_asset_resolver.gd`.
- [x] **Passo 2** — `scripts/core/image_ops.gd` e `scripts/core/asset_resolver.gd` até os testes passarem.
- [x] **Passo 3** — `tools/placeholders.json` (20 imagens; áudio segue em `tools/make_audio_placeholders.gd`, [ADR-F05-006](#adr-f05-006)) e `tools/make_placeholders.gd`; rodar; `--import`.
- [x] **Passo 4** — `tests/test_placeholders.gd`: cada entrada do manifesto existe com a dimensão certa.
- [x] **Passo 5** — `tools/process_image.gd`; testado com um sheet sintético (MU-7 3× maior, fundo magenta, 12 762 cores) no scratchpad.
- [x] **Passo 6** — `theme.tres` + `gui/theme/custom` no `project.godot`; `scenes/fx/spark_burst.tscn`; `tests/qa/scenes/theme_probe.tscn` e `asset_probe.tscn`.
- [x] **Passo 7** — 🧑 ação humana da fonte escrita na seção 8 e entregue ao humano; **não bloqueou**: a UI usa a fonte padrão do Godot até a entrega.
- [x] **Passo 8** — Portões, QA visual (`tests/qa/f05_assets.json`), `ASSETS.md`. Commit: responsabilidade do humano/agente de commit.

## 10. Verificação

- **Testes (`tests/test_*.gd`):**
  - `test_image_ops.gd`: imagem 4×4 com magenta e azul → após `chroma_key` magenta tem `a == 0` e azul intacto; `resize_nearest` de 2×2 para 6×6 preserva blocos 3×3 exatos; `slice` de 64×32 com frame 32×32 → 2 imagens; `reduce_palette(img_com_40_cores, 16)` → `count_opaque_colors ≤ 16`.
  - `test_asset_resolver.gd`: `placeholder_path("res://assets/sprites/mu7/mu7_sheet.png") == "res://assets/placeholder/sprites/mu7/mu7_sheet.png"`; `texture()` de um caminho sem definitivo retorna não-nulo com tamanho do contrato.
  - `test_placeholders.gd`: percorre o manifesto e confere `Image.load_from_file(ProjectSettings.globalize_path(...)).get_size() == frame * grid`.
- **Smoke:** `res://scenes/fx/spark_burst.tscn`, `res://tests/qa/scenes/theme_probe.tscn`.
- **Roteiro godot-qa:** cena `theme_probe.tscn` (VBox com Label de acentos, Button, Button desabilitado, HSlider, CheckBox, ProgressBar 60%, e à direita uma grade com `TextureRect` de cada placeholder de sprite; `ui_accept` chama `SparkBurst.emit` no centro). Inputs: frame 20 `ui_accept` press, frame 22 release. Screenshots: frame 10 `f05_theme` — tema escuro com bordas ciano, texto nítido, foco visível no primeiro botão, placeholders coloridos distintos; frame 24 `f05_sparks` — faíscas ciano no centro; (após a fonte) frame 10 `f05_font` — todos os acentos legíveis.
- **Playtest humano (opcional):** olhar `f05_theme` e dizer se a UI "parece leitura de sensor".

## 11. ADRs locais

### ADR-F05-001 — `AssetResolver` com espelho `assets/placeholder/`
- **Contexto:** ADR-005 pede que o definitivo substitua o placeholder "no mesmo caminho"; mas o placeholder mora em `assets/placeholder/`.
- **Decisão:** o código sempre referencia o **caminho final**; `AssetResolver` cai no espelho `assets/placeholder/<mesmo caminho>` quando o final não existe. Cenas `.tscn` que precisam de textura a recebem por script via `AssetResolver`.
- **Consequências:** troca de arte = copiar o arquivo; zero edição de código. **Data:** 2026-09-19.

### ADR-F05-002 — Paleta de UI e placeholders
- **Contexto:** o `ASSET-PIPELINE.md` (guia de estilo) ainda não existe; o GDD descreve paletas só em palavras.
- **Decisão:** hexadecimais da seção 6 (UI) e do manifesto (setores), derivados do [GDD-2.9 Paleta](../design/GDD.md#gdd-2-9-paleta). Quando o `ASSET-PIPELINE.md` existir, ele passa a ser a fonte e o manifesto/tema são atualizados.
- **Consequências:** consistência visual imediata. **Data:** 2026-09-19.

### ADR-F05-003 — Placeholders versionados
- **Contexto:** gerar no build exigiria rodar o gerador antes de cada export.
- **Decisão:** PNG/WAV placeholder são commitados (são pequenos); o gerador é idempotente.
- **Consequências:** clone limpo roda sem passo extra. **Data:** 2026-09-19.

<a id="adr-f05-004"></a>
### ADR-F05-004 — MU-7 com grade 6×10 (e não 6×8)

- **Contexto:** o rascunho do manifesto na seção 6 traz `"grid": [6, 8]` e o critério de aceite citava 192×256, mas a ficha [SPR-MU7](../ASSETS.md#spr-mu7) lista **10** animações (`idle`, `walk`, `jump`, `fall`, `land`, `hurt`, `interact`, `climb`, `death`, `dash`) e o prompt de IA pede 10 linhas.
- **Decisão:** o **contrato do `ASSETS.md` manda**. O sheet é 6×10 de 32×32 = **192×320**. O manifesto e os testes usam esse valor.
- **Consequências:** quando o definitivo chegar, o comando de pós-processamento é `--frame=32x32 --grid=6x10`. **Data:** 2026-09-19.

<a id="adr-f05-005"></a>
### ADR-F05-005 — Paleta vinda do `ASSET-PIPELINE.md`

- **Contexto:** a ADR-F05-002 previa que, quando o `ASSET-PIPELINE.md` existisse, ele passaria a ser a fonte da paleta. Ele existe.
- **Decisão:** o bloco `palettes` de `tools/placeholders.json` espelha a tabela "Paleta de referência (hex) por setor" do [`ASSET-PIPELINE.md`](../ASSET-PIPELINE.md) — Núcleo `#1B2B34`/`#2F4F5A`/`#5FD4C8`/`#E0B43C`, Estufa `#1E2A1C`/`#3F6B3A`/`#E58FB4`/`#B7D35A`, UI `#0B0F14`/`#2F4F5A`/`#5FD4C8`/`#D9534F` — mais um `outline` escuro e um `light` por setor (contorno de 1 px exigido pelo guia de estilo). As cores de corpo específicas (laranja do SR-3, cores dos coletáveis) continuam no manifesto.
- **Consequências:** o `theme.tres` usa a linha "UI / HUD" da mesma tabela; trocar a paleta do jogo = editar uma tabela e rodar o gerador. **Data:** 2026-09-19.

<a id="adr-f05-006"></a>
### ADR-F05-006 — Áudio placeholder continua em `make_audio_placeholders.gd`

- **Contexto:** a seção 6 desta feature previa que `make_placeholders.gd` gerasse PNG **e** WAV, mas a [F04](F04-audio-volume.md) já entregou `tools/make_audio_placeholders.gd` com os 39 WAVs sintetizados e o `AudioManager` já resolve o fallback.
- **Decisão:** manter dois geradores — `make_placeholders.gd` (imagem, dirigido pelo manifesto) e `make_audio_placeholders.gd` (áudio, tabela no próprio script). O `AssetResolver.audio()` cobre o mesmo contrato de fallback do `AudioManager` para quem não usa o autoload.
- **Consequências:** nenhuma regressão na F04; o manifesto não tem seção `audio`. Se um dia valer a pena unificar, o manifesto ganha a seção e o gerador de áudio vira um módulo. **Data:** 2026-09-19.

<a id="adr-f05-007"></a>
### ADR-F05-007 — Tema sem fonte, com `default_font_size` de transição

- **Contexto:** a fonte **UI-FONT** depende de download manual (itch.io) e a feature manda não bloquear.
- **Decisão:** `assets/ui/theme.tres` sai sem `default_font` (o Godot usa a fonte padrão) e com `default_font_size = 10`, valor legível na resolução interna 384×216. O tema já está aplicado em `project.godot` → `gui/theme/custom`.
- **Consequências:** ao instalar a m5x7, a integração são **duas linhas** no `theme.tres` (`default_font` + `default_font_size = 16`, tamanho nativo da m5x7) e nenhuma mudança de cena. **Data:** 2026-09-19.

<a id="adr-f05-008"></a>
### ADR-F05-008 — `light_radial.png` de 256 px casado com `Balance.VISION_RADIUS_ON`

- **Contexto:** a textura da lanterna precisa de uma escala de referência.
- **Decisão:** `light_radial.png` é 256×256 com o gradiente indo a zero exatamente no raio 128 px = `Balance.VISION_RADIUS_ON`. Assim a F18 usa a textura com `texture_scale = 1.0` e o raio de visão do GDD-P bate com o pixel aceso.
- **Consequências:** mudar `VISION_RADIUS_ON` passa a exigir `texture_scale = VISION_RADIUS_ON / 128.0` na F18. **Data:** 2026-09-19.

## 12. Log de evolução

### 2026-09-19 — Feature criada
- **Quem**: agente de planejamento · **O que**: documento inicial a partir do `ASSETS.md`, ADR-005 e GDD-2.9 · **Próximo passo**: implementação.

### 2026-09-19 — Implementação concluída
- **Quem**: agente de implementação F05
- **O que**: manifesto `tools/placeholders.json` (20 imagens, 4 paletas) + `tools/make_placeholders.gd` (18 placeholders em `assets/placeholder/` e 2 texturas de luz definitivas em `assets/fx/`); `scripts/core/image_ops.gd` e `scripts/core/asset_resolver.gd`; `tools/process_image.gd` (chroma key, crop, resize nearest, redução de paleta, fatiamento); `assets/ui/theme.tres` aplicado como `gui/theme/custom`; `scenes/fx/spark_burst.tscn`; splash usando o logo placeholder pelo `AssetResolver`; sondas de QA `theme_probe` e `asset_probe`; suítes `test_image_ops`, `test_asset_resolver`, `test_placeholders` (68 → **91** testes).
- **Portões**: `--import` sem erro · `91 passed, 0 failed` · smoke 7/7 · varreduras 3D e comentários vazias.
- **QA visual** (`tests/qa/f05_assets.json`, escala 3): `f05_splash_logo` (logo "ÓRBITA" em blocos ciano com acento e anel de órbita), `f05_contato_prova` (MU-7 legível + tile do Núcleo azul-esverdeado + tile da Estufa verde-musgo), `f05_theme` (painéis escuros, borda ciano, foco visível, acentos completos), `f05_sparks` (faíscas ciano no centro).
- **ADRs**: ADR-F05-004 a ADR-F05-008.
- **Próximo passo**: 🧑 ação humana da fonte m5x7 (seção 8) → copiar para `assets/fonts/ui_font.ttf`, escrever o `.import` sem antialias e ligar as duas linhas do `theme.tres`.
