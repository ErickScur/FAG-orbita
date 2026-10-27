---
id: F60
title: Fase 2 — Laboratório (Verão, CX-2, Superaquecimento, Dissipador)
status: done
scope: final
block: 6
priority: P0
rubric: ["Desenvolvimento de 4 fases com dificuldades diferentes", "Efeitos naturais", "Puzzle", "Inimigos", "Nível (progressão)"]
depends_on: ["F29", "F43", "F42", "F53", "F54"]
unblocks: ["F61", "F68"]
estimate: 2d
last_updated: 2026-10-27
---

# F60 — Fase 2 — Laboratório (Verão, CX-2, Superaquecimento, Dissipador)

## 1. Contexto e objetivo

Segunda fase de verdade e primeira da entrega final. O Laboratório é o setor do **Verão**: a
refrigeração quebrou, os corredores brancos assam, e o jogador corre entre **ilhas frias**. A
fase introduz a **Torre Calibradora CX-2** (o inimigo que se vence no Terminal, não no reflexo),
o status **SUPERAQUECIMENTO** e o upgrade **Dissipador Térmico**. É também a fase que tira o jogo
do corredor: religar a Estufa passa a devolver o MU-7 ao Núcleo Central, agora mais claro e com a
comporta do Laboratório destravada (decisão do humano, 2026-10-27).

