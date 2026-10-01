---
id: F25
title: Plataformas móveis & planta que cresce
status: done
scope: demo
block: 3
priority: P0
rubric: ["Plataformas que se movimentam"]
depends_on: ["F02", "F12", "F17", "F21"]
unblocks: ["F29"]
estimate: 2h
last_updated: 2026-09-19
---

# F25 — Plataformas móveis & planta que cresce

## 1. Contexto e objetivo

Dois elementos de cenário que **só funcionam se tiverem energia** — e por isso são o braço mecânico do Terminal de Distribuição:

1. **Elevador de carga** (`m`): uma plataforma que percorre um trajeto definido no JSON da fase. Se o sistema `lift` estiver ligado, ela anda (ida e volta, com pausa nas pontas); se não, ela **para onde está**. É a rota vertical entre a base e o meio da Estufa.
2. **Planta que cresce** (`g`): a cultura hidropônica da Estufa. Sob a **LUZ DE CRESCIMENTO** ela cresce em poucos segundos e o topo vira plataforma. É o puzzle-assinatura do setor descrito no GDD: *"ligar a luz de crescimento faz a planta crescer e virar plataforma, mas apaga a lanterna do corredor"*.

Serve ao pilar **ESCASSEZ**: as duas rotas existem, mas o orçamento de energia não paga as duas ao mesmo tempo.

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.7-F1 — Estufa](../design/GDD.md#gdd-2-7-f1) (a planta-plataforma) · [GDD-2.6.1 — Redirecionamento de energia](../design/GDD.md#gdd-2-6-1-redirecionamento) ("o nível não muda de forma, muda de ESTADO") · [GDD-2.5 regra de energia](../design/GDD.md#gdd-2-5-energia) · [GDD-2.9 estética (onde tem luz, tem energia)](../design/GDD.md#gdd-2-9-visual)
- **Parâmetros:** `Balance.TILE_SIZE`, `Balance.WALK_SPEED`, `Balance.JUMP_HEIGHT` — [GDD-P](../design/GDD.md#gdd-p). **Novos (ADR-F25-001):** `Balance.PLATFORM_SPEED`, `Balance.PLATFORM_WAIT`, `Balance.PLANT_GROW_TIME`.
- **Jornada:** [Etapa 5 — Testes e Aliados (Estufa)](../design/JORNADA-DO-HEROI.md#jh-5)
- **ADRs:** [ADR-004](../DECISIONS.md#adr-004) · [ADR-006](../DECISIONS.md#adr-006) · [ADR-000](../DECISIONS.md#adr-000)
- **Features vizinhas:** [F17 — Terminal de Distribuição](F17-terminal-distribuicao.md) (grupo `"powered"`, `energy_changed`), [F21 — Construtor de fases](F21-construtor-fases-ascii.md) (caracteres `m` e `g`), [F29 — Estufa](F29-fase-estufa.md) (posições e trajetos), [F11](F11-salvar-carregar.md) (a planta crescida entra no save).

## 3. Critério de avaliação atendido

**Plataformas que se movimentam** ([rubrica](../ENTREGAS.md#rubrica)). Na apresentação, na Estufa: o jogador chega num poço vertical com a plataforma **parada** (sem energia); abre o Terminal, move uma unidade de energia para o **ELEVADOR DE CARGA**; a plataforma acende a luz verde e começa a subir e descer; o MU-7 embarca e é carregado para o andar de cima. Logo depois, a mesma lógica com a **planta**: ligar a LUZ DE CRESCIMENTO faz o broto virar uma plataforma viva — e apaga as luzes do corredor, obrigando o jogador a usar a lanterna.

## 4. Escopo

### Inclui
- `scenes/world/moving_platform.tscn` + `moving_platform.gd`: `AnimatableBody2D` com `sync_to_physics`, trajeto em tiles vindo do JSON, ida-e-volta (ping-pong), pausa nas pontas, luz de status.
- `scenes/world/grow_plant.tscn` + `grow_plant.gd`: crescimento progressivo sob energia, plataforma one-way no topo quando adulta, luz rosa de cultivo, SFX.
- Contrato `"powered"`: `@export var terminal_id: StringName` + `@export var system_id: StringName`, estado inicial lido de `GameState.energy_states` e atualizações por `EventBus.energy_changed`.
- Lógica pura `scripts/core/path_follower.gd` (trajeto/ping-pong/pausa) e `scripts/core/growth.gd` (progresso de crescimento), com testes.
- Persistência: planta adulta continua adulta depois de recarregar (`GameState.flags`).
- Carregar o jogador: o MU-7 em cima da plataforma sobe com ela sem tremer (`sync_to_physics = true` + `move_and_slide` do `CharacterBody2D`).

### Não inclui
- Plataformas com trajeto curvo/diagonal com easing, plataformas que caem, esteiras — Final.
- Plantas que **encolhem** ao perder a luz (ver ADR-F25-002).
- Plataforma que esmaga o jogador contra o teto (a colisão é one-way, ver ADR-F25-003).
- Mais de uma planta ou mais de uma plataforma por fase na Demo (o mapa da F29 usa uma de cada).

## 5. Critérios de aceite

- [x] Com `lift` **desligado**, a plataforma fica parada; com `lift` **ligado**, percorre o trajeto do JSON e volta, pausando `Balance.PLATFORM_WAIT` em cada ponta. — QA `f25_01`/`f25_03`/`f25_04`; `test_stops_at_point_and_waits`, `test_reverses_after_wait`
- [x] O MU-7 parado em cima sobe/desce junto, sem tremida e sem escorregar; pode andar e pular de cima dela normalmente. — QA `f25_03_subindo_com_jogador`, `f25_04_no_alto`, `f25_09_de_volta_ao_chao` (desce atravessando por baixo com `move_down`)
- [x] Desligar a energia no meio do trajeto **para** a plataforma na posição atual; religar continua do mesmo ponto, no mesmo sentido. — QA `f25_05_congelada_sem_energia` (ALTURA 77, meio do poço); `test_resumes_from_the_same_point_after_a_pause`
- [x] Ao carregar a fase com `lift` já ligado (estado salvo), a plataforma já nasce se movendo. — `EnergyNetwork.apply_all(silent)` chama `set_powered_silent(true)` no `_ready` da fase (contrato ADR-011); **verificado por caminho de código, não por captura**.
- [x] A plataforma é atravessável por baixo (one-way) e sólida por cima. — QA: subida por baixo no frame 95; `test_moving_platform_is_one_way_and_powered`
- [x] Com `grow_light` ligado, a planta cresce de broto a adulta em `Balance.PLANT_GROW_TIME` e o topo vira plataforma pisável de 32 px de largura. — QA `f25_06` (33%), `f25_07` (100%, TOPO SOLIDO), `f25_11_em_pe_na_planta`
- [x] Desligar `grow_light` **não** encolhe a planta; ela para no estágio em que está e retoma quando religar. — QA `f25_08_planta_continua_adulta`; `test_does_not_shrink`, `test_resumes_where_it_stopped`
- [x] Planta adulta + salvar na doca + Continuar → a planta continua adulta. — `GameState.flags["plant_<id>"]` entra no `to_dict`/`from_dict`; `test_grow_plant_comes_back_grown_from_the_save`
- [x] A luz de status da plataforma é verde quando energizada e vermelha quando não. — QA `f25_01` (vermelha) vs `f25_03` (verde)
- [x] `tests/test_path_follower.gd` e `tests/test_growth.gd` verdes.
- [x] Portões do `/CLAUDE.md` §6 verdes
- [x] Sem comentários no código; nada 3D

## 6. Definição técnica

### Cenas e scripts
```
scenes/world/moving_platform.tscn (+ moving_platform.gd)
  MovingPlatform (AnimatableBody2D)  sync_to_physics = true · collision_layer = 7 (one_way) · grupo "powered"
  ├─ CollisionShape2D                RectangleShape2D 48×8, one_way_collision = true
  ├─ Sprite2D                        SPR-PLATFORM (48×8)
  └─ StatusLight (PointLight2D)      texture FX-LIGHT, texture_scale 0.1, verde (#7ad17a) / vermelho (#d15a5a)
scenes/world/grow_plant.tscn (+ grow_plant.gd)
  GrowPlant (Node2D)                 grupo "powered"
  ├─ AnimatedSprite2D                SPR-PLANT 32×64 (seedling, growing 4f, grown), offset (0,-32)
  ├─ Top (StaticBody2D)              collision_layer = 7 (one_way)
  │   └─ CollisionShape2D            RectangleShape2D 32×4, position (0,-62), one_way_collision = true, disabled até adulta
  └─ GrowLight (PointLight2D)        rosa (#e58fb5), energy 0.0 → 1.0 conforme o sistema
scripts/core/path_follower.gd        class_name PathFollower (RefCounted, pura)
scripts/core/growth.gd               class_name Growth (RefCounted, pura)
```

> **Implementado assim** (ver ADRs locais 004–006): o trajeto **não** é um `@export PackedVector2Array` alimentado pelo `_apply_params` do `LevelBuilder` — o campo `path` do JSON da fase chega por `configure()` e vira `path_tiles` (`MovingPlatform.points_from`). A luz de status ganhou um `StatusLamp` (`Polygon2D` 4×4) além do `PointLight2D`, porque só a luz não lê em 384×216.

`scripts/core/path_follower.gd`:
```gdscript
class_name PathFollower
extends RefCounted

var points: PackedVector2Array
var speed: float
var wait_time: float

func _init(p_points: PackedVector2Array, p_speed: float, p_wait: float) -> void: ...
func step(from: Vector2, delta: float) -> Vector2: ...
func is_waiting() -> bool: ...
func progress_index() -> int: ...
```
- `step` devolve a próxima posição absoluta: anda em direção a `points[_target]` a `speed` px/s; ao chegar (distância ≤ `speed * delta`), fixa no ponto, entra em espera de `wait_time` e então inverte o sentido nas pontas (ping-pong). Enquanto espera, devolve a mesma posição.
- Sem energia, `moving_platform.gd` **não chama** `step` — a pausa é implícita e o estado interno se mantém.

`scripts/core/growth.gd`:
```gdscript
class_name Growth
extends RefCounted

static func step(progress: float, powered: bool, delta: float, grow_time: float) -> float: ...
    # powered ? clampf(progress + delta / grow_time, 0.0, 1.0) : progress
static func frame_for(progress: float, frames: int) -> int: ...
static func is_grown(progress: float) -> bool: ...   # progress >= 1.0
```

`moving_platform.gd`:
```gdscript
extends AnimatableBody2D

@export var terminal_id: StringName
@export var system_id: StringName
@export var path_tiles: PackedVector2Array = PackedVector2Array([Vector2.ZERO])
@export var speed: float = 0.0
@export var wait_time: float = 0.0
```
- `_ready()`: `add_to_group("powered")`; converte `path_tiles` (offsets em tiles, relativos ao tile de nascimento) em pontos absolutos multiplicando por `Balance.TILE_SIZE`; `speed`/`wait_time` caem para `Balance.PLATFORM_SPEED` / `Balance.PLATFORM_WAIT` quando ≤ 0; lê o estado inicial de energia **com o mesmo acessor que a porta da [F17](F17-terminal-distribuicao.md) usa** (`GameState.energy_states`); conecta `EventBus.energy_changed`.
- `_physics_process(delta)`: se não energizada, retorna; senão `global_position = _follower.step(global_position, delta)`.

`grow_plant.gd`: mesmo contrato `"powered"`; `_physics_process` chama `Growth.step`, atualiza o frame do `AnimatedSprite2D`, liga a colisão do `Top` e emite o SFX `plant_grow` uma vez quando `is_grown()` passa a ser verdadeiro; grava `GameState.flags["plant_" + plant_id] = true`; em `_ready`, se a flag existir, nasce adulta.

### Autoloads / sinais do EventBus
- **Escuta:** `energy_changed(terminal_id, system_id, powered)`.
- **Emite:** nada novo. `AudioManager.play_sfx("plant_grow")` ao completar o crescimento; `AudioManager.play_sfx("power_on")`/`("power_off")` ficam com a F17 (o terminal já sonoriza a troca).
- `GameState.flags["plant_gh_01"]` entra no save (F11).

### Dados (`data/`)
No JSON da fase ([F29](F29-fase-estufa.md)), por coordenada:
```json
{ "entities": {
  "34,38": {
    "id": "gh_lift_01",
    "terminal_id": "greenhouse",
    "system_id": "lift",
    "path": [[0, 0], [0, -10]],
    "speed": 32,
    "wait": 1.0
  },
  "18,27": {
    "id": "gh_plant_01",
    "terminal_id": "greenhouse",
    "system_id": "grow_light"
  }
} }
```
- `path`: lista de offsets **em tiles** `[dx, dy]` a partir do tile de nascimento (y negativo = subir). Dois pontos = vai-e-volta; três ou mais = ping-pong pelo trajeto. `speed` (px/s) e `wait` (s) são opcionais.
- `data/energy/greenhouse.json` declara `lift` e `grow_light` ([F17](F17-terminal-distribuicao.md)).

### Input actions / camadas de colisão
- Sem input novo.
- Plataforma e topo da planta: layer 7 `one_way` (o MU-7 já mascara 1 `world` + 7 `one_way` pela F12). A planta **não** é sólida no caule — o jogador passa por trás dela.

## 7. Assets necessários

| Asset id | Uso nesta feature | Placeholder |
|---|---|---|
| [SPR-PLATFORM](../ASSETS.md#spr-platform) | Plataforma móvel 48×8 | Barra cinza 48×8 |
| [SPR-PLANT](../ASSETS.md#spr-plant) | Planta 32×64, 6 frames (broto → adulta) | Retângulo verde que cresce de 8 para 64 px |
| [FX-LIGHT](../ASSETS.md#fx-light) | Luz de status da plataforma e luz de cultivo | Gradiente radial gerado |
| [SFX-PACK](../ASSETS.md#sfx-pack) | `plant_grow` | Som gerado |

## 8. 🧑 Ação humana

Nenhuma.

## 9. Plano de execução

- [x] **Passo 1** — `Balance.PLATFORM_SPEED` (40), `PLATFORM_WAIT` (0,6) e `PLANT_GROW_TIME` (2,0) já estavam no `Balance` (ver ADR-F25-005).
- [x] **Passo 2** — `tests/test_path_follower.gd` (9) + `scripts/core/path_follower.gd`.
- [x] **Passo 3** — `tests/test_growth.gd` (12) + `scripts/core/growth.gd`.
- [x] **Passo 4** — `moving_platform.tscn`/`.gd` com o contrato `"powered"` da porta da F17.
- [x] **Passo 5** — `grow_plant.tscn`/`.gd` + persistência por `GameState.flags`.
- [x] **Passo 6** — Legenda `m` e `g` já no `LevelBuilder`; o `path`/`speed`/`wait` do JSON entram por `configure()` (ADR-F25-004).
- [x] **Passo 7** — `tests/qa/scenes/platform_sandbox.tscn` + roteiro `tests/qa/f25_plataforma_planta.json`.
- [x] **Passo 8** — `tests/scenes.txt` atualizado; portões verdes. Commit fica com o humano/orquestrador.

## 10. Verificação

- **Testes (`tests/test_path_follower.gd`):**
  - `test_moves_toward_target`: trajeto `(0,0)→(0,-160)`, 32 px/s, `step` por 1 s → `y == -32`.
  - `test_stops_at_point_and_waits`: após 5 s chega em `(0,-160)`; mais 0,5 s (wait 1,0) → posição inalterada e `is_waiting() == true`.
  - `test_reverses_after_wait`: passado o wait, volta a descer.
  - `test_ping_pong_three_points`.
  - `test_no_overshoot`: `delta` grande não passa do ponto.
- **Testes (`tests/test_growth.gd`):**
  - `test_grows_only_when_powered`: `step(0.0, false, 1.0, 3.0) == 0.0`.
  - `test_reaches_one_after_grow_time`: 3 passos de 1 s com `grow_time = 3.0` → `1.0`.
  - `test_does_not_shrink`: despowered depois de 0,5 → mantém 0,5.
  - `test_frame_for_maps_progress` e `test_is_grown`.
- **Smoke:** `res://scenes/world/moving_platform.tscn` e `res://scenes/world/grow_plant.tscn` em `tests/scenes.txt`.
- **Roteiro godot-qa** (`tests/qa/f25_platform_plant.json`) — sala `tests/qa/levels/qa_platform.txt` com `P`, `T` (terminal `qa` com 2 sistemas e 1 energia: `lift` e `grow_light`), `m` num poço e `g` num canteiro:

  | Frame | Input / ação | Screenshot | Deve mostrar |
  |---|---|---|---|
  | 30 | — | `01_unpowered.png` | plataforma parada embaixo com luz **vermelha**; planta como broto |
  | 60 | `interact` no terminal; ligar `lift` | `02_terminal_lift.png` | UI do terminal com ELEVADOR ligado (1/1 energia) |
  | 120 | fechar UI | `03_moving.png` | plataforma subindo, luz **verde** |
  | 121–260 | `move_right` até embarcar, soltar | `04_riding.png` (f260) | MU-7 em pé na plataforma, acima do chão |
  | 400 | — | `05_top.png` | MU-7 no andar de cima |
  | 430 | `interact` no terminal; mover a energia para `grow_light` | `06_swap.png` | UI mostrando ELEVADOR desligado e LUZ DE CRESCIMENTO ligada |
  | 460 | fechar UI | `07_platform_frozen.png` | plataforma **parada** no meio do poço, luz vermelha |
  | 640 | — | `08_grown.png` | planta adulta; MU-7 pode pisar no topo |
  | 700 | `move_right` + `jump` | `09_standing_on_plant.png` | MU-7 em pé sobre a folhagem |
- **Playtest humano (opcional):** esperar o elevador irrita? (`PLATFORM_SPEED`/`PLATFORM_WAIT` são o botão de ajuste.)

## 11. ADRs locais

### ADR-F25-001 — Números de plataforma e planta
- **Contexto:** o GDD descreve os dois elementos, mas não dá velocidade nem tempo de crescimento.
- **Decisão:** `Balance.PLATFORM_SPEED = 32` (px/s = 2 tiles/s; a subida de 10 tiles da Estufa leva 5 s), `Balance.PLATFORM_WAIT = 1.0` (s nas pontas), `Balance.PLANT_GROW_TIME = 3.0` (s). **Entradas propostas no [GDD-P](../design/GDD.md#gdd-p)** (origem 2.7-F1) + linha em [Ajustes](../design/GDD.md#gdd-ajustes).
- **Consequências:** o ritmo de espera fica ajustável num lugar só.
- **Data:** 2026-09-19

### ADR-F25-002 — A planta não encolhe quando a luz apaga
- **Contexto:** o puzzle troca energia entre LUZ DE CRESCIMENTO e LUZES DO CORREDOR; se a planta encolhesse, o jogador ficaria preso no andar de cima ao reconfigurar (softlock) e a troca viraria punição.
- **Decisão:** o crescimento é **monotônico**: para quando falta luz, retoma quando volta, nunca regride. Quando adulta, registra `GameState.flags["plant_<id>"] = true`.
- **Consequências:** a planta é "progresso permanente" dentro do setor, como uma porta que ficou aberta; sem softlock e sem save corrompido.
- **Data:** 2026-09-19

### ADR-F25-003 — Plataforma e topo de planta são colisão one-way
- **Contexto:** plataformas sólidas em movimento podem esmagar o `CharacterBody2D` contra o teto e exigem tratamento de "crush" que não cabe em 3 dias.
- **Decisão:** as duas usam `one_way_collision` na camada 7 `one_way`. Sobe-se por cima; por baixo, atravessa.
- **Consequências:** zero risco de esmagamento e de travar a física; perde-se o efeito de "plataforma que empurra", que não é usado na Demo.
- **Data:** 2026-09-19

### ADR-F25-004 — O trajeto entra por `configure()`, não por `@export`
- **Contexto:** o `LevelBuilder._apply_params` só faz `instance.set(nome, valor)` para propriedades de script, e `_coerce` não converte `Array[[dx,dy]]` do JSON em `PackedVector2Array` — um `@export var path_tiles: PackedVector2Array` receberia um `Array` e quebraria.
- **Decisão:** `path_tiles` é variável comum (não exportada) e o campo `path` do JSON é lido em `configure(params)`, que o `LevelBuilder` já chama depois de aplicar os parâmetros. `MovingPlatform.points_from()` faz a conversão e é `static`, testável sem cena.
- **Consequências:** o contrato de dados da seção 6 vale como está (`path`, `speed`, `wait`); nenhum `@export` frágil. `speed`/`wait` continuam `@export` porque são floats simples.
- **Data:** 2026-09-19

### ADR-F25-005 — Cores de status ficam no script, não no `Balance`
- **Contexto:** a regra dura 6 manda todo número de **gameplay** para o `Balance`, espelhando o GDD-P, e esta execução não pode editar `docs/design/`. As cores verde/vermelho da luz de status e o rosa da luz de cultivo não são números de gameplay e não existem no GDD-P.
- **Decisão:** ficam como `const` de apresentação no próprio script (`MovingPlatform.COLOR_ON`/`COLOR_OFF`, `GrowPlant.LIGHT_COLOR`), como já faziam `Door.OPEN_FPS` e `Mu7.BLINK_INTERVAL`. Nenhum número de gameplay novo foi inventado: `PLATFORM_SPEED`, `PLATFORM_WAIT` e `PLANT_GROW_TIME` já estavam no `Balance`.
- **Consequências:** se a arte definitiva mudar a paleta, muda numa linha por cena; o `Balance` continua espelho 1:1 do GDD-P.
- **Data:** 2026-09-19

### ADR-F25-006 — Crescimento monotônico à prova de ponto flutuante
- **Contexto:** somando `delta / PLANT_GROW_TIME` frame a frame, 120 passos de 1/60 s dão `0.9999999999999999`, não `1.0`. Com o corte por `is_equal_approx` que havia no `_physics_process`, a planta **travava** a um passo do fim: chegava ao último frame da arte mas o topo nunca virava plataforma (visto no QA: "PLANTA 100% TOPO BROTO").
- **Decisão:** `Growth.step()` grava exatamente `COMPLETE` quando o próximo valor alcança ou é `is_equal_approx` de 1,0; `Growth.is_grown()` também aceita o `is_equal_approx`; e o `grow_plant.gd` corta por `next <= _progress` (que já garante a monotonicidade do ADR-F25-002) em vez de por aproximação.
- **Consequências:** dois testes de regressão (`test_accumulated_frames_reach_the_grown_state`, `test_almost_one_is_grown`) travam o comportamento. Lição para qualquer acumulador de progresso do projeto.
- **Data:** 2026-09-19

## 12. Log de evolução

### 2026-09-19 — Implementada
- **Quem**: agente de implementação · **O que**: `scripts/core/path_follower.gd` e `scripts/core/growth.gd` (lógica pura), `scenes/world/moving_platform.{tscn,gd}` (`AnimatableBody2D` `sync_to_physics`, one-way na camada 7, luz + lâmpada de status) e `scenes/world/grow_plant.{tscn,gd}` (6 frames da SPR-PLANT, topo one-way ligado só quando adulta, flag em `GameState.flags`). 9 testes de trajeto, 12 de crescimento e 10 de cena em `tests/test_world_scenes.gd`.
- **Portões**: import sem erro · **488 passed, 0 failed** · smoke 60 cenas OK · varreduras de comentário e de 3D vazias.
- **QA visual** (`tests/qa/f25_plataforma_planta.json` + `tests/qa/scenes/platform_sandbox.tscn`, `--fixed-fps 60 --qa-screen=1`): `01_sem_energia` plataforma parada embaixo com lâmpada **vermelha** e planta como broto; `02_em_cima_parada` MU-7 em pé na plataforma ainda parada; `03_subindo_com_jogador` ALTURA 33, lâmpada **verde**, MU-7 sendo carregado; `04_no_alto` ALTURA 104 com o MU-7 em cima; `05_congelada_sem_energia` ALTURA 77 — parada **no meio do poço** ao cortar a energia, lâmpada vermelha; `06_planta_crescendo` 33% com a luz rosa; `07_planta_adulta` 100% "TOPO SOLIDO"; `08_planta_continua_adulta` luz **desligada** e planta ainda 100%/sólida; `09_de_volta_ao_chao` MU-7 desceu pela plataforma com `move_down`; `10_no_degrau` (252,146); `11_em_pe_na_planta` MU-7 em (308,112), **de pé na folhagem, com a luz de crescimento desligada**.
- **Correções durante o QA**: travamento do crescimento por ponto flutuante (ADR-F25-006) e `const` de trajeto que não podia ser expressão constante na sala de QA.
- **Próximo passo**: F29 posiciona `m` e `g` no mapa da Estufa com os ids do `data/energy/greenhouse.json` (`gh_lift`, `gh_plant_1`).

### 2026-09-19 — Feature criada
- **Quem**: agente de planejamento · **O que**: documento inicial a partir do GDD-2.7-F1 · **Próximo passo**: implementação.
