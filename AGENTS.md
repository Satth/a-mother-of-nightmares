# AGENTS.md — A Mother of Nightmares

## 1. Missão e contexto

Entregar uma build jogável e apresentável de **A Mother of Nightmares**, jogo narrativo de terror psicológico 2D side-scroller, para a Game Jam Caruaru 2026. A meta interna da equipe é **18/10/2026 às 11:00 (horário de Brasília)**; o regulamento informa congelamento/entrega oficial às 12:00. O objetivo é terminar com margem, não usar a margem como extensão de escopo.

A fonte principal de narrativa e mecânicas é `GDD — A Mother of Nightmares.docx`. As regras de produção, assets, IA e entrega vêm de `Regulamento_Game_Jam_Caruaru_2026_v4.pdf`, especialmente itens 10.2, 10.4, 12 e 13 e Anexo III. Em caso de conflito, cumprir o regulamento e avisar o coordenador.

## 2. Prioridades absolutas

1. O projeto abre e a cena principal roda sem erros impeditivos.
2. O jogador completa o fluxo do início ao fim: casa → floresta/ida → cortar 3 árvores → anoitecer/retorno → loop 2 → loop 3 → espírito/final.
3. Os três dias são distinguíveis e o estado não vaza incorretamente de um loop para outro.
4. O final é alcançável e apresenta a imagem/cena final com fade.
5. A build jogável e os materiais de entrega estão prontos antes das 11:00 de 18/10/2026.
6. Assets de terceiros e uso de IA são registrados corretamente e os créditos/declarações ficam prontos para itch.io, pitch e Anexo III.
7. Só depois disso: iluminação extra, parallax avançado, animações adicionais ou polimento não essencial.

## 3. Conformidade com a regra de produção da jam

O regulamento (itens 12.1–12.5) estabelece que a produção do jogo começa no evento, depois da revelação do tema. Ideias, rascunhos e anotações prévios são permitidos; arte, música, efeitos sonoros, roteiro, fases ou mecânicas específicos do jogo já prontos antes do evento não são. Código-base genérico prévio só é permitido nas condições do item 12.2(b), inclusive repositório público anterior ao evento e declaração na entrega.

- Não importar conteúdo específico do jogo produzido antes da revelação do tema.
- Se não estiver claro se algo é uma anotação permitida ou conteúdo pronto proibido, não presumir que está autorizado; sinalizar ao coordenador para verificar com a organização.
- Preservar commits/histórico e não reescrever a história do repositório. A organização pode solicitar o histórico de versões.

## 4. Regra de ouro: auditar antes de editar

**Não presuma que o repositório está vazio nem que o projeto é somente um esqueleto.** Antes de criar ou reescrever sistemas:

- Inspecione `project.godot`, cenas, scripts, autoloads, Input Map, export presets, `git status` e histórico recente.
- Execute o projeto uma vez. Use o Godot MCP disponível para inspecionar a árvore de cenas, iniciar/parar o jogo, capturar screenshots e testar entradas, se as ferramentas fornecidas pelo MCP suportarem essas ações.
- Descubra quais ferramentas o MCP realmente expõe. Não invente nomes de ferramentas nem assuma recursos que não aparecem na lista.
- Registre em poucas linhas o que já funciona, o que quebra e quais arquivos/funcionalidades já existem.
- Confirme no checkpoint de reconhecimento qual foi o tema oficial revelado e identifique uma ligação explícita na narrativa, na mecânica ou na arte. O GDD fornecido não nomeia claramente o tema da jam; não invente nem afirme uma aderência sem verificar. Se a ligação estiver fraca, propor uma alteração pequena ao coordenador.
- Faça o menor conjunto de mudanças possível para chegar ao MVP. Preserve trabalho funcional.

Se o MCP não estiver conectado ou não oferecer uma ação necessária, continue pelo editor/CLI do Godot disponível. Não bloqueie a entrega tentando consertar uma integração auxiliar.

