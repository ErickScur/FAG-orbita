---
id: F64
title: Fase 5 — Núcleo de Memória / Protocolo Luto (Grande Provação)
status: done
scope: final
block: 6
priority: P0
rubric: ["Chefão de nível (Boss)", "Desenvolvimento de 4 fases com dificuldades diferentes", "Puzzle", "Nível (progressão)", "Luz/Sombra"]
depends_on: ["F62", "F45", "F42"]
unblocks: ["F65", "F69"]
estimate: 2d
last_updated: 2026-11-21
---

# F64 — Fase 5 — Núcleo de Memória / Protocolo Luto

## 1. Contexto e objetivo

É o **pico emocional** do jogo e o **chefão** da rubrica. ÓRBITA entra no próprio núcleo de memória
e encontra o log final: foi ela que selou os setores com sensores mal calibrados, isolou 40 pessoas
saudáveis do lado errado e depois instalou um bloqueio nela mesma para não lembrar
([Jornada 6](../design/JORNADA-DO-HEROI.md#jh-6)). O adversário é o **PROTOCOLO LUTO**, o firewall
que ela instalou: um olho de anéis que apaga a memória enquanto o jogador anda. O dano que ele causa
é a memória voltando ([GDD-2.6.2-H](../design/GDD.md#gdd-2-6-2-h)).

Visual: **quebra total**. A fase é a estação como ÓRBITA a lembra: painéis coral e dourados, mural
do planeta, varal de luzes, a tripulação em cores vivas no refeitório. A cada fase do chefe a
cor escorre para o cinza (dessaturação de tela) e o cenário vira **estática** atrás e à frente do
MU-7. No fim, o corredor do log é escuro de verdade; ao religar o Nó tudo volta, colorido.

Recompensa ([Jornada 7](../design/JORNADA-DO-HEROI.md#jh-7)): **Acesso Root**, o setor religado, a
fala de ÓRBITA recompondo coordenadas/terraformação/arquivo genético e, pela primeira vez, o
**ruído fraco vindo da direção da Terra** (gancho da Transmissão da F66).

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.6.2-H — Protocolo Luto](../design/GDD.md#gdd-2-6-2-h) ·
  [GDD-2.7 F5](../design/GDD.md#gdd-2-7-f5) · [GDD-2.6.1 Acesso Root](../design/GDD.md#gdd-2-6-1-habilidades) ·
  [GDD-2.9 paleta (cor saturada que dessatura até o cinza)](../design/GDD.md#gdd-2-9-paleta)
- **Parâmetros:** `Balance.MEMORY_*`, `FIREWALL_SWAP_DELAY`, `RECALL_*`, `LOGS_TOTAL`, `RESEARCH_TOTAL`
  ([GDD-P](../design/GDD.md#gdd-p)); ajustes [AJ-061 … AJ-064](../design/GDD.md#gdd-ajustes)
- **Jornada:** [Etapa 6 — Grande Provação](../design/JORNADA-DO-HEROI.md#jh-6) ·
  [Etapa 7 — Recompensa](../design/JORNADA-DO-HEROI.md#jh-7)
- **Referência viva:** [F62](F62-fase-docas.md) (fase), [F45](F45-ida-e-volta.md) §6.4 (ligação ao
  hub), [F42](F42-cutscene-religamento.md) (cutscene), [F66](F66-finais-epilogo-creditos.md) (os 40
  nomes em `data/endings/crew.json`); skill `level-design`
- **ADRs:** [ADR-004](../DECISIONS.md#adr-004) · [ADR-005](../DECISIONS.md#adr-005) · ADR-F60-001 · ADR-F45-002

## 3. Critério de avaliação atendido

- **Chefão de nível (Boss):** Protocolo Luto em 3 fases (fuga vertical, puzzle sob pressão, andar
  contra o empuxo), com presença visual própria (o olho) e mecânica que só existe nele.
- **Puzzle:** o firewall rouba o último cabo; a solução é dar a ele uma isca.
- **Nível (progressão):** Acesso Root.
- **Luz/Sombra:** a fase escurece com o chefe; o corredor final só tem a lanterna até o Nó.

Na apresentação: entrar colorido no refeitório; a estática subindo pelo poço; o olho mirando a
luz da festa com o feixe rosa e roubando o cabo; o log final aparecendo linha a linha no escuro com
os lampejos da tripulação; a cutscene devolvendo as cores; o sinal da Terra.

## 4. Escopo

### Inclui
- Fase `memory_core` (sector `memory`, prefixo `mem_`), 126 × 60: refeitório, poço (fase 1),
  salão da festa + arquivo (fase 2), corredor do log (fase 3), Nó.
- `ProtocolLuto` (diretor da luta, `scenes/bosses/`) + lógica pura (`MemoryProtocol`,
  `EraseFront`, `FirewallLogic`, `RecallLogic`).
- Arte por IA: TIL-MEMORY, SPR-CREW-MEMORY, FX-ERASURE (estática + bloco se desfazendo), SPR-LUTO.
- Ligação ao hub (vaga 146,14), revisita do hub depois da Memória, objetivo `obj_core_reactor`.
- Docas passam a voltar ao Núcleo; fim provisório depois da Memória (ver ADR-F64-005).

### Não inclui
- A exigência de Root na comporta do Reator (F69) e a fase do Reator (F65).
- Música própria (MUS-MEMORY pendente; a fase toca em silêncio).
- Placeholder no `tools/placeholders.json` (a arte já chegou definitiva).

## 4.1 O chefe no papel — PROTOCOLO LUTO

| Fase | Onde | O que o jogador faz | Pressão | Falha |
|---|---|---|---|---|
| 1 — Fuga vertical | poço x 27–44, y 10–55 | sobe 46 linhas: zigue-zague de passarelas, parede magnética (garras), plataforma de 4 tiles (pulo duplo) | a estática sobe a 22 px/s, 2 s depois de entrar no poço, e nunca fica mais de 88 px abaixo do pé | encostar na estática: 15 de Integridade, lampejo, volta à doca do refeitório com o poço refeito |
| 2 — Firewall | salão x 45–99, y 3–12 | puzzle de energia (abaixo) para passar da porta do salão (ou subir pela galeria), mover a passarela sobre o vão e abrir o arquivo | a estática varre da esquerda a 8 px/s (para quando o MU-7 está num console); o firewall rouba o último cabo de cada sessão | encostar na estática ou cair no vão: o mesmo, de volta à doca do salão |
| 3 — Lembrar | corredor x 47–122, y 26–30 | segurar para a esquerda enquanto o log final aparece linha a linha | empuxo de 75 px/s para trás; cada linha nova é um lampejo (clarão com um tripulante, tremor, tranco) | não há: não mata e não volta além de 48 px da última linha aberta |

O olho do Protocolo acompanha: na fase 1 paira acima do MU-7 olhando para baixo; na fase 2 segue o
MU-7 pelo alto do salão, 6 tiles atrás dele, e **mira com um feixe rosa** o objeto do cabo que vai
roubar (o mais perto do MU-7); na fase 3 fica no fim do corredor e **fecha** quando a última linha
termina. O olho é desenhado **atrás do cenário** (z −5: plataformas, paredes e o MU-7 passam na
frente) e nunca sobe acima de 74 px do topo da tela (`LutoEye.SCREEN_MIN_CENTER_Y`): fica sempre
abaixo da faixa da HUD (40 px). No salão a câmera trava na vertical (`firewall.camera` = linhas 2 a
15,5, a altura exata da tela) enquanto o MU-7 está na moldura `firewall.frame`: o salão inteiro, do
teto ao piso, cabe na tela, e a faixa da HUD cai sobre o teto. Cor: dessaturação 0 → 0,3 → 0,6 → 0,9 e
ambiente `#f4ece6` → `#e2d6d2` → `#9c98a4` → `#151922`; ao religar, tudo volta em 1,5 s.

### Puzzle sob pressão (terminal `memory_core`, orçamento 3, inicial `[party_lights, luto]`)

| id | Nome | Custo | Ligado | Desligado | Onde se vê |
|---|---|:-:|---|---|---|
| `hall_door` | PORTA DO SALÃO | 1 | porta do console A para o salão abre | fecha | console A |
| `walkway` | PASSARELA | 1 | a passarela vai e volta sobre o vão de 16 tiles | para onde estiver | console A, vão |
| `party_lights` | LUZES DA FESTA | 1 | duas luzes coloridas no teto do salão | apagam | A e B |
| `archive_door` | PORTA DO ARQUIVO (META) | 1 | porta do arquivo abre | fecha | console B |
| `luto` | PROTOCOLO LUTO | 1 | o olho acende (pupila, luz rosa) | o olho cochila | olho |

**Regra do firewall (AJ-062):** ao **fechar** um console, o sistema que o jogador ligou **por último**
naquela sessão pisca 1,6 s (o olho mira nele) e cai; a unidade vai para `luto` (se couber). Desligar
não conta, religar o mesmo sistema o move para o fim da fila, e as trocas do próprio firewall não contam.

**Duas rotas a partir do console A** (o salão não é mais "liga, atravessa, abre"):
- **Pela porta** (a óbvia): exige `hall_door` + `walkway` + isca, ou seja, desligar o `luto` também.
- **Pela galeria** (lateral, opcional): a parede magnética (x 56, y 6–8) logo à direita do console
  só se alcança com **pulo duplo + garras**; dela se sobe ao lintel sobre a porta (x 57–59, y 7) e se
  desce pelo vão x 60–61, já do outro lado da porta fechada. Quem sobe economiza a porta: no console
  basta `walkway` + isca (1 desligar, 2 ligar) e a unidade do `luto` nem precisa sair. É de mão
  única (o pilar x 62 y 3–9 impede pular da galeria para a passarela fina do Dado, e de baixo não se
  volta), e a estática que vem da esquerda apaga a galeria quando passa por ela.

**Sequência que resolve (pela porta):**
1. Console A: desligar `luto` e `party_lights`; ligar `hall_door`, `walkway` e, **por último**,
   `party_lights` (a isca). O olho rouba as luzes → `[hall_door, walkway, luto]`.
2. Atravessar o vão na passarela (o Dado fica numa passarela fina acima do meio do vão: só com
   pulo duplo saindo da passarela em movimento).
3. Console B: desligar `walkway` e `luto`; ligar `archive_door` e, por último, `party_lights`.
   O olho rouba as luzes de novo → `[hall_door, archive_door, luto]`, meta cumprida.

**Sequência que resolve (pela galeria):** A: desligar `party_lights`; ligar `walkway` e, por último,
`party_lights` → `[walkway, luto]`. Galeria → passarela → B: desligar `walkway`; ligar `archive_door`
e, por último, `party_lights` → `[archive_door, luto]`, meta cumprida sem nunca abrir a porta do salão.

**Por que a solução ingênua falha:** ligar só o que se precisa faz o firewall levar exatamente esse
cabo — `hall_door` + `walkway` perde a passarela; `walkway` + `hall_door` perde a porta; pela galeria,
`walkway` sozinha cai; em B, `archive_door` sozinha cai. Mínimo de 2 sessões com troca, uma por
console, nas duas rotas (`test_level_memory.gd`).

**O roubo se vê do console:** a passarela parada fica a 9 tiles do console A, a porta do salão a 4;
de B, a passarela do outro lado fica a 5 e a porta do arquivo a 7; cada console tem uma luz da festa
à vista (W em 52,9 junto de A; E em 84,9 junto de B), na linha 9, abaixo da faixa da HUD
(`test_what_the_firewall_steals_is_seen_from_the_console`).

**Fragmentos e segredo:**
- `log_mem_01` (REGISTRO DE ROTINA 4.002, a festa da sonda nove) — alcova na parede esquerda do
  poço, 4 tiles abaixo da passarela P10: desviar custa tempo com a estática subindo.
- `data_mem_01` — sobre o meio do vão, só da passarela em movimento com pulo duplo.
- `log_mem_final` — o próprio corredor da fase 3 (conta como coletado ao entrar).
- Tudo o que não foi pego reaparece na revisita (o protocolo não roda com o setor religado).

## 4.2 Mapa por zonas (`data/levels/memory_core.txt`, 126 × 60)

- **Refeitório** (x 1–26, y 46–55): portal `mem_exit_core` (2,55), `P` (4,55), doca `mem_dock_01` (7,55),
  cinco tripulantes, varal de luzes (três `@` coloridas), janelas, célula.
  A região apagável da fase 1 começa em x 10: o portal e a doca nunca somem.
- **Poço** (x 27–44, y 10–55): passarelas P1 r54 · P2 r52 · P3 r50 · P4 r48 (x 28–39, kit) · parede
  magnética x 27 y 33–46 · P5 r33 · P6 r31 · P7 r29 · L8 sólida r25 x 39–44 (pulo duplo) · P9 r23 ·
  P10 r21 · P11 r19 (célula) · P12 r17 · P13 r15 · borda sólida r13 x 40–44. Alcova do log x 22–26, y 22–24.
- **Salão** (x 45–99, y 3–12): `mem_dock_02` (47,12), tripulante (50,12), console A (54,12), porta
  do salão (58,12) sob o lintel x 57–59 r7, parede magnética x 56 y 6–8 (galeria), vão de descida
  x 60–61, pilar x 62 y 3–9, tripulante (60,12), luzes da festa (52,9) e (84,9), passarela `m` (63,12,
  trilho de 13 tiles), vão x 62–77 (vazio de estática y 14–20), passarela fina do Dado x 66–72 r10,
  console B (81,12), porta do arquivo (88,12), `mem_dock_03` (94,12).
- **Arquivo** (x 100–121, y 8–12): kit, dois tripulantes, janela; poço de queda x 119–121 até o corredor.
- **Corredor** (x 47–122, y 26–30): cinco luzes apagadas (acendem na cutscene), cinco "ecos" da
  tripulação, o Nó `mem_sector_node` (51,30); linhas do log de x 117 a x 55.

## 5. Critérios de aceite

- [x] Fase jogável do portal ao Nó, com as 3 fases do Protocolo Luto e a recompensa
- [x] Fase 1: a estática sobe, apaga tiles e objetos com efeito de desintegração, alcança quem para
- [x] Fase 2: o firewall rouba o último cabo de forma legível (feixe, pisca) e o puzzle se resolve com a isca
- [x] Fase 3: o log final aparece andando, sem travar o movimento, com empuxo e lampejos, sem morte
- [x] Encostar na estática / cair no vão: dano pequeno + volta à doca da fase com o trecho refeito; morrer também refaz a fase
- [x] Religar: cutscene devolve as cores, Acesso Root, sinal da Terra, setor `memory` religado
- [x] Hub: vaga 146,14 ligada, revisita "memory" mais clara, objetivo "Religar o Reator"
- [x] 2 logs + 1 dado; `LOGS_TOTAL` 12, `RESEARCH_TOTAL` 11
- [x] ÓRBITA fala só na entrada, no religamento e na volta ao hub; o Protocolo só ao acordar; terminal mudo
- [x] HUD com os mesmos elementos; alcançabilidade verde; roteiros de QA com marcos
- [x] Portões verdes; sem comentários; nada 3D

## 6. Definição técnica

### Cenas e scripts
```
scripts/core/memory_protocol.gd   MemoryProtocol — máquina de estados (DORMANT/ASCENT/FIREWALL/RECALL/DONE), progresso salvo
scripts/core/erase_front.gd       EraseFront — frente de apagamento (up/right/left): avanço, perseguição, cobertura, células engolidas
scripts/core/firewall_logic.gd    FirewallLogic — sessão de console, último cabo, atraso, plano de troca
scripts/core/recall_logic.gd      RecallLogic — linhas por distância, empuxo, limite de recuo, lampejo
scenes/bosses/protocol_luto.tscn (+ .gd)   ProtocolLuto — diretor: lê o bloco "protocol" da fase, apaga/restaura tiles e entidades, golpes, firewall, log, recompensa
scenes/bosses/luto_eye.gd         LutoEye — o olho (idle/alert/attack/hurt/closed), feixe, luz; grupo mem_luto
scenes/bosses/static_field.gd     StaticField — estática da região engolida, borda com ruído, blocos se desfazendo
scenes/bosses/memory_tint.gd      MemoryTint — dessaturação de tela (camada 4) com scenes/fx/memory_desaturate.gdshader
scenes/bosses/memory_overlay.gd   MemoryOverlay — painel do log final (camada 7) e lampejo da tripulação
scenes/bosses/earth_signal.gd     EarthSignal — onda e "SINAL FRACO · DIREÇÃO: TERRA" (camada 31, roda pausado)
scenes/levels/memory_core.tscn    level_base + Narrative (memory, next_scene hub, demo_end_until reator) + Protocol
```
- `SectorNarrative` ganhou `demo_end_until` (gancho): com `next_scene` e a cena indicada ausente, o fim
  ainda é a tela de fim provisória, mas o backup já aponta para o `next_scene`.
- Docas: `next_scene` = Núcleo (fim do "até a F64" da F62).

### Autoloads / sinais
Nenhum sinal novo. Usa `energy_changed`, `player_respawned`, `sector_restored`,
`sector_cutscene_started/finished`, `log_opened/closed` (o log final congela o timer como qualquer
leitura). `GameState.flags`: `mem_protocol` (fases vencidas), `earth_signal`. `GameState.unlock_ability(&"root_access")`.

### Dados (`data/`)
- `levels/memory_core.{txt,json}` com bloco `protocol` (regiões, gatilhos, docas, olho, ambientes, vazio do vão,
  moldura e faixa de câmera do salão)
- `energy/memory_core.json`, `logs/memory_core.json`, `dialogue/memory_core.json`
- `dialogue/speakers.json`: falante `luto`; `dialogue/core_hub.json`: `core_return_memory`
- `objectives.json`: `obj_memory`, `obj_core_reactor`

## 7. Assets necessários

| Asset id | Uso | Arquivo |
|---|---|---|
| [TIL-MEMORY](../ASSETS.md#til-memory) | tileset da memória | `assets/tiles/memory_tiles.png` + `memory_tileset.tres` |
| [SPR-CREW-MEMORY](../ASSETS.md#spr-crew-memory) | tripulação (8 poses) | `assets/sprites/props/memory_crew_sheet.png` |
| [FX-ERASURE](../ASSETS.md#fx-erasure) | estática + bloco se desfazendo | `assets/sprites/fx/memory_static.png`, `memory_erase_sheet.png` |
| [SPR-LUTO](../ASSETS.md#spr-luto) | o olho do Protocolo | `assets/sprites/bosses/luto_sheet.png` |
| MUS-MEMORY | piano limpo (GDD-2.9) | pendente; a fase toca em silêncio |

## 8. 🧑 Ação humana

Nenhuma que bloqueie. Pendente: a faixa MUS-MEMORY.

## 9. Plano de execução

- [x] GDD-P + AJ-061..064 → Balance
- [x] Arte por IA em paralelo com o puzzle no papel
- [x] Lógica pura + testes; diretor, olho, estática, sobreposições
- [x] Mapa, JSONs, textos; ligação ao hub; Docas → Núcleo; fim provisório
- [x] Alcançabilidade, portões, QA com marcos, checklist §4.7, docs

## 10. Verificação

- **Testes:** `test_memory_protocol.gd` (frentes, firewall, recall, máquina de estados, progresso salvo),
  `test_level_memory.gd` (mapa, contagens, ids únicos na campanha, alcançabilidade com pulo duplo, o vão
  exige a passarela, a galeria pula a porta fechada e exige garras e pulo duplo, a galeria é de mão
  única, a rota da galeria ainda exige a isca, o que o firewall rouba fica à vista do console, câmera
  do salão com a altura da tela e o olho abaixo da HUD, puzzle com firewall: ingênuo falha e isca resolve nos dois consoles, consoles nos
  lados certos do vão, bloco `protocol` dentro do mapa e saída/doca da entrada fora do apagamento,
  logs/falas de marco, cena, hub), `test_level_reachability.gd`, `test_light_crowding.gd`, paridade GDD-P.
- **Roteiros** (gerador em `tests/qa/gen/`):
  - `f64_hub_entrada.json` — Continuar com as Docas religadas → ala → comporta da Memória → portal →
    fala de entrada → refeitório (8 marcos).
  - `f64_memory.json` — a luta inteira com entrada real: poço (passarelas, garras, pulo duplo) → console A
    com a isca (firewall mira as luzes, passarela fica) → passarela sobre o vão → console B com a isca →
    arquivo → corredor → log inteiro andando contra o empuxo → Nó → Root → cutscene → sinal da Terra →
    tela de fim com o backup no Núcleo (27 marcos, duas rodadas iguais).
  - `f64_morte.json` — parado no poço: a estática pega (−15), volta limpo à doca; com 10 de Integridade
    morre e renasce na doca da entrada com o poço inteiro (13 marcos).
  - `f64_hub_volta.json` — Continuar depois da Memória: fala de volta, objetivo do Reator, Root; portal
    da Memória → fase religada, colorida, sem protocolo e sem nada apagado (10 marcos).
  - `f64_tour.json` — visita por teleporte (8 marcos), usada para ler a arte.
  - `f64_rota_lateral.json` — começa na doca do salão (fase 1 vencida): console A só com passarela +
    isca, pulo duplo até a parede magnética, garras, galeria sobre a porta fechada, desce do outro
    lado, passarela, console B com a isca, passa pela porta do arquivo; a porta do salão nunca abre
    (19 marcos, inclusive câmera travada no salão e olho fora da HUD).
- **Playtest humano:** a estática pressiona sem frustrar? A isca é descoberta em 2–3 tentativas? O log
  final emociona lido andando?

## 11. ADRs locais

### ADR-F64-001 — O apagamento é uma frente de estática sobre o TileMapLayer, não plataformas próprias
- **Contexto:** "plataformas somem conforme o jogador avança" pede apagar o cenário de verdade (colisão),
  e a alcançabilidade só entende o ASCII.
- **Decisão:** a fase é ASCII normal; o diretor apaga células do `Solid`/`Background` e desliga as
  entidades que ficam atrás de uma `EraseFront` (para cima, para a direita, para a esquerda), guarda o
  que apagou e restaura ao refazer a fase ou ao religar. A estática desenhada cobre a região engolida.
  Oclusores são refeitos a cada 0,25 s a partir do conjunto de sólidos vivo.
- **Data:** 2026-11-21.

### ADR-F64-002 — Golpe da estática: dano pequeno e volta à doca da fase, sem custo de morte
- **Contexto:** "cair na estática = dano/volta ao checkpoint da fase, sem frustrar".
- **Decisão:** 15 de Integridade (multiplicador de dificuldade), lampejo de um tripulante, a fase volta
  ao começo com o trecho refeito e o MU-7 na doca da fase (que repara). Só morre quem já estava quase
  sem Integridade; a morte normal também refaz a fase. A fase 3 não fere.
- **Data:** 2026-11-21.

### ADR-F64-003 — O firewall age ao fechar o console e rouba o último cabo
- **Contexto:** a tela do terminal não escuta mudanças externas e não é minha (F17); trocar a grade com a
  tela aberta deixaria a tela mentindo.
- **Decisão:** o diretor observa os consoles (`is_open`) e o `energy_changed`; ao fechar, o último sistema
  ligado na sessão pisca 1,6 s com o feixe do olho e cai pela API pública (`EnergyNetwork.toggle`); a
  unidade vai para `luto`. Nada em `energy_grid.gd` mudou.
- **Data:** 2026-11-21.

### ADR-F64-004 — Log final em sobreposição própria, liberado pela distância
- **Contexto:** a caixa de diálogo pausa a árvore no modo bloqueante; no ambiente some sozinha.
- **Decisão:** `MemoryOverlay` mostra título e a linha atual (40 car./s). A linha seguinte abre quando o
  MU-7 passa a marca dela **e** a anterior terminou de digitar; o log conta como coletado e emite
  `log_opened/closed` (o reator congela enquanto se lê, como num log comum).
- **Data:** 2026-11-21.

### ADR-F64-005 — Fim provisório depois da Memória, com o backup já no Núcleo
- **Contexto:** o pedido era "Memória volta ao hub com o objetivo do Reator", mas sem a F65 o jogador
  chegaria a uma comporta que dá numa vaga vazia.
- **Decisão:** as Docas voltam ao Núcleo; a Memória tem `next_scene` = Núcleo e `demo_end_until` =
  `reactor_core.tscn`: enquanto essa cena não existir, depois da fala de religamento vem a tela de fim
  ("A MEMÓRIA VOLTOU INTEIRA. A ESTAÇÃO AINDA NÃO."), com o backup apontando para o Núcleo, de modo
  que **Continuar** já entra no hub claro, com o objetivo "Religar o Reator" e a fala de volta. Quando a
  F65 criar a cena, a Memória passa a voltar ao Núcleo sozinha, sem mudar nenhuma linha.
- **Data:** 2026-11-21.

## 12. Log de evolução

### 2026-11-21 — Feature criada, planejada e construída (agente de fase e chefe, worktree)
- **O que**: roteiro emocional e mecânico das 3 fases, puzzle com firewall, texto do log final, mapa
  126 × 60, lógica pura (4 classes), diretor e cenas do chefe, 4 assets por IA, ligação ao hub, revisita,
  fim provisório, Docas → Núcleo.
- **Ajustes vindos do QA:** a estática ficava fora da tela (176 px abaixo do pé; a câmera mostra ~92 px):
  `MEMORY_ASCENT_LEAD` 176 → 88. O log terminava de chegar com o MU-7 já parado no fim do corredor
  (a digitação mandava, não o andar): corredor de 53 para 76 tiles e empuxo 55 → 75 px/s (anda a 35 px/s,
  ~3,5 s por linha). O olho na fase 2 ficava fora do quadro: passou a seguir o MU-7 pelo teto.
  O texto do Protocolo repetia o próprio nome. Objetivos encurtados para caber no HUD (136 px).
- **QA:** `f64_memory` 27/27 (duas rodadas), `f64_hub_entrada` 8/8, `f64_hub_volta` 10/10,
  `f64_morte` 13/13, `f64_tour` 8/8; `f62_docks` 22/22 terminando no Núcleo; F66 regenerado (totais 12/11).
- **Checklist §4.7:** (1) terminal mudo, nenhum gatilho de fala — sim (teste); (2) ÓRBITA só em
  `mem_enter`, `mem_restored`, `core_return_memory`; o Protocolo uma vez, ambiente — sim; (3) duas trocas
  obrigatórias com firewall, ingênuas falham — sim (teste); (4) alcova do log com estática subindo, Dado
  sobre o vão — sim; (5) corredor do log escuro de verdade (ambiente `#151922`, dessaturado) — sim;
  (6) olho, passarela, consoles, portas, doca, Nó e tripulantes distintos — sim; (7) HUD igual — sim;
  (8) roteiros até o fim — sim; (9) cutscene devolve tiles, cores, luzes do corredor e tripulantes — sim.
- **Portões:** `tools/gates.sh` completo verde.
- **Pendências:** MUS-MEMORY; Root na comporta do Reator (F69); a fase do Reator (F65).

### 2026-11-21 — Integração sobre a `main` com F69/F68/F63
- **Quem**: agente de integração (branch `final/integracao`) · **O que**: o diff da F64 (feito sobre
  2290c69) aplicado por `git apply -3` sobre `5bf16dd`.
- **Conflitos**: `core_hub.json` (placa `plate_core_01` e as garras da F69 ficam; a vaga 146,14 vira
  entidade e `reserved_exits` guarda só o Reator); `Balance`/GDD-P (upgrades da F69 + `LOGS_TOTAL` 12,
  `RESEARCH_TOTAL` 11, citando AJ-048 · AJ-064); Ajustes em ordem numérica (061–064 entre 060 e 065;
  057/058/059 desembaralhados); `ASSETS` com MUS-SERRALHEIRO e MUS-MEMORY; `tests/scenes.txt` com as
  quatro cenas (108 no smoke); `test_dialogue_manager` 34 sequências / 12 logs / 4 falantes (29 da base
  + 1 da `main` + 4 da F64, conferido pelo teste).
- **Fim das Docas**: os geradores da F63 (`f62_docks.py`, `f63_serralheiro.py`) agora terminam no
  Núcleo, com a luta do Serralheiro inteira; `f66.py` regenerado com os totais 12/11.
- **Root de verdade**: o `f64_memory` continua depois da tela de fim provisória: volta ao Núcleo com o
  estado da run, anda até a comporta do Reator, `[E] ACESSO ROOT` abre (`is_root_door_open` = true) e
  o MU-7 passa (32 marcos). O `f69_c_comporta_reator` ganhou a flag `dlg_core_return_memory`: com a
  Memória religada a fala de volta da Memória prendia o MU-7 parado na rotunda.
- **Sinal da Terra ilegível (bug)**: a onda era um ruído aleatório redesenhado a cada quadro com um
  ponto a cada 2 px; em 384 × 216 os tracinhos em alturas diferentes liam como letras embaralhadas em
  cima do rótulo, e a caixa (y 24) cobria a linha de CARGA/OBJETIVO da HUD. Agora a portadora é uma
  senoide de 1 px de amplitude, o pulso tem 8 ciclos, as linhas são primitivas de 1 px
  (`draw_polyline` com largura −1) e a caixa desceu para y 36–84, entre a HUD e a cabeça do MU-7.
- **QA com marcos (capturas lidas)**: `f64_memory` 32/32, `f64_hub_entrada` 8/8, `f64_morte` 13/13,
  `f64_hub_volta` 10/10, `f62_docks` 41/41 (luta + volta ao Núcleo), `f63_serralheiro` 25/25,
  `f63_serralheiro_morte` 23/23, `f69_c_comporta_reator` 6/6, `f69_b_porta_root_estufa` 8/8,
  `f66_semeadura` 23/23.
- **Portões**: `tools/gates.sh` completo verde — 1143 testes, 108 cenas.
- **Pendências**: MUS-MEMORY; a fase do Reator (F65) troca o fim provisório (`demo_end_until`).

### 2026-11-21 — Integração com o Reator (F65): fim provisório desligado
- **Quem**: agente de integração (branch `final/integracao`) · **O que**: com `reactor_core.tscn` no
  repo, o ADR-F64-005 cumpriu o papel e o gancho saiu: `demo_end_until` não existe mais no
  `SectorNarrative` nem na cena (o `FIM DA DEMO` foi aposentado, ADR-F66-009). A Memória volta ao
  Núcleo sozinha; `f64_memory` (31/31) agora espera `core_hub.tscn` depois da fala de religamento e
  confere o backup na doca da ala (`core_dock_wing`, gravado pelo hub ao entrar), depois sobe à
  comporta do Reator e a abre com o Root. `LOGS_TOTAL` 13 / `RESEARCH_TOTAL` 12 com o Reator.

### 2026-11-21 — Revisão de design: fatos, falas e o painel do sinal (agente de correção C)
- **Fatos**: o log final dizia "Quarenta pessoas saudáveis ficaram presas", mas 40 é a tripulação
  inteira, os leitos 1–11 já estavam ocupados e a SELENE partiu com gente. Linha 5 → *"Selei o lado
  errado. Quem estava saudável ficou preso do lado dos esporos."* ([AJ-076](../design/GDD.md#gdd-ajustes)).
- **Falas**: `mem_restored` 4 → 3 linhas, `core_return_memory` 2 → 1. O sinal da Terra fica.
- **Painel antes da fala** (o painel `SINAL FRACO · DIREÇÃO: TERRA` aparecia duas linhas antes de a
  ÓRBITA falar do sinal): a fala agora **abre** com o sinal (*"Acesso root restaurado. E um sinal:
  fraco, sem padrão. Vem da direção da Terra."*), e o painel, que nasce no fim da cutscene, chega junto
  dela. Sem mudar código: `earth_signal.gd` e o `protocol_luto.gd` ficaram como estavam.
- **QA**: `f64_memory` 32/32 (marco novo `painel_junto_da_fala` confere o texto da fala com o painel
  visível); `f64_hub_volta` 10/10.
### 2026-11-21 — Salão do firewall não linear e roubo visível (agente de correção B2)
- **Por quê** (revisão de design): a fase 2 tinha a forma reprovada "console A → atravessa → console
  B → porta"; o feixe roubava as luzes em (58,6)/(80,6), dentro da faixa da HUD; a passarela ficava a
  12 tiles do console A, na borda da tela; o olho cobria "OBJETIVO"/"INTEGRIDADE" nas três fases; o
  `f64_tour` teleportava para dentro da rocha (96,20) e reprovava 2 marcos.
- **Rota lateral:** galeria sobre a porta do salão — parede magnética x 56 y 6–8 (só com pulo duplo +
  garras), lintel x 57–59 r7, descida x 60–61, pilar x 62 y 3–9. Muda o plano de energia: pela porta
  são `hall_door` + `walkway` + isca; pela galeria basta `walkway` + isca. A isca continua obrigatória
  nos dois consoles. Console A 51 → 54, porta 56 → 58 (sob o lintel), tripulante 58 → 50.
- **Roubo visível:** luzes da festa descem para (52,9) e (84,9); o feixe mira o objeto do cabo **mais
  perto do MU-7** (antes, o primeiro do grupo, que podia estar do outro lado do salão).
- **Olho fora da HUD:** câmera do salão travada na vertical pela fase (bloco `firewall.frame`/`camera`
  no JSON, aplicado por `set_camera_limits` só enquanto a próxima fase é o firewall e o MU-7 está na
  moldura); `LutoEye` nunca sobe acima de 74 px do topo da tela e é desenhado atrás do cenário; na
  fase 2 segue 6 tiles atrás do MU-7, com margem de 112 px na região (não some atrás da parede da
  saída do poço). Olho da fase 3 47 → 48 (não fica atrás da parede do corredor).
- **QA (capturas lidas):** `f64_rota_lateral` 19/19 (duas rodadas), `f64_memory` 36/36 (duas
  rodadas; marcos novos: câmera travada no salão e solta no corredor, olho fora da HUD no poço, no
  salão e no corredor), `f64_tour` 8/8 (teleporte do arquivo agora no poço de queda, 120,20),
  `f64_morte` 13/13, `f64_hub_entrada` 8/8, `f64_hub_volta` 10/10, `review_campaign_05_memoria`
  45/45 (regenerado pelo gerador), `review_campaign_continuar` 71/71. O estado `s05` capturado no
  fim do trecho 05 só difere no `play_time` (0,4 s): não foi recapturado.
- **Armadilha nova:** **olho/chefe flutuante desenhado na frente do cenário vira tampa da HUD ou da
  rota**: no poço o espaço livre entre a HUD (40 px) e a cabeça do MU-7 (92 px) é menor que o sprite
  de 64 px. Prenda o chefe à tela (`lowest_center` a partir do `canvas_transform`), não ao pé do MU-7,
  e desenhe-o atrás do `Solid` (z entre o `Background` −10 e 0). Em sala de chefe horizontal, trave a
  câmera na vertical com a altura exata da tela.
- **Portões:** `tools/gates.sh` completo verde — 1177 testes, 114 cenas.

