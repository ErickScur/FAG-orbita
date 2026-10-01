---
id: F36
title: Tutorial de verdade e apresentação do MU-7
status: in-progress
scope: demo
block: 5
priority: P0
rubric: ["Jogabilidade", "Telas do jogo"]
depends_on: ["F07", "F12", "F17", "F19", "F21", "F28"]
unblocks: []
estimate: 4h
last_updated: 2026-09-20
---

# F36 — Tutorial de verdade e apresentação do MU-7

## 1. Contexto e objetivo

O playtest humano foi direto: *"O tutorial em si, não está um tutorial, tá só uma fase sem
entender muito."* O jogador pediu duas coisas: (a) uma **apresentação de contexto** no boot do
MU-7 — quem ele é, onde está, o que precisa fazer — e (b) um **tutorial explícito**: "aperta tal
tecla para tal coisa", cobrindo porta, pular, descer e plataforma magnética.

A F36 responde com quatro peças: a **tela de briefing** entre o menu e o Núcleo; um **sistema de
cartões de tutorial** dirigido por dados; a **reconstrução do Núcleo Central** como uma sequência
didática em que cada cartão é seguido por um obstáculo que obriga a usar o comando ensinado; e um
**terceiro sistema no Terminal de Distribuição** do Núcleo, para o tutorial já ensinar a mecânica
central do jogo — energia é escolha — em vez de só um corredor.

