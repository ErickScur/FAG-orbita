---
id: F02
title: Autoloads núcleo & Balance
status: done
scope: demo
block: 0
priority: P0
rubric: []
depends_on: ["F01", "F06"]
unblocks: ["F03", "F04", "F07", "F08", "F11", "F12", "F13", "F14"]
estimate: 2h
last_updated: 2026-09-19
---

# F02 — Autoloads núcleo & Balance

## 1. Contexto e objetivo

Todo sistema do jogo conversa por um barramento de sinais (`EventBus`), guarda o estado da run num lugar só (`GameState`), lê preferências de um lugar só (`Settings`) e tira números de um lugar só (`Balance`). Esta feature cria esses quatro pilares técnicos e registra **todos** os autoloads do contrato no `project.godot`, com esqueletos mínimos para os que outras features preenchem (SceneManager → F03, AudioManager → F04, SaveManager → F11, DialogueManager → F19).

Serve ao pilar **ESCASSEZ** ([GDD pilares](../design/GDD.md#gdd-pilares)) porque centraliza Integridade, Carga e Estabilidade do Reator, e aplica o multiplicador de dificuldade num único ponto. O jogador não vê esta feature; vê suas consequências em todo HUD, dano e timer.

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-P — Parâmetros numéricos](../design/GDD.md#gdd-p) (todas as constantes) · [Multiplicadores de dificuldade](../design/GDD.md#gdd-p-dificuldade) · [GDD-2.5 Timer](../design/GDD.md#gdd-2-5-timer) (congelado em pause/diálogo/log) · [GDD-2.5 Derrota](../design/GDD.md#gdd-2-5-derrota) · [GDD-2.6.1 Status base](../design/GDD.md#gdd-2-6-1-status) · [GDD-2.6.3 Itens](../design/GDD.md#gdd-2-6-3)
- **Parâmetros:** todos os `Balance.*` da tabela GDD-P, com os mesmos nomes e valores (ex.: `Balance.INTEGRITY_MAX`, `Balance.CHARGE_MAX`, `Balance.REACTOR_START`, `Balance.LOGS_TOTAL`, `Balance.RESEARCH_TOTAL`)
- **Ajustes:** [AJ-001, AJ-002, AJ-003](../design/GDD.md#gdd-ajustes)
- **ADRs:** [ADR-001](../DECISIONS.md#adr-001) · [ADR-007](../DECISIONS.md#adr-007)

## 3. Critério de avaliação atendido

Nenhum item direto. É pré-requisito de **Life skills**, **Dificuldade ajustável**, **Salvar/Carregar progresso** e **HUD** ([ENTREGAS §3.2](../ENTREGAS.md#rubrica)): o avaliador verá o dano mudar entre Fácil/Normal/Difícil porque o multiplicador mora aqui.

## 4. Escopo

### Inclui
- `scripts/core/balance.gd` (`class_name Balance`) espelhando 1:1 a tabela GDD-P + os multiplicadores de dificuldade.
- `autoload/event_bus.gd` com **todos** os sinais do contrato.
- `autoload/game_state.gd` com todos os campos e métodos do contrato, incluindo `play_time` e congelamento do timer.
- `autoload/settings.gd` completo: campos, `load_settings()`/`save_settings()` em `user://settings.cfg`, multiplicadores, `apply_display()`.
- Esqueletos (API pública com corpo mínimo e sem erro) de `scene_manager.gd`, `audio_manager.gd`, `save_manager.gd`, `dialogue_manager.gd`.
- Registro no `[autoload]` do `project.godot`, na ordem: `EventBus`, `Settings`, `GameState`, `SaveManager`, `AudioManager`, `SceneManager`, `DialogueManager` (o `QACapture` já foi registrado pela F06; mantê-lo por último).
- Testes `tests/test_balance.gd`, `tests/test_game_state.gd`, `tests/test_settings.gd`.

### Não inclui
- Lógica real de troca de cena (F03), áudio (F04), save em disco (F11), fila de diálogo (F19).
- Decaimento do reator ao longo do tempo ([F14](F14-estabilidade-reator.md)) — aqui só existe o campo e o multiplicador.
- Respawn após morte ([F13](F13-integridade-carga-respawn.md)) — aqui só `apply_damage` emite `player_died`.
- Upgrades permanentes (Placa de Blindagem etc. — F49, Final).

## 5. Critérios de aceite

- [x] `Balance` tem **todas** as todas as constantes da tabela GDD-P (85 hoje) da tabela GDD-P com nome e valor idênticos (teste compara uma lista embutida no teste).
- [x] `Balance.difficulty_damage_multiplier(&"hard") == 1.5`, `(&"easy") == 0.5`, `(&"normal") == 1.0`; idem `difficulty_reactor_multiplier`.
- [x] `EventBus` declara exatamente os 25 sinais do contrato, com as assinaturas tipadas.
- [x] `GameState.new_game()` deixa: `reactor_percent = Balance.REACTOR_START`, `integrity = integrity_max = Balance.INTEGRITY_MAX`, `charge = charge_max = Balance.CHARGE_MAX`, listas vazias, `deaths = 0`, `play_time = 0.0`, `checkpoint = {}`.
- [x] `GameState.apply_damage(10)` em Difícil reduz a Integridade em 15; em Fácil em 5; emite `player_damaged` e `integrity_changed`; ao chegar a 0 emite `player_died` uma única vez.
- [x] `spend_charge(v)` retorna `false` e não altera nada se `charge < v`; `add_charge` satura em `charge_max`; ambos emitem `charge_changed`.
- [x] `is_timer_frozen()` é `true` durante pause (`game_paused(true)`), diálogo (`dialogue_started` → `dialogue_finished`), log aberto (`log_opened` → `log_closed`) ou com `Settings.no_timer`.
- [x] `to_dict()` → `JSON.stringify` → `JSON.parse_string` → `from_dict()` reproduz o mesmo estado (StringNames e ints preservados).
- [x] `Settings.save_settings()` + `load_settings()` preserva todos os campos; arquivo ausente usa padrões (volumes 1.0/0.8/0.8/0.8, `&"normal"`, `no_timer=false`, `fullscreen=false`).
- [ ] O jogo abre (`"$GODOT" --path . --quit-after 60`) sem erro com os 8 autoloads.
- [ ] Portões do `/CLAUDE.md` §6 verdes.
- [x] Sem comentários no código; nada 3D.

## 6. Definição técnica

### Cenas e scripts
```
scripts/core/balance.gd       class_name Balance extends RefCounted (só const + 2 static func)
autoload/event_bus.gd         extends Node
autoload/game_state.gd        extends Node
autoload/settings.gd          extends Node
autoload/save_manager.gd      extends Node (esqueleto → F11)
autoload/audio_manager.gd     extends Node (esqueleto → F04)
autoload/scene_manager.gd     extends Node (esqueleto → F03)
autoload/dialogue_manager.gd  extends Node (esqueleto → F19)
```

### `Balance`
```gdscript
class_name Balance
extends RefCounted

const TILE_SIZE: int = 16
const INTEGRITY_MAX: int = 100
const INTEGRITY_CELLS: int = 4
const CHARGE_MAX: float = 100.0
const CHARGE_DOCK_REGEN: float = 5.0
const WALK_SPEED: float = 110.0
const DASH_SPEED: float = 320.0
const DASH_TIME: float = 0.25
const REACTOR_START: float = 100.0
const REACTOR_DECAY_INTERVAL: float = 90.0
const LOGS_TOTAL: int = 24
const RESEARCH_TOTAL: int = 12
const DIFFICULTY_DAMAGE := {&"easy": 0.5, &"normal": 1.0, &"hard": 1.5}
const DIFFICULTY_REACTOR := {&"easy": 0.5, &"normal": 1.0, &"hard": 1.5}

static func difficulty_damage_multiplier(difficulty: StringName) -> float:
	return DIFFICULTY_DAMAGE.get(difficulty, 1.0)
```
(Trecho ilustrativo; o arquivo real contém **todas** as linhas da GDD-P.) Inteiros da GDD-P que são pontos de Integridade/dano ficam `int`; Carga, tempo e porcentagem ficam `float`.

### `EventBus`
Os 25 sinais do contrato, exatamente:
`integrity_changed(current: int, maximum: int)` · `charge_changed(current: float, maximum: float)` · `reactor_changed(percent: float)` · `reactor_critical(active: bool)` · `player_damaged(amount: int)` · `player_died()` · `player_respawned()` · `status_applied(status_id: StringName, duration: float)` · `status_cleared(status_id: StringName)` · `interaction_available(prompt: String)` · `interaction_cleared()` · `energy_changed(terminal_id: StringName, system_id: StringName, powered: bool)` · `sector_restored(sector_id: StringName)` · `ability_unlocked(ability_id: StringName)` · `collectible_picked(kind: StringName, item_id: StringName)` · `log_opened(log_id: StringName)` · `log_closed(log_id: StringName)` · `dialogue_started()` · `dialogue_finished()` · `objective_changed(text: String)` · `checkpoint_reached(checkpoint_id: StringName)` · `game_over(reason: StringName)` · `demo_completed()` · `flashlight_toggled(on: bool)` · `game_paused(paused: bool)`.

### `GameState`
- Campos: exatamente os do contrato (`reactor_percent`, `integrity`, `integrity_max`, `charge`, `charge_max`, `logs_collected`, `research_collected`, `collected_ids`, `abilities`, `sectors_restored`, `energy_states`, `checkpoint`, `deaths`, `play_time`, `flags`, `current_objective`).
- Privados: `_paused: bool`, `_dialogue_active: bool`, `_log_open: bool`, `_died_emitted: bool`.
- `_ready()`: conecta `EventBus.game_paused`, `dialogue_started/finished`, `log_opened/closed` para atualizar os privados; chama `new_game()`.
- `_process(delta)`: soma `delta` a `play_time` somente quando `get_tree().current_scene` existe e `scene_file_path.begins_with("res://scenes/levels/")` (o autoload é pausável, então pause congela o tempo).
- `new_game()`: reset descrito nos critérios; emite `integrity_changed`, `charge_changed`, `reactor_changed`.
- `apply_damage(amount: int)`: `scaled := roundi(amount * Settings.damage_multiplier())`; ignora se `scaled <= 0` ou `integrity == 0`; subtrai com clamp; emite `player_damaged(scaled)`, `integrity_changed`; se chegou a 0, `deaths += 1` **não** é feito aqui (é da F13) — só emite `player_died()` uma vez até `integrity` voltar a > 0.
- `add_charge(v: float)`, `spend_charge(v: float) -> bool`, `repair(v: int)` (usado por Kit de Solda/respawn), `change_reactor(delta_percent: float)` com clamp 0..100 e emissão de `reactor_changed`.
- `is_timer_frozen() -> bool`: `_paused or _dialogue_active or _log_open or Settings.no_timer`.
- `to_dict() -> Dictionary` / `from_dict(d: Dictionary)`: StringName ↔ String, `energy_states` como `{terminal_id: [system_id...]}`, ints convertidos com `int()` na volta. Chave `"version": 1`.

### `Settings`
```gdscript
const PATH := "user://settings.cfg"
var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 0.8
var voice_volume: float = 0.8
var difficulty: StringName = &"normal"
var no_timer: bool = false
var fullscreen: bool = false
```
- `load_settings(path := PATH)` / `save_settings(path := PATH)` com `ConfigFile`, seções `[audio]` e `[game]` e `[display]`.
- `damage_multiplier() -> float` → `Balance.difficulty_damage_multiplier(difficulty)`.
- `reactor_decay_multiplier() -> float` → `0.0` se `no_timer`, senão `Balance.difficulty_reactor_multiplier(difficulty)`.
- `apply_display()` → `DisplayServer.window_set_mode(WINDOW_MODE_FULLSCREEN | WINDOW_MODE_WINDOWED)`.
- `_ready()`: `load_settings()`, `apply_display()`.

### Esqueletos (API congelada; corpo mínimo)
- `SceneManager`: `goto(path: String) -> void` (por enquanto `get_tree().change_scene_to_file.call_deferred(path)`), `goto_instant(path: String) -> void`, `is_transitioning() -> bool`.
- `AudioManager`: `play_music(id: StringName, fade: float = -1.0) -> void`, `stop_music(fade: float = -1.0) -> void`, `play_sfx(sfx_name: StringName) -> void`, `set_bus_volume(bus: StringName, linear: float) -> void`, `apply_volumes() -> void` — todos vazios exceto `pass`-equivalente (`return`).
- `SaveManager`: `const SAVE_PATH := "user://save.json"`, `has_save() -> bool` (`FileAccess.file_exists`), `save_game() -> bool` / `load_game() -> bool` / `delete_save() -> void` retornando `false`/nada.
- `DialogueManager`: `is_active() -> bool` retornando `false`.

### Dados (`data/`)
- Nenhum.

### Input actions / camadas de colisão
- Nenhuma.

## 7. Assets necessários

| Asset id | Uso nesta feature | Placeholder |
|---|---|---|
| — | Nenhum | — |

## 8. 🧑 Ação humana

Nenhuma.

## 9. Plano de execução

- [x] **Passo 1** — Escrever `tests/test_balance.gd` (lista esperada copiada da GDD-P) e `tests/test_game_state.gd` / `tests/test_settings.gd` no formato da [F06](F06-testes-portoes-qa.md) (`extends TestCase`). Rodar: falham.
- [x] **Passo 2** — `scripts/core/balance.gd` completo.
- [x] **Passo 3** — `event_bus.gd`, `settings.gd`, `game_state.gd`.
- [x] **Passo 4** — Esqueletos dos outros 4 autoloads.
- [x] **Passo 5** — `[autoload]` no `project.godot`: `EventBus="*res://autoload/event_bus.gd"` etc., na ordem da seção 4, `QACapture` por último.
- [ ] **Passo 6** — `--import`, `run_tests.gd` (verde), `smoke.sh`, varreduras.
- [ ] **Passo 7** — Commit `feat(F02): autoloads núcleo, EventBus, GameState, Settings e Balance`.

## 10. Verificação

- **Testes (`tests/test_*.gd`):**
  - `test_balance.gd`: cada constante da GDD-P existe (via `Balance.new().get_script().get_script_constant_map()`) com valor igual; multiplicadores das 3 dificuldades.
  - `test_game_state.gd`: instancia `load("res://autoload/game_state.gd").new()` (não o autoload) para `new_game`, `spend_charge`, `add_charge`, `add_reactor` com clamp, round trip `to_dict/from_dict` via JSON; `apply_damage` usando o autoload `Settings` com `difficulty` trocado e restaurado no fim.
  - `test_settings.gd`: salvar em `user://test_settings.cfg`, recarregar numa instância nova, comparar; `reactor_decay_multiplier()` = 0 com `no_timer`.
- **Smoke:** nenhuma cena nova.
- **Roteiro godot-qa:** não se aplica (sem visual). Validação por `"$GODOT" --path . --quit-after 60` sem `ERROR`.
- **Playtest humano (opcional):** —

## 11. ADRs locais

### ADR-F02-001 — Nomes das constantes de dificuldade
- **Contexto:** a tabela [Multiplicadores de dificuldade](../design/GDD.md#gdd-p-dificuldade) tem valores, mas não nomes de constante `Balance.*`.
- **Decisão:** `Balance.DIFFICULTY_DAMAGE_MULT` e `Balance.DIFFICULTY_REACTOR_MULT` (dicionários `StringName → float`, valores 0,5/1,0/1,5 do GDD), mais `difficulty_damage_multiplier()` e `difficulty_reactor_multiplier()`. "Modo sem timer" (×0) é aplicado por `Settings.reactor_decay_multiplier()`.
- **Consequências:** **adicionar as duas linhas à tabela GDD-P e uma entrada em [Ajustes](../design/GDD.md#gdd-ajustes)** ao implementar. **Data:** 2026-09-19.

### ADR-F02-002 — Esqueletos de autoloads com API congelada
- **Contexto:** `project.godot` falha ao abrir se um autoload aponta para arquivo inexistente; F03/F04/F11/F19 vêm depois.
- **Decisão:** a F02 registra todos e cria esqueletos com as assinaturas públicas definitivas; as features donas só preenchem o corpo.
- **Consequências:** qualquer feature pode chamar `AudioManager.play_sfx` desde já sem erro. **Data:** 2026-09-19.

### ADR-F02-003 — `play_time` conta só em cenas de fase
- **Contexto:** a estatística de tempo da [F10](F10-telas-fim-de-jogo.md) deve refletir gameplay.
- **Decisão:** soma em `_process` apenas quando a cena atual está em `res://scenes/levels/`; como o autoload é pausável, pause não conta.
- **Consequências:** menus e loading não entram no tempo. **Data:** 2026-09-19.

### ADR-F02-004 — `QACapture` não é registrado pela F02
- **Contexto:** a seção 4 assume que a F06 já registrou `QACapture` no `[autoload]`, mas a F06 está `not-started` e `autoload/qa_capture.gd` não existe. Registrar um autoload apontando para arquivo inexistente quebra a abertura do projeto.
- **Decisão:** a F02 registra apenas os 7 autoloads cujos arquivos ela cria (`EventBus`, `Settings`, `GameState`, `SaveManager`, `AudioManager`, `SceneManager`, `DialogueManager`), nessa ordem. A F06 acrescenta `QACapture` como última linha da seção.
- **Consequências:** o critério de aceite "8 autoloads" fica pendente até a F06. **Data:** 2026-09-19.

### ADR-F02-005 — Nomes do contrato do `/CLAUDE.md` §4.3 vencem os da seção 6
- **Contexto:** a seção 6 desta feature cita `repair(v: int)` e `change_reactor(delta_percent: float)`, enquanto o contrato dos autoloads ([`/CLAUDE.md` §4.3](../../CLAUDE.md)) define `repair(amount: int)` e `change_reactor(amount: float)` para os mesmos comportamentos.
- **Decisão:** valem os nomes do contrato (`repair`, `change_reactor`), por ser a fonte única citada por todas as outras features. Nenhum apelido foi criado.
- **Consequências:** F13/F14/F20 chamam `repair`/`change_reactor`. A seção 6 desta feature fica divergente do código — corrigir quando alguém reeditar o documento. **Data:** 2026-09-19.

### ADR-F02-006 — `set_objective` e `get_stats` ficam com as features donas
- **Contexto:** o contrato §4.3 lista `set_objective(id)` e `get_stats()` no `GameState`, mas a semântica de ambos depende de artefatos de outras features (`data/objectives.json` + `scripts/core/objectives.gd` da [F15](F15-hud-objetivos.md); `scripts/core/stats.gd` da [F20](F20-coletaveis-contadores.md)), que ainda não existem.
- **Decisão:** a F02 implementa todo o resto do contrato (incluindo `register_pickup`, `repair`, `change_reactor`, `reactor_multiplier`, `is_dead`) e deixa `set_objective`/`get_stats` para F15/F20, em vez de inventar formato de objetivo ou de estatísticas.
- **Consequências:** quem chamar esses dois métodos antes da F15/F20 recebe erro claro de método inexistente. **Data:** 2026-09-19.

## 12. Log de evolução

### 2026-09-19 — Feature criada
- **Quem**: agente de planejamento · **O que**: documento inicial a partir do GDD-P e do contrato compartilhado · **Próximo passo**: implementação (depois da F06).

### 2026-09-19 — Implementação
- **Quem**: agente de implementação (Claude) · **O que**: `scripts/core/balance.gd` espelhando a GDD-P inteira (85 constantes, não as 37 do critério antigo — a tabela cresceu com AJ-006/AJ-012/AJ-013), `autoload/event_bus.gd` com os 25 sinais do contrato, `autoload/settings.gd` (ConfigFile em `user://settings.cfg`, seções `[audio]`/`[game]`/`[display]`, multiplicadores, `apply_display`), `autoload/game_state.gd` (campos do contrato, congelamento do timer por pause/diálogo/log/`no_timer`, `apply_damage`/`repair`/`add_charge`/`spend_charge`/`change_reactor`/`register_pickup`/`to_dict`/`from_dict`), esqueletos de `save_manager.gd`, `audio_manager.gd`, `dialogue_manager.gd` (e `scene_manager.gd`, preenchido em seguida pela F03) e a seção `[autoload]` do `project.godot` na ordem de dependência. Testes `tests/test_balance.gd`, `tests/test_game_state.gd` e `tests/test_settings.gd` no formato da F06.
- **Decisões**: ADR-F02-004 (sem `QACapture` até a F06), ADR-F02-005 (nomes `repair`/`change_reactor` do contrato §4.3), ADR-F02-006 (`set_objective`/`get_stats` ficam com F15/F20).
- **Validação**: `--import` e `--path .` sem `SCRIPT ERROR`/`ERROR:`; varreduras de 3D e de comentários vazias. As 24 asserções das 4 suítes foram executadas com um `TestCase`/runner temporário (removido depois) — todas passaram; a execução oficial fica para a F06.
- **Pendente**: critérios "8 autoloads" e "portões §6 verdes" dependem da F06 (`tests/run_tests.gd`, `tools/smoke.sh`, `QACapture`). A tabela GDD-P tem linhas corrompidas (as linhas de Ajustes AJ-013..AJ-016 foram coladas dentro da tabela, a partir de `SR3_SPEED`); os nomes e valores ainda são legíveis e foram espelhados, mas o GDD precisa de conserto — não foi feito aqui por ser `docs/`.
- **Próximo passo**: F06 (runner, smoke, QACapture) para fechar os dois critérios pendentes.
