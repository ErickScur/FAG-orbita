# ÓRBITA

> Uma IA de manutenção acorda sozinha numa estação espacial 200 anos depois da tripulação morrer e assume um velho chassi robótico para religar a estação antes que ela caia. Cada setor que ela ilumina revela um pedaço da verdade que ela mesma apagou da própria memória.

Jogo de plataforma 2D em Godot 4.7, feito para a disciplina de **Desenvolvimento de Jogos**. Tema: **ESTAÇÃO** — a estação espacial de pesquisa **ARTEMIS**.

## Sobre

É um jogo de plataforma onde a energia é o inimigo e o recurso ao mesmo tempo. Cada luz que você acende apaga outra, e cada porta que você abre revela uma parte do passado que a protagonista preferia esquecer.

Três pilares:

1. **Escassez** — energia é finita; toda escolha tira algo de algum lugar.
2. **Descoberta** — a história não é contada, é encontrada.
3. **Ausência** — ninguém vivo na estação: todo aliado é uma gravação, todo inimigo é uma máquina cumprindo uma ordem de 200 anos atrás.

## Status

🚧 **Demo (1ª entrega)** — Fase 0 Núcleo Central (tutorial) + Fase 1 Estufa.

## Controles

| Ação | Teclado | Controle |
|---|---|---|
| Mover | A / D ou ← / → | Analógico esquerdo |
| Pular (segurar = mais alto) | Espaço | A |
| Dash magnético | Shift | B |
| Interagir | E | X |
| Feixe de Manutenção | Q | Y |
| Lanterna | F | LB |
| Arquivo de Logs | L | — |
| Pause | Esc | Start |
| Mapa da estação | Tab | Select *(entrega final)* |

## Como rodar

1. Baixe o **Godot 4.7** (versão padrão, não a .NET): https://godotengine.org/download
2. Clone este repositório.
3. Abra o Godot → **Import** → selecione o `project.godot` → **Import & Edit** → **F5**.
   Ou, pelo terminal: `godot --path .`

Builds prontas para Windows e macOS ficam na página de *Releases* (a partir da tag `v0.1-demo`).

## Estrutura do projeto

```
autoload/      sistemas globais (estado, save, áudio, cenas, diálogo)
scripts/core/  lógica pura e testável (energia, status, fases, balanceamento)
scenes/        boot, ui, player, enemies, world, levels
data/          fases em ASCII, puzzles de energia, logs e diálogos (JSON)
assets/        sprites, tiles, ui, fontes, áudio
tests/         testes de lógica e roteiros de QA
tools/         utilitários (placeholders, smoke test)
```

As fases são escritas como **mapas ASCII** em `data/levels/` e montadas em tempo de execução.

## Design

- [Game Design Document](docs/design/GDD.md)
- [Jornada do Herói](docs/design/JORNADA-DO-HEROI.md)

## Equipe

Alex Hoffmann · Erick Scur · Murilo Wolff Klug · Kauan Giacomin · Victor William

Professor: Jeferson Eduardo Guido — disciplina de Desenvolvimento de Jogos.

## Créditos e licenças de assets

| Asset | Autor | Licença |
|---|---|---|
| m5x7 (fonte da UI) | Daniel Linssen | livre, crédito solicitado — https://managore.itch.io/m5x7 |
| Plataforma móvel | Kenney — *Pixel Platformer: Industrial Expansion* | CC0 — https://kenney.nl/assets |
| Partículas | Kenney — *Particle Pack* | CC0 — https://kenney.nl/assets |
| Efeitos sonoros | Kenney — *Sci-Fi Sounds* | CC0 — https://kenney.nl/assets |
| MU-7, SR-3, terminais, porta, planta, objetos, tilesets, fundo de espaço, logo | gerados com Gemini / Nano Banana Pro | uso próprio do projeto |
| Trilhas do Núcleo Central e da Estufa | geradas por IA | uso próprio do projeto |