## 5. Escopo fechado do MVP

### Obrigatório

- Godot 4.x; confirmar a versão instalada e respeitá-la. Não atualizar a engine durante a jam.
- Singleplayer 2D lateral.
- Movimento esquerda/direita por `A`/`D` e setas.
- `E` para interagir. Configurar Input Map com ações nomeadas, não espalhar verificações de tecla por diversos scripts.
- Casa: filho presente nos Dias 1 e 2; diálogo curto; pegar machado; sair pela porta.
- Floresta: deslocamento de ida; cortar 3 árvores; mudança visual/estado para anoitecer; retorno para a esquerda.
- Dia 1: caminho quase igual à ida, com ao menos um indício sutil de anormalidade.
- Dia 2: mudança visual clara (tons frios/névoa) e pelo menos um obstáculo/alteração simples, visível e solucionável.
- Dia 3: filho ausente, detalhe da cama/quarto vazio, atmosfera quase monocromática e espírito da esposa bloqueando a progressão.
- Fade entre transições e final com imagem/cena, seguido de opção simples de reiniciar ou encerrar, se viável.
- Estado de jogo consistente ao avançar de dia e ao reiniciar.
- Build testada e publicada na página do jogo do itch.io, além dos créditos e declarações obrigatórios.

### Opcional — não implementar se ameaçar a entrega

- Pulo, corrida, inventário, combate, puzzles, colecionáveis, segredos, diálogos extensos, menus elaborados, save/load, múltiplas rotas e animações numerosas.
- A especificação do GDD permite pulo/corrida opcionais. Não adicione pulo só para tornar um obstáculo mais complexo: prefira uma solução curta e clara, como um galho removível/interativo ou alteração ambiental simples.

## 6. Arquitetura: modular, mas sem engenharia excessiva

Primeiro adapte-se à estrutura que já existe. Se não houver arquitetura equivalente, use como referência — não como obrigação rígida — algo semelhante a:

- `scenes/house_interior.tscn`
- `scenes/forest.tscn`
- `scenes/ending.tscn`
- `scenes/player/player.tscn`
- `scenes/interactables/` para árvore, machado, porta, filho, obstáculo e espírito, conforme necessário
- `scripts/autoload/game_state.gd`
- `scripts/autoload/scene_transition.gd`
- `scripts/player/player_controller.gd`
- `scripts/interactions/` para interação/diálogo
- `assets/art/`, `assets/audio/`, `assets/fonts/`
- `ASSETS_AND_AI.txt` (na raiz para ficar fácil de conferir no prazo)

Módulos recomendados:

- **GameState**: dia atual (1–3), progresso do corte da madeira, machado obtido, filho presente e transição de dia. Centralizar estado persistente entre cenas.
- **SceneTransition**: fade e troca de cena, se a lógica existente não resolver isso.
- **PlayerController**: movimento e animações do protagonista; usar `CharacterBody2D` se isso for compatível com o projeto atual.
- **Interação**: prompt de `E`, alvo/interactuable atual e despacho da ação por sinal/interface simples.
- **DialogueBox**: exibir poucas linhas e avançar com `E`; impedir que a mesma entrada avance o diálogo e acione a interação seguinte no mesmo frame.
- **Direção do loop/floresta**: acionar ida, noite, retorno, variações por dia e evento final.

Não crie um framework genérico, máquina de estados elaborada ou autoload para cada recurso. Evite singletons adicionais sem necessidade. Use sinais e APIs pequenas onde isso diminui acoplamento.

### Contrato de comportamento

- `day` é sempre 1, 2 ou 3; cada retorno bem-sucedido avança apenas um dia.
- Reiniciar uma cena não deve apagar acidentalmente o número do dia; iniciar um novo jogo deve restaurar o estado inicial.
- A madeira coletada é contada por interação com árvores e não pode aumentar infinitamente ao manter `E` pressionado.
- A porta de saída não pode funcionar antes de obter o machado ou concluir a interação de casa, conforme o fluxo implementado.
- O Dia 3 deve terminar no encontro com o espírito, sem exigir completar tarefas impossíveis após ele aparecer.
- Se o jogador ficar sem saída por um bug, a sequência deve ser reproduzível e fácil de diagnosticar.

