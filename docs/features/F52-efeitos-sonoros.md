---
id: F52
title: Efeitos sonoros definitivos
status: done
scope: demo
block: 6
priority: P1
rubric: ["Efeitos visuais/sonoros"]
depends_on: ["F04"]
unblocks: []
estimate: 2h
last_updated: 2026-09-20
---

# F52 — Efeitos sonoros definitivos

## 1. Contexto e objetivo

Desde a [F04](F04-audio-volume.md) o jogo toca efeito sonoro por nome
(`AudioManager.play_sfx(&"jump")`), mas **todos** os sons eram placeholders sintéticos gerados
por `tools/make_audio_placeholders.gd`: senoides e rajadas de ruído na amplitude certa, sem
nenhuma textura. O jogo inteiro — passo, porta, disjuntor, coleta, dano, religamento — soava
como um sintetizador de laboratório.

Esta feature integra o pacote **Kenney Sci-Fi Sounds (CC0)** entregue pelo humano: 23 dos 29
nomes de efeito que o código realmente toca passam a apontar para um arquivo definitivo, com
variações sorteadas onde elas fazem diferença (passo, porta, coleta) e com **volume relativo
medido e normalizado**, para que passo não estoure e alarme não suma. Os 6 nomes sem par
honesto no pacote continuam placeholder — som errado é pior que som sintético.

## 2. Referências de design (ler ANTES de codar)

