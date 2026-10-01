---
id: F12
title: Movimento do MU-7 & câmera
status: done
scope: demo
block: 2
priority: P0
rubric: []
depends_on: ["F02", "F05", "F06"]
unblocks: ["F13", "F16", "F18", "F21", "F22", "F24", "F25", "F31"]
estimate: 2.5h
last_updated: 2026-09-19
---

# F12 — Movimento do MU-7 & câmera

## 1. Contexto e objetivo

O MU-7 é o corpo da ÓRBITA: um chassi de manutenção velho, pesado e um pouco lento **de propósito**. Esta feature entrega o controle de plataforma 2D (andar, pular com altura variável, descer de plataformas finas) e a câmera que segue o jogador com leve antecipação na direção do movimento. É a base de tudo que vem depois (dano, interação, lanterna, inimigos, garras, plataformas móveis).

Serve aos pilares **ESCASSEZ** (o chassi não é ágil; cada salto é pensado) e **AUSÊNCIA** (o peso do corpo velho reforça a solidão da máquina). Aparece para o jogador desde o primeiro segundo da Fase 0, justificado narrativamente como *"calibração do chassi"*.

O controle precisa **parecer justo** mesmo sendo pesado: coyote time, jump buffer e pulo variável entram por isso — são invisíveis ao jogador, mas eliminam a sensação de "apertei e não pulou".

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.6.1 Status base](../design/GDD.md#gdd-2-6-1-status) (velocidade, pulo, gravidade) · [GDD-2.4 Controles](../design/GDD.md#gdd-2-4) (`jump` segurar = pulo mais alto; `move_down` desce de plataforma fina) · [GDD-2.2 Visão geral](../design/GDD.md#gdd-2-2) (câmera com leve antecipação) · [GDD-2.9 Estilo visual](../design/GDD.md#gdd-2-9-visual) (animação econômica, 4–6 frames, peso e leve atraso) · [GDD-2.9 SFX](../design/GDD.md#gdd-2-9-sfx) (passos metálicos, servo hidráulico no pulo, impacto pesado)
- **Parâmetros:** `Balance.WALK_SPEED` (110 px/s), `Balance.JUMP_HEIGHT` (40 px), `Balance.GRAVITY` (980 px/s²), `Balance.TILE_SIZE` (16) — [GDD-P](../design/GDD.md#gdd-p). Novos (ADR-F12-001): `COYOTE_TIME`, `JUMP_BUFFER_TIME`, `JUMP_CUT_MULTIPLIER`, `MAX_FALL_SPEED`, `WALK_ACCEL`, `WALK_DECEL`, `AIR_ACCEL_RATIO`, `DROP_THROUGH_TIME`, `CAMERA_LOOKAHEAD`, `CAMERA_LOOKAHEAD_SPEED`, `CAMERA_SMOOTHING`, `CAMERA_OFFSET_Y`
- **Ajustes:** [AJ-001](../design/GDD.md#gdd-ajustes) (tile 16 px, pulo = 40 px)
- **Jornada:** [Etapa 1 — Mundo Comum](../design/JORNADA-DO-HEROI.md#jh-1) (tutorial como "calibração do chassi")
- **ADRs:** [ADR-000](../DECISIONS.md#adr-000) (só 2D) · [ADR-003](../DECISIONS.md#adr-003) (384×216, limites de câmera por fase) · [ADR-005](../DECISIONS.md#adr-005) (placeholder) · [ADR-010](../DECISIONS.md#adr-010) (Input Map e camadas)
- **Assets:** [SPR-MU7](../ASSETS.md#spr-mu7) · [SFX-PACK](../ASSETS.md#sfx-pack)

## 3. Critério de avaliação atendido

Nenhum item da rubrica diretamente (é **base**), mas atende ao requisito do 1º bimestre "Plataforma 2D / Movimentação" ([GDD-2.10](../design/GDD.md#gdd-2-10)). O avaliador vê: o MU-7 andando com peso, pulo curto (toque) e pulo alto (segurar), descendo por uma plataforma fina com ↓+ESPAÇO, câmera deslizando levemente à frente do movimento e parando nas bordas da fase.

## 4. Escopo

### Inclui
- Cena `scenes/player/mu7.tscn` (`CharacterBody2D`) com script `mu7.gd` tipado.
- Andar com aceleração/desaceleração (sensação de chassi pesado), sem deslizar.
- **Pulo variável:** velocidade inicial derivada de `Balance.JUMP_HEIGHT` e `Balance.GRAVITY` (`v0 = √(2·g·h)` = 280 px/s); soltar `jump` durante a subida corta a velocidade por `JUMP_CUT_MULTIPLIER`.
- **Coyote time** e **jump buffer** (lógica pura testável em `scripts/core/platformer_math.gd`).
- Velocidade máxima de queda (`MAX_FALL_SPEED`).
- **Plataformas one-way** (camada 7 `one_way`): o jogador sobe por baixo e fica em cima; `move_down` + `jump` atravessa para baixo.
- `Camera2D` filha do MU-7 com suavização, **look-ahead** horizontal e **limites por fase** (`set_camera_limits(rect_px)`), processada em física para não tremer.
- `AnimatedSprite2D` com as animações do contrato [SPR-MU7](../ASSETS.md#spr-mu7): `idle`, `walk`, `jump`, `fall`, `land`, `hurt`, `interact`, `climb` (as duas últimas só ficam registradas; quem as toca é F16/F24; `hurt` é tocada pela F13).
- Virar o sprite conforme a direção (`flip_h`), mantendo o `facing` para câmera/lanterna.
- API de travamento de input: `set_input_locked(locked: bool)` (usada por diálogo, terminal, morte).
- SFX: `jump`, `land`, passos (`step_metal_1..3` ou `step_soil`, conforme a fase).
- Cena de teste `scenes/dev/movement_test.tscn` (sala montada por código, sem LevelBuilder) para validar antes da F21.

### Não inclui
- **Dash** (F31), **pulo duplo/Propulsor** (Final, F42), **garras/escalada** (F24), **escadas/dutos com `move_up`** (sem escadas na demo; Final).
- Dano, knockback, invencibilidade e morte (F13) — a F12 só expõe `velocity` e `set_input_locked`.
- Gravidade alterada por sistemas de energia / zonas 0g (Final, Docas).
- Passos que mudam por material de piso tile a tile (a demo usa um som por fase, via metadado da fase).
- Remapeamento de teclas (F51).

## 5. Critérios de aceite

- [x] Com `move_right` pressionado em chão plano, o MU-7 atinge `Balance.WALK_SPEED` (110 px/s ± 1) em ≤ 0,15 s e para em ≤ 0,12 s ao soltar. — `test_walk_speed_reached_within_budget` (0,1233 s) e `test_walk_stops_within_budget` (0,0917 s).
- [x] Toque rápido em `jump` (1 frame) produz pulo visivelmente mais baixo que segurar; segurando, o pico fica em **40 px ± 2** acima do chão. — medido em cena: **14 px** (toque) × **40 px** (segurando); sonda de física: 17,19 px × 40,07 px.
- [x] Apertar `jump` até `COYOTE_TIME` depois de sair de uma borda ainda pula; depois disso não pula. — `test_coyote_allows_late_jump` / `test_coyote_expires`.
- [x] Apertar `jump` até `JUMP_BUFFER` antes de tocar o chão faz o pulo sair no pouso. — `test_buffer_triggers_on_landing` / `test_buffer_expires`.
- [x] Plataforma one-way: pular por baixo atravessa; pousar em cima segura; `move_down`+`jump` em cima dela faz cair através; em chão sólido `move_down`+`jump` apenas pula (medido: sobe 14 px e a máscara `one_way` continua ligada).
- [x] Queda nunca ultrapassa `MAX_FALL_SPEED` (medido 400,0 px/s em queda de 560 px).
- [x] Animações trocam corretamente: `idle` parado, `walk` andando, `jump` subindo, `fall` caindo, `land` por 1 ciclo no pouso; sprite vira com a direção (`flip_h` conferido pixel a pixel nas capturas 05/06).
- [x] Câmera: parado depois de andar para a direita o MU-7 fica **24 px** à esquerda do centro; em movimento a antecipação líquida cai para ~4 px por causa do atraso do `position_smoothing` (ver ADR-F12-007). Nas bordas da sala a câmera não passa de `limit_*`.
- [x] Sem tremedeira de pixel perceptível na câmera ao andar (câmera em `CAMERA2D_PROCESS_PHYSICS` + snap 2D do projeto).
- [x] `set_input_locked(true)` zera input horizontal e ignora `jump` (gravidade continua).
- [x] SFX `jump`/`land` tocam uma vez por evento; passos tocam nos frames 1 e 4 do `walk` (nenhum aviso de "efeito sonoro ausente" nos logs de QA).
- [x] Nenhum número mágico: todos os valores vêm de `Balance`.
- [x] Portões do `/CLAUDE.md` §6 verdes (import limpo, 158 testes, 20 cenas no smoke, varreduras vazias).
- [x] Sem comentários no código; nada 3D

## 6. Definição técnica

> Seção atualizada na implementação. Onde diverge do plano original há um ADR local (F12-004 a F12-007).

### Cenas e scripts
```
scripts/core/platformer_math.gd          class_name PlatformerMath (estático)
scripts/core/jump_assist.gd              class_name JumpAssist (RefCounted)
scripts/core/sprite_sheet.gd             class_name SpriteSheet (estático)
scenes/player/mu7.tscn (+ mu7.gd)        CharacterBody2D, class_name Mu7
tests/qa/scenes/mu7_sandbox.tscn (+ .gd) sala de teste construída por código
tests/test_platformer_math.gd            13 casos
tests/test_jump_assist.gd                10 casos
tests/test_sprite_sheet.gd                5 casos
tests/qa/f12_01..11_*.json               11 roteiros godot-qa (um por prova)
```

**Árvore de `mu7.tscn`** (origem do nó = **pés, centro**):
```
MU7 (CharacterBody2D)      script mu7.gd · groups ["player"] · layer 2 · mask 65 (world+one_way)
├─ CollisionShape2D        RectangleShape2D 14×24 · position (0, -12)
├─ AnimatedSprite2D        position (0, -16) · sprite_frames montado em _ready()
├─ OneWayProbe (RayCast2D) target_position (0, 4)   · mask 64 (one_way)
├─ OneWayClearance (RayCast2D) target_position (0, -24) · mask 64 (one_way)
└─ Camera2D                process_callback = PHYSICS · smoothing on · limit_smoothed
```
`floor_snap_length = 4.0`. Os nós reservados de outras features (`InteractionSensor`, `Hurtbox`,
`Flashlight`) **não** nascem aqui: quem os cria é a F16/F13/F18.

**Câmera:** o enquadramento vertical (`CAMERA_OFFSET_Y`) e o look-ahead horizontal
(`CAMERA_LOOK_AHEAD`) são aplicados na **posição** do nó `Camera2D`, não em `Camera2D.offset`
(ADR-F12-006) — `offset` escapa de `limit_*` e mostrava fora da sala.

**`platformer_math.gd`:**
```gdscript
static func jump_velocity(height: float, gravity: float, step: float = 0.0) -> float
static func approach(current: float, target: float, amount: float) -> float
static func apply_jump_cut(velocity_y: float, multiplier: float) -> float
static func clamp_fall(velocity_y: float, max_fall: float) -> float
static func simulate_jump_peak(v0: float, gravity: float, step: float, max_fall: float) -> float
```
`jump_velocity` devolve **negativo**; com `step > 0` desconta `gravity * step / 2` para que o pico
discreto bata exatamente em `JUMP_HEIGHT` (ADR-F12-005). `simulate_jump_peak` replica a ordem do
`_physics_process` (move → integra) e existe para os testes.

**`jump_assist.gd`:** `_init(coyote, buffer)`, `update(delta, on_floor)`, `press()`, `consume()`,
`cancel()`, `coyote_left()`, `buffer_left()`.

**`sprite_sheet.gd`:** `build_frames(texture, frame_size, rows) -> SpriteFrames`, onde cada linha é
`{"name", "row", "frames", "fps", "loop"}`. A textura vem de
`AssetResolver.texture("res://assets/sprites/mu7/mu7_sheet.png")` — nunca caminho fixo de placeholder.

**Fluxo de `_physics_process(delta)`:** drop-timer → eixo (`0` se travado) → aceleração
(`WALK_ACCEL`/`WALK_DECEL`, ×`AIR_ACCEL_RATIO` no ar) → gravidade + `clamp_fall` → assistência de
pulo (drop-through, `consume`, corte ao soltar) → `move_and_slide()` → pouso (`land` + SFX) →
`facing`/`flip_h` → estado de animação → look-ahead da câmera.

**Estados** (`enum State { IDLE, WALK, JUMP, FALL, LAND, ACTION }`): `LAND` segura até
`animation_finished`; `ACTION` é forçado de fora por `play_action(anim)` (seam para F13 `hurt`,
F16 `interact`, F24 `climb`, F31 `dash`).

**Animações montadas** (grade 6×10 de 32×32, contrato [SPR-MU7](../ASSETS.md#spr-mu7)):

| Animação | Linha | Frames | FPS | Loop | Quem toca |
|---|:--:|:--:|:--:|:--:|---|
| `idle` | 0 | 4 | 4 | sim | F12 |
| `walk` | 1 | 6 | 10 | sim | F12 |
| `jump` | 2 | 2 | 8 | não | F12 |
| `fall` | 3 | 2 | 8 | sim | F12 |
| `land` | 4 | 2 | 12 | não | F12 |
| `hurt` | 5 | 2 | 10 | não | F13 |
| `interact` | 6 | 4 | 8 | não | F16 |
| `climb` | 7 | 4 | 8 | sim | F24 |
| `death` | 8 | 4 | 8 | não | F13 |
| `dash` | 9 | 3 | 12 | não | F31 |

**Passos:** `AnimatedSprite2D.frame_changed` → em `walk`, nos frames 1 e 4, com `is_on_floor()`,
`AudioManager.play_sfx(floor_sfx)`. `floor_sfx` é `@export` e vale `&"step_metal"` por padrão (o
`AudioManager` sorteia `step_metal_1..3`); a fase troca para `&"step_soil"` (F21).

**API pública de `mu7.gd`:**
```gdscript
var facing: int
@export var floor_sfx: StringName
func set_input_locked(locked: bool) -> void
func is_input_locked() -> bool
func set_camera_limits(rect_px: Rect2i) -> void
func snap_camera() -> void
func play_action(anim: StringName) -> void
```

**`mu7_sandbox.tscn`** (sala de 768×216, `set_camera_limits(Rect2i(0, 0, 768, 216))`, spawn em
`(112, 160)`, chão em `y = 160`):

| Elemento | Retângulo (px) | Para quê |
|---|---|---|
| Degrau de 2 tiles | `(0, 128, 64, 88)` | pulo longo sobe, curto não |
| Chão A | `(64, 160, 368, 56)` | andar, pular, câmera |
| Plataforma one-way | `(432, 160, 48, 4)` | ponte sobre o poço, drop-through |
| Fundo do poço | `(432, 192, 48, 24)` | poço de 3 tiles de vão / 2 de fundo |
| Chão B | `(480, 160, 288, 56)` | limite direito da câmera |
| Degrau de 1 tile | `(608, 144, 48, 16)` | degrau curto |
| Paredes | `(-16, …)` e `(768, …)` | fecham a sala |

A sala também escuta a ação `map` para alternar `get_tree().paused` (ADR-F12-008): é só um gancho de
QA, porque a captura do `QACapture` resolve o `await RenderingServer.frame_post_draw` com atraso
quando a janela não está em foco.

### Autoloads / sinais do EventBus
- Lê: `Balance`. Chama: `AudioManager.play_sfx(name)`.
- Escuta: `EventBus.dialogue_started` / `dialogue_finished` → `set_input_locked(true/false)`.
- Emite: nada.

### Dados (`data/`)
- Nenhum.

### Input actions / camadas de colisão
- Ações usadas: `move_left`, `move_right`, `move_down`, `jump`.
- MU-7: `collision_layer` = 2 (`player`); `collision_mask` = 1 + 64 (`world` + `one_way`).
  `OneWayProbe` e `OneWayClearance`: mask só 64.

## 7. Assets necessários

| Asset id | Uso nesta feature | Placeholder |
|---|---|---|
| [SPR-MU7](../ASSETS.md#spr-mu7) | Todas as animações do chassi (grade 6×8 de 32×32) | Retângulo cinza-azulado 20×26 com "olho" ciano, uma cor por linha/animação (F05) |
| [SFX-PACK](../ASSETS.md#sfx-pack) | `jump`, `land`, `step_metal_1..3`, `step_soil` | Beeps gerados (F05/F04) |

## 8. 🧑 Ação humana

Nenhuma.

## 9. Plano de execução

- [x] **Passo 1** — Constantes novas (ADR-F12-001/004) em `scripts/core/balance.gd` e em `tests/test_balance.gd`. **Pendente:** espelhar na tabela [GDD-P](../design/GDD.md#gdd-p) + linha em [Ajustes](../design/GDD.md#gdd-ajustes) — esta rodada não tinha permissão de editar `docs/design/`.
- [x] **Passo 2** — `tests/test_platformer_math.gd` e `tests/test_jump_assist.gd` escritos antes da implementação.
- [x] **Passo 3** — `scripts/core/platformer_math.gd` (`PlatformerMath`) e `scripts/core/jump_assist.gd` (`JumpAssist`).
- [x] **Passo 4** — `scenes/player/mu7.tscn` + `mu7.gd`; `SpriteFrames` montado em `_ready()` por `scripts/core/sprite_sheet.gd` a partir do caminho resolvido pelo `AssetResolver`.
- [x] **Passo 5** — Câmera: suavização, look-ahead, `set_camera_limits`, `snap_camera`.
- [x] **Passo 6** — Drop-through em one-way com `OneWayProbe` + `OneWayClearance` + timer.
- [x] **Passo 7** — SFX de pulo, pouso e passos.
- [x] **Passo 8** — `tests/qa/scenes/mu7_sandbox.tscn`; `mu7.tscn` e a sala registrados em `tests/scenes.txt`.
- [x] **Passo 9** — Portões + QA visual por screenshot (11 capturas medidas em pixels).

## 10. Verificação

### Portões (2026-09-19, todos verdes)
- `--import`: sem `SCRIPT ERROR` / `Parse Error` / `ERROR:`.
- `tests/run_tests.gd`: **158 passed, 0 failed** (eram 128 antes da F12; +30 casos).
- `tools/smoke.sh`: **20 cenas OK**, incluindo `res://scenes/player/mu7.tscn` e
  `res://tests/qa/scenes/mu7_sandbox.tscn`.
- Varreduras `Node3D|Camera3D|MeshInstance3D|Body3D|Area3D` e `^\s*#` em `.gd`: vazias.

### Testes de lógica pura
- `tests/test_platformer_math.gd` — velocidade derivada e negativa, compensação de meia gravidade,
  pico do pulo cheio = `JUMP_HEIGHT` ± 2, pulo cortado < metade, toque não vence 2 tiles, pulo cheio
  vence 2 tiles, corte só na subida, `clamp_fall`, `approach` sem ultrapassar, tempo de aceleração
  (≤ 0,15 s) e de frenagem (≤ 0,12 s).
- `tests/test_jump_assist.gd` — pulo no chão, sem aperto não pula, coyote válido/expirado, buffer
  aproveitado/expirado, `consume()` zera, `cancel()`, recarga do coyote, tempos negativos limitados.
- `tests/test_sprite_sheet.gd` — folha resolvida pelo `AssetResolver`, 6×10 de 32×32, todas as
  animações registradas com contagem/loop corretos, regiões seguindo a grade, textura nula segura.
- `tests/test_balance.gd` — as 12 constantes novas entraram na tabela esperada.

### QA visual (11 capturas, 384×216, `--fixed-fps 60`, sala `mu7_sandbox`)
Cada roteiro congela a árvore (`map`) antes de capturar, para a imagem corresponder ao frame pedido.
Medidas em pixels de tela, com o chão da sala em `y = 160` (tela = mundo, a câmera fica presa pelos
limites verticais).

| Captura | Roteiro | Medida |
|---|---|---|
| `f12_01_idle` | `f12_01_idle.json` | pés em `y = 160`, `idle` rodando, sprite 20×30 |
| `f12_02_apice_curto_f40` | `f12_02_pulo_curto.json` | pés em `y = 146` → **14 px** acima do chão |
| `f12_03_apice_longo_f47` | `f12_03_pulo_longo.json` | pés em `y = 120` → **40 px** acima do chão |
| `f12_04_andando_direita` | `f12_04_andar_direita.json` | `walk` (tinta da linha 1), olhando para a direita |
| `f12_05_camera_antecipa_direita` | `f12_05_camera_direita.json` | câmera 3,8 px à frente do jogador em movimento |
| `f12_06_camera_antecipa_esquerda` | `f12_06_camera_esquerda.json` | `flip_h` invertido, antecipação para a esquerda |
| `f12_07_degrau2_pulo_curto_falha` | `f12_07_degrau_pulo_curto.json` | pés em `y = 146`, degrau em `y = 128` → não sobe |
| `f12_08_degrau2_pulo_longo_sobe` | `f12_08_degrau_pulo_longo.json` | pés em `y = 128` → **em cima** do degrau de 2 tiles |
| `f12_09_sobre_plataforma_oneway` | `f12_09_sobre_oneway.json` | em pé na ponte one-way, 21,5 px à esquerda do centro |
| `f12_10_desceu_pela_oneway` | `f12_10_descer_oneway.json` | dentro do poço, pés em `y = 192`, abaixo da ponte |
| `f12_11_saiu_do_poco` | `f12_11_sair_poco.json` | de volta ao chão em `y = 160` |

Comando usado (a saída vai para um diretório de scratch, não para o repo):
```bash
"$GODOT" --path . --fixed-fps 60 -- --qa \
  --qa-scene=res://tests/qa/scenes/mu7_sandbox.tscn \
  --qa-script=res://tests/qa/f12_03_pulo_longo.json --qa-out=<dir>
```

### Sondas de física (headless, sem render)
- toque de 1 frame: pico **17,19 px**; pulo segurado: pico **40,07 px** (`JUMP_HEIGHT` = 40).
- degrau de 2 tiles: com toque termina em `(71, 160)`; segurando termina em `(7, 128)` — em cima.
- queda de 560 px: velocidade máxima **400,0 px/s** = `MAX_FALL_SPEED`.
- câmera: `position.x` chega a ±24 (`CAMERA_LOOK_AHEAD`); parado o centro fica 24,0 px à frente do
  jogador, andando fica 3,8 px (atraso do `position_smoothing`).
- `set_input_locked(true)` com `move_right`+`jump` pressionados: posição e velocidade não mudam.
- chão sólido com `move_down`+`jump`: sobe 14 px e a máscara `one_way` continua ligada.

## 11. ADRs locais

### ADR-F12-001 — Parâmetros de sensação ausentes no GDD-P
- **Contexto:** o GDD define velocidade, altura de pulo e gravidade, mas não corte de pulo,
  aceleração, queda máxima nem os parâmetros restantes de câmera. Sem eles o controle fica "duro".
- **Decisão:** usar os valores que **já existiam** na [GDD-P](../design/GDD.md#gdd-p) via AJ-006
  (`COYOTE_TIME`, `JUMP_BUFFER`, `CAMERA_SMOOTHING`, `CAMERA_LOOK_AHEAD`) e acrescentar ao `Balance`
  só o que faltava:

| Constante | Valor | Unidade | Origem |
|---|---|---|---|
| `COYOTE_TIME` | 0.12 | s | já no GDD-P (AJ-006) |
| `JUMP_BUFFER` | 0.12 | s | já no GDD-P (AJ-006) |
| `CAMERA_SMOOTHING` | 5.0 | fator | já no GDD-P (AJ-006) |
| `CAMERA_LOOK_AHEAD` | 24 | px | já no GDD-P (AJ-006) |
| `JUMP_CUT_MULTIPLIER` | 0.5 | fração | novo |
| `MAX_FALL_SPEED` | 400 | px/s | novo |
| `WALK_ACCEL` | 900 | px/s² | novo |
| `WALK_DECEL` | 1200 | px/s² | novo |
| `AIR_ACCEL_RATIO` | 0.7 | fração | novo |
| `DROP_THROUGH_TIME` | 0.2 | s | novo |
| `CAMERA_LOOK_AHEAD_SPEED` | 4.0 | 1/s | novo |
| `CAMERA_OFFSET_Y` | -16 | px | novo |

- **Consequências:** o pulo segurado dá exatamente 40 px; com toque mínimo dá 14–17 px. Alcance
  horizontal de um pulo completo ≈ 63 px (≈ 4 tiles) → **regra de level design**: vãos de até
  3 tiles e degraus de até 2 tiles.
- **Divergência do plano:** os nomes `JUMP_BUFFER_TIME`, `CAMERA_LOOKAHEAD` e `CAMERA_LOOKAHEAD_SPEED`
  do plano viraram `JUMP_BUFFER`, `CAMERA_LOOK_AHEAD` e `CAMERA_LOOK_AHEAD_SPEED` para casar com os
  nomes já publicados na GDD-P; `CAMERA_SMOOTHING` ficou 5.0 (GDD) em vez de 8.0, e
  `CAMERA_LOOK_AHEAD` ficou 24 px (GDD) em vez de 32 px.
- **Data:** 2026-09-19

### ADR-F12-002 — Velocidade do pulo derivada, não tabelada
- **Contexto:** o GDD fala em altura (2,5 tiles), não em velocidade.
- **Decisão:** `v0 = √(2·GRAVITY·JUMP_HEIGHT)` calculado em `PlatformerMath.jump_velocity`. Mudar `JUMP_HEIGHT` ou `GRAVITY` no GDD ajusta o pulo automaticamente.
- **Consequências:** nenhuma constante de velocidade de pulo no `Balance`; zonas de gravidade diferente (Final) continuam coerentes.
- **Data:** 2026-09-19

### ADR-F12-003 — Drop-through por desligamento temporário da máscara
- **Contexto:** Godot 4 não tem "descer de one-way" nativo.
- **Decisão:** remover o bit `one_way` da `collision_mask` por `DROP_THROUGH_TIME` e empurrar 1 px para baixo; detectar a one-way sob os pés com `RayCast2D` só na camada 7.
- **Consequências:** simples e testável por screenshot; plataformas one-way precisam **só** da camada 7 (a F21 garante no TileSet).
- **Data:** 2026-09-19

### ADR-F12-004 — `platformer_math.gd` e `jump_assist.gd` em arquivos separados
- **Contexto:** o plano pedia `PlatformerMath` + `JumpAssist` no mesmo arquivo; GDScript só aceita um
  `class_name` por arquivo, o que obrigaria `PlatformerMath.JumpAssist` como classe interna.
- **Decisão:** dois arquivos em `scripts/core/`, cada um com seu `class_name`, e uma suíte de testes
  para cada. Nasceu junto `scripts/core/sprite_sheet.gd` (`SpriteSheet.build_frames`), que o plano já
  previa mas ainda não existia.
- **Consequências:** `JumpAssist.new(coyote, buffer)` é usado direto; F22 (SR-3) e F42 reaproveitam.
- **Data:** 2026-09-19

### ADR-F12-005 — Velocidade de pulo compensa o passo de física
- **Contexto:** `v0 = √(2·g·h)` só dá `h` no contínuo. Integrando a 1/60 s na ordem do
  `_physics_process` (move e depois integra a gravidade) o pico sai em **42,4 px**, fora do critério
  de 40 ± 2.
- **Decisão:** `jump_velocity(height, gravity, step)` devolve `-(√(2·g·h) − g·step/2)`. Com `step = 0`
  (default) continua valendo `−280` para os testes do contrato; com `step = delta` o pico discreto dá
  40,07 px.
- **Consequências:** o pulo continua derivado de `JUMP_HEIGHT`/`GRAVITY` (ADR-F12-002); nenhuma
  constante de velocidade entra no `Balance`. Se a taxa de física mudar, o pulo continua com 40 px.
- **Data:** 2026-09-19

### ADR-F12-006 — Enquadramento da câmera na posição do nó, não em `Camera2D.offset`
- **Contexto:** com `offset = (look_ahead, CAMERA_OFFSET_Y)` a câmera mostrava 16 px acima do topo da
  sala (faixa cinza fora de `limit_top`), porque o `offset` do Godot 4 é aplicado **depois** do corte
  por `limit_*`.
- **Decisão:** aplicar `CAMERA_OFFSET_Y` e o look-ahead em `Camera2D.position` (o nó é filho do MU-7),
  deixando `offset` zerado. Assim os limites cortam o enquadramento inteiro.
- **Consequências:** nas bordas da sala a antecipação é absorvida pelo limite, que é o comportamento
  correto. Em salas com exatamente a altura da tela o `CAMERA_OFFSET_Y` não aparece — só em salas
  mais altas.
- **Data:** 2026-09-19

### ADR-F12-007 — Antecipação visível só com o jogador parado (pendência de tuning)
- **Contexto:** `position_smoothing_speed = CAMERA_SMOOTHING = 5.0` produz um atraso de regime
  `velocidade / suavização = 110 / 5 = 22 px` **contra** o look-ahead de 24 px. Resultado medido: em
  movimento o MU-7 fica só ~4 px do lado certo do centro; parado, fica os 24 px cheios.
- **Decisão:** **não** inventar compensação de atraso no código. O comportamento é 100% governado por
  `Balance.CAMERA_LOOK_AHEAD` e `Balance.CAMERA_SMOOTHING`, que são números do GDD.
- **Consequências:** se o playtest pedir antecipação mais forte em movimento, sobe-se
  `CAMERA_SMOOTHING` (ex.: 8.0 → atraso 13,75 px) e/ou `CAMERA_LOOK_AHEAD` **no GDD-P**, sem tocar em
  código. Fica registrado como pendência de tuning para a F21/F28.
- **Data:** 2026-09-19

### ADR-F12-008 — Sala de QA em `tests/qa/scenes/` com gancho de congelamento
- **Contexto:** o plano previa `scenes/dev/movement_test.tscn`. Todas as cenas de prova do projeto
  moram em `tests/qa/scenes/`. Além disso, o `QACapture` resolve o `await
  RenderingServer.frame_post_draw` com muito atraso quando a janela perde o foco: numa corrida de 400
  frames, 12 de 14 screenshots saíram idênticas e correspondiam a um frame muito posterior.
- **Decisão:** a sala vive em `tests/qa/scenes/mu7_sandbox.tscn` e alterna `get_tree().paused` ao
  receber a ação `map`; o jogador é marcado `PROCESS_MODE_PAUSABLE` e a sala `PROCESS_MODE_ALWAYS`.
  Cada roteiro congela a cena, tira **uma** foto e sai. A sala também **não** entra no grupo
  `gameplay`, senão o menu de pausa abre sozinho quando a janela perde o foco
  (`pause_menu.gd` → `NOTIFICATION_APPLICATION_FOCUS_OUT`).
- **Consequências:** QA por screenshot determinístico, ao custo de um processo por foto. A limitação
  do `QACapture` continua de pé e vale para as próximas features — ver o log abaixo.
- **Data:** 2026-09-19

## 12. Log de evolução

> Append-only. Mais novo no fim.

### 2026-09-19 — Feature criada
- **Quem**: agente de planejamento · **O que**: documento inicial a partir do GDD · **Próximo passo**: implementação.

### 2026-09-19 — Implementação
- **Quem**: agente de implementação (F12)
- **O que**: `PlatformerMath`, `JumpAssist`, `SpriteSheet`, `mu7.tscn`/`mu7.gd` (movimento, pulo
  variável, coyote, buffer, drop-through one-way, câmera com limites e antecipação, SFX de pulo,
  pouso e passos), sala `tests/qa/scenes/mu7_sandbox.tscn`, 11 roteiros de QA, 30 casos de teste
  novos (128 → 158) e 8 constantes novas no `Balance`.
- **Portões**: import limpo, 158 passed / 0 failed, 20 cenas no smoke, varreduras de 3D e de
  comentários vazias, 11 screenshots medidas em pixels.
- **Pendências**: (a) espelhar as 8 constantes novas na tabela GDD-P + linha em Ajustes — esta
  rodada não podia editar `docs/design/`; (b) tuning da antecipação da câmera em movimento
  (ADR-F12-007); (c) `QACapture` perde sincronia de screenshot quando a janela não está em foco
  (ADR-F12-008) — candidato a lição em `CLAUDE.md` §9 e a correção na F06.
- **Próximo passo**: F13 (integridade/dano) e F21 (construtor de fases) reaproveitam
  `set_camera_limits`, `play_action` e `set_input_locked`.

### 2026-09-19 — Correção: ↓ sozinho não descia da plataforma fina (relato do jogador)
- **Sintoma**: andar e pular funcionavam, mas descer da plataforma one-way não.
- **Causa**: `_try_drop_through()` só era chamado dentro do `_handle_jump()`, ou seja, exigia **↓ + Espaço**. O [GDD-2.4](../design/GDD.md#gdd-2-4) diz que `move_down` sozinho já desce de plataforma fina.
- **Correção**: `_physics_process` chama `_try_drop_through()` em `Input.is_action_just_pressed(&"move_down")`; o caminho ↓+pulo continua valendo.
- **Verificação**: roteiro de regressão `tests/qa/f12_12_descer_oneway.json` — captura A mostra o MU-7 em cima da ponte ciana, captura B mostra ele dentro do poço, abaixo dela.
- **Lição**: o QA do agente havia "provado" a descida com ↓+pulo, que não é o controle do GDD. Roteiro de QA precisa usar **o controle documentado**, não o que o código implementou.

