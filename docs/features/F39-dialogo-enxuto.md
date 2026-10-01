---
id: F39
title: Diálogo enxuto e no tempo certo
status: in-progress
scope: demo
block: 6
priority: P0
rubric: ["Diálogo"]
depends_on: ["F19", "F29", "F38"]
unblocks: []
estimate: 1.5h
last_updated: 2026-09-20
---

# F39 — Diálogo enxuto e no tempo certo

## 1. Contexto e objetivo

O ÓRBITA é um jogo de **puzzle**. Depois de jogar a Demo, o humano resumiu o problema
numa frase: *"precisamos dar menos informações, o jogador só vai saber o objetivo, e tem
que se virar. Não aplicar no tutorial, lá é exceção."*

Hoje a Estufa narra tudo. Vinte sequências de fala cobrem o setor inteiro: a ÓRBITA
explica o que são os esporos, avisa que dois circuitos não ligam cinco sistemas, conta que
a trepadeira virou escada, que o elevador parou, que o corredor escureceu. O jogador nunca
precisa olhar para o mundo — a legenda já disse o que aconteceu e por quê. Isso mata o
puzzle do Terminal de Distribuição, que é a mecânica central do jogo
([GDD-2.3](../design/GDD.md#gdd-2-3)).

O segundo problema é de ritmo: *"o diálogo da ÓRBITA falando garras magnéticas instaladas
está ficando muito tempo na tela (na verdade acho que todos os diálogos da ÓRBITA estão
ficando muito tempo)"*. Medido, `gh_claws` ficava **7,70 s** na tela — 2,10 s digitando e
**5,60 s** parada depois de terminar de digitar.

O terceiro é um vazamento de informação de design: o cartão da primeira coleta de Dado de
Pesquisa dizia *"coleta opcional, conta no placar"*, ou seja, ensinava o jogador a ignorar
o colecionável.

Esta feature corta as falas explicativas da Estufa, calibra o tempo de leitura da fala
ambiente e reescreve os textos de primeira coleta que entregavam informação demais. O
**Núcleo Central continua intocado**: ele é o tutorial e explica tudo.

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.3 Terminal de Distribuição](../design/GDD.md#gdd-2-3) (a decisão do
  jogador é o jogo; narrar o efeito a substitui) ·
  [GDD-2.5 Timer](../design/GDD.md#gdd-2-5-timer) (fala ambiente **não** congela o timer;
  fala travante e log congelam) ·
  [GDD-2.6.3](../design/GDD.md#gdd-2-6-3) (Dado de Pesquisa) ·
  [GDD-2.8 HUD — Legendas](../design/GDD.md#gdd-2-8-hud)
- **Parâmetros:** `Balance.DIALOGUE_CPS`, `Balance.DIALOGUE_READ_CPS`,
  `Balance.DIALOGUE_AMBIENT_MIN_TIME` ([GDD-P](../design/GDD.md#gdd-p))
- **Jornada:** [Etapa 3 — A Estufa](../design/JORNADA-DO-HEROI.md) (o tom da ÓRBITA
  continua o mesmo; o que muda é a quantidade, não a voz)
- **Features:** [F19 — Diálogo, legendas & logs](F19-dialogo-logs.md) ·
  [F29 — Fase Estufa](F29-fase-estufa.md) ·
  [F38 — Narrativa enxuta](F38-narrativa-enxuta.md)
- **Rodada:** contrato "menos informação, mais puzzle" (F39 · F40 · F41)

## 3. Critério de avaliação atendido

Item **Diálogo** da rubrica ([ENTREGAS.md](../ENTREGAS.md#rubrica)). O avaliador continua
vendo legenda com o nome de quem fala, fala travante com avanço por `[E]` e logs da Helena
— o que muda é que a Estufa fala cinco vezes em vez de vinte, e cada fala sai da tela em
tempo de leitura em vez de ficar parada.

## 4. Escopo

### Inclui
- Apagar de `data/dialogue/greenhouse.json`: `gh_spores`, `gh_terminal_first`,
  `gh_plant_grown`, `gh_dark_corridor`, `gh_rule_reminder` e os dez `gh_bark_*`.
- Calibrar `Balance.DIALOGUE_READ_CPS` com medição por quadro, não por chute.
- Reescrever `first_research_hint` e `first_capacitor_hint` em `data/hud_texts.json`.
- Testes de regressão que travam as três coisas.
- Cena-sonda e roteiro de QA que medem o tempo de fala em quadros.

### Não inclui
- Qualquer fala do Núcleo Central (`core_*`, `hab_*`) — é tutorial, fica como está.
- A tela do Terminal de Distribuição — é a [F40](F40-terminal-mudo.md) (Agente B).
- Escuridão e lanterna — é a [F41](F41-escuridao-de-verdade.md) (Agente C).
- Os gatilhos de fala órfãos em `data/levels/greenhouse.json` (ver §10 e §12).
- Tecla para dispensar fala ambiente (avaliada e recusada — ver ADR-F39-002).

## 5. Critérios de aceite

- [x] `data/dialogue/greenhouse.json` tem exatamente cinco sequências: `gh_enter`,
      `gh_node_room`, `gh_claws`, `gh_restored`, `first_death`.
- [x] Nenhuma fala da Estufa narra o efeito de ligar/desligar um sistema.
- [x] `core_hub.json` intacto: dez sequências, incluindo os quatro `core_bark_*`.
- [x] Uma linha ambiente típica da Estufa (84 caracteres) segura a tela entre 2,5 s e
      3,5 s depois de digitada, **medido em quadros** com `--fixed-fps 60`.
- [x] O cartão do Dado de Pesquisa não diz que a coleta é opcional.
- [x] A guarda do cartão de tutorial (`DialogueManager.ADVANCE_ACTIONS`) continua valendo
      — `test_tutorial.gd` verde.
- [ ] Portões do `/CLAUDE.md` §6 verdes (bloqueado por arquivo de outro agente — §12).
- [x] Sem comentários no código; nada 3D.

## 6. Definição técnica

### Cenas e scripts
```
autoload/dialogue_manager.gd          (não muda — só lê Balance)
scripts/core/balance.gd               DIALOGUE_READ_CPS 15.0 -> 28.0
tests/qa/scenes/dialogue_timing_probe.tscn (+ .gd)   cena-sonda de medição
```

### Autoloads / sinais do EventBus
Nada novo. `DialogueManager._ambient_hold(length)` continua sendo
`max(DIALOGUE_AMBIENT_MIN_TIME, length / DIALOGUE_READ_CPS)`; só o número mudou.

### Dados (`data/`)
- `data/dialogue/greenhouse.json` — 20 sequências / 25 falas → **5 sequências / 9 falas**.
- `data/hud_texts.json` — `first_research_hint` e `first_capacitor_hint`.

### Input actions / camadas de colisão
Nenhuma mudança. `ADVANCE_ACTIONS` permanece `[interact, jump, ui_accept]` e continua
sendo consumida **só** por fala travante e log.

## 7. Assets necessários

| Asset id | Uso nesta feature | Placeholder |
|---|---|---|
| — | Nenhum asset novo | — |

## 8. 🧑 Ação humana

Nenhuma.

## 9. Plano de execução

- [x] **Passo 1** — Varrer com `grep` todas as referências às quinze sequências antes de
      apagar qualquer coisa, e anotar de quem é cada arquivo.
- [x] **Passo 2** — Medir o estado atual: cena-sonda `dialogue_timing_probe` toca
      `gh_claws` num quadro conhecido e imprime em quantos quadros a fala some; roteiro
      `f39_tempo_de_fala.json` fotografa a escada de quadros para conferir na imagem.
- [x] **Passo 3** — Apagar as sequências e recontar (20 → 5).
- [x] **Passo 4** — Calibrar `DIALOGUE_READ_CPS` e medir de novo.
- [x] **Passo 5** — Reescrever os textos de primeira coleta.
- [x] **Passo 6** — Testes de regressão (`test_dialogue_manager.gd`,
      `test_pickup_rules.gd`, `test_balance.gd`).
- [x] **Passo 7** — Portões + QA lendo as próprias capturas.

## 10. Verificação

- **Testes (`tests/test_*.gd`):**
  - `test_dialogue_manager.gd::test_greenhouse_keeps_only_the_five_sequences` — lista
    explícita do que fica e do que foi cortado.
  - `test_dialogue_manager.gd::test_ambient_line_leaves_the_screen_in_reading_time` —
    chama `_ambient_hold(84)` e exige `2.5 <= hold <= 3.5`.
  - `test_dialogue_manager.gd::test_content_loaded` — `DEMO_SEQUENCES` 30 → 15.
  - `test_pickup_rules.gd::test_first_pickup_hints_do_not_say_the_pickup_is_skippable` —
    nenhum texto de primeira coleta contém "opcional".
  - `test_balance.gd` — espelho de `DIALOGUE_READ_CPS = 28.0`.
- **Smoke:** a cena-sonda `tests/qa/scenes/dialogue_timing_probe.tscn` **não** foi
  adicionada a `tests/scenes.txt` porque três agentes editam o repo ao mesmo tempo e o
  arquivo é compartilhado. Fica como pendência para o orquestrador.
- **Roteiro godot-qa:** `tests/qa/f39_tempo_de_fala.json` sobre
  `tests/qa/scenes/dialogue_timing_probe.tscn`, com `--fixed-fps 60`.
  A sonda toca `gh_claws` (84 caracteres, a fala das garras que o humano reclamou) no
  quadro 30 e o roteiro fotografa de 6 em 6 quadros (0,1 s) entre 150 e 558.
  A caixa deve aparecer por volta do quadro 31, estar completa no 150 e ter sumido antes
  do quadro 342.

  | | quadro em que a caixa some | tempo total na tela | espera depois de digitada |
  |---|---:|---:|---:|
  | antes (`READ_CPS` 15) | 493 (foto ainda cheia no 492, vazia no 498) | **7,70 s** | 5,60 s |
  | depois (`READ_CPS` 28) | 337 (foto ainda cheia no 336, vazia no 342) | **5,10 s** | 3,00 s |

- **Playtest humano:** jogar a Estufa inteira e confirmar que dá para entender o que cada
  sistema faz **olhando o mundo**, sem a ÓRBITA narrando.

## 11. ADRs locais

### ADR-F39-001 — `DIALOGUE_READ_CPS` sobe de 15 para 28
- **Contexto:** `_ambient_hold()` segura a fala por `comprimento / READ_CPS` segundos
  depois de ela terminar de digitar. Com 15 cps, a linha de 84 caracteres de `gh_claws`
  ficava parada 5,60 s, e a fala inteira ocupava 7,70 s de tela.
- **Decisão:** `DIALOGUE_READ_CPS = 28.0`. Em 84 caracteres dá exatamente 3,00 s de
  espera, o centro da faixa pedida (2,5–3,5 s), e 5,10 s de tela no total.
  `DIALOGUE_CPS` (40, velocidade da máquina de escrever) e
  `DIALOGUE_AMBIENT_MIN_TIME` (2,0 s, piso para linha curta) **não** mudam: mexer na
  máquina de escrever mudaria também a fala travante do tutorial, que ninguém reclamou.
- **Consequências:** toda fala ambiente do jogo encurta na mesma proporção, inclusive os
  `core_bark_*` do Núcleo — o piso de 2,0 s protege as linhas curtas (abaixo de 56
  caracteres o tempo não muda). Número novo para a tabela GDD-P.
- **Data:** 2026-09-20

### ADR-F39-002 — Não existe tecla para dispensar fala ambiente
- **Contexto:** avaliado se, além de encurtar, a fala ambiente deveria sumir na hora com
  uma tecla.
- **Decisão:** não implementar.
- **Consequências / porquê:** as três teclas candidatas já têm dono e o conflito é real,
  não teórico. `interact` é o `[E]` que abre terminal e lê log — e a Estufa tem fala
  ambiente na tela boa parte do tempo, então o mesmo aperto teria de escolher entre
  dispensar a legenda e acionar o mundo. `jump` é pulo. `ui_cancel` é a pausa. Pior: a
  guarda do cartão de tutorial (`scenes/ui/tutorial_card.gd`) ignora a tecla justamente
  quando ela está em `DialogueManager.ADVANCE_ACTIONS` e há diálogo na tela — foi a
  correção da lição §9 da F36, em que o cartão de escalar ficava preso para sempre. Fazer
  a fala ambiente consumir `interact` reabriria aquele bug pela porta dos fundos. Com a
  fala caindo de 7,70 s para 5,10 s o problema que motivava a tecla deixa de existir.
- **Data:** 2026-09-20

### ADR-F39-003 — Medir por sonda, não por olho
- **Contexto:** o pedido era "não chute: meça".
- **Decisão:** `tests/qa/scenes/dialogue_timing_probe.gd` toca a fala num quadro fixo,
  observa `DialogueManager.is_active()` e imprime quantos quadros a fala durou. O roteiro
  de QA fotografa a mesma janela de quadros para conferência visual, e a região da caixa
  de legenda nas fotos é comparada quadro a quadro (o brilho médio da faixa y 164–210
  salta de 38,9 para 67,7 no quadro em que a caixa some).
- **Consequências:** o número do relatório vem de duas fontes independentes que batem
  (sonda: 462 → 306 quadros; fotos: caixa cheia no 492 → 336). A sonda fica no repo e
  qualquer mudança futura em `READ_CPS` pode ser remedida do mesmo jeito.
- **Data:** 2026-09-20

## 12. Log de evolução

### 2026-09-20 — Implementação
- **Quem**: Agente A da rodada "menos informação, mais puzzle".
- **O que**:
  - `data/dialogue/greenhouse.json`: 20 sequências / 25 falas → 5 sequências / 9 falas.
    Apagadas `gh_spores`, `gh_terminal_first`, `gh_plant_grown`, `gh_dark_corridor`,
    `gh_rule_reminder` e os dez `gh_bark_*`. `core_hub.json` intocado (10 sequências).
  - `scripts/core/balance.gd`: `DIALOGUE_READ_CPS` 15.0 → 28.0 (ADR-F39-001).
    `tests/test_balance.gd` espelhado.
  - `data/hud_texts.json`: `first_research_hint` "coleta opcional, conta no placar" →
    "pesquisa da tripulação, conta no placar"; `first_capacitor_hint` "aumenta a Carga
    máxima para sempre" → "aumenta a Carga máxima do chassi" ("para sempre" era dica de
    estratégia, não descrição do objeto). Os três outros textos de primeira coleta
    (`first_cell_hint`, `first_repair_kit_hint`, `first_log_hint`) só nomeiam o que o
    objeto é e ficaram como estavam.
  - Testes novos: `test_greenhouse_keeps_only_the_five_sequences`,
    `test_ambient_line_leaves_the_screen_in_reading_time`,
    `test_first_pickup_hints_do_not_say_the_pickup_is_skippable`.
  - QA novo: `tests/qa/scenes/dialogue_timing_probe.{tscn,gd}` e
    `tests/qa/f39_tempo_de_fala.json`.
- **Medição**: `gh_claws` (84 caracteres) caiu de **462 quadros (7,70 s)** para
  **306 quadros (5,10 s)** na tela; a espera depois de digitada caiu de 5,60 s para
  3,00 s. Confirmado nas capturas (caixa cheia no quadro 336, tela limpa no 342).
- **Referências órfãs deixadas em arquivo de outro agente** (não editei, por contrato):
  - `data/levels/greenhouse.json:219` — gatilho `gh_t_spores` → `"dialogue": "gh_spores"`
  - `data/levels/greenhouse.json:230` — gatilho `gh_t_terminal` →
    `"dialogue": "gh_terminal_first"`
  - `data/levels/greenhouse.json:261` — gatilho `gh_t_corridor` →
    `"dialogue": "gh_dark_corridor"`
  - `scenes/dev/dialogue_test.gd:12` — `QUEUE_SECOND := &"gh_terminal_first"` (cena de
    desenvolvimento; sem dono nesta rodada)
  As três primeiras reprovam `test_level_greenhouse.gd::test_objective_and_dialogue_ids_exist`.
  As linhas `"group": "gh_spores"` do mesmo arquivo **não** são órfãs: ali `gh_spores` é
  nome de grupo de entidade, não id de fala.
- **Próximo passo**: alguém com posse de `data/levels/greenhouse.json` apaga o campo
  `dialogue` desses três gatilhos (os gatilhos em si podem ficar — `gh_t_terminal` e
  `gh_t_corridor` ainda delimitam zonas). Depois disso, `run_tests.gd` volta a 0.
