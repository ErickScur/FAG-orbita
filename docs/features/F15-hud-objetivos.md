---
id: F15
title: HUD & objetivo atual
status: done
scope: demo
block: 2
priority: P0
rubric: ["HUD", "Missões primárias"]
depends_on: ["F02", "F05", "F13", "F14"]
unblocks: ["F16", "F17", "F19", "F20", "F23", "F28", "F29"]
estimate: 2.5h
last_updated: 2026-09-19
---

# F15 — HUD & objetivo atual

## 1. Contexto e objetivo

O HUD do ÓRBITA é **minimalista e diegético**: parece a leitura de sensor do próprio chassi. Mostra Integridade em 4 células, Carga, ícones de status, Estabilidade do Reator, contadores de Fragmentos de Log e Dados de Pesquisa, o prompt de interação contextual e o **objetivo atual** ("missão primária").

Ele é a janela do jogador para todos os sistemas da demo: sem HUD, o dano da F13, o timer da F14, a coleta da F20 e a interação da F16 ficam invisíveis. É também onde o avaliador "vê" metade da rubrica acontecendo.

Serve ao pilar **ESCASSEZ** (tudo que o HUD mostra é um recurso acabando).

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.8 HUD](../design/GDD.md#gdd-2-8-hud) (layout ASCII e tabela de regiões — **seguir literalmente**) · [GDD-2.6.1 Status base](../design/GDD.md#gdd-2-6-1-status) · [GDD-2.6.2-F Status](../design/GDD.md#gdd-2-6-2-f) (ícones com contador) · [GDD-2.6.3 Itens](../design/GDD.md#gdd-2-6-3) (24 logs, 12 dados) · [GDD-2.9 Estilo visual](../design/GDD.md#gdd-2-9-visual)
- **Parâmetros:** `Balance.INTEGRITY_CELLS`, `Balance.INTEGRITY_MAX`, `Balance.CHARGE_MAX`, `Balance.REACTOR_CRITICAL`, `Balance.LOGS_TOTAL`, `Balance.RESEARCH_TOTAL` — [GDD-P](../design/GDD.md#gdd-p). Novos (ADR-F15-001): `HUD_TOAST_TIME`, `HUD_PULSE_HZ`, `LOW_INTEGRITY_BEEP_INTERVAL`
- **Jornada:** [Etapa 2 — Chamado](../design/JORNADA-DO-HEROI.md#jh-2) (objetivo mensurável: estabilizar o reator)
- **ADRs:** [ADR-003](../DECISIONS.md#adr-003) (384×216, fonte pixel) · [ADR-005](../DECISIONS.md#adr-005)
- **Assets:** [UI-HUD](../ASSETS.md#ui-hud) · [UI-FONT](../ASSETS.md#ui-font) · [SFX-PACK](../ASSETS.md#sfx-pack) (`low_integrity`)

## 3. Critério de avaliação atendido

- **HUD:** a tela do GDD-2.8 implementada — integridade, carga, status, reator, contadores, prompt.
- **Missões primárias:** o texto do **objetivo atual** sempre visível ("Estabilizar o reator: religar a Estufa"), atualizado por diálogo/eventos.

**Como o avaliador vê:** durante toda a demo o HUD acompanha a ação; ao pegar um log, o contador vai de 00/24 para 01/24 com um toast; ao aceitar o chamado, o objetivo muda na tela.

## 4. Escopo

### Inclui
- `scenes/ui/hud.tscn` (+ `hud.gd`), `CanvasLayer` instanciado pelo `level_base` (F21) em toda fase.
- Integridade: 4 células (`Vitals.cell_states`), célula vazia **vermelha piscando**.
- Carga: barra azul com valor; marcação do custo da próxima habilidade **só se** a habilidade existir (`abilities` contém `dash` — F31); sem ela, sem marcação.
- Ícones de status com contador regressivo (`status_applied` / `status_cleared`), até 4 lado a lado.
- Estabilidade do Reator: `ESTABILIDADE DO REATOR: NN%` + barra + estado (`descendo` / `congelado` / `SEM TIMER`); pulsa em vermelho quando `reactor_critical(true)`; oculta enquanto `flags.reactor_online == false`.
- Contadores `LOGS nn/24` e `DADOS nn/12` (inferior direito).
- Prompt de interação (centro inferior) via `interaction_available` / `interaction_cleared`; escondido durante diálogo.
- Objetivo atual (superior direito), via `objective_changed`; textos em `data/objectives.json`; helper puro `scripts/core/objectives.gd` + `GameState.set_objective(id)`.
- **Toasts** curtos (centro superior): `+40 CARGA`, `+25 INTEGRIDADE`, `FRAGMENTO DE LOG 01/24`, `DADO DE PESQUISA 01/12`, `OBJETIVO ATUALIZADO`, `CAPACIDADE MÁXIMA +25`.
- Bipe `low_integrity` enquanto a Integridade estiver em 1 célula ou menos.
- Reação a `game_paused(true)` (o HUD continua visível; toasts pausam junto com a árvore).

### Não inclui
- Caixa de legenda/diálogo (`dialogue_box.tscn`) — F19 (CanvasLayer próprio, acima do HUD).
- Menu de pause, opções — F09/F08.
- Mapa (TAB) e Arquivo de Logs (L) — Final (F47) / stretch (F33).
- Barra de boss, ícones de habilidade — Final.
- Lógica de coleta, dano, reator — F20/F13/F14 (aqui só se **escuta**).

## 5. Critérios de aceite

- [x] Com 100/100 de Integridade: 4 células cheias; com 60: 2 cheias, 1 parcial, 1 vazia piscando; com 0: 4 vazias.
- [x] A barra de Carga acompanha `charge_changed` na hora (lanterna drenando mostra queda contínua).
- [x] `status_applied(&"corrosion", 6.0)` mostra o ícone com contagem 6…0 e some sozinho; `status_cleared` remove antes da hora.
- [x] O bloco do reator só aparece depois que `flags.reactor_online` fica verdadeiro; mostra o inteiro `ceil` igual ao `ReactorClock.display_percent`.
- [x] `reactor_critical(true)` deixa percentual e barra pulsando em vermelho a `HUD_PULSE_HZ`; `(false)` volta ao normal.
- [x] Modo sem timer: o bloco mostra `SEM TIMER` e não pulsa.
- [x] `interaction_available("[E] ACESSAR TERMINAL")` mostra o texto centralizado embaixo; `interaction_cleared` esconde; `dialogue_started` esconde e `dialogue_finished` restaura (se ainda houver alvo).
- [x] `collectible_picked(&"log", id)` incrementa `LOGS` e mostra toast por `HUD_TOAST_TIME`; idem para `research`/`DADOS`.
- [x] `objective_changed(text)` troca o texto do objetivo e mostra o toast `OBJETIVO ATUALIZADO`; o texto persiste ao trocar de fase (vem de `GameState.current_objective`).
- [x] Todo o HUD cabe em 384×216 sem sobrepor a área jogável central e sem cortar texto com acentos.
- [x] Nada de `get_node("../..")`: o HUD só conhece o `EventBus` e o `GameState`.
- [x] Portões do `/CLAUDE.md` §6 verdes
- [x] Sem comentários no código; nada 3D

## 6. Definição técnica

### Cenas e scripts
```
scenes/ui/hud.tscn (+ hud.gd)
scripts/core/objectives.gd          class_name Objectives (carrega data/objectives.json)
autoload/game_state.gd              (+ set_objective)
data/objectives.json
tests/test_objectives.gd
scenes/dev/hud_test.tscn (+ .gd)    dispara sinais roteirizados para o QA
```

**Árvore de `hud.tscn`** (`CanvasLayer` layer 10, `process_mode = PROCESS_MODE_PAUSABLE`; todos os `Control` com `mouse_filter = IGNORE`):
```
HUD (CanvasLayer)
└─ Root (Control, anchors full)
   ├─ Vitals (VBoxContainer, offset 4,4)
   │  ├─ Cells (HBoxContainer)         4 × TextureRect 16×16 (UI-HUD)
   │  ├─ ChargeBar (TextureProgressBar 72×6) + ChargeLabel (Label "CARGA")
   │  └─ Statuses (HBoxContainer)      até 4 × (TextureRect 16×16 + Label do contador)
   ├─ Reactor (VBoxContainer, top center, largura 160)
   │  ├─ ReactorLabel (Label "ESTABILIDADE DO REATOR: 74%")
   │  ├─ ReactorBar (TextureProgressBar 140×5)
   │  └─ ReactorState (Label "descendo")
   ├─ Objective (Label, top right, largura 116, autowrap, alinhado à direita)
   ├─ Counters (VBoxContainer, bottom right, offset -4,-4)
   │  ├─ LogsLabel (Label "LOGS 00/24")
   │  └─ DataLabel (Label "DADOS 00/12")
   ├─ Prompt (Label, bottom center, y = -28, alinhado ao centro)
   └─ Toasts (VBoxContainer, top center, y = 40, alinhado ao centro)
```
Posições seguem o mockup do [GDD-2.8](../design/GDD.md#gdd-2-8-hud). Fonte: `assets/ui/theme.tres` (F05), tamanho 8 px, sem outline.

**`hud.gd` — sinais escutados:**

| Sinal | Efeito |
|---|---|
| `integrity_changed(cur, max)` | Redesenha células via `Vitals.cell_states`; liga/desliga o bipe `low_integrity` |
| `charge_changed(cur, max)` | Atualiza `ChargeBar` (`max_value = max`, `value = cur`) |
| `player_damaged(amount)` | Flash vermelho curto (0,1 s) na moldura das células |
| `status_applied(id, dur)` | Cria/atualiza ícone + contador |
| `status_cleared(id)` | Remove o ícone |
| `reactor_changed(percent)` | `ReactorLabel`/`ReactorBar`; mostra o bloco se ainda escondido |
| `reactor_critical(active)` | Liga/desliga o `Tween` de pulso vermelho |
| `collectible_picked(kind, id)` | Atualiza contadores + toast |
| `log_opened` / `log_closed` | (sem efeito no HUD; reservado) |
| `interaction_available(prompt)` / `interaction_cleared()` | Mostra/esconde `Prompt` |
| `dialogue_started` / `dialogue_finished` | Esconde/restaura `Prompt` |
| `objective_changed(text)` | Atualiza `Objective` + toast |
| `ability_unlocked(id)` | Se `id == &"dash"`, liga a marcação de custo na barra de Carga |
| `game_paused(paused)` | Pausa/retoma o `Tween` de pulso |

No `_ready()` o HUD **lê o estado atual do `GameState`** (integridade, carga, reator, contadores, objetivo, statuses ativos) para nascer coerente após load/respawn, sem depender de sinais passados.

**Pulso crítico:** `Tween` infinito em `modulate` do `Reactor` entre branco e `Color(1, 0.3, 0.3)` a `HUD_PULSE_HZ` (2 Hz), `set_process_mode(TWEEN_PAUSE_STOP)`.

**Toasts:** `_toast(text: String)` cria um `Label`, `Tween` de `modulate:a` 1→0 em `HUD_TOAST_TIME` (2,0 s) e `queue_free()`; máximo de 3 simultâneos (o mais antigo sai).

**Contadores:** `LOGS %02d/%02d` com `GameState.logs_collected.size()` e `Balance.LOGS_TOTAL`; `DADOS %02d/%02d` com `research_collected` e `Balance.RESEARCH_TOTAL`.

**Objetivos** (`scripts/core/objectives.gd`, pura — só `FileAccess`/`JSON`):
```gdscript
class_name Objectives
extends RefCounted

const PATH := "res://data/objectives.json"

static func load_all(path: String = PATH) -> Dictionary
static func text_for(id: StringName, table: Dictionary) -> String
```
`text_for` devolve `""` para id desconhecido (o chamador ignora e emite `push_warning`).

`GameState.set_objective(id: StringName)` (extensão do contrato, ADR-F15-002): resolve o texto, guarda em `current_objective` e emite `EventBus.objective_changed(text)`.

**`data/objectives.json`** (demo):
```json
{
  "obj_calibrate": "Calibrar o chassi MU-7",
  "obj_read_log": "Acessar o terminal de registros do Núcleo",
  "obj_open_habitat": "Abrir a porta do Setor Habitacional no Terminal de Distribuição",
  "obj_reach_greenhouse": "Atravessar o Setor Habitacional até a Estufa",
  "obj_find_terminal_gh": "Encontrar o Terminal de Distribuição da Estufa",
  "obj_reach_node": "Chegar à câmara do Nó de Energia",
  "obj_restore_gh": "Religar o Nó de Energia da Estufa",
  "obj_demo_exit": "Seguir para a saída da Estufa"
}
```

**Bipe de integridade baixa:** quando `cell_states` tiver no máximo 1 célula não vazia e o jogador estiver vivo, chamar `AudioManager.play_sfx("low_integrity")` a cada `LOW_INTEGRITY_BEEP_INTERVAL` (1,5 s) por um `Timer` interno; parar ao subir ou ao morrer.

**`hud_test.tscn`:** nó no grupo `level` que instancia o HUD e roteiriza emissões (dano, carga, status, reator, crítico, coleta, objetivo, prompt) em tempos fixos, para o QA capturar cada estado sem depender das outras features.

### Autoloads / sinais do EventBus
- Escuta: todos os sinais da tabela acima.
- Emite: `objective_changed` (a partir de `GameState.set_objective`).
- Usa: `GameState` (leitura), `Balance`, `AudioManager`.

### Dados (`data/`)
- `data/objectives.json` (acima). Texto do jogador **nunca** concatenado em lógica.

### Input actions / camadas de colisão
- Nenhuma (o HUD não recebe input; `mouse_filter = IGNORE` em tudo).

## 7. Assets necessários

| Asset id | Uso nesta feature | Placeholder |
|---|---|---|
| [UI-HUD](../ASSETS.md#ui-hud) | Células cheia/vazia/piscando, molduras 9-slice das barras, ícones de status, ícones Log/Dado/[E] | Quadrados coloridos 16×16 (F05) |
| [UI-FONT](../ASSETS.md#ui-font) | Toda a tipografia do HUD (acentos pt-BR, legível em 8 px) | Fonte padrão do Godot até chegar |
| [SFX-PACK](../ASSETS.md#sfx-pack) | `low_integrity` | Beep gerado |

## 8. 🧑 Ação humana

Nenhuma.

## 9. Plano de execução

- [x] **Passo 1** — Constantes novas (ADR-F15-001) no GDD-P + Ajustes e no `balance.gd`.
- [x] **Passo 2** — `data/objectives.json` + `scripts/core/objectives.gd` + `tests/test_objectives.gd`.
- [x] **Passo 3** — `GameState.set_objective`.
- [x] **Passo 4** — `hud.tscn` (árvore da seção 6) com placeholders e o tema da F05.
- [x] **Passo 5** — `hud.gd`: leitura inicial do `GameState` + conexões do EventBus.
- [x] **Passo 6** — Células, barras, statuses com contador, pulso crítico, toasts, contadores, prompt, objetivo.
- [x] **Passo 7** — Bipe de integridade baixa.
- [x] **Passo 8** — Instanciação pelo `level_base` (combinar com a F21) e `scenes/dev/hud_test.tscn`.
- [x] **Passo 9** — Portões + QA (ler os screenshots e conferir que nada corta/sobrepõe).

## 10. Verificação

- **Testes (`tests/test_objectives.gd`):**
  - `test_load_all_has_demo_ids` — o JSON carrega e contém as 8 chaves da demo.
  - `test_text_for_known` — `text_for(&"obj_restore_gh", t)` retorna o texto com acentos correto.
  - `test_text_for_unknown_is_empty` — id inexistente → `""`.
  - `test_json_is_flat_strings` — todos os valores são `String` não vazias (evita objeto aninhado por engano).
- **Smoke:** `res://scenes/ui/hud.tscn`, `res://scenes/dev/hud_test.tscn`.
- **Roteiro godot-qa** (`tests/qa/f15_hud.json`; cena `res://scenes/dev/hud_test.tscn`, que emite o roteiro abaixo por conta própria):

| Frame | Evento disparado pela cena | Screenshot | O que deve aparecer |
|---:|---|---|---|
| 10 | estado inicial (100/100, reator offline) | `f15_01_inicial` | 4 células cheias, Carga cheia, **sem** bloco do reator, objetivo "Calibrar o chassi MU-7", contadores 00/24 e 00/12 |
| 40 | `reactor_online = true`, `reactor_changed(100)` | `f15_02_reator` | "ESTABILIDADE DO REATOR: 100%" + barra + "descendo" |
| 70 | `apply_damage(40)` | `f15_03_dano` | 2 células cheias, 1 parcial/vazia piscando, flash vermelho |
| 100 | `charge_changed(35/100)` + `status_applied(&"corrosion", 6)` | `f15_04_status` | Barra de Carga em ~1/3; ícone de corrosão com "6" |
| 160 | `interaction_available("[E] ACESSAR TERMINAL")` | `f15_05_prompt` | Prompt centralizado embaixo |
| 200 | `collectible_picked(&"log", "log_core_01")` | `f15_06_toast_log` | `LOGS 01/24` + toast "FRAGMENTO DE LOG 01/24" |
| 240 | `objective_changed("Estabilizar o reator: religar a Estufa")` | `f15_07_objetivo` | Novo texto no canto superior direito + toast |
| 280 | `reactor_critical(true)` + `reactor_changed(18)` | `f15_08_critico` | Percentual 18% em vermelho (pulsando) |
| 330 | `dialogue_started()` | `f15_09_sem_prompt` | Prompt escondido, resto do HUD intacto |

- **Playtest humano (opcional):** "dá para entender, sem explicação, quanto de vida e de tempo você tem?"

## 11. ADRs locais

### ADR-F15-001 — Constantes visuais do HUD
- **Contexto:** o GDD descreve comportamento ("pulsa em vermelho", "contador regressivo") sem números.
- **Decisão:** `HUD_TOAST_TIME = 2.0` s, `HUD_PULSE_HZ = 2.0` Hz, `LOW_INTEGRITY_BEEP_INTERVAL = 1.5` s no `Balance` + GDD-P/Ajustes.
- **Consequências:** ajuste de ritmo centralizado; nada de número mágico na UI.
- **Data:** 2026-09-19

### ADR-F15-002 — `GameState.set_objective(id)` e `data/objectives.json`
- **Contexto:** o contrato tem `current_objective: String` e o sinal `objective_changed(text)`, mas o texto precisa morar em `data/` ([ADR-006](../DECISIONS.md#adr-006)) e ser setado por diálogos, fases e eventos.
- **Decisão:** textos em `data/objectives.json`; quem muda o objetivo passa **id**, não texto: `GameState.set_objective(&"obj_restore_gh")`.
- **Consequências:** extensão do contrato do `GameState` (registrar no log da F02); tradução e revisão de texto num arquivo só.
- **Data:** 2026-09-19

### ADR-F15-003 — HUD instanciado pela fase, não autoload
- **Contexto:** o HUD só existe em gameplay; telas e menus não devem mostrá-lo.
- **Decisão:** `level_base.tscn` (F21) instancia `hud.tscn`; o HUD se autoconfigura lendo o `GameState` no `_ready()`.
- **Consequências:** nenhuma cena de menu precisa esconder HUD; testes usam `hud_test.tscn`.
- **Data:** 2026-09-19

### ADR-F15-004 — Marcação de custo na barra de Carga é condicional
- **Contexto:** o GDD pede "marcação do custo da próxima habilidade", mas na demo base não há habilidade que gaste Carga além da lanterna (dash e feixe são stretch, F31).
- **Decisão:** a marcação só aparece quando `GameState.abilities` contém `dash`; sem ela, a barra fica limpa.
- **Consequências:** nada de marcador inútil na demo; F31 liga o recurso sem mexer no HUD.
- **Data:** 2026-09-19

### ADR-F15-005 — Fonte do HUD em 16 px, não 8 px
- **Contexto:** o §6 desta feature dizia "tamanho 8 px", mas a regra dura 5 do `/CLAUDE.md` e a lição da F05/F03 são explícitas: a **m5x7 só é nítida em múltiplos de 16**; em 8 os glifos caem em meio pixel e derretem.
- **Decisão:** todo texto do HUD usa `font_size = 16` (o padrão do `theme.tres`). A m5x7 desenha glifos de 5×7 px nesse tamanho, então o HUD inteiro continua cabendo em 384×216 — o QA confirma o bloco do reator em 176 px de largura e o objetivo em duas linhas sem cortar acentos.
- **Consequências:** a regra dura ganha do texto da feature; nenhum `theme_override_font_sizes` fora de 16/32/48 no projeto (varredura vazia).
- **Data:** 2026-09-19

### ADR-F15-006 — Textos do HUD em `data/hud_texts.json`
- **Contexto:** o §6 só previa `data/objectives.json`, mas os rótulos e toasts (`ESTABILIDADE DO REATOR: %d%%`, `LOGS %02d/%02d`, `FRAGMENTO DE LOG %02d/%02d`, `descendo`/`congelado`/`SEM TIMER`) são texto que o jogador lê e não podem ser concatenados na lógica ([regra 4.2.5](/CLAUDE.md), [ADR-006](../DECISIONS.md#adr-006)).
- **Decisão:** `data/hud_texts.json` com 13 chaves de template, carregado por `HudModel.load_texts()` (que reusa o parser de `Objectives`). `HudModel.format_pair/format_single` aplicam os templates.
- **Consequências:** revisão de texto e tradução num arquivo só; `scripts/core/hud_model.gd` fica puro e testável (`tests/test_hud_model.gd`).
- **Data:** 2026-09-19

### ADR-F15-007 — O pulso crítico vai de vermelho escuro a vermelho claro
- **Contexto:** pulsar entre branco e vermelho faz o bloco do reator ficar **branco** metade do ciclo. Em screenshot (e num olhar de relance) o estado crítico some, e o GDD pede "pulsa em vermelho".
- **Decisão:** `modulate` interpola entre `Color(0.72, 0.16, 0.16)` e `Color(1, 0.36, 0.36)` a `Balance.HUD_PULSE_HZ`. O bloco é vermelho em qualquer instante do ciclo; a variação de brilho é o pulso.
- **Consequências:** o QA consegue provar o estado crítico em qualquer frame; duas capturas com 4 frames de diferença mostram brilhos diferentes.
- **Data:** 2026-09-19

### ADR-F15-008 — Célula parcial é a textura cheia escurecida
- **Contexto:** o contrato do [UI-HUD](../ASSETS.md#ui-hud) tem célula cheia, vazia e piscando — não tem célula "pela metade", mas `Vitals.cell_states` devolve três estados.
- **Decisão:** cheia = tile 0 sem modulação; parcial = tile 0 com `modulate = Color(0.55, 0.62, 0.66)`; vazia = tile 2 (vermelho) com alfa pulsando entre 0,25 e 1 a `HUD_PULSE_HZ`.
- **Consequências:** nada muda no contrato do asset; quando o definitivo chegar, a leitura continua a mesma.
- **Data:** 2026-09-19

### ADR-F15-009 — Cena de prova em `tests/qa/scenes/hud_probe.tscn`
- **Contexto:** o §6 pedia `scenes/dev/hud_test.tscn`; a convenção do projeto é `tests/qa/scenes/`.
- **Decisão:** `tests/qa/scenes/hud_probe.tscn` (grupos `level` + `gameplay`), que fixa `Settings.difficulty = normal` e dispara o roteiro da seção 10 por número de frame, 6 frames antes de cada captura.
- **Consequências:** mesma convenção da F12/F13; nada de `scenes/dev/` na build.
- **Data:** 2026-09-19

### ADR-F15-010 — O HUD reavalia a visibilidade do bloco do reator por frame
- **Contexto:** o `level_base` (F21) e as sequências de diálogo (F19) escrevem `GameState.flags["reactor_online"] = true` direto, sem passar por `set_reactor_online()`, então o HUD não recebe nenhum sinal para revelar o bloco.
- **Decisão:** `_update_reactor_visibility()` roda no `_process` e, quando `_reactor.visible` diverge de `GameState.is_reactor_online()`, refaz `_on_reactor_changed`.
- **Consequências:** o bloco aparece no frame seguinte ao alarme, venha a flag por onde vier; custo de uma comparação de bool por frame.
- **Data:** 2026-09-19

## 12. Log de evolução

> Append-only. Mais novo no fim.

### 2026-09-19 — Feature criada
- **Quem**: agente de planejamento · **O que**: documento inicial a partir do GDD · **Próximo passo**: implementação.

### 2026-09-19 — Implementada
- **Quem**: agente de implementação · **O que**: `scenes/ui/hud.tscn` + `hud.gd` (4 células de Integridade com parcial e vazia piscando, barra de Carga com marca de custo condicional, ícones de status com contagem regressiva, bloco `ESTABILIDADE DO REATOR: NN%` + barra + estado `descendo`/`congelado`/`SEM TIMER`, contadores `LOGS nn/24` e `DADOS nn/12` com ícone, prompt de interação, objetivo no canto superior direito, toasts, flash de dano, bipe `low_integrity`), `scripts/core/objectives.gd`, `scripts/core/hud_model.gd`, `data/objectives.json` (8 objetivos da demo), `data/hud_texts.json`, `GameState.set_objective(id)`/`clear_objective()`, `Balance.HUD_TOAST_TIME`/`HUD_PULSE_HZ`/`LOW_INTEGRITY_BEEP_INTERVAL`, cena `tests/qa/scenes/hud_probe.tscn`, suítes `tests/test_objectives.gd` (5 casos) e `tests/test_hud_model.gd` (10 casos), roteiro `tests/qa/f15_hud.json`. O HUD só conhece `EventBus`, `GameState` e `Balance` — nenhum `get_node` para fora dele. Portões: import limpo, 271 testes passando, 36 cenas no smoke, varreduras 3D/comentários/fonte vazias. QA leu as 11 capturas em 384×216 (ampliadas 3×): estado inicial sem o bloco do reator, bloco aparecendo em 100%, dano com flash e célula vazia vermelha, Carga em 35% com corrosão contando 6→3, prompt centralizado, toast `FRAGMENTO DE LOG 01/24` com o contador em 01/24, objetivo trocando com toast `OBJETIVO ATUALIZADO`, crítico em 18% pulsando vermelho (duas capturas com brilhos diferentes) e prompt sumindo no diálogo com o reator marcado `congelado`.
- **Pendências**: `HUD_TOAST_TIME`, `HUD_PULSE_HZ` e `LOW_INTEGRITY_BEEP_INTERVAL` **ainda não estão na tabela [GDD-P](../design/GDD.md#gdd-p) nem nos Ajustes** — esta execução foi proibida de editar `docs/design/`. `HudModel.cell_states` delega para `Vitals.cell_states` (F13), como previsto.
- **Próximo passo**: F16/F17/F19/F20 já têm onde aparecer (prompt, terminal, diálogo, contadores); a F31 liga a marca de custo da Carga só emitindo `ability_unlocked(&"dash")`.

### 2026-09-20 — revisto pela [F37](F37-legibilidade-hud.md)
- O playtest humano apontou excesso de informação sem rótulo. O bloco do reator perdeu a linha permanente de estado (`descendo` saiu; `CRÍTICO`/`SEM TIMER`/`TIMER PARADO` só aparecem quando valem), o título encurtou para `REATOR nn%`, a integridade ganhou rótulo e os dois contadores viraram uma linha só. Os textos desta doc que mostram `LOGS nn/24` e `DADOS nn/12` refletem o estado anterior — hoje os totais são 4 e 4 ([AJ-024](../design/GDD.md#gdd-ajustes)).

### 2026-09-20 — objetivo único por fase (revisão da [F37](F37-legibilidade-hud.md))
- **Motivo (playtest)**: *"eu acho que só deveria ter um objetivo por fase, e nao ficar mudando ele.
  colocar ele mais pra cima na tela, tipo. direita em cima / objetivo: / religar bla bla bla"*.
- **O que mudou**: `data/objectives.json` caiu de **13 objetivos para 2** — `obj_core_hub`
  (*Atravessar o Núcleo Central e chegar à Estufa*) e `obj_greenhouse` (*Religar o Nó do Setor da
  Estufa*). O objetivo passa a vir **só** do campo `objective` do JSON da fase, aplicado por
  `level_base._apply_progress()` quando a fase carrega, e não muda mais até a fase terminar.
- **De onde saiu**: 3 gatilhos do `core_hub.json`, 4 gatilhos do `greenhouse.json`, 1 gatilho do
  `test_room.json`, 1 sequência do `core_hub.json` de diálogo, o passo-a-passo de
  `scenes/levels/greenhouse.gd` e o script inteiro `scenes/levels/core_hub.gd` (existia só para
  isso). `GameState.clear_objective()` saiu por não ter chamador.
- **O que substitui a orientação passo a passo**: os cartões de tecla da F36 e a linha `META:` do
  Terminal de Distribuição — conferida por QA nos dois terminais antes de apagar os objetivos
  intermediários.
- **Onde aparece**: canto **superior** direito, em duas partes — `OBJETIVO:` apagado e o texto em
  ciano, ambos alinhados à direita em fonte 16. O sinal `objective_changed` e o aviso
  `OBJETIVO ATUALIZADO` continuam, só que disparam uma vez por fase.
