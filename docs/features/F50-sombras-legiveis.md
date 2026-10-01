---
id: F50
title: Sombras que dão volume, não sombras que apagam a fase
status: done
scope: demo
block: 6
priority: P0
rubric: ["Luz/Sombra", "Desenvolvimento de fases"]
depends_on: ["F18", "F21", "F41", "F43", "F47"]
unblocks: []
estimate: 3h
last_updated: 2026-09-20
---

# F50 — Sombras que dão volume, não sombras que apagam a fase

## 1. Contexto e objetivo

O humano jogou a Estufa depois da [F47](F47-tilesets-definitivos.md) e disse: *"ficou bem
ruim com o tileset novo: a iluminação ta cagada, tem uma caixa preta ao redor de tudo e nem
da pra ver o tileset em si. parece que tem uma caixa de sombra ao redor, e tudo escuro."*

Ele estava descrevendo, com precisão, **auto-sombreamento**. Desde a
[F18](F18-luz-lanterna.md) o `tools/make_tileset.gd` colava um `OccluderPolygon2D` de 16×16 —
o tile inteiro — em **toda máscara ≠ 15**, ou seja, em todo tile que tem pelo menos uma face
exposta. Como a sombra 2D do Godot nasce na **aresta do oclusor** e se estende para longe da
luz, o tile projetava sombra **sobre si mesmo**: a face que a lâmpada ilumina era exatamente a
face apagada. O tile de parede de fundo (`(1,2)`, sem oclusor) recebia a luz inteira.

Resultado medido no corredor da Estufa, dentro do alcance de 90 px da lâmpada:

| Região | Antes |
|---|---:|
| **Face do bloco sólido** (chão, teto, patamar) | **0,040** |
| **Parede de fundo** atrás dele | **0,136** |
| **Interior da sombra projetada** | **0,035** |

A parede de fundo era **3,4× mais clara que o bloco que estava mais perto da lâmpada** — e a
face do bloco era indistinguível do interior de uma sombra. Daí a leitura do humano: cunhas
pretas de borda dura, silhueta do nível sumindo, tileset invisível.

Com o placeholder chapado da [F41](F41-escuridao.md) o defeito já existia, só não doía: um
quadrado liso apagado continua parecendo um quadrado liso. O atlas definitivo põe o material
(chapa, musgo, grama, rebite) justamente nas faces expostas — e era tudo isso que ia para zero.

