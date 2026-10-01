---
id: F38
title: Menos fala, mais história por fragmento
status: done
scope: demo
block: 7
priority: P0
rubric: ["Diálogo"]
depends_on: ["F19", "F20"]
unblocks: []
estimate: 2h
last_updated: 2026-09-20
---

# F38 — Menos fala, mais história por fragmento

## 1. Contexto e objetivo

Feedback literal do jogador humano na revisão de jogabilidade: *"tá com muito diálogo e
pouca gameplay. Deveria ser mais voltado para puzzles, e desbloquear fragmentos maiores da
história (menos fragmentos, com mais conteúdo, só que mais difícil de encontrá-los). Talvez
ÓRBITA esteja falando muito."*

A F19 entregou o canal narrativo (caixa de legenda, `DialogueManager`, JSON de falas e logs)
com um roteiro escrito em fatias pequenas: 7 logs curtos e muita fala ambiente de comentário
— inclusive cartões de tutorial de tecla disfarçados de fala da ÓRBITA. O resultado é que o
jogador ouve a IA o tempo todo e nunca recebe uma recompensa narrativa que pareça uma
recompensa.

Esta feature faz a poda: **corta fala que não ensina nem vira ponto de virada**, e **funde os
7 logs da demo em 4 logs grandes** (9 a 12 linhas cada). A ÓRBITA continua sendo a IA educada
em negação — esse é o coração do jogo e não foi mexido. O que saiu foi comentário. Serve os
pilares [AUSÊNCIA](../design/GDD.md#gdd-pilares) (todo aliado é uma gravação, e agora cada
gravação pesa) e ESCOLHA (o puzzle fala por si; a IA não narra mais cada botão).

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.8 HUD — Legendas](../design/GDD.md#gdd-2-8-hud) · [GDD-2.5 Timer](../design/GDD.md#gdd-2-5-timer) (log congela o timer) · [GDD-2.6.3](../design/GDD.md#gdd-2-6-3) (Fragmento de Log)
- **Parâmetros:** `Balance.LOGS_TOTAL` e `Balance.RESEARCH_TOTAL` ([GDD-P](../design/GDD.md#gdd-p)) — passam de 24/12 para **4/4**
- **Jornada:** [Etapa 3 — Mentor](../design/JORNADA-DO-HEROI.md#jh-3) (cada upgrade chega com um pedaço da verdade) · [Etapa 4 — Travessia do Limiar](../design/JORNADA-DO-HEROI.md#jh-4) · [Etapa 5 — Testes e Aliados](../design/JORNADA-DO-HEROI.md#jh-5) (Estufa: oxigênio caindo, culturas adaptadas) · [Contexto](../design/JORNADA-DO-HEROI.md#jh-contexto) (o planeta habitável)
- **ADRs:** [ADR-006](../DECISIONS.md#adr-006) (conteúdo em JSON)
- **Contrato da rodada:** `CONTRATO-REVISAO.md` (F36/F37/F38) — ids de log e de diálogo são o ponto de encontro entre os três agentes

## 3. Critério de avaliação atendido

**Diálogo.** O avaliador continua vendo legendas em pt-BR com o nome de quem fala, voz da
ÓRBITA e gravações degradadas da Helena com cabeçalho `[REC] REPRODUZINDO`. A diferença é de
ritmo: menos interrupção no meio do puzzle e um log que realmente conta alguma coisa quando
é encontrado. Na apresentação, abrir o log do Núcleo mostra em 10 linhas quem era a Helena,
o que é a ARTEMIS e por que o Terminal de Distribuição existe — o pitch do jogo inteiro.

## 4. Escopo

### Inclui
- Remoção das sequências `core_calib_move`, `core_calib_jump`, `core_log_hint` e
  `core_flashlight_hint` (viraram cartões de tutorial na F36).
- Poda das sequências travantes que ficam: `core_wake` 6→4, `core_alarm` 6→4, `hab_body` 4→3,
  `hab_first_sr3` 3→2, e a mesma poda na Estufa.
- Fusão dos logs: 7 → 4, cada um com 10–11 linhas.
- `Balance.LOGS_TOTAL` 24→4 e `Balance.RESEARCH_TOTAL` 12→4.
- Atualização dos testes de balance, de dados de diálogo e do `DialogueManager`.

### Não inclui
- Reposicionamento dos logs no mapa e remoção dos gatilhos das falas apagadas
  (`data/levels/*.json`) — **F36, Agente A**.
- HUD dos contadores — **F37, Agente B**.
- Tabela GDD-P em `docs/design/GDD.md` — **orquestrador** (ver §11).
- Mudança de mecânica do `DialogueManager`, da caixa ou do ritmo de digitação.

## 5. Critérios de aceite

- [x] `data/logs/` tem exatamente 4 logs, cada um com 9 a 12 linhas.
- [x] `log_gh_02` mantém `unlock_ability: magnetic_claws`.
- [x] Nenhuma palavra do twist (`DialogueData.FORBIDDEN_WORDS`) nos logs.
- [x] Toda linha de log e de fala cabe em `DialogueData.MAX_LINE_CHARS` (110).
- [x] O log aberto no jogo cabe na caixa de 384×216 sem cortar texto (QA por screenshot).
- [x] `Balance.LOGS_TOTAL == 4` e `Balance.RESEARCH_TOTAL == 4`, com `test_balance.gd` batendo.
- [x] Sem comentários no código; nada 3D.
- [ ] Portões do `/CLAUDE.md` §6 verdes — **depende da F36** (ver §10).

## 6. Definição técnica

### Cenas e scripts
```
scripts/core/balance.gd        LOGS_TOTAL, RESEARCH_TOTAL
```
Nenhuma cena nova. Nenhum script novo.

### Autoloads / sinais do EventBus
Nenhum sinal novo. `DialogueManager`, `EventBus.log_opened/log_closed` e
`EventBus.ability_unlocked` continuam iguais.

### Dados (`data/`)
- `data/dialogue/core_hub.json` — 14 → **10** sequências.
- `data/dialogue/greenhouse.json` — 20 sequências, textos enxutos.
- `data/logs/core_hub.json` — `log_core_01` (10 linhas), `log_hab_01` (11 linhas).
- `data/logs/greenhouse.json` — `log_gh_01` (11 linhas), `log_gh_02` (11 linhas, garras).

Logs apagados (conteúdo fundido, não perdido): `log_hab_02` → `log_hab_01` ·
`log_gh_02` → `log_gh_01` · `log_gh_03` + `log_gh_04` → `log_gh_02`.

### Input actions / camadas de colisão
Nenhuma alteração.

## 7. Assets necessários

| Asset id | Uso nesta feature | Placeholder |
|---|---|---|
| — | Feature de texto puro; nenhum asset novo | — |

## 8. 🧑 Ação humana

Nenhuma.

## 9. Plano de execução

- [x] **Passo 1** — Mapear todas as referências aos ids de log e de sequência fora de `data/`.
- [x] **Passo 2** — Reescrever `data/logs/*.json` com os 4 logs fundidos.
- [x] **Passo 3** — Podar `data/dialogue/*.json`.
- [x] **Passo 4** — `Balance.LOGS_TOTAL`/`RESEARCH_TOTAL` e `tests/test_balance.gd`.
- [x] **Passo 5** — Ajustar `tests/test_dialogue_data.gd`, `tests/test_dialogue_manager.gd`,
  `tests/test_abilities.gd` e `tests/test_run_stats.gd`.
- [x] **Passo 6** — Portões e QA visual do log aberto.

## 10. Verificação

- **Testes:**
  - `tests/test_balance.gd` — `LOGS_TOTAL: 4`, `RESEARCH_TOTAL: 4`.
  - `tests/test_dialogue_data.gd` — `test_demo_has_four_long_logs` passa a exigir 4 logs, entre
    9 e 12 linhas, e a bater com `Balance.LOGS_TOTAL`; `test_unlock_ability_only_on_the_claws_log`
    aponta para `log_gh_02`.
  - `tests/test_dialogue_manager.gd` — `DEMO_SEQUENCES` 34→30, `DEMO_LOGS` 7→4; os casos que
    usavam `core_calib_move`/`core_calib_jump` passaram a usar `core_bark_lights_on` e
    `core_lights_off`.
  - `tests/test_abilities.gd` e `tests/test_run_stats.gd` — corrigidos por consequência direta
    (ver §11, ADR-F38-002).
- **Resultado (2026-09-20):** `--import` limpo · `run_tests.gd` **527 passaram, 5 falharam** —
  as 5 são o aperto de mão com a F36 (`data/levels/core_hub.json` e `greenhouse.json` ainda
  apontam para `core_calib_move`, `core_flashlight_hint`, `log_hab_02`, `log_gh_03`,
  `log_gh_04`). Nenhuma falha está em arquivo da F38. · `tools/smoke.sh` **66 cenas, 0 erro** ·
  greps de 3D e de comentário vazios.
- **Smoke:** nenhuma cena nova.
- **Roteiro godot-qa:** `tests/qa/f38_log.json` sobre `res://scenes/dev/dialogue_test.tscn` —
  avança a abertura, abre `log_core_01` com `beam` e fotografa a primeira, a nona e a décima
  linha. As três screenshots mostram o texto quebrando em **duas linhas de tela**, dentro do
  painel, com acentos corretos e sem corte; a linha mais longa do roteiro (91 caracteres)
  ainda sobra meia linha de espaço.
- **Playtest humano:** confirmar que a ÓRBITA agora "cala a boca" durante o puzzle e que achar
  um log parece recompensa.

## 11. ADRs locais

### ADR-F38-001 — Os barks de energia continuam repetindo
- **Contexto:** o pedido da rodada era marcar `"once": true` em todos os `*_bark_*` para que
  não repetissem a vida inteira. Só que `tests/test_energy_data.gd::test_every_bark_exists_in_dialogue`
  exige explicitamente o contrário (`"fala '%s' precisa poder repetir"`), porque o bark é o
  **único feedback** que diz qual sistema acabou de ligar ou desligar no Terminal de Distribuição.
- **Decisão:** manter `"once": false` nos 14 barks de energia e cumprir a intenção do pedido
  pelo outro lado — cada bark foi reduzido a **uma linha curta** (alguns encurtados ainda mais,
  ex. `core_bark_lights_on` de 10 para 5 palavras).
- **Consequências:** o jogador continua sabendo o que mudou a cada toggle, sem parede de texto.
  Se o humano insistir em silenciar a repetição, o caminho certo é um cooldown no
  `DialogueManager`, não `once` — e aí `test_energy_data.gd` (arquivo da F36) precisa mudar junto.
- **Data:** 2026-09-20

### ADR-F38-002 — Testes fora da lista da F38 corrigidos por consequência direta
- **Contexto:** `tests/test_abilities.gd` (id fixo `log_gh_03`) e `tests/test_run_stats.gd`
  (`"VOCÊ NUNCA VAI LER 18 LOGS."` cravado, derivado de `LOGS_TOTAL = 24`) quebram só por causa
  das mudanças da F38 e não pertencem a nenhum outro agente da rodada.
- **Decisão:** corrigir os dois com a alteração mínima, trocando o literal pelo id novo e o
  número cravado por `Balance.LOGS_TOTAL`.
- **Consequências:** o `test_run_stats.gd` ficou imune à próxima mudança de `LOGS_TOTAL`.
- **Data:** 2026-09-20

### ADR-F38-003 — Tamanho de log: 9 a 12 linhas, uma frase falada por linha
- **Contexto:** "log maior" pode virar parede de texto ilegível em 384×216, ou dezenas de
  avanços de `[E]`.
- **Decisão:** 9 a 12 linhas por log (travado por `test_dialogue_data.gd`), cada linha uma
  frase falada de no máximo ~95 caracteres — duas linhas de tela na caixa.
- **Consequências:** um log inteiro custa ~10 avanços e o timer fica congelado o tempo todo
  ([GDD-2.5](../design/GDD.md#gdd-2-5-timer)), então não há pressão para pular a leitura.
- **Data:** 2026-09-20

## 12. Log de evolução

### 2026-09-20 — Poda de fala e fusão dos logs
- **Quem**: Agente C da revisão de jogabilidade
- **O que**: 65 → 45 linhas de fala da ÓRBITA (−31%), 4 sequências apagadas, 7 → 4 logs
  (39 → 43 linhas de log, concentradas em quatro achados), `LOGS_TOTAL`/`RESEARCH_TOTAL` = 4,
  testes ajustados, QA visual do log aberto lido por screenshot.
- **Próximo passo**: orquestrador sincroniza a tabela GDD-P (`LOGS_TOTAL` 24→4,
  `RESEARCH_TOTAL` 12→4); F36 reposiciona os 4 logs e remove os gatilhos órfãos nos
  `data/levels/*.json`; alguém precisa decidir o que fazer com
  `data/levels/energy_test.json`, que ainda aponta `log_on_restore: log_gh_03`.