- **GDD:** [GDD-2.9 — SFX](../design/GDD.md#gdd-2-9-sfx) (tabela evento → efeito)
- **Parâmetros:** nenhum novo; o ganho é assado no arquivo, não em constante de código
- **ADRs:** [ADR-005](../DECISIONS.md#adr-005) (placeholder-first), regra dura 10 (licença)
- **Assets:** ficha **SFX-PACK** em [`ASSETS.md`](../ASSETS.md#sfx-pack)

## 3. Critério de avaliação atendido

Rubrica **"Efeitos visuais/sonoros"**: na apresentação, cada ação do MU-7 tem resposta sonora
com textura real — passo metálico com três variações, comporta pneumática abrindo e fechando,
estalo elétrico do disjuntor, varredura ascendente ao religar um sistema e descendente ao
cortar, estouro grave ao perder o chassi, gemido descendente da SR-3 desligando.

## 4. Escopo

### Inclui
- 31 arquivos `.wav` definitivos em `assets/audio/sfx/`, cortados, com fade e normalizados.
- Grupos de variação: `step_metal_1..3`, `door_open_1..3`, `door_close_1..3`, `pickup_1..2`.
- Correção na resolução de efeito do `AudioManager`: grupo definitivo vence placeholder.
- Suíte `tests/test_audio_sfx.gd` (10 testes) e roteiro `tests/qa/f52_sfx.json`.

### Não inclui
- `docs/ASSETS.md` (a ficha SFX-PACK e a licença são registradas pelo humano).
- Os 6 efeitos sem par no pacote (seção 7) — seguem placeholder.
- `beam`, `dash`, `electric_buzz`, `steam_hiss`: ainda não são tocados por código (F31/F32).

## 5. Critérios de aceite

- [x] Todo nome de efeito que o código toca resolve para algum arquivo (nenhum silêncio).
- [x] Os 23 nomes integrados resolvem para `res://assets/audio/sfx/`, nunca para o placeholder.
- [x] Os grupos de variação são encontrados e sorteados (3/3/3/2).
- [x] Portões do `/CLAUDE.md` §6 verdes (import, 668 testes, smoke de 76 cenas, varreduras).
- [x] Sem comentários no código; nada 3D.

## 6. Definição técnica

### Cenas e scripts
```
autoload/audio_manager.gd      _streams_for / _load_sfx_group / _sfx_path_in
assets/audio/sfx/*.wav         31 arquivos definitivos (+ .import)
tests/test_audio_sfx.gd        suíte de cobertura sonora
tests/qa/f52_sfx.json          roteiro de gameplay curto
```

A resolução de efeito passou a ser **por grupo, não por arquivo**. Antes, `_streams_for` pedia o
caminho direto (`pickup`) e, como o placeholder `pickup.wav` existia, parava ali — as variações
definitivas `pickup_1/2` nunca eram vistas. Agora procura o grupo inteiro (direto **ou**
variações) primeiro em `assets/audio/sfx/` e só cai para `assets/placeholder/audio/sfx/` se o
definitivo não existir. Mesma história para `door_open` e `door_close`.

### Autoloads / sinais do EventBus
Nenhum sinal novo. `AudioManager.play_sfx` e o bus **SFX** (volume do jogador nas Opções)
continuam iguais.

### Dados (`data/`)
Nenhum. Os nomes de efeito já vinham de `data/dialogue/*.json` (campo `sfx`) e de
`data/levels/*.json` (campo `floor_sfx`); os dois casos entraram nos testes.

## 7. Assets

**Origem:** Kenney — *Sci-Fi Sounds (1.0)*, https://kenney.nl — 74 `.ogg`, entregue pelo humano.
**Licença:** CC0 1.0 (`License.txt` do pacote: *"License: (Creative Commons Zero, CC0)"*).
Crédito não obrigatório; entra no `README.md` por cortesia.

### Efeito → arquivo do pacote

| Efeito do jogo | Fonte no pacote | Corte | RMS final |
|---|---|---|---|
| `step_metal_1/2/3` | `impactMetal_003/004/002` | 0,25 s | −28 dB |
| `land` | `impactMetal_001` | 0,45 s | −23,8 dB |
| `claw_grab` | `impactMetal_000` | 0,30 s | −27 dB |
| `door_open_1/2/3` | `doorOpen_000/001/002` | 0,53 s | −24 dB |
| `door_close_1/2/3` | `doorClose_000/001/002` | 0,53 s | −24 dB |
| `power_on` | `laserLarge_001` (varredura ascendente) | 0,55 s | −24 dB |
| `power_off` | `laserSmall_002` (varredura descendente) | 0,34 s | −24 dB |
| `terminal_breaker` | `forceField_003` (estalo elétrico) | 0,28 s | −25 dB |
| `sector_restored` | `forceField_002` | 0,90 s | −21 dB |
| `respawn` | `forceField_001` | 0,90 s | −22 dB |
| `interact` | `laserRetro_002` | 0,26 s | −25 dB |
| `ui_confirm` | `laserRetro_000` | 0,18 s | −23 dB |
| `ui_move` | `laserSmall_000` | 0,14 s | −27 dB |
| `ui_back` | `laserSmall_001` | 0,24 s | −24 dB |
| `ui_error` | `laserSmall_004` | 0,30 s | −24 dB |
| `pickup_1/2` | `laserRetro_003/004` | 0,20 s | −23 dB |
| `log_pickup` | `laserRetro_001` | 0,24 s | −23 dB |
| `secret_found` | `laserLarge_004` | 0,60 s | −22 dB |
| `jump` | `thrusterFire_001` (0,50–0,75 s) | 0,25 s | −24 dB |
| `damage` | `explosionCrunch_000` | 0,55 s | −22 dB |
| `chassis_lost` | `lowFrequency_explosion_000` | 1,60 s | −21 dB |
| `sr3_shutdown` | `spaceEngineLow_003` + queda de tom | 1,66 s | −22 dB |
| `plant_grow` | `slime_000` | 0,50 s | −27 dB |
| `spores` | `slime_001` (0,30–4,30 s, loop) | 4,00 s | −28 dB |

### Ainda placeholder (o pacote não tem par honesto)

| Efeito | Por que não entrou | Sugestão |
|---|---|---|
| `reactor_alarm` | pacote não tem alarme; usar zumbido no lugar mentiria sobre o perigo | Freesound "alarm loop" CC0 |
| `low_integrity` | precisa de batimento eletrônico pulsante | Freesound "heartbeat electronic" CC0 |
| `tape_hiss` | o chiado de fita da Helena não existe num pacote sci-fi | Freesound "tape hiss" CC0 |
| `dialogue_blip` | toca a cada 3 caracteres; nada no pacote é curto o bastante (mínimo 0,24 s) | Kenney Interface Sounds |
| `flashlight` | clique mecânico curto; o que existe é impacto metálico com cauda | Kenney Interface Sounds |
| `step_soil` | passo em terra; nada orgânico-seco no pacote | Kenney Impact Sounds |

## 8. 🧑 Ação humana

Nenhuma para a feature funcionar. **Pendências do humano:** registrar a ficha SFX-PACK no
`docs/ASSETS.md` com a licença acima e citar Kenney nos créditos do `README.md`.

## 9. Plano de execução

- [x] **Passo 1** — descompactar o pacote fora do repo e confirmar licença (CC0, Kenney).
- [x] **Passo 2** — varrer o código e levantar os 29 nomes realmente tocados.
- [x] **Passo 3** — medir pico e RMS dos 74 arquivos; casar evento → som pela textura medida
  (duração, envelope e direção de tom) e pelo contexto de uso.
- [x] **Passo 4** — cortar, aplicar fade e normalizar por RMS com teto no percentil 99,9.
- [x] **Passo 5** — corrigir a resolução por grupo no `AudioManager`.
- [x] **Passo 6** — testes, portões e QA de gameplay.

## 10. Verificação

- **Testes:** `tests/test_audio_sfx.gd` — os 29 nomes tocados têm som; os 23 integrados vêm do
  caminho definitivo; os 6 pendentes vêm do placeholder (documenta a dívida e quebra quando
  alguém "resolver" com o arquivo errado); grupos de variação com contagem exata; nenhum stream
  de duração zero; nomes vindos de `PickupRules`, dos diálogos e do `floor_sfx` das fases;
  `spores` resolve para um `AudioStreamWAV` (o enxame precisa de WAV para entrar em loop).
- **Smoke:** nenhuma cena nova; 76 cenas seguem carregando sem erro.
- **Roteiro godot-qa:** `tests/qa/f52_sfx.json` no `core_hub` — passa a fala de abertura
  (`dialogue_blip` + `power_on`), anda, pula, interage e liga a lanterna. O log da execução não
  pode conter `efeito sonoro ausente`.

## 11. ADRs locais

### ADR-F52-001 — Normalizar por RMS com teto de percentil, e não por pico
- **Contexto:** o pacote chega com **todos** os arquivos em pico ≈ −1 dBFS, mas com RMS de
  −5,3 dB (motores) a −26,4 dB (slime): 21 dB de diferença de volume percebido. Normalizar por
  pico não muda nada; passo e alarme continuariam desalinhados.
- **Decisão:** normalizar cada arquivo por **RMS** para um alvo por categoria (passo −28 dB, UI
  −23 a −27 dB, evento de mundo −24 dB, momento dramático −21 dB), limitando o ganho para que o
  **percentil 99,9** não passe de −5,2 dB e aplicando `tanh` suave em 0,92 para os transientes
  isolados. Sem isso, um único estalo de 0,9 no `slime` puxaria o arquivo inteiro para 8 dB
  abaixo do alvo.
- **Consequências:** o volume é assado no arquivo, não numa tabela de ganho em código — vale
  também para quem carrega o `.wav` por caminho direto (`spore_swarm`). Os placeholders que
  sobraram (pico −13 dB, RMS −22 a −28 dB) continuam coerentes com os novos.
- **Data:** 2026-09-20

### ADR-F52-002 — Arquivo `.wav` em vez de `.ogg`
- **Contexto:** o pacote é `.ogg`, e `.ogg` é o formato preferido do projeto. Mas todo arquivo
  precisou de corte, fade e ganho, e a máquina não tem codificador Vorbis (`ffmpeg`/`oggenc`
  ausentes; o `afconvert` do macOS decodifica Ogg mas não o escreve).
- **Decisão:** entregar `.wav` 44,1 kHz mono 16 bits — extensão já suportada pelo
  `AudioManager.EXTENSIONS` e pelo `AssetResolver`. Total de 1,6 MB para 31 efeitos.
- **Consequências:** `scenes/enemies/spore_swarm.gd` (que exige `AudioStreamWAV` para forçar
  `LOOP_FORWARD`) e `scenes/ui/options_menu.gd` (que aponta para `ui_confirm.wav`) continuam
  funcionando sem mudança. Se um dia o pacote definitivo vier em `.ogg`, os dois caminhos
  precisam de uma olhada.
- **Data:** 2026-09-20

### ADR-F52-003 — Grupo definitivo vence placeholder direto
- **Contexto:** `_streams_for` procurava primeiro o arquivo direto (`pickup`) nos dois diretórios
  e só tentava variações se **nenhum** dos dois existisse. Com `pickup.wav` no placeholder, as
  variações definitivas `pickup_1/2` ficavam invisíveis — a feature teria entregue arquivo novo
  e som velho, sem nenhum erro no console.
- **Decisão:** procurar o **grupo inteiro** (direto, senão variações) primeiro no diretório
  definitivo e só então no de placeholder.
- **Consequências:** o teste `test_integrated_sfx_use_the_final_file_not_the_placeholder` trava
  essa regra. `tests/test_asset_resolver.gd` teve de trocar o exemplo de fallback (usava
  `ui_confirm.ogg`, que agora é definitivo) para `steam_hiss.ogg`, que segue placeholder.
- **Data:** 2026-09-20

## 12. Log de evolução

### 2026-09-20 — Feature implementada
- **Quem**: agente SFX · **O que**: pacote Kenney Sci-Fi Sounds (CC0) integrado — 31 arquivos
  definitivos cobrindo 23 dos 29 nomes tocados pelo jogo, com variações de passo, porta e
  coleta, volume normalizado por RMS, resolução por grupo no `AudioManager`, 10 testes novos e
  roteiro de QA de gameplay. · **Próximo passo**: humano registra a ficha SFX-PACK no
  `ASSETS.md` (licença CC0/Kenney) e busca os 6 efeitos que faltam na tabela da seção 7.
