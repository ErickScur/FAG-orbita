---
id: F10
title: Telas de fim de jogo
status: done
scope: demo
block: 1
priority: P0
rubric: ["Tela de fim de jogo"]
depends_on: ["F03", "F05", "F07"]
unblocks: ["F13", "F14", "F29"]
estimate: 1.5h
last_updated: 2026-09-19
---

# F10 — Telas de fim de jogo

## 1. Contexto e objetivo

O ÓRBITA tem três fins ([GDD-2.8 Telas](../design/GDD.md#gdd-2-8-telas)):

1. **Chassi perdido** (Integridade 0): sobreposição preta com `SINAL DO CHASSI PERDIDO - RESTAURANDO BACKUP` e o custo em estabilidade. Não é game over: o jogo continua no último Ponto de Backup.
2. **Perda de órbita** (Reator 0%): `PERDA DE ÓRBITA - MISSÃO ENCERRADA`, com o número de logs que o jogador nunca vai ler e a opção de carregar o último setor.
3. **FIM DA DEMO** ([AJ-004](../design/GDD.md#gdd-ajustes)): ao religar a Estufa e sair pela transição final, estatísticas da run (tempo, logs, dados, mortes, segredos) e volta ao menu.

Serve aos pilares **ESCASSEZ** (morrer custa tempo do mundo) e **AUSÊNCIA** (texto monoespaçado, sem "Game Over" comemorativo).

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.8 Telas](../design/GDD.md#gdd-2-8-telas) (telas 6, 7 e 8) · [GDD-2.5 Derrota](../design/GDD.md#gdd-2-5-derrota) · [GDD-2.6.3 Itens](../design/GDD.md#gdd-2-6-3)
- **Parâmetros:** `Balance.REACTOR_DEATH_PENALTY` (3%), `Balance.RESPAWN_INTEGRITY_RATIO` (0,5), `Balance.LOGS_TOTAL` (24), `Balance.RESEARCH_TOTAL` (12) ([GDD-P](../design/GDD.md#gdd-p))
- **Ajustes:** [AJ-004](../design/GDD.md#gdd-ajustes)
- **Jornada:** [Etapa 5 — Testes e Aliados](../design/JORNADA-DO-HEROI.md#jh-5) (a Demo termina no fim da Estufa) · [Etapa 9](../design/JORNADA-DO-HEROI.md#jh-9) (tom do epílogo)
- **ADRs:** [ADR-009](../DECISIONS.md#adr-009)

## 3. Critério de avaliação atendido

**Tela de fim de jogo** ([ENTREGAS §3.1](../ENTREGAS.md#rubrica)): "Perda de órbita (reator 0%), chassi perdido, FIM DA DEMO com estatísticas". No roteiro da apresentação o avaliador vê o chassi perdido (morte proposital) e a tela FIM DA DEMO ao final.

## 4. Escopo

### Inclui
- `scenes/ui/chassis_lost.tscn` (+ `.gd`): `CanvasLayer` sobreposto, texto monoespaçado com efeito de digitação, custo `−3% ESTABILIDADE`, sinal `finished`.
- `scenes/ui/game_over.tscn` (+ `.gd`): cena cheia (via `SceneManager.goto`) com CARREGAR ÚLTIMO SETOR / MENU PRINCIPAL.
- `scenes/ui/demo_end.tscn` (+ `.gd`): "FIM DA DEMO" + estatísticas + MENU PRINCIPAL.
- `scripts/core/run_stats.gd` (`class_name RunStats`): formatação de tempo e linhas de estatística (lógica pura + testes).
- Ligações no `SceneManager`: `EventBus.game_over(reason)` → `goto(game_over.tscn)`; `EventBus.demo_completed` → `goto(demo_end.tscn)`.

### Não inclui
- A lógica de morte/respawn e a penalidade de 3% ([F13](F13-integridade-carga-respawn.md)) e o zeramento do reator ([F14](F14-estabilidade-reator.md)) — aqui só as telas e os sinais.
- Epílogo por Dados de Pesquisa, lista dos 40 nomes, "VOCÊ ESCOLHERIA DE NOVO?" (F46 — Final).
- Ranking/placar persistente entre runs (Final).
- Créditos de assets rolando (ficam no `README.md`).

## 5. Critérios de aceite

- [x] `chassis_lost.tscn` instanciado sobre a fase mostra, em fundo preto: `SINAL DO CHASSI PERDIDO - RESTAURANDO BACKUP` digitado caractere a caractere e, abaixo, `CUSTO: -3% DE ESTABILIDADE` (valor vindo de `Balance.REACTOR_DEATH_PENALTY`).
- [x] Após a digitação + 1,5 s (ou ao apertar `interact`/`ui_accept`), emite `finished` e se libera; o jogo volta a rodar (quem respawna é a F13).
- [x] Com o reator em 0, `EventBus.game_over(&"reactor")` leva à cena `game_over.tscn` com o texto `PERDA DE ÓRBITA - MISSÃO ENCERRADA` e a linha "VOCÊ NUNCA VAI LER N LOGS" (N = `Balance.LOGS_TOTAL - GameState.logs_collected.size()`).
- [x] Em `game_over.tscn`, CARREGAR ÚLTIMO SETOR aparece só se `SaveManager.has_save()`; carrega e volta ao checkpoint. MENU PRINCIPAL volta ao menu.
- [x] `EventBus.demo_completed` leva a `demo_end.tscn` com título "FIM DA DEMO" e as linhas: `TEMPO  MM:SS`, `LOGS  x/24`, `DADOS  x/12`, `MORTES  n`, `SEGREDOS  n/4` (`Balance.SECRETS_TOTAL`, ver ADR-F10-004) — todos lidos do `GameState` e dos totais do `Balance`.
- [x] `demo_end.tscn` mostra a frase de fechamento "A ESTUFA VOLTOU A RESPIRAR. A ESTAÇÃO AINDA NÃO." e o botão MENU PRINCIPAL (foco inicial).
- [x] Nenhuma dessas telas fica presa com a árvore pausada (todas com `process_mode = ALWAYS` onde aplicável) e todas despausam ao trocar de cena.
- [x] Textos em pt-BR (acentos) e o cabeçalho técnico em caixa alta monoespaçada como no GDD.
- [x] Portões do `/CLAUDE.md` §6 verdes.
- [x] Sem comentários no código; nada 3D.

## 6. Definição técnica

### Cenas e scripts
```
scenes/ui/chassis_lost.tscn (+ chassis_lost.gd)
scenes/ui/game_over.tscn    (+ game_over.gd)
scenes/ui/demo_end.tscn     (+ demo_end.gd)
scripts/core/run_stats.gd   class_name RunStats
autoload/scene_manager.gd   (+ conexões game_over / demo_completed)
```

### `chassis_lost.tscn`
```
ChassisLost (CanvasLayer, layer 80, process_mode ALWAYS, script chassis_lost.gd)
└─ Root (Control, full rect)
   ├─ Fade (ColorRect, #000000, alpha 0 → 1 em 0,4 s)
   └─ VBox (centro)
      ├─ MainLine (Label, "SINAL DO CHASSI PERDIDO - RESTAURANDO BACKUP", cor #E0525A)
      ├─ CostLine (Label, "CUSTO: -3% DE ESTABILIDADE", cor #8A9BA8)
      └─ HintLine (Label, "[E] CONTINUAR", cor #56606A, aparece ao fim da digitação)
```
`chassis_lost.gd`: `signal finished`; `func play() -> void` faz o fade, digita `MainLine` (1 caractere a cada 0,03 s, SFX `damage` no início), mostra `CostLine` com `"CUSTO: -%d%% DE ESTABILIDADE" % Balance.REACTOR_DEATH_PENALTY`, espera, emite `finished` e `queue_free()`. Quem instancia: a [F13](F13-integridade-carga-respawn.md), ao tratar `EventBus.player_died`.

### `game_over.tscn`
```
GameOver (Control, full rect, script game_over.gd)
├─ Background (ColorRect, #000000)
└─ VBox (centro)
   ├─ Title (Label, "PERDA DE ÓRBITA - MISSÃO ENCERRADA", cor #E0525A)
   ├─ Detail (Label, "VOCÊ NUNCA VAI LER 18 LOGS.", cor #8A9BA8)
   ├─ LoadButton (Button, "CARREGAR ÚLTIMO SETOR")
   └─ MenuButton (Button, "MENU PRINCIPAL")
```
`game_over.gd`: `_ready()` monta `Detail` com `RunStats.unread_logs_line(GameState)`, `AudioManager.stop_music(0.5)`, foco no primeiro botão habilitado.

### `demo_end.tscn`
```
DemoEnd (Control, full rect, script demo_end.gd)
├─ Background (ColorRect, #05080C)
└─ VBox (centro, separation 4)
   ├─ Title (Label, "FIM DA DEMO")
   ├─ Stats (VBoxContainer preenchido por código: uma Label por linha)
   ├─ Closing (Label, autowrap, "A ESTUFA VOLTOU A RESPIRAR. A ESTAÇÃO AINDA NÃO.")
   └─ MenuButton (Button, "MENU PRINCIPAL")
```
`demo_end.gd`: `for line in RunStats.summary_lines(GameState): …`; toca `&"menu"` no `AudioManager`; MENU PRINCIPAL → `SceneManager.goto(ScenePaths.MAIN_MENU)`.

### `RunStats` (lógica pura)
```gdscript
class_name RunStats
extends RefCounted

static func format_time(seconds: float) -> String          # 754.2 -> "12:34"
static func summary_lines(state: Node) -> PackedStringArray
static func unread_logs_line(state: Node) -> String
static func secrets_found(state: Node) -> int
```
`summary_lines` devolve, nesta ordem: `"TEMPO      %s"`, `"LOGS       %d/%d"` (`Balance.LOGS_TOTAL`), `"DADOS      %d/%d"` (`Balance.RESEARCH_TOTAL`), `"MORTES     %d"`, `"SEGREDOS   %d/%d"` (`Balance.SECRETS_TOTAL`, ver ADR-F10-004). `secrets_found` conta as chaves de `GameState.flags` que começam com `"secret_"` e valem `true` — convenção acordada com a [F27](F27-area-secreta.md) (ver ADR-F10-002). Tempo ≥ 1 h vira `H:MM:SS`.

Implementado também `summary_rows(state) -> Array` (pares `[rótulo, valor]`) e `unread_logs(state) -> int`: a `demo_end` monta uma `HBoxContainer` por linha (rótulo à esquerda, valor à direita) porque a m5x7 é proporcional e o alinhamento por espaços de `summary_lines` só fica reto em fonte monoespaçada. `summary_lines` continua sendo o contrato textual testado.

### Autoloads / sinais do EventBus
- Escuta (no `SceneManager`, política de fim de jogo desta feature — [ADR-013](../DECISIONS.md#adr-013) e ADR-F10-005):
  - `game_over(reason: StringName)` → `goto(ScenePaths.GAME_OVER)`;
  - `demo_completed()` → `goto(ScenePaths.DEMO_END)`;
  - `player_died()` → instancia `chassis_lost.tscn` como filho do `SceneManager` e chama `play()`; ignora a morte se `GameState.reactor_percent <= 0.0` (nesse caso quem manda é `game_over`).
- Emite: `player_respawned()` quando a tela de chassi perdido termina — **seam da [F13](F13-integridade-carga-respawn.md)**, que escuta esse sinal para recolocar o MU-7 na doca, repor `RESPAWN_INTEGRITY_RATIO` de Integridade e contar a morte; a penalidade de −3% segue sendo da [F14](F14-estabilidade-reator.md).
- `ScenePaths` ganhou `GAME_OVER`, `DEMO_END` e `CHASSIS_LOST`.

### Dados (`data/`)
- Nenhum (textos nas cenas).

### Input actions / camadas de colisão
- `ui_accept`, `ui_cancel`, `interact` (pular a digitação).

## 7. Assets necessários

| Asset id | Uso nesta feature | Placeholder |
|---|---|---|
| [UI-FONT](../ASSETS.md#ui-font) | Texto técnico em caixa alta | Tema da F05 |
| [SFX-PACK](../ASSETS.md#sfx-pack) | `damage` (chassi perdido), `ui_confirm`, `ui_back` | Beeps (F05) |
| [MUS-MENU](../ASSETS.md#mus-menu) | Trilha da tela FIM DA DEMO | Drone (F05) |

## 8. 🧑 Ação humana

Nenhuma.

## 9. Plano de execução

- [x] **Passo 1** — `tests/test_run_stats.gd` (falha) → `scripts/core/run_stats.gd`.
- [x] **Passo 2** — `chassis_lost.tscn` + `.gd` com digitação e `finished`.
- [x] **Passo 3** — `game_over.tscn` + `demo_end.tscn` + scripts.
- [x] **Passo 4** — Conexões no `SceneManager`.
- [x] **Passo 5** — Cena de QA `tests/qa/scenes/end_probe.tscn` (grupo `gameplay`) com 3 botões que: instanciam `chassis_lost` e chamam `play()`, emitem `EventBus.game_over(&"reactor")`, emitem `EventBus.demo_completed()`; antes disso preenche o `GameState` com valores de exemplo (play_time 754, 6 logs, 4 dados, 2 mortes, 1 segredo).
- [x] **Passo 6** — `tests/scenes.txt` += as 3 telas e a sonda; QA; portões; commit `feat(F10): telas de chassi perdido, perda de órbita e fim da demo`.

## 10. Verificação

- **Testes (`tests/test_*.gd`):** `test_run_stats.gd` — `format_time(0) == "00:00"`, `format_time(754.2) == "12:34"`, `format_time(3725) == "1:02:05"`; `summary_lines` com um `GameState` falso (script instanciado) devolve 5 linhas com `x/24` e `x/12` vindos do `Balance`; `secrets_found` conta só `secret_*` verdadeiros; `unread_logs_line` com 6 logs → "VOCÊ NUNCA VAI LER 18 LOGS.".
- **Smoke:** `res://scenes/ui/chassis_lost.tscn`, `res://scenes/ui/game_over.tscn`, `res://scenes/ui/demo_end.tscn`, `res://tests/qa/scenes/end_probe.tscn`.
- **Roteiro godot-qa:** cena `end_probe.tscn` (a sonda pré-carrega o `GameState` com tempo 754,2 s, 6 logs, 4 dados, 2 mortes e 1 segredo). Atenção: a janela real roda a ~120 fps, então os frames dos roteiros valem ~1/120 s — as esperas foram dobradas em relação ao rascunho.
  - `f10_ends.json`: `ui_accept` no botão 1 → `f10_01_chassis_typing` (linha vermelha sendo digitada), `f10_02_chassis_full` (linha completa + "CUSTO: -3% DE ESTABILIDADE" + barra + "[E] CONTINUAR"); `interact` → `f10_03_chassis_closed` (sonda visível de novo); `ui_down` + `ui_accept` → `f10_04_game_over` (título vermelho, "VOCÊ NUNCA VAI LER 18 LOGS.", CARREGAR desabilitado sem backup).
  - `f10_game_over_com_backup.json`: mesmo caminho com `user://save.json` presente → `f10_05_game_over_com_backup` (CARREGAR ÚLTIMO SETOR habilitado e com foco).
  - `f10_demo_end.json` (botão 3) → `f10_11_demo_end` com as 5 linhas: `TEMPO 12:34`, `LOGS 6/24`, `DADOS 4/12`, `MORTES 2`, `SEGREDOS 1/4`.
- **Playtest humano (opcional):** ver a tela de chassi perdido e dizer se a espera é curta o bastante para não irritar.

## 11. ADRs locais

### ADR-F10-001 — Chassi perdido é sobreposição, game over é cena
- **Contexto:** morrer não recarrega a fase (respawn na doca); perder o reator encerra a run.
- **Decisão:** `chassis_lost` é `CanvasLayer` sobre a fase com sinal `finished`; `game_over` e `demo_end` são cenas próprias via `SceneManager`.
- **Consequências:** respawn sem recarregar a fase (mais rápido e preserva o estado do setor). **Data:** 2026-09-19.

### ADR-F10-002 — Contagem de segredos por flag
- **Contexto:** o `GameState` não tem campo de segredos e a GDD-P não tem total de áreas secretas.
- **Decisão:** convenção `GameState.flags["secret_<id>"] = true` (gravada pela [F27](F27-area-secreta.md)); a tela mostra apenas o número encontrado, sem total.
- **Consequências:** se o total virar necessário, adicionar `SECRETS_TOTAL` à [GDD-P](../design/GDD.md#gdd-p) + [Ajustes](../design/GDD.md#gdd-ajustes). **Data:** 2026-09-19.

### ADR-F10-003 — `SceneManager` escuta `game_over` e `demo_completed`
- **Contexto:** quem emite (F14/F29) não deve conhecer caminhos de tela.
- **Decisão:** as duas conexões ficam no `SceneManager`.
- **Consequências:** um único lugar que mapeia fim → tela. **Data:** 2026-09-19.

### ADR-F10-004 — `SEGREDOS` mostra o total (`n/4`)
- **Contexto:** a ADR-F10-002 decidiu mostrar só o número encontrado porque a GDD-P não tinha total de áreas secretas. A GDD-P passou a ter `SECRETS_TOTAL = 4` ([AJ-012](../design/GDD.md#gdd-ajustes)) e a [F29](F29-fase-estufa.md) já descreve a linha como `ÁREAS SECRETAS 1/4`.
- **Decisão:** a linha vira `SEGREDOS   %d/%d` usando `Balance.SECRETS_TOTAL`, no mesmo formato de `LOGS` e `DADOS`. Supera a parte "sem total" da ADR-F10-002; a convenção `flags["secret_<id>"]` continua valendo.
- **Consequências:** as três linhas de coleta ficam com a mesma leitura. **Data:** 2026-09-19.

### ADR-F10-005 — A política de morte também mora no `SceneManager`
- **Contexto:** a [ADR-013](../DECISIONS.md#adr-013) diz que a F10 é dona da política de fim de jogo, inclusive da morte do chassi. O rascunho da [F13](F13-integridade-carga-respawn.md) previa que o `mu7.gd` chamasse `SceneManager.goto("chassis_lost.tscn")`, o que duplicaria a política e contraria a ADR-F10-001 (a tela é sobreposição, não cena).
- **Decisão:** o `SceneManager` — único lugar que já hospeda UI global (o menu de pause) — escuta `player_died` e instancia a sobreposição. Ao terminar, emite `EventBus.player_respawned()`; a F13 escuta esse sinal em vez de emiti-lo. Nenhum sinal novo foi criado no `EventBus`.
- **Consequências:** fases e jogador só emitem `player_died`; a F13 vira ouvinte de `player_respawned`. O rascunho da F13 §"Morte"/§"Respawn" precisa ser reescrito nessa direção (divergência reportada, não corrigida aqui). **Data:** 2026-09-19.

## 12. Log de evolução

### 2026-09-19 — Feature criada
- **Quem**: agente de planejamento · **O que**: documento inicial a partir do GDD-2.8 (telas 6–8) e AJ-004 · **Próximo passo**: implementação.

### 2026-09-19 — Feature implementada (`status: done`)
- **Quem**: agente de implementação
- **O que**:
  - `scripts/core/run_stats.gd` (`RunStats`) com `format_time`, `summary_rows`, `summary_lines`, `unread_logs`, `unread_logs_line`, `secrets_found`;
  - `scenes/ui/chassis_lost.tscn/.gd` — sobreposição `CanvasLayer` (layer 80, `PROCESS_MODE_ALWAYS`) com fade, digitação caractere a caractere dirigida por `_process` (sem `await`, para não retomar corrotina em nó liberado), barra de restauração, `CUSTO: -3% DE ESTABILIDADE` vindo de `Balance.REACTOR_DEATH_PENALTY` e sinal `finished`;
  - `scenes/ui/game_over.tscn/.gd` e `scenes/ui/demo_end.tscn/.gd` — cenas cheias na linguagem do menu/loading (fundo estelar via `AssetResolver`, painel com moldura, fonte 16/32), nada de tela preta e vazia;
  - conexões `player_died` / `game_over` / `demo_completed` no `SceneManager`; `ScenePaths.GAME_OVER/DEMO_END/CHASSIS_LOST`;
  - sonda `tests/qa/scenes/end_probe.tscn/.gd` (grupo `gameplay`) e roteiros `tests/qa/f10_ends.json`, `f10_demo_end.json`, `f10_game_over_com_backup.json`;
  - `tests/test_run_stats.gd` (13 casos) e as três telas em `tests/scenes.txt`.
- **Portões**: import limpo · `128 passed, 0 failed` (eram 99) · smoke 18/18 OK · varreduras 3D/comentários/`font_size` vazias.
- **QA visual** (janela real, `--qa-scale=3`): `f10_01_chassis_typing` (linha vermelha em digitação), `f10_02_chassis_full` (linha completa + custo + barra + `[E] CONTINUAR`), `f10_03_chassis_closed` (sonda de volta), `f10_04_game_over` (CARREGAR desabilitado sem backup), `f10_05_game_over_com_backup` (CARREGAR habilitado e focado), `f10_11_demo_end` (`FIM DA DEMO` em 32 + `TEMPO 12:34` / `LOGS 6/24` / `DADOS 4/12` / `MORTES 2` / `SEGREDOS 1/4` + frase de fechamento + `MENU PRINCIPAL`).
- **Decisões novas**: ADR-F10-004 (total de segredos) e ADR-F10-005 (política de morte no `SceneManager`, seam `player_respawned` para a F13).
- **Próximo passo**: F13 consome `player_respawned` (posição na doca, integridade, contagem de mortes) e F14 aplica a penalidade de −3%.
