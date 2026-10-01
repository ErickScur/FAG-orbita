---
id: F16
title: Sistema de interação
status: done
scope: demo
block: 2
priority: P0
rubric: []
depends_on: ["F02", "F12", "F15"]
unblocks: ["F17", "F19", "F20", "F24", "F27", "F28", "F29"]
estimate: 1.5h
last_updated: 2026-09-19
---

# F16 — Sistema de interação

## 1. Contexto e objetivo

Tudo que a ÓRBITA faz no mundo passa pelo botão de **manutenção**, não de ataque: `interact` (E / X) abre terminais, lê registros, examina objetos do cotidiano interrompido e religa o Nó de Energia do setor. Esta feature entrega o componente genérico `Interactable`, o sensor no MU-7, a escolha do alvo mais próximo e o prompt contextual do HUD (`[E] ACESSAR TERMINAL`).

É a "cola" entre o movimento (F12) e todo o conteúdo: Terminal de Distribuição (F17), logs e diálogos (F19), área secreta (F27), fases (F28/F29).

Serve ao pilar **DESCOBERTA** (a história é encontrada objeto a objeto) e à regra de design dos controles: *"o botão de agressão do jogo é um botão de manutenção"*.

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.4 Controles](../design/GDD.md#gdd-2-4) (`interact` = terminais, portas, alavancas, docas, corpos e objetos com log; regra "nenhum botão é atacar") · [GDD-2.8 HUD](../design/GDD.md#gdd-2-8-hud) (prompt contextual `[E] ACESSAR TERMINAL` no centro inferior) · [GDD-2.6.1 Habilidades](../design/GDD.md#gdd-2-6-1-habilidades) (Interagir é habilidade inicial) · [GDD-2.9 SFX](../design/GDD.md#gdd-2-9-sfx)
- **Parâmetros:** nenhum do GDD-P. Novos (ADR-F16-001): `INTERACT_RANGE`
- **Jornada:** [Etapa 1](../design/JORNADA-DO-HEROI.md#jh-1) (ler logs como rotina) · [Etapa 4](../design/JORNADA-DO-HEROI.md#jh-4) (examinar o primeiro corpo)
- **ADRs:** [ADR-010](../DECISIONS.md#adr-010) (input e camadas)
- **Assets:** [UI-HUD](../ASSETS.md#ui-hud) (ícone da tecla [E]) · [SFX-PACK](../ASSETS.md#sfx-pack) (`interact`)

## 3. Critério de avaliação atendido

Base (sem item próprio), mas **habilita** os itens Diálogo (F19), Puzzle (F17), Coleta/Itens (F20) e Área secreta (F27). O avaliador vê o prompt aparecendo ao chegar perto de cada objeto e sumindo ao se afastar.

## 4. Escopo

### Inclui
- `scenes/world/interactable.gd` (`class_name Interactable extends Area2D`): `prompt_text`, `enabled`, sinal `interacted(actor)`, método `interact(actor)`.
- Nó `InteractionSensor` (`Area2D`) no `mu7.tscn` + lógica em `mu7.gd`: mantém a lista de candidatos, escolhe o alvo (mais próximo; empate resolve por `priority`), emite `interaction_available(prompt)` / `interaction_cleared()`.
- Prefixo de tecla conforme o último dispositivo usado: `[E]` (teclado) ou `[X]` (controle).
- Acionamento: `interact` pressionado, jogador **no chão**, não travado, sem diálogo ativo → `target.interact(self)`, animação `interact`, SFX `interact`.
- Bloqueios: enquanto `DialogueManager.is_active()`, enquanto a UI do terminal estiver aberta e enquanto o jogador estiver travado (`set_input_locked`) não há prompt nem acionamento.
- Suporte a **desabilitar/reabilitar** um `Interactable` em runtime (ex.: terminal sem energia, Nó já religado) com troca de `prompt_text`.
- Cena de teste `scenes/dev/interaction_test.tscn` com 3 interagíveis (um desabilitado) e um contador de acionamentos na tela.

### Não inclui
- O que cada objeto faz ao ser interagido (terminal → F17, log → F19, Nó → F17, parede secreta → F27).
- Prompt desenhado (é um `Label` do HUD, F15).
- Interação por toque/automática (coletáveis F20 e doca F13 são por contato, sem botão).
- Segurar para interagir, minigames, roda de opções — fora de escopo da demo.
- Remapeamento de teclas (F51): o glifo é escolhido por dispositivo, não pela tecla configurada.

## 5. Critérios de aceite

- [x] Chegar perto de um `Interactable` habilitado mostra `[E] <PROMPT>` no HUD; afastar-se esconde.
- [x] Com dois interagíveis sobrepostos, o prompt é o do **mais próximo**; andar de um para o outro troca o texto sem piscar duas vezes.
- [x] Apertar `interact` chama `interact(actor)` **uma única vez** por pressionada e emite `interacted`.
- [x] Um `Interactable` com `enabled = false` não aparece no prompt e não pode ser acionado.
- [x] Durante diálogo (`dialogue_started`) o prompt some e `interact` não aciona nada (a tecla é do diálogo); ao terminar, o prompt volta se ainda houver alvo.
- [x] No ar, o prompt aparece mas o acionamento não ocorre (evita interagir pulando).
- [x] Usando controle, o prompt mostra `[X]`; voltando ao teclado, `[E]`.
- [x] O jogador nunca precisa mirar: qualquer lado funciona, dentro de `INTERACT_RANGE`.
- [x] Portões do `/CLAUDE.md` §6 verdes
- [x] Sem comentários no código; nada 3D

## 6. Definição técnica

### Cenas e scripts
```
scenes/world/interactable.gd        class_name Interactable extends Area2D
scenes/player/mu7.tscn (+ mu7.gd)   nó InteractionSensor + lógica de alvo
scenes/dev/interaction_test.tscn (+ .gd)
tests/test_interaction_target.gd
scripts/core/interaction_rules.gd   class_name InteractionRules (pura: escolha de alvo e prompt)
```

**`interactable.gd`:**
```gdscript
class_name Interactable
extends Area2D

signal interacted(actor: Node)

@export var prompt_text: String = "INTERAGIR"
@export var enabled: bool = true
@export var priority: int = 0

func interact(actor: Node) -> void
func set_enabled(value: bool) -> void
func set_prompt(text: String) -> void
```
- `interact`: se `enabled`, emite `interacted(actor)`. Quem usa (terminal, log, Nó) conecta o sinal **ou** herda e sobrescreve.
- `collision_layer = interactable (4)`, `collision_mask = 0`, `monitoring = false`, `monitorable = true`.
- `set_enabled(false)` num objeto que é o alvo atual faz o sensor recalcular (o sensor revalida todo frame de física).

**`InteractionSensor`** (filho do MU-7): `Area2D` com `CircleShape2D` de raio `Balance.INTERACT_RANGE` (24 px), `position (0, -12)`, `collision_layer = 0`, `collision_mask = interactable (4)`, `monitoring = true`. O raio é atribuído em `_ready()` por código (nada de número no `.tscn`).

**Lógica em `mu7.gd`** (por frame de física, depois do movimento):
```gdscript
var candidates := _sensor.get_overlapping_areas()
var target := InteractionRules.pick(candidates, global_position)
if target != _target or _prompt_dirty:
    _target = target
    if _target == null or _blocked():
        EventBus.interaction_cleared.emit()
    else:
        EventBus.interaction_available.emit(InteractionRules.prompt(_key_glyph(), _target.prompt_text))
```
- `_blocked()`: `is_input_locked()` ou `DialogueManager.is_active()`.
- Acionamento: `if Input.is_action_just_pressed(&"interact") and _target != null and is_on_floor() and not _blocked(): play_action(&"interact"); AudioManager.play_sfx("interact"); _target.interact(self)`.
- `_key_glyph()`: `"[X]"` se o último `InputEvent` relevante foi `InputEventJoypadButton`/`InputEventJoypadMotion` (rastreado em `_input`), senão `"[E]"`.

**`interaction_rules.gd`** (pura, testável — recebe dados, não nós):
```gdscript
class_name InteractionRules
extends RefCounted

static func pick_index(positions: PackedVector2Array, enabled: PackedInt32Array,
        priorities: PackedInt32Array, origin: Vector2) -> int
static func prompt(glyph: String, text: String) -> String
```
- `pick_index`: ignora desabilitados; escolhe a maior `priority`; empate → menor distância; nenhum → `-1`.
- `prompt`: `"%s %s" % [glyph, text]`.
- O wrapper `InteractionRules.pick(areas, origin)` (não puro, no mesmo arquivo) monta os arrays a partir dos `Interactable` e devolve o nó.

**Prompts padrão da demo** (em pt-BR, definidos por quem cria o objeto):

| Objeto | `prompt_text` | Feature dona |
|---|---|---|
| Terminal de Distribuição | `ACESSAR TERMINAL` | F17 |
| Terminal de Distribuição sem energia | `TERMINAL SEM ENERGIA` (`enabled = false`) | F17 |
| Terminal de registros / fragmento em objeto | `LER REGISTRO` | F19 |
| Objeto do cotidiano (caneca, cadeira, foto, traje) | `EXAMINAR` | F19/F28 |
| Nó de Energia do setor | `RELIGAR NÓ DE ENERGIA` | F17/F29 |
| Parede falsa revelada | `FORÇAR PAINEL` | F27 |

**`interaction_test.tscn`:** chão simples, MU-7, três `Interactable` (dois habilitados com prompts diferentes a 20 px um do outro, um desabilitado) e um `Label` que conta `interacted` recebidos.

### Autoloads / sinais do EventBus
- Emite: `interaction_available(prompt: String)`, `interaction_cleared()`.
- Escuta: `dialogue_started` / `dialogue_finished` (para revalidar o prompt).
- Usa: `DialogueManager.is_active()` (F19; enquanto não existir, tratar como `false`), `AudioManager.play_sfx`.

### Dados (`data/`)
- Nenhum. (Os textos dos prompts são propriedades exportadas, definidas pela feature/fase dona do objeto.)

### Input actions / camadas de colisão
- Ação `interact` (E / X — [GDD-2.4](../design/GDD.md#gdd-2-4)).
- `Interactable`: layer `interactable` (4), mask 0. `InteractionSensor`: layer 0, mask `interactable` (4).

## 7. Assets necessários

| Asset id | Uso nesta feature | Placeholder |
|---|---|---|
| [UI-HUD](../ASSETS.md#ui-hud) | Ícone da tecla `[E]` (opcional no prompt textual) | Quadrado com "E" (F05) |
| [SFX-PACK](../ASSETS.md#sfx-pack) | `interact` | Beep gerado |

## 8. 🧑 Ação humana

Nenhuma.

## 9. Plano de execução

- [x] **Passo 1** — `INTERACT_RANGE` no GDD-P + Ajustes e no `balance.gd`.
- [x] **Passo 2** — `tests/test_interaction_target.gd` → falha → `scripts/core/interaction_rules.gd` → passa.
- [x] **Passo 3** — `scenes/world/interactable.gd`.
- [x] **Passo 4** — `InteractionSensor` no `mu7.tscn` + lógica de alvo/prompt/acionamento no `mu7.gd`.
- [x] **Passo 5** — Glifo por dispositivo e bloqueios (diálogo, travado, no ar).
- [x] **Passo 6** — `scenes/dev/interaction_test.tscn`; `tests/scenes.txt`.
- [x] **Passo 7** — Portões + QA.

## 10. Verificação

- **Testes (`tests/test_interaction_target.gd`):**
  - `test_pick_nearest` — três posições, a mais próxima vence.
  - `test_pick_ignores_disabled` — o mais próximo desabilitado é ignorado e vence o segundo.
  - `test_priority_beats_distance` — alvo distante com `priority = 1` vence o próximo com `priority = 0`.
  - `test_pick_none` — lista vazia ou tudo desabilitado → `-1`.
  - `test_prompt_format` — `prompt("[E]", "ACESSAR TERMINAL") == "[E] ACESSAR TERMINAL"`.
- **Smoke:** `res://scenes/dev/interaction_test.tscn`.
- **Roteiro godot-qa** (`tests/qa/f16_interaction.json`; cena `res://scenes/dev/interaction_test.tscn`):

| Frame | Input | Screenshot | O que deve aparecer |
|---:|---|---|---|
| 10 | — | `f16_01_sem_prompt` | MU-7 longe dos objetos, sem prompt no HUD |
| 11–70 | segurar `move_right` até o 1º interagível | — | — |
| 75 | — | `f16_02_prompt_a` | `[E] ACESSAR TERMINAL` no centro inferior |
| 80 | `interact` (1 frame) | — | — |
| 90 | — | `f16_03_interagiu` | Contador da cena em 1; MU-7 na animação `interact` |
| 91–130 | segurar `move_right` até o 2º interagível | — | — |
| 135 | — | `f16_04_prompt_b` | `[E] LER REGISTRO` (texto trocado) |
| 136–180 | segurar `move_right` até o desabilitado | — | — |
| 190 | — | `f16_05_desabilitado` | Sem prompt, mesmo com o MU-7 em cima do objeto |
| 200 | `jump` segurado + `interact` no ar | — | — |
| 205 | — | `f16_06_no_ar` | Contador ainda em 1 (não acionou no ar) |

- **Playtest humano (opcional):** "ficou claro o que dá para usar na sala? o prompt aparece cedo demais ou tarde demais?"

## 11. ADRs locais

### ADR-F16-001 — `INTERACT_RANGE` no Balance
- **Contexto:** o GDD não define a distância de interação.
- **Decisão:** `INTERACT_RANGE = 24` px (1,5 tile) no `Balance`, registrado no GDD-P + Ajustes.
- **Consequências:** o objeto fica "usável" quando o MU-7 está visivelmente encostado nele; sem número mágico na cena.
- **Data:** 2026-09-19

### ADR-F16-002 — Alvo por proximidade, sem mira
- **Contexto:** o chassi é lento e a resolução é pequena; exigir olhar para o objeto geraria frustração.
- **Decisão:** o alvo é o `Interactable` mais próximo do centro do MU-7 dentro do raio, com desempate por `priority`. Direção do sprite não conta.
- **Consequências:** em fases com objetos muito juntos, usar `priority` (ex.: terminal > prop decorativo).
- **Data:** 2026-09-19

### ADR-F16-003 — `interact` no chão e um acionamento por pressionada
- **Contexto:** interagir no meio de um pulo confunde o estado de animação e permite abrir terminais em lugares inesperados.
- **Decisão:** acionar exige `is_on_floor()`; o prompt continua aparecendo no ar (informação, não ação). Usa `is_action_just_pressed`, nunca `is_action_pressed`.
- **Consequências:** comportamento previsível; a F19 pode usar a mesma tecla para avançar falas sem conflito (ver F19: o diálogo ignora o frame em que começou).
- **Data:** 2026-09-19

### ADR-F16-004 — `priority` virou `interaction_priority`
- **Contexto:** `Interactable` estende `Area2D`, que **já tem** uma propriedade `priority` (float, ordem de processamento das áreas). Declarar `@export var priority: int` compila o arquivo isolado mas quebra quem o referencia de fora: `Parse Error: Could not resolve external class member "priority"` no `mu7.gd`.
- **Decisão:** a propriedade do componente chama-se `interaction_priority`. `prompt_text` e `enabled` não colidem e ficaram como estavam.
- **Consequências:** quem criar interagíveis (F17, F19, F20, F27) usa `interaction_priority`. Lição válida para qualquer componente que estenda um nó do engine: conferir o nome antes de exportar.
- **Data:** 2026-09-19

### ADR-F16-005 — `InteractionRules` fica 100% pura
- **Contexto:** o plano previa um wrapper `InteractionRules.pick(areas, origin)` no mesmo arquivo, recebendo nós.
- **Decisão:** `scripts/core/interaction_rules.gd` só recebe arrays (`pick_index`, `prompt`, `glyph`) — a regra §4.2.3 do `/CLAUDE.md` (lógica pura sem nós). A montagem dos arrays a partir de `get_overlapping_areas()` mora em `Mu7._pick_interaction_target()`.
- **Consequências:** a escolha de alvo é testável headless (8 casos em `tests/test_interaction_rules.gd`) e `scripts/core/` não depende de `scenes/`.
- **Data:** 2026-09-19

### ADR-F16-006 — Interagíveis de prova: `terminal.tscn` e `log_object.tscn`
- **Contexto:** a F16 precisa de objetos reais para provar o prompt, mas o Terminal de Distribuição é da F17 e os logs são da F19.
- **Decisão:** esta feature entrega dois interagíveis simples que já moram no lugar definitivo do `/CLAUDE.md` §4.1: `scenes/world/terminal.tscn` (`class_name Terminal`, terminal de registro — troca o frame `off`→`on` e o prompt para "LER DE NOVO" ao ser lido) e `scenes/world/log_object.tscn` (`class_name LogObject`, objeto do cotidiano com `prop_column`). Nenhum dos dois abre diálogo: quem quiser conteúdo conecta o sinal `interacted`.
- **Consequências:** a F19 pluga o `DialogueManager` no `interacted` sem reescrever a cena; a F17 herda de `Interactable` do mesmo jeito.
- **Data:** 2026-09-19

## 12. Log de evolução

> Append-only. Mais novo no fim.

### 2026-09-19 — Feature criada
- **Quem**: agente de planejamento · **O que**: documento inicial a partir do GDD · **Próximo passo**: implementação.

### 2026-09-19 — Implementada
- **Quem**: agente de implementação (lote F13/F16/F18).
- **O que**: `scripts/core/interaction_rules.gd` (pura) + `tests/test_interaction_rules.gd` (8 casos); `scenes/world/interactable.gd` (`class_name Interactable`, camada 4, sinal `interacted`, `set_enabled`/`set_prompt`); nó `InteractionSensor` no `mu7.tscn` com raio de `Balance.INTERACT_RANGE` aplicado por código; alvo, prompt e acionamento no `mu7.gd`; glifo `[E]`/`[X]` pelo último dispositivo visto em `_input`; bloqueio por `set_input_locked`, morte, knockback e `DialogueManager.is_active()`. Interagíveis de prova `terminal.tscn` e `log_object.tscn`. Sala `tests/qa/scenes/interaction_sandbox.tscn`, roteiro `tests/qa/f16_interacao.json`.
- **Portões**: import 0 erros · 272 testes passando · smoke 36/36 · varreduras vazias.
- **QA visual** (6 capturas lidas pelo agente): longe dos objetos não há prompt e o contador marca "INTERAÇÕES 0"; ao encostar no terminal aparece **`[E] ACESSAR TERMINAL`** no centro inferior; `interact` leva o contador a 1, acende a tela do terminal e **troca o prompt para `[E] LER DE NOVO`** (prova da troca de texto em runtime); andando mais um pouco o prompt vira **`[E] LER REGISTRO`** (objeto de log) sem piscar duas vezes; **no ar o prompt continua visível e o contador não sobe** (acionamento exige `is_on_floor()`); em cima do interagível desabilitado não há prompt nenhum.
- **Pendências**: o prompt é desenhado por um `Label` da sala de prova — o HUD real é da F15, que escuta `interaction_available`/`interaction_cleared`. O glifo `[X]` foi validado só por teste unitário (`InteractionRules.glyph(true)`), sem controle físico na máquina de QA.
- **Próximo passo**: F17 (Terminal de Distribuição), F19 (logs/diálogo) e F20 conectam `interacted`.
