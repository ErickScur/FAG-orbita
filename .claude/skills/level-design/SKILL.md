---
name: level-design
description: Desenha e constrói uma fase do ÓRBITA — Laboratório (F60), Enfermaria (F61), Docas (F62), Núcleo de Memória (F64), Núcleo do Reator (F65), arenas de chefe — ou reformula uma existente. Cobre o puzzle de energia no papel, o mapa ASCII, os JSONs de fase e de terminal, luz, rotas, segredos, a checagem de alcançabilidade e o roteiro de QA com marcos. Use em "faça a fase X", "a fase está fácil/curta/confusa", ou antes de qualquer edição em data/levels/ ou data/energy/.
---

# level-design — Fase nova sem retrabalho

Por que esta skill existe: na demo, **12 rodadas de retrabalho** vieram do playtest humano, não
de bug — e quase todas diziam a mesma coisa: informação demais, desafio de menos. Além disso, a
F43 achou quatro armadilhas de geometria que **não aparecem em log nenhum**. Esta skill põe as
duas coisas antes do primeiro tile.

## 1. Regras de design (aprendidas no playtest — valem para toda fase fora do tutorial)

| Regra | Origem (fala do humano) |
|---|---|
| **Só o Núcleo Central explica.** Fora dele o terminal mostra título, objetivo e orçamento — sem etiqueta por sistema, sem "AO LIGAR", sem "EXIGE DESLIGAR". O JSON de energia **não** leva `"verbose": true`. | F40: *"é um jogo de puzzle, o jogador só vai saber o objetivo e tem que se virar"* |
| **ÓRBITA fala só em marco**: entrada da fase, descoberta-chave (upgrade), religamento. Nada de comentário ambiente, dica ou `bark` repetido. | F38/F39: *"muito diálogo e pouca gameplay"* |
| **História em poucos fragmentos grandes e difíceis de achar** (logs/dados atrás de parkour, segredo ou escolha de energia cara). | F38: *"menos fragmentos, com mais conteúdo, mais difíceis"* |
| **Fase grande e não linear.** Proibido o formato "liga, sobe, abre a porta e já era". | F43: *"fases maiores, mapas maiores, parkour"* |
| **Toda escolha de energia muda algo visível de onde o jogador está.** Porta que abre para o vazio é defeito. | F28: *"se eu abro a porta não tem nada à frente"* |
| **Escuro é escuro**: `ambient_color` escuro de verdade; a lanterna é necessária. Quem garante legibilidade é o tileset de brilho médio, não o ambiente. | F41: *"não precisa da lanterna"* |
| **Cada interativo tem silhueta própria** (porta do chão ao teto ≠ doca ≠ terminal). Nada de dois objetos com o mesmo vocabulário visual lado a lado. | F54: *"a doca está muito igual à porta"* |
| **HUD não cresce.** Fase nova não põe elemento permanente na tela; informação extra vai para o Terminal do Chassi (F44). | F37/F44: *"muita informação na HUD"* |
| **Checkpoint na entrada é automático** (F53) e há doca antes de cada trecho difícil. | F53: *"tem que dar uns passos para trás para salvar"* |
| **Habilidade nova se ensina com uma sala segura** em que só ela resolve, sem dano, com no máximo um cartão de tecla curto na primeira vez (como as garras na Estufa). | F36 |
| **Religar o Nó termina em cutscene** (F42): o caminho de volta tem lâmpadas, portas e plantas que reagem à energia. Se a fase nova não tem nada energizável no caminho, a cutscene fica vazia. | F42 |

