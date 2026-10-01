---
id: F49
title: FX definitivos — esporos, fundo de espaço e logo
status: done
scope: demo
block: 6
priority: P1
rubric: ["Paralax", "Telas"]
depends_on: ["F03", "F07", "F23", "F26", "F41"]
unblocks: []
estimate: 3h
last_updated: 2026-09-20
---

# F49 — FX definitivos: esporos, fundo de espaço e logo

## 1. Contexto e objetivo

Três assets saíram do estado *placeholder* e entraram no caminho final ([ADR-005](../DECISIONS.md#adr-005)):

- **[SPR-SPORE](../ASSETS.md#spr-spore)** — a partícula do enxame da Estufa ([F23](F23-esporos-status.md)) e das motas de ambiente, montada a partir do **Kenney Particle Pack (CC0)**;
- **[BG-SPACE](../ASSETS.md#bg-space)** — as três camadas do parallax ([F26](F26-parallax.md)), recortadas de uma única imagem entregue com as bandas empilhadas;
- **[UI-LOGO](../ASSETS.md#ui-logo)** — o logo ÓRBITA da splash ([F03](F03-boot-splash.md)) e do menu ([F07](F07-menu-principal.md)).

Nenhuma cena de gameplay mudou de comportamento: a troca é de textura, mais três ajustes que o tamanho novo das camadas exigiu.

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.9 estilo visual](../design/GDD.md#gdd-2-9-visual) · [GDD-2.8 telas](../design/GDD.md#gdd-2-8-telas)
- **Jornada:** [Contexto](../design/JORNADA-DO-HEROI.md#jh-contexto) — o planeta-alvo é o destino da missão e fica visível o tempo todo
- **ADRs:** [ADR-003](../DECISIONS.md#adr-003) (384×216, nearest) · [ADR-005](../DECISIONS.md#adr-005) (placeholder → final) · [ADR-F26-003](F26-parallax.md#adr-f26-003) (as duas flags de `follow_viewport`)

## 3. Critério de avaliação atendido

**Paralax** e **Telas**: o menu abre com o planeta-alvo, a nebulosa e a estrutura da estação deslizando em três velocidades atrás do logo definitivo; dentro das fases o mesmo céu aparece pelas vigias.

## 4. Escopo

### Inclui
- `assets/backgrounds/space_far.png`, `space_mid.png`, `space_near.png` — **1152×216** cada.
- `assets/ui/logo.png` — 192×48, fundo transparente.
- `assets/sprites/fx/spore.png` — 32×8 (4 frames de 8×8).
- `scenes/world/space_parallax.gd` — `repeat_size` passa a vir do tamanho da textura.
- `scenes/world/ambient_motes.gd` — usa o **frame 3** da tira (mota pálida), não o esporo.
- `tests/test_parallax_seam.gd` + `tests/qa/scenes/parallax_seam.tscn` — guarda de regressão da emenda.

### Não inclui
- `assets/fx/light_radial.png` / `light_cone.png` — gerados e **calibrados** com `Balance.VISION_RADIUS_ON` ([F18](F18-luz-lanterna.md)); não foram tocados.
- Texturas nas partículas de `scenes/fx/` (poeira, faísca, pulso) — ver seção 11, ADR-F49-004.
- Qualquer alteração em `Balance` ou no `docs/ASSETS.md` (pedidos no relatório).

## 5. Critérios de aceite

- [x] O logo aparece na splash e no menu com o acento do **Ó** legível em 384×216.
- [x] As três camadas do espaço aparecem no menu em velocidades diferentes e sem emenda.
- [x] O planeta-alvo é visível no menu **desde o primeiro frame** e passa pelas vigias das fases.
- [x] O enxame de esporos lê como matéria orgânica verde-amarelada, distinta das motas de ambiente.
- [x] `--import` · `run_tests.gd` (652 passes) · `tools/smoke.sh` (76 cenas) · varreduras §6 limpas.

## 6. Definição técnica

### Recorte do BG-SPACE

A entrega veio como **uma imagem 1672×941** com as três bandas empilhadas e separadas por faixas brancas. Os limites foram detectados por conteúdo (média por linha + detecção das linhas de franja), não por divisão em terços:

| Camada | Linhas na origem | Altura | Conteúdo |
|---|---|---|---|
| `far` | 6–307 | 302 | campo de estrelas em azul quase preto |
| `mid` | 321–619 | 299 | nebulosa teal/roxa + **planeta habitável e lua** |
| `near` | 632–935 | 304 | treliças e detritos sobre magenta |

Colunas úteis: **6–1665** (as colunas 4/5 e 1666/1667 são franja da faixa branca). Cada banda foi reescalada por média de área para **1152×216** — três larguras de tela exatas, o que dá variedade antes de repetir e mantém `repeat_size` redondo.

### Tratamento por camada
- **`far`** — opaca (é o fundo). *Wrap-fade* de 64 px para fechar a emenda.
- **`mid`** — alfa derivado da luminância (rampa 10→40) para o campo de estrelas da `far` aparecer pelos vazios; **o disco do planeta e a lua são protegidos** com alfa 1. *Wrap-fade* de 64 px e **roll horizontal de 405 px**, que traz o planeta para dentro do primeiro trecho visível (ver ADR-F49-002).
- **`near`** — magenta removido pela métrica `(r+b)/2 − g` com *unmix* do fundo (ver ADR-F49-003). Sem *wrap-fade*: a emenda da arte já casa e um fade fantasmaria as silhuetas.

### Cenas e scripts
```
scenes/world/space_parallax.gd   _mount() aplica a textura E copia o tamanho dela para repeat_size
scenes/world/space_parallax.tscn repeat_size = (1152, 216) · repeat_times = 3
scenes/world/ambient_motes.gd    FRAME_COLUMN = 3 (mota pálida da tira SPR-SPORE)
```

### Dados (`data/`)
Nenhum arquivo novo. `core_hub.json` e `greenhouse.json` já traziam `"parallax": true`.

## 7. Assets necessários

| Asset id | Arquivo final | Origem |
|---|---|---|
| [BG-SPACE](../ASSETS.md#bg-space) | `assets/backgrounds/space_{far,mid,near}.png` (1152×216) | entrega do humano (`bg space.png`, 1672×941) |
| [UI-LOGO](../ASSETS.md#ui-logo) | `assets/ui/logo.png` (192×48) | entrega do humano (`logo.png`, 2508×627) |
| [SPR-SPORE](../ASSETS.md#spr-spore) | `assets/sprites/fx/spore.png` (32×8) | **Kenney Particle Pack 1.1 (CC0)** — `dirt_02`, `dirt_01`, `smoke_01`, `circle_05` |

## 8. 🧑 Ação humana

Nenhuma.

## 9. Plano de execução

- [x] **Passo 1** — Detectar as bandas do `bg space.png` por conteúdo e confirmar a emenda horizontal na origem.
- [x] **Passo 2** — Gerar as três camadas em 1152×216 com o tratamento de alfa de cada uma.
- [x] **Passo 3** — Recortar, chavear e encaixar o logo em 192×48.
- [x] **Passo 4** — Escolher as partículas do pacote Kenney e montar a tira 32×8.
- [x] **Passo 5** — `repeat_size` vindo da textura; `AmbientMotes` no frame 3.
- [x] **Passo 6** — Teste de emenda + cena de QA com câmera em estações.
- [x] **Passo 7** — Portões e QA visual.

## 10. Verificação

- **Testes:** `tests/test_parallax_seam.gd` — contrato 1152×216 das três camadas; emenda de `far`/`mid` dentro de 2,5× a diferença típica entre colunas vizinhas; só a `far` é opaca, a `mid` deixa passar >5% e a `near` >40%.
- **Smoke:** `res://tests/qa/scenes/parallax_seam.tscn` entrou em `tests/scenes.txt`.
- **Roteiros de QA** (`--fixed-fps 60`):

  | Roteiro | Cena | Mostrou |
  |---|---|---|
  | `f49_logo.json` | `scenes/boot/splash.tscn` | logo na splash com o **Ó** acentuado; menu com o planeta à direita, nebulosa à esquerda e treliças à frente; 4 s depois as três camadas deslocadas em velocidades diferentes |
  | `f49_emenda.json` | `tests/qa/scenes/parallax_seam.tscn` | três estações de câmera separadas por exatamente uma tela da camada `near` (cobrindo o período de 1152 px): nenhuma costura vertical |
  | `f49_corredor.json` | `scenes/dev/parallax_test.tscn` | o espaço pelas vigias: no início estrutura e nebulosa, depois de andar o **limbo do planeta** aparece pelas escotilhas |
  | `f49_vigia.json` | `scenes/levels/core_hub.tscn` | a vigia 2×2 do nascimento mostra a estrutura da estação (região escura da tira — a fase inteira anda só 138 px na camada `mid`) |
  | `f49_esporos.json` | `tests/qa/scenes/spore_sandbox.tscn` | enxame de grumos verde-amarelados; entrar nele aplica **CORROSÃO** e tira integridade |
  | `f49_estufa.json` | `scenes/levels/greenhouse.tscn` | motas de ambiente como pontinhos pálidos esverdeados, distintas dos grumos do enxame |

## 11. ADRs locais

### ADR-F49-001 — Camadas de 1152×216 em vez de 384×216

- **Contexto:** o contrato do [BG-SPACE](../ASSETS.md#bg-space) pede 384×216, mas a entrega tem proporção ~5,5:1 por banda. Reduzir para 384 de largura jogaria fora quase dois terços do desenho e faria o fundo repetir a cada tela.
- **Decisão:** cada camada vira **1152×216** = três larguras de tela. `space_parallax.gd` lê `texture.get_size()` e escreve em `repeat_size`, então o `.tscn` e a textura nunca podem discordar.
- **Consequências:** o contrato do `ASSETS.md` precisa ser atualizado (pedido no relatório). Se as camadas voltarem ao placeholder de 384 px, o `repeat_size` acompanha sozinho.
- **Data:** 2026-09-20

### ADR-F49-002 — O planeta é reposicionado na tira, não redesenhado

- **Contexto:** no recorte original o planeta cai em x ≈ 700 da tira. A camada `mid` tem `scroll_scale.x = 0,18` e o Núcleo Central tem 768 px de largura, então a fase inteira revela só x ∈ [34, 488] — **o planeta nunca apareceria em jogo**, e no menu levaria ~105 s de `autoscroll` para entrar em cena. A Jornada diz o contrário: o destino fica visível o tempo todo.
- **Decisão:** rolar a tira `mid` 405 px na horizontal. Como a camada já fecha em ciclo depois do *wrap-fade*, rolar não cria emenda nenhuma — só escolhe onde o ciclo começa. O planeta passa a nascer em x ≈ 300, dentro da primeira tela.
- **Consequências:** o planeta abre o menu e cruza as vigias do Núcleo. Se o `scroll_scale` da `mid` mudar, o enquadramento muda junto — o número de roll é o ponto único de ajuste.
- **Data:** 2026-09-20

### ADR-F49-003 — Chave de magenta por `(r+b)/2 − g`, não por distância de cor

- **Contexto:** a primeira tentativa de remover o fundo magenta da camada `near` usou distância euclidiana até `#F604FC`. Pixels meio-a-meio entre magenta e treliça ficam longe o bastante do magenta para receber alfa 1 — e **saem com contorno rosa**, visível em cada cano e cada cabo.
- **Decisão:** medir "magentice" como `(r + b)/2 − g`, que vale ~245 no fundo e ~0 numa silhueta cinza-azulada seja ela clara ou escura, e daí tirar o alfa e desfazer a mistura (`F = (C − K·(1−a))/a`).
- **Consequências:** sem franja rosa. Detalhes cor-de-rosa da própria arte viram buracos semitransparentes — são poucos pixels e leem como janelas iluminadas. A mesma função serviu para o logo, com um piso de 0,20 por causa do ruído de compressão nos cantos da imagem entregue.
- **Data:** 2026-09-20

### ADR-F49-004 — O resto do pacote Kenney fica proposto, não aplicado

- **Contexto:** as partículas de `scenes/fx/` (poeira ao aterrissar, faísca ao coletar, pulso de religamento) são `CPUParticles2D` **sem textura** — quadrados lisos. O pacote tem candidatos óbvios.
- **Decisão:** não aplicar. Essas cenas pertencem a outro agente nesta rodada; a troca é de uma linha (`texture = ...`) e está descrita no relatório para quem as edita.
- **Consequências:** o jogo continua com quadrados nesses três efeitos. Nada quebra.
- **Data:** 2026-09-20

## 12. Log de evolução

### 2026-09-20 — Assets definitivos integrados

- **Quem**: agente de FX · **O que**: BG-SPACE recortado em três camadas de 1152×216 com alfa por camada, UI-LOGO em 192×48 e SPR-SPORE montado do Kenney Particle Pack; `space_parallax.gd` passou a derivar `repeat_size` da textura e `AmbientMotes` migrou para o frame pálido da tira; novo `test_parallax_seam.gd` e cena de QA `parallax_seam`. · **Achado**: com `scroll_scale.x = 0,18` e fases de 768 px, o planeta só entra em cena se estiver no primeiro terço da tira (ADR-F49-002); e a chave de magenta por distância de cor deixa franja rosa (ADR-F49-003). · **Próximo passo**: atualizar as fichas do `ASSETS.md` (contrato de 1152×216 e crédito Kenney) e decidir as texturas das partículas de `scenes/fx/`.
