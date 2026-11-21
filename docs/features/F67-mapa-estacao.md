---
id: F67
title: Mapa da estação (TAB e pause)
status: done
scope: final
block: 5B
priority: P1
rubric: ["Scanner", "Telas do jogo", "Itens e inventário"]
depends_on: ["F09", "F20", "F44"]
unblocks: ["F62", "F64", "F65"]
estimate: 3h
last_updated: 2026-11-21
---

# F67 — Mapa da estação (TAB e pause)

## 1. Contexto e objetivo

O humano pediu na F44 *"uma especie de mapa que vai desbloqueando conforme religamos a energia (e o
resto fica com um ?? ou sem energia)"*, e o GDD-2.8 (tela 4) define o **Mapa** como planta técnica:
setores religados em branco, sem energia em cinza, portas seladas com cadeado.

O mapa é a leitura do pilar **DESCOBERTA** em escala de estação: o jogador vê o hub radial inteiro,
onde está ("VOCÊ ESTÁ AQUI"), o que já religou, o que falta e quantos logs e dados ainda estão
escondidos em cada setor. Não cresce o HUD (regra da F37/F44): mora no Terminal do Chassi, como
segunda página do `[TAB]`, e no item **MAPA** da pausa.

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.8 Telas (4 — Mapa; 3 — Pause com MAPA)](../design/GDD.md#gdd-2-8-telas) ·
  [GDD-2.7 hub radial](../design/GDD.md#gdd-2-7-mapa) (desenho do mapa) ·
  [GDD-2.4 Controles](../design/GDD.md#gdd-2-4) (`map` = TAB) ·
  [GDD-2.5 timer](../design/GDD.md#gdd-2-5-timer) (telas congelam o reator) ·
  [AJ-052](../design/GDD.md#gdd-ajustes) (TAB abre o chassi; TAB de novo, o mapa)
- **Parâmetros:** `Balance.LOGS_TOTAL`, `Balance.RESEARCH_TOTAL` só como conferência (teste soma
  os setores). **Nenhuma constante nova.**
- **ADRs:** [ADR-004](../DECISIONS.md#adr-004) (fases em ASCII: os dados de pesquisa são contados
  no mapa da fase) · [ADR-006](../DECISIONS.md#adr-006) (texto em `data/`)
- **Features:** [F44](F44-terminal-do-chassi.md) (casa do mapa) · [F09](F09-pause-recomecar.md) ·
  [F20](F20-coletaveis-contadores.md) · [F33](F33-arquivo-logs.md) (mesmo catálogo de logs)

## 3. Critério de avaliação atendido

| Item da rubrica | Como o avaliador vê |
|---|---|
| **Scanner** | `[TAB]` duas vezes (ou pausa → MAPA): planta da ARTEMIS com os 7 setores, o MU-7 piscando no setor atual, cadeados nas portas seladas e, por setor, `LOGS x/y` e `DADOS x/y` encontrados. |
| **Telas do jogo** | Tela nova, com estética de blueprint, que pausa o jogo e fecha com TAB/ESC/voltar. |
| **Itens e inventário** | A contagem por setor diz onde ainda há coleta pendente. |

## 4. Escopo

### Inclui
- `scenes/ui/station_map.tscn` + `.gd` — planta desenhada em código (`_draw`): grade de blueprint,
  corredores do hub até cada setor, caixas por estado, cadeado na porta selada, marcador piscante
  "VOCÊ ESTÁ AQUI"; um `Button` por setor, com vizinhos de foco radiais (setas/D-pad).
- Faixa de informação do setor selecionado: nome, estado, `VOCÊ ESTÁ AQUI`, contagens ou dica.
- Página **MAPA** no Terminal do Chassi (`[TAB]` abre o diagnóstico, `[TAB]` de novo abre o mapa,
  `[TAB]`/`[ESC]` fecham); linha `SETORES RELIGADOS x/7` no diagnóstico (antes `??`).
- Item **MAPA** na pausa (overlay; `ESC`/`TAB`/Start volta para a pausa).
- `scripts/core/station_map_model.gd` (`StationMapModel`, lógica pura): carrega o JSON, estado de
  cada setor, setor atual, contagens, vizinhos de navegação.
- `data/map/station.json`: os 7 setores (mesmo os que ainda não têm fase), com nome, fase, cena,
  pré-requisito da porta e célula no desenho.
- `GameState.mark_visited()/has_visited()` + `_track_visit()` (marca `flags.visited_<fase>` ao
  entrar numa fase; sai no save sem mudar o formato).
- Marco de QA `expect_call` no `QACapture` (`QAMarks.same_value`) para provar timer congelado e
  foco preso sem depender de captura.

### Não inclui
- Mapa por sala dentro de cada fase (o mapa é da estação, por setor).
- Exigência do **Acesso Root** na porta do Reator: o pré-requisito do mapa é só o setor anterior;
  quando a F69 criar a habilidade, o mapa pode ganhar `requires_ability` (pendência registrada).
- Teleporte/viagem rápida pelo mapa.

## 5. Critérios de aceite

- [x] `[TAB]` abre o Terminal do Chassi; `[TAB]` de novo mostra o mapa; `[TAB]`/`[ESC]` fecham e
      devolvem o jogo como estava (foco liberado: o `[TAB]` seguinte abre de novo).
- [x] Pausa → **MAPA** abre o mesmo mapa por cima da pausa; `ESC`/`TAB` volta para a pausa com o
      foco no botão MAPA.
- [x] Estados: religado (branco, corredor aceso), visitado sem energia (cinza), selado (cadeado na
      porta), desconhecido (contorno tracejado, `SEM DADOS`).
- [x] O setor atual pisca e a faixa de baixo diz `VOCÊ ESTÁ AQUI` ao abrir.
- [x] `LOGS x/y` e `DADOS x/y` por setor saem dos dados (logs pelo campo `sector`; dados pelo
      símbolo `r` do mapa ASCII da fase) e a soma fecha com `Balance` (teste).
- [x] Setas/D-pad navegam pelo desenho radial e o foco nunca sai do mapa (vizinhos explícitos;
      teste + marco `overlay_owns_focus`).
- [x] Com o mapa aberto o reator não cai (`GameState.is_timer_frozen()`; marco de QA).
- [x] Fase nova entra no mapa só com dados (ver §6 "Como uma fase nova entra").
- [x] Portões do `/CLAUDE.md` §6 verdes (validação no Godot 4.7.2, 2026-11-21)
- [x] Sem comentários no código; nada 3D

## 6. Definição técnica

### Cenas e scripts
```
scenes/ui/station_map.tscn (+ .gd)    Control em tela cheia; standalone (pausa) ou página do chassi
scenes/ui/chassis_menu.tscn (+ .gd)   página DIAGNÓSTICO | MAPA (nó %Map, standalone = false)
scenes/ui/pause_menu.tscn (+ .gd)     botão MAPA → overlay
scripts/core/station_map_model.gd     StationMapModel (pura)
scripts/core/qa_marks.gd              QAMarks.same_value (marco expect_call)
```
Estado de um setor (`StationMapModel.state_of`), nesta ordem:
1. **religado** — `id` em `GameState.sectors_restored`, ou `restored_when` religado (o Núcleo
   religa junto com a Estufa, quando o hub acende e o reator entra em linha);
2. **visitado** — setor atual, `flags.visited_<fase>`, checkpoint na cena dele ou qualquer
   log/dado dele já coletado (vale para saves antigos, de antes da marca de visita);
3. **selado** — `requires` ainda não religado (é a mesma regra das comportas do hub,
   `sealed_until_sector`);
4. **desconhecido** — porta aberta, nunca visitado.

### Como uma fase nova entra no mapa
Nada de código. A fase precisa de:
- a entrada dela já existe em `data/map/station.json` (`docks`, `memory` → fase `memory_core`,
  `reactor` → fase `reactor_core`); `id` = `sector_id` do Terminal de Distribuição; `level` = nome
  do `data/levels/<level>.txt`; `scene` = `res://scenes/levels/<level>.tscn`;
- logs em `data/logs/<fase>.json` com `"sector"` igual ao `id` **ou** ao `level` do setor (o teste
  `test_every_log_sector_is_a_sector_of_the_station_map` reprova setor desconhecido);
- dados de pesquisa como `r` no ASCII (o id vem do JSON da fase, igual ao `LevelBuilder`);
- o teste `test_sector_counts_add_up_to_the_campaign_totals` reprova se a soma por setor não fechar
  com `Balance.LOGS_TOTAL`/`RESEARCH_TOTAL` — bumpar o Balance junto da fase.

### Autoloads / sinais do EventBus
- Nenhum sinal novo. Lê `GameState.sectors_restored`, `flags`, `collected_ids`, `checkpoint`.
- `GameState`: `mark_visited(scene_path) -> bool`, `has_visited(level_key) -> bool` (acréscimos).
- `QACapture`: evento `expect_call` (`{"expect_call": "GameState.is_timer_frozen", "equals": true}`).
- Pausa: `PauseMenu.overlay_owns_focus()` para o marco de foco.

### Dados (`data/`)
- `data/map/station.json` — setores e desenho.
- `data/ui/station_map.json` — textos (sem setas nem travessão: a m5x7 não tem).
- `data/ui/chassis_menu.json` — rodapé `[TAB] MAPA   [ESC] FECHAR`, bloco `ESTAÇÃO ARTEMIS`.

### Input actions / camadas de colisão
- `map` (TAB/Select), `ui_up/down/left/right`, `ui_cancel`, `pause`. Nenhuma ação nova.

## 7. Assets necessários

| Asset id | Uso nesta feature | Placeholder |
|---|---|---|
| — | Planta, cadeado e marcador desenhados em código (`draw_rect` pixel a pixel) | não precisa |
| [UI-FONT](../ASSETS.md#ui-font) | m5x7 em 16 px | — |

## 8. 🧑 Ação humana

Nenhuma.

## 9. Plano de execução

- [x] **Passo 1** — `StationMapModel` + `data/map/station.json` + `tests/test_station_map.gd`.
- [x] **Passo 2** — `station_map.tscn/.gd` (desenho, botões, foco radial, faixa de informação).
- [x] **Passo 3** — Página do mapa no Terminal do Chassi; item MAPA na pausa.
- [x] **Passo 4** — Marca de visita no `GameState`; marco `expect_call` no QA.
- [x] **Passo 5** — QA (`tests/qa/f67_*.json`), docs, commit.

## 10. Verificação

- **Testes (`tests/test_station_map.gd`):** sete setores na ordem; células únicas e no desenho do
  GDD; cena = nível; pré-requisitos válidos; estados em jogo novo, depois da Estufa e por visita;
  `mark_visited`; soma das contagens = `Balance`; contagem por coleta; ids de dado lidos da fase;
  vizinhos radiais e todos os setores alcançáveis pelas setas; textos sem glifo ausente; nomes
  cabem nas caixas e a faixa cabe na tela (medido com a fonte do tema); um botão por setor com os
  seis vizinhos de foco dentro do mapa; mapa no smoke, no chassi e no pause.
- **Testes (`tests/test_qa_marks.gd`):** comparação do marco `expect_call`.
- **Smoke:** `res://scenes/ui/station_map.tscn`.
- **Roteiros godot-qa:**
  - `tests/qa/f67_map_hub.json` — hub: TAB (diagnóstico), TAB (mapa), setas, timer congelado,
    TAB fecha e o TAB seguinte reabre.
  - `tests/qa/f67_map_pause_lab.json` — Laboratório com a Estufa religada: nasce na entrada
    (marco 5,42), pausa → MAPA, foco preso depois de 12 setas, ESC volta à pausa, timer congelado.
- **Playtest humano:** a planta se lê de relance em 384×216? o cadeado é reconhecível?

## 11. ADRs locais

### ADR-F67-001 — O mapa é a segunda página do Terminal do Chassi
- **Contexto:** o GDD dá `TAB` ao mapa; a F44 deu `TAB` ao Terminal do Chassi, e o humano pediu
  o mapa *dentro* desse terminal.
- **Decisão:** `[TAB]` abre o diagnóstico; `[TAB]` de novo troca para o MAPA; `[TAB]` no mapa e
  `[ESC]` em qualquer página fecham. A pausa tem o item MAPA. Registrado como AJ-052.
- **Consequências:** o tutorial da F44 continua certo; o mapa fica a dois toques; nenhuma ação nova.
- **Data:** 2026-11-20

### ADR-F67-002 — Contagem por setor sai dos dados, não de número no JSON
- **Contexto:** "logs x/y por setor" sem número mágico.
- **Decisão:** logs por `sector` dos `data/logs/*.json`; dados pelo símbolo de `kind research`
  da legenda do `LevelBuilder` no ASCII da fase, com o id resolvido igual ao construtor (cache
  estático por fase). Teste amarra a soma ao `Balance`.
- **Consequências:** fase nova conta sozinha; setor sem arquivo de fase mostra `0/0` (mas só
  aparece contagem para setor visitado/religado).
- **Data:** 2026-11-20

### ADR-F67-003 — Foco preso por vizinhos explícitos, não pelo `FocusTrap`
- **Contexto:** o `FocusTrap` liga os controles em lista circular (esquerda = anterior), o que
  quebraria a navegação radial.
- **Decisão:** cada botão de setor tem os 4 vizinhos + `focus_next/previous` apontando para botões
  do próprio mapa (ou para si mesmo). Teste confere os seis caminhos.
- **Data:** 2026-11-20

### ADR-F67-004 — Visita registrada em `flags`
- **Contexto:** "visitado sem energia" precisa de memória de visita; não existia.
- **Decisão:** `GameState._track_visit()` marca `flags["visited_<fase>"]` na primeira vez que a cena
  atual é uma fase. `flags` já vai no save; nenhum campo novo no formato.
- **Data:** 2026-11-20

## 12. Log de evolução

### 2026-11-20 — Feature criada e implementada
- **Quem**: agente de UI (worktree) · **O que**: modelo, dados, cena, página no chassi, item no
  pause, marca de visita, marco `expect_call`, testes e roteiros de QA.
- **Portões / QA:** **não rodados** — todo lançamento do Godot (até `--headless --version`) travou no macOS nesta sessão. Testes, smoke e roteiros (`tests/qa/f67_*`, `f33_*`) estão escritos; os critérios marcados `[x]` são de projeto, não de execução. **Próximo passo:** `tools/gates.sh`, os quatro roteiros de QA e leitura das capturas; só então `[x]` no INDEX.

### 2026-11-21 — Validação com Godot
- **Quem**: agente de integração (branch `final/integracao`) · **O que**: primeira execução com
  o Godot 4.7.2. Os scripts novos não tinham erro de tipagem nem de parse: o import e os
  930 testes passaram de primeira, menos um (abaixo). `tools/gates.sh` completo verde.
- **QA com marcos (todos OK):** `f67_map_hub` (23 marcos), `f67_map_pause_lab` (9; ganhou o
  marco de nascimento 5,42). Capturas lidas: `03_mapa_hub` (RELIGADOS 2/7, Estufa branca com
  corredor aceso, Laboratório tracejado, Enfermaria/Docas/Memória/Reator com cadeado, faixa
  `NÚCLEO CENTRAL · RELIGADO · VOCÊ ESTÁ AQUI · LOGS 1/2 · DADOS 1/1`), `03_mapa_no_laboratorio`
  (`LABORATÓRIO · SEM ENERGIA`). Texto todo em 16 px, acentos certos, nada cortado.
- **Conserto na ferramenta de QA:** `QACapture` ordenava os eventos com `sort_custom`, que **não é
  estável**: eventos do mesmo quadro rodavam fora da ordem do roteiro (`new_game` depois do
  `from_dict` apagava o checkpoint). Agora `QAMarks.ordered_events` desempata pela posição no
  roteiro; teste `test_events_in_the_same_frame_keep_the_script_order`.

### 2026-11-21 — Correção da revisão da campanha (grupo A)
- **Sala de comando no mapa**: dentro dela o mapa marcava "NÚCLEO CENTRAL — VOCÊ ESTÁ AQUI"
  (nenhum setor tinha a cena). O setor do Reator ganhou `extra_scenes` em
  `data/map/station.json` com a sala; `StationMapModel.is_current` confere a lista. Teste
  `test_the_command_room_counts_as_the_reactor_on_the_map`; QA `review_campaign_telas_sala` 8/8,
  `sala_2_mapa` mostra NÚCLEO DO REATOR — VOCÊ ESTÁ AQUI.
