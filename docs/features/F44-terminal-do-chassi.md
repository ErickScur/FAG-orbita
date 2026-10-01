---
id: F44
title: Terminal do chassi e HUD magro
status: done
scope: demo
block: 5
priority: P0
rubric: ["HUD", "Score de jogador (placar/contadores)", "Missões primárias", "Telas do jogo"]
depends_on: ["F15", "F36", "F37", "F09"]
unblocks: ["F47"]
estimate: 3h
last_updated: 2026-09-20
---

# F44 — Terminal do chassi e HUD magro

## 1. Contexto e objetivo

Terceiro playtest do humano, palavras dele:

> *"Acho que ainda da pra dar uma diminuida nas informações visuais da tela. Objetivo ser menor,
> com uma fonte menor. E talvez o reator, podemos fazer uma feature (e explicar no tutorial talvez,
> que a gente aperta um botao para abrir um menu/inventario, onde podemos ver a porcentagem do
> reator, os logs/dados coletados (tirar da tela talvez), e futuramente coisas como salas ou modulos
> visitados, ou até uma especie de mapa que vai desbloqueando conforme religamos a energia (e o
> resto fica com um ?? ou sem energia). Essa questao do mapa pode ficar para depois da demo"*

A [F37](F37-legibilidade-hud.md) já tinha rotulado e enxugado o HUD; o que sobrou de excesso é
**informação que não muda a decisão do próximo segundo**: a porcentagem do reator, os dois
contadores de coleta e um objetivo que ocupava três linhas no canto.

A F44 move essa informação para uma **tela de status sob demanda** — o *Terminal do Chassi*, aberto
com `[TAB]` — e deixa no HUD só o que o jogador usa enquanto pula: integridade, carga, status,
objetivo e prompt. A exceção é o reator em estado **crítico**, que volta ao HUD em vermelho:
esconder um cronômetro que está matando o jogador seria injusto.

Serve ao pilar **ESCASSEZ** (a leitura dos recursos continua existindo, só que consultada em vez de
gritada) e ao princípio desta rodada — *menos informação na tela, mais dedução*.

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.8 HUD](../design/GDD.md#gdd-2-8-hud) (regiões do HUD) ·
  [GDD-2.8 Telas](../design/GDD.md#gdd-2-8-telas) · [GDD-2.4 Controles](../design/GDD.md#gdd-2-4)
  (a ação `map` já estava documentada e mapeada em TAB) ·
  [GDD-2.5 Timer](../design/GDD.md#gdd-2-5-timer)
- **Parâmetros:** `Balance.REACTOR_CRITICAL`, `Balance.REACTOR_START`, `Balance.LOGS_TOTAL`,
  `Balance.RESEARCH_TOTAL`, `Balance.INTEGRITY_CELLS` ([GDD-P](../design/GDD.md#gdd-p)) —
  **nenhuma constante nova**.
- **Jornada:** [Etapa 2 — Chamado](../design/JORNADA-DO-HEROI.md#jh-2) (o MU-7 é um chassi de
  manutenção; um diagnóstico interno é diegético).
- **ADRs:** [ADR-003](../DECISIONS.md#adr-003) (384×216, fonte pixel em múltiplos de 16) ·
  [ADR-006](../DECISIONS.md#adr-006) (texto do jogador em `data/`) ·
  [ADR-010](../DECISIONS.md#adr-010) (Input Map)
- **Features:** [F15](F15-hud-objetivos.md) · [F37](F37-legibilidade-hud.md) ·
  [F36](F36-tutorial-briefing.md) (cartões de tecla) · [F09](F09-pause-recomecar.md) (FocusTrap,
  lição do foco que escapa)

## 3. Critério de avaliação atendido

| Item da rubrica | Como o avaliador vê |
|---|---|
| **HUD** | A tela de jogo mostra quatro leituras e nada mais: integridade, carga, status e objetivo. Cabe num olhar de um segundo. |
| **Score de jogador (placar/contadores)** | `FRAGMENTOS DE LOG n/4` e `DADOS DE PESQUISA n/4` continuam **visíveis em jogo** — agora no Terminal do Chassi, a um toque de TAB — e continuam na tela de **FIM DA DEMO** ([F10](F10-telas-fim-de-jogo.md)). O item segue atendido: na apresentação dá para pegar um dado, abrir o TAB e mostrar o contador em `1/4`. |
| **Missões primárias** | O objetivo continua fixo no canto superior direito, agora em uma linha só e em cor discreta. |
| **Telas do jogo** | Uma tela nova, com estética de diagnóstico do chassi, que pausa o jogo e fecha com a mesma tecla ou com ESC. |

## 4. Escopo

### Inclui
- `scenes/ui/chassis_menu.tscn` + `.gd` — tela de status aberta pela ação `map` (TAB).
- Conteúdo da demo: **ESTABILIDADE DO REATOR** (porcentagem + barra), **INTEGRIDADE** e **CARGA**
  em valor exato, **FRAGMENTOS DE LOG** e **DADOS DE PESQUISA**, **HABILIDADES** adquiridas.
- Espaço reservado e rotulado para depois da demo: **MAPA DA ESTAÇÃO** (`SEM ENERGIA`) e
  **SETORES VISITADOS** (`??`), sob o cabeçalho `AGUARDANDO ENERGIA`.
- HUD magro: saem o bloco do reator (fora do crítico) e os dois contadores fixos.
- Reator **volta ao HUD em vermelho** enquanto `reactor_critical` estiver ativo.
- Objetivo em uma linha, em cor discreta, com a fonte e o tamanho vindos do `Theme`.
- Cartão de tutorial `tut_chassis` no Núcleo Central + gatilho `core_t_chassis`.
- Linha `CHASSI  TAB` no painel `CONTROLES` da pausa.

### Não inclui
- **O mapa** — pedido explícito do humano para depois da demo. Aqui só existe o lugar dele,
  desenhado e rotulado como bloqueado.
- Registro de salas/módulos visitados (o `SETORES VISITADOS` é placeholder visual).
- Arquivo de logs navegável (`log_archive`, tecla L) — continua stretch ([F33](F33-arquivo-logs.md)).
- Troca da fonte do objetivo para a m3x6 — o arquivo da fonte ainda não está no projeto; a F44
  deixa a troca a **uma linha** de distância (ver ADR-F44-005).

## 5. Critérios de aceite

- [x] Em jogo normal o HUD mostra **apenas** integridade, carga, ícones de status, objetivo e
      prompt de interação.
- [x] `[TAB]` abre o Terminal do Chassi; `[TAB]` e `[ESC]` fecham.
- [x] A tela pausa o jogo (`get_tree().paused`) e processa com `PROCESS_MODE_ALWAYS`.
- [x] Abrir o terminal do chassi não abre a pausa, e abrir a pausa não abre o terminal do chassi
      (a tecla é consumida em `_input`, e `can_pause()` recusa com a árvore já pausada).
- [x] `[TAB]` é **ignorado** durante fala travante e durante leitura de log, o mesmo tratamento que
      a pausa recebe.
- [x] `[TAB]` é ignorado com um modal de foco na tela (Terminal de Distribuição, opções) e com o
      chassi perdido.
- [x] O terminal do chassi mostra reator (ou `SEM LEITURA` antes do alarme), integridade, carga,
      os dois contadores, as habilidades e o bloco bloqueado do mapa.
- [x] Abaixo de `Balance.REACTOR_CRITICAL` o bloco do reator reaparece no HUD, em vermelho, com
      `CRÍTICO`; acima, fica invisível.
- [x] Cada objetivo cabe em **uma linha** de 136 px na fonte do tema (coberto por teste).
- [x] A fonte e o tamanho do objetivo vêm da variação de tema `ObjectiveLabel`, não de
      `theme_override_font_sizes` na cena.
- [x] O cartão `tut_chassis` usa uma tecla que o diálogo **não** consome (`map` não está em
      `DialogueManager.ADVANCE_ACTIONS`) — coberto por teste.
- [x] Nenhum tamanho de fonte fora de múltiplo de 16.
- [x] Portões do `/CLAUDE.md` §6 verdes.
- [x] Sem comentários no código; nada 3D.

## 6. Definição técnica

### Cenas e scripts
```
scenes/ui/chassis_menu.tscn (+ chassis_menu.gd)   tela nova, CanvasLayer layer 40
scenes/ui/hud.tscn (+ hud.gd)                     sem contadores; reator só em crítico
scenes/ui/pause_menu.gd                           linha CHASSI + guarda em can_pause()
assets/ui/theme.tres                              variação de tema ObjectiveLabel
tests/qa/scenes/chassis_probe.tscn (+ .gd)        cena de prova do QA
```

**Árvore de `chassis_menu.tscn`** (`CanvasLayer` layer 40, `process_mode = ALWAYS`,
grupo `chassis_menu`, todos os `Control` com `mouse_filter = IGNORE` e **nenhum** focável):
```
ChassisMenu (CanvasLayer)
└─ Root (Control, full rect)
   ├─ Dim (ColorRect, #030507 a 92%)
   └─ Center (CenterContainer)
      └─ Panel (PanelContainer, 344 px, StyleBox opaco)
         └─ Body (VBoxContainer, separation 1)
            ├─ Title                "TERMINAL DO CHASSI MU-7"
            ├─ ReactorRow           rótulo + valor (%, ou SEM LEITURA)
            ├─ ReactorBar           ProgressBar 5 px
            ├─ Columns              esquerda: INTEGRIDADE / CARGA
            │                       direita:  FRAGMENTOS DE LOG / DADOS DE PESQUISA
            ├─ AbilitiesTitle       "HABILIDADES"
            ├─ Abilities            lista montada em tempo de execução
            ├─ LockedTitle          "AGUARDANDO ENERGIA"
            ├─ MapRow               "MAPA DA ESTAÇÃO"   -> "SEM ENERGIA"
            ├─ SectorsRow           "SETORES VISITADOS" -> "??"
            └─ Footer               "[TAB] FECHAR"
```
Altura medida: 192 px num viewport de 216 — 12 px de folga em cima e embaixo. Largura 344 px
(x = 20..364).

**`chassis_menu.gd`** — `can_open()` recusa quando: a árvore já está pausada; `SceneManager` está
em transição; `DialogueManager.is_active() and freezes_timer()` (fala travante **ou** leitura de
log); `GameState.is_dead()`; há um `Control` com foco (`gui_get_focus_owner() != null`, que cobre o
Terminal de Distribuição e as opções sem o chassi precisar conhecer essas cenas); a cena atual não é
fase nem está no grupo `gameplay`.

`open()` faz `get_tree().paused = true` e emite `EventBus.game_paused(true)` — é o mesmo contrato
da pausa, então o timer do reator congela sozinho e o HUD mostra o estado certo. `close()` desfaz.

### Autoloads / sinais do EventBus
- Emite `game_paused(true/false)` (sinal existente; nenhum sinal novo).
- Lê `GameState` (reator, integridade, carga, coleta, habilidades), `Balance`, `Settings`,
  `SceneManager`, `DialogueManager`, `AudioManager`, `ScenePaths`.
- Nenhum `get_node` para fora da própria cena.

### Dados (`data/`)
- **Novo:** `data/ui/chassis_menu.json` — 19 chaves de texto/template (título, rótulos, `%d%%`,
  `%d/%d`, nomes de habilidade, textos bloqueados, rodapé). Carregado por
  `HudModel.load_texts(path)`, que já aceitava caminho.
- `data/objectives.json` — textos encurtados para caber em uma linha:
  `obj_core_hub` "Atravessar o Núcleo Central e chegar à Estufa" → **"Chegar à Estufa"** (85 px);
  `obj_greenhouse` "Religar o Nó do Setor da Estufa" → **"Religar o Nó da Estufa"** (119 px).
- `data/tutorial.json` — cartão `tut_chassis` (`[TAB]` · `TERMINAL DO CHASSI` ·
  *reator, coleta e habilidades* · ação `map`).
- `data/levels/core_hub.json` — gatilho `core_t_chassis`, `rect [35, 7, 3, 5]`, entre o terminal de
  registros (col 31) e o corredor escuro (col 39). **Foi a única alteração feita nesse arquivo.**

### Input actions / camadas de colisão
- **Nenhuma ação nova.** A ação `map` já existia no `project.godot` e já estava em
  `physical_keycode 4194306` (**TAB**) + botão 4 do controle. `project.godot` **não foi tocado**.
- Nenhuma camada de colisão envolvida.

## 7. Assets necessários

| Asset id | Uso nesta feature | Placeholder |
|---|---|---|
| [UI-FONT](../ASSETS.md#ui-font) | m5x7 em 16 px em toda a tela nova | definitivo |
| [UI-HUD](../ASSETS.md#ui-hud) | nenhum ícone novo; os ícones 10/11 dos contadores **saíram** do HUD | — |
| (futuro) `font_m3x6` | fonte pixel menor para o objetivo — **ainda não está no projeto** | m5x7 em 16 px |

Nenhum asset novo entra no repo nesta feature.

## 8. 🧑 Ação humana

Nenhuma.

## 9. Plano de execução

- [x] **Passo 1** — conferir que a ação `map` existe e já está em TAB; decidir por não mexer no
      `project.godot`.
- [x] **Passo 2** — `data/ui/chassis_menu.json` + `chassis_menu.tscn`/`.gd`.
- [x] **Passo 3** — montar a tela pelo `hud.tscn` (ADR-F44-002) e travar os conflitos com a pausa.
- [x] **Passo 4** — HUD magro: contadores fora, reator só em crítico.
- [x] **Passo 5** — objetivo em uma linha, cor discreta, fonte saindo do `Theme`.
- [x] **Passo 6** — cartão `tut_chassis`, gatilho no Núcleo e linha `CHASSI` na pausa.
- [x] **Passo 7** — testes, portões e QA visual lido pelo agente.

## 10. Verificação

- **Testes:**
  - `tests/test_hud_chassis.gd` (**novo**, 13 casos): chaves obrigatórias do
    `data/ui/chassis_menu.json`; templates `%d%%` e `%d/%d`; nenhum glifo que a m5x7 não tem;
    nome da habilidade batendo com `ClimbLogic.ABILITY_ID`; cena registrada no smoke; o HUD
    instancia a tela; abre/fecha com `map`/`ui_cancel`, pausa a árvore e processa sempre; recusa
    durante fala travante e com modal de foco; `can_pause()` recusa com a árvore pausada; a pausa
    lista a linha `CHASSI`; o HUD perdeu os contadores fixos e o `_refresh_counters`; o bloco do
    reator só aparece em crítico; a variação de tema `ObjectiveLabel` existe, deriva de `Label`,
    declara fonte própria e tamanho 16, e os dois rótulos do objetivo a usam; **todo objetivo cabe
    em 136 px** medindo com a fonte real do tema.
  - `tests/test_tutorial.gd` (**ampliado**): `tut_chassis` entra em `REQUIRED_IDS` e no mapa de
    inputs esperados; entra na lista de cartões que **não** podem dividir tecla com
    `DialogueManager.ADVANCE_ACTIONS`; dois casos novos provam que a tecla anunciada é `[TAB]`, que
    `OS.get_keycode_string` da ação `map` é mesmo `Tab`, e que o Núcleo tem o gatilho.
  - Ajustados por causa do texto novo dos objetivos: `tests/test_objectives.gd`,
    `tests/test_reactor_state.gd`, e `TUTORIAL_ORDER` de `tests/test_level_core_hub.gd`.
- **Smoke:** `res://scenes/ui/chassis_menu.tscn` e `res://tests/qa/scenes/chassis_probe.tscn`
  em `tests/scenes.txt` — **71 cenas, 0 erro**.
- **Roteiros godot-qa:**
  - `tests/qa/f44_chassi.json` em `tests/qa/scenes/chassis_probe.tscn` — HUD limpo, terminal
    aberto, terminal fechado, reator crítico no HUD, cartão `[TAB]`, terminal aberto pela tecla do
    cartão, log em leitura e `[TAB]` ignorado durante a leitura.
  - `tests/qa/f44_nucleo.json` em `res://scenes/levels/core_hub.tscn` com `--qa-new-game` — a tela
    dentro da fase de verdade (reator ainda `SEM LEITURA`, nenhuma habilidade) e a pausa com a
    linha `CHASSI  TAB`.
- **Playtest humano:** abrir o TAB no meio de um pulo e conferir se a tela responde na hora; jogar
  até o reator ficar crítico e ver se o bloco vermelho aparece sem precisar abrir nada.

## 11. ADRs locais

### ADR-F44-001 — A tela é um diagnóstico do chassi, não um menu de sistema
- **Contexto:** o humano pediu "um menu/inventário". Um menu de sistema no meio da fase quebra a
  ficção de estar dentro de um robô de manutenção, e concorre com a pausa.
- **Decisão:** a tela se chama **TERMINAL DO CHASSI MU-7**, tem estética de leitura de sensor
  (rótulo apagado à esquerda, valor claro à direita) e **não tem botão nenhum** — é só leitura.
- **Consequências:** sem botões, não há foco para roubar, então o `FocusTrap` da
  [F09](F09-pause-recomecar.md) **não é necessário**; e a ausência de foco vira o próprio sinal que
  o terminal usa para detectar modais alheios (ADR-F44-003). Quando o mapa chegar (pós-demo) e a
  tela ganhar navegação, o `FocusTrap` volta a ser obrigatório.
- **Data:** 2026-09-20

### ADR-F44-002 — A tela é montada pelo HUD, não pelo `SceneManager`
- **Contexto:** a pausa é instanciada pelo `SceneManager` (autoload), o que a torna global. O
  terminal do chassi só faz sentido em gameplay — e `autoload/scene_manager.gd` e
  `scenes/levels/level_base.tscn` pertenciam a outros agentes nesta rodada.
- **Decisão:** `chassis_menu.tscn` é instanciado **dentro de `hud.tscn`** (CanvasLayer aninhado,
  layer 40 contra 10 do HUD). O HUD já é montado pelo `level_base` em toda fase e por todas as
  cenas de prova do QA, então a tela existe exatamente onde deveria existir e em lugar nenhum além
  disso — menu principal, opções e telas de fim não têm HUD, logo não têm TAB.
- **Consequências:** `CanvasLayer` aninhado funciona (confirmado por screenshot: a tela desenha
  sobre o mundo e sobre o HUD, e a pausa em layer 50 desenha sobre ela). Se um dia o HUD sair de
  alguma fase, o TAB sai junto — é um acoplamento a documentar, não um acidente.
- **Data:** 2026-09-20

### ADR-F44-003 — Modal alheio é detectado pelo foco, não por conhecer a cena
- **Contexto:** o Terminal de Distribuição (`energy_terminal_ui`) **não pausa a árvore**, então
  `get_tree().paused` não bastava para impedir o TAB por cima dele. Conhecer aquela cena pelo nome
  quebraria a regra de fronteira 4.2.1 (e o arquivo é de outro agente).
- **Decisão:** `can_open()` recusa quando `get_viewport().gui_get_focus_owner() != null`. Em
  gameplay nenhum `Control` tem foco (o HUD inteiro é `mouse_filter = IGNORE` e os cartões são
  `Label`); todo modal do projeto dá `grab_focus()` num botão ao abrir.
- **Consequências:** um teste guarda a regra. Qualquer modal futuro ganha a proteção de graça, sem
  o terminal do chassi precisar saber que ele existe.
- **Data:** 2026-09-20

### ADR-F44-004 — O reator volta ao HUD em estado crítico
- **Contexto:** o humano pediu o reator fora da tela. Mas o reator é um cronômetro que mata: abaixo
  de `Balance.REACTOR_CRITICAL` o jogador precisa **sentir** a pressão, e obrigá-lo a abrir um menu
  para descobrir que está morrendo é injusto.
- **Decisão:** o bloco do reator (`REATOR nn%` + barra + `CRÍTICO`) fica invisível no estado normal
  e **reaparece no topo-centro, em vermelho pulsante, enquanto `reactor_critical` estiver ativo**.
  No modo sem timer ele nunca aparece, porque `_critical` já nasce falso ali.
- **Consequências:** `_reactor_should_show()` passa a ser `is_reactor_online() and _critical`; o
  `_process` do HUD continua reavaliando por frame (ADR-F15-010), então o bloco aparece no frame
  seguinte ao alarme venha o estado por onde vier.
- **Data:** 2026-09-20

### ADR-F44-005 — O objetivo perde peso, não tamanho de fonte
- **Contexto:** o humano pediu "fonte menor". A regra dura 5 do `/CLAUDE.md` e a lição da
  F05/F03 proíbem: a **m5x7 só é nítida em múltiplos de 16**; em 8 ou 12 os glifos caem em meio
  pixel e derretem — bug que o próprio humano já relatou uma vez.
- **Decisão:** reduzir o **peso visual** em três frentes, sem tocar no tamanho do glifo:
  1. **uma linha só** — os dois objetivos foram encurtados (247 px → 85 px; 169 px → 119 px), o
     que derruba o bloco de três linhas para duas;
  2. **cor mais discreta** — o texto sai do ciano dos vitais (`#5fd4c8`) para `#96b1ba`, e o
     rótulo `OBJETIVO:` vai para `#49555f`, quase apagado (o rótulo fica, porque foi um pedido
     explícito do playtest anterior, registrado no ADR-F37-005);
  3. **altura do bloco** de 72 px para 36 px.
- **Preparação da troca de fonte:** os dois rótulos passaram a usar a variação de tema
  `ObjectiveLabel`, declarada em `assets/ui/theme.tres` com fonte e tamanho próprios. Trocar para a
  m3x6 quando o arquivo chegar é **uma linha**: em `assets/ui/theme.tres`,
  `[ext_resource type="FontFile" path="res://assets/fonts/ui_font.ttf" id="2_objectivefont"]` →
  `path="res://assets/fonts/m3x6.ttf"`. A m3x6 também tem tamanho nativo 16, então
  `ObjectiveLabel/font_sizes/font_size = 16` continua valendo e a varredura de múltiplos de 16
  continua limpa.
- **Consequências:** um teste mede cada objetivo com a fonte real do tema e falha se algum passar
  de 136 px — o guarda-corpo contra um objetivo novo que volte a quebrar em duas linhas.
- **Data:** 2026-09-20

### ADR-F44-006 — O cartão do tutorial usa `map`, que o diálogo não consome
- **Contexto:** a lição da F36 no §9: cartões cuja tecla está em `DialogueManager.ADVANCE_ACTIONS`
  (`interact`, `jump`, `ui_accept`) ficam bloqueados enquanto há fala na tela, e o cartão de
  escalar chegou a **nunca completar** por causa disso.
- **Decisão:** o cartão `tut_chassis` usa a ação `map`, que não está na lista. O gatilho fica em
  `rect [35, 7, 3, 5]`, logo depois do terminal de registros — o jogador acabou de ganhar o
  primeiro fragmento de log e a célula, então tem o que ver na tela.
- **Consequências:** `tut_chassis` entra no teste que varre os cartões livres da guarda de diálogo.
  A tecla também foi para o painel `CONTROLES` da pausa (`CHASSI  TAB`), lido do Input Map.
- **Data:** 2026-09-20

### ADR-F44-007 — `project.godot` não foi tocado
- **Contexto:** a tarefa previa ajustar a tecla da ação `map` "se fizesse sentido", e a lição do
  bootstrap avisa que o humano pode estar com o editor aberto e sobrescrever o arquivo.
- **Decisão:** a ação `map` já estava mapeada em `physical_keycode 4194306` (**TAB**) e no botão 4
  do controle — exatamente o candidato óbvio. Nada a mudar, então `project.godot` ficou intacto.
- **Consequências:** zero risco de conflito com o editor aberto. Um teste (`test_tutorial.gd`)
  ancora que a ação `map` continua em TAB, para o cartão nunca anunciar uma tecla errada.
- **Data:** 2026-09-20

## 12. Log de evolução

> Append-only. Mais novo no fim.

### 2026-09-20 — Feature criada e implementada
- **Quem**: Agente D da rodada "menos informação, mais puzzle".
- **O que**: Terminal do Chassi (`[TAB]`), HUD magro, reator de volta só em crítico, objetivo em
  uma linha e mais apagado, cartão de tutorial `tut_chassis` e linha `CHASSI` no painel de
  controles da pausa.
- **HUD antes → depois** (coordenadas medidas em 384×216):
  - **saíram**: bloco do reator no topo-centro (x 152..232, y 2..42) e a linha de contadores
    `LOGS n/4 · DADOS n/4` no rodapé direito (x 208..380, y 198..214);
  - **encolheu**: bloco do objetivo no topo direito de 3 linhas (y 2..74) para 2 (y 2..38), em cor
    discreta;
  - **ficaram**: células + `INTEGRIDADE` (y 2..18), barra + `CARGA` (y 18..34), ícones de status
    (y 34..50), prompt de interação (centro, y 180..198) e a pilha de avisos (y 92..146);
  - **volta condicional**: o bloco do reator reaparece em x 152..232 quando o reator está crítico.
- **Rubrica**: *Score de jogador* continua atendido — os contadores seguem visíveis em jogo, no
  Terminal do Chassi, e na tela de FIM DA DEMO. Registrado na seção 3.
- **Portões**: `--import` sem erro · `run_tests.gd` **593 passed, 1 failed** — a única falha é
  `test_level_greenhouse.gd::test_objective_and_dialogue_ids_exist` procurando `gh_spores`,
  `gh_terminal_first` e `gh_dark_corridor`, que o **Agente A apagou** de
  `data/dialogue/greenhouse.json` nesta mesma rodada (arquivo dele, falha dele) ·
  `tools/smoke.sh` **71 cenas, 0 erro** · varreduras 3D / comentários / fonte fora de múltiplo de
  16 vazias.
- **Arquivos de outros donos tocados e por quê**: `tests/test_objectives.gd` e
  `tests/test_reactor_state.gd` traziam o texto antigo dos objetivos **escrito à mão**, e
  `tests/test_level_core_hub.gd` trazia a lista fechada de cartões do Núcleo — três edições de uma
  linha cada, consequência direta desta feature.
- **Próximo passo**: o orquestrador registrar em [Ajustes de implementação](../design/GDD.md#gdd-ajustes)
  que o reator saiu do HUD permanente e que os contadores migraram para o Terminal do Chassi, e
  atualizar o esquema do [GDD-2.8](../design/GDD.md#gdd-2-8-hud). Quando a m3x6 entrar no repo,
  trocar a linha do `2_objectivefont` no `theme.tres` (ADR-F44-005). O mapa da estação fica para
  depois da demo, no espaço já reservado.
