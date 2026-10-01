---
id: F22
title: Inimigo SR-3 "Aranha de Reparo"
status: done
scope: demo
block: 3
priority: P0
rubric: []
depends_on: ["F02", "F12", "F13", "F21"]
unblocks: ["F28", "F29", "F31"]
estimate: 1.5h
last_updated: 2026-09-19
---

# F22 — Inimigo SR-3 "Aranha de Reparo"

## 1. Contexto e objetivo

A SR-3 é o primeiro inimigo do jogo e o único da Demo. É uma aranha de reparo de seis pernas que **patrulha uma plataforma em linha reta e vira ao chegar na borda ou numa parede**. Ela não persegue e não ataca de propósito: só machuca por contato (10 de Integridade + knockback). Ensina *timing* de pulo e que encostar custa caro.

Serve aos pilares **AUSÊNCIA** (é uma máquina cumprindo uma ordem de 200 anos atrás, não um monstro) e **ESCASSEZ** (cada contato custa Integridade, e morrer custa Estabilidade do Reator). Aparece pela primeira vez no corredor do Setor Habitacional do Núcleo Central (Jornada, etapa 4 — "os sistemas de segurança passam a tratar o MU-7 como intruso") e depois duas vezes na Estufa.

Atende o requisito do 2º bimestre "Inimigos" ([GDD-2.10](../design/GDD.md#gdd-2-10)); não é um item isolado da rubrica, mas é pré-requisito do Combate (não-letal) da [F31](F31-dash-feixe.md).

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.6.2-A — SR-3 "Aranha de Reparo"](../design/GDD.md#gdd-2-6-2-a) · [GDD-2.6.2 — Inimigos (nenhum é destruído, só DESLIGADO)](../design/GDD.md#gdd-2-6-2) · [GDD-2.9 SFX (desligar = "gemido" descendente)](../design/GDD.md#gdd-2-9-sfx)
- **Parâmetros:** `Balance.SR3_CONTACT_DAMAGE` (10), `Balance.GRAVITY`, `Balance.BEAM_SHUTDOWN_TIME` (usado pela F31) — [GDD-P](../design/GDD.md#gdd-p). **Novos (ver ADR-F22-001):** `Balance.SR3_SPEED`, `Balance.SR3_KNOCKBACK_X`, `Balance.SR3_KNOCKBACK_Y`.
- **Multiplicador de dificuldade:** aplicado só em `GameState.apply_damage` ([GDD-P dificuldade](../design/GDD.md#gdd-p-dificuldade)) — a SR-3 **nunca** multiplica dano.
- **Jornada:** [Etapa 4 — Travessia do Limiar](../design/JORNADA-DO-HEROI.md#jh-4) (primeira SR-3) · [Etapa 5 — Testes e Aliados](../design/JORNADA-DO-HEROI.md#jh-5)
- **ADRs:** [ADR-000](../DECISIONS.md#adr-000) · [ADR-004](../DECISIONS.md#adr-004) · [ADR-005](../DECISIONS.md#adr-005) · [ADR-007](../DECISIONS.md#adr-007)

## 3. Critério de avaliação atendido

Nenhum item isolado da [rubrica](../ENTREGAS.md#rubrica); cumpre o requisito de bimestre "Inimigos". Na apresentação ([roteiro §4](../ENTREGAS.md#apresentacao)) o avaliador vê, no corredor Habitacional e na Estufa, a SR-3 com sua luz âmbar andando no escuro, virando na borda, e o MU-7 levando dano e sendo empurrado ao encostar nela (a barra de Integridade cai uma fração de célula). Com a [F31](F31-dash-feixe.md) pronta, o Feixe a desliga por 4 s (Combate não-letal).

## 4. Escopo

### Inclui
- Cena `scenes/enemies/sr3.tscn` + `sr3.gd`: patrulha horizontal com gravidade, vira na borda da plataforma e em parede.
- Dano por contato (`Balance.SR3_CONTACT_DAMAGE`) com knockback para longe da SR-3, respeitando as i-frames do MU-7 definidas na [F13](F13-integridade-carga-respawn.md).
- API pública `shutdown(duration: float)` / `is_shut_down() -> bool` (a F31 usa; nesta feature é testada pela QA com chamada direta).
- Estado desligado: animação `shutdown` → `off`, luz apagada, hitbox desativada, SFX `sr3_shutdown`; volta a patrulhar ao fim do tempo.
- Luz âmbar de aviso (`PointLight2D` pequeno) — "onde tem luz, tem energia" ([GDD-2.9](../design/GDD.md#gdd-2-9-visual)).
- Lógica pura `scripts/core/sr3_logic.gd` (decisão de virar e vetor de knockback) com testes.
- Parâmetro por coordenada no JSON da fase: direção inicial (`dir`).
- Registro do caractere `S` na legenda do `LevelBuilder` (se a [F21](F21-construtor-fases-ascii.md) ainda não apontou para esta cena).

### Não inclui
- Desligar a SR-3 pela raiz num Terminal de Distribuição (nenhum sistema da Demo alimenta SR-3) — Final.
- Feixe de Manutenção (input `beam`) — [F31](F31-dash-feixe.md) (stretch).
- SR-3s soltas pelo Serralheiro (F43) — Final.
- Perseguição, ataque ativo ou morte permanente da SR-3 (contra o GDD).

## 5. Critérios de aceite

- [x] Uma SR-3 colocada com `S` numa plataforma anda a `Balance.SR3_SPEED` px/s e **vira** sem cair ao chegar na borda; também vira ao encostar numa parede.
- [x] Encostar no MU-7 chama o dano da F13 com `Balance.SR3_CONTACT_DAMAGE` (10 no Normal, 5 no Fácil, 15 no Difícil — multiplicador aplicado só no `GameState`) e emite `EventBus.player_damaged` / `integrity_changed` (via F13).
- [x] O MU-7 é empurrado para longe da SR-3 — o empurrão é o da F13 (`Balance.KNOCKBACK_SPEED` nos dois eixos, trava `Balance.SR3_KNOCKBACK_LOCK`), ver [ADR-F22-003](#adr-f22-003).
- [x] Ficar parado encostado não causa dano a cada frame: o próximo dano só ocorre depois das i-frames da F13.
- [x] `shutdown(4.0)` para a SR-3, troca para animação `off`, apaga a luz, desativa a hitbox (atravessável sem dano) e, após 4 s, ela volta a patrulhar na mesma direção.
- [x] A SR-3 atravessa o MU-7 fisicamente (não o empurra por colisão de corpo); só a hitbox interage.
- [x] `tests/test_sr3_logic.gd` verde (12 casos) + `tests/test_enemy_scenes.gd` (contrato da cena).
- [x] Portões do `/CLAUDE.md` §6 verdes — 399 testes, 48 cenas no smoke.
- [x] Sem comentários no código; nada 3D

## 6. Definição técnica

### Cenas e scripts
```
scenes/enemies/sr3.tscn (+ sr3.gd)
  Sr3 (CharacterBody2D)            collision_layer = 3 (enemy) · collision_mask = 1 (world)
  ├─ AnimatedSprite2D              SpriteFrames: walk (4f), shutdown (3f), off (1f) — frames 32×16, offset (0,-8)
  ├─ CollisionShape2D              RectangleShape2D 24×10, position (0,-5)
  ├─ Hitbox (Area2D)               collision_layer = 3 (enemy) · collision_mask = 2 (player) · monitoring = true
  │   └─ CollisionShape2D          RectangleShape2D 26×12, position (0,-6)
  ├─ FloorProbe (RayCast2D)        position (±12, -2), target_position (0, 10), mask = 1 (world)
  ├─ WallProbe (RayCast2D)         position (0,-5), target_position (±14, 0), mask = 1
  ├─ WarningLight (PointLight2D)   texture FX-LIGHT (light_radial.png), texture_scale 0.15, color âmbar #ffb347, energy 0.8
  └─ SfxPlayer (AudioStreamPlayer2D)  (opcional; one-shots vão pelo AudioManager)
scripts/core/sr3_logic.gd          class_name Sr3Logic (RefCounted, só funções static)
```

`sr3.gd` (ordem do `/CLAUDE.md` §5):
```gdscript
class_name Sr3
extends CharacterBody2D

signal shut_down(duration: float)
signal woke_up()

@export var dir: int = 1

var _shutdown_left: float = 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var floor_probe: RayCast2D = $FloorProbe
@onready var wall_probe: RayCast2D = $WallProbe
@onready var warning_light: PointLight2D = $WarningLight

func _ready() -> void: ...            # add_to_group("beam_target"); aplica dir às probes e ao flip_h
func _physics_process(delta: float) -> void: ...
func shutdown(duration: float) -> void: ...
func is_shut_down() -> bool: ...
func _turn() -> void: ...
func _hit_player(body: Node2D) -> void: ...
```

Regras do `_physics_process`:
1. Gravidade: `velocity.y += Balance.GRAVITY * delta`.
2. Desligada: `_shutdown_left -= delta`; `velocity.x = 0`; ao chegar a 0 → `sprite.play("walk")`, `warning_light.enabled = true`, `hitbox.set_deferred("monitoring", true)`, `woke_up.emit()`.
3. Ligada: se `is_on_floor()` e `Sr3Logic.should_turn(floor_probe.is_colliding(), wall_probe.is_colliding())` → `_turn()` (inverte `dir`, espelha `floor_probe.position.x`, `wall_probe.target_position.x` e `sprite.flip_h`). `velocity.x = dir * Balance.SR3_SPEED`.
4. `move_and_slide()`.
5. Ligada: para cada corpo em `hitbox.get_overlapping_bodies()` que esteja no grupo `"player"` → `_hit_player(body)`.

`_hit_player`: usa a API de dano do MU-7 definida pela [F13](F13-integridade-carga-respawn.md) (ela aplica i-frames e chama `GameState.apply_damage`). O knockback é `Sr3Logic.knockback(global_position.x, body.global_position.x, Balance.SR3_KNOCKBACK_X, Balance.SR3_KNOCKBACK_Y)`. Se a F13 expôs apenas `GameState.apply_damage(amount)` sem knockback, esta feature adiciona ao `scenes/player/mu7.gd` o método `apply_knockback(impulse: Vector2) -> void` (seta `velocity = impulse` e bloqueia o input horizontal por `Balance.SR3_KNOCKBACK_LOCK`, ver ADR-F22-001) e só chama o dano se o MU-7 não estiver em i-frames.

`scripts/core/sr3_logic.gd`:
```gdscript
class_name Sr3Logic
extends RefCounted

static func should_turn(floor_ahead: bool, wall_ahead: bool) -> bool: ...   # not floor_ahead or wall_ahead
static func knockback(enemy_x: float, player_x: float, strength_x: float, strength_y: float) -> Vector2: ...
                                                                            # x = sign(player_x - enemy_x) * strength_x (sign 0 → +1); y = -strength_y
```

### Autoloads / sinais do EventBus
- Emite indiretamente (via F13/`GameState.apply_damage`): `player_damaged(amount)`, `integrity_changed(current, maximum)`.
- `AudioManager.play_sfx("sr3_shutdown")` ao desligar; `AudioManager.play_sfx("damage")` fica com a F13 (dano).
- Grupos: a SR-3 entra em `"beam_target"` (a F31 procura esse grupo). O MU-7 deve estar no grupo `"player"` (F12).

### Dados (`data/`)
Parâmetro opcional por coordenada no JSON da fase ([F21](F21-construtor-fases-ascii.md), [ADR-004](../DECISIONS.md#adr-004)):
```json
{ "entities": { "42,10": { "dir": -1 } } }
```
`dir` ∈ {-1, 1}; padrão 1 (direita). O `LevelBuilder` atribui as chaves do objeto às propriedades `@export` de mesmo nome.

### Input actions / camadas de colisão
- Sem input.
- Corpo: layer 3 `enemy`, mask 1 `world` (não colide com o player). Hitbox: layer 3, mask 2 `player`. Probes: mask 1 `world` nas duas — a sonda de chão enxerga exatamente o que o corpo pisa, então a SR-3 vira na borda de uma plataforma fina em vez de andar para cima dela e cair ([log de 2026-09-20](#2026-09-20--a-aranha-parada-que-caía-da-borda)).

## 7. Assets necessários

| Asset id | Uso nesta feature | Placeholder |
|---|---|---|
| [SPR-SR3](../ASSETS.md#spr-sr3) | Sprite sheet 32×16: `walk` 4f · `shutdown` 3f · `off` 1f | Oval laranja 24×12 com 6 "pernas" (`tools/make_placeholders.gd`) |
| [FX-LIGHT](../ASSETS.md#fx-light) | Luz âmbar de aviso | Gradiente radial gerado |
| [SFX-PACK](../ASSETS.md#sfx-pack) | `sr3_shutdown` | Beep descendente gerado |

## 8. 🧑 Ação humana

Nenhuma.

## 9. Plano de execução

- [x] **Passo 1** — Constantes já presentes em `Balance` (`SR3_SPEED`, `SR3_KNOCKBACK_X/Y/LOCK`) — nenhum número novo foi inventado.
- [x] **Passo 2** — `tests/test_sr3_logic.gd` + `scripts/core/sr3_logic.gd`.
- [x] **Passo 3** — Placeholder `SPR-SR3` já gerado em `assets/placeholder/sprites/enemies/sr3_sheet.png` (128×48).
- [x] **Passo 4** — `scenes/enemies/sr3.tscn` escrita à mão + `sr3.gd`.
- [x] **Passo 5** — Dano/knockback pela `DamageArea` da F13; `mu7.gd` não foi tocado ([ADR-F22-003](#adr-f22-003)).
- [x] **Passo 6** — `S` → `res://scenes/enemies/sr3.tscn` já na legenda do `LevelBuilder` (F21), coberto por teste.
- [x] **Passo 7** — Sala de QA `tests/qa/scenes/enemy_sandbox.tscn` + roteiro `tests/qa/f22_sr3.json`; 7 PNGs lidos pelo agente ([ADR-F22-004](#adr-f22-004)).
- [x] **Passo 8** — Cenas em `tests/scenes.txt`; portões verdes. Commit fica com o humano.

## 10. Verificação

- **Testes (`tests/test_sr3_logic.gd`):**
  - `test_turns_at_ledge`: `should_turn(false, false) == true`.
  - `test_turns_at_wall`: `should_turn(true, true) == true`.
  - `test_keeps_walking`: `should_turn(true, false) == false`.
  - `test_knockback_pushes_away_right`: `knockback(100, 120, 160, 120) == Vector2(160, -120)`.
  - `test_knockback_pushes_away_left`: `knockback(100, 80, 160, 120) == Vector2(-160, -120)`.
  - `test_knockback_same_x_defaults_right`: `knockback(100, 100, 160, 120).x > 0`.
- **Smoke:** `res://scenes/enemies/sr3.tscn` em `tests/scenes.txt`.
- **Roteiro godot-qa** (`tests/qa/f22_sr3.json`, formato da [F06](F06-testes-portoes-qa.md)); sala `tests/qa/levels/qa_sr3.txt` carregada pelo mecanismo de fase da F21:
  ```
  ########################
  #                      #
  #                      #
  #                      #
  #                      #
  #                      #
  #                      #
  #  P       S           #
  #####      #######   ###
  ########################
  ```
  (a SR-3 anda na plataforma do meio, cols 11–17, e vira nas duas bordas; `CanvasModulate` claro nesta sala para leitura.)

  | Frame | Input / ação | Screenshot | Deve mostrar |
  |---|---|---|---|
  | 0 | — | — | cena carregada |
  | 30 | — | `01_patrol_start.png` | SR-3 sobre a plataforma do meio, luz âmbar acesa |
  | 150 | — | `02_turned.png` | SR-3 espelhada (virou na borda), ainda sobre a plataforma, sem ter caído |
  | 151–260 | segurar `move_right` | — | MU-7 anda até a SR-3 |
  | 262 | — | `03_hit.png` | MU-7 deslocado para longe da SR-3 (knockback), HUD com Integridade 90/100 (célula parcial) |
  | 263 | soltar `move_right`; QA chama `shutdown(4.0)` na SR-3 (comando `call` do roteiro F06) | — | — |
  | 280 | — | `04_off.png` | SR-3 dobrada (frame `off`), luz apagada |
  | 290–330 | segurar `move_right` | `05_pass_through.png` (f330) | MU-7 sobre/atravessando a SR-3 desligada sem novo dano |
  | 540 | — | `06_awake.png` | SR-3 voltou a andar, luz acesa |
- **Playtest humano (opcional):** no corredor Habitacional, pular a SR-3 três vezes — o pulo por cima deve parecer justo (não "raspar" a hitbox).

## 11. ADRs locais

### ADR-F22-001 — Números que faltam no GDD-P para a SR-3
- **Contexto:** o GDD dá dano (10) e comportamento, mas não velocidade nem força do knockback.
- **Decisão:** novas constantes em `Balance` — `SR3_SPEED = 30` (px/s; bem mais lenta que o MU-7 a 110 para ser pulável), `SR3_KNOCKBACK_X = 160` (px/s), `SR3_KNOCKBACK_Y = 120` (px/s), `SR3_KNOCKBACK_LOCK = 0.2` (s sem controle horizontal após o empurrão). **Entrada proposta no GDD-P** (origem 2.6.2-A) e linha em Ajustes: "AJ-xxx · 2.6.2-A · velocidade e knockback da SR-3 definidos (30 px/s; 160/120 px/s; 0,2 s) · GDD não especificava".
- **Consequências:** tuning centralizado; se o playtest achar a SR-3 fácil demais, sobe `SR3_SPEED` no GDD e no `Balance`.
- **Data:** 2026-09-19

### ADR-F22-002 — Dano pela hitbox, corpo não colide com o player
- **Contexto:** se o corpo da SR-3 colidir com o MU-7, o jogador pode ficar "em cima" dela ou empurrá-la, e o dano por contato fica ambíguo.
- **Decisão:** `CharacterBody2D` só com mask `world`; contato é uma `Area2D` checada por `get_overlapping_bodies()` a cada frame físico (sem depender de `body_entered`, que não repete). I-frames ficam na F13.
- **Consequências:** o jogador nunca "pisa" na SR-3; pular por cima é a única forma de passar sem dano (fiel ao GDD).
- **Data:** 2026-09-19

<a id="adr-f22-003"></a>
### ADR-F22-003 — O empurrão continua sendo o da F13; a SR-3 só marca o dano
- **Contexto:** a F13 já entrega `scenes/world/damage_area.gd` e o `mu7.gd` já trata contato, i-frames, animação de dano e knockback (`Balance.KNOCKBACK_SPEED` + trava `Balance.SR3_KNOCKBACK_LOCK`) lendo as `DamageArea` sobrepostas à Hurtbox. Reimplementar o empurrão dentro da SR-3 aplicaria o impulso duas vezes, e o `mu7.gd` está fora do escopo desta feature.
- **Decisão:** a `Hitbox` da SR-3 é uma `DamageArea` (layer `enemy`) com `contact_damage = Balance.SR3_CONTACT_DAMAGE` e `knockback = true`; quem empurra é o MU-7, para longe da posição da hitbox. `Sr3Logic` não tem função de knockback — seria código morto.
- **Consequências:** `Balance.SR3_KNOCKBACK_X` e `SR3_KNOCKBACK_Y` ficam **sem uso** (o empurrão usa `KNOCKBACK_SPEED`, 140 px/s nos dois eixos). Se o playtest quiser um empurrão específico da SR-3, a mudança é uma linha em `mu7.gd` lendo as duas constantes — trabalho da F31/F13.
- **Data:** 2026-09-19

<a id="adr-f22-004"></a>
### ADR-F22-004 — A prova de QA roda num sandbox, não numa sala ASCII
- **Contexto:** o roteiro do `QACapture` (F06) só entende `frame`, `action`, `scene`, `screenshot` e `quit` — não existe comando `call`, então não há como o roteiro chamar `shutdown(4.0)`.
- **Decisão:** a prova visual roda em `tests/qa/scenes/enemy_sandbox.tscn` (herda `SandboxRoom`), que monta a sala, o HUD e um rótulo de telemetria e dispara `shutdown()` no seu próprio *timeline* de frames. A patrulha por `S` no ASCII fica coberta pelo teste da legenda e pela F28/F29.
- **Consequências:** o QA é determinístico e sem sala ASCII dedicada; se o `QACapture` ganhar um comando `call`, o sandbox pode virar sala de fase.
- **Data:** 2026-09-19

<a id="adr-f22-005"></a>
### ADR-F22-005 — `SR3_SPEED` é 40, não 30
- **Contexto:** o ADR-F22-001 propôs `SR3_SPEED = 30`, mas `scripts/core/balance.gd` (espelho do GDD-P, que manda pela regra dura 6) já traz `SR3_SPEED = 40.0`, `SR3_KNOCKBACK_X = 120`, `SR3_KNOCKBACK_Y = 120`, `SR3_KNOCKBACK_LOCK = 0.15`.
- **Decisão:** a implementação usa o `Balance` como está; nenhum número foi editado nesta feature (o GDD é versionado e não se toca sem pedido).
- **Consequências:** o texto do ADR-F22-001 está desatualizado em relação ao `Balance`; quem revisar o GDD-P decide qual valor fica.
- **Data:** 2026-09-19

## 12. Log de evolução

### 2026-09-19 — Feature criada
- **Quem**: agente de planejamento · **O que**: documento inicial a partir do GDD-2.6.2-A e da Jornada etapa 4 · **Próximo passo**: implementação.

### 2026-09-19 — Implementada
- **Quem**: agente de implementação · **O que**: `scripts/core/sr3_logic.gd` (lógica pura de virada, direção, contagem do desligamento e animação), `scenes/enemies/sr3.tscn` + `sr3.gd` (patrulha com sondas de borda e parede, luz âmbar, `DamageArea` de contato, `shutdown()`/`is_shut_down()` e grupo `beam_target` para a F31), `tests/test_sr3_logic.gd` e `tests/test_enemy_scenes.gd`, sandbox de QA `tests/qa/scenes/enemy_sandbox.tscn` + roteiro `tests/qa/f22_sr3.json`, cenas registradas em `tests/scenes.txt`. ADRs F22-003/004/005.
- **Portões**: import limpo · 399 testes, 0 falhas · 48 cenas no smoke, 0 erros · varreduras 3D e de comentários vazias.
- **QA lido**: patrulha com luz âmbar; virada na parede (x 129, dir 1) e na borda (x 299, dir −1) sem cair; contato → Integridade 90/100 e MU-7 empurrado de 240 para 270; `shutdown(4 s)` → parada, luz apagada, sem dano, atravessável (MU-7 passou de 271 a 163 com 90/100); volta a patrulhar sozinha.
- **Próximo passo**: F31 (Feixe) usa `shutdown(Balance.BEAM_SHUTDOWN_TIME)` no grupo `beam_target`; F28/F29 colocam `S` nas fases.

### 2026-09-20 — A aranha parada que caía da borda
- **Quem**: agente A · **Sintoma relatado**: "o sheet da aranha tá zoado, ela não se mexe, não tem animação".
- **Diagnóstico**: a folha `sr3_sheet.png` está correta (128×48, 4×3 quadros de 32×16, walk com 4 poses distintas). Eram **dois defeitos independentes**, medidos com a sonda `tests/qa/scenes/sr3_probe.tscn`, que escreve na tela `TILE`, `DIR`, animação, quadro e se está tocando de **cada** SR-3 da fase:
  1. **A caminhada nunca começava.** Atribuir `sprite_frames` faz o `AnimatedSprite2D` **escolher** a primeira animação (`animation = "walk"`) sem **tocar** nada. O `_play()` da SR-3 saía cedo em `if _sprite.animation == anim`, concluía "já estou em walk" e nunca chamava `play()`. Leitura de tela antes do conserto: `walk Q0 TOCA NAO` em todas as capturas, com o quadro travado em 0 enquanto o bicho deslizava pelo chão. O MU-7 já tinha o guarda certo (`… and _sprite.is_playing()`), por isso só a SR-3 aparecia congelada.
  2. **A SR-3 do andar do meio caía da fase.** A `FloorProbe` tinha `mask = 1 | 7`, então enxergava a passarela fina (`=`) como chão, mas o corpo tem `mask = 1` e atravessa plataforma fina. A `gh_sr3_02` saía do parapeito (tile 36,41), pisava no vão e despencava até o corredor de baixo (tile 33,51 em 1 s), sumindo da rota desenhada.
- **Conserto**: `Sr3Logic.should_restart_animation(current, target, playing, loops)` (lógica pura: troca de animação sempre toca; mesma animação só reinicia se ela laça e parou — assim a dobra de 3 quadros não pisca ao terminar) usada pelo `_play()` da `sr3.gd`; `FloorProbe.collision_mask = 1` em `sr3.tscn`. Nada foi mexido em `greenhouse.txt`/`.json` — a colocação estava certa, a sonda é que mentia.
- **Testes de regressão**: `test_enemy_scenes.gd::test_sr3_walks_its_animation_as_soon_as_it_enters_the_scene` (instancia a cena na árvore e exige `walk` **tocando**) e `::test_sr3_probes_see_the_floor_and_the_walls` (agora casa a máscara da sonda com a do corpo e proíbe o bit `one_way`); quatro casos de `should_restart_animation` em `test_sr3_logic.gd`; `test_sprite_sheet.gd::test_assigning_frames_selects_an_animation_without_playing_it` fixa o comportamento da engine que causou o bug. Os dois primeiros falham no código antigo (`5 passed, 2 failed`) e passam no novo.
- **Portões**: import limpo · **647 testes, 0 falhas** · smoke com 75 cenas, 0 erros · varreduras 3D e de comentários vazias.
- **QA lido**: `tests/qa/f22_sr3_animacao.json` no sandbox — andar (`walk Q1→Q2`, pernas em poses diferentes entre capturas de 6 quadros), dobrar (`shutdown`), desligada (`off`, achatada no chão, luz apagada) e voltar a andar. `tests/qa/f22_sr3_estufa.json` na Estufa real — as três SR-3 com `TOCA SIM` e quadro avançando; a `gh_sr3_02` agora patrulha o parapeito (36 → 42 → volta) sem cair. Travessia completa `tests/qa/f29_greenhouse.json` refeita: 44 capturas, zero erro, integridade cheia ao ler o protocolo das garras e tela **FIM DA DEMO** com `TEMPO 01:30 · MORTES 0`.
- **Próximo passo**: nenhum.
