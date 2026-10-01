---
id: F13
title: Integridade, Carga, dano & respawn
status: done
scope: demo
block: 2
priority: P0
rubric: ["Life skills (vida/energia)", "Recompensas"]
depends_on: ["F02", "F10", "F11", "F12"]
unblocks: ["F14", "F15", "F18", "F20", "F22", "F23", "F32"]
estimate: 2.5h
last_updated: 2026-09-19
---

# F13 — Integridade, Carga, dano & respawn

## 1. Contexto e objetivo

O MU-7 tem dois recursos: **Integridade** (vida do chassi, 100 pts em 4 células) e **Carga** (energia/stamina, 100 pts, gasta pela lanterna e habilidades). A Carga **não regenera andando** — só parado numa **doca de recarga** (Ponto de Backup) ou com itens. Isso cria o loop micro do GDD: *gastar carga → ficar sem → procurar tomada*.

Esta feature entrega o modelo de dano (contato com knockback e invencibilidade curta; dano contínuo por segundo), a morte do chassi e o **respawn na doca** com 50% de Integridade e **−3% de Estabilidade do Reator** — morrer custa tempo do mundo. Também aplica o **multiplicador de dificuldade** de dano num único lugar (`GameState.apply_damage`).

Serve ao pilar **ESCASSEZ** (recursos finitos, recarga só em pontos fixos) e à fragilidade narrativa do MU-7: um corpo de serviço, não de combate — encostar custa caro.

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.6.1 Status base](../design/GDD.md#gdd-2-6-1-status) (Integridade 100/4 células, Carga 100, regen 5/s parado na doca, sem reparo passivo) · [GDD-2.5 Derrota](../design/GDD.md#gdd-2-5-derrota) (condição 1: reaparece no Ponto de Backup com 50% e −3% de estabilidade) · [GDD-2.3 Loop micro](../design/GDD.md#gdd-2-3-micro) · [GDD-2.6.2-E Obstáculos](../design/GDD.md#gdd-2-6-2-e) ("Escuridão total — mata por queda") · [GDD-2.6.2-F Status](../design/GDD.md#gdd-2-6-2-f) (CORROSÃO impede recarga)
- **Parâmetros:** `Balance.INTEGRITY_MAX`, `Balance.INTEGRITY_CELLS`, `Balance.CHARGE_MAX`, `Balance.CHARGE_DOCK_REGEN`, `Balance.RESPAWN_INTEGRITY_RATIO`, `Balance.REACTOR_DEATH_PENALTY` (aplicado pela F14) — [GDD-P](../design/GDD.md#gdd-p) · multiplicadores em [GDD-P Dificuldade](../design/GDD.md#gdd-p-dificuldade). Novos (ADR-F13-001): `KNOCKBACK_X`, `KNOCKBACK_Y`, `KNOCKBACK_TIME`, `INVINCIBILITY_TIME`, `DEATH_DELAY`, `DOCK_REPAIR_RATE`
- **Jornada:** [Etapa 1 — Mundo Comum](../design/JORNADA-DO-HEROI.md#jh-1) (o MU-7 parado na doca há 2 séculos) · [Personagens](../design/JORNADA-DO-HEROI.md#jh-personagens)
- **ADRs:** [ADR-009](../DECISIONS.md#adr-009) · [ADR-010](../DECISIONS.md#adr-010) (camadas)
- **Assets:** [SPR-DOCK](../ASSETS.md#spr-dock) · [SPR-MU7](../ASSETS.md#spr-mu7) (`hurt`) · [SFX-PACK](../ASSETS.md#sfx-pack)

## 3. Critério de avaliação atendido

- **Life skills (vida/energia):** Integridade (4 células) e Carga (barra azul) visíveis no HUD (F15) mudando com dano, lanterna e doca.
- **Recompensas:** reparo/recarga na doca e pelos itens (Célula, Kit — F20) como recompensa por exploração; a F13 fornece `add_charge`/`repair`.

**Como o avaliador vê:** o apresentador encosta num SR-3 (knockback + piscar + célula some), fica numa doca e vê a Carga subir, e morre uma vez → tela "SINAL DO CHASSI PERDIDO - RESTAURANDO BACKUP" → reaparece na doca com 2 células e o reator 3% menor.

## 4. Escopo

### Inclui
- Comportamento dos métodos do `GameState`: `apply_damage(amount)`, `add_charge(v)`, `spend_charge(v) -> bool`, mais a extensão `repair(amount: int)` (ver ADR-F13-004).
- Multiplicador de dificuldade de dano aplicado **somente** em `GameState.apply_damage`.
- Lógica pura `scripts/core/vitals.gd` (escala de dano, células, respawn, acumulador de dano por segundo).
- Componente `scenes/world/damage_area.gd` (`class_name DamageArea`, `Area2D`) usado por inimigos e perigos (F22, F23, F32): dano de contato **ou** dano por segundo, com status opcional.
- `Hurtbox` do MU-7: knockback, estado `HURT` curto, invencibilidade com piscar, dano por segundo sem knockback.
- Morte: `player_died` (uma vez), animação `hurt`, trava de input, `DEATH_DELAY`, `GameState.deaths += 1`, ida para `scenes/ui/chassis_lost.tscn` (F10) — ou `game_over.tscn` se o reator zerou.
- Respawn: ao carregar a cena do checkpoint com `flags.respawn_pending`, o jogador nasce na doca `checkpoint.dock_id` com `ceil(integrity_max × RESPAWN_INTEGRITY_RATIO)` de Integridade; emite `player_respawned`.
- Comportamento da **doca de recarga** (`scenes/world/backup_dock.tscn`, criada pela F11): ativação automática ao entrar (checkpoint + save — parte da F11), regen de Carga `CHARGE_DOCK_REGEN`/s e reparo `DOCK_REPAIR_RATE`/s **enquanto o MU-7 estiver dentro e parado**; bloqueado por CORROSÃO.
- Zona de morte por queda (`Area2D` abaixo da fase, criada pela F21) → dano letal.
- SFX `damage` no dano.

### Não inclui
- HUD (células, barra) — F15 (esta feature só emite os sinais).
- Penalidade de −3% no reator — aplicada pela F14 ao ouvir `player_died`.
- Telas de chassi perdido / game over — F10.
- Save em si (`SaveManager.save_game()`) — F11 (chamado na ativação da doca).
- Upgrades de máximo (Núcleo de Capacitor → F20; Placa de Blindagem → Final/F49).
- Efeitos de status em si (CORROSÃO etc.) — F23; aqui só respeitamos `status_applied/cleared(&"corrosion")` na doca.
- SOBRECARGA (buff de recarga total) — Final (F48).

## 5. Critérios de aceite

- [x] `new_game()` deixa `integrity == integrity_max == Balance.INTEGRITY_MAX` e `charge == charge_max == Balance.CHARGE_MAX`.
- [x] Encostar num `DamageArea` de contato com `damage = 10` em Normal tira 10; em Fácil 5; em Difícil 15 (teste + QA com SR-3 placeholder).
- [x] Após dano de contato: knockback para longe da fonte (`KNOCKBACK_X`, `-KNOCKBACK_Y`), input travado por `KNOCKBACK_TIME`, sprite pisca e nenhum dano de contato é aplicado durante `INVINCIBILITY_TIME`.
- [x] `DamageArea` com `damage_per_second = 5` tira 5 pts por segundo em Normal, sem knockback, inclusive durante a invencibilidade.
- [x] `integrity_changed(current, maximum)` e `charge_changed(current, maximum)` são emitidos a cada mudança; `player_damaged(amount)` traz o valor **já escalado**.
- [x] Integridade 0 → `player_died` emitido **uma única vez**, input travado, após `DEATH_DELAY` troca para `chassis_lost.tscn`; `GameState.deaths` +1.
- [x] Após a tela de chassi perdido, o jogador nasce na última doca ativada com 50 de Integridade (Normal, máx 100), Carga inalterada, câmera já posicionada; coletáveis já pegos não voltam; `player_respawned` emitido.
- [x] Sem nenhuma doca ativada, o respawn acontece no `P` da fase atual.
- [x] Parado dentro da doca: Carga sobe 5/s e Integridade sobe `DOCK_REPAIR_RATE`/s até o máximo; andando dentro da doca, nada regenera; com CORROSÃO ativa, Carga não sobe.
- [x] Cair na zona de morte mata em qualquer dificuldade.
- [x] `spend_charge(v)` retorna `false` e não altera nada quando `charge < v`.
- [x] Portões do `/CLAUDE.md` §6 verdes
- [x] Sem comentários no código; nada 3D

## 6. Definição técnica

### Cenas e scripts
```
scripts/core/vitals.gd              class_name Vitals (static, pura)
autoload/game_state.gd              (completa os métodos de recurso; F02 criou as assinaturas)
scenes/world/damage_area.gd         class_name DamageArea extends Area2D (script sem cena própria)
scenes/player/mu7.gd                (acrescenta Hurtbox, knockback, invencibilidade, morte)
scenes/player/mu7.tscn              (acrescenta nó Hurtbox)
scenes/world/backup_dock.gd         (acrescenta regen/reparo; cena criada pela F11)
scenes/levels/level_base.gd         (acrescenta o passo de respawn; cena criada pela F21)
scenes/dev/damage_test.tscn (+ .gd) sala de teste com 1 DamageArea de contato, 1 de DPS, 1 doca e 1 poço
tests/test_vitals.gd
```

**`vitals.gd`** (pura):
```gdscript
class_name Vitals
extends RefCounted

static func scale_damage(amount: int, multiplier: float) -> int
static func cell_states(integrity: int, maximum: int, cells: int) -> Array[int]
static func respawn_integrity(maximum: int, ratio: float) -> int
static func accumulate(accumulator: float, per_second: float, delta: float) -> Vector2
static func clamp_add(current: float, amount: float, maximum: float) -> float
```
- `scale_damage`: `amount <= 0 → 0`; senão `maxi(1, ceili(amount * multiplier))` (dano nunca some por arredondamento, exceto multiplicador 0).
- `cell_states`: cada célula vale `maximum / cells`; retorna `2` cheia, `1` parcial, `0` vazia (ex.: 60/100/4 → `[2, 2, 1, 0]`). Usada pelo HUD (F15).
- `respawn_integrity`: `maxi(1, ceili(maximum * ratio))`.
- `accumulate`: soma `per_second * delta`; retorna `Vector2(dano_inteiro, resto)` — o chamador aplica o inteiro e guarda o resto.
- `clamp_add`: `clampf(current + amount, 0.0, maximum)`.

**`GameState` (métodos desta feature):**
```gdscript
func apply_damage(amount: int) -> void
func repair(amount: int) -> void
func add_charge(v: float) -> void
func spend_charge(v: float) -> bool
func is_dead() -> bool
```
- `apply_damage`: se `_dead`, retorna. `var mult: float = Balance.DIFFICULTY_DAMAGE_MULT[Settings.difficulty]`; `var dealt := Vitals.scale_damage(amount, mult)`; `integrity = maxi(0, integrity - dealt)`; emite `integrity_changed(integrity, integrity_max)` e `player_damaged(dealt)`; se `integrity == 0` → `_dead = true`, emite `player_died()`.
- `repair`: soma até `integrity_max`, emite `integrity_changed`.
- `add_charge`: `charge = Vitals.clamp_add(charge, v, charge_max)`; emite `charge_changed`.
- `spend_charge`: se `charge < v` → `false`; senão subtrai, emite, `true`.
- `_dead` volta a `false` no respawn e em `new_game()`/`from_dict()`.

**`DamageArea`** (componente):
```gdscript
class_name DamageArea
extends Area2D

@export var contact_damage: int = 0
@export var damage_per_second: float = 0.0
@export var knockback: bool = true
@export var status_id: StringName = &""
@export var status_duration: float = 0.0
@export var active: bool = true
```
- Fica na camada `enemy` (3) quando filho de inimigo, ou `hazard` (5) quando perigo de ambiente; `collision_mask = 0`, `monitorable = true`, `monitoring = false`.
- Os **valores vêm do `Balance`** no `_ready()` de quem instancia (ex.: SR-3 faz `$DamageArea.contact_damage = Balance.SR3_CONTACT_DAMAGE`). Nenhum número no `.tscn`.
- `active = false` desliga o dano (SR-3 desligado pelo Feixe, esporos encolhidos, piso sem energia).
- Status: a F13 **não** aplica status; ela emite `EventBus.status_applied(status_id, status_duration)` quando `status_id != &""` e o `DamageArea` causou dano — a F23 cuida da lógica do status.

**Hurtbox do MU-7** (nó `Hurtbox`, `Area2D`, `RectangleShape2D` 12×22 em (0, −12); `collision_layer = 0`, `collision_mask = enemy (3) + hazard (5)`, `monitoring = true`, `monitorable = false`). Em `_physics_process` do `mu7.gd`:
1. Se `GameState.is_dead()` ou `_locked_for_terminal`, ignora.
2. Para cada `DamageArea` ativa em `get_overlapping_areas()`:
   - `contact_damage > 0` e `_invincible_left <= 0` → `GameState.apply_damage(contact_damage)`, `_start_hurt(area.global_position, area.knockback)`.
   - `damage_per_second > 0` → `var r := Vitals.accumulate(_dps_acc, damage_per_second, delta)`; `_dps_acc = r.y`; se `r.x > 0` → `GameState.apply_damage(int(r.x))` (sem knockback, ignora invencibilidade).
3. `_dps_acc` zera quando nenhuma área de DPS está sobreposta.
- `_start_hurt(src, push)`: `play_action(&"hurt")`, `AudioManager.play_sfx("damage")`, `_invincible_left = INVINCIBILITY_TIME`; se `push`: `velocity = Vector2(signf(global_position.x - src.x) * KNOCKBACK_X, -KNOCKBACK_Y)` e trava input por `KNOCKBACK_TIME` (estado `HURT`).
- Piscar: enquanto `_invincible_left > 0`, `AnimatedSprite2D.visible` alterna a cada 0,1 s (visível ao fim).

**Morte** (`mu7.gd` escuta `EventBus.player_died`):
1. `set_input_locked(true)`, `velocity.x = 0`, `play_action(&"hurt")`.
2. `GameState.deaths += 1`; `GameState.flags["respawn_pending"] = true`.
3. `await get_tree().create_timer(Balance.DEATH_DELAY).timeout`.
4. Se `GameState.reactor_percent <= 0.0` → `SceneManager.goto("res://scenes/ui/game_over.tscn")` (a F14 já emitiu `game_over`); senão `EventBus.player_died.emit() (a F10 instancia a sobreposição)`. A F10 mostra a tela e depois chama `SceneManager.goto(GameState.checkpoint.scene)`.

**Respawn** (`level_base.gd`, passo executado depois do `LevelBuilder`, antes de liberar o jogador):
1. Se `GameState.flags.get("respawn_pending", false)`: procura a doca com `dock_id == GameState.checkpoint.dock_id` (grupo `backup_dock`); posição = doca ou, se vazia/não achada, `P`.
2. `GameState.integrity = Vitals.respawn_integrity(GameState.integrity_max, Balance.RESPAWN_INTEGRITY_RATIO)`; `_dead = false` (via método `GameState.revive()` interno ou atribuição + reset); emite `integrity_changed`.
3. `flags.erase("respawn_pending")`; `player.snap_camera()`; `EventBus.player_respawned.emit()`; `_invincible_left = INVINCIBILITY_TIME`.
4. Se `GameState.checkpoint` estiver vazio ao entrar numa fase, grava `{scene = scene_file_path, dock_id = ""}`.

**Doca** (`backup_dock.gd`, `Area2D` filho `ChargeZone` 24×40, mask `player`):
- `_physics_process`: se o MU-7 está dentro, `is_on_floor()` e `absf(velocity.x) < 1.0` → `add_charge(CHARGE_DOCK_REGEN * delta)` (se não houver CORROSÃO) e reparo acumulado com `Vitals.accumulate(_repair_acc, DOCK_REPAIR_RATE, delta)` → `GameState.repair(int)`.
- CORROSÃO: escuta `status_applied(&"corrosion", d)` → `_corroded = true`; `status_cleared(&"corrosion")` → `false`.
- Animação `charging` enquanto regenera, `idle` fora.

**Zona de morte:** a F21 cria um `Area2D` (camada `hazard`) 2 tiles abaixo do fundo da fase, com `DamageArea.contact_damage` letal. Para garantir letalidade em qualquer dificuldade, o script da zona chama `GameState.apply_damage(GameState.integrity_max * 2)` diretamente no `body_entered` do jogador (Fácil ×0,5 ainda zera).

### Autoloads / sinais do EventBus
- Emite: `integrity_changed(current, maximum)`, `charge_changed(current, maximum)`, `player_damaged(amount)`, `player_died()`, `player_respawned()`, `status_applied(status_id, duration)` (repasse de `DamageArea`).
- Escuta: `player_died` (no `mu7.gd`), `status_applied` / `status_cleared` (na doca).
- Usa: `Settings.difficulty`, `Balance.*`, `AudioManager.play_sfx`, `SceneManager.goto`, `GameState.checkpoint/flags/deaths`.

### Dados (`data/`)
- Nenhum.

### Input actions / camadas de colisão
- Sem input novo.
- `Hurtbox`: layer 0, mask `enemy` (3) + `hazard` (5). `DamageArea`: layer `enemy` (3) ou `hazard` (5), mask 0. `ChargeZone` da doca: layer `interactable` (4), mask `player` (2).

## 7. Assets necessários

| Asset id | Uso nesta feature | Placeholder |
|---|---|---|
| [SPR-DOCK](../ASSETS.md#spr-dock) | Animações `idle`/`charging` da doca | Moldura 28×44 com faixa ciana (F05) |
| [SPR-MU7](../ASSETS.md#spr-mu7) | Animação `hurt` (2f) | Cor própria na linha 6 (F05) |
| [SFX-PACK](../ASSETS.md#sfx-pack) | `damage` | Beep gerado |

## 8. 🧑 Ação humana

Nenhuma.

## 9. Plano de execução

- [x] **Passo 1** — Registrar as constantes novas (ADR-F13-001) no GDD-P + Ajustes e em `balance.gd`. Confirmar com a F08/F02 o nome do dicionário de multiplicadores (`Balance.DIFFICULTY_DAMAGE_MULT`); se já existir com outro nome, usar o existente.
- [x] **Passo 2** — `tests/test_vitals.gd` (seção 10) → falha → `scripts/core/vitals.gd` → passa.
- [x] **Passo 3** — Completar `apply_damage`, `repair`, `add_charge`, `spend_charge`, `is_dead` no `GameState`.
- [x] **Passo 4** — `damage_area.gd`.
- [x] **Passo 5** — `Hurtbox` no `mu7.tscn` + knockback, invencibilidade, piscar, DPS no `mu7.gd`.
- [x] **Passo 6** — Fluxo de morte (`player_died` → delay → `chassis_lost` / `game_over`).
- [x] **Passo 7** — Passo de respawn no `level_base.gd` (se a F21 ainda não existir, fazer em `damage_test.gd` e portar quando a F21 chegar; registrar no log).
- [x] **Passo 8** — Regen/reparo na doca + bloqueio por CORROSÃO.
- [x] **Passo 9** — `scenes/dev/damage_test.tscn` (chão, 1 DamageArea de contato 10, 1 DamageArea DPS 5, 1 doca, poço com zona de morte); `tests/scenes.txt`.
- [x] **Passo 10** — Portões + QA.

## 10. Verificação

- **Testes (`tests/test_vitals.gd`):**
  - `test_scale_damage_normal` — `scale_damage(10, 1.0) == 10`.
  - `test_scale_damage_easy_hard` — `scale_damage(10, 0.5) == 5`; `scale_damage(10, 1.5) == 15`; `scale_damage(5, 1.5) == 8` (arredonda para cima).
  - `test_scale_damage_never_zero` — `scale_damage(1, 0.5) == 1`; `scale_damage(0, 1.0) == 0`.
  - `test_cell_states` — `(100,100,4) → [2,2,2,2]`; `(60,100,4) → [2,2,1,0]`; `(0,100,4) → [0,0,0,0]`; `(25,100,4) → [2,0,0,0]`.
  - `test_respawn_integrity` — `respawn_integrity(100, 0.5) == 50`; `respawn_integrity(125, 0.5) == 63`.
  - `test_accumulate_dps` — 60 passos de `accumulate(acc, 5.0, 1.0/60.0)` somam exatamente 5 de dano inteiro (±0 após arredondamento do resto < 1).
  - `test_clamp_add` — `clamp_add(90, 40, 100) == 100`; `clamp_add(10, -30, 100) == 0`.
- **Smoke:** `res://scenes/dev/damage_test.tscn`.
- **Roteiro godot-qa** (`tests/qa/f13_damage.json`; cena `res://scenes/dev/damage_test.tscn`; layout: doca à esquerda, `DamageArea` de contato no meio, DPS à direita, poço no fim):

| Frame | Input | Screenshot | O que deve aparecer |
|---:|---|---|---|
| 10 | — | `f13_01_full` | HUD (se F15 pronta) com 4 células cheias; MU-7 fora da doca |
| 11–60 | segurar `move_right` até o bloco de contato | — | — |
| 62 | — | `f13_02_knockback` | MU-7 empurrado para a esquerda, no ar, animação `hurt` |
| 70 | — | `f13_03_blink` | Sprite invisível **ou** visível (piscando); 1 célula parcial (90/100) |
| 100–220 | segurar `move_right` atravessando a área DPS e parar dentro dela 2 s | — | — |
| 220 | — | `f13_04_dps` | Integridade ≈ 80 (sem knockback, MU-7 parado dentro da área) |
| 221–400 | andar até o poço e cair | — | — |
| 420 | — | `f13_05_chassis_lost` | Tela preta "SINAL DO CHASSI PERDIDO - RESTAURANDO BACKUP" (F10) |
| 600 | — | `f13_06_respawn` | MU-7 na doca, 2 células cheias (50/100), câmera centrada |
| 601–900 | parado | — | — |
| 900 | — | `f13_07_dock_regen` | Doca em `charging`; Integridade/Carga maiores que no frame 600 |

- **Playtest humano (opcional):** "tomar dano pareceu justo? o piscar deixa claro que você está invencível?"

## 11. ADRs locais

### ADR-F13-001 — Constantes de dano/respawn ausentes no GDD-P
- **Contexto:** o GDD define dano e knockback do SR-3 mas não a força do knockback, a duração da invencibilidade, o atraso da morte nem a taxa de reparo na doca.
- **Decisão:** adicionar ao GDD-P + Ajustes e ao `Balance`:

| Constante | Valor | Unidade |
|---|---|---|
| `KNOCKBACK_X` | 140 | px/s |
| `KNOCKBACK_Y` | 160 | px/s |
| `KNOCKBACK_TIME` | 0.25 | s |
| `INVINCIBILITY_TIME` | 1.0 | s |
| `DEATH_DELAY` | 0.8 | s |
| `DOCK_REPAIR_RATE` | 5 | pts/s |
| `DIFFICULTY_DAMAGE_MULT` | `{easy: 0.5, normal: 1.0, hard: 1.5}` | × (espelho de [GDD-P Dificuldade](../design/GDD.md#gdd-p-dificuldade)) |

- **Consequências:** tuning centralizado; se a F08 já tiver criado o dicionário com outro nome, prevalece o dela.
- **Data:** 2026-09-19

### ADR-F13-002 — Doca ativa ao entrar, regenera só parado
- **Contexto:** o GDD lista a doca entre os objetos de `interact` e diz que a Carga regenera "parado numa doca". Exigir botão para salvar é atrito extra e cria dependência da F16 antes da hora.
- **Decisão:** entrar na área da doca a **ativa** (checkpoint + save, F11); regen de Carga e reparo acontecem **enquanto parado** dentro dela. A doca não mostra prompt `[E]`.
- **Consequências:** zero dependência de F16; comportamento claro. Se o time quiser o literal do GDD, basta trocar a ativação por `Interactable` (F16) — registrar em Ajustes.
- **Data:** 2026-09-19

### ADR-F13-003 — Reparo na doca é gradual (e a Carga não muda no respawn)
- **Contexto:** o GDD diz "só repara em doca de recarga", sem taxa. Reparo instantâneo anularia a penalidade de 50% (o jogador renasce **dentro** da doca).
- **Decisão:** reparo gradual `DOCK_REPAIR_RATE` pts/s parado na doca; a Carga mantém o valor do momento da morte.
- **Consequências:** recuperar-se após morrer custa tempo do reator (reforça ESCASSEZ); sem constante nova de Carga no respawn.
- **Data:** 2026-09-19

### ADR-F13-004 — `GameState.repair()` e `is_dead()` como extensão do contrato
- **Contexto:** o contrato compartilhado lista `apply_damage`, `add_charge`, `spend_charge`, mas o Kit de Solda (F20) e a doca precisam **curar**.
- **Decisão:** acrescentar `repair(amount: int)` e `is_dead() -> bool` ao `GameState`. Dano negativo não é usado para curar.
- **Consequências:** F20 usa `repair(Balance.REPAIR_KIT_INTEGRITY)`. Registrar no log da F02.
- **Data:** 2026-09-19

### ADR-F13-005 — Respawn recarregando a cena do checkpoint
- **Contexto:** teleportar dentro da mesma cena exigiria resetar inimigos, portas e plataformas manualmente.
- **Decisão:** morrer sempre passa pela tela da F10 e recarrega a cena do checkpoint via `SceneManager.goto`; coletáveis (`collected_ids`) e energia (`energy_states`) persistem no `GameState`; inimigos resetam.
- **Consequências:** simples e robusto; custo de ~1 s de loading, aceitável.
- **Data:** 2026-09-19

### ADR-F13-006 — Os nomes do GDD-P prevalecem sobre os do ADR-F13-001
- **Contexto:** o ADR-F13-001 propôs `KNOCKBACK_X/Y/TIME`, `INVINCIBILITY_TIME` e `DOCK_REPAIR_RATE = 5`. Quando o `balance.gd` foi escrito (AJ-006/AJ-012), o GDD-P registrou `KNOCKBACK_SPEED = 140`, `INVULNERABLE_TIME = 0.8`, `SR3_KNOCKBACK_LOCK = 0.15` e `DOCK_REPAIR_RATE = 10`.
- **Decisão:** a implementação usa **as constantes que existem no `Balance`**. O empurrão genérico é `Vector2(±KNOCKBACK_SPEED, -KNOCKBACK_SPEED)`, a trava de input dura `SR3_KNOCKBACK_LOCK` e a invencibilidade `INVULNERABLE_TIME`. Nenhum número novo foi inventado.
- **Consequências:** o ADR-F13-001 fica como histórico; os nomes válidos são os do [GDD-P](../design/GDD.md#gdd-p). A F22 pode usar `SR3_KNOCKBACK_X/Y` no `DamageArea` do SR-3 se quiser um empurrão próprio.
- **Data:** 2026-09-19

### ADR-F13-007 — `deaths` e `revive()` moram no `GameState`
- **Contexto:** o plano original mandava o `mu7.gd` incrementar `GameState.deaths` e restaurar a Integridade no respawn. Isso quebra em qualquer cena sem jogador (telas de fim, testes headless).
- **Decisão:** `GameState.apply_damage` incrementa `deaths` no mesmo ponto em que emite `player_died` (uma vez só), e o `GameState` escuta `player_respawned` para chamar `revive()` — que aplica `Vitals.respawn_integrity` (50%) e `Vitals.respawn_charge` (`RESPAWN_CHARGE_RATIO = 1.0`, Carga cheia).
- **Consequências:** o MU-7 só cuida de posição, câmera, animação e invencibilidade pós-respawn; os números são testáveis headless.
- **Data:** 2026-09-19

### ADR-F13-008 — Respawn no mesmo carregamento de cena (supera o ADR-F13-005)
- **Contexto:** o ADR-F13-005 previa recarregar a cena do checkpoint. A F10 entregou `chassis_lost` como **sobreposição** que emite `player_respawned` sem trocar de cena ([ADR-013](../DECISIONS.md#adr-013)).
- **Decisão:** no `player_respawned` o MU-7 se reposiciona na doca de `GameState.checkpoint.dock_id` (grupo `backup_dock`); sem doca, pede `spawn_position()` ao nó do grupo `level` (o `P` da F21); sem fase, fica onde está. Câmera com `snap_camera()` e `INVULNERABLE_TIME` de graça.
- **Consequências:** respawn instantâneo, sem loading. Inimigos e plataformas **não** resetam — quando a F22/F25 existirem, quem precisar de reset escuta `player_respawned` (a F21 já faz isso para rearmar a zona de morte).
- **Data:** 2026-09-19

### ADR-F13-009 — `DEATH_DELAY` não é usado pela F13
- **Contexto:** o plano mandava esperar `Balance.DEATH_DELAY` antes de mostrar a tela. A F10/`SceneManager` já é dona do tempo (fade 0,4 s + digitação + espera).
- **Decisão:** a F13 só emite `player_died` (via `GameState`) e trava o input; o ritmo da tela é da F10. A morte toca a animação **`death`** (linha 9 do sheet, já existente) em vez de `hurt`.
- **Consequências:** `DEATH_DELAY` continua no `Balance` para quem precisar; não há atraso duplicado.
- **Data:** 2026-09-19

### ADR-F13-010 — Cenas de prova em `tests/qa/scenes/`
- **Contexto:** o plano pedia `scenes/dev/damage_test.tscn`. O projeto já concentra salas de prova em `tests/qa/scenes/` (ex.: `mu7_sandbox`), que não entram na build.
- **Decisão:** a sala de prova é `tests/qa/scenes/damage_sandbox.tscn` (+ base comum `sandbox_room.gd`), registrada em `tests/scenes.txt`.
- **Consequências:** nada de gameplay em `scenes/dev/`; o smoke cobre a sala.
- **Data:** 2026-09-19

## 12. Log de evolução

> Append-only. Mais novo no fim.

### 2026-09-19 — Feature criada
- **Quem**: agente de planejamento · **O que**: documento inicial a partir do GDD · **Próximo passo**: implementação.

### 2026-09-19 — Contrato de morte ajustado antes da implementação
- **Quem**: orquestrador (feature-loop Dia 1), após a F10 entregar as telas de fim.
- **O que muda nesta feature**: (1) `chassis_lost.tscn` é **sobreposição** instanciada pelo `SceneManager`, não cena de destino — a F13 **não** chama `goto`; (2) quem escuta `player_died` é a F10 ([ADR-F10-005](F10-telas-fim-de-jogo.md), [ADR-013](../DECISIONS.md#adr-013)); (3) a F13 **escuta** `player_respawned` para reposicionar o MU-7 na doca com 50% de Integridade e Carga cheia ([AJ-009](../design/GDD.md#gdd-ajustes)); (4) a F13 é quem incrementa `GameState.deaths` e a F14 aplica os −3% de Estabilidade.

### 2026-09-19 — Implementada
- **Quem**: agente de implementação (lote F13/F16/F18).
- **O que**: `scripts/core/vitals.gd` (pura) + `tests/test_vitals.gd` (14 casos); `GameState.apply_damage` passou a usar `Vitals.scale_damage` (arredonda para cima, nunca zera), ganhou `deaths += 1` na morte e `revive()`; `scenes/world/damage_area.gd` (`class_name DamageArea`); `Hurtbox` no `mu7.tscn` com knockback, i-frames com piscar e dano por segundo acumulado; `scenes/world/backup_dock.tscn` + `.gd` (contato ativa o checkpoint, emite `checkpoint_reached` → `SaveManager` salva, regen de Carga 5/s e reparo 10/s parado); respawn pelo `player_respawned`. Sala de prova `tests/qa/scenes/damage_sandbox.tscn`, roteiro `tests/qa/f13_dano_respawn.json`.
- **Portões**: import 0 erros · 272 testes passando · smoke 36/36 cenas · varreduras 3D/comentários/fonte vazias.
- **QA visual** (11 capturas lidas pelo agente): doca recarrega 42→47 de Carga em 1 s (`CHARGE_DOCK_REGEN`) com o toast "BACKUP SALVO"; contato tira **exatamente 10** em Normal e empurra o chassi para trás no ar (X 194→193 subindo, animação `hurt`); sprite pisca e a Integridade fica em 90 durante toda a invencibilidade; área de dano por segundo leva 79→69 em 2 s (`SPORE_DPS = 5`); queda no poço → tela "SINAL DO CHASSI PERDIDO"; respawn **na doca** (X 64) com 50 de Integridade (54 já com o reparo da doca), Carga 100 e MORTES 1; 3 s parado na doca: 54→84 (`DOCK_REPAIR_RATE = 10`).
- **Pendências**: a zona de morte da F21 (`level_base.gd`) usa `apply_damage(integrity_max)` — no Fácil (×0,5) isso **não** mata; o contrato desta feature é `integrity_max * 2` (usado na sala de prova). Reportado à F21.
- **Próximo passo**: F14 aplica os −3% de reator; F15 desenha células e barra; F20 usa `repair()`/`add_charge()`.
