---
id: F33
title: Arquivo de Logs (codex)
status: not-started
scope: stretch
block: 5
priority: P2
rubric: ["Diálogo", "Itens e inventário"]
depends_on: ["F09", "F15", "F19", "F20"]
unblocks: []
estimate: 1h
last_updated: 2026-09-19
---

# F33 — Arquivo de Logs (codex)

## 1. Contexto e objetivo

O **Arquivo de Logs** (tecla `L`, e também pelo menu de pause) é o codex do jogo: lista os Fragmentos de Log já coletados, **por setor e por autor**, e permite reler qualquer um ([GDD-2.8, tela 5](../design/GDD.md#gdd-2-8-telas)).

É a feature que transforma a coleta em **inventário legível**: sem ela, um log lido às pressas no meio do corredor some para sempre e a história — que é o pilar **DESCOBERTA** — fica dependente de o jogador ter prestado atenção na primeira vez. Com a Demo tendo 6 logs (2 no Núcleo, 4 na Estufa), o arquivo é também a vitrine do trabalho narrativo na hora da apresentação.

O timer do reator **não corre** com o arquivo aberto, como em qualquer leitura de log ([GDD-2.5](../design/GDD.md#gdd-2-5-timer)).

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.8 telas (5 — Arquivo de Logs; 3 — Pause com ARQUIVO DE LOGS)](../design/GDD.md#gdd-2-8-telas) · [GDD-2.6.3 (Fragmento de Log, 24 no total)](../design/GDD.md#gdd-2-6-3) · [GDD-2.5 timer](../design/GDD.md#gdd-2-5-timer) · [GDD-2.9 SFX (beep suave de arquivo aberto)](../design/GDD.md#gdd-2-9-sfx)
- **Parâmetros:** `Balance.LOGS_TOTAL` (24), `Balance.REACTOR_LOG_BONUS` (0,5) — [GDD-P](../design/GDD.md#gdd-p). Nenhum número novo.
- **Jornada:** [Etapa 3 — Mentor](../design/JORNADA-DO-HEROI.md#jh-3) · [Personagens](../design/JORNADA-DO-HEROI.md#jh-personagens)
- **ADRs:** [ADR-006](../DECISIONS.md#adr-006) (conteúdo em JSON) · [ADR-010](../DECISIONS.md#adr-010) (ação `log_archive` já mapeada em `L`) · [ADR-009](../DECISIONS.md#adr-009)
- **Features vizinhas:** [F19 — Diálogo, legendas & logs](F19-dialogo-logs.md) (esquema dos logs e caixa de leitura), [F20 — Coletáveis & contadores](F20-coletaveis-contadores.md) (`GameState.collected_ids`, `logs_collected`), [F09 — Pause](F09-pause-recomecar.md) (entrada no menu), [F15](F15-hud-objetivos.md).

## 3. Critério de avaliação atendido

- **Diálogo** e **Itens e inventário** ([rubrica](../ENTREGAS.md#rubrica)), somando à [F19](F19-dialogo-logs.md) e à [F20](F20-coletaveis-contadores.md).
- Na apresentação: o apresentador aperta `L` (ou abre o pause → ARQUIVO DE LOGS), mostra a lista **NÚCLEO CENTRAL / ESTUFA** com os logs coletados, seleciona o registro 09 da Dra. Helena e o texto aparece inteiro na tela — provando que a coleta alimenta um inventário de verdade, e não só um contador.

## 4. Escopo

### Inclui
- `scenes/ui/log_archive.tscn` + `log_archive.gd`: tela cheia com duas colunas (lista à esquerda agrupada por setor/autor; texto à direita), navegável por teclado e controle.
- Abertura por `log_archive` (tecla `L`) durante o jogo e pelo item **ARQUIVO DE LOGS** do menu de pause ([F09](F09-pause-recomecar.md)).
- Contador `LOGS x/24` no cabeçalho (`GameState.logs_collected` / `Balance.LOGS_TOTAL`).
- Logs não coletados aparecem como linhas bloqueadas (`■■■■ — REGISTRO AUSENTE`), mostrando ao jogador **quanto** falta sem entregar o conteúdo.
- Lógica pura `scripts/core/log_catalog.gd`: carrega todos os `data/logs/*.json`, valida ids únicos, agrupa por setor e autor e devolve a lista na ordem de leitura, marcando o que está em `GameState.collected_ids`.
- Pausa da árvore enquanto aberto (`get_tree().paused = true`, `process_mode = PROCESS_MODE_ALWAYS`), o que já congela o timer do reator.
- SFX: `log_pickup` ao abrir, `ui_move`/`ui_confirm`/`ui_back` na navegação.

### Não inclui
- Áudio dos logs ("reler um log toca o áudio de novo", [GDD-2.8](../design/GDD.md#gdd-2-8-telas)) — não há voz gravada na Demo.
- Entrada **ARQUIVO** na tela inicial (GDD tela 1) — Final.
- Filtro/busca, marcação de "não lido", conquistas.
- Dados de Pesquisa no codex (na Demo eles só contam no contador e no epílogo) — Final.

## 5. Critérios de aceite

- [ ] `L` durante o jogo abre o arquivo; `ESC`/`ui_back` fecha e devolve o controle ao jogo exatamente como estava.
- [ ] Abrir pelo pause também funciona, e fechar o arquivo volta para o **menu de pause**, não para o jogo.
- [ ] Com o arquivo aberto, a Estabilidade do Reator **não** cai (`GameState.is_timer_frozen()`).
- [ ] A lista mostra os 6 logs da Demo agrupados por setor (NÚCLEO CENTRAL, SETOR HABITACIONAL, ESTUFA) com o nome do autor.
- [ ] Logs ainda não coletados aparecem bloqueados e não podem ser abertos.
- [ ] Selecionar um log coletado mostra o texto completo, com acentos corretos e quebra de linha legível em 384×216.
- [ ] O cabeçalho mostra `LOGS x/24` coerente com o HUD.
- [ ] Reabrir o arquivo mantém a seleção anterior.
- [ ] Nenhum log lido pelo arquivo dá `+0,5%` de novo (o bônus é só na primeira leitura, [F19](F19-dialogo-logs.md)/[F14](F14-estabilidade-reator.md)).
- [ ] `tests/test_log_catalog.gd` verde.
- [ ] Portões do `/CLAUDE.md` §6 verdes
- [ ] Sem comentários no código; nada 3D

## 6. Definição técnica

### Cenas e scripts
```
scenes/ui/log_archive.tscn (+ log_archive.gd)
  LogArchive (CanvasLayer)          layer = 20 · process_mode = PROCESS_MODE_ALWAYS
  └─ Root (Control)                 tema assets/ui/theme.tres, ancorado à tela cheia
      ├─ Background (ColorRect)     preto 90%
      ├─ Header (Label)             "ARQUIVO DE LOGS            LOGS 04/24"
      ├─ Body (HBoxContainer)
      │   ├─ List (VBoxContainer em ScrollContainer)   linhas por setor → autor → título
      │   └─ Reader (VBoxContainer)
      │       ├─ Title (Label) · Author (Label)
      │       └─ Text (RichTextLabel)   fit_content, autowrap
      └─ Footer (Label)             "↑↓ navegar   ENTER abrir   ESC voltar"
scripts/core/log_catalog.gd         class_name LogCatalog (RefCounted, pura)
```
```gdscript
class_name LogCatalog
extends RefCounted

static func load_all(paths: PackedStringArray) -> Dictionary: ...
static func grouped(catalog: Dictionary, collected: Array) -> Array[Dictionary]: ...
    # [{ "sector": "Estufa", "entries": [{ "id": ..., "author": ..., "title": ..., "collected": true }] }]
static func duplicated_ids(catalog: Dictionary) -> PackedStringArray: ...
static func collected_count(catalog: Dictionary, collected: Array) -> int: ...
```
- `load_all` usa `FileAccess` + `JSON.parse_string` ([ADR-006](../DECISIONS.md#adr-006)) e aceita a lista de arquivos (`data/logs/core.json`, `data/logs/greenhouse.json`, …) — sem `get_tree()`, sem nós, testável headless.
- A ordem dentro de cada setor é a ordem dos ids no JSON (ordem de leitura pretendida).
- `log_archive.gd` só monta os `Control` a partir de `LogCatalog.grouped(...)` e lê `GameState.collected_ids`.

Abertura (duas portas de entrada):
- No jogo: um nó pequeno (o HUD da [F15](F15-hud-objetivos.md) ou o próprio `log_archive` como autoload-free `CanvasLayer` instanciado pela fase) escuta `Input.is_action_just_pressed("log_archive")` e instancia a cena, com `get_tree().paused = true`.
- No pause: o botão **ARQUIVO DE LOGS** do menu da [F09](F09-pause-recomecar.md) instancia a mesma cena por cima, e ao fechar devolve o foco ao menu.

### Autoloads / sinais do EventBus
- **Emite:** `log_opened(log_id)` / `log_closed(log_id)` ao abrir e fechar um registro (o mesmo par da [F19](F19-dialogo-logs.md)) — mas **sem** repetir o bônus de Estabilidade, que a [F14](F14-estabilidade-reator.md) só concede em id ainda não lido; `game_paused(true/false)` se a [F09](F09-pause-recomecar.md) usar esse sinal para o estado global.
- **Lê:** `GameState.collected_ids`, `GameState.logs_collected`.
- `AudioManager.play_sfx("log_pickup" | "ui_move" | "ui_confirm" | "ui_back")`.

### Dados (`data/`)
- Nenhum arquivo novo: consome `data/logs/core.json` ([F28](F28-fase-nucleo-central.md)) e `data/logs/greenhouse.json` ([F29](F29-fase-estufa.md)). O campo `sector` de cada log define o agrupamento; o campo `author`, o subtítulo.

### Input actions / camadas de colisão
- `log_archive` (tecla `L`) e `ui_up`/`ui_down`/`ui_accept`/`ui_cancel` — já existentes ([ADR-010](../DECISIONS.md#adr-010)). Nenhuma colisão.

## 7. Assets necessários

| Asset id | Uso nesta feature | Placeholder |
|---|---|---|
| [UI-FONT](../ASSETS.md#ui-font) | Fonte pixel com acentos (o texto é longo — é aqui que a legibilidade aparece) | m5x7 / fonte padrão |
| [UI-HUD](../ASSETS.md#ui-hud) | Ícone de Log no cabeçalho e nas linhas da lista | Ícone 16×16 gerado |
| [SFX-PACK](../ASSETS.md#sfx-pack) | `log_pickup`, `ui_move`, `ui_confirm`, `ui_back` | Beeps gerados |

## 8. 🧑 Ação humana

Nenhuma.

## 9. Plano de execução

- [ ] **Passo 1** — `tests/test_log_catalog.gd` + `scripts/core/log_catalog.gd`.
- [ ] **Passo 2** — `scenes/ui/log_archive.tscn` (layout de duas colunas no tema único) + `log_archive.gd`.
- [ ] **Passo 3** — Abertura por `L` no jogo, com pausa da árvore.
- [ ] **Passo 4** — Item **ARQUIVO DE LOGS** no menu de pause (F09), com retorno correto ao fechar.
- [ ] **Passo 5** — Linhas bloqueadas para logs não coletados + contador no cabeçalho.
- [ ] **Passo 6** — QA (roteiro da seção 10) + `tests/scenes.txt` + `/verify-gates`; commit `feat(F33): arquivo de logs navegável por setor e autor`.

## 10. Verificação

- **Testes (`tests/test_log_catalog.gd`):**
  - `test_loads_all_demo_logs`: carrega os dois arquivos e encontra os 6 ids da Demo.
  - `test_ids_are_unique`: `duplicated_ids(...)` vazio.
  - `test_groups_by_sector`: agrupa em NÚCLEO CENTRAL / SETOR HABITACIONAL / ESTUFA na ordem dos arquivos.
  - `test_marks_collected`: com `collected = ["log_core_01"]`, só essa entrada vem com `collected == true`.
  - `test_collected_count_matches`.
  - `test_every_log_has_author_and_lines`: nenhum log sem `author`, `title` ou `lines` não vazio.
- **Smoke:** `res://scenes/ui/log_archive.tscn` em `tests/scenes.txt`.
- **Roteiro godot-qa** (`tests/qa/f33_log_archive.json`), cena `res://scenes/levels/greenhouse.tscn` com o save de QA contendo 3 logs coletados:

  | Frame | Input / ação | Screenshot | Deve mostrar |
  |---|---|---|---|
  | 30 | — | `01_game.png` | jogo rodando, HUD com LOGS 03/24 |
  | 60 | `log_archive` (L) | `02_archive.png` | arquivo aberto, lista por setor, 3 linhas legíveis e as demais bloqueadas, Reator congelado |
  | 90 | `ui_down` ×2 | `03_selection.png` | seleção movida, painel direito atualizado |
  | 120 | `ui_accept` | `04_reading.png` | texto completo do log com acentos, sem corte |
  | 180 | `ui_cancel` | `05_closed.png` | de volta ao jogo, Reator voltando a cair |
  | 240 | `pause` → ARQUIVO DE LOGS | `06_from_pause.png` | mesma tela aberta por cima do pause |
  | 300 | `ui_cancel` | `07_back_to_pause.png` | de volta ao **menu de pause** (não ao jogo) |
- **Playtest humano (opcional):** a lista com 6 entradas parece "um acervo" ou parece vazia? (se parecer vazia, mostrar as 24 linhas bloqueadas resolve — já é o comportamento previsto.)

## 11. ADRs locais

### ADR-F33-001 — Logs não coletados aparecem bloqueados
- **Contexto:** mostrar só o que foi coletado deixa o codex da Demo com 6 linhas e nenhuma noção de progresso; mostrar tudo entregaria a narrativa.
- **Decisão:** todas as entradas dos JSONs carregados aparecem; as não coletadas vêm como `■■■■ — REGISTRO AUSENTE`, sem autor e sem texto.
- **Consequências:** o jogador vê que falta conteúdo (reforça o Score/coleta) sem spoiler. No Final, o mesmo comportamento serve aos 24 logs.
- **Data:** 2026-09-19

### ADR-F33-002 — O arquivo não concede bônus de Estabilidade
- **Contexto:** cada log lido dá `+0,5%` ([GDD-2.5](../design/GDD.md#gdd-2-5-timer)); reler no codex poderia virar uma bomba de reator infinita.
- **Decisão:** o bônus é concedido pela [F14](F14-estabilidade-reator.md) apenas na **primeira** leitura de cada id (controle por `GameState.collected_ids`); o arquivo emite `log_opened`/`log_closed` para HUD/áudio, mas nunca gera bônus.
- **Consequências:** o codex é puramente narrativo; o timer continua sendo pressão.
- **Data:** 2026-09-19

## 12. Log de evolução

### 2026-09-19 — Feature criada
- **Quem**: agente de planejamento · **O que**: documento inicial a partir do GDD-2.8 (tela 5) · **Próximo passo**: só depois do Bloco 4 inteiro `[x]`.
