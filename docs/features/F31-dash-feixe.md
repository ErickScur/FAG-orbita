---
id: F31
title: Dash magnético & Feixe de Manutenção
status: not-started
scope: stretch
block: 5
priority: P2
rubric: ["Habilidades", "Combate (não-letal)"]
depends_on: ["F12", "F13", "F22", "F23", "F29"]
unblocks: []
estimate: 1.5h
last_updated: 2026-09-19
---

# F31 — Dash magnético & Feixe de Manutenção

## 1. Contexto e objetivo

Duas habilidades que o [GDD-2.4](../design/GDD.md#gdd-2-4) marca como **iniciais** (fazem parte dos controles base) e que ficaram fora do caminho crítico da Demo ([ADR-009](../DECISIONS.md#adr-009), ordem de corte):

- **Dash magnético** (`SHIFT`): impulso horizontal de `Balance.DASH_SPEED` por `Balance.DASH_TIME`, custando `Balance.DASH_COST` de Carga, com `Balance.DASH_COOLDOWN` de recarga. Atravessa nuvens de esporos e jatos de vapor sem tomar dano.
- **Feixe de Manutenção** (`Q`): reinicia uma máquina a curta distância. Em inimigos, **DESLIGA por `Balance.BEAM_SHUTDOWN_TIME`** (4 s) — custa `Balance.BEAM_COST`. Não destrói nada.

É a tradução mecânica da regra de design mais importante do GDD: *"nenhum botão é 'atacar'. O botão de agressão do jogo é um botão de manutenção. ÓRBITA não sabe destruir, só sabe consertar e desligar."*

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.4 Controles (dash, feixe e a regra de design)](../design/GDD.md#gdd-2-4) · [GDD-2.6.1 Status base](../design/GDD.md#gdd-2-6-1-status) · [GDD-2.6.1 Habilidades](../design/GDD.md#gdd-2-6-1-habilidades) · [GDD-2.6.2 (inimigos só são desligados)](../design/GDD.md#gdd-2-6-2) · [GDD-2.6.2-D (atravessar esporos de dash)](../design/GDD.md#gdd-2-6-2-d) · [GDD-2.6.2-E (dash atravessa jato de vapor)](../design/GDD.md#gdd-2-6-2-e) · [GDD-2.9 SFX (feixe = chiado + gemido descendente)](../design/GDD.md#gdd-2-9-sfx)
- **Parâmetros:** `Balance.DASH_SPEED` (320), `Balance.DASH_TIME` (0,25), `Balance.DASH_COST` (20), `Balance.DASH_COOLDOWN` (1,0), `Balance.BEAM_COST` (25), `Balance.BEAM_SHUTDOWN_TIME` (4,0) — [GDD-P](../design/GDD.md#gdd-p). **Novo (ADR-F31-001):** `Balance.BEAM_RANGE`.
- **Jornada:** [Etapa 5 — Testes e Aliados](../design/JORNADA-DO-HEROI.md#jh-5)
- **ADRs:** [ADR-009](../DECISIONS.md#adr-009) (stretch) · [ADR-010](../DECISIONS.md#adr-010) (ações `dash` e `beam` já mapeadas)
- **Features vizinhas:** [F12](F12-movimento-mu7.md), [F13](F13-integridade-carga-respawn.md) (Carga, `spend_charge`), [F22](F22-inimigo-sr3.md) (`shutdown()`, grupo `"beam_target"`), [F23](F23-esporos-status.md) (`is_dashing()`), [F32](F32-obstaculos-ambientais.md) (vapor), [F29](F29-fase-estufa.md) (onde se usa).

## 3. Critério de avaliação atendido

- **Habilidades** e **Combate (não-letal)** ([rubrica](../ENTREGAS.md#rubrica)).
- Na apresentação: o MU-7 **atravessa a nuvem de esporos num dash** sem perder Integridade (a barra de Carga cai 20) e, diante de uma SR-3, aperta `Q` — a aranha **apaga a luz, dobra as pernas e para por 4 s** com um "gemido" descendente, e o jogador passa por cima dela. Nada explode, nada morre.

## 4. Escopo

### Inclui
- Estado `DASH` no `mu7.gd`: horizontal, sem gravidade, com cooldown e custo de Carga; `is_dashing() -> bool` público (usado por [F23](F23-esporos-status.md) e [F32](F32-obstaculos-ambientais.md)).
- Feixe: `RayCast2D` frontal de `Balance.BEAM_RANGE`, atinge o primeiro nó do grupo `"beam_target"` e chama `shutdown(Balance.BEAM_SHUTDOWN_TIME)`.
- Custos e bloqueios: `GameState.spend_charge(v) -> bool` (sem Carga, a habilidade não sai e toca um som seco); bloqueio por DESCARGA (`GameState.statuses.blocks_abilities()`, [F23](F23-esporos-status.md)).
- Feedback visual: rastro do dash (`CPUParticles2D` curto) e `Line2D` do feixe por 0,1 s + luz piscando.
- Marcação de custo na barra de Carga do HUD ([GDD-2.8](../design/GDD.md#gdd-2-8-hud): "com marcação do custo da próxima habilidade") — se a [F15](F15-hud-objetivos.md) já tiver o slot.
- As duas habilidades entram em `GameState.abilities` (`&"dash"`, `&"beam"`) já no `new_game()`, porque o GDD as define como iniciais.
- Dicas contextuais na Estufa: falas curtas ao ver a primeira SR-3 e a primeira nuvem (gatilhos novos no JSON da [F29](F29-fase-estufa.md)).
- Lógica pura `scripts/core/dash_logic.gd` com testes.

### Não inclui
- Pulo duplo / Propulsor (`DOUBLE_JUMP_COST`) — upgrade das Docas, Final.
- Feixe consertando máquinas amigas, abrindo portas ou sobrecarregando terminais (Acesso Root) — Final.
- Dash vertical/diagonal ou dash no ar encadeado.
- Inimigos que reagem ao barulho do dash (V-9) — Final.

## 5. Critérios de aceite

- [ ] `SHIFT` com Carga ≥ 20 dispara o dash: o MU-7 avança rápido por 0,25 s na direção que está olhando, gastando 20 de Carga.
- [ ] Durante o dash o MU-7 **não** toma dano de esporos nem de vapor, e o `is_dashing()` retorna `true`.
- [ ] O dash respeita o cooldown de 1 s (segundo `SHIFT` imediato não faz nada).
- [ ] Com Carga < 20, o dash não acontece e toca um som de recusa; a Carga não fica negativa.
- [ ] `Q` com Carga ≥ 25 dispara o feixe: a SR-3 a até `Balance.BEAM_RANGE` na frente desliga por 4 s (animação `off`, luz apagada, sem dano por contato) e volta sozinha depois.
- [ ] O feixe **não** atravessa parede (o `RayCast2D` colide com `world` também) e não afeta inimigos atrás do MU-7.
- [ ] Nenhum inimigo é destruído: depois dos 4 s ele volta a patrulhar.
- [ ] Com DESCARGA ativa (se algum dia houver fonte), dash e feixe ficam bloqueados.
- [ ] `tests/test_dash_logic.gd` verde.
- [ ] Portões do `/CLAUDE.md` §6 verdes
- [ ] Sem comentários no código; nada 3D

## 6. Definição técnica

### Cenas e scripts
```
scenes/player/mu7.tscn (+ mu7.gd)
  ├─ BeamRay (RayCast2D)     position (0,-14) · target_position (±Balance.BEAM_RANGE, 0) · mask = 1 (world) | 3 (enemy)
  ├─ BeamLine (Line2D)       2 pontos, visible = false, cor ciano
  └─ DashTrail (CPUParticles2D)  emitting = false, one_shot
scripts/core/dash_logic.gd   class_name DashLogic (RefCounted, só static)
```
```gdscript
class_name DashLogic
extends RefCounted

static func can_use(charge: float, cost: float, cooldown_left: float, blocked: bool) -> bool: ...
static func dash_velocity(facing: int, speed: float) -> Vector2: ...   # Vector2(facing * speed, 0)
```
No `mu7.gd`:
- `_physics_process`: `_dash_cooldown = maxf(0.0, _dash_cooldown - delta)`; se `state == DASH`, `_dash_left -= delta`, `velocity = _dash_velocity`, sem gravidade, `move_and_slide()`; ao acabar, volta ao estado normal e inicia o cooldown.
- Entrada do dash: `Input.is_action_just_pressed("dash")` e `DashLogic.can_use(GameState.charge, Balance.DASH_COST, _dash_cooldown, GameState.statuses.blocks_abilities())` e `GameState.spend_charge(Balance.DASH_COST)`.
- Feixe: `Input.is_action_just_pressed("beam")` → mesma checagem com `Balance.BEAM_COST`; `BeamRay.force_raycast_update()`; se o colisor está no grupo `"beam_target"` e tem o método `shutdown` → `collider.shutdown(Balance.BEAM_SHUTDOWN_TIME)`; `AudioManager.play_sfx("beam")`; `BeamLine` visível por 0,1 s.
- `is_dashing() -> bool` → `state == DASH`.

### Autoloads / sinais do EventBus
- **Usa:** `GameState.spend_charge(v) -> bool` (emite `charge_changed`), `GameState.statuses.blocks_abilities()`, `GameState.abilities`.
- **Emite:** `charge_changed` (via `GameState`), `ability_unlocked(&"dash")` e `ability_unlocked(&"beam")` se optarmos por anunciá-las no `new_game()` (ver ADR-F31-002).
- SFX: `dash` e `beam` (**novos** no SFX-PACK, ver seção 11) + `sr3_shutdown` (já existe, tocado pela [F22](F22-inimigo-sr3.md)).

### Dados (`data/`)
- Gatilhos/falas novos em `data/levels/greenhouse.json` e `data/dialogue/greenhouse.json`:
```json
{ "triggers": [
  { "id": "gh_t_beam_hint", "rect": [11, 36, 2, 2], "dialogue": "gh_beam_hint", "once": true },
  { "id": "gh_t_dash_hint", "rect": [22, 36, 2, 2], "dialogue": "gh_dash_hint", "once": true }
] }
```
```json
{
  "gh_beam_hint": ["Unidade de reparo ativa. Não me reconhece.", "O feixe de manutenção (Q) desliga uma máquina por alguns segundos."],
  "gh_dash_hint": ["Impulso magnético (SHIFT) atravessa a nuvem antes que ela reaja."]
}
```

### Input actions / camadas de colisão
- `dash` (SHIFT / B) e `beam` (Q / Y) — já definidas no [ADR-010](../DECISIONS.md#adr-010); **nenhuma nova**.
- `BeamRay` mascara `world` (1) e `enemy` (3) para não atravessar parede.

## 7. Assets necessários

| Asset id | Uso nesta feature | Placeholder |
|---|---|---|
| [SPR-MU7](../ASSETS.md#spr-mu7) | Reuso dos frames de `walk`/`interact` (sem linha nova) | — |
| [FX-LIGHT](../ASSETS.md#fx-light) | Brilho do feixe e rastro do dash | Gradiente radial |
| [SFX-PACK](../ASSETS.md#sfx-pack) | `dash`, `beam` (**novos**), `sr3_shutdown` (existente) | Beeps gerados |

## 8. 🧑 Ação humana

Nenhuma.

## 9. Plano de execução

- [ ] **Passo 1** — `Balance.BEAM_RANGE` + proposta de linha no GDD-P e em Ajustes.
- [ ] **Passo 2** — `tests/test_dash_logic.gd` + `scripts/core/dash_logic.gd`.
- [ ] **Passo 3** — Estado `DASH` + `is_dashing()` no `mu7.gd`.
- [ ] **Passo 4** — Feixe (raycast, `shutdown`, `Line2D`, SFX).
- [ ] **Passo 5** — `&"dash"` e `&"beam"` em `GameState.new_game()`; marcação de custo no HUD (se houver slot).
- [ ] **Passo 6** — Gatilhos e falas de dica na Estufa.
- [ ] **Passo 7** — QA (roteiro da seção 10) e `/verify-gates`; commit `feat(F31): dash magnético e feixe de manutenção`.

## 10. Verificação

- **Testes (`tests/test_dash_logic.gd`):**
  - `test_can_use_with_charge_and_no_cooldown`: `can_use(100, 20, 0.0, false) == true`.
  - `test_blocked_by_cooldown`: `can_use(100, 20, 0.5, false) == false`.
  - `test_blocked_by_low_charge`: `can_use(10, 20, 0.0, false) == false`.
  - `test_blocked_by_status`: `can_use(100, 20, 0.0, true) == false`.
  - `test_exact_charge_is_enough`: `can_use(20, 20, 0.0, false) == true`.
  - `test_dash_velocity_follows_facing`: `dash_velocity(-1, 320) == Vector2(-320, 0)`.
- **Smoke:** nenhuma cena nova (a `mu7.tscn` já está listada pela F12).
- **Roteiro godot-qa** (`tests/qa/f31_dash_beam.json`) — sala `tests/qa/levels/qa_dash.txt` com `P`, uma nuvem `~` e uma SR-3 `S`:

  | Frame | Input / ação | Screenshot | Deve mostrar |
  |---|---|---|---|
  | 30 | — | `01_start.png` | Carga 100/100, nuvem à direita |
  | 60 | `move_right` + `dash` | `02_dashing.png` | MU-7 dentro da nuvem com rastro, **Integridade intacta**, Carga 80 |
  | 90 | — | `03_after_dash.png` | MU-7 do outro lado, sem ícone de CORROSÃO |
  | 100 | `dash` de novo | `04_cooldown.png` | nada acontece (cooldown), Carga ainda 80 |
  | 220 | `dash` | `05_dash_ok.png` | dash sai de novo (cooldown terminado), Carga 60 |
  | 300 | `beam` mirando a SR-3 | `06_beam.png` | linha ciano até a SR-3, Carga 35 |
  | 320 | — | `07_sr3_off.png` | SR-3 dobrada e apagada |
  | 340–420 | `move_right` por cima dela | `08_pass.png` (f420) | MU-7 passou sem tomar dano |
  | 560 | — | `09_sr3_awake.png` | SR-3 andando de novo (não foi destruída) |
- **Playtest humano (opcional):** o dash parece "magnético" (curto e seco) e não um pulo lateral? O feixe dá a sensação de **desligar**, não de atacar?

## 11. ADRs locais

### ADR-F31-001 — Alcance do feixe
- **Contexto:** o GDD diz "curta distância" sem número.
- **Decisão:** `Balance.BEAM_RANGE = 32` (px = 2 tiles ≈ 2 m pela conversão do [AJ-002](../design/GDD.md#gdd-ajustes)). **Entrada proposta no [GDD-P](../design/GDD.md#gdd-p)** (origem 2.4) + linha em Ajustes.
- **Consequências:** obriga o jogador a chegar perto — o feixe continua sendo arriscado, como manda o GDD ("o jogo pune o confronto").
- **Data:** 2026-09-19

### ADR-F31-002 — Dash e Feixe são habilidades iniciais registradas em `abilities`
- **Contexto:** o GDD-2.6.1 lista as duas como iniciais, mas o contrato do `GameState` guarda habilidades destravadas num array.
- **Decisão:** `new_game()` já inclui `&"dash"` e `&"beam"` em `abilities` (sem emitir `ability_unlocked`, que é reservado a destraves narrativos como as Garras). Se a feature for cortada, o array simplesmente não as terá e nada quebra.
- **Consequências:** o save é consistente com ou sem a stretch; a [F24](F24-garras-magneticas.md) continua sendo o único destrave com cena.
- **Data:** 2026-09-19

### ADR-F31-003 — `dash` e `beam` são SFX novos no SFX-PACK
- **Contexto:** o [GDD-2.9 SFX](../design/GDD.md#gdd-2-9-sfx) descreve os dois sons, mas a lista do [SFX-PACK](../ASSETS.md#sfx-pack) não tem as linhas.
- **Decisão:** pedir as entradas `dash` ("pulso magnético curto e agudo") e `beam` ("chiado elétrico") no `ASSETS.md`; placeholder gerado até lá.
- **Consequências:** duas linhas novas na ficha do SFX-PACK (skill `asset-request`).
- **Data:** 2026-09-19

## 12. Log de evolução

### 2026-09-19 — Feature criada
- **Quem**: agente de planejamento · **O que**: documento inicial a partir do GDD-2.4 · **Próximo passo**: só depois do Bloco 4 inteiro `[x]` ([AGENTS §3.1](../AGENTS.md)).
