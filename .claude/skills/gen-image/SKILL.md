---
name: gen-image
description: Gera arte do ÓRBITA direto pela geração de imagem do Codex CLI (tools/gen_image.sh), sem o humano copiar prompt para o Gemini — sprite sheet, prop, tileset, retrato, fundo, logo. Cobre o prompt, as variações, a referência de estilo, a escolha, o fatiamento até o contrato e a pré-visualização em escala de jogo. Use quando uma ficha do ASSETS.md tiver prompt de IA e status pendente/placeholder, quando o usuário pedir "gera a arte de X", ou ao planejar uma fase nova (a arte já sai junto do plano).
---

# gen-image — Arte gerada pelo próprio agente

Testado em 2026-10-27 com `codex-cli 0.164.0`: folha 4×2 da CX-2 em 58 s e prop 1:2 em ~38 s
por variação, as duas com fundo magenta chapado e o estilo do MU-7 vindo da referência. A
folha da CX-2 passou pelo `autoslice_sheet.gd` com a contagem exata do contrato e ficou legível a
32 px. O humano não precisa mais copiar prompt nem baixar arquivo; ele só aprova o resultado no jogo.

Fallback: se `codex` não estiver no PATH ou a geração falhar duas vezes, volte ao fluxo antigo
da skill `asset-request` §B (prompt entregue ao humano para o Gemini).

## 1. Prompt
- Parta do prompt da ficha do `docs/ASSETS.md` (template do ASSET-PIPELINE §3). Se a ficha não
  tem prompt, escreva-o pela `asset-request` §A antes — **a ficha é o registro**, não o chat.
- Salve o prompt num `.txt` no scratchpad. Só o prompt de arte: o `gen_image.sh` acrescenta
  sozinho "use a ferramenta de imagem, não rode comandos, devolva o caminho".
- **Proporção de saída é fixa**: o Codex entregou 1774×887 (2:1) e 887×1774 (1:2). Peça uma
  grade de células quadradas que **caiba nessas proporções** (4×2, 2×4, 2×1, 1×2) e deixe o `autoslice_sheet.gd --columns=` remontar no contrato. Pedir 6:1 ou 5:1
  direto vai dar layout imprevisível.
- Sempre: "Solid flat magenta background (#FF00FF), no text, no labels, no grid lines", formas
  grossas, paleta do setor em hex, "Only the character/object, NO wall, NO floor".
- Animação: nomeie cada linha e a contagem de quadros ("Row 1: walk cycle, 4 frames…") e diga
  qual célula fica vazia.

## 2. Gerar
```bash
tools/gen_image.sh --prompt=<scratchpad>/<ID>.txt --out=<scratchpad>/<ID>/raw.png \
  --ref=assets/sprites/mu7/mu7_sheet.png --variants=2
```
- `--ref` (repetível) é a âncora de estilo: o MU-7 para personagens e máquinas; para tileset e
  prop do setor, a peça já aprovada mais próxima (tileset da fase anterior, porta, terminal).
- 2 variações por padrão. Cada uma é uma requisição da conta Codex do humano: não gere em massa
  sem motivo, e nunca mais de 4 por asset.
- Saída bruta **sempre no scratchpad**; o repo só recebe o arquivo final, fatiado.
- O stream do Codex pode mostrar itens `error` com o aviso `--dangerously-bypass-hook-trust`:
  é da config do usuário e não indica falha. Falha é `GEN FAIL`.

## 3. Escolher (você é o diretor de arte)
1. **Read** em cada variação. Reprove: texto ou grade desenhados, fundo não chapado, cenário
   dentro do quadro, quadros de tamanhos muito diferentes, detalhe fino demais.
2. Conte linhas e quadros e confira contra a ficha (asset-request §C.1). Não bateu, gere de novo
   com o prompt corrigido; não force.
3. Fatie a escolhida:
   ```bash
   perl -e 'alarm 120; exec @ARGV' "$GODOT" --headless --path . -s res://tools/autoslice_sheet.gd -- \
     --in=<raw> --out=<scratchpad>/<ID>/sheet.png --frame-width=W --frame-height=H --columns=N [--fit=contain]
   ```
   O fatiador imprime as linhas e quadros que achou: tem de bater com o contrato.
   **Quadro de estado de 16 px perde linha fina na redução por média**: a rachadura do gelo fino
   (~10 px em ~410 px brutos) sumiu e o quadro `cracked` saiu igual ao `intact`. Preserve linhas
   finas (pixel bruto quase branco que cobre ≥10% da célula reduzida vira cor cheia) e **compare
   quadros vizinhos da mesma animação** antes de aceitar (F61).
   **Passarela one-way desenhada pela IA some contra o fundo** (aconteceu no Lab e na Enfermaria):
   monte a one-way a partir da faixa de piso do próprio tileset (F61).
   **"Sem cruz" vale também para padrão acidental**: geada nas juntas dos azulejos formou "+" (F61).
   **Sprite pendurado (teto ou parede) não vai pelo `autoslice_sheet.gd`**: ele alinha cada
   quadro pelo pé e tira a escala do quadro mais alto, então a placa de fixação da CX-2 ficaria
   em alturas diferentes e o feixe do `fire` encolheria os outros quadros. Fatie alinhado pelo
   topo, centrado na placa, com a escala dos quadros sem efeito (F60; receita na ficha SPR-CX2).
4. **Veja em escala de jogo**:
   ```bash
   perl -e 'alarm 60; exec @ARGV' "$GODOT" --headless --path . -s res://tools/preview_sheet.gd -- \
     --in=<scratchpad>/<ID>/sheet.png --out=<scratchpad>/<ID>/preview.png --scale=6
   ```
   e **Read** no preview. Se a silhueta virou mancha a 32 px, a arte não serve, por mais bonita
   que esteja na imagem bruta.

## 4. Integrar e registrar
Siga a `asset-request` §C.2–C.5: caminho final, `SpriteFrames`/`TileSet`, testes de asset,
`tools/gates.sh`, uma captura no jogo pelo `godot-qa`. Na ficha do ASSETS.md:
- `Fonte`: **IA — geração de imagem do Codex CLI** (data, nº de variações, qual foi escolhida),
  prompt final na ficha e referência de estilo usada;
- status `integrado`; créditos do README na linha de arte gerada por IA.

## 5. Ao planejar uma fase
Na `plan-feature`/`level-design`, gere a arte **junto com o plano** (tileset do setor, inimigo
novo, props-chave), em vez de deixar para o fim. Na demo a arte chegou por último e cada entrega
virou uma rodada de integração e bug de luz/sombra. Rode a geração em background enquanto o
mapa é desenhado; a fase já nasce com arte de verdade, e o placeholder vira só fallback.