## 7. Regras de código e recursos Godot

- Respeite convenções e padrões já usados no projeto. Prefira scripts curtos e legíveis, funções com responsabilidade única e nomes claros.
- Conecte sinais de forma consistente e evite conexões duplicadas quando cenas recarregam.
- Prefira `@export` para ajustes de conteúdo úteis (velocidade, linhas de diálogo, caminhos de recursos) em vez de espalhar constantes mágicas.
- Não codifique caminhos de nós frágeis repetidamente; use referências exportadas, filhos estáveis ou grupos quando já fizerem sentido no projeto.
- Mantenha arte substituível: comportamento, colisão e lógica não podem depender do tamanho exato de um sprite placeholder. Ao trocar sprites, confira pivô/offset, escala, frames, hitboxes, collision shapes e pontos de interação.
- Evite instalar add-ons ou dependências novas, salvo se forem indispensáveis e seu uso/licença forem verificados.
- Não edite configuração global do OpenCode, chaves/API, credenciais ou arquivos pessoais do usuário.
- Não sobrescreva cenas ou scripts existentes sem revisar seu conteúdo e confirmar que não elimina trabalho válido.

## 8. Uso do Godot MCP

- Use o MCP para observar o estado real do editor/jogo, não como substituto da revisão de código.
- Antes de mudanças de cena, capture/registre a árvore relevante; depois, salve, execute e confira novamente.
- Depois de mudanças visuais ou de fluxo, use screenshot/playtest via MCP quando suportado.
- Ações de edição no editor podem não salvar recursos automaticamente: confirme que `.tscn`, `.tres` e scripts foram salvos no disco.
- Se o MCP não conseguir simular uma entrada, valide manualmente e documente essa limitação.
- Não exponha um servidor MCP editor para a rede pública; use a configuração local já aprovada.

## 9. Trabalho paralelo e prevenção de conflitos

- O coordenador é dono da integração, do contrato entre módulos, do `PLAN.md`, da build final e do checklist de entrega.
- Cada agente executor recebe uma tarefa pequena, critério de aceite, lista de arquivos sob responsabilidade e dependências.
- Prefira agentes em Git worktrees/branches isoladas, se o Ensemble estiver configurado corretamente.
- Não permita dois agentes alterarem o mesmo arquivo/cena simultaneamente. Reservar `project.godot`, autoloads, cena principal e configuração de export para um único responsável por vez.
- Antes de delegar, o coordenador comunica caminhos de scripts, nomes dos métodos/sinais e o estado compartilhado. Se o contrato mudar, avisa todos antes de integrar.
- Um agente nunca deve assumir que o trabalho de outro já foi mesclado: verificar branch, commit, caminho e arquivos presentes.
- Ao terminar, cada agente informa: resumo, arquivos alterados, comandos/testes executados, resultado, riscos restantes e assets/IA usados.
- Não faça merge cego. Leia o diff, procure conflitos de lógica e execute o fluxo completo depois da integração.

## 10. Assets de terceiros e biblioteca comunitária

O regulamento exige assets gratuitos, open source ou trial **com licença que permita uso comercial**. Um download gratuito ou uma tag de marketplace, isoladamente, não prova isso.

