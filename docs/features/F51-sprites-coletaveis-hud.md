---
id: F51
title: Arte definitiva — coletáveis, doca de recarga, HUD e drone BOTÂNICO
status: done
scope: demo
block: 6
priority: P1
rubric: ["Sprites", "HUD"]
depends_on: ["F15", "F20", "F13", "F44"]
unblocks: []
estimate: 3h
last_updated: 2026-09-20
---

# F51 — Arte definitiva: coletáveis, doca de recarga, HUD e drone BOTÂNICO

## 1. Contexto e objetivo

Quatro folhas geradas por IA substituem os últimos placeholders de sprite do jogo:
`SPR-PICKUPS`, `SPR-DOCK`, `UI-HUD` e `SPR-BOTANICO`. Com elas, **nenhum asset de
imagem do projeto continua em placeholder**.

O ponto crítico é a **legibilidade dos coletáveis**: o jogador já reclamou de
"coisas azuis no chão e as laranjas" quando os itens eram losangos que só mudavam
de cor. A regra registrada no `ASSETS.md` exige silhueta diferente por tipo, e o
ícone do contador no Terminal do Chassi tem de repetir a silhueta do item — é o
elo entre "coisa no chão" e "número na tela".

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.9 — paleta](../design/GDD.md#gdd-2-9-paleta)
- **ADRs:** [ADR-003](../DECISIONS.md#adr-003) (384×216, nearest), [ADR-005](../DECISIONS.md#adr-005) (placeholder → caminho final)
- **Assets:** `SPR-PICKUPS`, `SPR-DOCK`, `UI-HUD`, `SPR-BOTANICO` no [`ASSETS.md`](../ASSETS.md)
- **Pipeline:** [`ASSET-PIPELINE.md` §4](../ASSET-PIPELINE.md) (fatiamento)

## 3. Critério de avaliação atendido

**Sprites** e **HUD**: a estação deixa de ter arte de rascunho. O avaliador vê
cinco coletáveis distintos, um HUD com células de Integridade, molduras de barra
e ícones de status, e a doca de recarga piscando quando o MU-7 encosta nela.

## 4. Escopo

### Inclui
- Fatiamento das quatro folhas brutas para os contratos do `ASSETS.md`.
- Ligação das duas molduras 9-slice do `UI-HUD` às barras de Carga e do Reator.
- Ícones de contador (Log e Dado) no Terminal do Chassi, repetindo a silhueta do item.
- Cobaia sintética no `tests/test_asset_resolver.gd` (fim do rodízio de assets).

### Não inclui
- Implementação da F34 (drone BOTÂNICO 04). Só a arte entra; a feature segue `stretch`.
- Ícone `[E]` do atlas: continua sem uso, porque o prompt de interação alterna
  entre `[E]` e `[X]` conforme teclado/controle ([`interaction_rules.gd`](../../scripts/core/interaction_rules.gd)).

## 5. Critérios de aceite

- [x] As quatro folhas batem 1:1 com o contrato (4×5 de 16×16 · 5 de 32×48 · 8 colunas de 16×16 · 6 de 16×16).
- [x] Os cinco coletáveis se distinguem **pela forma**, não só pela cor.
- [x] As molduras 9-slice chegam à borda da célula e são esticadas pelo jogo; os ícones não encostam na borda.
- [x] A doca lê como "carregando" (a luz percorre a coluna) e o MU-7 se encaixa nela.
- [x] Portões do `/CLAUDE.md` §6 verdes.
- [x] Sem comentários no código; nada 3D.

## 6. Definição técnica

### Cenas e scripts
```
scenes/ui/hud.tscn + hud.gd              molduras 9-slice nas barras
scenes/ui/chassis_menu.tscn + .gd        ícones dos contadores
scripts/core/hud_model.gd                FRAME_CHARGE = 3, FRAME_REACTOR = 4
tests/qa/scenes/pickup_lineup.tscn/.gd   prova de silhueta + doca nos dois estados
tests/qa/f51_pickups.json                roteiro
```

### Arquivos de arte (caminho final)
```
assets/sprites/pickups/pickups_sheet.png   64×80  (4×5 de 16×16)
assets/sprites/world/dock_sheet.png        160×48 (5 de 32×48)
assets/ui/hud_sheet.png                    128×32 (8×2 de 16×16)
assets/sprites/npc/botanico_sheet.png      96×16  (6 de 16×16)
```

### Índices do atlas `UI-HUD` (`HudModel`)
`0` célula cheia · `1` célula vazia · `2` célula piscando · `3` moldura da Carga ·
`4` moldura do Reator · `5..9` Corrosão, Superaquecimento, Congelamento, Descarga,
Sobrecarga · `10` Log · `11` Dado · `12` tecla `[E]`.

## 7. Assets necessários

| Asset id | Uso nesta feature | Placeholder |
|---|---|---|
| SPR-PICKUPS | os cinco coletáveis | substituído |
| SPR-DOCK | doca de recarga / Ponto de Backup | substituído |
| UI-HUD | células, molduras e ícones do HUD | substituído |
| SPR-BOTANICO | arte do drone (F34 segue não implementada) | substituído |

## 8. 🧑 Ação humana

Nenhuma.

## 9. Plano de execução

- [x] **Passo 1** — conferir cada folha bruta contra o contrato antes de fatiar.
- [x] **Passo 2** — fatiar com chave por flood fill a partir da borda (ver ADR-F51-001).
- [x] **Passo 3** — ligar as molduras 9-slice e os ícones de contador.
- [x] **Passo 4** — trocar a cobaia do `test_asset_resolver`.
- [x] **Passo 5** — portões §6 e QA visual.

## 10. Verificação

- **Testes:** `tests/test_asset_resolver.gd` — cobaia agora é
  `res://assets/sprites/_sem_arte/fixture.png`, um caminho **sintético que nunca vai
  existir**; o espelho do MU-7 cobre o lado "resolve como placeholder". 669 testes verdes.
- **Smoke:** `res://tests/qa/scenes/pickup_lineup.tscn` adicionada em `tests/scenes.txt` (77 cenas).
- **Roteiro godot-qa:**
  - `tests/qa/f51_pickups.json` sobre `pickup_lineup` — os cinco itens lado a lado, duas
    primeiras coletas, a linha sob luz escura e as duas docas (ociosa e carregando).
  - `tests/qa/f15_hud.json` sobre `hud_probe` — HUD completo com molduras.
  - `tests/qa/f44_chassi.json` sobre `chassis_probe` — ícones dos contadores.
  - `tests/qa/f29_greenhouse.json` com `--qa-new-game` — a demo fecha até `FIM DA DEMO`.

## 11. ADRs locais

### ADR-F51-001 — Chave de fundo por flood fill, não por família de cor
- **Contexto:** o fatiador `tools/autoslice_sheet.gd` apaga o fundo por "família magenta"
  (`min(r,b) > 0.35 e g < magenta*0.75`). O Núcleo de Capacitor é roxo/rosa: a regra
  comeu o corpo inteiro do item e sobraram só as tampas cinzas.
- **Decisão:** fatiar estas folhas com flood fill a partir da borda (tolerância 0.45)
  + uma passada que limpa o fundo **cercado** (tolerância 0.25, para o miolo das molduras
  9-slice) + alfa endurecido em 0/255 depois do redimensionamento.
- **Consequências:** 0,0% de pixels semitransparentes nas quatro folhas (as entregas
  anteriores ficaram entre 5,7% e 42,9%); sprites roxos e rosas passam a ser seguros.
  O `tools/autoslice_sheet.gd` **não foi alterado** (fora do escopo deste agente) — a
  melhoria está descrita aqui para quem for mexer nele.
- **Data:** 2026-09-20

### ADR-F51-002 — A moldura 9-slice define a altura da barra
- **Contexto:** a barra de Carga tinha 6 px e a do Reator 5 px. Uma moldura 9-slice de
  16×16 com canto de 3 px não cabe em 6 px de altura.
- **Decisão:** as duas barras passam a ter 10 px de altura, com a `ProgressBar` recuada
  3 px de cada lado e um `NinePatchRect` (`patch_margin` 3, `draw_center = false`) por cima.
- **Consequências:** o bloco do Reator ficou 8 px mais alto (`offset_bottom` 42 → 50).
- **Data:** 2026-09-20

## 12. Log de evolução

### 2026-09-20 — Arte definitiva integrada
- **Quem**: agente SPRITES · **O que**: quatro folhas fatiadas e integradas, molduras
  9-slice ligadas, ícones de contador no Terminal do Chassi, cobaia sintética no teste
  do resolver · **Próximo passo**: rever a silhueta do Núcleo de Capacitor (ver
  "Defeito conhecido" abaixo) se o jogador voltar a confundi-lo com a Célula de Energia.

### Defeito conhecido — silhueta do Capacitor
A Célula de Energia (8×14) e o Núcleo de Capacitor (8×14) têm **o mesmo retângulo
externo**: os dois são cilindros verticais com tampas. Distinguem-se pela textura
interna (miolo azul liso × quatro anéis rosa) e pela cor. Correção de prompt pronta,
caso seja preciso regerar: *"row 5 capacitor core: draw it as a WIDE HORIZONTAL coil
lying on its side, wider than tall, with two side fins — it must not share the tall
vertical canister silhouette of row 1"*.

### Defeito conhecido — névoa do drone
Na folha bruta do drone a névoa do `spray` é tão alta quanto o próprio corpo. Para o
corpo continuar legível em 16×16 (12 px), a cauda da névoa perde ~2 px no fim do quadro.
Correção de prompt pronta: *"draw the water mist as a short puff no taller than one third
of the drone body, entirely inside the 16x16 frame"*.
