---
id: F37
title: Legibilidade do HUD e dos coletáveis
status: done
scope: demo
block: 5
priority: P0
rubric: ["HUD", "Score de jogador (placar/contadores)", "Missões primárias"]
depends_on: ["F15", "F20", "F09"]
unblocks: []
estimate: 3h
last_updated: 2026-09-20
---

# F37 — Legibilidade do HUD e dos coletáveis

## 1. Contexto e objetivo

Playtest com o jogador humano, palavras dele: *"tem muita informação visual na tela/hud. fica
confuso oq é integridade, logs, dados, oq são essas coisas azuis no chao e as laranjas."*

O problema é **semântico**, não só de densidade: o HUD mostrava barras e contadores sem dizer o
que cada coisa é, e os cinco coletáveis do chão eram **o mesmo losango em cinco cores**. O jogador
via formas coloridas e não conseguia ligar nada ao que o HUD contava.

Esta feature ataca quatro frentes: rotular o que era anônimo, cortar linhas que não informam,
explicar cada coletável na primeira vez que o jogador o pega, e listar os controles na pausa.
Serve ao pilar **ESCASSEZ** (o HUD é a leitura dos recursos acabando) e protege o item de rubrica
*Score de jogador* — os contadores continuam visíveis em jogo, só que mais discretos.

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.8 HUD](../design/GDD.md#gdd-2-8-hud) (regiões do HUD; o esquema já previa
  `[||||] INTEGRIDADE`) · [GDD-2.8 Telas](../design/GDD.md#gdd-2-8-telas) (tela 3 — Pause) ·
  [GDD-2.4 Controles](../design/GDD.md#gdd-2-4) (nomes e teclas do painel de controles) ·
  [GDD-2.6.3 Itens](../design/GDD.md#gdd-2-6-3)
- **Parâmetros:** `Balance.INTEGRITY_CELLS`, `Balance.CHARGE_MAX`, `Balance.DASH_COST`,
  `Balance.LOGS_TOTAL`, `Balance.RESEARCH_TOTAL`, `Balance.HUD_TOAST_TIME`,
  `Balance.HUD_TOAST_SLIDE`, `Balance.HUD_TOAST_SLIDE_TIME` ([GDD-P](../design/GDD.md#gdd-p))
- **Jornada:** [Etapa 2 — Chamado](../design/JORNADA-DO-HEROI.md#jh-2)
- **ADRs:** [ADR-003](../DECISIONS.md#adr-003) (384×216, fonte pixel em múltiplos de 16) ·
  [ADR-005](../DECISIONS.md#adr-005) (placeholder-first)
- **Features:** [F15](F15-hud-objetivos.md) · [F20](F20-coletaveis-contadores.md) ·
  [F09](F09-pause-recomecar.md) (FocusTrap)

## 3. Critério de avaliação atendido

- **HUD** — o avaliador olha a tela e consegue nomear cada leitura: `INTEGRIDADE` e `CARGA` em
  duas linhas paralelas e alinhadas no topo-esquerdo, `REATOR nn%` com barra no topo-centro.
- **Score de jogador (placar/contadores)** — `LOGS n/4` e `DADOS n/4` continuam na tela o tempo
  todo, no rodapé direito, com o **ícone igual ao item que o jogador pega do chão**. Na
  apresentação dá para pegar um dado de pesquisa e mostrar o contador subindo.

## 4. Escopo

### Inclui
- Rótulo `INTEGRIDADE` ao lado das células, alinhado com `CARGA` (mesmo tamanho de fonte, 16).
- Reator com duas linhas (título + barra); a terceira linha fica **oculta no estado normal** e só
  aparece quando há algo a dizer: `TIMER PARADO` / `SEM TIMER` em ciano, ou `CRÍTICO` em vermelho
  (crítico tem prioridade).
- Contadores de logs e dados fundidos em **uma linha** discreta (cor apagada), lendo os totais de
  `Balance.LOGS_TOTAL` / `Balance.RESEARCH_TOTAL`.
- Cartão de duas linhas (nome + o que faz) na **primeira coleta de cada tipo**, gravado em
  `GameState.flags["seen_kind_<kind>"]` (persiste no save).
- Painel estático `CONTROLES` na pausa, com as teclas lidas do Input Map.
- **Um objetivo por fase**, fixo, vindo só do JSON da fase, no canto superior direito com o rótulo
  `OBJETIVO:`.
- Silhuetas distintas para os cinco coletáveis no gerador de placeholder, e ícones do HUD de log e
  de dado espelhando essas silhuetas.

### Não inclui
- Remapeamento de teclas no painel de controles (é leitura, não edição).
- Modo daltônico / tamanho de legenda (F08).
- Arte definitiva dos coletáveis (continua placeholder, ADR-005).

## 5. Critérios de aceite

- [x] Topo-esquerdo lê como duas linhas paralelas alinhadas: células + `INTEGRIDADE`, barra +
      `CARGA`, ambas com fonte 16 e o texto começando na mesma coluna.
- [x] Em estado normal o reator ocupa duas linhas (terceira linha invisível); com o timer
      congelado aparece `TIMER PARADO` em ciano (`SEM TIMER` no modo sem timer) e em estado
      crítico aparece `CRÍTICO` em vermelho, que vence quando os dois valem ao mesmo tempo.
- [x] `LOGS n/N` e `DADOS n/N` ocupam uma única linha no rodapé direito, em cor mais apagada que os
      vitais, e nunca somem durante o jogo.
- [x] Os contadores leem `Balance.LOGS_TOTAL` / `Balance.RESEARCH_TOTAL` (hoje 4 e 4), sem número
      fixo no HUD.
- [x] Na primeira coleta de cada tipo aparece um cartão de duas linhas com nome + função; a partir
      da segunda volta o aviso curto de antes.
- [x] O cartão nunca é cortado (animação vertical, sem `clip_contents`).
- [x] A pausa mostra `CONTROLES` com mover, pular, descer, interagir, lanterna, garras e pausa; a
      navegação por setas continua presa aos botões do menu.
- [x] Os cinco coletáveis têm silhuetas diferentes em 16×16 e os ícones do HUD combinam com eles.
- [x] Cada fase tem **um** objetivo, definido no carregamento, que não muda até a fase acabar;
      nenhum gatilho ou fala troca objetivo (coberto por teste).
- [x] O objetivo fica no canto superior direito, com `OBJETIVO:` apagado acima do texto em ciano,
      alinhados à direita, fonte 16, no máximo 3 linhas e sem corte.
- [x] Nada colide no topo: `INTEGRIDADE` termina em x=142, o bloco do reator ocupa x=152..232 e o
      objetivo x=244..380.
- [x] Portões do `/CLAUDE.md` §6 verdes.
- [x] Sem comentários no código; nada 3D.

## 6. Definição técnica

### Cenas e scripts
```
scenes/ui/hud.tscn (+ hud.gd)            layout novo dos vitais, reator, contadores e avisos
scenes/ui/pause_menu.tscn (+ .gd)        painel CONTROLES montado em _build_controls()
scripts/core/pickup_rules.gd             seen_flag(), first_text_id(), first_hint_id()
tools/make_placeholders.gd               shape "pickup_rows" + ícones 10/11 do hud_sheet
scenes/levels/greenhouse.gd              perdeu a máquina de passos que trocava objetivo
scenes/levels/core_hub.gd (removido)     existia só para trocar o objetivo na porta
tools/placeholders.json                  SPR-PICKUPS passa de "diamond_rows" a "pickup_rows"
data/hud_texts.json                      textos do HUD e dos cartões de primeira coleta
```

### Autoloads / sinais do EventBus
- Escuta `EventBus.collectible_picked(kind, item_id)` — nenhum sinal novo foi criado.
- Grava `GameState.flags["seen_kind_<kind>"]`, que já é serializado por `SaveManager`.

### Dados (`data/`)
- `data/hud_texts.json`: `reactor_title` agora é `REATOR %d%%`; novas chaves `reactor_critical`
  (`CRÍTICO`), `integrity_label`, `first_<kind>` e `first_<kind>_hint`;
  `counter_logs`/`counter_research` perderam o zero à esquerda (`LOGS %d/%d`) porque os totais da
  demo são de um dígito. `reactor_frozen` passou a valer `TIMER PARADO` e `reactor_no_timer`,
  `SEM TIMER`.
- Chave removida (não é mais exibida): `reactor_falling` (era o `descendo` permanente).
- `HudModel.reactor_state_id(critical, frozen, no_timer)` é lógica pura e decide qual chave mostrar
  — nenhuma string solta no `.gd`.
- `data/objectives.json`: **2 objetivos** (`obj_core_hub`, `obj_greenhouse`). O campo `objective`
  sumiu de todos os gatilhos de `data/levels/*.json` e de todas as sequências de
  `data/dialogue/*.json`; só o `objective` de topo de cada fase sobrevive.
- `data/hud_texts.json` ganhou `objective_label` (`OBJETIVO:`).

### Input actions / camadas de colisão
- Nenhuma ação nova. O painel de controles **lê** `InputMap.action_get_events()` das ações
  `move_left`, `move_right`, `move_down`, `move_up`, `jump`, `interact`, `flashlight`, `pause`.

## 7. Assets necessários

| Asset id | Uso nesta feature | Placeholder |
|---|---|---|
| SPR-PICKUPS | cinco coletáveis do chão, uma linha por tipo | `assets/placeholder/sprites/pickups/pickups_sheet.png` (regerado) |
| UI-HUD | ícones 10 (log) e 11 (dado) dos contadores | `assets/placeholder/ui/hud_sheet.png` (regerado) |
| UI-FONT | m5x7 em tamanho 16 em todo texto novo | definitivo |

## 8. 🧑 Ação humana

Nenhuma.

## 9. Plano de execução

- [x] **Passo 1** — medir o HUD atual por screenshot e achar o orçamento horizontal de 384 px.
- [x] **Passo 2** — reorganizar `hud.tscn` (linhas de vitais com coluna fixa, reator de 2 linhas,
      contadores em uma linha).
- [x] **Passo 3** — cartão de primeira coleta em `hud.gd` + helpers em `pickup_rules.gd`.
- [x] **Passo 4** — painel `CONTROLES` na pausa lendo o Input Map.
- [x] **Passo 5** — silhuetas dos coletáveis no gerador de placeholder e ícones do HUD.
- [x] **Passo 6** — testes, portões e QA visual.

## 10. Verificação

- **Testes (`tests/test_*.gd`):** `test_hud_model.gd` ganhou
  `test_counters_fit_the_demo_totals` (contador formatado a partir de `Balance`),
  `test_first_pickup_card_texts_exist` (todo `PickupRules.KINDS` tem nome e explicação),
  `test_first_pickup_ids_follow_the_kind` e `test_seen_flag_is_unique_per_kind`; a lista de chaves
  obrigatórias passou a cobrir `reactor_critical` e `integrity_label`.
- **Smoke:** nenhuma cena nova; `tests/scenes.txt` não foi tocado. As cenas afetadas
  (`hud_probe.tscn`, `pause_sandbox.tscn`, `pickup_test.tscn`) já estavam na lista.
- **Roteiro godot-qa:**
  - `tests/qa/f15_hud.json` em `tests/qa/scenes/hud_probe.tscn` — estado normal, dano, status com
    contagem, toasts e reator crítico.
  - `tests/qa/f37_pickups.json` em `scenes/dev/pickup_test.tscn` com `--qa-new-game` — os cinco
    itens no chão e o cartão da primeira célula, do primeiro kit e do primeiro dado.
  - `tests/qa/f37_pausa.json` em `tests/qa/scenes/pause_sandbox.tscn` — pausa com o painel de
    controles, navegação por setas e diálogo de confirmação por cima.
  - `tests/qa/f37_objetivo.json` em `scenes/levels/core_hub.tscn` — objetivo no canto no começo
    da fase, travessia passando pelos dois pontos onde antes ele trocava (o log e o corredor
    escuro) provando que não muda, troca de fase para a Estufa e os três blocos do topo juntos com
    o reator visível. O roteiro confirma progresso pelas posições que o log do QA imprime
    (5 → 20 → 36 → 51 → Estufa), como manda a lição do §9.
  - `tests/qa/f37_terminal_nucleo.json` / `f37_terminal_estufa.json` em `scenes/dev/core_test.tscn`
    e `scenes/dev/energy_test.tscn` — confirmam a linha `META:` dos dois Terminais de Distribuição.
  - `tests/qa/f37_reator.json` em `tests/qa/scenes/hud_probe.tscn` — os três estados da terceira
    linha do reator: normal (invisível), `CRÍTICO` e `TIMER PARADO`, mais o retorno ao normal.
    O `hud_probe.gd` ganhou os frames 364/404/444 (fim de fala + reator restaurado, log aberto,
    log fechado) **depois** do fim do roteiro da F15, que continua intacto.
- **Playtest humano:** abrir a fase, olhar 3 segundos para a tela e dizer em voz alta o que é cada
  leitura; pegar uma célula e um dado e conferir se o cartão explica.

## 11. ADRs locais

### ADR-F37-001 — Título do reator encurtado para `REATOR nn%`
- **Contexto:** em 384 px, `ESTABILIDADE DO REATOR: 100%` ocupa ~164 px centrados (x ≈ 110 a 274).
  Qualquer rótulo à direita das células de integridade colidia com ele.
- **Decisão:** encurtar o título para `REATOR %d%%` (~68 px). Libera o topo-esquerdo para
  `INTEGRIDADE` e reduz o volume de texto — que era a reclamação do jogador.
- **Consequências:** diverge do esquema ASCII do [GDD-2.8](../design/GDD.md#gdd-2-8-hud); precisa
  de uma linha em [Ajustes de implementação](../design/GDD.md#gdd-ajustes) (o orquestrador é dono
  do GDD). A palavra "Estabilidade" continua na narrativa e no diálogo.
- **Data:** 2026-09-20

### ADR-F37-002 — Estado do reator só quando há algo a dizer
- **Contexto:** a terceira linha mostrava `descendo` o tempo todo — informação que a barra já dá.
  A primeira versão desta feature apagou a linha inteira fora do estado crítico, o que desfazia
  metade de uma correção anterior: num playtest o humano reclamou que *"o log não 'pausa' o
  inimigo, esquisito não conseguir ler isso direito"*, e a resposta foi fazer fala/log travantes
  pausarem o mundo. Sem indicador textual, uma barra parada é ambígua demais — parece uma barra
  que está só descendo devagar.
- **Decisão:** a linha continua **oculta no estado normal** e aparece só quando há estado a
  comunicar, por prioridade: `CRÍTICO` (vermelho) vence; senão `SEM TIMER` (ciano) quando a opção
  de acessibilidade está ligada; senão `TIMER PARADO` (ciano) enquanto o timer está congelado por
  leitura de log, fala travante ou pausa. A escolha mora em
  `HudModel.reactor_state_id(critical, frozen, no_timer)`, lógica pura e testada.
- **Dois textos, de propósito:** `SEM TIMER` descreve uma configuração permanente que o jogador
  ligou nas opções; `TIMER PARADO` descreve um congelamento momentâneo causado pela ação atual.
  Usar `TIMER PARADO` no modo sem timer sugeriria que ele vai voltar a andar.
- **Consequências:** o `descendo` permanente não volta; ganha-se uma linha que só fala quando
  precisa. `reactor_falling` saiu do `hud_texts.json`.
- **Data:** 2026-09-20 (revisado no mesmo dia, a pedido do orquestrador)

### ADR-F37-003 — Barra de carga com largura limitada pelo slot
- **Contexto:** a barra crescia com `charge_max` (capacitores) e empurrava o rótulo `CARGA` para a
  direita, quebrando o alinhamento com `INTEGRIDADE`.
- **Decisão:** a coluna dos medidores é fixa em 68 px; a barra nasce com 60 px e cresce até no
  máximo 68 px (`minf(...)`). O ganho de capacidade continua sendo comunicado pelo aviso
  `CAPACIDADE MÁXIMA +n` e pelo cartão de primeira coleta do capacitor.
- **Consequências:** com dois capacitores a barra satura visualmente; o número não é exibido, então
  não há leitura errada, só menos ênfase no crescimento.
- **Data:** 2026-09-20

### ADR-F37-005 — Um objetivo por fase, vindo só do JSON da fase
- **Contexto:** eram 13 objetivos trocando em gatilhos, falas e scripts de fase. O jogador
  reclamou que o objetivo "fica mudando" e deixou de servir como referência.
- **Decisão:** um objetivo por fase, definido em `data/levels/<fase>.json` e aplicado por
  `level_base._apply_progress()`. Nenhuma outra fonte pode trocá-lo. `objective_changed` e o aviso
  `OBJETIVO ATUALIZADO` continuam vivos — agora disparam uma vez, na troca de fase.
- **Pré-condição verificada antes de apagar:** a orientação passo a passo não se perde porque os
  controles são ensinados pelos cartões da F36 e a meta de cada puzzle está na linha `META:` do
  Terminal de Distribuição. Conferido por QA nos dois terminais (`f37_terminal_nucleo.json` e
  `f37_terminal_estufa.json`) **antes** da remoção.
- **Consequências:** `scenes/levels/core_hub.gd` foi removido (existia só para isso) e o nó
  `Narrative` saiu de `core_hub.tscn`; `scenes/levels/greenhouse.gd` perdeu `_step`/`_advance` e
  mantém só a narrativa do fim de fase; `GameState.clear_objective()` saiu por não ter chamador.
  Restou plumbing genérico e guardado em `level_builder.gd`, `dialogue_trigger.gd` e
  `dialogue_manager.gd` (leem `objective` do dado e não fazem nada quando vazio) — são arquivos do
  Agente A/autoload e ficaram intactos de propósito.
- **Data:** 2026-09-20

### ADR-F37-006 — Reator estreitado para caber o objetivo no topo direito
- **Contexto:** com o objetivo subindo para y=2 na direita, o bloco do reator (176 px centrados,
  x=104..280) invadia o espaço dele.
- **Decisão:** como o título agora é curto (`REATOR nn%`, 68 px), o bloco do reator caiu para
  80 px (offsets -40..40 → x=152..232). O objetivo ocupa 136 px (x=244..380).
- **Consequências:** a barra do reator ficou mais curta; as folgas são de 10 px à esquerda
  (`INTEGRIDADE` termina em 142) e 12 px à direita. `TIMER PARADO` (74 px) ainda cabe centralizado
  nos 80 px.
- **Data:** 2026-09-20

### ADR-F37-004 — Silhueta antes de cor nos coletáveis
- **Contexto:** os cinco tipos eram o mesmo losango em cinco cores; sob a luz escura da estação
  azul (célula) e roxo (capacitor) ficavam quase iguais, e nada ligava o item ao contador do HUD.
- **Decisão:** cada tipo ganhou uma silhueta própria no gerador de placeholder — pilha (célula),
  maleta com cruz (kit de solda), documento com linhas (log), gema hexagonal (dado de pesquisa) e
  anel/bobina (capacitor). Os ícones 10 e 11 do `hud_sheet` passaram a repetir as silhuetas do log
  e do dado.
- **Consequências:** `tools/placeholders.json` trocou o `shape` do SPR-PICKUPS de `diamond_rows`
  para `pickup_rows`; quando a arte definitiva chegar ela precisa manter as mesmas silhuetas para
  não quebrar a ligação item ↔ contador.
- **Data:** 2026-09-20

## 12. Log de evolução

### 2026-09-20 — Feature criada e implementada
- **Quem**: agente B da revisão de jogabilidade (F36/F37/F38).
- **O que**: rótulo `INTEGRIDADE`, reator de duas linhas com estado só em crítico, contadores em
  uma linha discreta, cartão de primeira coleta por tipo, painel `CONTROLES` na pausa e silhuetas
  distintas para os cinco coletáveis.
- **Bug antigo corrigido de passagem**: `set_anchors_and_offsets_preset(PRESET_FULL_RECT)` usa
  `PRESET_MODE_MINSIZE`, então o aviso do HUD era dimensionado como `largura_do_pai + largura_mínima`
  e nascia **deslocado para a direita** (desde a F15). O aviso agora recebe `size`/`position`
  explícitos e finalmente fica centralizado. Isso vale como lição para qualquer `Control` criado por
  código antes do primeiro layout.
- **Portões**: `--import` sem erro · `run_tests.gd` 560 passed, 0 failed · `tools/smoke.sh`
  69 cenas, 0 erro · greps de 3D e de comentários vazios · QA visual lido pelo agente em
  `f15_hud.json`, `f37_pickups.json` e `f37_pausa.json`.
- **Próximo passo**: orquestrador registrar o AJ do título do reator na tabela de
  [Ajustes de implementação](../design/GDD.md#gdd-ajustes) e atualizar o esquema do GDD-2.8.

### 2026-09-20 — Revisão do ADR-F37-002 (pedido do orquestrador)
- **Quem**: agente B · **O que**: o indicador de timer congelado voltou, no mesmo padrão do
  `CRÍTICO` — terceira linha oculta no normal, `TIMER PARADO` em ciano com o timer congelado,
  `SEM TIMER` em ciano no modo sem timer, `CRÍTICO` em vermelho com prioridade sobre os dois.
- **Como**: `HudModel.reactor_state_id()` (lógica pura) + `REACTOR_STATE_COLORS` no `hud.gd`;
  textos de volta no `data/hud_texts.json`.
- **Testes novos** (`test_hud_model.gd`): `test_reactor_state_is_hidden_when_nothing_to_say`,
  `test_reactor_state_shows_frozen_timer`, `test_reactor_state_shows_no_timer_mode`,
  `test_reactor_state_critical_wins_over_frozen`.

### 2026-09-20 — Um objetivo por fase e objetivo no topo direito (pedido do humano)
- **Quem**: agente B · **Motivo (playtest)**: *"eu acho que só deveria ter um objetivo por fase, e
  nao ficar mudando ele. colocar ele mais pra cima na tela, tipo. direita em cima / objetivo: /
  religar bla bla bla"*.
- **Antes de apagar**: abri os dois Terminais de Distribuição no QA e li a linha `META:` —
  Núcleo: *"META: Abrir a porta do Setor Habitacional"*; Estufa: *"META: Abrir a Porta do Nó do
  Setor e religar o Nó"*, com as etiquetas `META` e `ROTA` nas linhas dos sistemas. A orientação
  que os objetivos intermediários davam continua disponível, então segui com a remoção.
- **O que mudou**: `data/objectives.json` de 13 para 2 objetivos; o campo `objective` saiu de 3
  gatilhos do Núcleo, 4 da Estufa, 1 do `test_room` e 1 sequência de diálogo; `greenhouse.gd`
  perdeu a máquina de passos; `core_hub.gd` foi removido junto com o nó `Narrative` da cena;
  `GameState.clear_objective()` saiu. O HUD ganhou o bloco `OBJETIVO:` + texto no topo direito e o
  reator encolheu para 80 px.
- **Testes novos** (`test_objectives.gd`, reescrito): `test_each_level_declares_its_own_objective`,
  `test_no_trigger_changes_the_objective` e `test_no_dialogue_changes_the_objective` varrem
  `data/levels/*.json` e `data/dialogue/*.json` inteiros — é o guarda-corpo contra a volta do
  objetivo que muda. `test_level_core_hub.gd` e `test_level_greenhouse.gd` trocaram o teste de
  "objetivo não repete na rota" por "nenhum gatilho troca o objetivo".
- **Portões**: `--import` limpo · `run_tests.gd` **569 passed, 0 failed** · `tools/smoke.sh`
  69 cenas, 0 erro · greps vazios · QA visual de 4 situações lido pelo agente.
- **Portões**: `--import` limpo · `run_tests.gd` 560 passed, 0 failed · `tools/smoke.sh` 69 cenas,
  0 erro · greps vazios · QA visual dos três estados em `f37_reator.json`.