- Registre cada imagem, sprite sheet, tile set, áudio, fonte, plugin, script externo e outro recurso de terceiros utilizado em `ASSETS_AND_AI.txt` assim que entrar no projeto.
- Guarde nome, criador, URL exata da página, licença, evidência/URL da licença, arquivos incorporados, modificações e texto de crédito exigido.
- Preferir CC0 ou uma licença permissiva claramente comercial para reduzir risco e tempo de conferência. CC-BY exige atribuição. Não usar licenças `NC`/“NonCommercial”, conteúdo pago ou licenças desconhecidas.
- Verifique cada asset e a licença do arquivo específico antes de incorporá-lo. A licença geral de um site não substitui a licença da submissão.
- Não use conteúdo protegido reconhecível de jogos/filmes citados como referência visual.
- Não importar pacotes grandes só porque são gratuitos. Prefira poucos assets coerentes e necessários.
- O `ASSETS_AND_AI.txt` não substitui a publicação dos créditos na página do itch.io, os créditos/lista no pitch nem o Anexo III assinado por todos.

Fontes para procurar — sempre verificar a licença do item específico:
- Kenney, packs individuais frequentemente CC0: https://kenney.nl/assets/pixel-pack
- OpenGameArt, licenças e atribuição variam por submissão: https://opengameart.org/content/faq
- Freesound, filtrar e usar apenas CC0 ou CC-BY compatível; nunca CC-BY-NC: https://freesound.org/help/faq/
- itch.io, busca de assets gratuitos marcados como uso comercial; conferir a licença na página de cada item: https://itch.io/game-assets/free/tag-commercial-use/tag-pixel-art
- Godot Asset Library, recursos gratuitos com várias licenças; conferir a licença do add-on/asset: https://docs.godotengine.org/en/stable/community/asset_library/what_is_assetlib.html

## 11. Uso de IA e transparência

O regulamento (item 13 e Anexo III) exige declarar todo conteúdo gerado ou modificado por IA, incluindo código, arte, áudio e texto, e identificar as ferramentas usadas.

- Atualize `ASSETS_AND_AI.txt` durante o trabalho, não no fim de memória.
- Para conteúdo gerado/modificado por IA, registre a ferramenta/serviço e o modelo exato quando conhecido, a categoria e os arquivos/trechos afetados, como foi usado e quem verificou.
- Registre também scripts/código sugeridos ou substancialmente modificados por agentes de IA. Não marque “não usou IA” se houve uso.
- Se a equipe usar OpenCode, OpenRouter, Godot MCP ou outras ferramentas, diferencie a ferramenta de orquestração/editor do modelo generativo que produziu o conteúdo. Informe precisamente o que souber; não invente modelos ou licenças.
- Antes de enviar, copiar os dados do registro para a página do jogo, pitch e Anexo III, com revisão humana e assinatura de todos os integrantes.

## 12. Testes e definição de pronto

Um recurso só está pronto quando:

- A cena/script abre sem erro de parsing ou referência quebrada.
- A interação é testada dentro do jogo, não só pela leitura do código.
- O comportamento funciona com teclado e não depende de uma condição acidental do editor.
- O recurso continua funcionando após reload/troca de cena relevante.
- Não introduz regressão no fluxo anterior.
- O teste/limitação é registrado no resultado da tarefa.

Checklist de smoke test obrigatório:

1. Iniciar jogo e mover para os dois lados.
2. Falar com o filho, obter o machado e sair de casa.
3. Cortar exatamente 3 árvores e provocar o anoitecer.
4. Voltar à esquerda e concluir o retorno do Dia 1.
5. Confirmar Dia 2, variação visual/obstáculo e filho ainda presente.
6. Concluir o Dia 2 e confirmar Dia 3.
7. Confirmar a ausência do filho e o quarto/cama vazios.
8. Encontrar o espírito, bloquear a passagem e alcançar o final com fade.
9. Reiniciar uma vez e confirmar que o estado volta ao inicial.
10. Conferir áudio, resolução, prompt/diálogos e ausência de erro impeditivo.
11. Exportar e abrir a build exportada; não considerar suficiente apenas a execução no editor.

## 13. Critério para cortar escopo

Se uma implementação arriscar quebrar o fluxo completo ou a entrega, substituí-la por uma versão visual/funcional mais simples. Prioridade é **fim a fim estável**, não quantidade de sistemas. Não iniciar funcionalidade opcional depois do congelamento interno da release candidate.