Esta feature troca o modelo de oclusão: **um oclusor por silhueta de ilha sólida, que só
projeta pela face oposta à luz**.

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.9 Estilo visual](../design/GDD.md#gdd-2-9-visual) (*a luz não é decoração,
  é informação*) · [GDD-2.9 Paleta por setor](../design/GDD.md#gdd-2-9-paleta)
- **Parâmetros:** `Balance.LAMP_RADIUS` (96), `Balance.LAMP_ENERGY`, `Balance.VISION_RADIUS_*`,
  `Balance.AMBIENT_DARK` ([GDD-P](../design/GDD.md#gdd-p))
- **ADRs:** [ADR-002](../DECISIONS.md#adr-002) (Compatibility) ·
  [ADR-003](../DECISIONS.md#adr-003) (384×216) · [ADR-F18-003](F18-luz-lanterna.md)
  (oclusão só em máscara ≠ 15 — **revogado aqui**) · [ADR-F41-001](F41-escuridao.md#adr-f41-001)
  (tileset claro + ambiente escuro — **mantido**) · [ADR-F47-003](F47-tilesets-definitivos.md)
  (ganho do atlas — **mantido, não foi a causa**)

## 3. Critério de avaliação atendido

- **Luz/Sombra:** a sombra passa a fazer o que sombra faz — marcar o que a luz **não** alcança
  porque alguma coisa está na frente — em vez de apagar a própria coisa que está na frente.
- **Desenvolvimento de fases:** piso, parede e vão voltam a se distinguir na tela. O tileset
  definitivo da F47 finalmente aparece.

**Como o avaliador vê:** o corredor da Estufa deixa de ser uma colagem de polígonos pretos; a
lanterna projeta um cone limpo com sombra atrás de cada coluna.

## 4. Escopo

### Inclui
- `LevelBuilder.build_occluders` / `LevelBuilder.silhouette_loops`: contorno de cada ilha
  sólida traçado a partir da grade ASCII, em `LightOccluder2D` com
  `cull_mode = CULL_COUNTER_CLOCKWISE`.
- `tools/make_tileset.gd`: fim do oclusor por tile e da camada de oclusão do `TileSet`;
  `.tres` dos dois setores regerados.
- `magnetic_wall.tscn` e `secret_wall.tscn`: mesmo `cull_mode` nos oclusores próprios.
- Penumbra: `SHADOW_FILTER_PCF13` + `shadow_filter_smooth = 1.5` na lâmpada e na lanterna.
- `tests/test_light_shadows.gd` travando o modelo novo.
- Sondas `tests/qa/scenes/shadow_probe*` (mesmo ponto com e sem sombra, com e sem lanterna).

### Não inclui
- Mexer em `ambient_color`, energia ou raio de lâmpada — a calibragem da F41 continua valendo
  e foi **confirmada** por medição (§10).
- Mexer no ganho do atlas da F47 — a medição descartou a hipótese "a arte ficou escura demais".
- Oclusor em plataforma fina (`=`), porta, planta e plataforma móvel: continuam sem oclusor,
  como antes.
- Mover `SHADOW_SMOOTH` para o `Balance` (arquivo de outro agente nesta rodada — ver
  [ADR-F50-003](#adr-f50-003)).

## 5. Critérios de aceite

- [x] A face de um bloco sólido dentro do alcance da lâmpada fica **mais clara que a parede de
      fundo atrás dele** (0,040 → 0,370 contra 0,136 → 0,218).
- [x] A escuridão da F41 continua intacta: região longe do MU-7 sem lâmpada em **0,026** na
      Estufa e **0,018** no Núcleo, **0 % dos pixels legíveis** — idênticos ao antes.
- [x] A luz **não atravessa parede**: com a lanterna colada numa coluna de 1 tile, o outro lado
      fica na sombra (captura `L_leak`).
- [x] Sombras continuam existindo onde têm função (cunha atrás de coluna, vão, patamar).
- [x] Travessia completa `tests/qa/f29_greenhouse.json` fecha em **FIM DA DEMO**
      (`TEMPO 01:30 · LOGS 1/4 · DADOS 1/4 · MORTES 0 · SEGREDOS 0/4`).
- [x] Portões do `/CLAUDE.md` §6 verdes (675 testes, 76 cenas de smoke, varreduras vazias).
- [x] Sem comentários no código; nada 3D.

## 6. Definição técnica

### Cenas e scripts
```
scripts/core/level_builder.gd        build_occluders / silhouette_loops (novos)
tools/make_tileset.gd                sem oclusor por tile, sem camada de oclusão
assets/tiles/core_tileset.tres       regerado
assets/tiles/greenhouse_tileset.tres regerado
scenes/world/magnetic_wall.tscn      cull_mode = 2 no oclusor
scenes/world/secret_wall.tscn        cull_mode = 2 no oclusor
scenes/world/powered_lamp.gd/.tscn   PCF13 + shadow_filter_smooth 1.5
scenes/player/mu7.gd/.tscn           PCF13 + shadow_filter_smooth 1.5 na lanterna
tests/test_light_shadows.gd          contrato do modelo novo
tests/qa/scenes/shadow_probe.gd      sonda paramétrica (sombra on/off, cull, tint, suavização)
tests/qa/scenes/shadow_probe_gh_corridor[_noshadow].tscn
tests/qa/scenes/shadow_probe_core_lit[_noshadow].tscn
tests/qa/scenes/shadow_probe_gh_leak.tscn
tests/qa/f50_sombras.json · tests/qa/f50_lanterna.json
```

### Como o contorno é traçado
Para cada célula sólida, cada um dos 4 lados cujo vizinho **não** é sólido vira uma aresta
dirigida com o sólido sempre do mesmo lado (topo →, direita ↓, base ←, esquerda ↑). As arestas
internas — entre dois sólidos — simplesmente não existem, e são elas que causavam o
auto-sombreamento. As arestas são encadeadas fim→início em laços fechados; pontos colineares
são descartados. Contorno externo e furo saem com rotações opostas, que é o que faz o
`cull_mode` funcionar dos dois lados sem caso especial.

Custo: a Estufa (48×64) troca ~1000 oclusores de tile por algumas dezenas de laços.

### Dados (`data/`)
Nenhuma mudança.

### Input actions / camadas de colisão
Nenhuma mudança. Colisão continua sendo por tile (`physics_layer_0`), intocada.

## 7. Assets necessários

Nenhum novo. Os dois atlas da [F47](F47-tilesets-definitivos.md) continuam como estão — a
medição (§10) mostrou que o ganho de brilho deles **não** era o problema.

## 8. 🧑 Ação humana

Nenhuma.

## 9. Plano de execução

- [x] **Passo 1** — Reproduzir o quadro do humano com sonda (`shadow_probe_gh_corridor`).
- [x] **Passo 2** — Isolar a contribuição das sombras (mesma cena com `shadow_enabled = false`).
- [x] **Passo 3** — Medir face do bloco × parede de fundo × interior da sombra.
- [x] **Passo 4** — A/B contra o tileset anterior (`c356ce2`) para descartar a arte.
- [x] **Passo 5** — Testar `cull_mode` no oclusor por tile (não resolve) e no contorno de ilha
      (resolve).
- [x] **Passo 6** — Implementar `silhouette_loops`, tirar o oclusor do tileset, suavizar.
- [x] **Passo 7** — Portões §6, travessia completa, `test_light_shadows.gd`.

## 10. Verificação

### Medição — Estufa, corredor iluminado, MU-7 no tile 16,21, dentro de 90 px da lâmpada

| Região | Antes | Depois |
|---|---:|---:|
| Face do bloco sólido | **0,040** | **0,370** |
| Parede de fundo | 0,136 | 0,218 |
| Interior da sombra projetada | 0,035 | 0,035 (inalterado) |
| Média de todo pixel sólido da tela | 0,045 | 0,098 |
| Pixels sólidos que a sombra apagava | 21,9 % (0,032 no lugar de 0,289) | 0 % |

### A/B contra o tileset anterior (`c356ce2`)

| Atlas | Luma média dos sólidos | Parede de fundo `(1,2)` | Razão sólido/fundo |
|---|---:|---:|---:|
| Placeholder (antes da F47) — Estufa | 0,604 | 0,478 | 1,26 |
| Definitivo (F47) — Estufa | 0,550 | 0,360 | 1,53 |
| Placeholder — Núcleo | 0,638 | 0,478 | 1,33 |
| Definitivo — Núcleo | 0,529 | 0,389 | 1,36 |

O atlas definitivo é ~9 % mais escuro que o placeholder, mas o sólido ficou **relativamente
mais claro** que o fundo, não mais escuro. A hipótese "a F47 desequilibrou sólido × fundo" está
**descartada**: a inversão vista na tela (fundo 3,4× mais claro que o sólido) é produzida pela
sombra, não pela arte. A F47 apenas tornou visível um defeito que existia desde a F18.

### A escuridão da F41 continua valendo

Caixas e limiar da [F41 §10](F41-escuridao.md#10-verificação), mesmas sondas
(`dark_probe_greenhouse`, `dark_probe_core`):

| Situação | Cenário | Longe do MU-7 | Perto do MU-7 |
|---|---:|---:|---:|
| Estufa escura, sem lanterna — antes | 0,063 (15 %) | **0,026 (0 %)** | 0,062 |
| Estufa escura, sem lanterna — **depois** | 0,073 (17 %) | **0,026 (0 %)** | 0,083 |
| Estufa escura, com lanterna — antes | 0,116 (36 %) | 0,038 | 0,106 (31 %) |
| Estufa escura, com lanterna — **depois** | 0,157 (46 %) | 0,100 | **0,347 (76 %)** |
| Núcleo escuro, sem lanterna — antes | 0,033 (3 %) | **0,018 (0 %)** | 0,100 |
| Núcleo escuro, sem lanterna — **depois** | 0,035 (3 %) | **0,018 (0 %)** | 0,115 |
| Núcleo escuro, com lanterna — antes | 0,084 (25 %) | 0,037 | 0,280 (94 %) |
| Núcleo escuro, com lanterna — **depois** | 0,119 (35 %) | 0,042 | **0,326 (99 %)** |

Sem lanterna nada mudou. Com lanterna, o que a lanterna aponta ficou legível — que é o ponto.

### Travessia inteira do Núcleo (`f28_core_hub.json`), caixa "longe do MU-7"

| Captura | Antes | Depois |
|---|---:|---:|
| `09_corredor_sem_lampada` | 0,055 (16 %) | 0,074 (24 %) |
| `16_iluminacao_desligada` | 0,109 (38 %) | 0,140 (50 %) |
| `18_nucleo_no_escuro` | 0,110 (40 %) | 0,149 (53 %) |
| `02_nucleo_aceso` | 0,237 (75 %) | 0,287 (87 %) |

- **Testes (`tests/test_light_shadows.gd`):** o `TileSet` não tem camada de oclusão · um bloco
  isolado vira um laço de 4 cantos · oito blocos vizinhos viram **um** laço de 4 cantos (é o
  teste que prova que a aresta interna sumiu) · uma sala produz contorno externo e furo com
  rotações opostas · o oclusor gerado tem `CULL_COUNTER_CLOCKWISE` · parede magnética e parede
  falsa também.
- **Portões:** import 0 erros · **675 testes, 0 falhas** · smoke 76/76 · varreduras vazias.
- **Roteiros godot-qa** (`--fixed-fps 60`, `--qa-new-game`):
  `tests/qa/f50_sombras.json` (uma foto por sonda) · `tests/qa/f50_lanterna.json` (mesmo ponto
  sem e com lanterna) · `tests/qa/f29_greenhouse.json` completo em
  `res://scenes/levels/greenhouse.tscn` (fecha em FIM DA DEMO) · `tests/qa/f28_core_hub.json`
  completo.

## 11. ADRs locais

<a id="adr-f50-001"></a>
### ADR-F50-001 — Oclusor é por silhueta de ilha, não por tile
- **Contexto:** um `OccluderPolygon2D` de 16×16 por tile faz o tile projetar sombra sobre a
  própria face. Medido: a face do bloco mais próxima da lâmpada ficava em 0,040 enquanto a
  parede de fundo atrás dele ficava em 0,136.
- **Decisão:** o `LevelBuilder` traça o contorno de cada ilha sólida a partir da grade ASCII e
  cria um `LightOccluder2D` por laço. O `TileSet` deixa de ter camada de oclusão.
- **Alternativa recusada:** manter o oclusor por tile e ligar `cull_mode` nele. Foi testado e
  **não resolve**: as arestas internas, entre dois sólidos vizinhos, continuam projetando umas
  sobre as outras. Medido na mesma tela, média de todo pixel sólido: 0,045 sem `cull_mode` ·
  0,045 com `CULL_CLOCKWISE` · 0,053 com `CULL_COUNTER_CLOCKWISE` · **0,098** com o contorno
  de ilha.
- **Consequências:** revoga o [ADR-F18-003](F18-luz-lanterna.md). Editar o `.txt` de uma fase
  continua sendo a única coisa que o humano precisa fazer — o contorno é derivado dele. Bônus:
  a Estufa troca ~1000 oclusores por algumas dezenas.
- **Data:** 2026-09-20

<a id="adr-f50-002"></a>
### ADR-F50-002 — Só a face oposta à luz projeta
- **Contexto:** num jogo 2D de lado, o que o jogador vê de um bloco é a **face** dele, não o
  topo. A luz que bate nessa face tem de acendê-la; a sombra começa **atrás** do bloco.
- **Decisão:** `cull_mode = CULL_COUNTER_CLOCKWISE` nos contornos gerados e nos oclusores
  próprios da parede magnética e da parede falsa. A regra de orientação das arestas
  (sólido sempre do mesmo lado) faz contorno externo e furo rodarem ao contrário, então a
  mesma constante vale para bloco e para sala sem caso especial.
- **Alternativa recusada:** `shadow_color` com um cinza dentro da sombra. Funciona (face do
  bloco 0,032 → 0,191) mas é ambiente **chapado dentro de todo o retângulo da luz**: a luz
  passaria a vazar por baixo da parede para o corredor do outro lado, que é exatamente o que a
  oclusão existe para impedir.
- **Consequências:** parede de 1 tile continua bloqueando a luz (verificado com a lanterna
  colada na coluna do tile 12 da Estufa). Ilhas grossas praticamente não projetam sombra
  interna — o volume vem da queda da luz e da sombra lançada além da silhueta.
- **Data:** 2026-09-20

<a id="adr-f50-003"></a>
### ADR-F50-003 — Penumbra de 1,5 px, com a constante provisória na cena
- **Contexto:** borda de sombra dura em preto puro numa tela de 384×216 recorta a cena em
  polígonos. Com a face do bloco acesa a borda incomoda menos, mas continua dura.
- **Decisão:** `SHADOW_FILTER_PCF13` com `shadow_filter_smooth = 1.5` na lâmpada e na lanterna.
  1,5 px é menos de um tile e some na escala inteira sem borrar o pixel art.
- **Consequências:** `SHADOW_SMOOTH` fica como `const` em `scenes/world/powered_lamp.gd` e
  `scenes/player/mu7.gd`. **Dívida aberta:** mover para `scripts/core/balance.gd` e para a
  tabela [GDD-P](../design/GDD.md#gdd-p), junto com a dívida que a
  [ADR-F41-004](F41-escuridao.md#adr-f41-004) já deixou.
- **Data:** 2026-09-20

## 12. Log de evolução

> Append-only. Mais novo no fim.

### 2026-09-20 — Auto-sombreamento diagnosticado e corrigido
- **Quem**: agente LUZ.
- **O que**: oclusor por silhueta de ilha com `cull_mode`, fim do oclusor por tile, penumbra de
  1,5 px, `tests/test_light_shadows.gd`, sondas `shadow_probe*`.
- **Portões**: import 0 erros · 675 testes, 0 falhas · smoke 76/76 · varreduras vazias · QA
  visual lido pelo agente · travessia `f29_greenhouse` fechando em FIM DA DEMO.
- **Pendências**: `SHADOW_SMOOTH` no `Balance` ([ADR-F50-003](#adr-f50-003)).
- **Próximo passo**: reavaliar se a plataforma fina (`=`) merece um oclusor de meia altura —
  hoje a luz atravessa a grade, o que é coerente com o desenho mas some com a sombra dela.
