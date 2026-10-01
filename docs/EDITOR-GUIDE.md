# EDITOR-GUIDE.md — Godot para quem nunca abriu o Godot

> O agente faz quase tudo por arquivo. Este guia serve para o humano (1) testar o jogo e (2) executar os raros passos no editor.

---

## 1. Abrir o jogo e o editor

| Quero… | Como |
|---|---|
| **Jogar** a versão atual | No terminal do Claude Code: `! "$GODOT" --path /Users/BRScurPaEr/code/fag/jogo` — ou peça ao agente "rode o jogo" |
| **Abrir o editor** | Dê dois cliques em `~/Downloads/Godot.app` → na lista de projetos clique em **jogo** → **Editar** (ou **Import** → escolha a pasta `/Users/BRScurPaEr/code/fag/jogo` → arquivo `project.godot`) |
| Rodar o jogo dentro do editor | Tecla **F5** (ou botão ▶ no canto superior direito) |
| Rodar só a cena aberta | Tecla **F6** |
| Parar o jogo | **F8** ou feche a janela do jogo |
| Ver erros | Painel **Output** / **Debugger** na parte de baixo do editor. Copie o texto vermelho e cole para o agente |

> Dica: se o macOS bloquear o Godot ("desenvolvedor não identificado"), clique com o **botão direito** no `Godot.app` → **Abrir** → **Abrir**. Opcional: arraste o `Godot.app` para **Aplicativos** e avise o agente para atualizar o caminho.

## 2. Mapa do editor (Godot 4)

```
+------------------------------------------------------------------+
| Menu: Scene  Project  Debug  Editor  Help      [2D][3D][Script] ▶ |
+-----------+------------------------------------------+-----------+
| Scene     |                                          | Inspector |
| (árvore   |        Viewport (a cena)                 | (proprie- |
|  de nós)  |                                          |  dades do |
+-----------+                                          |  nó sele- |
| FileSystem|                                          |  cionado) |
| (res://)  +------------------------------------------+           |
|           | Output | Debugger | Audio | Animation    |           |
+-----------+------------------------------------------+-----------+
```

- **Scene** (esquerda, em cima): os nós da cena aberta.
- **FileSystem** (esquerda, embaixo): os arquivos do projeto (`res://`).
- **Inspector** (direita): propriedades do que está selecionado.
- **Output** (embaixo): mensagens e erros.
- Ignore a aba **3D** — o jogo é 2D.

## 3. Coisas que só o editor faz (lista curta)

| Ação | Feature | Frequência |
|---|---|---|
| Instalar **Export Templates** 4.7.2 | [F30](features/F30-build-demo.md) | 1 vez |
| Playtest e opinião de "sensação" | todas | sempre que quiser |

Todo o resto (Input Map, autoloads, cenas, tilesets, áudio, export presets) o agente escreve nos arquivos.

---

<a id="formato-acao-humana"></a>
## 4. Formato do bloco 🧑 AÇÃO HUMANA (para agentes)

Todo passo que o humano precisa executar é escrito assim, na seção 8 da feature **e** na resposta ao humano:

```markdown
> 🧑 **AÇÃO HUMANA — <título curto>** (≈ N min)
> **Por quê:** <1 linha: por que o agente não consegue fazer sozinho>
> 1. <ação atômica com o nome EXATO do menu/botão/campo, entre aspas ou em negrito>
> 2. <…> — valor a digitar: `<valor>`
> 3. <…>
> **Pronto quando:** <o que o humano deve ver na tela para saber que deu certo>
> **Avise o agente com:** "<frase exata>"
> **Se der errado:** <o erro mais provável e o que fazer / copiar o Output para o agente>
```

Regras:
- Um clique por passo. Nome de menu exatamente como aparece no editor em inglês (o editor vem em inglês por padrão; se o humano trocar para português, forneça os dois).
- Nunca "configure X" genérico — diga **onde** clicar e **o que** digitar.
- Sempre termine com como verificar e com a frase para avisar o agente.
- Depois do aviso, o agente **confere por arquivo/CLI** que o efeito aconteceu.

### Exemplo

> 🧑 **AÇÃO HUMANA — Instalar os templates de exportação** (≈ 5 min)
> **Por quê:** o download dos templates é feito pelo editor.
> 1. Abra o editor (seção 1 deste guia).
> 2. Menu **Editor** → **Manage Export Templates…**
> 3. Clique em **Download and Install** e espere a barra chegar ao fim (~1 GB).
> 4. Feche a janela.
> **Pronto quando:** a janela mostra "Current Version: 4.7.2.stable" com status **Installed**.
> **Avise o agente com:** "templates instalados"
> **Se der errado:** se o download falhar, clique em **Download from:** → escolha outro espelho e tente de novo.
