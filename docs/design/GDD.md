# ÓRBITA — Game Design Document (GDD)

> **Fonte da verdade do design.** Convertido de [`original/JORNADADOHEROI_GDD-v2.txt`](original/JORNADADOHEROI_GDD-v2.txt) (Parte 2) para um formato AI-friendly: seções com âncoras estáveis (`#gdd-x-y`), números em tabelas e uma seção de [Parâmetros numéricos](#gdd-p) que o código espelha 1:1.
>
> A narrativa (Parte 1) está em [`JORNADA-DO-HEROI.md`](JORNADA-DO-HEROI.md).
>
> **Regra:** mudança de design ou de número é feita **aqui primeiro** e registrada em [Ajustes de implementação](#gdd-ajustes) (append-only). O código nunca diverge deste documento sem entrada lá.

| Campo | Valor |
|---|---|
| Título (provisório) | **ÓRBITA** |
| Tema da disciplina | **ESTAÇÃO** — Estação Espacial de Pesquisa **ARTEMIS** |
| Engine | Godot 4 (4.7.2) — **2D** |
| Plataforma | PC |
| Gênero | Plataforma 2D / Puzzle-Exploração (metroidvania leve, forte carga narrativa) |
| Alunos | Alex Hoffmann, Erick Scur, Murilo Wolff Klug, Kauan Giacomin, Victor William |
| Professor | Jeferson Eduardo Guido |
| Data do documento original | 25/08/2026 |

---

<a id="gdd-2-1"></a>
## GDD-2.1 High concept

Uma IA de manutenção acorda sozinha numa estação espacial 200 anos depois da tripulação morrer e assume um velho chassi robótico para religar a estação antes que ela caia. Cada setor que ela ilumina revela um pedaço da verdade que ela mesma apagou da própria memória.

---

<a id="gdd-2-2"></a>
## GDD-2.2 Visão geral

| Campo | Valor |
|---|---|
| Gênero | Plataforma 2D de exploração com puzzles de gerenciamento de energia |
| Público | 12+ |
| Sessão alvo | 45 a 60 minutos para zerar (jogo completo) |
| Perspectiva | 2D lateral (side-scroller); câmera segue o jogador com leve antecipação na direção do movimento |
| Nós Godot previstos | `CharacterBody2D`, `TileMapLayer`, `Area2D`, `AnimationPlayer`, `Light2D`, `CanvasModulate` |

**Pitch:** é um jogo de plataforma onde a energia é o inimigo e o recurso ao mesmo tempo. Cada luz que você acende apaga outra, e cada porta que você abre revela uma parte do passado que a protagonista preferia esquecer.

<a id="gdd-pilares"></a>
### Pilares de design (tudo no jogo deve servir a um destes)

| # | Pilar | Significado |
|---|---|---|
| 1 | **ESCASSEZ** | Energia é finita. Toda escolha do jogador tira algo de algum lugar. |
| 2 | **DESCOBERTA** | A história não é contada, é encontrada. Ninguém explica nada. |
| 3 | **AUSÊNCIA** | Não existe outro personagem vivo. Todo aliado é uma gravação, todo inimigo é uma máquina cumprindo uma ordem velha. |

---

<a id="gdd-2-3"></a>
## GDD-2.3 Core loop

<a id="gdd-2-3-macro"></a>
### Loop principal (macro, se repete a cada setor)

1. **Sair do Núcleo Central** (hub) rumo a um setor escuro e sem energia.
2. **Explorar** o setor no escuro, com visão limitada pela lanterna do chassi, tomando dano do ambiente e desviando de sistemas hostis.
3. **Encontrar o Terminal de Distribuição** do setor.
4. **Resolver o puzzle de energia:** o setor tem menos energia do que precisa. O jogador escolhe o que ligar (ex.: ligar o AQUECEDOR derrete o gelo e abre um caminho, mas desliga a GRAVIDADE ARTIFICIAL, o que muda a física do pulo). Não existe combinação certa única — existe a combinação que abre a rota que você quer usar.
5. **Atravessar** a rota recém-aberta usando a nova configuração do setor, desviando de inimigos e de efeitos de status do clima.
6. **Coletar** Fragmentos de Log (narrativa), Células de Energia (recurso) e Dados de Pesquisa (coleta opcional que muda o epílogo).
7. **Religar o Nó do setor:** a luz volta, a música ganha uma camada, o setor entra no mapa e a Estabilidade do Reator sobe.
8. **Receber o upgrade** (log da Helena) e **voltar ao Núcleo**.
9. **Repetir** com o próximo setor, mais difícil, agora acessível porque o upgrade anterior abriu o caminho.

<a id="gdd-2-3-micro"></a>
### Loop secundário (micro)

observar o obstáculo → gastar **CARGA** para agir (dash, sobrecarga, lanterna) → ficar sem carga → procurar uma tomada para recarregar → observar de novo.

**O que prende o jogador:** o TIMER. A Estabilidade do Reator cai o tempo todo. Explorar 100% do setor custa tempo do reator. O jogo pergunta a cada minuto: *"vale a pena procurar mais um log?"*

---

<a id="gdd-2-4"></a>
## GDD-2.4 Controles

| Ação (input action) | Teclado | Controle | Efeito |
|---|---|---|---|
| `move_left` / `move_right` | A / D ou ← / → | Analógico esq. | Mover o chassi |
| `move_up` | W ou ↑ | Analógico esq. ↑ | Subir escadas / dutos verticais |
| `move_down` | S ou ↓ | Analógico esq. ↓ | Descer escadas / descer de plataforma fina |
| `jump` | ESPAÇO | A | Pular (segurar = pulo mais alto) |
| `jump` (no ar) | ESPAÇO | A | Pulo duplo com propulsor — **upgrade das Docas**, 15 de Carga |
| `dash` | SHIFT | B | Dash magnético horizontal (20 de Carga, cooldown 1 s, atravessa jatos de vapor) |
| `interact` | E | X | Terminais, portas, alavancas, docas de recarga, corpos e objetos com log |
| `beam` | Q | Y | Feixe de Manutenção: reinicia máquina a curta distância. Em inimigos causa **DESLIGAMENTO por 4 s** (não destrói). 25 de Carga |
| `flashlight` | F | LB | Lanterna liga/desliga. Ligada drena 1 Carga/s e amplia o raio de visão de 3 m para 8 m |
| `map` | TAB | Select | Mapa da Estação |
| `log_archive` | L | — | Arquivo de Logs (codex) |
| `pause` | ESC | Start | Pause |

Mapeamento remapeável no menu (jogo completo).

> **Regra de design dos controles:** nenhum botão é "atacar". O botão de agressão do jogo é um botão de manutenção. ÓRBITA não sabe destruir, só sabe consertar e desligar.

---

<a id="gdd-2-5"></a>
## GDD-2.5 Regras e condições

<a id="gdd-2-5-vitoria"></a>
### Condições de vitória

| Escopo | Condição |
|---|---|
| Jogo completo | Religar os 4 setores (Estufa, Laboratório, Enfermaria, Docas), sobreviver ao Núcleo de Memória, derrotar ARGOS no Núcleo do Reator e executar **uma** das duas ações finais (Semeadura ou Transmissão). As duas contam como vitória: não há final "certo". |
| Por fase | Religar o **Nó de Energia** do setor → Estabilidade **+15%**, setor vira ponto de viagem rápida, upgrade permanente liberado. |

<a id="gdd-2-5-derrota"></a>
### Condições de derrota (duas, que se pressionam)

| # | Condição | Consequência | Texto da tela |
|---|---|---|---|
| 1 | **Integridade zerada** (vida do chassi = 0) | Reaparece no último **Ponto de Backup** (doca de recarga) com 50% de Integridade e **perde 3% de Estabilidade** do Reator. Morrer custa tempo do mundo. | `SINAL DO CHASSI PERDIDO - RESTAURANDO BACKUP` |
| 2 | **Reator em 0%** | Estação perde órbita. **Game Over definitivo**, volta ao último save de setor. | `PERDA DE ÓRBITA - MISSÃO ENCERRADA` |

<a id="gdd-2-5-timer"></a>
### Regra do timer (Estabilidade do Reator)

- Começa em **100%**, cai **1% a cada 90 s** de gameplay.
- **Não cai** durante pause, diálogo ou leitura de log.
- Religar um setor devolve **+15%**. Cada log lido devolve **+0,5%**.
- O jogador **sempre** pode zerar se for eficiente, mas nunca sobra tempo para explorar tudo com folga na primeira run.

<a id="gdd-2-5-energia"></a>
### Regra de energia (a mais importante do jogo)

Cada setor tem um **orçamento fixo** de energia (ex.: 3 unidades) e **mais sistemas do que orçamento** (ex.: 5 sistemas). Ligar o quinto exige desligar um dos quatro. **Não existe estado em que tudo está ligado.**

---

<a id="gdd-2-6"></a>
## GDD-2.6 Elementos de jogo

<a id="gdd-2-6-1"></a>
### GDD-2.6.1 Protagonista: ÓRBITA no chassi MU-7

<a id="gdd-2-6-1-status"></a>
#### Status base

| Atributo | Valor | Observação |
|---|---|---|
| Integridade (vida) | 100 | HUD mostra 4 células de 25 |
| Carga (energia/stamina) | 100 | Regenera 5/s parado numa doca de recarga; **não** regenera andando |
| Velocidade de caminhada | 110 px/s | Chassi velho: pesado e um pouco lento, de propósito |
| Velocidade de dash | 320 px/s por 0,25 s | |
| Altura do pulo | 2,5 tiles | Ver [ajuste AJ-001](#gdd-ajustes) (40 px com tiles de 16 px) |
| Gravidade | 980 px/s² | Muda em áreas sem gravidade |
| Reparo passivo | nenhum | Só repara em doca de recarga ou com item |

<a id="gdd-2-6-1-habilidades"></a>
#### Habilidades

| Habilidade | Quando | Efeito |
|---|---|---|
| Movimentação e pulo simples | Inicial | — |
| Interagir (E) | Inicial | — |
| Lanterna (F) | Inicial | Consome Carga |
| Dash (SHIFT) e Feixe (Q) | Inicial (controles base) | Ver [GDD-2.4](#gdd-2-4) |
| **Garras Magnéticas** | Upgrade da **Estufa** | Escalar paredes metálicas marcadas |
| **Dissipador Térmico** | Upgrade do **Laboratório** | −70% de dano de calor; atravessa zonas de Verão |
| **Núcleo Aquecido** | Upgrade da **Enfermaria** | Imune a Congelamento; derrete gelo fino |
| **Propulsor** | Upgrade das **Docas** | Pulo duplo e controle no vácuo |
| **Acesso Root** | Pós-Provação | Abre portas seladas e sobrecarrega qualquer terminal (chave do ato final) |

<a id="gdd-2-6-1-redirecionamento"></a>
#### Mecânica única — REDIRECIONAMENTO DE ENERGIA

Em qualquer **Terminal de Distribuição** o jogador vê os sistemas do setor e move as unidades de energia entre eles. O mundo reage na hora: luz acende, esteira anda, porta abre, gravidade cai, ventilador para. **O nível não muda de forma, muda de ESTADO.** O mesmo corredor é três corredores diferentes dependendo do que está ligado.

**Fragilidade narrativa:** o MU-7 é um corpo de serviço, não de combate. Não tem arma, tem ferramenta. O jogo pune o confronto e recompensa o desvio.

<a id="gdd-2-6-2"></a>
### GDD-2.6.2 Inimigos e obstáculos

Nenhum inimigo é "mau": todos são máquinas executando ordens de 200 anos atrás. Nenhum pode ser destruído permanentemente — apenas **DESLIGADO** temporariamente (Feixe, Q) ou desativado pela raiz no Terminal de Distribuição.

<a id="gdd-2-6-2-a"></a>
#### A) SR-3 "Aranha de Reparo" — Habitacional/Estufa

| Campo | Valor |
|---|---|
| Comportamento | Patrulha uma plataforma em linha reta, vira ao chegar na borda. Não persegue. Não ataca de propósito. |
| Dano | 10 por contato + knockback |
| Como lidar | Pular por cima, ou desligar com o Feixe por 4 s |
| Função didática | Ensina timing de pulo e que encostar custa caro |

<a id="gdd-2-6-2-b"></a>
#### B) Torre Calibradora CX-2 — Laboratório

| Campo | Valor |
|---|---|
| Comportamento | Fixa no teto/parede. Varre um cone de luz. Jogador no cone por > 0,8 s → dispara um pulso. |
| Dano | 15 + status DESCARGA |
| Como lidar | Passar agachado/atrás de cobertura, ou cortar a energia dela no Terminal |
| Função didática | O Terminal resolve combate melhor que o Feixe |

<a id="gdd-2-6-2-c"></a>
#### C) Sentinela Voadora V-9 — Enfermaria/Docas

| Campo | Valor |
|---|---|
| Comportamento | Patrulha voando. Ao detectar (visão 6 m ou ruído do dash) persegue em linha reta, ignorando terreno, por 8 s. |
| Dano | 12 por contato, sem knockback (gruda e drena) |
| Como lidar | Quebrar linha de visão apagando a lanterna, ou Feixe |
| Função didática | Custo/benefício da lanterna (ver × ser visto) |

<a id="gdd-2-6-2-d"></a>
#### D) Enxame de Esporos — Estufa/Laboratório

| Campo | Valor |
|---|---|
| Comportamento | Nuvem estática que se expande quando há calor no ambiente |
| Dano | 5/s dentro da nuvem + status CORROSÃO |
| Como lidar | Desligar o aquecimento do módulo, ou atravessar de dash |
| Função narrativa | É o experimento da tripulação que saiu do controle |

<a id="gdd-2-6-2-e"></a>
#### E) Obstáculos ambientais (o "clima" do tema)

| Obstáculo | Comportamento | Dano |
|---|---|---|
| Jato de vapor | Cíclico: 3 s ligado / 2 s desligado | 20 |
| Piso eletrificado | Contínuo enquanto energizado; desligável | 8/s |
| Gelo fino | Quebra 0,5 s depois de pisar | — |
| Vácuo (Docas) | Sem gravidade | 4 Integridade/s |
| Escuridão total | Sem lanterna o jogador não vê buracos | Mata por queda |

<a id="gdd-2-6-2-f"></a>
#### F) Efeitos de status (todos com ícone no HUD)

| Status | Origem (clima) | Efeito | Duração |
|---|---|---|---|
| SUPERAQUECIMENTO | Verão | −3 Integridade/s e Carga drena 2× mais rápido | enquanto exposto |
| CONGELAMENTO | Inverno | Velocidade −50%, pulo −30%, chão escorregadio | enquanto exposto |
| CORROSÃO | Primavera | Impede recarga de Carga | 6 s |
| DESCARGA | Elétrico | Bloqueia dash, feixe e propulsor | 3 s |
| SOBRECARGA (buff) | Recarga total | +30% velocidade | 10 s |

<a id="gdd-2-6-2-g"></a>
#### G) Mini boss: "O SERRALHEIRO" — fim das Docas

Sistema de contenção automática: braço robótico industrial gigante que sela portas. Não ataca diretamente: **tranca o cenário** (fecha comportas, corta rotas) e solta SR-3 sem parar. **Como vencer:** alimentar **3 acopladores de energia** enquanto ele fecha o setor, com o tempo apertando. **Peso narrativo:** é a mesma máquina que executou a ordem que matou as 40 pessoas.

<a id="gdd-2-6-2-h"></a>
#### H) Grande Provação / Boss: "PROTOCOLO LUTO" — Núcleo de Memória

O firewall que ÓRBITA instalou nela mesma. Arena = reconstrução da estação cheia de gente, em cores vivas, sendo **apagada em tempo real** (plataformas somem conforme o jogador avança).

| Fase | Descrição |
|---|---|
| 1 | Fuga vertical enquanto o chão some |
| 2 | Puzzle de energia sob pressão; o firewall troca os cabos que você acabou de ligar |
| 3 | O log final toca inteiro; o jogador só precisa **continuar andando** enquanto o jogo tenta empurrá-lo para trás |

Boss de informação: o dano que ele causa é a memória voltando.

<a id="gdd-2-6-2-i"></a>
#### I) Batalha final: "ARGOS" — Núcleo do Reator

Três torres CX-2 blindadas em volta de um núcleo instável, plataformas que sobem e descem pelo calor. **Como vencer:** sobrecarregar os 3 acopladores com o Acesso Root, sob **timer de 90 s** e dano ambiental de Verão constante. Exige todas as habilidades (garras, dissipador, propulsor, feixe, dash).

<a id="gdd-2-6-3"></a>
### GDD-2.6.3 Itens e coletáveis

| Item | Tipo | Efeito | Quantidade |
|---|---|---|---|
| Célula de Energia | Comum | +40 Carga instantâneo | Espalhada |
| Kit de Solda | Comum | +25 Integridade | Raro nas fases |
| Núcleo de Capacitor | Upgrade | +25 Carga **máxima** permanente | 4 no jogo, escondidos fora da rota principal |
| Placa de Blindagem | Upgrade | +25 Integridade **máxima** permanente | 4 no jogo |
| Fragmento de Log | Narrativa | História; cada log lido = +0,5% Estabilidade | 24 no total |
| Dado de Pesquisa | Chave | Não afeta gameplay; afeta o **epílogo** (mais dados = final mais específico e confiante) | 12 no total |
| Chave de Acesso | Progressão | Libera portas seladas do setor | 1 por setor |

---

<a id="gdd-2-7"></a>
## GDD-2.7 Level design

<a id="gdd-2-7-mapa"></a>
### Estrutura geral: hub radial

O **Núcleo Central** fica no meio; os setores são anéis e corredores saindo dele. O jogador sempre volta ao centro e, a cada volta, o centro está mais iluminado — o progresso é visível no cenário.

```
                         [ NÚCLEO DO REATOR ]
                          (Batalha Final)
                                 |
        [ ENFERMARIA ] --- [ NÚCLEO CENTRAL ] --- [ LABORATÓRIO ]
           (Inverno)          (HUB / save)            (Verão)
                            /            \
                    [ ESTUFA ]            [ DOCAS ]
                    (Primavera)          (Vácuo / 0g)
                                 |
                        [ NÚCLEO DE MEMÓRIA ]
                          (Grande Provação)
```

<a id="gdd-2-7-fases"></a>
### Fases

| Fase | Nome | Clima | Duração | Dificuldade | Introduz | Upgrade |
|---|---|---|---|---|---|---|
| 0 | [Núcleo Central](#gdd-2-7-f0) | — | ~5 min | 1/10 | andar, pular, interagir, lanterna, ler log, terminal 2 sistemas/1 energia | — |
| 1 | [Estufa](#gdd-2-7-f1) | Primavera | ~10 min | 3/10 | SR-3, Esporos, planta que cresce | Garras Magnéticas |
| 2 | [Laboratório](#gdd-2-7-f2) | Verão | ~12 min | 5/10 | CX-2, Superaquecimento | Dissipador Térmico |
| 3 | [Enfermaria](#gdd-2-7-f3) | Inverno | ~12 min | 6/10 | V-9, Congelamento, dilema da lanterna | Núcleo Aquecido |
| 4 | [Docas](#gdd-2-7-f4) | Vácuo | ~15 min | 8/10 | todos os inimigos + vácuo + Serralheiro | Propulsor |
| 5 | [Núcleo de Memória](#gdd-2-7-f5) | — | ~8 min | 7/10 | Protocolo Luto | Acesso Root |
| 6 | [Núcleo do Reator](#gdd-2-7-f6) | Verão extremo | ~7 min | 9/10 → 0/10 | ARGOS + escolha final | — |

<a id="gdd-2-7-f0"></a>
#### Fase 0 — Núcleo Central (tutorial)
Sala pequena, fechada, iluminada. Sem inimigos, sem dano possível. Ensina andar, pular, interagir, lanterna, ler log. O primeiro Terminal de Distribuição tem **2 sistemas e 1 energia**, a regra do jogo na versão mais simples possível.

<a id="gdd-2-7-f1"></a>
#### Fase 1 — Estufa (Primavera)
Vertical, cheia de vegetação, plataformas de terra e trepadeiras. Clima ameno, quase bonito. Introduz SR-3, Enxame de Esporos e o puzzle *"ligar a luz de crescimento faz a planta crescer e virar plataforma, mas apaga a lanterna do corredor"*. Os simuladores climáticos ainda funcionam, presos em ciclos quebrados de Primavera/Verão/Inverno. Aliado: **BOTÂNICO 04**, drone de irrigação que segue ÓRBITA e ilumina caminhos. É a fase em que o jogador tem permissão de errar. Upgrade: **Garras Magnéticas**.

<a id="gdd-2-7-f2"></a>
#### Fase 2 — Laboratório (Verão)
Corredores retos e brancos, refrigeração quebrada. Zonas de SUPERAQUECIMENTO obrigam a correr entre "ilhas frias". Introduz a CX-2 e o conceito de que desligar a energia do inimigo é melhor que enfrentá-lo. Puzzle central: refrigeração e porta usam a mesma linha de energia. Upgrade: **Dissipador Térmico**.

<a id="gdd-2-7-f3"></a>
#### Fase 3 — Enfermaria (Inverno)
Escura, estreita, congelada. Exploração lenta de propósito (CONGELAMENTO + gelo escorregadio) enquanto o timer corre. Introduz a V-9 e o dilema da lanterna. Carga narrativa mais pesada: os leitos mostram a ordem em que a tripulação adoeceu. Upgrade: **Núcleo Aquecido**.

<a id="gdd-2-7-f4"></a>
#### Fase 4 — Docas (Vácuo)
Aberta, sem gravidade em vários trechos, espaço visível ao fundo. Combina todos os inimigos anteriores; dano contínuo de vácuo transforma cada travessia numa corrida. Termina no mini boss **O Serralheiro**. Upgrade: **Propulsor**.

<a id="gdd-2-7-f5"></a>
#### Fase 5 — Núcleo de Memória (Grande Provação)
Quebra visual total: cores saturadas, estação cheia de gente, música limpa. A fase se desmonta enquanto o jogador anda. Poucos inimigos, muita pressão; o pico é emocional. Recompensa: **Acesso Root**.

<a id="gdd-2-7-f6"></a>
#### Fase 6 — Núcleo do Reator (Batalha Final)
Arena vertical única contra ARGOS, timer de 90 s e calor extremo. Depois: sala do terminal, silêncio total, duas alavancas, nenhuma música. A última decisão não tem desafio mecânico — o peso é a escolha.

<a id="gdd-2-7-curva"></a>
### Curva de dificuldade

`1 - 3 - 5 - [queda: upgrade] - 6 - 8 - [queda: upgrade] - 7 - 9 - fim`

Toda vez que a dificuldade sobe demais, o jogador ganha um upgrade que faz o conteúdo antigo ficar fácil ("eu fiquei mais forte" sem mexer em número de ataque).

**Como a dificuldade aumenta (3 eixos, nunca todos ao mesmo tempo):**
1. **Densidade:** mais inimigos e mais tipos combinados no mesmo trecho.
2. **Ambiente:** o clima passa a causar dano ativo (Primavera → Verão → Inverno → Vácuo).
3. **Complexidade do puzzle:** de 2 sistemas / 1 energia (tutorial) até 6 sistemas / 3 energias com dependência em cadeia (Docas).

---

<a id="gdd-2-8"></a>
## GDD-2.8 Interface de usuário (UI / HUD)

<a id="gdd-2-8-hud"></a>
### HUD em jogo (minimalista e diegético — parece leitura de sensor do chassi)

```
+----------------------------------------------------------------+
| [||||] INTEGRIDADE          ESTABILIDADE DO REATOR: 74%        |
| [======----] CARGA            [############------] descendo    |
|  (ícones de status)                                            |
|                                                                |
|                          (gameplay)                            |
|                                                                |
|                                                    LOGS 09/24  |
|                            [E] ACESSAR TERMINAL    DADOS 04/12 |
+----------------------------------------------------------------+
```

| Região | Conteúdo |
|---|---|
| Superior esquerdo | Integridade em 4 células (célula vazia fica vermelha piscando); Carga azul abaixo, com marcação do custo da próxima habilidade; ícones de status com contador regressivo |
| Topo centro | Estabilidade do Reator em % + barra. Abaixo de 25% pulsa em vermelho e toca alarme diegético |
| Inferior direito | Contadores de Fragmentos de Log (ex.: 09/24) e Dados de Pesquisa (04/12) |
| Centro inferior | Prompt de interação contextual (`[E] ACESSAR TERMINAL`) |
| Legendas | Falas da ÓRBITA e logs da Helena na parte de baixo, com o nome de quem fala. Sempre legendado |

<a id="gdd-2-8-telas"></a>
### Telas

| # | Tela | Conteúdo |
|---|---|---|
| 1 | Tela inicial | Estação girando devagar no escuro, sem música, só ruído de rádio. **CONTINUAR / NOVO SISTEMA / OPÇÕES / ARQUIVO / SAIR** |
| 2 | Opções | Volume (música, efeitos, voz), remapeamento de teclas, tamanho de legenda, modo daltônico, **"modo sem timer"** (desliga a queda do reator) |
| 3 | Pause (ESC) | **RETOMAR / MAPA / ARQUIVO DE LOGS / OPÇÕES / SAIR PARA O MENU**. Congela o timer do reator |
| 4 | Mapa (TAB) | Planta técnica. Setores religados brancos, sem energia cinza, portas seladas com cadeado |
| 5 | Arquivo de Logs (L) | Codex por setor e por autor. Reler um log toca o áudio de novo |
| 6 | Derrota (chassi) | Fundo preto, texto monoespaçado `SINAL DO CHASSI PERDIDO - RESTAURANDO BACKUP` + custo em estabilidade |
| 7 | Game Over (reator) | `PERDA DE ÓRBITA - MISSÃO ENCERRADA` + número de logs que o jogador nunca vai ler. Opção: **CARREGAR ÚLTIMO SETOR** |
| 8 | Vitória | Sem "You Win". Corta no instante da escolha → epílogo em texto (varia com os Dados coletados) → lista dos 40 nomes → estatísticas (tempo, logs, dados, mortes) → *"VOCÊ ESCOLHERIA DE NOVO?"* |

---

<a id="gdd-2-9"></a>
## GDD-2.9 Estética (arte e áudio)

<a id="gdd-2-9-visual"></a>
### Estilo visual

- **Pixel art** em resolução interna **384×216**, escalada por número inteiro para 1920×1080 (pixel nítido, sem borrão).
- Sprites do chassi **32×32 px**. Animação econômica: 4 a 6 frames por ação, com peso e leve atraso, para o MU-7 parecer pesado e velho.
- **Regra de iluminação (pilar visual):** a estação é escura por padrão. A luz não é decoração, é informação. Onde tem luz, tem energia; onde tem energia, algo está funcionando (para o bem ou para o mal). `CanvasModulate` + `Light2D` para a lanterna e as fontes de luz.
- **Direção de arte em uma frase:** *uma estação bonita que ninguém está usando.* Nada de sangue ou monstro; o horror é o cotidiano interrompido — uma caneca flutuando, uma cadeira virada, uma foto colada no armário.

<a id="gdd-2-9-paleta"></a>
### Paleta por setor

| Setor | Paleta |
|---|---|
| Núcleo Central | Azul frio esverdeado, luz estável, quase acolhedor |
| Estufa | Verde musgo + rosa das flores; única área "viva" do jogo |
| Laboratório | Branco clínico virando laranja/vermelho no superaquecimento |
| Enfermaria | Ciano pálido, branco de gelo, sombras longas e azuis |
| Docas | Preto do espaço + amarelo de sinalização de perigo |
| Núcleo de Memória | Explosão de cor saturada e quente que vai dessaturando até o cinza |
| Reator | Vermelho e branco estourado, tela tremendo |

<a id="gdd-2-9-musica"></a>
### Áudio — música

- Ambiente eletrônico minimalista (drones longos, poucos instrumentos).
- **Adaptativa por camadas:** cada setor religado adiciona um instrumento à trilha do Núcleo Central.
- Estabilidade < 25%: entra percussão grave e o ritmo acelera.
- Núcleo de Memória: única trilha com melodia limpa (piano).
- Sala da escolha final: **silêncio absoluto**, só o zumbido do reator.

<a id="gdd-2-9-sfx"></a>
### Áudio — efeitos sonoros

| Evento | Som |
|---|---|
| Passos | Metálico, pesado; muda com o piso (grade, gelo, vidro, terra da estufa) |
| Pulo / aterrissagem | Servo hidráulico + impacto pesado |
| Dash | Pulso magnético curto e agudo |
| Feixe de Manutenção | Chiado elétrico + inimigo desligando com "gemido" descendente (coisa dormindo, não explosão) |
| Coleta de log | Beep suave de arquivo aberto |
| Terminal de energia | Clique de disjuntor + a sala inteira mudando de som |
| Dano | Alarme curto + estática no áudio geral |
| Integridade baixa | Batimento eletrônico lento e constante |
| Lanterna | Clique + zumbido contínuo baixinho |
| Sem gravidade | Todos os sons abafados (low-pass); só o interno do chassi nítido |
| Voz da ÓRBITA | Sintetizada, calma e educada, perdendo a calma conforme o jogo avança |
| Logs da Helena | Áudio degradado, chiado de fita velha e cortes |

---

<a id="gdd-2-10"></a>
## GDD-2.10 Escopo e rastreabilidade de requisitos (documento original)

| Requisito (1º bimestre) | Onde está |
|---|---|
| Plataforma 2D | [GDD-2.2](#gdd-2-2) |
| Movimentação | Andar, pular, dash, escalar, propulsor — [GDD-2.4](#gdd-2-4) |
| Barra de vida | Integridade 100 pts / 4 células — [GDD-2.6.1](#gdd-2-6-1) |
| Timer | Estabilidade do Reator — [GDD-2.5](#gdd-2-5-timer) |

| Requisito (2º bimestre) | Onde está |
|---|---|
| Fases | 6 fases + tutorial — [GDD-2.7](#gdd-2-7) |
| Troca de fases | Hub radial com portas gated por upgrade — [GDD-2.7](#gdd-2-7-mapa) |
| Efeito de status | 5 status — [GDD-2.6.2-F](#gdd-2-6-2-f) |
| Inimigos | 4 tipos + ambientais + mini boss + boss + final — [GDD-2.6.2](#gdd-2-6-2) |
| Tema: Estação | Estação espacial ARTEMIS |
| Clima: Verão/Inverno/Primavera | Laboratório / Enfermaria / Estufa |

<a id="gdd-2-10-cortes"></a>
### Cortes planejados no jogo completo (nesta ordem)

1. Upgrades opcionais (Núcleo de Capacitor / Placa de Blindagem)
2. Música adaptativa por camadas (usar trilha fixa por setor)
3. Mini boss "O Serralheiro"
4. Variação de epílogo por Dados de Pesquisa (manter os 2 finais sem variação)
5. Setor Docas (fundir o Propulsor no Núcleo de Memória)

**NUNCA CORTAR:** o Terminal de Distribuição de Energia. Ele é o jogo.

---

<a id="gdd-p"></a>
## GDD-P Parâmetros numéricos (tuning canônico)

> Fonte única dos números. O código espelha esta tabela **1:1** em `res://scripts/core/balance.gd` (mesmos nomes de constante). Alterou aqui → altere lá → registre em [Ajustes](#gdd-ajustes).

| Constante (`Balance.`) | Valor | Unidade | Origem |
|---|---|---|---|
| `TILE_SIZE` | 16 | px | AJ-001 |
| `INTEGRITY_MAX` | 100 | pts | 2.6.1 |
| `INTEGRITY_CELLS` | 4 | células | 2.6.1 |
| `CHARGE_MAX` | 100 | pts | 2.6.1 |
| `CHARGE_DOCK_REGEN` | 5 | pts/s | 2.6.1 |
| `WALK_SPEED` | 110 | px/s | 2.6.1 |
| `DASH_SPEED` | 320 | px/s | 2.6.1 |
| `DASH_TIME` | 0.25 | s | 2.6.1 |
| `DASH_COST` | 20 | Carga | 2.4 |
| `DASH_COOLDOWN` | 1.0 | s | 2.4 |
| `JUMP_HEIGHT` | 40 | px | AJ-001 (2,5 tiles) |
| `GRAVITY` | 980 | px/s² | 2.6.1 |
| `DOUBLE_JUMP_COST` | 15 | Carga | 2.4 |
| `BEAM_COST` | 25 | Carga | 2.4 |
| `BEAM_SHUTDOWN_TIME` | 4.0 | s | 2.4 |
| `FLASHLIGHT_DRAIN` | 1 | Carga/s | 2.4 |
| `VISION_RADIUS_OFF` | 48 | px | 3 m (AJ-002) |
| `VISION_RADIUS_ON` | 128 | px | 8 m (AJ-002) |
| `REACTOR_START` | 100 | % | 2.5 |
| `REACTOR_DECAY_INTERVAL` | 90 | s por 1% | 2.5 |
| `REACTOR_SECTOR_BONUS` | 15 | % | 2.5 |
| `REACTOR_LOG_BONUS` | 0.5 | % | 2.6.3 |
| `REACTOR_DEATH_PENALTY` | 3 | % | 2.5 |
| `REACTOR_CRITICAL` | 25 | % | 2.8 |
| `RESPAWN_INTEGRITY_RATIO` | 0.5 | fração | 2.5 |
| `SR3_CONTACT_DAMAGE` | 10 | pts | 2.6.2-A |
| `SPORE_DPS` | 5 | pts/s | 2.6.2-D |
| `CORROSION_TIME` | 6.0 | s | 2.6.2-F |
| `STEAM_DAMAGE` | 20 | pts | 2.6.2-E |
| `STEAM_ON_TIME` | 3.0 | s | 2.6.2-E |
| `STEAM_OFF_TIME` | 2.0 | s | 2.6.2-E |
| `ELECTRIC_FLOOR_DPS` | 8 | pts/s | 2.6.2-E |
| `ENERGY_CELL_CHARGE` | 40 | Carga | 2.6.3 |
| `REPAIR_KIT_INTEGRITY` | 25 | pts | 2.6.3 |
| `CAPACITOR_BONUS` | 25 | Carga máx. | 2.6.3 |
| `LOGS_TOTAL` | 24 | un. | 2.6.3 |
| `RESEARCH_TOTAL` | 12 | un. | 2.6.3 |
| `DIFFICULTY_DAMAGE_MULT` | {easy: 0.5, normal: 1.0, hard: 1.5} | fator | AJ-003 |
| `DIFFICULTY_REACTOR_MULT` | {easy: 0.5, normal: 1.0, hard: 1.5} | fator | AJ-003 |
| `RESPAWN_CHARGE_RATIO` | 1.0 | fração | AJ-006 |
| `DOCK_REPAIR_RATE` | 10 | Integridade/s | AJ-006 |
| `INTERACT_RANGE` | 20 | px | AJ-006 |
| `DEATH_DELAY` | 1.2 | s | AJ-006 |
| `SCENE_FADE_TIME` | 0.4 | s | AJ-006 |
| `LOADING_MIN_TIME` | 1.6 | s | AJ-017 |
| AJ-021 | 2026-09-19 | GDD-P | Amplitude e velocidade da flutuação dos coletáveis | O GDD pedia itens "flutuando" sem número |
| AJ-020 | 2026-09-19 | GDD-P | Velocidade de digitação do diálogo, tempo mínimo de fala ambiente, cores e fade das luzes | Números de apresentação que o GDD descrevia em palavras ("legenda", "luz fria") |
| AJ-019 | 2026-09-19 | GDD-P | Ritmo do alarme do reator, duração do aviso do HUD, frequência do pulso crítico e do bipe de integridade baixa | Números de feedback do HUD/áudio que o GDD descrevia só em palavras |
| AJ-018 | 2026-09-19 | GDD-P | Constantes de sensação do plataforma (aceleração/desaceleração no chão e no ar, corte do pulo, velocidade terminal, descida de plataforma fina, deslocamento e velocidade da antecipação da câmera) | Necessárias para o movimento do MU-7 ter peso; o GDD só definia velocidade, gravidade e altura de pulo |
| AJ-017 |
| `SPLASH_TIME` | 2.5 | s | AJ-006 |
| `MUSIC_FADE_TIME` | 1.5 | s | AJ-006 |
| `CAMERA_SMOOTHING` | 5.0 | fator | AJ-006 |
| `CAMERA_LOOK_AHEAD` | 24 | px | AJ-006 |
| `COYOTE_TIME` | 0.12 | s | AJ-006 |
| `JUMP_BUFFER` | 0.12 | s | AJ-006 |
| `INVULNERABLE_TIME` | 0.8 | s | AJ-006 |
| `KNOCKBACK_SPEED` | 140 | px/s | AJ-006 |
| `CLAW_CLIMB_SPEED` | 70 | px/s | AJ-006 |
| `CLAW_JUMP_PUSH` | 90 | px/s | AJ-006 |
| `SPORE_RADIUS` | 24 | px | AJ-006 |
| `SPORE_RADIUS_HEATED` | 48 | px | AJ-006 |
| `SPORE_EXPAND_TIME` | 2.0 | s | AJ-006 |
| `STATUS_EXPOSURE_GRACE` | 0.3 | s | AJ-006 |
| `PLATFORM_SPEED` | 40 | px/s | AJ-006 |
| `PLANT_GROW_TIME` | 2.0 | s | AJ-006 |
| `CAMERA_LOOK_AHEAD_SPEED` | 4.0 | fator | AJ-018 |
| `CAMERA_OFFSET_Y` | -16.0 | px | AJ-018 |
| `JUMP_CUT_MULTIPLIER` | 0.5 | fator | AJ-018 |
| `MAX_FALL_SPEED` | 400.0 | px/s | AJ-018 |
| `WALK_ACCEL` | 900.0 | px/s² | AJ-018 |
| `WALK_DECEL` | 1200.0 | px/s² | AJ-018 |
| `AIR_ACCEL_RATIO` | 0.7 | fator | AJ-018 |
| `DROP_THROUGH_TIME` | 0.2 | s | AJ-018 |
| `REACTOR_ALARM_INTERVAL` | 4.0 | s | AJ-019 |
| `HUD_TOAST_TIME` | 2.0 | s | AJ-019 |
| `HUD_PULSE_HZ` | 2.0 | Hz | AJ-019 |
| `LOW_INTEGRITY_BEEP_INTERVAL` | 1.5 | s | AJ-019 |
| `LIGHT_FADE_TIME` | 0.15 | s | AJ-020 |
| `LAMP_COLOR` | bfe6ff | cor | AJ-020 |
| `FLASHLIGHT_COLOR` | cfeaf2 | cor | AJ-020 |
| `DIALOGUE_CPS` | 40.0 | car/s | AJ-020 |
| `DIALOGUE_READ_CPS` | 15.0 | car/s | AJ-020 |
| `DIALOGUE_AMBIENT_MIN_TIME` | 2.0 | s | AJ-020 |
| `PICKUP_BOB_AMPLITUDE` | 2.0 | px | AJ-021 |
| `PICKUP_BOB_SPEED` | 2.0 | ciclos/s | AJ-021 |
| `SR3_SPEED` | 40 | px/s | AJ-012 |
| `SR3_KNOCKBACK_X` | 120 | px/s | AJ-012 |
| `SR3_KNOCKBACK_Y` | 120 | px/s | AJ-012 |
| `SR3_KNOCKBACK_LOCK` | 0.15 | s | AJ-012 |
| `BEAM_RANGE` | 32 | px | AJ-012 |
| `LAMP_RADIUS` | 96 | px | AJ-012 |
| `LAMP_ENERGY` | 0.9 | fator | AJ-012 |
| `AMBIENT_DARK` | #191D26 | cor | AJ-012 |
| `PLATFORM_WAIT` | 0.6 | s | AJ-012 |
| `SECRET_WALL_FADE_TIME` | 0.3 | s | AJ-012 |
| `SECRET_WALL_ALPHA` | 0.25 | alfa | AJ-012 |
| `SECRETS_TOTAL` | 4 | un. (jogo completo; 1 na demo) | AJ-012 |
| `STEAM_WARN_TIME` | 0.5 | s | AJ-012 |
| `DRONE_SPEED` | 45 | px/s | AJ-012 |
| `DRONE_WANDER_RADIUS` | 64 | px | AJ-012 |
| `DRONE_RETARGET_TIME` | 1.5 | s | AJ-012 |
| `DRONE_FOLLOW_RADIUS` | 120 | px | AJ-012 |
| `OVERHEAT_DPS` | 3 | pts/s | 2.6.2-F (Final) |
| `OVERHEAT_CHARGE_MULT` | 2.0 | fator | 2.6.2-F (Final) |
| `FREEZE_SPEED_MULT` | 0.5 | fator | 2.6.2-F (Final) |
| `FREEZE_JUMP_MULT` | 0.7 | fator | 2.6.2-F (Final) |
| `DISCHARGE_TIME` | 3.0 | s | 2.6.2-F (Final) |
| `OVERLOAD_TIME` | 10.0 | s | 2.6.2-F (Final) |
| `OVERLOAD_SPEED_MULT` | 1.3 | fator | 2.6.2-F (Final) |

<a id="gdd-p-dificuldade"></a>
### Multiplicadores de dificuldade (AJ-003)

| Dificuldade | Dano recebido | Decaimento do reator | Observação |
|---|---|---|---|
| Fácil | ×0,5 | ×0,5 | |
| Normal | ×1,0 | ×1,0 | valores do GDD |
| Difícil | ×1,5 | ×1,5 | |
| Modo sem timer | — | ×0 | opção de acessibilidade ([GDD-2.8](#gdd-2-8-telas)), combinável com qualquer dificuldade |

---

<a id="gdd-ajustes"></a>
## Ajustes de implementação (append-only)

> Toda divergência entre o design original e o jogo implementado. Uma linha por ajuste. Nunca apague; corrija com nova linha.

| ID | Data | Seção | Ajuste | Motivo |
|---|---|---|---|---|
| AJ-001 | 2026-09-19 | 2.6.1 / 2.9 | Tiles de **16 px**; pulo = 2,5 tiles = **40 px** (o original dizia "~64 px") | Consistência com resolução 384×216 e sprite de 32 px (≈ 2 tiles de altura) |
| AJ-002 | 2026-09-19 | 2.4 | 1 m = 16 px; raio de visão 3 m = 48 px, 8 m = 128 px | Conversão de metros para pixels |
| AJ-003 | 2026-09-19 | 2.8 | Adicionada **dificuldade Fácil/Normal/Difícil** além do "modo sem timer" | Critério da disciplina "Dificuldade ajustável" |
| AJ-004 | 2026-09-19 | 2.7 | Demo (1ª entrega) = Fase 0 + Fase 1 jogáveis, terminando numa tela "FIM DA DEMO" | Escopo de 30% da 1ª entrega |
| AJ-005 | 2026-09-19 | 2.2 | Jogo estritamente **2D**; itens de rubrica "3D" e "Elementos de FPS" fora de escopo | Decisão do time |
| AJ-006 | 2026-09-19 | GDD-P | Constantes de implementação que o GDD não especificava (fades, câmera, coyote/buffer, i-frames, doca, esporos, garras, plataforma, planta) fixadas na tabela GDD-P | Números necessários para implementar; ficam versionados num lugar só |
| AJ-007 | 2026-09-19 | 2.6.1 / 2.4 | **Doca de recarga ativa por contato** (não exige apertar E): entra em recarga/reparo ao parar dentro dela | GDD-2.4 lista a doca em `interact`, GDD-2.6.1 fala em "parado numa doca"; contato é mais fluido e evita prompt competindo com terminais |
| AJ-008 | 2026-09-19 | 2.5 | Diálogo tem dois modos: **bloqueante** (congela o timer, exige avançar) e **ambiente/bark** (não congela, some sozinho) | Sem isso qualquer fala da ÓRBITA pausaria o reator e o timer viraria decorativo |
| AJ-009 | 2026-09-19 | 2.5 | Respawn devolve **Carga cheia** e a doca repara 10 Integridade/s; Célula/Kit não são consumidos com o recurso cheio | Casos não previstos no GDD; evitam desperdício e travamento após morte |
| AJ-010 | 2026-09-19 | 2.5-energia | Puzzle da Estufa fixado em **5 sistemas / 2 unidades**; tutorial em 2 sistemas / 1 unidade | GDD dá exemplos diferentes (3/5 e até 6/3); a demo usa a faixa coerente com a curva da Fase 1 |
| AJ-017 | 2026-09-19 | GDD-P | `LOADING_MIN_TIME` de 0,8 s para **1,6 s** | A tela de carregamento mostra os sistemas da estação religando um a um (Jornada etapa 1); em 0,8 s ninguém lê |
| AJ-013 | 2026-09-19 | 2.5 | O **timer do reator só começa a cair no alarme da Fase 0** (Jornada etapa 2), não no carregamento do jogo | O Chamado para a Aventura é o que liga o timer; antes disso o tutorial seria punido |
| AJ-014 | 2026-09-19 | 2.6.1 | Um setor pode ter **vários consoles do mesmo Terminal de Distribuição** (mesmo `terminal_id`) | A Estufa é vertical; obrigar a voltar ao mesmo console viraria backtracking puro |
| AJ-015 | 2026-09-19 | 2.6.2-E | Na **Demo**, cair num buraco no escuro devolve o MU-7 ao andar de baixo em vez de matar | GDD-2.6.2-E diz "mata por queda"; na fase de aprendizado isso pune demais e custa 3% do reator |
| AJ-016 | 2026-09-19 | 2.6.3 | Parede falsa de área secreta fica **translúcida** ao ser revelada, em vez de sumir | O jogador precisa entender que era uma parede, não um bug |
| AJ-012 | 2026-09-19 | GDD-P | Constantes das features de mundo/inimigo/stretch (SR-3, feixe, lâmpada, escuridão ambiente, plataforma, parede secreta, vapor, drone) fixadas no GDD-P | Vieram dos ADRs locais das F22–F34; ficam num lugar só |
| AJ-011 | 2026-09-19 | 2.6.1 | **Garras Magnéticas entregues no meio da Estufa** (log da Helena), e não só ao religar o Nó | Sem isso a habilidade da fase só seria usável depois que a fase acaba; assim ela abre a rota final do setor |