Curva de dificuldade ([GDD-2.7-curva](../../../docs/design/GDD.md#gdd-2-7-curva)): suba **um** eixo por vez — densidade de inimigos, clima com dano, ou complexidade do puzzle (3 sistemas/1 energia no tutorial até 6/3 com dependência em cadeia nas Docas). A Estufa é 3/10 e mesmo assim ficou fácil demais na primeira versão: **calibre para cima**.

## 2. Geometria (fonte: `Balance` + lições da F43)

| Restrição | Valor | Consequência no ASCII |
|---|---|---|
| Altura do pulo (`JUMP_HEIGHT`) | 40 px | degrau de **2 tiles** sobe; 3 tiles não |
| Vão horizontal no mesmo nível | ~62 px (110 px/s × 0,57 s) | vão de até **3 tiles**; 4 só com ajuda |
| Topo colidível da `GrowPlant` | 64 px acima do pé | precisa de **patamar de embarque a 2 tiles do topo**; não se escala do chão |
| Corpo do MU-7 × alcance das garras | 14 px × 10 px | chaminé de escalada com **2 tiles de largura** |
| Plataformas finas empilhadas | — | pelo menos **2 colunas de sobreposição** horizontal |
| Descer de plataforma fina | só ↓ (GDD-2.4) | não exija ↓+pulo |

A autoridade é o teste `tests/test_level_reachability.gd` (lógica em `scripts/core/level_reachability.gd`), que simula a física do `mu7.gd` quadro a quadro a partir do spawn e reprova coletável, terminal, log, doca, saída ou Nó inalcançável, com o motivo provável. Toda fase em `data/levels/*.txt` entra sozinha no teste (só a sandbox `test_room` está isenta). As regras 1 e 2 saem da física; a 3 é regra de design (ADR-F43-002), porque fisicamente 1 coluna de sobreposição até passa num pulo reto, mas é injusta para o jogador.

Para **ver** o mapa marcado (`_` onde o MU-7 fica de pé, `.` onde o corpo passa):
`perl -e 'alarm 200; exec @ARGV' "$GODOT" --headless --path . -s res://tools/level_reach.gd -- --level=<fase>`

O modelo é generoso com energia (toda porta aberta, toda planta crescida, garras sempre ativas, plataforma móvel em qualquer ponto do trilho) e ignora inimigos, perigos e a ordem do puzzle — ele prova que **a geometria** não trava, não que o puzzle tem solução. A ordem do puzzle se prova no papel (§4.2) e no roteiro de QA.

## 3. Luz e sombra
- **No máximo 12 luzes por janela de 256 px** (`tests/test_light_crowding.gd`). No renderer Compatibility, da 17ª luz por item em diante ela é descartada **em silêncio**, e a primeira a sumir costuma ser a lanterna. Brilho repetido por tile (parede magnética, faixas) é **fundido por trecho**.
- Oclusão é o **contorno da ilha sólida** com `cull_mode`, nunca um `OccluderPolygon2D` por tile (o bloco faz sombra na própria face, F50).
- Fundo de parallax: confira onde o assunto da arte cai **depois** de aplicar `scroll_scale` à largura da fase (F49).

## 4. Fluxo

1. **Ler**: a feature (ou crie-a com `plan-feature`), [GDD-2.7](../../../docs/design/GDD.md#gdd-2-7) da fase, o inimigo e o status novos (GDD-2.6.2), a etapa da Jornada, e a Estufa como referência viva (`data/levels/greenhouse.{txt,json}`, `data/energy/greenhouse.json`, `docs/features/F43-estufa-viva.md`).
2. **Puzzle no papel, antes do mapa.** Escreva na seção 4 da feature:
   - tabela de sistemas (id, custo, efeito ligado, efeito desligado, onde o efeito é visível);
   - a **sequência de estados de energia** que resolve a fase (quantas trocas o jogador faz);
   - **por que a solução ingênua falha** (se ligar tudo o que parece óbvio resolve, não é puzzle);
   - onde estão os fragmentos difíceis e o segredo.
3. **ASCII + JSON.** Legenda em `scripts/core/level_builder.gd` (`LEGEND`); esquema de fase da F21/ADR-012 (`terminals`, `entities`, `triggers` com `once`); esquema de energia da F17 (`budget`, `goal_text`, `goal_systems`, `initial`, `systems[]` com `cost`/`requires`/`locked`/`effects`). Entidades com parâmetro usam id no JSON, nunca número mágico no `.gd`.
4. **Alcançabilidade**: `tools/gates.sh --skip-smoke` (roda os testes, inclusive o de alcançabilidade) até verde. Se existir `tools/level_reach.gd`, use-o para ver o mapa marcado.
5. **Portões completos**: `tools/gates.sh`.
6. **Roteiro de QA com marcos** (skill `godot-qa`, modelo `tests/qa/f29_greenhouse.json`): carrega a própria cena no frame 1, `expect_tile` em repouso depois de cada trecho, `expect_scene` no fim. Rode com `tools/qa.sh` e **leia** as capturas.
7. **Checklist antes de chamar o humano para jogar** (todos "sim"):
   - [ ] Fora do tutorial, nenhum texto explica a solução?
   - [ ] ÓRBITA fala no máximo nos marcos?
   - [ ] Existem pelo menos duas trocas de energia obrigatórias e a solução ingênua falha?
   - [ ] Há rota opcional difícil com recompensa (dado/log) e um segredo?
   - [ ] Escuro de verdade em pelo menos um trecho que exige a lanterna?
   - [ ] Cada interativo é distinguível pela silhueta numa captura sem HUD?
   - [ ] A HUD tem os mesmos elementos que tinha antes da fase?
   - [ ] O roteiro de QA chega ao fim com todos os marcos OK?
   - [ ] A cutscene de religamento tem o que mostrar?
8. **Docs**: `/update-feature-docs`; armadilha nova vai para a §5 abaixo.

## 5. Armadilhas conhecidas
- **(F43)** Planta sem patamar de embarque, chaminé de 1 tile e plataforma fina com 1 coluna de sobreposição travam o jogador **sem erro no log** (detalhes na §2).
- **(F54)** Raycast contra `TileMapLayer` falha na primeira física depois do `_ready()`: espere **2 quadros de física** antes de medir o mundo (porta nasceu enfiada na parede).
- **(F47)** Coordenada crua de atlas (`LevelBuilder.ONE_WAY_TILE`, `MagneticWall.TILE_COLUMN/ROW`, `SecretWall.tile_column/row`) é contrato com a arte; tileset novo passa por `tests/test_level_tileset.gd`.
- **(F22)** Sonda de borda de inimigo usa a **mesma máscara de colisão do corpo**, senão o inimigo anda para fora de plataforma fina e cai da fase.
- **(F36)** Mexeu no mapa → os roteiros de QA da fase ficaram falsos. Refaça os marcos.
- **(F60)** Troca forçada de energia some se houver console **depois** da comporta que precisa
  ficar ligada: o jogador a desliga pelas costas. Último console antes dela (ADR-F60-001),
  provado por flood fill em `tests/test_level_lab.gd`.
- **(F60)** Luz fria dentro de zona quente grande some na imagem (o laranja aditivo apaga o azul
  claro): a ilha fria lia como lâmpada branca até a cor ir para `#4aa8ff` com energia 1,2.
  Confira contraste de zona dentro de zona na captura.
- **(F60)** Parede magnética na saída de uma prateleira agarra o MU-7 quando ele só anda para
  fora: use escada de plataforma fina onde a garra não é a intenção.
- **(F31)** **Vão "maior que 3 tiles" não obriga o dash**: coyote time (0,12 s) saindo da borda
  alcança ~87 px. Para obrigar o dash, ponha **teto baixo (2 tiles) sobre o vão** ou vão de 6+ tiles;
  prove com `dash_enabled=false` no modelo de alcançabilidade (`tests/test_level_core_hub.gd`).
- **(F31)** **Cartão de tecla cobre obstáculo rente ao piso** quando a câmera encosta no limite de
  baixo do mapa (o piso cai sempre na faixa de 140–176 px da tela, a do cartão). Obstáculo de
  tutorial fica pelo menos 1 tile acima do piso do corredor ou longe do centro da tela.
- **(F61)** **Cutscene de religamento fraca** quando o caminho do Nó ao nascimento quase não tem
  lâmpada ou aquecedor sem energia: na Enfermaria ela mostra a sala clareando e pouca coisa
  acendendo. Ponha lâmpadas ligadas a sistemas (ou desligadas no fim do puzzle) ao longo dessa rota.
- **(F61)** **O Terminal do Chassi cresce uma linha a cada 2 habilidades**: a 5ª estourou os 216 px
  e Mapa/Setores viraram uma linha só; a 7ª estoura de novo. `test_the_open_menu_fits_the_screen_with_every_ability`
  pega isso **se** a habilidade nova entrar em `ALL_ABILITIES`.
- **(F60)** Elevador que nasce estacionado no destino e **desce** quando ligado dá consequência
  visível no console e é a única forma de embarcar: bom padrão para "ligar mostra algo".
- **(F45)** **As 2 colunas de sobreposição valem também do piso para a primeira plataforma fina**:
  a escada da rotunda do hub começava 2 tiles acima e 1 coluna depois do fim do corredor, e o
  Reator ficou inalcançável (só o `test_each_sealed_door_really_guards_its_exit` pegou). Rode
  `tools/level_reach.gd --level=<fase>` e confira o `_` em cima de cada plataforma.
- **(F45)** **Saída de fase que fica aberta para sempre é portal de interação**, nunca de contato: no
  corredor da ala, andar até o Laboratório disparava a Estufa. Quem volta aparece na saída cujo
  `target` é a fase de origem (`ArrivalRoute`); fase nova liga ao hub pela tabela da F45 §6.4, e
  `test_reserved_exits_wait_for_their_scenes` reprova cena nova com a vaga ainda reservada.
- **(F62)** **Zona de vácuo encostada num salto obrigatório** deixa o MU-7 entrar no ar e flutuar à
  deriva até a próxima parede: comece o vácuo pelo menos 2 colunas depois do pouso do último pulo
  e faça a entrada andando pelo piso.
- **(F62)** Vácuo + rota longa somam muito dano (4/s): ponha doca no caminho de cada travessia e
  conte o tempo no vácuo do roteiro de QA; o primeiro roteiro morreu no vestíbulo sem nenhum inimigo.
- **(F62)** Dois jatos de vapor num duto de 3 tiles matam: sem altura para esperar fora do jato,
  só o dash passa, e a Carga do dash concorre com o pulo duplo e o Propulsor.
- **(F69)** **Porta ocupa só a célula do pé no ASCII**, mas o corpo tem 3 tiles e uma antepara
  até o teto: fechar só a célula do `|` no modelo deixou o MU-7 "passar por cima" da porta ROOT do
  Laboratório. O modelo de alcançabilidade fecha a coluna inteira (`_close_gate`); porta nova com
  teto alto confira com `tools/level_reach.gd`.
- **(revisão da campanha)** **Interativo colado numa porta ROOT disputa o `[E]`**: o log na coluna
  39 do Laboratório roubava o `[E]` da comporta (37) com o MU-7 barrado na 38, e a placa 4/4 ficou
  impossível. O painel ROOT abrível tem `PRIORITY_GATE` e `tests/test_root_door_priority.gd` monta
  cada porta ROOT de toda fase com o que estiver a 4 tiles e prova que ela vence; fase nova com
  porta ROOT já entra nesse teste.
- **(F69)** **Letra de legenda é de uma entidade só**: F62 e F69 pegaram o `A` em paralelo e o
  dicionário `LEGEND` ficou com a chave duas vezes, sem erro (o acoplador venceu). Hoje
  `test_no_legend_letter_is_declared_twice` lê o código e reprova; em fase nova, confira a
  `LEGEND` inteira antes de escolher letra.
- **(F63, revisão B1)** **Arena quase da altura da tela deixa o chefe do teto sob a HUD**: com o
  limite de baixo no piso, o topo da tela cai no trilho e o carro fica nos 40 px dos rótulos. Enquadre
  pela altura do pé (limite de baixo mais alto enquanto o MU-7 está no piso principal, `ArenaFraming`,
  `framing_floor` no JSON) e, se houver fosso, raso o bastante para o quadro alto ainda mostrar o que
  há nele; no acordar, câmera temporária no chefe (`BossFocusCamera`). Prova: `test_boss_framing.gd`.
- **(F63)** **Arena de chefe mais alta que a tela esconde o chefe**: com o MU-7 no chão a câmera
  mostra só ~124 px acima do pé; na antessala de 15 linhas o trilho do teto ficava fora do quadro e
  o braço sumia. Baixe o teto (foi para 13 linhas), limite a câmera pelo piso enquanto o MU-7 está
  na arena (`set_camera_limits`) e estacione o chefe **dentro da tela da entrada**, senão o
  "acordar" acontece fora do quadro.
- **(F63)** Vão de 1 tile entre plataforma fina e bloco sólido no mesmo nível derruba o MU-7 que só
  anda (corpo 14 px < vão 16 px): emende o degrau no bloco.
- **(F63)** **Doca de renascimento no piso de uma patrulha** vira castigo em loop: a `dk_dock_05`
  dividia o fosso do vestíbulo com uma SR-3 e cada tentativa contra o Serralheiro começava com dano.
  Doca fica em piso que nenhuma `S` alcança andando (`test_no_dock_shares_a_floor_with_a_patrol`,
  em `tests/test_level_lock.gd`, por enquanto só nas Docas).
- **(F64)** **Perigo que persegue por baixo precisa caber nos ~92 px que a câmera mostra abaixo do
  pé** (offset −16): a estática da fuga vertical nascia 176 px abaixo e o jogador fugia de algo que
  nunca via. `MEMORY_ASCENT_LEAD` foi para 88; confira na captura que a frente aparece na tela.
- **(F64)** **Texto liberado por distância só lê se o espaçamento casar com o andar**: (velocidade de
  andar − empuxo) × tempo de digitação da linha ≥ distância entre gatilhos; senão o log termina com o
  MU-7 já parado no fim do corredor (foi preciso corredor 53 → 76 tiles e empuxo 55 → 75 px/s).
- **(F65)** **O modelo de alcançabilidade conta o fundo do mapa como chão**: um fosso de 3 tiles
  aberto para fora do mapa (letal no jogo) virou chão no modelo, e o pulo duplo saía dele para o
  outro lado do vão "só com dash". Fosso que prova habilidade precisa de fundo fora do alcance do
  pulo duplo (7 tiles no Reator) ou chão de verdade.
- **(F65)** **O modelo não dá pulo duplo saindo de plataforma móvel**, e **arena aberta é toda
  alcançável caindo de cima**: provar "só com Propulsor" dentro de uma arena não funciona; prove a
  habilidade num gargalo antes dela (o bloco de 4 tiles da aproximação) e use paredes, não
  plataformas, para separar trechos.
- **(F65)** **O Feixe é horizontal a −8 px do pé**: torre de teto pendurada 3 tiles acima do piso
  não é atingível. Ponha a torre de parede na altura do peito de onde o jogador para, ou o corpo
  do Feixe ao alcance do ápice de um pulo, e confira no roteiro de QA.
- **(F65)** **Sistema `locked` nunca liga**, nem no `initial` (`EnergyGrid.set_state` pula o que
  `can_power` recusa): "ligado e travado" não existe. O que o terminal não pode desligar fica fora
  dele (`system_id: ""`), comandado pela própria cena.
- Chefe flutuante desenhado na frente do cenário cobre a HUD ou a rota: no poço da Memória o espaço entre a faixa da HUD (40 px) e a cabeça do MU-7 (92 px) é menor que o sprite de 64 px → ancore o chefe na tela (canvas transform), desenhe-o atrás do `Solid` (z entre −10 e 0) e, em salão horizontal de chefe, trave a câmera vertical em exatamente uma tela (F64).
