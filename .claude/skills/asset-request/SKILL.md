---
name: asset-request
description: Cria ou atualiza a ficha de um asset do ÓRBITA no docs/ASSETS.md — contrato técnico, opção gratuita (link + licença verificada) e/ou prompt pronto para Gemini/Nano Banana Pro — e, quando o humano entregar o arquivo bruto, pós-processa e integra no jogo. Use quando uma feature precisar de arte/som/fonte, quando o usuário pedir "prompts dos assets", "onde baixo X", ou disser que baixou/gerou um asset.
---

# asset-request — Do pedido ao asset integrado

Leia antes: `docs/ASSETS.md` (registro e contratos), `docs/ASSET-PIPELINE.md` (estilo, paleta, fontes gratuitas, template de prompt).

## A. Criar a ficha
1. **ID**: `SPR-`, `TIL-`, `BG-`, `UI-`, `FX-`, `MUS-`, `SFX-` + nome curto. Verifique se já existe.
2. **Contrato**: caminho final `assets/...`, dimensões exatas (tile 16, frame 32, tela 384×216), frames/linhas, loop (áudio).
3. **Opção gratuita**: busque (WebSearch/WebFetch) em Kenney, itch.io (filtro CC0), OpenGameArt, Freesound (CC0), Pixabay. Anote **link direto e licença** conferida na página. Nada sem licença clara.
4. **Opção IA**: prompt em inglês seguindo o template do ASSET-PIPELINE §3 — fundo magenta `#FF00FF`, grade/frames explícitos, paleta do setor, "no text, no grid lines".
5. Linha no índice do ASSETS.md (prioridade A/B/C, feature) + ficha completa. Status `pendente` (ou `placeholder` se já há gerado).
6. Garanta o placeholder: `"$GODOT" --headless --path . -s res://tools/make_placeholders.gd`.

## B. Entregar ao humano
Resuma em lista curta, por prioridade: ID → "baixe daqui (licença X)" **ou** "cole este prompt no Gemini", e onde salvar: `~/Downloads/orbita-assets/<ID>/`.

## C. Integrar o que chegou
1. Confira o arquivo (Read na imagem). Rejeite se ilegível em tamanho pequeno.
2. Pós-processe com `tools/process_image.gd` (remove magenta, nearest, grade, paleta) para o caminho final.
3. Atualize `SpriteFrames`/`TileSet`/cena para apontar ao arquivo final; `--import`.
4. `godot-qa` para ver no jogo.
5. ASSETS.md: status `integrado`, autor/licença na tabela de créditos; espelhe no `README.md`.
6. Commit: `art(F<id>): <asset>` ou `audio(F<id>): <asset>`.
