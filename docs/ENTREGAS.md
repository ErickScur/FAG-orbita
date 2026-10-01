# ENTREGAS.md — Escopos de entrega e rubrica

> O que vale nota, o que entra em cada entrega e como vamos mostrar. Quando uma feature que atende a rubrica fica `[x]`, atualize a coluna **Status** abaixo.

---

<a id="entregas"></a>
## 1. Entregas

| Entrega | Conteúdo | Prazo | Tag git |
|---|---|---|---|
| **1 — Demo (~30%)** | Fase 0 Núcleo Central + Fase 1 Estufa, todas as telas da rubrica, sistemas-base. Termina em "FIM DA DEMO" | 3 dias de trabalho focado | `v0.1-demo` |
| **2 — Final** | Fases 2–6, mini boss, boss, batalha final, final alternativo, mapa, música adaptativa, apresentação | a definir | `v1.0` |

**Por que ~30%:** o jogo completo tem 7 fases (0–6) e ~12 logs; a demo entrega 2 fases (0 e 1) + 4 logs + 4 dados + todos os sistemas-base e telas. Conteúdo ≈ 25–30%; sistemas ≈ 70%. Os contadores da demo fecham em 4/4 ([AJ-024](design/GDD.md#gdd-ajustes)).

### Definition of Done da Demo
- [x] Do **splash** ao **FIM DA DEMO** sem crash **rodando do código-fonte** (reverificado em 2026-09-20 depois da revisão de jogabilidade F36/F37/F38: menu → briefing do MU-7 → Núcleo Central com os cartões de tutorial, o terminal de 3 sistemas e o elevador opcional → Estufa pela rota da luz de crescimento → garras → parede magnética → Nó religado → `FIM DA DEMO` com `TEMPO 00:50 · LOGS 1/4 · DADOS 1/4 · MORTES 0 · SEGREDOS 0/4`). Falta só em **build exportada** (F30).
- [x] Todas as linhas `DEMO` do [INDEX](INDEX.md) em `[x]` **exceto F30** (build, adiada a pedido).
- [ ] Todos os itens da rubrica marcados como **Demo** abaixo verificáveis em jogo.
- [ ] Repositório público atualizado, `README.md` com controles e créditos, tag `v0.1-demo`.
- [ ] Nenhum asset sem licença registrada.

---

<a id="ritmo-3-dias"></a>
## 2. Ritmo sugerido (3 dias)

| Dia | Features | Marco ao fim do dia |
|---|---|---|
| **1** | F01–F06 (fundação), F07–F11 (telas), F12 (movimento) | Splash → loading → menu → opções (volume) → jogo com MU-7 andando numa sala de teste → pause/recomeçar → save/load |
| **2** | F13–F21 (núcleo), F22–F24 | HUD completo, reator caindo, terminal de energia funcionando, lanterna, logs, coletáveis, SR-3, esporos, garras |
| **3** | F25–F29 (fases), troca de assets, F30 (build), playtest; stretch F31–F34 se sobrar | Demo completa exportada e publicada |

Asset "definitivo" é trabalho paralelo do humano: assim que o Dia 1 terminar, o agente entrega a lista priorizada do [`ASSETS.md`](ASSETS.md) (links gratuitos + prompts Nano Banana Pro).

---

<a id="rubrica"></a>
## 3. Rubrica da disciplina → features

### 3.1 Itens fixos (1 ponto cada)

| Item | Feature(s) | Entrega | Como mostrar | Status |
|---|---|:--:|---|:--:|
| Apresentação do jogo (5–10 min) | [F72](INDEX.md#bloco-6--entrega-final-não-detalhado) (+ roteiro §4) | Demo e Final | Roteiro abaixo | `[ ]` |
| Github | [F01](features/F01-setup-projeto.md), [F30](features/F30-build-demo.md) | Demo | Repo público, histórico de commits por feature, README, release | `[~]` (repo e README ok; release na F30) |
| Menu | [F07](features/F07-menu-principal.md) | Demo | Tela inicial com Continuar/Novo/Opções/Sair | `[`[x]` |
| Tela de loading / splash screen | [F03](features/F03-cenas-splash-loading.md) | Demo | Splash com logo + loading com barra entre menu e fase | `[x]` |
| Tela de fim de jogo | [F10](features/F10-telas-fim-de-jogo.md) | Demo | Perda de órbita (reator 0%), chassi perdido, FIM DA DEMO com estatísticas | `[`[x]` |
| Ajuste de volume (dentro do jogo) | [F04](features/F04-audio-volume.md), [F08](features/F08-opcoes-dificuldade.md) | Demo | Sliders Master/Música/Efeitos/Voz no menu **e** no pause | `[`[x]` |

### 3.2 Mecânicas (pontuam como desenvolvimento de mecânica)

| Mecânica | Feature(s) | Entrega | Status |
|---|---|:--:|:--:|
| Diálogo | [F19](features/F19-dialogo-logs.md) | Demo | `[`[x]` |
| Salvar/Carregar progresso | [F11](features/F11-salvar-carregar.md) | Demo | `[`[x]` |
| Score de jogador (placar/contadores) | [F20](features/F20-coletaveis-contadores.md) + [F37](features/F37-legibilidade-hud.md) (Logs x/4, Dados x/4 numa linha do HUD, estatísticas no fim) | Demo | `[x]` |
| Dificuldade ajustável | [F08](features/F08-opcoes-dificuldade.md) | Demo | `[`[x]` |
| Life skills (vida/energia) | [F13](features/F13-integridade-carga-respawn.md) (Integridade + Carga) | Demo | `[`[x]` |
| Luz/Sombra | [F18](features/F18-luz-lanterna.md) | Demo | `[`[x]` |
| Efeitos naturais (campo de visão, clima) | [F18](features/F18-luz-lanterna.md) (campo de visão), [F23](features/F23-esporos-status.md) (Primavera/esporos) | Demo | `[`[x]` |
| Puzzle | [F17](features/F17-terminal-distribuicao.md) | Demo | `[`[x]` |
| Música (trilha sonora) | [F04](features/F04-audio-volume.md), [F28](features/F28-fase-nucleo-central.md), [F29](features/F29-fase-estufa.md) | Demo | `[`[x]` |
| Efeitos visuais/sonoros | [F05](features/F05-pipeline-assets-placeholders.md), [F04](features/F04-audio-volume.md), [F29](features/F29-fase-estufa.md) | Demo | `[`[x]` |
| Habilidades | [F24](features/F24-garras-magneticas.md) (+ [F31](features/F31-dash-feixe.md) stretch) | Demo | `[`[x]` |
| Itens e inventário | [F20](features/F20-coletaveis-contadores.md) (+ [F33](features/F33-arquivo-logs.md) stretch) | Demo | `[`[x]` |
| Coleta de itens | [F20](features/F20-coletaveis-contadores.md) | Demo | `[`[x]` |
| Recompensas | [F14](features/F14-estabilidade-reator.md) (log → +0,5% reator; setor → +15%), [F20](features/F20-coletaveis-contadores.md), [F24](features/F24-garras-magneticas.md) (upgrade ao religar setor) | Demo | `[ ]` |
| HUD | [F15](features/F15-hud-objetivos.md) | Demo | `[`[x]` |
| Missões primárias | [F15](features/F15-hud-objetivos.md) (objetivo atual: estabilizar o reator / religar a Estufa) | Demo | `[`[x]` |
| Botão de pause | [F09](features/F09-pause-recomecar.md) | Demo | `[`[x]` |
| Botão de recomeçar jogo | [F09](features/F09-pause-recomecar.md) | Demo | `[`[x]` |
| Plataformas que se movimentam | [F25](features/F25-plataformas-moveis-planta.md) | Demo | `[`[x]` |
| Paralax | [F26](features/F26-parallax.md) | Demo | `[`[x]` |
| Área secreta | [F27](features/F27-area-secreta.md) | Demo | `[`[x]` |
| Combate (não-letal) | [F31](features/F31-dash-feixe.md) (Feixe desliga inimigos) | Stretch | `[ ]` |
| Movimento aleatório de NPCs | [F34](features/F34-drone-botanico.md) | Stretch | `[ ]` |
| Missões secundárias | Coleta opcional de Dados de Pesquisa ([F20](features/F20-coletaveis-contadores.md)) + F66 | Final | `[ ]` |
| Desenvolvimento de 4 fases com dificuldades diferentes | F60, F61, F62 (+ Estufa) | Final | `[ ]` |
| Chefão de nível (Boss) | F64, F65 | Final | `[ ]` |
| Chefão de nível inferior (Mini-boss) | F63 | Final | `[ ]` |
| Fim de jogo alternativo | F66 | Final | `[ ]` |
| Nível (progressão) | F69 (upgrades permanentes) | Final | `[ ]` |
| Scanner | F67 (mapa da estação) | Final | `[ ]` |
| 3D · Elementos de FPS | — | `[-]` [ADR-000](DECISIONS.md#adr-000) | `[-]` |
| Elementos de RTS · Turnos · Montaria · Sandbox · Endless · Conta de usuário · Classes · Armaduras · Loja · Dinheiro · Simulação de dia | — | `[-]` fora dos pilares do GDD | `[-]` |

---

<a id="apresentacao"></a>
## 4. Roteiro da apresentação da Demo (5–10 min)

1. **(1 min) Conceito:** tema "Estação" → estação espacial ARTEMIS; pitch e pilares ([VISION](VISION.md)).
2. **(1 min) Jornada do Herói:** as 9 etapas em 1 slide; mostrar onde a demo está (etapas 1–5).
3. **(5 min) Gameplay ao vivo:** splash → loading → menu → opções (mexer no volume, trocar dificuldade) → briefing do MU-7 → Núcleo Central (tutorial com cartões de tecla, primeiro terminal 3 sistemas/1 energia) → Estufa (lanterna/escuridão, SR-3, esporos, planta que cresce, plataforma móvel, área secreta, garras) → pause/recomeçar → salvar/carregar → morrer uma vez (chassi perdido) → religar a Estufa → FIM DA DEMO com estatísticas.
4. **(1 min) Por dentro:** GitHub (commits por feature), GDD versionado, arquitetura (autoloads, fases em ASCII).
5. **(1 min) Próximos passos:** fases 2–6, bosses, final alternativo.

Checklist a mostrar na tela durante a demo: a tabela §3 com os itens `[x]`.
