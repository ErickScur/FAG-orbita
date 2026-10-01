---
id: F21
title: Construtor de fases ASCII
status: done
scope: demo
block: 2
priority: P0
rubric: []
depends_on: ["F02", "F05", "F06", "F12"]
unblocks: ["F13", "F17", "F18", "F19", "F20", "F22", "F23", "F24", "F25", "F26", "F27", "F28", "F29"]
estimate: 3.5h
last_updated: 2026-09-19
---

# F21 — Construtor de fases ASCII

## 1. Contexto e objetivo

O humano não sabe usar o editor do Godot e o agente não consegue editar com segurança o formato binário de `TileMapLayer` dentro de um `.tscn`. Por isso ([ADR-004](../DECISIONS.md#adr-004)) **toda fase do ÓRBITA é um arquivo de texto**: `data/levels/<fase>.txt` (uma linha = uma linha de tiles de 16 px) + `data/levels/<fase>.json` (parâmetros por coordenada e metadados). O `LevelBuilder` lê o texto, preenche o `TileMapLayer` com autotile por bitmask, instancia as entidades por caractere e configura câmera, luz ambiente, música, terminais e gatilhos.

Editar uma fase passa a ser **editar texto** — algo que agente e humano fazem sem editor, com diff legível no git e verificação por screenshot.

É infraestrutura: não pontua sozinha, mas sem ela não existem a Fase 0 (F28) nem a Estufa (F29).

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.7 Level design](../design/GDD.md#gdd-2-7) · [GDD-2.7 F0](../design/GDD.md#gdd-2-7-f0) e [F1](../design/GDD.md#gdd-2-7-f1) (o que cada fase da demo precisa conter) · [GDD-2.2](../design/GDD.md#gdd-2-2) (nós previstos: `TileMapLayer`, `Area2D`) · [GDD-2.9 Paleta](../design/GDD.md#gdd-2-9-paleta)
- **Parâmetros:** `Balance.TILE_SIZE` (16) — [GDD-P](../design/GDD.md#gdd-p) · [AJ-001](../design/GDD.md#gdd-ajustes)
- **Jornada:** [Etapa 4](../design/JORNADA-DO-HEROI.md#jh-4) (o corredor habitacional é a transição Núcleo → Estufa)
- **ADRs:** [ADR-004](../DECISIONS.md#adr-004) (**a decisão que origina esta feature**) · [ADR-003](../DECISIONS.md#adr-003) (16 px, limites de câmera) · [ADR-005](../DECISIONS.md#adr-005) (tiles placeholder) · [ADR-006](../DECISIONS.md#adr-006) (JSON) · [ADR-007](../DECISIONS.md#adr-007) (testes de lógica pura)
- **Assets:** [TIL-CORE](../ASSETS.md#til-core) · [TIL-GREENHOUSE](../ASSETS.md#til-greenhouse)

## 3. Critério de avaliação atendido

Nenhum item direto (infra), mas habilita "Desenvolvimento de fases", "Plataformas que se movimentam", "Área secreta", "Paralax" e o Puzzle — e é um ótimo argumento no slide "Por dentro" da apresentação ([ENTREGAS §4](../ENTREGAS.md#apresentacao)): *fases em ASCII, versionadas em texto*.

## 4. Escopo

### Inclui
- **Parser puro** `scripts/core/level_parser.gd`: texto → estrutura (sólidos, one-way, entidades, spawn, dimensões), com validação e erros legíveis; **zero nós** (testável headless).
- **Autotile próprio por bitmask 4-direções** (sem `TerrainSet` do editor): máscara 0–15 → coordenada de atlas, documentado na §6.4.
- **`LevelBuilder`** (`scripts/core/level_builder.gd`, funções que recebem os nós como parâmetro): preenche `Background` e `Solid`, instancia entidades, cria gatilhos de diálogo, zona de morte e limites de câmera.
- **Gerador de TileSet** `tools/make_tileset.gd` (headless): escreve `assets/tiles/core_tileset.tres` e `greenhouse_tileset.tres` com atlas 16 px, colisão por tile, **one-way**, camada de oclusão (F18) e a legenda de atlas da §6.4. O `.tres` é um arquivo de texto revisável no git.
- **`scenes/levels/level_base.tscn` (+ `.gd`)**: cena-mãe de toda fase (`@export var level_id`), no grupo `level`, com `TileMapLayer`s, `CanvasModulate`, `EnergyNetwork`, HUD, entidades e o passo de respawn (F13).
- **Legenda completa** (§6.3) e **esquema do JSON de fase** (§6.5).
- **Fase de teste** `data/levels/test_room.txt` + `.json` + `scenes/levels/test_room.tscn` cobrindo todos os caracteres implementados.
- Tolerância a entidades ainda não implementadas (stretch F31–F34): `push_warning` e segue.

### Não inclui
- O conteúdo das fases da demo (Núcleo Central e Estufa) — F28/F29.
- As entidades em si (SR-3 F22, esporos F23, plataformas/planta F25, parallax F26, parede secreta F27, vapor/piso elétrico F32, drone F34) — aqui só o **mapeamento** e o contrato `configure(params)`.
- Editor visual, importador de Tiled, rotação/flip de tiles, tiles animados.
- Terrenos com transição suave entre dois materiais (autotile é de um material só por camada).
- Streaming/chunking de fases grandes (as fases da demo cabem em memória com folga).

## 5. Critérios de aceite

- [x] `LevelParser.parse` devolve dimensões corretas, conjunto de sólidos, one-ways, lista de entidades com célula e caractere, e o spawn `P`. (`test_level_parser.gd::test_dimensions`, `test_solids_and_oneways`, `test_entities_collected`, `test_spawn_required`)
- [x] Linhas de comprimentos diferentes são **preenchidas à direita** com vazio e geram aviso, não erro. (`test_ragged_lines_pad`)
- [x] Caractere desconhecido gera erro com linha/coluna (`"linha 2, coluna 4: caractere '&' desconhecido"`, 1-based). (`test_unknown_char_error`)
- [x] Ausência de `P` ou mais de um `P` gera erro. (`test_spawn_required`)
- [x] A máscara de vizinhança produz o tile correto nos 16 casos (teste exaustivo). (`test_neighbor_mask_all_16`, `test_atlas_coords_for_mask`, `test_mask_out_of_bounds_is_solid`)
- [x] Carregar `test_room.tscn` monta a sala inteira: chão, plataformas one-way, jogador no `P`, doca, terminal de registros, props, lâmpadas — e `push_warning` citando a feature para o que ainda não existe (F17/F20/F22/F23/F24/F25/F27) — **sem nenhum `ERROR:` no log** (smoke verde).
- [x] Limites de câmera batem com o tamanho da fase (`width*16` × `height*16`). Horizontalmente nada fora do mapa aparece (screenshot `f21_04_camera_limite`); verticalmente a sala de teste (160 px) é mais baixa que o viewport (216 px) e o Godot centraliza — ver [ADR-F21-008](#adr-f21-008).
- [x] A zona de morte fica 2 tiles abaixo do fundo e mata (aplica `GameState.apply_damage(integrity_max)`; rearma em `player_respawned`).
- [x] Entidades com `id` no JSON entram no grupo `entity:<id>`; com `group`, no grupo indicado. Nós energizados recebem `terminal_id`/`system_id` como propriedade, conforme [ADR-011](../DECISIONS.md#adr-011).
- [x] `"triggers"` viram `Area2D` funcionais nas coordenadas em tiles indicadas (`dialogue`, `objective`, `set_flag`, todos com `once` — [ADR-012](../DECISIONS.md#adr-012)); provado em jogo pelos screenshots `f21_02_bark_andando` e `f21_04_camera_limite`.
- [x] Recarregar a fase reproduz exatamente o mesmo mundo (determinístico), respeitando `collected_ids`. `energy_states` fica a cargo do `EnergyNetwork` (F17) via `load_terminals`.
- [x] `tools/make_tileset.gd` roda headless e regenera os `.tres` de forma idêntica (diff vazio ao rodar duas vezes — ids normalizados, [ADR-F21-006](#adr-f21-006)).
- [x] Portões do `/CLAUDE.md` §6 verdes (272 testes, 36 cenas de smoke, varreduras vazias)
- [x] Sem comentários no código; nada 3D

## 6. Definição técnica

### 6.1 Cenas e scripts
```
scripts/core/level_parser.gd     class_name LevelParser (pura)
scripts/core/level_builder.gd    class_name LevelBuilder (constrói usando nós recebidos)
tools/make_tileset.gd            gerador headless dos .tres
assets/tiles/core_tileset.tres
assets/tiles/greenhouse_tileset.tres
scenes/levels/level_base.tscn (+ level_base.gd)
scenes/levels/test_room.tscn
data/levels/test_room.txt
data/levels/test_room.json
tests/test_level_parser.gd
tests/test_level_data.gd
```

### 6.2 `level_base.tscn`
```
Level (Node2D)                   script level_base.gd · groups: ["level"]
├─ Background (TileMapLayer)     z_index -10 · tile_set do JSON
├─ Solid (TileMapLayer)          colisão world (1) + one_way (7)
├─ Parallax (Node2D)             ponto de entrada da F26
├─ Entities (Node2D)             tudo que o builder instancia
├─ Triggers (Node2D)             gatilhos de diálogo/região
├─ DeathZone (Area2D)            2 tiles abaixo do fundo · camada hazard (5)
├─ EnergyNetwork (Node)          F17 · grupo "energy_network"
├─ CanvasModulate                cor de `ambient_color` (F18)
└─ HUD (instância de hud.tscn)   F15
```
`level_base.gd`:
```gdscript
@export var level_id: String = ""

func _ready() -> void
func spawn_position() -> Vector2
func camera_rect() -> Rect2i
```
Ordem do `_ready()`: 1) carrega `.txt`/`.json`; 2) `LevelParser.parse` (erro → `push_error` + aborta); 3) `LevelBuilder.build_tiles`; 4) `LevelBuilder.build_entities`; 5) `EnergyNetwork` carrega terminais e aplica o estado (silencioso); 6) instancia o jogador no `P` **ou** na doca do checkpoint (respawn, F13); 7) `set_camera_limits` + `snap_camera`; 8) aplica `ambient_color`, `music`, `floor_sfx`, `reactor_online`; 9) objetivo inicial (`objective`) e `on_enter_dialogue` (F19).

### 6.3 Legenda ASCII (1 caractere = 1 tile de 16 px)

> Fonte única: `const LEGEND := {...}` no topo de `scripts/core/level_builder.gd`, espelhando esta tabela. **Âncora:** todas as features do projeto usam exatamente estes caracteres.

| Char | Nome | O que o builder faz | Âncora | Feature dona |
|:--:|---|---|---|---|
| `#` | Sólido | Tile na camada `Solid` com colisão `world`; autotile por bitmask | — | F21 |
| `=` | Plataforma one-way | Tile com colisão `one_way` (atravessa por baixo) | — | F21/F12 |
| (espaço) | Vazio | Só o tile de fundo na camada `Background` | — | F21 |
| `P` | Spawn do jogador | Posição inicial (obrigatório, exatamente 1) | pés | F21/F12 |
| `D` | Doca de backup | `scenes/world/backup_dock.tscn` (checkpoint + recarga) | pés | F11/F13 |
| `T` | Terminal de distribuição | `scenes/world/distribution_terminal.tscn`; `terminal`, `role`, `sector`, `log_on_restore` no JSON | pés | F17 |
| `L` | Terminal de log | `scenes/world/log_object.tscn` (`style: terminal`), `id` = log | pés | F19 |
| `l` | Fragmento de log | `scenes/world/collectible.tscn` (`kind: log`) | centro | F20 |
| `r` | Dado de pesquisa | `collectible.tscn` (`kind: research`) | centro | F20 |
| `c` | Célula de energia | `collectible.tscn` (`kind: cell`) | centro | F20 |
| `k` | Kit de solda | `collectible.tscn` (`kind: repair_kit`) | centro | F20 |
| `C` | Núcleo de capacitor | `collectible.tscn` (`kind: capacitor`) | centro | F20 |
| `\|` | Porta de energia | `scenes/world/door.tscn` (3 tiles de altura, ancorada no tile inferior) | pés | F17 |
| `E` | Saída / transição | `scenes/world/level_exit.tscn` (`target`, `dock_id` no JSON) | pés | F28/F29 |
| `S` | SR-3 | `scenes/enemies/sr3.tscn` (patrulha da plataforma sob ele) | pés | F22 |
| `~` | Esporos | `scenes/enemies/spore_swarm.tscn` (`group` para o terminal) | centro | F23 |
| `M` | Parede magnética | `scenes/world/magnetic_wall.tscn` (escalável com Garras) | centro | F24 |
| `m` | Plataforma móvel | `scenes/world/moving_platform.tscn` (`path`, `speed` no JSON) | centro | F25 |
| `g` | Planta que cresce | `scenes/world/grow_plant.tscn` (vira plataforma ao crescer) | pés | F25 |
| `x` | Parede falsa | `scenes/world/secret_wall.tscn` (some ao encostar/interagir) | centro | F27 |
| `W` | Janela | Tile de janela na camada `Background` (mostra o parallax) | — | F21/F26 |
| `@` | Lâmpada | `scenes/world/powered_lamp.tscn` (`group`, `color`, `radius`) | centro | F18 |
| `o` | Prop | `Sprite2D` da folha de props; com `"log"` no JSON vira `log_object` (`style: prop`) | pés | F19/F28 |
| `b` | Drone BOTÂNICO 04 | `scenes/npc/botanico.tscn` | centro | F34 (stretch) |
| `v` | Jato de vapor | `scenes/world/steam_vent.tscn` ([ADR-F21-008](#adr-f21-008)) | pés | F32 (stretch) |
| `z` | Piso eletrificado | `scenes/world/electric_floor.tscn` | pés | F32 (stretch) |

**Âncoras:** `pés` = `(cell.x * 16 + 8, cell.y * 16 + 16)` (base do tile, mesma convenção do MU-7); `centro` = `(cell.x * 16 + 8, cell.y * 16 + 8)`.

### 6.4 Autotile por bitmask (atlas de 8 colunas)

Máscara de um tile sólido: `1` se o vizinho **acima** é sólido, `+2` direita, `+4` abaixo, `+8` esquerda (fora do mapa conta como sólido, para a borda do mapa não virar parede recortada). A máscara 0–15 vira coordenada de atlas: `Vector2i(mask % 8, mask / 8)` → linhas 0 e 1 do atlas.

| Linha | Coluna | Conteúdo |
|:--:|:--:|---|
| 0 | 0–7 | Sólidos com máscara 0–7 |
| 1 | 0–7 | Sólidos com máscara 8–15 |
| 2 | 0 | Plataforma one-way (`=`) |
| 2 | 1 | Parede de fundo (`Background` padrão) |
| 2 | 2 | Janela (`W`) |
| 2 | 3 | Grade de ventilação |
| 2 | 4 | Cano horizontal |
| 2 | 5 | Cano vertical |
| 2 | 6 | Luminária de teto (decorativa; a luz real é o `@`) |
| 2 | 7 | Faixa de perigo |

Esse layout é exatamente o contrato de [TIL-CORE](../ASSETS.md#til-core) e [TIL-GREENHOUSE](../ASSETS.md#til-greenhouse) (16 variações de borda + extras).

**Colisão/oclusão no `.tres`** (gerado por `tools/make_tileset.gd`):
- `physics_layer_0`: `collision_layer = 1` (`world`), polígono quadrado 16×16 nos tiles de sólido (linhas 0–1).
- `physics_layer_1`: `collision_layer = 64` (`one_way`), polígono com `one_way = true` só no tile (2,0).
- `occlusion_layer_0`: polígono quadrado só nos sólidos com máscara ≠ 15 ([ADR-F18-003](F18-luz-lanterna.md)).
- Trecho do `.tres` gerado (referência de formato):
```
[sub_resource type="TileSetAtlasSource" id="atlas_core"]
texture = ExtResource("tiles")
texture_region_size = Vector2i(16, 16)
0:0/0 = 0
0:0/0/physics_layer_0/polygon_0/points = PackedVector2Array(-8, -8, 8, -8, 8, 8, -8, 8)
2:0/0 = 0
2:0/0/physics_layer_1/polygon_0/points = PackedVector2Array(-8, -8, 8, -8, 8, 8, -8, 8)
2:0/0/physics_layer_1/polygon_0/one_way = true
```

### 6.5 Esquema de `data/levels/<fase>.json`
```json
{
  "id": "greenhouse",
  "name": "Estufa",
  "tileset": "res://assets/tiles/greenhouse_tileset.tres",
  "ambient_color": "#141b1a",
  "music": "greenhouse",
  "floor_sfx": "step_soil",
  "reactor_online": true,
  "terminals": ["greenhouse"],
  "objective": "obj_find_terminal_gh",
  "on_enter_dialogue": "gh_enter",
  "entities": {
    "12,30": { "id": "gh_terminal_a", "terminal": "greenhouse" },
    "44,7":  { "id": "gh_terminal_b", "terminal": "greenhouse" },
    "47,6":  { "id": "gh_node", "terminal": "greenhouse", "role": "sector_node",
               "sector": "greenhouse", "log_on_restore": "log_gh_03" },
    "40,8":  { "id": "gh_node_door" },
    "8,26":  { "id": "log_gh_01" },
    "22,18": { "group": "gh_spores" },
    "5,29":  { "group": "gh_corridor_lamps", "color": "#bfe6ff", "radius": 64 },
    "30,20": { "id": "gh_lift", "path": [[0, 0], [0, -8]], "speed": 40 },
    "18,24": { "id": "gh_plant_1" },
    "54,29": { "id": "exit_demo", "target": "res://scenes/ui/demo_end.tscn" }
  },
  "triggers": [
    { "id": "trg_spores", "rect": [20, 14, 6, 8], "dialogue": "gh_spores" }
  ]
}
```

| Campo | Significado |
|---|---|
| `tileset` | Caminho do `.tres` usado nas duas camadas |
| `ambient_color` | Cor do `CanvasModulate` (F18) |
| `music` | Id passado a `AudioManager.play_music` |
| `floor_sfx` | Som de passo da fase (F12) |
| `reactor_online` | Liga o timer ao entrar (F14) — usado em fases de teste e na Estufa |
| `terminals` | Ids de `data/energy/*.json` carregados pelo `EnergyNetwork` (F17) |
| `objective` / `on_enter_dialogue` | Objetivo inicial (F15) e sequência de entrada (F19) |
| `entities["x,y"]` | Parâmetros da entidade naquela célula; `id` → grupo `entity:<id>`; `group` → grupo extra; o resto vai para `configure(params)` |
| `triggers[]` | `rect` em **tiles** `[x, y, largura, altura]` + `dialogue` (+ `once`, default `true`) |

### 6.6 `level_parser.gd` (pura)
```gdscript
class_name LevelParser
extends RefCounted

const SOLID := "#"
const ONE_WAY := "="
const EMPTY := " "

static func parse(text: String, legend_chars: String) -> Dictionary
static func neighbor_mask(solids: Dictionary, cell: Vector2i, width: int, height: int) -> int
static func atlas_coords_for_mask(mask: int) -> Vector2i
static func cell_to_position(cell: Vector2i, anchor: StringName, tile_size: int) -> Vector2
```
`parse` devolve:
```gdscript
{
  "width": int, "height": int,
  "solids": Dictionary,          # Vector2i -> true
  "one_ways": Array[Vector2i],
  "entities": Array[Dictionary], # {symbol: String, cell: Vector2i}
  "spawn": Vector2i,
  "errors": PackedStringArray,
  "warnings": PackedStringArray
}
```

### 6.7 `level_builder.gd`
```gdscript
class_name LevelBuilder
extends RefCounted

const LEGEND := {}   # espelho da tabela §6.3: char -> {scene, anchor, kind, feature}

static func build_tiles(parsed: Dictionary, solid: TileMapLayer, background: TileMapLayer) -> void
static func build_entities(parsed: Dictionary, meta: Dictionary, parent: Node2D, level_id: String) -> void
static func build_triggers(meta: Dictionary, parent: Node2D) -> void
static func build_death_zone(parsed: Dictionary, zone: Area2D) -> void
```
- `build_entities`: para cada entidade, resolve a cena da `LEGEND`; se `ResourceLoader.exists(path)` for falso → `push_warning("entidade '<char>' ainda não implementada (F<id>)")` e segue. Instancia, posiciona pela âncora, aplica `params` do JSON (`id` → `add_to_group("entity:" + id)`, `group` → `add_to_group(group)`), chama `configure(params)` se existir e, para coletáveis, injeta `kind` e `item_id` (`PickupRules.default_item_id` quando não houver `id`).
- `build_tiles`: `Background` recebe o tile de parede de fundo em toda célula não sólida (e o tile de janela onde houver `W`); `Solid` recebe `atlas_coords_for_mask` nos `#` e o tile one-way nos `=`.

### 6.8 Fase de teste (`data/levels/test_room.txt`)

32 colunas × 10 linhas, cobrindo os caracteres implementáveis na demo:

```
################################
#   @          @          @    #
#           c        r         #
#         =====    =====       #
#  l                        k  #
# ====          ~~      ###### #
#      g        m           M x#
#                              #
#P  D   o   S     T    |  L  E #
################################
```

`data/levels/test_room.json`:
```json
{
  "id": "test_room",
  "name": "Sala de teste",
  "tileset": "res://assets/tiles/core_tileset.tres",
  "ambient_color": "#191d26",
  "music": "core",
  "floor_sfx": "step_metal",
  "reactor_online": true,
  "terminals": ["core_hub"],
  "objective": "obj_calibrate",
  "entities": {
    "18,8": { "id": "test_terminal", "terminal": "core_hub" },
    "22,8": { "id": "door_habitat" },
    "25,8": { "id": "log_core_01" },
    "3,4":  { "id": "log_hab_01" },
    "7,6":  { "id": "test_plant" },
    "16,6": { "id": "test_lift", "path": [[0, 0], [0, -3]], "speed": 30 },
    "4,1":  { "group": "core_lights" },
    "15,1": { "group": "core_lights" },
    "26,1": { "group": "core_lights" },
    "16,5": { "group": "test_spores" },
    "17,5": { "group": "test_spores" },
    "28,8": { "id": "test_exit", "target": "res://scenes/levels/test_room.tscn" }
  },
  "triggers": [
    { "id": "trg_test", "rect": [10, 4, 6, 4], "dialogue": "core_calib_move" }
  ]
}
```
`scenes/levels/test_room.tscn` = instância de `level_base.tscn` com `level_id = "test_room"`.

### 6.9 Autoloads / sinais do EventBus
- Emite: nada diretamente (repassa para as features donas). O `level_base` chama `GameState.set_objective`, `AudioManager.play_music`, `DialogueManager.play`.
- Usa: `GameState.collected_ids` (coletáveis já pegos somem), `GameState.energy_states` (F17), `GameState.checkpoint`/`flags.respawn_pending` (F13).

### 6.10 Input actions / camadas de colisão
- Sem input novo.
- `Solid`: camadas `world` (1) e `one_way` (7). `DeathZone`: `hazard` (5), mask `player` (2). `Triggers`: mask `player` (2).

## 7. Assets necessários

| Asset id | Uso nesta feature | Placeholder |
|---|---|---|
| [TIL-CORE](../ASSETS.md#til-core) | Atlas do Núcleo (16 bordas + one-way + fundo + janela + extras) | Quadrados azul-esverdeados com borda clara (F05) |
| [TIL-GREENHOUSE](../ASSETS.md#til-greenhouse) | Mesmo layout, paleta da Estufa (inclui parede magnética listrada) | Verde-musgo com pontos rosa (F05) |

## 8. 🧑 Ação humana

Nenhuma.

## 9. Plano de execução

- [x] **Passo 1** — `tests/test_level_parser.gd` (seção 10) → falha → `scripts/core/level_parser.gd` → passa.
- [x] **Passo 2** — `tools/make_tileset.gd` + rodar headless → conferir `core_tileset.tres` e `greenhouse_tileset.tres` (colisão, one-way, oclusão).
- [x] **Passo 3** — `scripts/core/level_builder.gd` com a `LEGEND` da §6.3 e `build_tiles`.
- [x] **Passo 4** — `scenes/levels/level_base.tscn` + `level_base.gd` (ordem do `_ready()` da §6.2).
- [x] **Passo 5** — `build_entities` (âncoras, grupos, `configure`, tolerância a cena ausente) e `build_triggers`/`build_death_zone`.
- [x] **Passo 6** — `data/levels/test_room.txt`/`.json` + `scenes/levels/test_room.tscn`; adicionar a `tests/scenes.txt`.
- [x] **Passo 7** — `tests/test_level_data.gd` (todo `.txt` tem `.json`, coordenadas dentro do mapa, ids únicos).
- [x] **Passo 8** — Integrações: spawn/respawn (F13), `EnergyNetwork` (F17), HUD (F15), câmera (F12).
- [x] **Passo 9** — Portões + QA; documentar no log qualquer caractere novo pedido por outra feature.

## 10. Verificação

- **Testes (`tests/test_level_parser.gd`):**
  - `test_dimensions` — texto de 5×3 → `width == 5`, `height == 3`.
  - `test_solids_and_oneways` — posições corretas de `#` e `=`.
  - `test_spawn_required` — sem `P` → erro; com dois `P` → erro; com um → `spawn` correto.
  - `test_unknown_char_error` — caractere fora da legenda → erro citando linha e coluna.
  - `test_ragged_lines_pad` — linhas curtas viram vazio à direita + aviso.
  - `test_neighbor_mask_all_16` — tabela exaustiva das 16 combinações.
  - `test_mask_out_of_bounds_is_solid` — tile na borda do mapa tem vizinho externo sólido.
  - `test_atlas_coords_for_mask` — `0 → (0,0)`, `7 → (7,0)`, `8 → (0,1)`, `15 → (7,1)`.
  - `test_cell_to_position_anchors` — `(2,3)` com âncora `pés` → `(40, 64)`; com `centro` → `(40, 56)`.
  - `test_entities_collected` — cada caractere de entidade vira um item da lista com célula certa.
- **Testes (`tests/test_level_data.gd`):**
  - `test_every_txt_has_json` — todo `data/levels/*.txt` tem `.json` par.
  - `test_json_entity_coords_exist` — toda chave `"x,y"` aponta para uma célula dentro do mapa **e** que tenha entidade no `.txt`.
  - `test_trigger_rects_inside` — todo `rect` cabe no mapa.
  - `test_tileset_paths_exist` — `tileset` aponta para arquivo existente.
  - `test_terminals_exist` — todo id em `terminals` tem `data/energy/<id>.json`.
- **Smoke:** `res://scenes/levels/level_base.tscn`, `res://scenes/levels/test_room.tscn`.
- **Roteiro godot-qa** (`tests/qa/f21_level.json`; cena `res://scenes/levels/test_room.tscn`):

| Frame | Input | Screenshot | O que deve aparecer |
|---:|---|---|---|
| 10 | — | `f21_01_sala` | Sala montada: chão e teto sólidos com bordas corretas, plataformas `=`, lâmpadas acesas, MU-7 em pé no `P` (canto inferior esquerdo), doca ao lado |
| 15 | — | `f21_02_entidades` | Terminal, porta, terminal de log, coletáveis (`c`, `l`, `r`, `k`), planta, plataforma móvel, esporos e SR-3 posicionados nas células da legenda |
| 20–120 | segurar `move_right`, pulando nas plataformas | `f21_03_oneway` | MU-7 atravessando a one-way por baixo e pousando em cima |
| 200 | — | `f21_04_camera_limite` | Câmera parada no limite direito da sala (nada fora do mapa) |
| 260 | andar até a saída `E` | `f21_05_transicao` | Sala recarregada; coletáveis já pegos **ausentes** |

- Conferência de log: `tools/smoke.sh` não pode mostrar `ERROR:`; `push_warning` de entidade não implementada é aceitável e deve citar a feature.
- **Playtest humano (opcional):** mostrar ao humano o `.txt` ao lado do screenshot e perguntar se ele consegue apontar onde mudar para mover uma plataforma.

## 11. ADRs locais

### ADR-F21-001 — Autotile por bitmask próprio, não `TerrainSet`
- **Contexto:** terrenos do Godot exigem configuração pesada no editor e são difíceis de escrever à mão num `.tres`.
- **Decisão:** máscara 4-direções → índice de atlas (`mask % 8`, `mask / 8`), com os 16 tiles nas duas primeiras linhas do atlas. Fora do mapa conta como sólido.
- **Consequências:** o contrato do tileset fica simples e previsível para o artista; `set_cell` direto, sem `set_cells_terrain_connect`. Cantos internos diagonais não são tratados (aceitável no estilo).
- **Data:** 2026-09-19

### ADR-F21-002 — TileSet gerado por script, versionado como `.tres`
- **Contexto:** o [ADR-004](../DECISIONS.md#adr-004) prevê `.tres` escrito pelo agente; escrever 16+ blocos de polígono à mão é frágil.
- **Decisão:** `tools/make_tileset.gd` (headless) gera os `.tres` de forma determinística; o arquivo é commitado e revisável.
- **Consequências:** trocar a arte do tileset = trocar o PNG e rodar o gerador; o diff do `.tres` mostra exatamente o que mudou.
- **Data:** 2026-09-19

### ADR-F21-003 — Parâmetros por coordenada `"x,y"` no JSON
- **Contexto:** o `.txt` não comporta parâmetros (qual terminal, qual log, qual caminho de plataforma).
- **Decisão:** `entities` indexado pela célula `"coluna,linha"` (0-based), aplicado via `configure(params)`.
- **Consequências:** mover uma entidade no `.txt` exige mover a chave no `.json` — o `test_level_data` avisa quando a chave não corresponde a nenhuma entidade.
- **Data:** 2026-09-19

### ADR-F21-004 — Entidade sem cena não quebra a fase
- **Contexto:** F22–F34 chegam depois; fases de teste usam caracteres ainda não implementados.
- **Decisão:** cena ausente → `push_warning` citando a feature responsável, e a construção continua.
- **Consequências:** é possível escrever as fases da demo antes das entidades existirem; o portão de smoke continua exigindo zero `ERROR:`.
- **Data:** 2026-09-19

### ADR-F21-005 — Porta e doca ancoradas no tile inferior
- **Contexto:** porta (16×48) e doca (32×48) ocupam mais de um tile.
- **Decisão:** um único caractere no tile **inferior**; a entidade se estende para cima (e para os lados, no caso da doca).
- **Consequências:** a legenda fica com 1 char por entidade; quem desenha a fase deixa espaço livre acima.
- **Data:** 2026-09-19

<a id="adr-f21-006"></a>
### ADR-F21-006 — Ids do `.tres` normalizados depois do `ResourceSaver`
- **Contexto:** `ResourceSaver.save` gera ids aleatórios para `ExtResource`/`SubResource` (`OccluderPolygon2D_nl0nb`), então rodar o gerador duas vezes produzia um diff enorme e falso.
- **Decisão:** `tools/make_tileset.gd` compartilha um único `OccluderPolygon2D` e, depois de salvar, reescreve o texto trocando os ids gerados por nomes estáveis (`tiles`, `occluder_square`, `atlas_source`).
- **Consequências:** rodar o gerador duas vezes dá diff vazio (verificado); o `.tres` fica legível e revisável no git.
- **Data:** 2026-09-19

<a id="adr-f21-007"></a>
### ADR-F21-007 — `id_property` e `aliases` na legenda, em vez de `configure` obrigatório
- **Contexto:** as entidades entregues pelas features vizinhas expõem `@export` com nomes próprios (`dock_id`, `log_id`, `lamp_color`, `prop_column`) e não implementam `configure(params)`.
- **Decisão:** cada entrada da `LEGEND` pode declarar `id_property` (para onde vai o `id` do JSON) e `aliases` (chave do JSON → nome da propriedade). O `LevelBuilder` ainda chama `configure(params)` quando existir.
- **Consequências:** a fase em JSON continua falando a linguagem do design (`terminal`, `color`, `log`) e cada feature mantém seus nomes de `@export`. Trocar o nome de um `@export` exige atualizar a legenda.
- **Data:** 2026-09-19

<a id="adr-f21-008"></a>
### ADR-F21-008 — `steam_vent.tscn` e sala de teste sem plataforma alcançável
- **Contexto:** a §6.3 citava `scenes/world/steam_jet.tscn`, mas o `/CLAUDE.md` §4.1 lista `steam_vent`. A sala de teste da §6.8 também desenha as plataformas `=` a 4 tiles do chão, acima do alcance do pulo (`JUMP_HEIGHT = 40` px = 2,5 tiles).
- **Decisão:** a legenda aponta para `res://scenes/world/steam_vent.tscn` (vale o `/CLAUDE.md`). A sala de teste continua como está: ela é **fixture de cobertura da legenda**, não fixture de plataforma — a travessia de one-way já é coberta pelo QA da F12.
- **Consequências:** a F32 cria `steam_vent.tscn`. Fases reais (F28/F29) precisam respeitar 2 tiles de altura entre plataformas.
- **Data:** 2026-09-19

## 12. Log de evolução

> Append-only. Mais novo no fim.

### 2026-09-19 — Feature criada
- **Quem**: agente de planejamento · **O que**: documento inicial com legenda completa, esquema de JSON e fase de teste · **Próximo passo**: implementação.

### 2026-09-19 — Implementada
- **Quem**: agente de implementação · **O que**: `LevelParser` puro, `LevelBuilder` com a `LEGEND` completa (21 caracteres), autotile por bitmask, `tools/make_tileset.gd` determinístico (`core_tileset.tres` + `greenhouse_tileset.tres` com colisão `world`, one-way e oclusão), `level_base.tscn`/`.gd`, `test_room.txt`/`.json`/`.tscn`, probe de QA `tests/qa/scenes/level_probe.tscn`, suítes `test_level_parser.gd` (14 testes) e `test_level_data.gd` (8 testes). · **Próximo passo**: F28/F29 escrevem as fases da demo usando a legenda da §6.3.
- **Divergências**: coordenadas do `test_room.json` da §6.8 corrigidas para as reais do `.txt` (`23,8` porta, `26,8` log, `29,8` saída, `28,4` kit); acrescentado um `C` (capacitor) na linha 2 para a sala cobrir todos os caracteres da demo; `reactor_online` fica `false` na sala de teste para não ligar o timer em QA.
- **Pendências**: `EnergyNetwork` (F17) só é chamado por `load_terminals(ids)` se o nó tiver o método — o nó existe no grupo `energy_network` e espera o script da F17. `data/energy/core_hub.json` ainda não existe, então `test_terminals_exist` só valida quando houver algum arquivo em `data/energy/`.

