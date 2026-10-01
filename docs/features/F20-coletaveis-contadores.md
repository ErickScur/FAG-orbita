---
id: F20
title: Coletáveis & contadores
status: done
scope: demo
block: 2
priority: P0
rubric: ["Coleta de itens", "Score de jogador (placar/contadores)", "Itens e inventário", "Recompensas"]
depends_on: ["F02", "F13", "F15", "F19", "F21"]
unblocks: ["F10", "F27", "F28", "F29", "F33"]
estimate: 2h
last_updated: 2026-09-19
---

# F20 — Coletáveis & contadores

## 1. Contexto e objetivo

Explorar a estação tem que valer a pena — e custar tempo de reator. Esta feature entrega os cinco coletáveis da demo (**Célula de Energia**, **Kit de Solda**, **Fragmento de Log**, **Dado de Pesquisa**, **Núcleo de Capacitor**), a regra de que **nada reaparece** depois de coletado (`GameState.collected_ids`), os contadores `LOGS nn/24` e `DADOS nn/12` do HUD e as **estatísticas** que a tela de fim de jogo mostra (tempo, logs, dados, mortes).

Os Fragmentos de Log são narrativa + 0,5% de estabilidade; os Dados de Pesquisa são a **coleta opcional** que, no jogo completo, muda o epílogo — na demo eles são o "score" do jogador. É o pilar **DESCOBERTA** virando número na tela.

