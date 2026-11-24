# GLOSSARY.md — Termos do jogo

> Use estes termos **exatamente assim** na UI e nos textos. Código usa o identificador em inglês da coluna "Código".

| Termo (UI) | Código | Definição |
|---|---|---|
| **ÓRBITA** | `orbita` | A IA de manutenção protagonista |
| **MU-7** | `mu7` | Chassi de manutenção bípede que ÓRBITA controla (o personagem jogável) |
| **ARTEMIS** | — | A estação espacial de pesquisa (tema "Estação") |
| **Integridade** | `integrity` | Vida do chassi (100, em 4 células) |
| **Carga** | `charge` | Energia/stamina do chassi; gasta em lanterna, dash, feixe; só recarrega na doca ou com Célula |
| **Estabilidade do Reator** | `reactor_percent` | Timer global em %; cai com o tempo; 0% = Perda de Órbita |
| **Terminal de Distribuição** | `distribution_terminal` | Onde o jogador move unidades de energia entre sistemas do setor (puzzle) |
| **Sistema** | `system` | Algo que consome energia no setor (luz, porta, aquecimento, plataforma…) |
| **Orçamento de energia** | `budget` | Quantas unidades o setor tem para distribuir |
| **Nó do setor** | `sector_node` | Ponto final do setor; religá-lo restaura o setor (+15% reator, upgrade) |
| **Doca de Backup** | `backup_dock` | Checkpoint: recarrega Carga, repara, salva o jogo |
| **Fragmento de Log** | `log` | Gravação/texto narrativo coletável (24 no jogo) |
| **Dado de Pesquisa** | `research` | Coletável opcional sobre o planeta alvo (12 no jogo); muda o epílogo |
| **Célula de Energia** | `energy_cell` | +40 Carga |
| **Kit de Solda** | `repair_kit` | +25 Integridade |
| **Núcleo de Capacitor** | `capacitor` | +25 Carga máxima permanente (escondido) |
| **Placa de Blindagem** | `armor_plate` | +25 Integridade máxima permanente (Final) |
| **Lanterna** | `flashlight` | Luz do chassi; amplia a visão, drena Carga |
| **Garras Magnéticas** | `magnetic_claws` | Upgrade da Estufa: escalar paredes metálicas marcadas |
| **Dash magnético** | `dash` | Arrancada horizontal (20 Carga) |
| **Feixe de Manutenção** | `beam` | Desliga máquinas por 4 s (25 Carga); não destrói |
| **Desligamento** | `shutdown` | Estado de inimigo atingido pelo Feixe |
| **Corrosão** | `corrosion` | Status: impede recarga de Carga por 6 s (esporos) |
| **Superaquecimento** | `overheat` | Status do Verão: −3 Integridade/s e Carga drena 2× (zona de calor) |
| **Descarga** | `discharge` | Status elétrico (pulso da CX-2): bloqueia as garras por 3 s (AJ-040) |
| **Congelamento / Sobrecarga** | `freeze` / `overload` | Demais status (Final) |
| **Dissipador Térmico** | `heat_sink` | Upgrade do Laboratório: −70% de dano de calor |
| **Torre Calibradora CX-2** | `cx2` | Inimigo do Laboratório: varre um cone e dispara pulso; vence-se no Terminal |
| **Zona de calor / Fornalha** | `heat_zone` (`warm` / `furnace`) | Área do Verão que aplica Superaquecimento; a fornalha soma 12/s |
| **Ilha fria** | `cold_island` | Área ligada à refrigeração que anula o calor dentro dela |
| **Jato de vapor** | `steam_vent` | Obstáculo cíclico (3 s ligado / 2 s desligado, 20 de dano) |
| **Laboratório** | `lab` | Fase 2 (Verão) |
| **Sentinela Voadora V-9** | `v9` | Inimigo da Enfermaria: vê o MU-7 iluminado, ouve o dash, persegue atravessando o cenário e gruda drenando Carga |
| **Núcleo Aquecido** | `heated_core` | Upgrade da Enfermaria: imune a Congelamento; derrete parede de gelo por contato |
| **Gelo fino** | `thin_ice` | Plataforma que racha ao ser pisada, cai em 0,5 s e se refaz |
| **Parede de gelo** | `ice_wall` | Bloqueio que derrete com o aquecedor ligado (e recongela) ou com o Núcleo Aquecido |
| **Aquecedor** | `cold_island` (`kind: warm`) | Área ligada ao aquecimento que anula o frio |
| **Enfermaria** | `infirmary` | Fase 3 (Inverno) |
| **SR-3 "Aranha de Reparo"** | `sr3` | Primeiro inimigo; patrulha e vira na borda |
| **Enxame de Esporos** | `spore_swarm` | Nuvem que cresce com calor; causa Corrosão |
| **BOTÂNICO 04** | `botanico` | Drone de irrigação aliado da Estufa |
| **Dra. Helena Vasquez** | `helena` | Engenheira Chefe; mentora em logs, com retrato de 6 expressões ([AJ-079](design/GDD.md#gdd-ajustes)) |
| **Núcleo Central** | `core` | Hub e tutorial (Fase 0) |
| **Estufa** | `greenhouse` | Fase 1 (Primavera) |
| **Setor Habitacional** | `habitation` | Corredor de transição onde está o primeiro corpo |
| **Chassi perdido** | `chassis_lost` | Tela de morte: `SINAL DO CHASSI PERDIDO - RESTAURANDO BACKUP` |
| **Perda de Órbita** | `game_over` | Game Over por reator 0%: `PERDA DE ÓRBITA - MISSÃO ENCERRADA` |
| **Novo Sistema** | `new_game` | "Novo jogo" no menu inicial |
