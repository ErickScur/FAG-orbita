---
id: F62
title: Fase 4 — Docas (Vácuo, Propulsor)
status: done
scope: final
block: 6
priority: P0
rubric: ["Desenvolvimento de 4 fases com dificuldades diferentes", "Efeitos naturais", "Puzzle", "Inimigos", "Nível (progressão)", "Luz/Sombra"]
depends_on: ["F61"]
unblocks: ["F63", "F64"]
estimate: 2d
last_updated: 2026-11-21
---

# F62 — Fase 4 — Docas (Vácuo, Propulsor)

## 1. Contexto e objetivo

Quarta fase de verdade e a mais difícil até aqui (8/10). As Docas são o setor do **Vácuo**:
"aberta, sem gravidade em vários trechos, espaço visível ao fundo. Combina todos os inimigos
anteriores; dano contínuo de vácuo transforma cada travessia numa corrida"
([GDD-2.7 F4](../design/GDD.md#gdd-2-7-f4)). Introduz o **vácuo** (gravidade zero, inércia, 4 de
Integridade/s) e o upgrade **Propulsor** (pulo duplo e controle no vácuo). Narrativa: o hangar
guarda o **berço vazio da SELENE**, a nave de escape que partiu quase vazia, e as comportas que o
Serralheiro fechou ([Jornada etapa 5](../design/JORNADA-DO-HEROI.md#jh-5)).

Pilares: **energia é escolha** (o Campo de Contenção dá ar e gravidade ao hangar, mas é o vácuo que
leva para cima; a meta exige a cadeia inteira do orçamento) e **o vácuo é estado, não lugar**
(o mesmo hangar é uma sala de plataforma ou uma travessia à deriva, dependendo do terminal).

A fase vai até a **antessala do Serralheiro** com o Nó do setor dentro; o mini boss é a F63
(seção "Gancho para a F63").

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.7 F4 — Docas](../design/GDD.md#gdd-2-7-f4) ·
  [GDD-2.6.1 habilidades (Propulsor)](../design/GDD.md#gdd-2-6-1-habilidades) ·
  [GDD-2.6.2-E — vácuo](../design/GDD.md#gdd-2-6-2-e) ·
  [GDD-2.6.2-G — Serralheiro](../design/GDD.md#gdd-2-6-2-g) ·
  [GDD-2.7 curva (6 sistemas / 3 energias em cadeia)](../design/GDD.md#gdd-2-7-curva) ·
  [GDD-2.9 paleta (preto do espaço + amarelo de perigo)](../design/GDD.md#gdd-2-9-paleta)
- **Parâmetros:** `Balance.VACUUM_*`, `THRUSTER_*`, `DOUBLE_JUMP_COST`, `LOGS_TOTAL`,
  `RESEARCH_TOTAL`, `SECRETS_TOTAL` ([GDD-P](../design/GDD.md#gdd-p)); ajustes
  [AJ-047, AJ-048, AJ-049](../design/GDD.md#gdd-ajustes)
- **Jornada:** [Etapa 5 — Docas: havia uma nave de escape que partiu quase vazia](../design/JORNADA-DO-HEROI.md#jh-5)
- **Referência viva:** Enfermaria ([F61](F61-fase-enfermaria.md)) e Laboratório
  ([F60](F60-fase-laboratorio.md)) — mesmo pipeline de fase, `sector_narrative`, `revisit`,
  ADR-F60-001; skill `level-design`
- **ADRs:** [ADR-004](../DECISIONS.md#adr-004) · [ADR-005](../DECISIONS.md#adr-005) · ADR-F60-001

## 3. Critério de avaliação atendido

- **Desenvolvimento de 4 fases com dificuldades diferentes:** 5ª fase jogável (8/10).
- **Efeitos naturais:** vácuo com deriva e dano contínuo; o terminal liga e desliga a gravidade do hangar.
- **Puzzle:** 6 sistemas / 3 energias, com a cadeia `node_door` → `outer_hatch` → `containment`.
- **Inimigos:** SR-3, CX-2 e V-9 na mesma fase.
- **Nível (progressão):** Propulsor, ganho no meio da fase.
- **Luz/Sombra:** galeria e duto escuros; o hangar e o anel externo mostram o espaço aberto.

Na apresentação: cortar o Campo de Contenção e ver o hangar virar vácuo (estrelas, borda amarela,
destroços); flutuar até o vestiário; pegar o Propulsor; pulo duplo nas prateleiras; pilotar no anel externo.

## 4. Escopo

### Inclui

**A. Vácuo (`V` no ASCII)** — `scenes/world/vacuum_zone.tscn`: retângulo (`rect`) sem gravidade
que tira `VACUUM_DPS` de Integridade/s. Leitura inconfundível: o fundo vira céu estrelado aberto
(sem luz de cena, com paralaxe), destroços à deriva e borda tracejada amarela piscando. Quando a
contenção sela o hangar, as estrelas ficam atrás de um véu ciano, a borda fica contínua e ciano, e
os destroços somem. Ligada a sistema por `group` + `invert` (o `powered` da zona é "vácuo ativo").

**B. Movimento no vácuo** (`VacuumRules` puro + `mu7.gd`):
- sem gravidade e sem atrito: o MU-7 mantém a velocidade (deriva), teto `VACUUM_MAX_SPEED`;
- **botas magnéticas**: de pé no piso ele anda normal (`VACUUM_FLOOR_STICK`);
- encostar em parede ou teto o **ancora**; o pulo vira **impulso** (`VACUUM_PUSH_SPEED`) na direção
  das setas — sem seta, para longe da superfície; do piso, seta lateral sai na diagonal; de
  parede/teto dá para deslizar rente (seta paralela);
- sem Propulsor, a deriva só muda de rumo encostando em algo ou com o dash (1 no ar);
- **com Propulsor**: segurar uma direção acelera (`THRUSTER_ACCEL` até `THRUSTER_SPEED`) gastando
  `THRUSTER_DRAIN` de Carga/s, com jato visível no sentido oposto.

**C. Propulsor (`thruster`)** — entregue pelo `log_dk_01` (vestiário EVA). Fora do vácuo: **pulo
duplo**, um por salto, mesma altura do pulo, `DOUBLE_JUMP_COST` de Carga, jato para baixo. DESCARGA
bloqueia. Custo no Terminal do Chassi (`HudModel.ABILITY_COSTS`), cartão `tut_thruster` na primeira vez.

**D. A fase** — `scenes/levels/docks.tscn`, `data/levels/docks.{txt,json}`, `data/energy/docks.json`,
`data/logs/docks.json`, `data/dialogue/docks.json`, objetivo `obj_docks`. Acopladores `A`
(`scenes/world/coupler.tscn`) e o berço vazio (`scenes/world/escape_cradle.tscn`).

**E. Ligação** — religar a Enfermaria volta ao Núcleo (`next_scene`); religar as Docas → cutscene →
fala → **volta ao Núcleo** (`next_scene`, desde a F64; antes era a tela de fim). Entrada `revisit`
`after_sector: docks` no Núcleo (objetivo `obj_core_memory`, fala `core_return_docks`, Núcleo mais
claro), que abre a comporta da Memória.

### Não inclui
- O Serralheiro (F63): a antessala fica pronta, sem chefe.
- ~~A porta das Docas no Núcleo e a entrada `revisit` `after_sector: infirmary` (F45).~~ Feitas na
  integração (2026-11-21, ver log).
- ~~A frase da tela de fim para as Docas.~~ Feita na integração.
- Música própria: toca `core` até a faixa `docks` (MUS-DOCKS, pendente).

## 4.1 Puzzle no papel

**Terminal `docks`, orçamento 3, 6 sistemas, inicial `[security, containment]` (2/3).**
Consoles: **A** no piso do hangar (vê o elevador descer, o vácuo abrir e o sinal do vestiário),
**B** no vestiário EVA (vê a porta do vestiário e dois sinais: contenção ciano, eclusa âmbar),
**C** no alto do bloco do vestíbulo, **antes** da comporta da antessala (ADR-F60-001; nenhum console
depois dela).

| id | Nome no terminal | Custo | Requer | Ligado | Desligado | Onde se vê |
|---|---|:-:|---|---|---|---|
| `security` | SEGURANÇA DAS DOCAS | 1 | — | CX-2 ×3, V-9 ×3 e sinalizadores âmbar ativos | param e apagam (escuro de verdade) | galeria, hangar (A), vestíbulo (C) |
| `containment` | CAMPO DE CONTENÇÃO | 1 | — | hangar pressurizado: gravidade, sem dano | hangar em vácuo | hangar inteiro (A), sinal ciano (B) |
| `cargo_lift` | ELEVADOR DE CARGA | 1 | `containment` | elevador desce do passadiço ao piso e oscila | para onde estiver | hangar (A) |
| `eva_door` | VESTIÁRIO EVA | 1 | — | porta do vestiário abre | fecha | sinal verde (A), porta (B) |
| `outer_hatch` | ECLUSA EXTERNA | 1 | `containment` | eclusa do duto para o anel externo abre | fecha | sinal âmbar (B), eclusa |
| `node_door` | COMPORTA DA ANTESSALA | 1 | `outer_hatch` | comporta da antessala abre, luzes da antessala acendem | fecha | C |

**Sequência que resolve** (duas rotas até o vestiário):
1. Galeria de carga escura: SR-3 entre caixas, CX-2 varrendo do teto, sinalizador de segurança.
   **Brecha** (vácuo permanente) no fim: impulso para cima, ancora no teto, desliza para a direita
   até o corredor. Doca e queda no hangar.
2. **A**, no hangar pressurizado. O vestiário fica no alto (passadiço, 19 tiles acima).
   - **Rota segura:** `[containment, cargo_lift, eva_door]` — a segurança cai à força; o elevador
     leva ao passadiço.
   - **Rota do vácuo:** desligar `containment`, ligar `eva_door` (`[security, eva_door]` ou
     `[eva_door]`): o hangar vira vácuo e o MU-7 flutua até o passadiço (impulso para cima, ancora
     no teto, impulso diagonal). Pelo caminho: o Dado acima do berço e a cabine secreta.
3. Vestiário EVA: `log_dk_01` → **Propulsor**. Prateleiras de 4 tiles (sala segura do pulo duplo,
   cartão `tut_thruster`) levam ao duto. **B**: precisa `outer_hatch`, que exige `containment` →
   `[containment, outer_hatch, X]`.
4. Duto de manutenção (gravidade, escuro): jato de vapor (dash ou espera), um poço de 3 tiles para o hangar, CX-2
   no teto se a segurança ficou ligada. Doca, eclusa externa.
5. **Anel externo** (vácuo permanente): destroços, V-9, CX-2, Dado no canto. Com o Propulsor, pilotar
   até o tubo de atracação no casco e cair no vestíbulo.
6. Vestíbulo: SR-3 no pouso, doca; o bloco de **C** tem 4 tiles (só com pulo duplo). Em **C**:
   `node_door` exige `outer_hatch` e `containment` → estado final `[containment, outer_hatch,
   node_door]`; o terceiro sistema (segurança, elevador ou vestiário) cai — o sinalizador do
   vestíbulo apaga, a comporta abre.
7. Passagem → queda na antessala → estrado de 4 tiles (pulo duplo) → Nó.

**Por que a solução ingênua falha:**
- Ligar a meta já em A (`[containment, outer_hatch, node_door]`) fecha o vestiário e corta o
  elevador: sem Propulsor não se chega ao duto nem se sobe o bloco de C.
- Abrir só o vestiário em A (`[security, containment, eva_door]`) mostra a porta lá em cima, sem
  caminho: o hangar pressurizado não tem como subir sem o elevador ou o vácuo.
- Manter a segurança até o fim é impossível: a cadeia da meta ocupa o orçamento inteiro.

**Fragmentos e segredo:**
- `log_dk_01` (vestiário, no caminho) — Helena: o protocolo EVA, Ana Lúcia e a SELENE. Libera `thruster`.
- `log_dk_02` (cabine de lançamento, **segredo** atrás de parede falsa na parede leste do hangar,
  só alcançável flutuando com o hangar em vácuo) — Helena viu a SELENE partir quase vazia e o
  Serralheiro fechar as comportas "por ordem que chegou pela rede". Mesmo cômodo: `capacitor_dk_01`
  (`C` em 81,20; `kind` `capacitor`, o mesmo de `capacitor_gh_01`, `capacitor_lab_01` e
  `capacitor_inf_01` — o 4º e último Núcleo de Capacitor do jogo, para o modelo de upgrades da F69).
- `data_dk_01` — acima do berço vazio, no meio do hangar: só no vácuo.
- `data_dk_02` — canto superior do anel externo, atrás da varredura da CX-2.

## 4.2 Mapa por zonas (contrato para o ASCII)

`data/levels/docks.txt`, **120 × 50**. Coordenadas em tiles (coluna, linha).

- **Galeria de carga** (x 1–23, y 43–48): portal de volta ao Núcleo `dk_exit_core` (1,48),
  nascimento `P` (3,48), doca `dk_dock_01` (6,48), caixas, SR-3 numa prateleira sólida
  (x 13–17, y 45) com a célula na ponta, CX-2 no teto (16,43).
- **Brecha** (vácuo permanente `dk_vac_breach`, x 24–29, y 31–48): célula no alto; sai rente ao
  teto pelo corredor x 30–35, y 31–34 (doca `dk_dock_02`), que cai dentro do hangar.
- **Hangar** (x 36–78, y 14–40; vácuo `dk_vac_hangar` com a contenção desligada): passadiço
  x 36–54 (y 21–22), elevador de carga (56,20), berço vazio (66,40), Dado (66,29), V-9 ×2,
  sinalizadores, **A** (47,40). Parapeito (76–78, 21) diante da parede falsa (79,19–20) → cabine
  x 80–85, y 17–20 (log 2, capacitor).
- **Vestiário EVA** (x 16–27, y 6–20) + corredor (x 28–35, y 18–20) com a porta (34,20): log 1
  (18,20), **B** (25,20), doca (29,20), prateleiras y 17 / 13 / 9 (4 tiles cada).
- **Duto** (x 16–86, y 2–4): um jato de vapor (40,4), poço x 46–48 para o hangar, CX-2 (68,2),
  doca (82,4), eclusa externa (85,4).
- **Anel externo** (vácuo permanente, x 87–117, y 2–16): 4 destroços, V-9, CX-2 (101,6),
  Dado (114,3); tubo de atracação no casco (x 108–113, y 17).
- **Vestíbulo** (x 98–117, y 18–25): SR-3 (116,25) no fosso leste (x 106–117), bloco de **C**
  x 102–105 (C em (103,21)), comporta da antessala (99,25), kit (101,25). A doca `dk_dock_05` fica
  na **passagem** (96,25), do outro lado da comporta, longe da patrulha (integração F63).
- **Volta ao Núcleo** (padrão da F45): portal `E` `dk_exit_core` junto do nascimento e bloco
  `revisit` `after_sector: docks` no `docks.json` (fase mais clara na revisita). No Núcleo, a
  comporta `door_docks` (121,11, selada até a Enfermaria) e o portal `core_hub_exit_docks` (125,11)
  ligam as Docas à ala de setores (F45 §6.4, ligado na integração).
- **Antessala** (x 84–117, y 30–44) — ver Gancho para a F63.

## 4.3 Gancho para a F63 (O Serralheiro)

Estado atual, depois da F63 (detalhes em [F63 §4](F63-serralheiro.md#4-escopo)):

- **Arena:** `x 84–117, y 32–44` (34 × 13 tiles = 544 × 208 px), piso na linha 45, **teto na 31**
  (desceu duas linhas para o trilho do braço caber na câmera, ADR-F63-004). Entrada única por cima:
  passagem `x 90–97, y 23–25` (doca `dk_dock_05` em 96,25) e poço `x 90–92, y 26–31`, com a
  escotilha da F63 na linha 31. Não há volta: morrer leva à doca `dk_dock_05`.
- **O Serralheiro:** `K` em **(103,32)**, braço estacionado à vista do pouso; parâmetros no
  `docks.json` (`couplers`, `node`, `arena`, `trigger`, `rail`, `gate`, `hatch`, `vent`, `bays`).
- **Nó do setor:** `dk_sector_node` em **(115,40)**, sobre o estrado sólido `x 111–117, y 41–44`
  (pulo duplo), coberto pela placa soldada até o braço desligar. Luz `dk_node_lamp` em (115,36).
- **Acopladores** (`A`, `scenes/world/coupler.tscn`, classe `Coupler`, grupo `coupler`):
  `dk_coupler_01` **(87,44)** no piso oeste, `dk_coupler_02` **(100,37)** na passarela `=`
  x 93–106 y 38, `dk_coupler_03` **(112,40)** no estrado. Estados `OFF / CHARGING / POWERED /
  SEALED`; a F63 somou o soquete de **segurar** (`set_armed`, `is_held`, carga com 3 pontos).
  Seguem sem sistema de energia (`system_id: ""`).
- Plataforma de pouso `=` x 89–94 y 41; degrau `=` x 105–110 y 41 emendado ao estrado; comporta do
  piso da F63 em x 95, y 39–44. Luzes da antessala ligadas a `node_door`.

## 5. Critérios de aceite

- [x] Vácuo: sem gravidade, deriva, 4 Integridade/s, ancora em parede/teto, impulso pelo pulo; leitura visual inconfundível; a contenção liga e desliga o vácuo do hangar
- [x] Propulsor: pulo duplo (15 de Carga, 1 por salto) e pilotagem no vácuo (6 Carga/s); jato visível; DESCARGA bloqueia; custo no Terminal do Chassi
- [x] Docas jogáveis do começo ao Nó; religar → cutscene → fala → tela de fim
- [x] Religar a Enfermaria volta ao Núcleo
- [x] Puzzle 6/3 com cadeia; a solução ingênua falha; nenhum estado de energia prende o jogador
- [x] 2 logs + 2 dados + 1 capacitor + 1 segredo; contadores 10/10
- [x] ÓRBITA fala só na entrada, no Propulsor e no religamento; terminal mudo
- [x] HUD com os mesmos elementos de antes
- [x] Alcançabilidade verde (com vácuo e pulo duplo no modelo); roteiros de QA com marcos chegam ao fim
- [x] Portões verdes; sem comentários; nada 3D

## 6. Definição técnica

```
scripts/core/vacuum_rules.gd          class_name VacuumRules — pulo duplo, impulso, deriva, pilotagem (puro)
scenes/world/vacuum_zone.tscn (+ .gd) zona de vácuo: céu, destroços, borda; powered = vácuo ativo
scenes/world/coupler.tscn (+ .gd)     acoplador de energia (F63 reaproveita)
scenes/world/escape_cradle.tscn (+gd) berço vazio da SELENE (prop grande, 128×64)
scenes/levels/docks.tscn              level_base, level_id "docks", Narrative (thruster, tut_thruster)
scripts/core/level_reachability.gd    + pulo duplo (meta "reach": {"double_jump": true}) e vácuo por inundação
```
- `mu7.gd`: `_vacuum_step` (piso com botas, âncora, impulso, pilotagem), `_try_double_jump`, jato
  (`ThrusterJet` + `ThrusterExhaust`), dano de vácuo no `_process_hurtbox`.
- `VacuumZone` **não** entra no grupo `powered`: a cutscene de religamento liga tudo o que está
  desligado, e ligar o vácuo seria abrir a baia no fim.
- `SectorNarrative.ability_tutorial`: cartão de tecla na hora do upgrade.

Números novos (GDD-P + AJ-047/048 antes do Balance):

| Constante | Valor | Origem |
|---|---|---|
| `VACUUM_DPS` | 4 pts/s | 2.6.2-E |
| `VACUUM_PUSH_SPEED` | 100 px/s | AJ-047 |
| `VACUUM_MAX_SPEED` | 160 px/s | AJ-047 |
| `VACUUM_FLOOR_STICK` | 30 px/s | AJ-047 |
| `THRUSTER_ACCEL` | 320 px/s² | AJ-047 |
| `THRUSTER_SPEED` | 120 px/s | AJ-047 |
| `THRUSTER_DRAIN` | 6 Carga/s | AJ-047 |
| `LOGS_TOTAL` / `RESEARCH_TOTAL` / `SECRETS_TOTAL` | 10 / 10 / 5 | AJ-048 |

## 7. Assets necessários

| Asset id | Uso | Placeholder |
|---|---|---|
| TIL-DOCKS | tileset das Docas | `assets/placeholder/tiles/docks_tiles.png` |
| SPR-PROPS-DOCKS | caixa, combustível, traje, carrinho, empilhadeira, poltronas, cabeço, painel | `assets/placeholder/sprites/props/docks_props_sheet.png` |
| SPR-CRADLE | berço vazio da SELENE (128×64) | `assets/placeholder/sprites/world/escape_cradle.png` |
| SPR-COUPLER | acoplador, 4 estados | `assets/placeholder/sprites/world/coupler_sheet.png` |
| FX-THRUSTER | jato do Propulsor, 4 quadros 16×16 | `assets/placeholder/sprites/fx/thruster_jet.png` |
| MUS-DOCKS | trilha das Docas | toca `core` até chegar |

## 8. 🧑 Ação humana

Nenhuma que bloqueie. Pendente: a faixa `docks` (ficha MUS-DOCKS).

## 9. Plano de execução

- [x] **Passo 1** — GDD-P + AJ-047..049; Balance
- [x] **Passo 2** — Arte por IA em paralelo com o puzzle no papel
- [x] **Passo 3** — Vácuo, Propulsor, zona, acoplador, berço; modelo de alcançabilidade
- [x] **Passo 4** — Mapa, JSONs, textos, ligação Enfermaria → Núcleo, revisita das Docas
- [x] **Passo 5** — Testes, portões, QA com marcos, checklist §4.7, docs e commit

## 10. Verificação

- **Testes:** `test_vacuum_rules.gd` (regras puras), `test_energy_docks.gd` (§4.1 resolve pelas duas
  rotas; ingênuas falham; a cadeia ocupa o orçamento; nenhum estado prende), `test_level_docks.gd`
  (contagens, consoles antes da comporta por flood fill, gates de 4 tiles só com pulo duplo,
  meio da fase sem Propulsor pelo modelo com vácuo), `test_level_reachability.gd` (fixtures de vácuo
  e de pulo duplo), `test_level_tileset.gd`, `test_hud_chassis.gd`, `test_tutorial.gd`, paridade GDD-P.
- **Roteiros:** `tests/qa/f62_docks.json` (nascimento → Nó → tela de fim) e
  `tests/qa/f62_vacuum.json` (hangar em vácuo: deriva, âncora, impulso, Dado do berço).
- **Playtest humano:** o vácuo é legível? A deriva sem Propulsor é jogável e a pilotagem com ele é
  claramente melhor? 8/10?

## 11. ADRs locais

### ADR-F62-001 — O vácuo do hangar é ligado por `group` + `invert`, fora do grupo `powered`
- **Contexto:** a zona precisa responder ao `containment` ao contrário (contenção ligada = sem
  vácuo). O pitfall da F60 manda `invert` só por grupo. E a cutscene de religamento liga todo nó do
  grupo `powered` que está desligado.
- **Decisão:** a zona tem `powered` = "vácuo ativo", é comandada por `group:dk_vac_hangar` com
  `invert` e `system_id: ""`, e não entra em `powered`. As zonas permanentes nem têm vínculo.
- **Data:** 2026-11-20.

### ADR-F62-002 — Impulso no vácuo: do piso sempre sai, de parede e teto pode deslizar
- **Contexto:** com "afastar sempre" o MU-7 nunca subia rente a uma parede até uma abertura; com
  "seta pura" o pulo + seta lateral no piso virava andar.
- **Decisão:** a componente para dentro da superfície é descartada; no **piso**, sem componente de
  afastar, soma-se "para cima" (pulo + direita sai na diagonal); em **parede/teto** a seta paralela
  vale pura (desliza). Sem seta: para longe da superfície.
- **Data:** 2026-11-20.

### ADR-F62-003 — Propulsor por log no vestiário, não por coletável
- **Contexto:** o upgrade tinha de vir no meio da fase, num ponto que só a primeira metade alcança.
- **Decisão:** mesmo padrão das garras, do dissipador e do núcleo aquecido (log da Helena com
  `unlock_ability`), mais o cartão `tut_thruster` pela `SectorNarrative` na hora do upgrade.
- **Data:** 2026-11-20.

### ADR-F62-004 — Religar as Docas leva à tela de fim; a revisita "docks" fica pronta
- **Contexto:** o pedido trazia as duas coisas ("volta ao Núcleo" e "o FIM DA DEMO passa a disparar
  depois das Docas"), e a porta da Enfermaria/Docas no Núcleo é da F45.
- **Decisão:** a Enfermaria passa a voltar ao Núcleo (`next_scene`); as Docas disparam o fim
  (sem `next_scene`). A entrada `revisit` `after_sector: docks` já fica no `core_hub.json` para a
  F64 só trocar o fim das Docas pela volta ao Núcleo.
- **Data:** 2026-11-20.

## 12. Log de evolução

### 2026-11-20 — Feature criada, planejada e construída (agente de fase, worktree)
- **Quem**: agente de fase F62.
- **O que**: feature criada (puzzle no papel, mapa por zonas, gancho da F63) e construída inteira:
  - **Números**: GDD-P + AJ-047 (vácuo e Propulsor), AJ-048 (Enfermaria volta ao Núcleo; 10/10/5),
    AJ-049 (vácuo como estado, cadeia da meta, Propulsor no meio) → `Balance`.
  - **Sistemas**: `VacuumRules` (puro), `VacuumZone` (`V`), `Coupler` (`A`), `EscapeCradle`;
    `mu7.gd` com vácuo (botas, âncora, impulso, pilotagem), pulo duplo e jato; dano de vácuo no
    `_process_hurtbox`; Propulsor no Terminal do Chassi; cartão `tut_thruster` pela
    `SectorNarrative.ability_tutorial`; modelo de alcançabilidade com pulo duplo (meta `reach`) e
    vácuo por inundação.
  - **Fase**: `docks.{txt,json}` 120×50, `energy/docks.json` (6/3, cadeia), logs, falas,
    `docks.tscn`, objetivos `obj_docks`, `obj_core_docks`, `obj_core_memory`; `revisit` das Docas no
    Núcleo e fala `core_return_docks`; Enfermaria → Núcleo.
  - **Arte por IA** (Codex, 2 variações cada, nenhuma regerada): TIL-DOCKS, SPR-PROPS-DOCKS,
    SPR-CRADLE, SPR-COUPLER, FX-THRUSTER; placeholders no manifesto; fichas no ASSETS; MUS-DOCKS pendente.
- **Ajustes vindos do QA** (o mapa mudou depois do primeiro roteiro):
  - pular a caixa logo antes da brecha deixava o MU-7 **entrar no vácuo no ar e flutuar** até a
    parede — a zona da brecha começa agora 2 colunas depois da caixa;
  - deslizar rente ao teto **reancorava** a cada quadro (o contato tangencial conta como colisão):
    agora só ancora quem deriva **contra** a superfície (`VacuumRules.hits_surface`);
  - SR-3 da galeria mudou para uma prateleira sólida (no piso ela empurrava o MU-7 e o trilho
    variava de rodada para rodada); um só jato de vapor no duto (dois em 3 tiles de altura matavam);
    poço do duto de 4 para 3 tiles; tubo de atracação de 3 para 6 tiles; com o Propulsor, seta para
    longe da superfície pilota a partir da âncora.
- **QA**: `tests/qa/f62_docks.json` (gerador `tests/qa/gen/f62_docks.py`) — nascimento → brecha em
  vácuo (impulso, âncora no teto, deslize) → A (corta contenção, abre vestiário) → hangar em vácuo
  (sobe pelo poço do elevador, desliza no teto, desce rente à parede) → doca → log 1 (Propulsor) →
  B (contenção + eclusa) → 3 prateleiras de pulo duplo → duto (dash no vapor, pulo duplo no poço,
  doca) → anel externo pilotando → tubo → bloco de C (pulo duplo) → C (vestiário fora, meta dentro) →
  antessala → estrado → Nó → cutscene → fala → tela de fim. **22/22 marcos em duas rodadas.** O
  roteiro desliga a segurança por chamada no quadro 150 (a CX-2 da galeria, em tempo real, tirava o
  trilho do lugar); a segurança ligada aparece no `tests/qa/f62_tour.json` (4 marcos, visita por
  teleporte: brecha, hangar selado × vácuo, berço, vestiário, duto, anel, vestíbulo, antessala).
  Capturas lidas: brecha com céu aberto e borda amarela; hangar selado (véu ciano) × em vácuo;
  berço em silhueta contra as estrelas; cartão do pulo duplo; jato no anel externo; Nó com os três
  acopladores; tela de fim 1/10 · 0/10 · 0/5.
- **Checklist §4.7**: (1) terminal mudo, fase sem gatilhos de fala — sim (teste); (2) ÓRBITA só em
  `dk_enter`, `dk_thruster`, `dk_restored` (e `core_return_docks` no Núcleo) — sim; (3) trocas
  obrigatórias em A, B e C, ingênuas falham, mínimo de 6 trocas (`test_energy_docks`) — sim;
  (4) cabine secreta só no vácuo (log 2 + capacitor), Dado do berço só no vácuo, Dado do anel atrás
  da CX-2 — sim; (5) galeria, duto e antessala escuros de verdade — sim; (6) silhuetas: berço,
  acoplador, comporta, doca, console, portal, borda do vácuo — sim; (7) HUD igual (custo do
  Propulsor só no Terminal do Chassi) — sim; (8) roteiro até o fim — sim; (9) cutscene: sinalizadores
  da segurança, porta do vestiário, elevador e luzes da antessala acendem no caminho — sim.
- **Portões**: `tools/gates.sh` completo verde — 916 testes, 92 cenas.
- **Pendências**: frase da tela de fim para as Docas (`scenes/ui/demo_end.gd` não é meu: hoje cai
  na da Enfermaria); faixa MUS-DOCKS; sons próprios do vácuo/jato (empresta `dash`/`jump`);
  ligação hub ↔ Docas (F45/orquestrador); F63 ocupa a antessala.

### 2026-11-21 — Integração com a F45 (ida e volta) e o hub
- **Quem**: agente de integração (branch `final/integracao`) · **O que**: o diff da F62 (feito sobre
  a `main` sem a F45) aplicado sobre a `main` com F45/F67/F33/F34/F71. Conflito textual só na skill
  `level-design` e na tabela de Ajustes do GDD (AJ reordenados por número: 047–053, 059–060).
- **Conflitos semânticos**: nenhum de código. `level_exit` já era `Interactable` com `sector` e o `E`
  das Docas (`dk_exit_core`, `sector: core`) entrou no padrão; `hud_model` (custo do Propulsor),
  `sector_plate`/cores (F71), `tests/scenes.txt` e as listas `PLAYABLE_LEVELS` combinaram sem
  mexer. Quebraram só contagens: `test_reserved_exits_wait_for_their_scenes` (vaga ainda
  reservada, o esperado), `DEMO_SEQUENCES` 27→28 (fala nova) e 3→4 portais no hub.
- **Ligação ao hub** (F45 §6.4): `E` em 125,11 e `core_hub_exit_docks` movido de `reserved_exits`
  para `entities`; Docas em `HUB_EXITS`/`SECTOR_RETURNS`. Revisita do hub completa: greenhouse →
  lab → **infirmary** (nova: `obj_core_docks`, `#4a637a`, fala `core_return_infirmary`) → docks
  (`#58748a`, `obj_core_memory`, `core_return_docks`). Testes novos em `test_level_docks.gd`
  (ordem da revisita, saída viva e vaga consumida).
- **Tela de fim**: `demo_end.gd` ganhou `docks` ("AS DOCAS SEGURARAM O AR. A ESTAÇÃO AINDA NÃO.") e
  o padrão passou a ser as Docas, o último setor pronto.
- **Capacitor**: `capacitor_dk_01` usa o `kind` `capacitor` dos outros três (4 no jogo, alvo da F69).
- **QA com marcos (todos OK)**: `f62_docks` 22/22 (fim com a frase das Docas), `f62_tour` 4/4,
  `f45_c_ala_selada` 6/6 (comporta das Docas aberta e portal vivo), `f62_hub_docks` 9/9 (novo:
  Continuar com a Enfermaria religada → portal das Docas → chega no portal `dk_exit_core` 1,48 → volta
  → reaparece em 125,12), `f61_hub_return` 16/16 (estendido: a Enfermaria religada volta pela porta
  dela, fala `core_return_infirmary`, objetivo "Chegar às Docas", comporta aberta), `f45_a` e `f45_b`.
- **Nota**: quem entra pela porta nasce no portal de volta (ADR-F45-002), não no `P`.
- **Portões**: `tools/gates.sh` completo verde — 1010 testes, 96 cenas no smoke.

### 2026-11-21 — Integração com a F63 (O Serralheiro) sobre F66/F69/F68
- **Quem**: agente de integração (branch `final/integracao`) · **O que**: a arena da F63 ocupa a
  antessala; a §4.3 acima descreve o estado novo (teto na 31, arena y 32–44, A2 (100,37), A3
  (112,40), `K` (103,32)).
- **Doca do vestíbulo**: `dk_dock_05` saiu do fosso (114,25), onde a SR-3 (116,25) patrulha, e foi
  para a passagem (96,25), entre a comporta da antessala e o poço. Antes, a cada tentativa contra o
  Serralheiro o MU-7 renascia colado à SR-3 e levava dano antes de se mexer (checklist §4.7: morrer
  não pode virar castigo em loop). A SR-3 continua guardando o fosso na primeira passagem; o bloco
  de **C** e a comporta a separam da doca. A doca segue no caminho (checkpoint por contato).
- **4ª Placa (F69)**: `plate_dk_01` em (32,40), num cofre x 31–34 × 38–40 cavado na parede oeste do
  hangar, atrás da porta ROOT `dk_root_door` (35,40). Fica à vista de quem cai no hangar pela
  primeira vez (`SELADA - ACESSO ROOT`) e pede a volta depois do Núcleo de Memória.
- **QA com marcos**: `f62_docks` 41/41, `f62_tour` 4/4, `f62_hub_docks` 9/9 (capturas lidas: a
  passagem com a doca nova e a SR-3 do outro lado do bloco).

### 2026-11-21 — As Docas voltam ao Núcleo (integração da F64)
- Religar as Docas → cutscene → fala → **volta ao Núcleo** (`next_scene` no `docks.tscn`), com a
  revisita `after_sector: docks` abrindo a comporta da Memória. O `f62_docks` (gerador da F63, com a
  luta do Serralheiro) termina em `core_hub.tscn`: 41/41 marcos.