Vale quatro itens da rubrica (Coleta de itens, Score, Itens e inventário, Recompensas).

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.6.3 Itens e coletáveis](../design/GDD.md#gdd-2-6-3) (tabela canônica de efeitos e quantidades) · [GDD-2.8 HUD](../design/GDD.md#gdd-2-8-hud) (contadores no inferior direito) · [GDD-2.8 Telas](../design/GDD.md#gdd-2-8-telas) (tela 8: estatísticas — tempo, logs, dados, mortes) · [GDD-2.3 Loop principal](../design/GDD.md#gdd-2-3-macro) (passo 6: coletar) · [GDD-2.9 SFX](../design/GDD.md#gdd-2-9-sfx)
- **Parâmetros:** `Balance.ENERGY_CELL_CHARGE` (40), `Balance.REPAIR_KIT_INTEGRITY` (25), `Balance.CAPACITOR_BONUS` (25), `Balance.LOGS_TOTAL` (24), `Balance.RESEARCH_TOTAL` (12), `Balance.REACTOR_LOG_BONUS` (via F14) — [GDD-P](../design/GDD.md#gdd-p). Novos (ADR-F20-002): `PICKUP_BOB_AMPLITUDE`, `PICKUP_BOB_SPEED`
- **Jornada:** [Etapa 5 — Testes e Aliados](../design/JORNADA-DO-HEROI.md#jh-5) (Dados de Pesquisa: coordenadas, leituras atmosféricas, mapas de solo — coleta opcional que pesa no final) · [Etapa 3 — Mentor](../design/JORNADA-DO-HEROI.md#jh-3)
- **ADRs:** [ADR-004](../DECISIONS.md#adr-004) (entidades por caractere + parâmetros no JSON) · [ADR-006](../DECISIONS.md#adr-006)
- **Assets:** [SPR-PICKUPS](../ASSETS.md#spr-pickups) · [UI-HUD](../ASSETS.md#ui-hud) · [SFX-PACK](../ASSETS.md#sfx-pack)

## 3. Critério de avaliação atendido

- **Coleta de itens:** encostar num item recolhe, com som, toast e efeito imediato.
- **Score de jogador (placar/contadores):** `LOGS nn/24` e `DADOS nn/12` sempre na tela + estatísticas finais.
- **Itens e inventário:** cinco tipos com efeitos distintos; o "inventário" da demo é o estado persistente (`collected_ids`, `logs_collected`, `research_collected`, `abilities`).
- **Recompensas:** Célula (+40 Carga), Kit (+25 Integridade), Capacitor (+25 Carga máxima permanente), Log (+0,5% de reator).

**Como o avaliador vê:** o apresentador pega uma Célula com a Carga baixa (barra salta), um Fragmento de Log (contador 01/24, log abre, reator sobe) e um Dado (02/12); no FIM DA DEMO as estatísticas aparecem.

## 4. Escopo

### Inclui
- `scenes/world/collectible.tscn` (+ `.gd`): um único `Area2D` configurável por `kind` (`cell`, `repair_kit`, `log`, `research`, `capacitor`), com animação de brilho/flutuação da folha [SPR-PICKUPS](../ASSETS.md#spr-pickups).
- Ids estáveis por item (`item_id`), vindos do JSON da fase ou gerados de forma determinística pela posição (`<fase>_<char>_<x>_<y>`), para que **não reapareçam** após coletados.
- `GameState.register_pickup(kind, item_id) -> bool` (extensão do contrato, ADR-F20-001): grava em `collected_ids`, alimenta `logs_collected`/`research_collected` e emite `collectible_picked`.
- Regras de efeito por tipo (tabela §6.3), incluindo **não coletar** Célula/Kit com o recurso já cheio.
- Contadores no HUD (a F15 já escuta `collectible_picked`; aqui garantimos os dados corretos) + toasts.
- Estatísticas: `scripts/core/stats.gd` (`format_time`, `summary`) consumido pela tela FIM DA DEMO e pelo Game Over (F10); `GameState.play_time` acumulado durante o gameplay.
- Persistência: tudo entra no `to_dict()/from_dict()` da F11 (conferir que os arrays são serializados como strings).
- Integração com o `LevelBuilder` (F21): caracteres `c`, `k`, `l`, `r`, `C`.

### Não inclui
- Placa de Blindagem (+25 Integridade máxima) — Final (F49); o `kind` fica previsto no código mas sem item na demo.
- Chave de Acesso (1 por setor) — Final (a demo usa porta ligada à energia).
- Arquivo de Logs / codex navegável — stretch F33.
- Tela de fim em si — F10 (aqui só entregamos `Stats.summary`).
- Epílogo variando por Dados — Final (F46).
- Inventário com UI, slots ou uso manual de item — fora de escopo (itens são instantâneos).

## 5. Critérios de aceite

- [x] Encostar numa **Célula** com Carga < máxima: `+Balance.ENERGY_CELL_CHARGE`, SFX `pickup`, toast `+40 CARGA`, item some e **não** volta ao recarregar a fase.
- [x] Com a Carga cheia, a Célula **não** é coletada (continua no mundo).
- [x] **Kit de Solda**: `+Balance.REPAIR_KIT_INTEGRITY` de Integridade (sem passar do máximo); não coleta com Integridade cheia.
- [x] **Núcleo de Capacitor**: `charge_max += Balance.CAPACITOR_BONUS`, Carga enche até o novo máximo, toast `CAPACIDADE MÁXIMA +25`, HUD reflete a barra maior; sempre coletável.
- [x] **Fragmento de Log**: registra, abre o log correspondente (F19), contador `LOGS nn/24`, +0,5% de reator (F14); pegar duas vezes é impossível.
- [x] **Dado de Pesquisa**: contador `DADOS nn/12`, toast `DADO DE PESQUISA nn/12`, nenhum efeito de gameplay.
- [x] Morrer e renascer, ou salvar e carregar, mantém todos os itens já coletados fora do mundo.
- [x] `RunStats.format_time(754.2) == "12:34"` (ADR-F20-006); `GameState.get_stats()` alimenta a tela de fim com tempo, logs, dados, mortes e segredos.
- [x] `GameState.play_time` só corre em gameplay (`is_in_level()`, já vindo da F14).
- [x] Todos os itens têm id único na demo (`tests/test_level_item_ids.gd`, varre `data/levels/*.txt` + `*.json`).
- [x] Portões do `/CLAUDE.md` §6 verdes
- [x] Sem comentários no código; nada 3D

## 6. Definição técnica

### 6.1 Cenas e scripts
```
scenes/world/collectible.tscn (+ .gd)   class_name Collectible
scripts/core/pickup_rules.gd            class_name PickupRules (pura: pode coletar? linha da folha, SFX, id)
scripts/core/run_stats.gd               já existe (F10) — reutilizado no lugar de um Stats novo (ADR-F20-006)
autoload/game_state.gd                  (+ get_stats, expand_charge_max; register_pickup/play_time já existiam)
autoload/dialogue_manager.gd            (+ registro do log em open_log — caminho único, ADR-F20-001)
scenes/ui/hud.gd                        (kind canônico, PickupRules.amount_for, moldura de Carga elástica)
scripts/core/level_builder.gd           (default_item_id delega para PickupRules)
tests/test_pickup_rules.gd
tests/test_collectible.gd
tests/test_level_item_ids.gd
tests/test_game_state.gd                (+ get_stats, expand_charge_max, capacitor no save)
scenes/dev/pickup_test.tscn (+ .gd)
tests/qa/f20_pickups.json
```

### 6.2 `collectible.tscn`
```
Collectible (Area2D)          script collectible.gd · layer pickup (6) · mask player (2)
├─ CollisionShape2D           RectangleShape2D 12×12
└─ AnimatedSprite2D           SPR-PICKUPS, 16×16, 1 linha por tipo, 4f de brilho, autoplay
```
```gdscript
@export var kind: StringName = &"cell"
@export var item_id: StringName = &""
@export var log_id: StringName = &""

func configure(params: Dictionary) -> void
```
- `configure` recebe do `LevelBuilder` (F21): `kind` (derivado do caractere), `item_id` (do JSON da fase ou gerado), `log_id` (para `kind == &"log"`; default = `item_id`).
- `_ready()`: se `GameState.collected_ids.has(item_id)` → `queue_free()` antes de aparecer; senão toca a linha da animação do tipo e inicia o "bob" (`position.y` com `sin`, `PICKUP_BOB_AMPLITUDE`/`PICKUP_BOB_SPEED`).
- `body_entered(body)`: se `body.is_in_group(&"player")` e `PickupRules.can_collect(kind, GameState.charge, GameState.charge_max, GameState.integrity, GameState.integrity_max)` → aplica efeito, `GameState.register_pickup(kind, item_id)`, SFX, `queue_free()`.

### 6.3 Regras por tipo

| `kind` | Char ASCII | Efeito | Coleta bloqueada quando | SFX | Toast |
|---|:--:|---|---|---|---|
| `cell` | `c` | `GameState.add_charge(Balance.ENERGY_CELL_CHARGE)` | Carga cheia | `pickup` | `+40 CARGA` |
| `repair_kit` | `k` | `GameState.repair(Balance.REPAIR_KIT_INTEGRITY)` | Integridade cheia | `pickup` | `+25 INTEGRIDADE` |
| `log` | `l` | `DialogueManager.open_log(log_id)` (que registra a coleta) | — | `log_pickup` | `FRAGMENTO DE LOG nn/24` |
| `research` | `r` | nenhum (só contador) | — | `pickup` | `DADO DE PESQUISA nn/12` |
| `capacitor` | `C` | `charge_max += Balance.CAPACITOR_BONUS`; `add_charge(CAPACITOR_BONUS)` | — | `pickup` | `CAPACIDADE MÁXIMA +25` |

> Para `kind == &"log"`, quem registra é o `DialogueManager` (ADR-F19-004) — o coletável apenas abre o log e se destrói **se** o registro ocorreu (log inédito) ou se já estava coletado.

### 6.4 `pickup_rules.gd` e `stats.gd` (puras)
```gdscript
class_name PickupRules
extends RefCounted

static func can_collect(kind: StringName, charge: float, charge_max: float,
        integrity: int, integrity_max: int) -> bool
static func toast_text(kind: StringName, amount: int, count: int, total: int) -> String
static func default_item_id(level_id: String, symbol: String, cell: Vector2i) -> StringName
```
`default_item_id` → `"%s_%s_%d_%d" % [level_id, symbol_name, cell.x, cell.y]` (ex.: `greenhouse_r_28_11`).

```gdscript
class_name Stats
extends RefCounted

static func format_time(seconds: float) -> String          # "12:34" (mm:ss, horas viram minutos)
static func summary(state: Dictionary) -> Dictionary       # {time, logs, logs_total, research, research_total, deaths, sectors}
static func percent(collected: int, total: int) -> int
```
`summary` recebe `GameState.to_dict()` (ou um dicionário equivalente) — assim o teste não precisa de autoload.

### 6.5 `GameState` (extensões desta feature)
```gdscript
var play_time: float = 0.0

func register_pickup(kind: StringName, item_id: StringName) -> bool
func get_stats() -> Dictionary
```
- `register_pickup`: se `collected_ids.has(item_id)` → `false`. Senão adiciona; se `kind == &"log"` e não estiver em `logs_collected`, adiciona; se `kind == &"research"`, adiciona em `research_collected`; emite `EventBus.collectible_picked(kind, item_id)`; `true`.
- `play_time` acumulado no mesmo `_process` do reator (F14), com a mesma condição de "está em gameplay" (cena no grupo `level`), **sem** congelar por diálogo (tempo de jogo é tempo real jogado; o timer do reator é que congela).
- `get_stats()` → `Stats.summary(to_dict())`.

### 6.6 Textos na tela de fim (consumidos pela F10)
```
TEMPO: 12:34      MORTES: 2
FRAGMENTOS DE LOG: 06/24
DADOS DE PESQUISA: 03/12
SETORES RELIGADOS: 1
```
A F10 monta o layout; a F20 garante os números via `GameState.get_stats()`.

### 6.7 Autoloads / sinais do EventBus
- Emite: `collectible_picked(kind, item_id)`.
- Escuta: nada (o HUD e o reator é que escutam).
- Usa: `GameState`, `Balance`, `AudioManager.play_sfx`, `DialogueManager.open_log`.

### 6.8 Dados (`data/`)
- JSON da fase (F21), por coordenada: `{"id": "log_gh_01"}` em um `l`, `{"id": "data_gh_02"}` em um `r`. Sem `id`, o builder usa `PickupRules.default_item_id`.
- Ids de log **devem** existir em `data/logs/*.json` (validado no teste da F19 e no `test_level_item_ids`).

### 6.9 Input actions / camadas de colisão
- Sem input (coleta por contato).
- `Collectible`: layer `pickup` (6), mask `player` (2), `monitoring = true`.

## 7. Assets necessários

| Asset id | Uso nesta feature | Placeholder |
|---|---|---|
| [SPR-PICKUPS](../ASSETS.md#spr-pickups) | 5 linhas de 16×16 com 4f de brilho (Célula, Kit, Log, Dado, Capacitor) | Losangos coloridos (F05) |
| [UI-HUD](../ASSETS.md#ui-hud) | Ícones Log e Dado dos contadores | Quadrados (F05) |
| [SFX-PACK](../ASSETS.md#sfx-pack) | `pickup`, `log_pickup` | Beeps gerados |

## 8. 🧑 Ação humana

Nenhuma.

## 9. Plano de execução

- [x] **Passo 1** — `PICKUP_BOB_AMPLITUDE`/`PICKUP_BOB_SPEED` no `balance.gd` (pendência: espelhar em GDD-P/Ajustes — o agente não edita `docs/design/`).
- [x] **Passo 2** — `tests/test_pickup_rules.gd` + `scripts/core/pickup_rules.gd`; `Stats` virou `RunStats` (ADR-F20-006).
- [x] **Passo 3** — `GameState.get_stats()` e `GameState.expand_charge_max()` (`register_pickup`/`play_time` já vinham da F13/F14).
- [x] **Passo 4** — `collectible.tscn` + `collectible.gd` com os 5 tipos, bob e auto-destruição quando já coletado.
- [x] **Passo 5** — `c`, `k`, `l`, `r`, `C` já mapeados no `LevelBuilder` (F21); `default_item_id` passou a delegar para `PickupRules`.
- [x] **Passo 6** — Toasts/contadores conferidos com a F15 (kind canônico `cell`, ADR-F20-008); log integrado com a F19; reator com a F14.
- [x] **Passo 7** — `tests/test_level_item_ids.gd` (ids únicos entre fases e logs existentes).
- [x] **Passo 8** — `scenes/dev/pickup_test.tscn`; `res://scenes/world/collectible.tscn` e `res://scenes/dev/pickup_test.tscn` em `tests/scenes.txt`.
- [x] **Passo 9** — Portões verdes (348 testes, 43 cenas no smoke) + QA visual com 11 screenshots.

## 10. Verificação

- **Testes (`tests/test_pickup_rules.gd`):**
  - `test_cell_blocked_when_full` — `can_collect(&"cell", 100, 100, …) == false`; com 60 → `true`.
  - `test_kit_blocked_when_full` — idem para Integridade.
  - `test_log_research_capacitor_always` — sempre `true`.
  - `test_toast_texts` — `toast_text(&"cell", 40, 0, 0) == "+40 CARGA"`; `toast_text(&"research", 0, 3, 12) == "DADO DE PESQUISA 03/12"`.
  - `test_default_item_id_stable` — mesma fase/char/célula → mesmo id; células diferentes → ids diferentes.
- **Testes (`tests/test_stats.gd`):**
  - `test_format_time` — `format_time(0) == "00:00"`; `format_time(754.2) == "12:34"`; `format_time(3725) == "62:05"`.
  - `test_summary_fields` — dicionário com `time`, `logs`, `logs_total`, `research`, `research_total`, `deaths`, `sectors`.
  - `test_percent` — `percent(6, 24) == 25`; `percent(0, 12) == 0`.
- **Testes (`tests/test_level_item_ids.gd`):**
  - `test_item_ids_unique_across_levels` — varre `data/levels/*.json` e falha se houver id repetido.
  - `test_log_items_reference_existing_logs` — todo `l` com `id` aponta para um log existente em `data/logs/`.
- **Smoke:** `res://scenes/world/collectible.tscn`, `res://scenes/dev/pickup_test.tscn`.
- **Roteiro godot-qa** (`tests/qa/f20_pickups.json`; cena `res://scenes/dev/pickup_test.tscn`: MU-7 com Carga 30 e Integridade 60, e na ordem — Célula, Kit, Dado, Fragmento de Log, Capacitor):

| Frame | Input | Screenshot | O que deve aparecer |
|---:|---|---|---|
| 10 | — | `f20_01_inicial` | 5 itens flutuando; HUD `LOGS 00/24`, `DADOS 00/12`, Carga baixa |
| 11–60 | segurar `move_right` (pega a Célula) | `f20_02_celula` | Toast `+40 CARGA`, barra de Carga maior, item sumiu |
| 61–110 | continuar (Kit) | `f20_03_kit` | Toast `+25 INTEGRIDADE`, células do HUD cheias |
| 111–160 | continuar (Dado) | `f20_04_dado` | `DADOS 01/12` + toast |
| 161–210 | continuar (Fragmento de Log) | `f20_05_log` | Caixa de diálogo do log aberta (F19) |
| 211–300 | `interact` até fechar | `f20_06_contador_log` | `LOGS 01/24`, reator +0,5% |
| 301–350 | continuar (Capacitor) | `f20_07_capacitor` | Toast `CAPACIDADE MÁXIMA +25`, barra de Carga mais longa e cheia |
| 360 | (a cena recarrega a si mesma) | `f20_08_nao_voltam` | Nenhum item no mundo; contadores mantidos |

- **Playtest humano (opcional):** "os contadores fazem você querer voltar e procurar mais? o tempo do reator te fez desistir de algum item?"

## 11. ADRs locais

### ADR-F20-001 — `GameState.register_pickup` como ponto único de coleta
- **Contexto:** logs podem ser coletados por fragmento (`l`) **ou** lidos num terminal (`L`); contador, reator e save precisam concordar.
- **Decisão:** um método só no `GameState` (extensão do contrato) registra qualquer coleta, deduplica por `collected_ids` e emite `collectible_picked`. Ninguém mexe nos arrays diretamente.
- **Consequências:** F14 (reator), F15 (HUD), F11 (save) e F33 (codex) leem a mesma fonte. Registrar no log da F02.
- **Data:** 2026-09-19

### ADR-F20-002 — Constantes de apresentação do coletável
- **Contexto:** a flutuação do item não está no GDD.
- **Decisão:** `PICKUP_BOB_AMPLITUDE = 2` px e `PICKUP_BOB_SPEED = 2.0` rad/s no `Balance` + GDD-P/Ajustes.
- **Consequências:** itens legíveis a 384×216 sem número mágico.
- **Data:** 2026-09-19

### ADR-F20-003 — Célula e Kit não são coletados com o recurso cheio
- **Contexto:** o GDD não diz o que acontece ao pegar uma Célula com 100 de Carga; desperdiçar um recurso escasso frustra.
- **Decisão:** o item permanece no mundo até ser útil.
- **Consequências:** coerente com ESCASSEZ; o jogador aprende a "guardar" recursos no mapa. Registrar em Ajustes.
- **Data:** 2026-09-19

### ADR-F20-004 — Ids determinísticos por posição quando o JSON não define
- **Contexto:** `collected_ids` precisa de um id estável, mas anotar todo item no JSON da fase é trabalhoso.
- **Decisão:** sem `id` no JSON, o builder gera `<fase>_<char>_<x>_<y>`. Itens narrativos (logs) **devem** ter id explícito.
- **Consequências:** mover um item no `.txt` "reseta" a coleta dele (aceitável em desenvolvimento; teste garante unicidade).
- **Data:** 2026-09-19

### ADR-F20-006 — `RunStats` no lugar de um `Stats` novo
- **Contexto:** a F10 já entregou `scripts/core/run_stats.gd` (`format_time`, `summary_rows`, `summary_lines`, `secrets_found`, `unread_logs_line`) e as telas de fim já o consomem.
- **Decisão:** não criar `scripts/core/stats.gd`. `GameState.get_stats()` monta o dicionário do §6.6 chamando `RunStats`, que continua sendo a única fonte de formatação.
- **Consequências:** o §6.4 da feature fica obsoleto; `get_stats()` devolve `time`, `time_text`, `logs`, `logs_total`, `research`, `research_total`, `deaths`, `secrets`, `secrets_total`, `sectors`, `rows` e `lines`. `percent()` não foi necessário para a demo.
- **Data:** 2026-09-19

### ADR-F20-007 — Texto de toast continua em `data/hud_texts.json`
- **Contexto:** o §6.4 previa `PickupRules.toast_text`, mas a F15 já monta os toasts a partir de `data/hud_texts.json` (`toast_charge`, `toast_integrity`, `toast_capacity`, `toast_log`, `toast_research`).
- **Decisão:** `PickupRules` não formata texto de jogador. Ele expõe `amount_for(kind)` e o HUD escolhe o template.
- **Consequências:** regra dura 7 (texto do jogador em `data/`) preservada; uma única fonte de texto e nenhum pt-BR dentro de lógica pura.
- **Data:** 2026-09-19

### ADR-F20-008 — `cell` é o `kind` canônico da Célula de Energia
- **Contexto:** o `LevelBuilder` (F21) emitia `&"cell"` e o HUD (F15) esperava `&"energy_cell"`; o toast `+40 CARGA` nunca apareceria.
- **Decisão:** `cell` é o nome canônico (é o que o GDD e a legenda ASCII usam). `PickupRules.KIND_*` passa a ser a fonte dos nomes e o HUD importa as constantes em vez de repetir literais.
- **Consequências:** `scenes/ui/hud.gd` alterado em duas linhas; `PickupRules.amount_for` substituiu o `match` duplicado do HUD.
- **Data:** 2026-09-19

### ADR-F20-009 — `GameState.expand_charge_max` e moldura de Carga elástica
- **Contexto:** o Capacitor aumenta a Carga **máxima**; mexer em `charge_max` direto na cena violaria a fronteira "estado da run vive no GameState", e a moldura de 72 px do HUD não mostrava ganho nenhum.
- **Decisão:** método `expand_charge_max(value)` no `GameState` (sobe o teto, enche a diferença e emite `charge_changed`) e `HudModel`/HUD redimensionam a moldura para `72 px × charge_max / Balance.CHARGE_MAX`, reposicionando a marca de custo do dash.
- **Consequências:** a barra fica visivelmente mais longa (72 → 90 px com um Capacitor); `from_dict` já restaura `charge_max`, então o bônus sobrevive ao save sem código novo.
- **Data:** 2026-09-19

### ADR-F20-005 — `play_time` não congela em diálogo
- **Contexto:** o timer do reator congela em diálogo/log; a estatística "tempo de jogo" mediria outra coisa se congelasse junto.
- **Decisão:** `play_time` acumula em qualquer momento de gameplay (menos pause e telas), inclusive durante diálogos.
- **Consequências:** a estatística final é o tempo real de sessão; o reator continua sendo a moeda de pressão.
- **Data:** 2026-09-19

## 12. Log de evolução

> Append-only. Mais novo no fim.

### 2026-09-19 — Feature criada
- **Quem**: agente de planejamento · **O que**: documento inicial a partir do GDD · **Próximo passo**: implementação.

### 2026-09-19 — Implementação
- **Quem**: agente de implementação
- **O que**: `scripts/core/pickup_rules.gd` (lógica pura: `can_collect`, `sheet_row`, `sfx_for`, `amount_for`, `default_item_id`); `scenes/world/collectible.tscn` + `.gd` (`Area2D` na camada `pickup`, 5 tipos com a linha certa do `SPR-PICKUPS` via `AssetResolver`, flutuação com `Balance.PICKUP_BOB_*`, SFX, auto-destruição quando o id já está em `collected_ids`); `GameState.get_stats()` e `GameState.expand_charge_max()`; `DialogueManager.open_log()` passou a registrar a coleta do log (caminho único para o fragmento `l` e para o terminal `L`, sem contagem dupla); HUD com o `kind` canônico `cell` e moldura de Carga elástica; `LevelBuilder.default_item_id` delegando para `PickupRules`; cena de QA `scenes/dev/pickup_test.tscn`; suítes `test_pickup_rules`, `test_collectible`, `test_level_item_ids` e novos casos em `test_game_state`.
- **Portões**: import limpo · **348 passed, 0 failed** · smoke 43 cenas OK · varreduras 3D e de comentários vazias.
- **QA visual** (`tests/qa/f20_pickups.json`, cena `pickup_test`, 11 screenshots): itens flutuando com HUD `LOGS 00/24`/`DADOS 00/12` e Carga 30/100; Célula → toast `+40 CARGA`, barra sobe para 70/100, item some; Kit → `+25 INTEGRIDADE` (60 → 85, a quarta célula do HUD deixa de piscar em vermelho); Dado → `DADO DE PESQUISA 01/12` e contador `DADOS 01/12`; Fragmento de Log → caixa do log aberta, toast `FRAGMENTO DE LOG 01/24`, reator 80% → **81%** (o +0,5% da F14) e estado `congelado`; terminal `L` do mundo → `FRAGMENTO DE LOG 02/24`, provando que ler um log conta pelo mesmo caminho; Capacitor → `CAPACIDADE MÁXIMA +25`, `CARGA 95/125` e moldura da barra visivelmente mais longa; ao recarregar a cena nenhum item volta e os contadores/teto de Carga permanecem.
- **Divergências abertas**: (a) `PICKUP_BOB_AMPLITUDE = 2.0` e `PICKUP_BOB_SPEED = 2.0` estão no `balance.gd` mas ainda **não** na tabela GDD-P nem em Ajustes (ADR-F20-002 pede as duas linhas; o agente não edita `docs/design/`); (b) [AJ-009](../design/GDD.md#gdd-ajustes) (Célula/Kit não consumidos com o recurso cheio) está implementado e testado, falta a linha em Ajustes; (c) o §6.4 do documento (classe `Stats`, `PickupRules.toast_text`, `percent`) ficou obsoleto — ver ADR-F20-006 e ADR-F20-007.
- **Próximo passo**: F27 (segredos) e F33 (codex) consomem `collected_ids`/`get_stats()` sem mudanças.

### 2026-09-20 — revisto pela [F37](F37-legibilidade-hud.md)
- Os cinco coletáveis eram o mesmo losango em cinco cores e o jogador não sabia o que eram ("oq são essas coisas azuis no chao e as laranjas"). Cada tipo ganhou silhueta própria, o ícone do contador repete essa silhueta, e a **primeira** coleta de cada tipo mostra nome e função. Totais da demo agora 4 logs / 4 dados ([AJ-024](../design/GDD.md#gdd-ajustes)).
