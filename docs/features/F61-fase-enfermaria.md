---
id: F61
title: Fase 3 — Enfermaria (Inverno, V-9, Congelamento, Núcleo Aquecido)
status: done
scope: final
block: 6
priority: P0
rubric: ["Desenvolvimento de 4 fases com dificuldades diferentes", "Efeitos naturais", "Puzzle", "Inimigos", "Nível (progressão)", "Luz/Sombra"]
depends_on: ["F60", "F31"]
unblocks: ["F62", "F68"]
estimate: 2d
last_updated: 2026-10-27
---

# F61 — Fase 3 — Enfermaria (Inverno, V-9, Congelamento, Núcleo Aquecido)

## 1. Contexto e objetivo

Terceira fase de verdade. A Enfermaria é o setor do **Inverno**: "escura, estreita, congelada.
Exploração lenta de propósito (CONGELAMENTO + gelo escorregadio) enquanto o timer corre"
([GDD-2.7 F3](../design/GDD.md#gdd-2-7-f3)). Introduz a **Sentinela Voadora V-9** e o **dilema
da lanterna** — ver é ser visto —, o status **CONGELAMENTO** e o upgrade **Núcleo Aquecido**. É
a fase de carga narrativa mais pesada até aqui: os leitos mostram a ordem em que a tripulação
adoeceu.

Pilares: **energia é escolha** (o aquecimento protege e abre o gelo até o MU-7 ganhar o Núcleo
Aquecido; depois disso, cortá-lo é o que abre o Nó) e **luz é informação** (a lanterna que mostra
o buraco também mostra o MU-7 para a V-9).

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.7 F3 — Enfermaria](../design/GDD.md#gdd-2-7-f3) ·
  [GDD-2.6.2-C — V-9](../design/GDD.md#gdd-2-6-2-c) ·
  [GDD-2.6.2-E — gelo fino, escuridão](../design/GDD.md#gdd-2-6-2-e) ·
  [GDD-2.6.2-F — CONGELAMENTO](../design/GDD.md#gdd-2-6-2-f) ·
  [GDD-2.6.1 habilidades (Núcleo Aquecido)](../design/GDD.md#gdd-2-6-1-habilidades) ·
  [GDD-2.3 (o exemplo do aquecedor que derrete o gelo)](../design/GDD.md#gdd-2-3) ·
  [GDD-2.9 paleta (ciano pálido, branco de gelo, sombras longas e azuis)](../design/GDD.md#gdd-2-9-paleta)
- **Parâmetros:** `Balance.V9_*`, `FREEZE_*`, `THIN_ICE_*`, `ICE_MELT_TIME`, `LOGS_TOTAL`,
  `RESEARCH_TOTAL` ([GDD-P](../design/GDD.md#gdd-p)); ajustes [AJ-043, AJ-044, AJ-045](../design/GDD.md#gdd-ajustes)
- **Jornada:** [Etapa 5 — Enfermaria: a ordem em que a tripulação adoeceu](../design/JORNADA-DO-HEROI.md#jh-5)
- **Referência viva:** Laboratório ([F60](F60-fase-laboratorio.md)) — mesmo arco de puzzle, mesmas
  ferramentas (`revisit`, `sector_narrative`, zona/ilha, `entity_tiles`, `test_energy_bindings`);
  Dash e Feixe da [F31](F31-dash-feixe.md); skill `level-design`
- **ADRs:** [ADR-004](../DECISIONS.md#adr-004) · [ADR-005](../DECISIONS.md#adr-005) · ADR-F60-001/002/003

## 3. Critério de avaliação atendido

- **Desenvolvimento de 4 fases com dificuldades diferentes:** 4ª fase jogável (6/10).
- **Inimigos:** V-9 que voa, persegue atravessando o cenário e gruda drenando Carga.
- **Luz/Sombra:** a lanterna como escolha tática, não como conforto.
- **Efeitos naturais:** frio que deixa o MU-7 lento e escorregando, gelo que racha e se refaz,
  paredes de gelo que derretem.
- **Nível (progressão):** Núcleo Aquecido.

Na apresentação: atravessar a Ala de Leitos no escuro com a V-9 patrulhando, acender a lanterna
para ver o buraco e ser perseguido; desligar a V-9 com o Feixe; derreter a parede de gelo depois
do upgrade.

## 4. Escopo

### Inclui

**A. Ligação entre setores** — religar o Laboratório leva ao Núcleo (o `lab.tscn` ganha
`next_scene`); o bloco `revisit` vira **lista ordenada** (vale a última entrada cujo
`after_sector` já foi religado). Depois do Laboratório: comporta da Enfermaria destravada, saída do
Laboratório selada (até a F45), objetivo `obj_core_infirmary`, fala de marco `core_return_lab`,
Núcleo ainda mais claro. Antes disso a comporta da Enfermaria aparece selada. Religar a
Enfermaria → cutscene → fala → tela de fim (frase de fechamento por último setor religado).

**B. Sistemas novos**
- **V-9** (`Y` no ASCII): drone que patrulha um trilho (`path` no JSON). Detecta o MU-7 a
  `V9_VISION_RANGE` **se ele estiver iluminado** (lanterna acesa ou dentro da luz de uma lâmpada
  ligada); no escuro, só a `V9_DARK_VISION`. O **dash** a menos de `V9_HEAR_RADIUS` também o
  denuncia. Detectou → persegue em linha reta **atravessando o cenário** a `V9_CHASE_SPEED` por até
  `V9_CHASE_TIME`; perde o alvo se ele ficar `V9_LOSE_TIME` sem ser visto. Contato: `V9_CONTACT_DAMAGE`,
  **sem knockback**, gruda por `V9_LATCH_TIME` drenando `V9_LATCH_DRAIN` de Carga/s, depois solta e
  volta ao trilho. Feixe → `shutdown()` (cai e fica inerte). `powered` pelo terminal.
- **Zona fria** (`h` com `"kind": "cold"`, a mesma zona de clima da F60): aplica CONGELAMENTO.
  **Aquecedor** = a ilha (`i`) com `"kind": "warm"` ligado ao `heating`: anula o frio dentro dele.
- **CONGELAMENTO real**: velocidade × `FREEZE_SPEED_MULT`, pulo × `FREEZE_JUMP_MULT`, chão
  escorregadio (desaceleração × `FREEZE_DECEL_MULT`). O Núcleo Aquecido dá imunidade.
- **Gelo fino** (`_` no ASCII): plataforma que racha ao ser pisada e cai `THIN_ICE_BREAK_TIME`
  depois; refaz em `THIN_ICE_REFORM_TIME`.
- **Parede de gelo** (`I` no ASCII): bloqueia a passagem. Derrete (`ICE_MELT_TIME`) **enquanto o
  aquecedor do grupo dela estiver ligado** — e volta a congelar quando ele desliga —, ou quando o
  MU-7 **com Núcleo Aquecido** encosta nela (essa não volta).
- **Núcleo Aquecido** (`heated_core`): entregue pelo log da Helena no meio da fase.

**C. A fase** — `scenes/levels/infirmary.tscn`, `data/levels/infirmary.{txt,json}`,
`data/energy/infirmary.json`, `data/logs/infirmary.json`, `data/dialogue/infirmary.json`,
objetivo `obj_infirmary`.

### Não inclui
- Portas de mão dupla entre setores (F45); mapa da estação (F67).
- Propulsor/pulo duplo (F62). SOBRECARGA (F68).
- Música própria: toca `core` até o humano trazer `infirmary` (🧑 §8).

## 4.1 Puzzle no papel

**Terminal `infirmary`, orçamento 2, 6 sistemas, inicial `[sentinels, heating]` (2/2).**
Consoles: **B** no fim da Ala de Leitos, **C** no patamar de cima antes da comporta da
quarentena. **Nenhum console antes da Ala** (a V-9 tem de ser enfrentada com lanterna, cobertura e
Feixe) e **nenhum depois da comporta da quarentena** (ADR-F60-001).

| id | Nome no terminal | Custo | Requer | Ligado | Desligado | Onde se vê |
|---|---|:-:|---|---|---|---|
| `sentinels` | SENTINELAS V-9 | 1 | — | V-9 patrulhando | V-9 pousam e apagam | Ala de Leitos (B vê uma) |
| `heating` | AQUECIMENTO | 1 | — | aquecedores acesos; paredes de gelo do alcance deles derretem | frio em toda parte; paredes recongelam | Ala, patamar (C fica num aquecedor), ala de quarentena |
| `stretcher_lift` | ELEVADOR DE MACAS | 1 | `heating` | elevador anda | para onde estiver | poço ao lado de B |
| `pharmacy_door` | FARMÁCIA | 1 | — | porta da farmácia abre (opcional: kit, dado) | fecha | ao lado de B |
| `quarantine_door` | QUARENTENA | 1 | — | comporta da quarentena abre | fecha | ao lado de C |
| `node_door` | PORTA DO NÓ DO SETOR | 1 | — | porta do Nó abre | fecha | fim da câmara criogênica (meta) |

**Sequência que resolve:**
1. Ala de Leitos com as V-9 ligadas e no escuro: lanterna para ver os buracos × ser visto; aquecedores
   como abrigo do frio; Feixe como saída de emergência.
2. B: desliga `sentinels`, liga `stretcher_lift` → `[heating, stretcher_lift]`. Sobe.
3. C: desliga `stretcher_lift`, liga `quarantine_door` → `[heating, quarantine_door]`.
4. Quarentena: a parede de gelo do caminho está derretida (aquecedor dela ligado); `log_inf_01` → **Núcleo Aquecido**.
5. Segue para a câmara criogênica, paredes de gelo fora do alcance dos aquecedores (só o Núcleo
   derrete) e pontes de gelo fino; encontra a porta do Nó fechada.
6. Volta a C: desliga `heating`, liga `node_door` → `[quarantine_door, node_door]`. O aquecedor de C apaga.
7. Quarentena (a parede que dependia do aquecedor recongela — o Núcleo derrete) → câmara → Nó.

**Por que a solução ingênua falha:**
- Ligar a meta cedo não leva a nada: o Nó está depois da quarentena, no andar de cima.
- Manter o aquecimento é impossível no fim: `heating` + `quarantine_door` + `node_door` = 3 > 2, e não
  há console depois da comporta.
- Cortar o aquecimento antes do Núcleo: o frio deixa o MU-7 lento (a V-9 alcança), as paredes de
  gelo recongelam e o elevador para.
- Correr de dash pela Ala: o barulho chama todas as V-9 ao alcance.

**Fragmentos e segredo:**
- `log_inf_01` (terminal `L`, quarentena, no caminho) — Helena: o Núcleo Aquecido e a quarentena.
  Desbloqueia `heated_core`.
- `log_inf_02` (terminal `L`, sala secreta atrás de parede falsa, alcançável só com o Núcleo
  Aquecido derretendo uma parede de gelo fora da rota) — os leitos: a ordem em que adoeceram. Mesmo
  cômodo: `capacitor_inf_01`.
- `data_inf_01` — farmácia (opcional, custa a unidade da porta da farmácia na hora certa).
- `data_inf_02` — fundo de um poço escuro com pontes de gelo fino, na câmara criogênica.
- Leitos (props) com prontuário: `o` com log curto? **Não** — história em poucos fragmentos
  grandes; os leitos são cenário legível (placas numeradas, um vazio).

## 4.2 Mapa por zonas (contrato para o ASCII)

Alvo **~100 × 52**, corredores de **3 a 4 tiles de altura** ("estreita"), duas bandas ligadas pelo
poço do elevador de macas.

- **Entrada** (oeste, banda de baixo): `P`, doca, fala de marco. Sem console.
- **Ala de Leitos** (banda de baixo, a maior zona): escura, 3 V-9 em trilhos, leitos e macas como
  cobertura, 2–3 buracos que só se veem com luz (cair leva a um duto congelado com saída, não mata),
  zonas frias com 2–3 aquecedores, uma parede de gelo no alcance de um aquecedor.
- **Fim da Ala**: doca, console **B**, porta da **farmácia** (sala opcional com `data_inf_01` e kit),
  poço do elevador de macas (única subida).
- **Patamar** (banda de cima): doca, console **C** dentro de um aquecedor, comporta da **quarentena**.
- **Quarentena**: parede de gelo no alcance do aquecedor dela, `log_inf_01`, saída para a câmara
  criogênica; desvio com parede de gelo **fora** do alcance de aquecedor → parede falsa → sala secreta
  (`log_inf_02`, `capacitor_inf_01`).
- **Câmara criogênica** (desce a leste): frio, paredes de gelo só para o Núcleo, pontes de gelo fino
  sobre um fosso (cair = voltar subindo), poço escuro lateral com `data_inf_02`.
- **Câmara do Nó**: doca antes da porta `node_door`; Nó do setor.

Geometria da `level-design` §2. Pontes de gelo fino: o MU-7 com CONGELAMENTO anda a 55 px/s —
calcule os vãos para que a ponte só seja atravessável **sem** o frio (é o Núcleo que resolve).

## 5. Critérios de aceite

- [x] Religar o Laboratório leva ao Núcleo; revisita em lista (Estufa → Lab); comporta da Enfermaria selada antes e aberta depois
- [x] Enfermaria jogável do começo ao Nó; religar → cutscene → tela de fim com a frase da Enfermaria
- [x] V-9: vê o MU-7 iluminado a 96 px, no escuro só de perto; ouve o dash; persegue atravessando parede até 8 s; perde o alvo no escuro; gruda (12 + dreno de Carga) sem knockback; Feixe desliga; terminal desliga
- [x] CONGELAMENTO: lento, pulo menor, escorregadio; aquecedor ligado anula; Núcleo Aquecido imuniza
- [x] Gelo fino racha, cai e se refaz; parede de gelo derrete com aquecedor (e recongela) ou com o Núcleo (para sempre)
- [x] A solução ingênua falha como em §4.1; nenhum estado de energia prende o jogador
- [x] 2 logs + 2 dados + 1 capacitor + 1 segredo; contadores 8/8
- [x] ÓRBITA fala só na entrada, no Núcleo Aquecido, no religamento e na volta ao Núcleo; terminal mudo
- [x] HUD com os mesmos elementos de antes
- [x] Alcançabilidade verde; roteiros de QA com marcos chegam ao fim
- [x] Portões verdes; sem comentários; nada 3D

## 6. Definição técnica

```
scenes/enemies/v9.tscn (+ v9.gd)                drone; trilho, visão por luz, audição do dash, perseguição, gruda
scripts/core/v9_logic.gd                         class_name V9Logic — estados e decisões (puro)
scripts/core/freeze_rules.gd (ou HeatRules→ClimateRules)  frio, aquecedor, Núcleo Aquecido (puro)
scenes/world/thin_ice.tscn (+ thin_ice.gd)       plataforma que racha e se refaz
scenes/world/ice_wall.tscn (+ ice_wall.gd)       bloqueio que derrete (aquecedor por grupo / Núcleo por contato)
scenes/levels/infirmary.tscn                     level_base, level_id "infirmary", Narrative (heated_core)
```
- A zona de clima da F60 ganha `kind: "cold"`; a ilha ganha `kind: "warm"` (aquecedor). Reaproveite
  `heat_zone`/`cold_island` generalizando (nomes em inglês que digam o que é), sem quebrar o Lab.
- `mu7.gd`: CONGELAMENTO (`speed_multiplier`, `jump_multiplier`, `is_slippery`) e imunidade com `heated_core`;
  contato que gruda (V-9) sem knockback.
- "Iluminado" para a V-9: lanterna acesa (`mu7.is_flashlight_on()`) ou dentro do raio de uma
  `PoweredLamp` ligada (consulta pura testável).
- `revisit` em lista; `sector_narrative` do Lab com `next_scene = core_hub`; tela de fim com frase
  por último setor religado (`data/` ou cena de UI).

Números novos (GDD-P + AJ antes do Balance):

| Constante | Valor | Origem |
|---|---|---|
| `V9_CONTACT_DAMAGE` | 12 pts | 2.6.2-C |
| `V9_CHASE_TIME` | 8.0 s | 2.6.2-C |
| `V9_VISION_RANGE` | 96 px (6 m) | 2.6.2-C |
| `V9_DARK_VISION` | 32 px | AJ |
| `V9_HEAR_RADIUS` | 128 px | AJ |
| `V9_LOSE_TIME` | 1.0 s | AJ |
| `V9_PATROL_SPEED` | 30 px/s | AJ |
| `V9_CHASE_SPEED` | 70 px/s (mais lenta que o MU-7 a pé, mais rápida que o MU-7 congelado) | AJ |
| `V9_LATCH_TIME` | 1.5 s | AJ |
| `V9_LATCH_DRAIN` | 10 Carga/s | AJ |
| `V9_COOLDOWN` | 2.0 s | AJ |
| `FREEZE_DECEL_MULT` | 0.2 | AJ (chão escorregadio) |
| `THIN_ICE_BREAK_TIME` | 0.5 s | 2.6.2-E |
| `THIN_ICE_REFORM_TIME` | 3.0 s | AJ |
| `ICE_MELT_TIME` | 0.5 s | AJ |
| `LOGS_TOTAL` / `RESEARCH_TOTAL` | 8 / 8 | AJ |

## 7. Assets necessários

| Asset id | Uso | Placeholder |
|---|---|---|
| SPR-V9 (novo) | drone: patrulha, alerta, perseguição, grudado, desligado | `assets/placeholder/sprites/enemies/v9_sheet.png` |
| TIL-INFIRMARY (novo) | tileset da Enfermaria (ciano pálido, branco de gelo) | `assets/placeholder/tiles/infirmary_tiles.png` |
| SPR-ICE (novo) | gelo fino (inteiro, rachado) e parede de gelo (inteira, derretendo) | `assets/placeholder/sprites/world/ice_sheet.png` |
| SPR-PROPS-INF (novo) | leito, maca, suporte de soro, cápsula criogênica | `assets/placeholder/sprites/props/infirmary_props_sheet.png` |
| MUS-INFIRMARY (novo) | trilha da Enfermaria | toca `core` até chegar |

## 8. 🧑 Ação humana

Nenhuma que bloqueie. Pendente: a faixa `infirmary` (ficha MUS-INFIRMARY).

## 9. Plano de execução

- [x] **Passo 1** — GDD-P + Ajustes; INDEX `[~]` (orquestrador, depois do commit da F31)
- [x] **Passo 2** — Sistemas (subagente A) e Arte (subagente B) em paralelo
- [x] **Passo 3** — Fase, Núcleo e QA (subagente C)
- [x] **Passo 4** — Portões, QA, checklist §4.7 (orquestrador)
- [x] **Passo 5** — Docs e commit

## 10. Verificação

- **Testes:** `test_v9_logic.gd`, `test_freeze_rules.gd` (ou a generalização do clima),
  `test_thin_ice.gd`/`test_ice_wall.gd` (lógica pura), `test_sector_revisit.gd` (lista),
  `test_energy_infirmary.gd` (§4.1 resolve; `[heating, quarantine_door, node_door]` impossível;
  nenhum estado prende), `test_level_infirmary.gd` (sem console antes da Ala nem depois da quarentena,
  por flood fill), `test_energy_bindings.gd` (já cobre), alcançabilidade, paridade GDD-P.
- **Roteiros:** `tests/qa/f61_infirmary.json` (do nascimento ao fim, com marcos por zona) e
  `tests/qa/f61_hub_return.json` (Lab religado → Núcleo → comporta da Enfermaria). Capturas: V-9
  vendo o MU-7 com a lanterna; V-9 perdendo-o no escuro; MU-7 grudado; Feixe na V-9; frio (ícone);
  aquecedor; gelo fino rachando; parede derretendo; tela de fim 8/8.
- **Playtest humano:** a lanterna virou uma escolha? A V-9 é justa (dá para ler o alerta antes da
  perseguição)? A Enfermaria é mais difícil que o Laboratório (6/10)?

## 11. ADRs locais

### ADR-F61-001 — "Derrete gelo fino" são duas coisas
- **Contexto:** o GDD diz que o gelo fino quebra 0,5 s depois de pisar (2.6.2-E), que o aquecedor
  derrete o gelo e abre caminho (2.3) e que o Núcleo Aquecido derrete gelo fino (2.6.1).
- **Decisão:** **gelo fino** é plataforma (racha e cai); **parede de gelo** é bloqueio (derrete com
  aquecedor ligado e recongela, ou com o Núcleo por contato, para sempre). Vai para os Ajustes.
- **Data:** 2026-10-27.

### ADR-F61-002 — Nenhum console antes da Ala de Leitos
- **Contexto:** com um console na entrada, todo jogador desligaria as V-9 antes de vê-las (no Lab, as
  torres saem no primeiro console).
- **Decisão:** o primeiro console fica no fim da Ala; a V-9 é enfrentada com lanterna, cobertura e Feixe.
- **Data:** 2026-10-27.

## 12. Log de evolução

### 2026-10-27 — Feature criada e planejada
- **Quem**: orquestrador (feature-loop) · **O que**: arquivo criado a partir do GDD-2.7 F3,
  GDD-2.6.2-C/E/F, GDD-2.3 e Jornada 5; puzzle no papel e mapa por zonas. Decisão do humano: a F31
  (Dash + Feixe) entra antes, então o Feixe é uma das saídas contra a V-9 · **Próximo passo**:
  números no GDD depois do commit da F31; subagentes A e B.

### 2026-10-27 — Arte da Enfermaria (subagente B)
- **Quem**: subagente de arte · **O que**: placeholders e arte definitiva por IA (Codex, 2 variações
  cada, nenhuma regerada) de SPR-V9, TIL-INFIRMARY (+ `infirmary_tileset.tres`, cópia do Lab),
  SPR-ICE e SPR-PROPS-INF, todos no contrato e com 0 px semitransparentes; ficha MUS-INFIRMARY
  `pendente`. `tests/test_level_tileset.gd` confere a Enfermaria. A passarela one-way é montada da
  faixa de piso porque as duas da IA sumiam no fundo escuro; a V-9 é fatiada centrada pelo corpo
  (receita na ficha) · **Próximo passo**: subagente C usa `"tileset":
  "res://assets/tiles/infirmary_tileset.tres"` no JSON da fase e `"sheet"` dos props.

### 2026-10-27 — Sistemas (subagente A)
- **Quem**: agente de sistemas · **O que**: V-9 (`V9Logic` puro + `scenes/enemies/v9`), visão por
  luz (`LightExposure`: lanterna ou raio de `PoweredLamp` ligada, com linha livre), audição do dash
  (`mu7.is_dashing()`, sem sinal novo), aviso de 0,4 s (`V9_ALERT_TIME`, AJ-046), perseguição que
  atravessa o cenário, gruda sem empurrão (`Mu7.take_latch_hit`) drenando Carga, descanso, Feixe e
  terminal. Clima generalizado sem renomear classes: zona `h` com `kind: "cold"` (CONGELAMENTO) e ilha
  `i` com `kind: "warm"` (aquecedor); Laboratório idêntico (`f60_lab` 17/17, `f60_lab_systems` 4/4).
  CONGELAMENTO real no `mu7` (`FreezeRules`: 55 px/s, pulo de 28 px, freio ×0,2 no chão);
  `heated_core` impede o status. Gelo fino `_` (`ThinIceLogic`), parede de gelo `I`
  (`IceWallLogic`; aquecedor por `heater`/grupo ou vínculo direto; Núcleo derrete a pilha encostada,
  para sempre). `o` aceita `sheet` (quadros em grade pela largura da folha). `revisit` em lista. Lab →
  Núcleo; `infirmary.tscn`; frase da tela de fim por último setor. Terminal do Chassi: Mapa e
  Setores lado a lado para caber a 5ª habilidade (o teste de altura reprovou 226 px > 216).
  Sandbox `infirmary_sandbox` + `tests/qa/f61_systems.json` (11 marcos + 29 conferências da
  sandbox, duas rodadas) · **Decisões**: o MU-7 grudado anda normal (o custo é a Carga e a perseguição
  colada); o Feixe acerta de dentro (`hit_from_inside`), então desliga a V-9 grudada; a visão da V-9
  exige linha livre; o descanso de 2 s vale também depois dos 8 s de perseguição (senão ela
  recomeçava na hora); `heated_core` não aplica o status (nenhum ícone = nenhum efeito); gelo fino é
  sólido de todos os lados, sem sombra; parede de gelo sem oclusor · **Próximo passo**: dados da fase
  (subagente C).

### 2026-10-27 — Fechamento pelo orquestrador (o humano parou o agente de fase)
- **Quem**: orquestrador · **Contexto**: o humano interrompeu o agente de fase e pediu para
  continuar de onde ele parou. Estado encontrado: mapa, JSONs, textos, Núcleo e testes de conteúdo
  prontos; o redesenho dos dois retornos (escada do poço e fosso do desvio) já estava feito e
  coberto por `test_every_drop_has_a_way_back`; só a contagem de `_` no teste estava velha (21 → 23).
  Faltavam os roteiros de QA da fase e da volta ao Núcleo.
- **O que fiz**:
  - `tests/qa/f61_infirmary.json` — **do nascimento à tela de fim sem atalho**, com entradas reais:
    Ala de Leitos escura com as V-9 → console B (desliga sentinelas, liga elevador) → patamar →
    console C (desliga elevador, liga quarentena) → log `log_inf_01` (Núcleo Aquecido) → parede da
    câmara derretida por contato → pontes de gelo fino → poço do Nó → porta do Nó fechada → volta
    pelas plataformas da direita até C (desliga aquecimento, liga porta do Nó; o brilho do aquecedor
    some na hora) → segunda travessia → Nó → cutscene → tela de fim com a frase da Enfermaria.
    **15/15 marcos em duas rodadas**; capturas lidas.
  - `tests/qa/f61_hub_return.json` — comporta da Enfermaria **selada** antes do Laboratório; depois
    dele, nasce no Habitacional, fala de marco, objetivo "Chegar à Enfermaria", saídas da Estufa e do
    Lab fechadas, comporta aberta, chegada à Enfermaria. **10/10 em duas rodadas.**
  - Geradores versionados (`tools/qa_build.py`, `tests/qa/gen/f61_*.py`): mexeu no mapa, regenere.
  - Regressão: `f31_dash_beam` 10/10, `f60_lab_systems` 4/4, `f61_systems` 11/11, `f29_greenhouse`
    27/27, `f60_lab` 17/17, `f60_hub_return` 9/9 (marco de cena ganhou folga para a tela de loading).
  - `tools/qa.sh` passa a contar os monitores: com um só, não pede `--screen 1` (virava erro).
- **Portões**: 879 testes, 88 cenas, verdes.
- **Checklist §4.7**: (1) terminal mudo e fase sem gatilhos de fala (testes) — sim; (2) ÓRBITA só
  em `inf_enter`, `inf_heated_core`, `inf_restored`, `core_return_lab` — sim; (3) troca forçada
  aquecimento ↔ porta do Nó e ingênua falha (`test_energy_infirmary`) — sim; (4) farmácia opcional
  (custa a unidade), poço escuro com dado, sala secreta atrás de gelo de Núcleo + parede falsa — sim;
  (5) Ala e câmara escuras de verdade (capturas, `test_the_dark_stays_dark`) — sim; (6) silhuetas
  distintas (V-9, gelo fino, parede de gelo, consoles, docas, comportas) — sim, com a ressalva de
  que o **aquecedor não tem sprite** (só luz e vapor); (7) HUD igual — sim; (8) roteiros até o fim —
  sim; (9) cutscene — **fraca**: mostra o setor clareando, mas pouca coisa acende no caminho.
- **Pendências**: sons próprios (`v9_alert`, `ice_crack`, `ice_break`, `ice_melt` — hoje emprestados);
  sprite do aquecedor; faixa `infirmary` (humano); lâmpadas na rota da cutscene; o roteiro completo
  pega só o log obrigatório (os opcionais ficam para o jogador).
- **Próximo passo**: playtest humano — a lanterna virou escolha? a V-9 é justa? 6/10?