Serve o pilar de **energia finita** ([GDD-2.5](../design/GDD.md#gdd-2-5-energia)) e responde ao
pedido de "mais puzzle, menos corredor".

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.4 — Controles](../design/GDD.md#gdd-2-4) (os cartões citam exatamente as teclas
  documentadas), [GDD-2.5 — Regra de energia](../design/GDD.md#gdd-2-5-energia),
  [GDD-2.5 — Timer](../design/GDD.md#gdd-2-5-timer)
- **Parâmetros:** `Balance.TILE_SIZE`, `Balance.JUMP_HEIGHT`, `Balance.WALK_SPEED`,
  `Balance.PLATFORM_SPEED` ([GDD-P](../design/GDD.md#gdd-p))
- **Jornada:** [Etapa 1 — O mundo comum](../design/JORNADA-DO-HEROI.md#jh-1),
  [Etapa 2 — O chamado](../design/JORNADA-DO-HEROI.md#jh-2)
- **ADRs:** [ADR-004](../DECISIONS.md#adr-004) (fases em ASCII), [ADR-006](../DECISIONS.md#adr-006)
  (conteúdo em JSON), [ADR-010](../DECISIONS.md#adr-010) (Input Map)
- **Feature irmã:** [F28 — Núcleo Central](F28-fase-nucleo-central.md) (a fase reconstruída aqui)

## 3. Critério de avaliação atendido

| Item da rubrica | Como o avaliador vê |
|---|---|
| Jogabilidade / curva de aprendizado | O jogo ensina cada comando na tela, e logo depois cobra o comando num obstáculo |
| Telas do jogo | Uma tela nova de briefing, com estética de terminal da estação, entre menu e fase |
| Mecânica principal legível | O tutorial termina num terminal de 3 sistemas / 1 energia: a troca fica óbvia |

## 4. Escopo

### Inclui
- `scenes/boot/briefing.tscn` + `.gd`, texto em `data/ui/briefing.json`.
- `scenes/ui/tutorial_card.tscn` + `.gd` (CanvasLayer próprio, montado em `level_base.tscn`).
- `scripts/core/tutorial_data.gd` (lógica pura) + `data/tutorial.json` (catálogo de 8 cartões).
- `scenes/world/tutorial_zone.tscn` + `.gd` e campo `"tutorial"` nos gatilhos de fase.
- Sinais `tutorial_requested` / `tutorial_completed` no `EventBus`.
- Núcleo Central reconstruído (`data/levels/core_hub.txt` / `.json`).
- Terminal `core_hub` com 3 sistemas e 1 unidade (`data/energy/core_hub.json`).
- Acerto dos dados da Estufa para o novo catálogo de 2 logs (`log_gh_01`, `log_gh_02`).

### Não inclui
- HUD (F37) e textos de diálogo/log (F38).
- Remapeamento de teclas, tutorial da Estufa além do cartão `tut_climb`.

## 5. Critérios de aceite

- [x] NOVO SISTEMA leva ao briefing; CONTINUAR segue indo ao checkpoint salvo.
- [x] O briefing revela o texto por máquina de escrever, avança com `[ESPAÇO]`/`[E]` e pula com `[ESC]`.
- [x] Um cartão por vez; o cartão não pausa o jogo e não rouba foco.
- [x] O cartão conclui com a tecla que ele mostra, exibe `[OK]`, some em 0,6 s e não volta.
- [x] A sequência do Núcleo é mover → pausa → pular → descer → interagir → lanterna → terminal.
- [x] Cada cartão tem um obstáculo depois dele que exige o comando ensinado.
- [x] O terminal do Núcleo tem 3 sistemas e 1 unidade, e nenhum estado tranca o jogo.
- [x] Portões do `/CLAUDE.md` §6 verdes.
- [x] Sem comentários no código; nada 3D.

## 6. Definição técnica

### Cenas e scripts
```
scenes/boot/briefing.tscn (+ briefing.gd)
scenes/ui/tutorial_card.tscn (+ tutorial_card.gd)
scenes/world/tutorial_zone.tscn (+ tutorial_zone.gd)
scripts/core/tutorial_data.gd        class_name TutorialData (lógica pura, testável)
scenes/world/dialogue_trigger.gd     + @export tutorial_id
scripts/core/level_builder.gd        + campo "tutorial" no gatilho
scenes/levels/level_base.tscn        instancia o TutorialCard
scenes/ui/main_menu.gd               NOVO SISTEMA -> briefing
```

### Autoloads / sinais do EventBus
- **Novos:** `tutorial_requested(tutorial_id: StringName)` — uma zona pede um cartão;
  `tutorial_completed(tutorial_id: StringName)` — o jogador executou a ação.
- **Estado:** `GameState.flags["<tutorial_id>"] = true` marca o cartão como aprendido (vai no save).

### Dados (`data/`)
- `data/tutorial.json` — `{ "<id>": { key, text, hint, actions[] } }`.
- `data/ui/briefing.json` — `{ header, blocks[{ title, fields[[k,v]], lines[] }] }`.
- `data/levels/*.json` — gatilho ganha `"tutorial": "<id>"` (convive com `dialogue`, `objective`,
  `set_flag`, `once`).
- `data/energy/core_hub.json` — 3 sistemas (`lights_core` VISÃO, `lift_core` ACESSO,
  `door_habitat` META), orçamento 1.

### Input actions / camadas de colisão
Nenhuma ação nova. A `tutorial_zone` usa `collision_layer = 0`, `collision_mask = 2` (player).

## 7. Assets necessários

| Asset id | Uso nesta feature | Placeholder |
|---|---|---|
| `font_m5x7` | Todo o texto do briefing e dos cartões | já definitivo |
| `bg_space_far` | Fundo estrelado do briefing | `assets/placeholder/backgrounds/space_far.png` |
| `sfx_ui_confirm`, `sfx_dialogue_blip` | Avanço de bloco e máquina de escrever | placeholders |

Nenhum asset novo.

## 8. 🧑 Ação humana

Nenhuma.

## 9. Plano de execução

- [x] **Passo 1** — Sinais no `EventBus`, `TutorialData` e `data/tutorial.json`.
- [x] **Passo 2** — `tutorial_card` + montagem em `level_base.tscn`.
- [x] **Passo 3** — `tutorial_zone` e campo `"tutorial"` nos gatilhos.
- [x] **Passo 4** — Briefing + ligação com o menu principal.
- [x] **Passo 5** — Núcleo Central reconstruído em ASCII com a sequência didática.
- [x] **Passo 6** — Terminal de 3 sistemas + elevador opcional com `data_core_01`.
- [x] **Passo 7** — Testes, smoke, QA visual, documentação.

## 10. Verificação

- **Testes:** `tests/test_tutorial.gd` (catálogo, inputs por cartão, largura do texto, glifos que a
  m5x7 não tem, cenas registradas, briefing lido de `data/`), `tests/test_level_core_hub.gd`
  (ordem didática dos cartões, cartão antes do obstáculo, puzzle de 3 sistemas, elevador serve o
  dado opcional), `tests/test_energy_data.gd` (`test_core_hub_is_three_one`,
  `test_core_hub_lift_is_an_optional_detour`, `test_core_hub_has_no_softlock` por força bruta em
  todos os subconjuntos).
- **Smoke:** `res://scenes/boot/briefing.tscn`, `res://scenes/ui/tutorial_card.tscn`,
  `res://scenes/world/tutorial_zone.tscn` adicionadas a `tests/scenes.txt`.
- **Roteiros godot-qa:** `tests/qa/f36_briefing.json` (cinco blocos + ida para a fase),
  `tests/qa/f36_briefing_pular.json` (`[ESC]` pula tudo), `tests/qa/f36_tutorial.json`
  (a sequência inteira do Núcleo, exercitando **as teclas que o GDD-2.4 documenta**).
- **Playtest humano:** ele deve conseguir terminar o Núcleo sem perguntar nada, e dizer se o
  briefing tem texto demais.

## 11. ADRs locais

### ADR-F36-001 — O cartão de tutorial é um `CanvasLayer` próprio, não parte do HUD
- **Contexto:** o HUD já estava saturado (queixa do jogador) e está sendo reescrito na F37.
- **Decisão:** o cartão vive em `scenes/ui/tutorial_card.tscn`, `layer = 9` (abaixo do HUD 10, do
  diálogo 30, do terminal 20 e da pausa 50), instanciado por `level_base.tscn`.
- **Consequências:** zero acoplamento com a F37; o cartão sempre fica atrás de qualquer modal.
- **Data:** 2026-09-20

### ADR-F36-002 — O texto do cartão evita setas e ✓
- **Contexto:** a m5x7 **não tem** os glifos `←` `→` `↑` `↓` `✓` `—`, e o `.import` da fonte está
  com `allow_system_fallback=true`, então esses caracteres cairiam numa fonte do sistema e sairiam
  borrados no meio do pixel art.
- **Decisão:** os cartões usam palavras (`[SETAS]`, `[BAIXO]`, `[CIMA]`) e `[OK]` no lugar do ✓ —
  a mesma linguagem que a tela de carregamento já usa. Um teste guarda a regra.
- **Consequências:** o texto foge à letra da tabela do contrato, mantendo o sentido.
- **Data:** 2026-09-20

### ADR-F36-003 — O cartão ignora a tecla que está avançando um diálogo
- **Contexto:** `interact` e `jump` também avançam falas travantes. O cartão `tut_terminal` nasce
  junto com a fala `core_terminal_first`: sem proteção, a primeira tecla de avanço "concluía" o
  cartão sem o jogador ter tocado no terminal.
- **Decisão:** o cartão guarda o estado do `DialogueManager` do frame anterior e ignora a tecla se
  havia fala ativa. Um frame de atraso é de propósito: quando a tecla **abre** um log, o estado
  anterior era "sem fala", então o cartão conclui corretamente.
- **Consequências:** o cartão conclui com a ação real, não com o avanço da fala.
- **Data:** 2026-09-20

### ADR-F36-004 — O elevador de serviço é uma recompensa opcional, não um portão
- **Contexto:** o terminal precisava de um terceiro sistema para ensinar escassez, sem risco de
  travar o jogador.
- **Decisão:** `lift_core` alimenta uma `moving_platform` num poço que sobe até um nicho com
  `data_core_01`. O poço fica **antes** do terminal no caminho, então dá para voltar e trocar a
  energia em qualquer estado. O nicho tem piso sólido e o poço tem fundo: nunca se fica preso.
- **Consequências:** o jogador vive "energia é escolha" antes mesmo de precisar abrir a porta.
- **Data:** 2026-09-20

## 12. Log de evolução

### 2026-09-20 — Implementação
- **Quem**: Agente A da revisão de jogabilidade · **O que**: briefing, sistema de cartões, Núcleo
  Central reconstruído como tutorial e terminal de 3 sistemas · **Próximo passo**: o orquestrador
  precisa sincronizar a GDD-P/INDEX e, se quiser, pedir à F38 as falas do elevador.

### 2026-09-20 — QA visual e ajustes achados por screenshot
- **Quem**: Agente A · **O que**:
  1. **Posição do cartão** — a primeira posição (`offset_top -92`) batia de frente com a pilha de
     avisos do HUD novo (F37, y 92..146): a screenshot mostrou "OBJETIVO ATUALIZADO" escrito por
     cima do cartão. Posição final: `offset_top -76 / offset_bottom -40` (y 140..176), entre os
     avisos (terminam em ~146) e o prompt de interação (começa em 180). Confirmado numa screenshot
     com aviso + cartão + prompt na tela ao mesmo tempo, os três legíveis e sem sobreposição.
  2. **Curso do elevador** — com `path [[0,0],[0,-6]]` a plataforma parava 12 px acima do chão e
     **não carregava o jogador**: ele ficava pisando no piso enquanto ela subia por dentro dele
     (one-way só segura por cima). Corrigido para `[[0,0.75],[0,-5.5]]`: embaixo a superfície fica
     rente ao piso (y 192) e em cima 4 px acima do nicho (y 92 contra 96). A screenshot seguinte
     mostra o jogador subindo (linha 11 → 9 → 6 → 5) e andando para dentro do nicho do
     `data_core_01`.
  3. **Velocidade do elevador** — os campos `speed`/`wait` saíram do JSON da fase: a plataforma usa
     `Balance.PLATFORM_SPEED` e `Balance.PLATFORM_WAIT`, sem número mágico em dado de fase.
  4. **Ritmo do briefing** — 46 caracteres/s ficou arrastado na captura; subiu para 60.
- **Portões**: import 0 erros · 560 testes, 0 falhas · smoke 69/69 · varreduras vazias.

### 2026-09-20 — `log_gh_01` saiu da rota principal e o elevador da Estufa foi acertado
- **Quem**: Agente A (pedido do orquestrador) · **O que**:
  1. **`log_gh_01` reposicionado** de `(7,37)` — que ficava literalmente entre o spawn e o primeiro
     pilar da rota — para `(37,26)`, uma saliência de 1 tile do outro lado do poço do elevador de
     carga, na Zona B. Piso novo em `(37,27)`; vão de 4 tiles (cols 33-36) separa a saliência do
     chão da Zona B. Só se chega lá **subindo o elevador e pulando para a direita no topo**, o que
     custa ligar `lift_platform` (que exige `heating` e obriga a apagar `corridor_light`) — a mesma
     escolha de energia que o elevador do Núcleo ensina na fase anterior.
  2. **Elevador da Estufa acertado** — tinha o mesmo defeito do Núcleo: parava 12 px acima do chão
     e **subia por dentro do jogador** sem carregá-lo. `path` passou de `[[0,0],[0,-10]]` para
     `[[0,0.75],[0,-9.25]]`: embaixo rente ao piso (y 608) e em cima rente ao piso da Zona B
     (y 448), com a saliência 16 px acima — subida de graça, pulo para a direita deliberado.
  3. **`tests/qa/e2e_menu_to_level.json` atualizado** para a sequência nova (menu → NOVO SISTEMA →
     confirmação → briefing → `[ESC]` → loading → Núcleo) e rodado de ponta a ponta.
- **Testes novos**: `test_the_first_log_hangs_off_the_lift_shaft`,
  `test_the_first_log_is_never_on_the_walking_route` (confere contra as constantes `ROUTE_*`),
  `test_the_first_log_ledge_always_lets_you_leave` (prova estrutural de que dá para cair de volta
  na Zona A), `test_reaching_the_first_log_costs_a_system`,
  `test_the_lift_docks_level_with_both_floors` e, no Núcleo,
  `test_the_lift_docks_level_with_the_floor_and_the_niche`.
- **Portões**: import 0 erros · 564 passaram · smoke 69/69 · varreduras vazias.