Pilar servido: **energia é escolha** — "refrigeração e porta usam a mesma linha"
([GDD-2.7 F2](../design/GDD.md#gdd-2-7-f2)). A refrigeração é o que mantém o MU-7 vivo até ele
ganhar o Dissipador; depois disso, desligá-la é o que abre o Nó.

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.7 F2 — Laboratório](../design/GDD.md#gdd-2-7-f2) ·
  [GDD-2.6.2-B — CX-2](../design/GDD.md#gdd-2-6-2-b) ·
  [GDD-2.6.2-D — Esporos (Estufa/Laboratório)](../design/GDD.md#gdd-2-6-2-d) ·
  [GDD-2.6.2-E — vapor](../design/GDD.md#gdd-2-6-2-e) ·
  [GDD-2.6.2-F — SUPERAQUECIMENTO, DESCARGA](../design/GDD.md#gdd-2-6-2-f) ·
  [GDD-2.6.1 habilidades (Dissipador)](../design/GDD.md#gdd-2-6-1-habilidades) ·
  [GDD-2.7 mapa radial](../design/GDD.md#gdd-2-7-mapa) · [curva](../design/GDD.md#gdd-2-7-curva)
- **Parâmetros:** `Balance.CX2_*`, `FURNACE_DPS`, `HEAT_SINK_DAMAGE_MULT`, `OVERHEAT_*`,
  `DISCHARGE_TIME`, `STEAM_*`, `SPORE_*`, `LOGS_TOTAL`, `RESEARCH_TOTAL`
  ([GDD-P](../design/GDD.md#gdd-p)); ajustes [AJ-039, AJ-040, AJ-041](../design/GDD.md#gdd-ajustes)
- **Jornada:** [Etapa 5 — Laboratório: o experimento e o arquivo genético](../design/JORNADA-DO-HEROI.md#jh-5) ·
  prenúncio da [Etapa 6](../design/JORNADA-DO-HEROI.md#jh-6) (sensores mal calibrados)
- **Referência viva:** Estufa (`data/levels/greenhouse.{txt,json}`, `data/energy/greenhouse.json`,
  [F43](F43-estufa-viva.md)); skill `level-design`
- **ADRs:** [ADR-004](../DECISIONS.md#adr-004) · [ADR-005](../DECISIONS.md#adr-005) · [ADR-006](../DECISIONS.md#adr-006)

## 3. Critério de avaliação atendido

- **Desenvolvimento de 4 fases com dificuldades diferentes:** a 3ª fase jogável (5/10), maior que
  a Estufa, com clima que causa dano ativo — o eixo "Ambiente" da curva.
- **Efeitos naturais:** calor tremulando no ar, ilhas frias com geada, jatos de vapor.
- **Puzzle:** 6 sistemas / 2 energias, troca forçada entre refrigeração e porta.
- **Inimigos:** CX-2 nova, com o Terminal resolvendo o combate.
- **Nível (progressão):** Dissipador Térmico, e o hub que muda depois de cada setor.

Na apresentação: entrar no Laboratório pelo Núcleo, mostrar o cone da CX-2 travando no MU-7,
desligar as torres no Terminal e ver os cones apagarem; cortar a refrigeração depois do Dissipador.

## 4. Escopo

### Inclui

**A. Ligação entre setores (AJ-041)**
- Religar a Estufa leva ao Núcleo Central (não mais à tela de fim). O Núcleo, revisitado depois
  da Estufa: nasce na doca do Habitacional (`hab_dock_01`), ambiente mais claro, objetivo
  `obj_core_lab`, uma fala de marco (`core_return`), **comporta do Laboratório destravada** e a
  saída para a Estufa selada (a volta de mão dupla é a [F45](F45-ida-e-volta.md)).
- Antes da Estufa, a comporta do Laboratório já existe no Núcleo, **selada** (tinta vermelha da
  porta selada): o jogador vê para onde vai voltar.
- Religar o Laboratório → cutscene → fala de fechamento → tela de fim (`demo_completed`).

**B. Sistemas novos**
- **CX-2** (`X` no ASCII): torre fixa em teto ou parede, varre um cone de luz. Jogador dentro do
  cone **e com linha de visão** por `CX2_LOCK_TIME` → pulso: `CX2_PULSE_DAMAGE` + knockback +
  DESCARGA. Parede sólida corta o cone (é a "cobertura": o MU-7 não agacha, AJ-039). Entra no
  grupo `powered`: desligada pelo Terminal, apaga o cone e fica inerte.
- **Zona de calor** (`h` no ASCII, retângulo no JSON): aplica SUPERAQUECIMENTO enquanto o MU-7
  está dentro. Variante **fornalha** (`kind: "furnace"`) soma `FURNACE_DPS`. Visual: tremulação de
  ar e brilho laranja por trecho (sem uma luz por tile).
- **Ilha fria** (`i` no ASCII, retângulo no JSON): enquanto energizada (refrigeração), anula a
  zona de calor dentro dela. Visual: luz azul e geada; apagada, some.
- **Jato de vapor** (`v`, já na legenda): ciclo `STEAM_ON_TIME`/`STEAM_OFF_TIME`, aviso de
  `STEAM_WARN_TIME`, `STEAM_DAMAGE` por toque. Ligável por sistema com ação `invert` (o
  alívio de pressão desliga os jatos).
- **SUPERAQUECIMENTO** com efeito real: `OVERHEAT_DPS` de Integridade e Carga drenando
  `OVERHEAT_CHARGE_MULT`× mais rápido.
- **DESCARGA** com efeito real: bloqueia as garras magnéticas por `DISCHARGE_TIME` (AJ-040).
- **Dissipador Térmico** (`heat_sink`): entregue pelo log da Helena no meio da fase, como as
  garras. Multiplica por `HEAT_SINK_DAMAGE_MULT` o dano de SUPERAQUECIMENTO e de fornalha (vapor
  não é calor de ambiente: não reduz).
- **Esporos do Laboratório**: os enxames incham quando a refrigeração **desliga** (`invert`).

**C. A fase** — `scenes/levels/lab.tscn`, `data/levels/lab.{txt,json}`, `data/energy/lab.json`,
`data/logs/lab.json`, `data/dialogue/lab.json`, objetivo `obj_lab`.

### Não inclui
- Dash, Feixe e Propulsor (F31/F62); por isso DESCARGA vale para as garras (AJ-040).
- Portas de mão dupla entre setores e volta Estufa → Núcleo por porta (F45).
- Piso eletrificado (fica na F32), CONGELAMENTO e SOBRECARGA (F61/F68).
- Música própria do Laboratório: a fase toca `core` até o humano trazer a faixa `lab` (🧑 §8).

## 4.1 Puzzle no papel

**Terminal `lab`, orçamento 2, 6 sistemas, inicial `[towers, cooling]` (2/2 em uso).**
Quatro consoles do mesmo terminal (AJ-014): **A** entrada, **B** entrada da galeria,
**C** patamar de cima (antes da comporta da ala), e nenhum depois da ala — de propósito (ver
"por que a ingênua falha").

| id | Nome no terminal | Custo | Requer | Ligado | Desligado | Onde se vê |
|---|---|:-:|---|---|---|---|
| `towers` | TORRES CALIBRADORAS | 1 | — | cones das CX-2 varrendo | cones apagam, torres inertes | corredor quente e galeria (consoles A e B enxergam uma torre) |
| `cooling` | REFRIGERAÇÃO | 1 | — | ilhas frias azuis; esporos pequenos | ilhas somem; esporos incham | ilhas no corredor quente e no patamar (C fica dentro de uma) |
| `sample_lift` | ELEVADOR DE AMOSTRAS | 1 | `cooling` | elevador sobe e desce no poço | para onde estiver | poço ao lado do console B / do patamar |
| `relief` | ALÍVIO DE PRESSÃO | 1 | — | jatos de vapor param (`invert`) | jatos voltam ao ciclo | jatos do corredor quente e do sótão |
| `wing_door` | COMPORTA DA ALA DE PESQUISA | 1 | — | comporta da ala abre | fecha | ao lado do console C |
| `node_door` | PORTA DO NÓ DO SETOR | 1 | — | porta do Nó abre | fecha | fim da descida da fornalha (meta) |

Meta: `node_door`. Textos do terminal: título `LABORATÓRIO - DISTRIBUIÇÃO`, objetivo
`Abrir a Porta do Nó do Setor e religar o Nó`, sem `verbose`.

**Sequência que resolve (6 trocas):**
1. A ou B: desliga `towers` → `[cooling]`.
2. B: liga `sample_lift` → `[cooling, sample_lift]`. Sobe o poço.
3. C: desliga `sample_lift`, liga `wing_door` → `[cooling, wing_door]`.
4. Ala: lê `log_lab_01` → **Dissipador**. Segue até a fornalha, desce, encontra a porta do Nó fechada.
5. Volta a C: desliga `cooling`, liga `node_door` → `[wing_door, node_door]`. A ilha de C apaga na hora.
6. Ala → fornalha (esporos inchados, fornalha suportável com Dissipador) → porta do Nó → religa.

Jogador experiente pode, no passo 3, já escolher `[wing_door, node_door]` e atravessar o
patamar quente sem Dissipador (3/s, sobrevive): a ala dá o Dissipador antes da fornalha.

**Por que a solução ingênua falha:**
- Ligar a meta primeiro (`node_door` no console A) não leva a nada: o Nó fica no fim da rota de
  cima, e subir exige `cooling` + `sample_lift` (o orçamento todo).
- Manter a refrigeração "porque ela protege" é impossível no fim: a rota final precisa de
  `wing_door` **e** `node_door` ao mesmo tempo — `cooling` + as duas = 3 > 2. Não há console depois
  da ala, então não dá para soltar a comporta pelas costas.
- Cortar a refrigeração cedo (antes de subir) para o elevador e cozinha o corredor quente.
- Entrar na fornalha sem ler o log da ala: 15/s, morte em segundos; backup no patamar.

**Fragmentos e segredo (difíceis, poucos e grandes):**
- `log_lab_01` (terminal `L`, ala de pesquisa, no caminho) — Helena: o Dissipador, o calor, o
  arquivo genético. Desbloqueia `heat_sink`.
- `log_lab_02` (terminal `L`, **sala secreta** atrás de parede falsa no fim do **sótão**, rota
  opcional quente com vapor ao oeste do patamar) — prenúncio: as torres CX-2 calibravam os
  sensores das comportas. Mesmo cômodo: `capacitor_lab_01`.
- `data_lab_01` — topo da galeria: parede magnética vigiada por CX-2 + plataformas finas.
- `data_lab_02` — bolsão escuro na descida da fornalha: só com lanterna (drena 2× sob calor).

## 4.2 Mapa por zonas (contrato para o ASCII)

Tamanho alvo **112 × 44** tiles (Estufa: 48 × 64). Duas bandas horizontais ligadas por um poço
de elevador, mais uma descida vertical a leste.

```
 x→ 0      15                    51                       81 84        93          104   111
 r3  ######[ SÓTÃO quente (opcional): vapor, plataformas, parede falsa → log_lab_02 + C ]##
 r4                                                         |[PATAMAR C D3][|ala][ ALA: L log_lab_01 ][FORNALHA
 r16 ##################################################### poço ############################  desce   ]
 r18                                [ GALERIA (alta): topo = data_lab_01 ]  do                    zonas furnace,
     [ENTRADA P D1 A][ CORREDOR QUENTE: ilhas, vapor, 1 CX-2 ][ D2 B  CX-2 ×3, mag., SR-3 ×2 ] eleva-     esporos, bolsão
 r41 ##########################################################################  dor    [D4 |Nó  NÓ ] escuro (r_lab_02)
```

- **Entrada** (x 2–14, chão na linha 41): `P`, doca `D1`, console `A`, fala de marco ao entrar.
- **Corredor quente** (x 15–50): zona de calor inteira; 3 ilhas frias; 2–3 jatos de vapor; 1 CX-2
  no teto; desníveis de 1–2 tiles e um vão de 3. Esperar fora da ilha custa vida; dentro, nada.
- **Galeria** (x 51–80, linhas 18–41): doca `D2` e console `B` na entrada, 3 CX-2 em paredes,
  parede magnética até o topo (`data_lab_01`), 2 SR-3 no piso, plataformas finas. **Escura**.
- **Poço do elevador** (x 81–83, linhas 4–41): plataforma móvel `freight`, `sample_lift`. É a única
  subida; a descida pelo poço é livre (cair não mata).
- **Patamar** (x 84–92, linhas 4–15): doca `D3`, console `C` dentro de uma ilha fria, zona de calor.
- **Sótão** (x 2–80, linhas 3–15, a oeste do patamar): opcional, quente, vapor, plataformas.
  Termina numa parede falsa (`x`) com `log_lab_02` e `capacitor_lab_01`.
- **Ala de pesquisa** (x 93–103): comporta `wing_door` na entrada, `log_lab_01` no caminho, 1 CX-2
  (já inerte se as torres estiverem desligadas), props de laboratório.
- **Fornalha** (x 104–110, linhas 4–33): descida vertical por plataformas, 2–3 trechos `furnace`
  curtos (2–3 s cada), esporos ×3, bolsão escuro lateral com `data_lab_02`.
- **Câmara do Nó** (x 96–110, linhas 34–41): doca `D4` antes da porta `node_door`, Nó do setor.

Geometria (skill `level-design` §2): degrau ≤ 2 tiles, vão ≤ 3, chaminé de garra com 2 tiles,
≥ 2 colunas de sobreposição entre plataformas finas, ≤ 12 luzes por janela de 256 px. A
cutscene de religamento corre do Nó (leste) ao nascimento (oeste) pela banda de baixo, onde
estão as lâmpadas, ilhas, torres e jatos que acendem.

## 5. Critérios de aceite

- [x] Religar a Estufa leva ao Núcleo; o Núcleo revisitado nasce na doca do Habitacional, mais claro, com objetivo `obj_core_lab`, comporta do Laboratório aberta e saída da Estufa selada
- [x] Antes da Estufa, a comporta do Laboratório aparece selada no Núcleo
- [x] Laboratório jogável do começo ao Nó; religar → cutscene → tela de fim
- [x] CX-2: cone visível, trava em `CX2_LOCK_TIME` só com linha de visão, pulso dá 15 + knockback + DESCARGA; desligar `towers` apaga todos os cones
- [x] SUPERAQUECIMENTO tira 3/s e dobra a drenagem da lanterna; ilha fria energizada anula; ícone no HUD (o mesmo slot de status de sempre)
- [x] DESCARGA solta e bloqueia as garras por 3 s
- [x] Dissipador entregue por `log_lab_01`, aparece no Terminal do Chassi; com ele, calor e fornalha dão 30% do dano
- [x] A solução ingênua falha como descrito em §4.1; nenhuma configuração de energia prende o jogador sem saída
- [x] 2 logs + 2 dados + 1 capacitor + 1 segredo; contadores 6/6 no Terminal do Chassi e na tela de fim
- [x] Fora a entrada, a Dissipador e o religamento, ÓRBITA não fala; terminal mudo
- [x] HUD com os mesmos elementos de antes
- [x] Alcançabilidade verde para `lab` e `core_hub`; roteiro de QA com marcos chega ao fim
- [x] Portões do `/CLAUDE.md` §6 verdes; sem comentários; nada 3D

## 6. Definição técnica

### Cenas e scripts
```
scenes/enemies/cx2.tscn (+ cx2.gd)              Node2D/StaticBody2D, cone (Polygon2D + PointLight2D),
                                                RayCast2D de linha de visão, DamageArea do pulso
scripts/core/cx2_logic.gd                       class_name Cx2Logic — varredura, cone, trava, recarga (puro)
scenes/world/heat_zone.tscn (+ heat_zone.gd)    Area2D; kind warm|furnace; aplica status / DPS
scenes/world/cold_island.tscn (+ cold_island.gd) Area2D powered; anula calor dentro
scenes/world/steam_vent.tscn (+ steam_vent.gd)  jato cíclico (F32 parcial), powered
scripts/core/heat_rules.gd                      class_name HeatRules — dano de calor por segundo (puro):
                                                status, fornalha, ilha, Dissipador
scenes/levels/sector_narrative.gd               generaliza greenhouse.gd: sector_id, ability_id,
                                                ability_dialogue, restored_dialogue, next_scene
scenes/levels/lab.tscn                          instancia level_base, level_id = "lab"
```
- `greenhouse.tscn` passa a usar `sector_narrative.gd` com `next_scene = core_hub.tscn`;
  `greenhouse.gd` some (ou vira wrapper vazio, se algum teste depender do caminho).
- `level_base.gd`: bloco `revisit` no JSON da fase (abaixo).
- `door.gd`: parâmetro `sealed_until_sector`. `level_exit.gd`: parâmetro `closes_after_sector`.
- `mu7.gd`: integra SUPERAQUECIMENTO (DPS via `HeatRules` + `GameState.apply_damage`, que já
  aplica dificuldade), drenagem `charge_drain_multiplier()` na lanterna, DESCARGA bloqueando
  `_has_claws()`/agarre.
- `LevelBuilder.LEGEND`: `X` (CX-2), `h` (zona de calor, âncora de retângulo), `i` (ilha fria);
  `v` aponta para `steam_vent.tscn` já existente.

### Autoloads / sinais do EventBus
- Nenhum sinal novo. `status_applied/cleared`, `ability_unlocked`, `sector_restored`,
  `demo_completed`, `energy_changed` cobrem tudo.
- `GameState`: nada novo além do uso de `abilities` (`heat_sink`) e `sectors_restored`.

### Dados (`data/`)
- `data/levels/lab.{txt,json}`, `data/energy/lab.json`, `data/logs/lab.json`,
  `data/dialogue/lab.json` (`lab_enter`, `lab_heat_sink`, `lab_restored`),
  `data/dialogue/core_hub.json` (+ `core_return`), `data/objectives.json` (+ `obj_core_lab`, `obj_lab`).
- Zona de calor e ilha fria: entidade com `"rect": [colunas, linhas]` (tamanho a partir do tile
  da letra), `"kind"`, e `terminal_id`/`system_id` ou `group` como qualquer `powered`.
- Bloco `revisit` no JSON de fase (Núcleo):
  ```json
  "revisit": {
    "after_sector": "greenhouse",
    "spawn_dock": "hab_dock_01",
    "objective": "obj_core_lab",
    "ambient_color": "#1b2a36",
    "on_enter_dialogue": "core_return"
  }
  ```
  Com `after_sector` em `GameState.sectors_restored`, a fase usa esses valores no lugar dos de
  topo, e o `start_position()` vira a doca indicada (checkpoint de entrada incluso).

### Input actions / camadas de colisão
- Nenhuma ação nova. CX-2 e vapor em `hazard` (5); linha de visão da CX-2 contra `world` (1).

## 7. Assets necessários

| Asset id | Uso | Placeholder |
|---|---|---|
| SPR-CX2 (novo) | torre CX-2: varrendo, travando, disparo, desligada | `assets/placeholder/sprites/enemies/cx2_sheet.png` |
| TIL-LAB (novo) | tileset do Laboratório (branco sujo, Verão) | `assets/placeholder/tiles/lab_tiles.png` |
| SPR-STEAM (novo) | bocal do jato de vapor (o jato é partícula) | `assets/placeholder/sprites/world/steam_vent.png` |
| SPR-PROPS | props de laboratório (reuso do que existir) | — |
| MUS-LAB (novo) | trilha do Laboratório | toca `core` até chegar |

Arte gerada pelo agente (skill `gen-image`), registrada no `ASSETS.md`.

## 8. 🧑 Ação humana

Nenhuma que bloqueie. Pendente para depois: a faixa `lab` (loop 2–3 min, Verão, abafado,
"refrigeração quebrada"), com prompt e busca na ficha MUS-LAB do `ASSETS.md`.

## 9. Plano de execução

- [x] **Passo 1** — GDD-P + Ajustes (AJ-039/040/041) e arquivo da feature (orquestrador)
- [x] **Passo 2** — Sistemas (subagente A): CX-2, calor, ilha, vapor, status, Dissipador, revisita do Núcleo, `sector_narrative`
- [x] **Passo 2b** — Arte (subagente B, em paralelo): TIL-LAB, SPR-CX2, SPR-STEAM, placeholders, fichas
- [x] **Passo 3** — Fase (subagente C): ASCII, JSONs, textos, edição do Núcleo, roteiro de QA
- [x] **Passo 4** — Portões, QA com marcos, checklist §4.7 (orquestrador)
- [x] **Passo 5** — Docs e commit

## 10. Verificação

- **Testes:** `test_cx2_logic.gd` (varredura, cone, trava só com visão, recarga), `test_heat_rules.gd`
  (status, fornalha, ilha, Dissipador, dificuldade), `test_sector_revisit.gd` (bloco `revisit`),
  `test_energy_lab.gd` (solução de §4.1 resolve; ingênua não; nenhum estado sem saída — orçamento),
  alcançabilidade (`lab` entra sozinho), paridade GDD-P.
- **Smoke:** `lab.tscn`, `cx2.tscn`, `heat_zone.tscn`, `cold_island.tscn`, `steam_vent.tscn` em `tests/scenes.txt`.
- **Roteiro godot-qa:** `tests/qa/f60_lab.json` (fase inteira com marcos por zona) e
  `tests/qa/f60_hub_return.json` (Estufa religada → Núcleo revisitado → comporta → Laboratório).
  Capturas: cone da CX-2 travando; ilha fria acesa e apagada; patamar antes/depois de cortar a
  refrigeração; esporos inchados; bolsão escuro com lanterna; cutscene; tela de fim 6/6.
- **Playtest humano:** a fase está difícil o bastante (5/10)? A troca refrigeração ↔ porta é
  um "aha" ou um beco? A CX-2 é legível (cone, aviso, pulso)?

## 11. ADRs locais

### ADR-F60-001 — Fase sem console depois da ala
- **Contexto:** com um console depois da comporta da ala, o jogador soltaria a comporta pelas
  costas e manteria a refrigeração, e a troca central do GDD sumiria.
- **Decisão:** o último console de cima (C) fica antes da comporta; a fornalha e a câmara do Nó
  não têm console.
- **Consequências:** o jogador que descobre a porta do Nó fechada volta ~20 tiles até C. É o
  momento do "aha". Data: 2026-10-27.

### ADR-F60-002 — Zona de calor como retângulo de entidade
- **Contexto:** calor por tile no ASCII lotaria a legenda e criaria uma luz por tile (17ª luz
  descartada em silêncio).
- **Decisão:** `h`/`i` marcam o canto superior esquerdo; o tamanho vem de `rect` no JSON. Um
  brilho por zona, esticado.
- **Data:** 2026-10-27.

### ADR-F60-003 — Volta ao Núcleo pelo bloco `revisit`, não por porta
- **Contexto:** o humano escolheu "volta ao Núcleo"; portas de mão dupla são a F45.
- **Decisão:** a Estufa termina com `SceneManager.goto(core_hub)`; o Núcleo lê `revisit` quando
  `after_sector` já foi religado. A saída para a Estufa fecha até a F45.
- **Data:** 2026-10-27.

## 12. Log de evolução

### 2026-10-27 — Feature criada e planejada
- **Quem**: orquestrador (feature-loop) · **O que**: arquivo criado a partir do GDD-2.7 F2,
  GDD-2.6.2-B/F e Jornada 5; puzzle no papel (§4.1) e mapa por zonas (§4.2). Decisões do humano:
  volta ao Núcleo depois da Estufa; ferramental pendente commitado à parte (`2f32cf5`).
  Achado no estudo: dash, feixe (F31) e vapor/piso (F32) não existem na build — DESCARGA passa a
  valer para as garras (AJ-040) e o vapor entra aqui · **Próximo passo**: subagentes A e B.

### 2026-10-27 — Arte do Laboratório (subagente B)
- **Quem**: agente de arte · **O que**: placeholders de SPR-CX2, TIL-LAB e SPR-STEAM no
  `tools/make_placeholders.gd` (formas `ceiling_turret` e `steam_vent`, paleta `lab`), depois os
  três definitivos gerados pelo Codex (2 variações cada), fatiados no contrato e integrados:
  `cx2_sheet.png` 128×64 (4×2), `lab_tiles.png` 128×64 (8×4) + `lab_tileset.tres` (cópia da
  estrutura da Estufa), `steam_vent.png` 16×16. Fichas no `ASSETS.md` (mais MUS-LAB pendente,
  com prompt e termos de busca). `tests/test_level_tileset.gd` passou a conferir o Lab, inclusive
  a parede magnética · **Achados**: a CX-2 precisa de fatiamento alinhado pelo topo (o
  `autoslice_sheet.gd` alinha pelo pé); `MagneticWall` e `PoweredLamp` leem a folha da
  Estufa/Núcleo fixa no código, então no Lab a parede magnética e a luminária ainda mostram a
  arte daqueles setores até o código ler o tileset da fase · **Próximo passo**: agente C usa
  `"tileset": "res://assets/tiles/lab_tileset.tres"` no JSON da fase.

### 2026-10-27 — Sistemas da fase (subagente A)
- **Quem**: agente de sistemas · **O que**: CX-2 (`Cx2Logic` puro + `cx2.tscn`), zona de calor,
  ilha fria, jato de vapor, SUPERAQUECIMENTO/DESCARGA com efeito real, Dissipador (`heat_sink`,
  rótulo no Terminal do Chassi), `SectorNarrative` (substitui `greenhouse.gd`), `lab.tscn`, bloco
  `revisit` (`SectorRevisit` puro + `level_base`), `sealed_until_sector` na porta,
  `closes_after_sector` na saída, letras `X`/`h`/`i` na legenda, chave `entity_tiles` no JSON de
  fase (parede magnética, luminária e parede falsa usam a folha do setor). Testes:
  `test_cx2_logic`, `test_heat_rules`, `test_sector_revisit`, `test_lab_systems`; sandbox
  `tests/qa/scenes/lab_sandbox.tscn` + roteiro `tests/qa/f60_lab_systems.json` (3 marcos, capturas
  lidas: cone ciano → vermelho, pulso 15 + DESCARGA, recarga sem cone, calor 3/s, ilha anula,
  vapor 20).
- **Decisões**: (1) DPS de calor tem **um** caminho: a zona só aplica o status; o `mu7` soma
  `statuses.integrity_dps()` + fornalha e multiplica pelo Dissipador (`HeatRules.total_dps`). Zona e
  ilha não são `DamageArea`. (2) A CX-2 **congela a varredura** enquanto trava (o cone para em cima
  do alvo e fica vermelho); fora da visão a trava zera; na recarga o cone some. Não trava com o
  MU-7 de entrada travada (fala/cutscene). (3) Quadro do `scan` segue o ângulo da varredura
  (0 = esquerda … 3 = direita), sem loop. (4) Altura do jato (48 px) mora no `.tscn`, como as
  hitboxes da SR-3: nenhum número novo na GDD-P. (5) Porta destravada por setor fica presa
  aberta (ignora terminal e grupo). (6) Ao religar um setor com `next_scene`, o checkpoint já
  aponta para a próxima cena antes do save do Nó: "Continuar" no meio da fala de fechamento não
  deixa o jogador numa Estufa sem saída.
- **Pendente**: dano por segundo com dificuldade continua em pedaços de 1 ponto
  (`Vitals.scale_damage` arredonda para cima): no Fácil esporos e calor tiram o mesmo que no
  Normal, no Difícil o dobro. Vale para os esporos desde a F23; correção é no `GameState`.

### 2026-10-27 — Fase, Núcleo revisitado e QA (subagente C)
- **Quem**: agente de fase · **O que**: `data/levels/lab.{txt,json}` (112×44), `data/energy/lab.json`
  (6 sistemas/2, mudo), `data/logs/lab.json`, `data/dialogue/lab.json`, `core_return`,
  `obj_core_lab`/`obj_lab`; Núcleo alargado 8 colunas a leste (comporta selada `door_lab` em 80,
  saída do Lab em 84, saída da Estufa com `closes_after_sector`, bloco `revisit` com
  `ambient_color #2b3f52`, `reactor_online` e `triggers: []`). Testes `test_level_lab.gd` (prova
  por flood fill que não há console depois da comporta da ala e que a sala do Nó e a sala secreta
  são fechadas) e `test_energy_lab.gd` (sequência §4.1, `[cooling, wing_door, node_door]`
  impossível, todo caminho até o Nó corta a refrigeração, nenhum estado prende, ≥4 trocas).
  `lab` nos testes de luz (crowding com `X`/`h`/`i` modelados, darkness). Roteiros
  `tests/qa/f60_lab.json` (nascimento → Nó → tela de fim, 17 marcos, LOGS 6/6, DADOS 6/6) e
  `tests/qa/f60_hub_return.json` (comporta selada antes, revisita depois, 9 marcos).
- **Desvios do papel**: fornalha vira um zigue-zague de 4 prateleiras **sob** a ala (x 96–109,
  linhas 17–31) com escadas de plataforma fina, reversível sem garras; câmara do Nó embaixo,
  volta por escada fina (x 108–109) em vez de parede magnética (o MU-7 agarrava a parede ao
  andar para fora da prateleira). Sótão encurtado (x 44–80) para não virar corredor vazio.
  Console B ao lado do poço (x 80) num degrau que segura as SR-3 fora do fundo do poço; o
  elevador nasce estacionado em cima e **desce** quando ligado (consequência visível em B).
  Pilar magnético da galeria sobe até a linha 21 (o pulo da parede cai na prateleira do dado);
  `obj_lab` = "Religar o Laboratório" (o texto do papel passava de 136 px no HUD).
- **Correção em código de sistema**: `level_base.spawn_position()` caía no `P` quando o
  checkpoint vinha sem doca (o que a `SectorNarrative` grava ao religar a Estufa), ignorando o
  `spawn_dock` da revisita: agora cai em `start_position()`.
- **Achados**: ilha fria dentro de zona de calor alta some na imagem (o brilho laranja grande
  apaga o azul); a faixa de calor do patamar ficou baixa (linhas 13–15). Com `difficulty=hard` o
  arredondamento de dano por segundo (pendência do agente A) dobra calor e esporos e a fornalha
  fica letal; os roteiros fixam `normal`. A tela de fim ainda diz "A ESTUFA VOLTOU A RESPIRAR".

### 2026-10-27 — Verificação, correções e fechamento (orquestrador)
- **Quem**: orquestrador · **O que**: portões completos verdes por mim (767 testes, 83 cenas);
  roteiros relidos e capturas-chave lidas (cone da CX-2 travando, terminal 2/2 mudo, ilhas no
  corredor, patamar antes/depois de cortar a refrigeração, esporos inchados, cutscene, tela de
  fim 6/6, Núcleo antes e depois da Estufa).
- **Correções minhas**:
  - **Dano por segundo respeita a dificuldade.** O DPS saía em pedaços de 1 ponto e cada
    pedaço passava por `Vitals.scale_damage`, que arredonda para cima: Fácil tirava o mesmo que
    o Normal e Difícil o dobro (vinha desde a F23, nos esporos). O humano joga no Difícil, onde a
    fornalha matava. Agora `GameState.apply_damage_over_time(per_second, delta, acumulador)`
    escala a **taxa** antes de acumular, e o MU-7 usa esse caminho para esporos e calor. O
    multiplicador continua só no `GameState`. Teste: `test_damage_over_time_follows_difficulty`
    (10/s por 1,05 s → 5/10/15).
  - Tela de fim: "O LABORATÓRIO ESFRIOU. A ESTAÇÃO AINDA NÃO." (ainda falava da Estufa).
  - Ilha fria lia como lâmpada branca dentro da zona de calor: luz `#4aa8ff` com energia 1,2
    (era `#7fd4ff`, 0,9). Na captura nova as ilhas leem azul no corredor.
- **QA**: `f60_lab.json` 17/17 em 4 de 6 rodadas completas; `f60_hub_return.json` 9/9;
  `f29_greenhouse.json` 27/27. Falhas observadas:
  - uma rodada perdeu o trilho na entrada porque a CX-2 disparou no MU-7 (a fase da varredura
    depende do tempo real de carga da cena, e o roteiro para dentro do cone para fotografar) —
    instabilidade do roteiro, não do jogo;
  - **uma rodada ficou com o MU-7 parado em 79,15 (ao lado do bocal `lab_vent_04`, à esquerda do
    poço) por ~7 s com ← apertado e três pulos**, integridade cheia e nada sólido no tile. Não
    reproduziu em mais 6 rodadas (3 delas com captura a cada 15 quadros nesse trecho). Fica como
    **observação aberta para o playtest**: se o humano enroscar ali, é o mesmo caso.
- **Mecanismo novo**: `tests/test_energy_bindings.gd` reprova, em qualquer fase, nó vinculado
  por `terminal_id`/`system_id` a um sistema que também o comanda com `invert` (armadilha do
  agente A). Provado plantando o defeito num esporo do Lab: o teste reprovou; desfeito, verde.
  Lições novas nas skills `godot-pitfalls`, `godot-qa`, `gen-image` e `level-design`.
- **Checklist §4.7**: todos "sim" (respostas com evidência no relatório do agente de fase,
  conferidas nas capturas). Ressalva: a ilha fria ainda é o interativo de silhueta mais fraca
  (é luz e geada, não objeto).
- **Pendências**: faixa `lab` (humano); tremor/pisca contínuo dentro da fornalha (ver no playtest); roteiros
  `f28`/`f35` do Núcleo sem marcos e parados na coluna 59 (antigos, não são desta feature).
- **Próximo passo**: playtest humano — dificuldade (5/10), o "aha" da troca refrigeração ↔
  porta, legibilidade da CX-2, e o ponto 79,15 do patamar.
