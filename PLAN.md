# PLAN.md — A Mother of Nightmares

**Prazo interno:** domingo, 18/10/2026, 11:00 BRT.  
**Prazo oficial do regulamento:** domingo, 18/10/2026, 12:00, congelamento/entrega da build (item 10.2).  
**Último marco obrigatório antes da entrega:** playtest cruzado às 10:30; jogar pelo menos 2 jogos de outras equipes e registrar 3 observações (item 10.2).  
**GDD:** `GDD — A Mother of Nightmares.docx`.  
**Regulamento:** `Regulamento_Game_Jam_Caruaru_2026_v4.pdf`.

> Plano de recuperação para a última noite. Primeiro auditar e preservar o que já existe. Os horários são limites de decisão, não convites para aumentar o escopo. Se o projeto já cumprir uma tarefa, testar e marcá-la como concluída em vez de reimplementá-la.

## 1. Decisão de produto

Entregar uma experiência de terror 2D de aproximadamente 5–8 minutos em três loops narrativos. A prioridade é controle responsivo, interação compreensível, mudança de atmosfera entre os dias e final alcançável. O visual deve parecer intencional, mas não pode colocar a estabilidade em risco. O critério de avaliação dá peso à jogabilidade/diversão (2,0), criatividade/inovação (2,0), aderência ao tema (1,5), execução técnica (1,5), arte/áudio (1,5) e pitch/modelo de negócio (1,5).

### O que significa “o esqueleto está pronto”

A hipótese de que “agora é só mudar os sprites” é parcialmente correta: se o loop, as interações, os estados e as transições já estão implementados e testados, a arte pode ser trocada de forma relativamente localizada. Mas trocar sprites não é necessariamente trivial: tamanho, pivô/offset, escala, frames de animação, collision shapes, anchors e pontos de interação podem mudar o gameplay. Portanto, não alterar arte em massa antes de confirmar a jornada completa com placeholders.

**Gate de entrada:** nos primeiros 20 minutos, executar o jogo e preencher um diagnóstico real. Não recriar sistemas já funcionais.

## 2. Resultado mínimo de entrega (MVP)

### Fluxo do jogador

1. **Casa / manhã:** o protagonista começa em casa. Dias 1 e 2: o filho está presente e há 2–3 linhas de diálogo. Interagir para pegar o machado e sair pela porta.
2. **Floresta / ida:** andar para a direita, interagir com árvores e cortar 3 unidades de madeira. Não permitir que uma árvore conte várias vezes por segurar E.
3. **Anoitecer:** trigger visual/sonoro simples muda a direção/objetivo para a volta.
4. **Retorno do Dia 1:** o caminho é quase o mesmo, com pelo menos um sinal sutil de que algo mudou. Retornar à porta e transicionar com fade.
5. **Dia 2:** paleta mais fria/dessaturada, névoa ou vinheta e ao menos uma alteração/obstrução solucionável, sem criar um puzzle longo. O filho ainda aparece em casa.
6. **Dia 3:** o filho não aparece; quarto/cama vazios. Paleta quase monocromática e o espírito da esposa surge e bloqueia o caminho.
7. **Final:** o encontro com o espírito aciona uma sequência visual/imagem final e fade. Oferecer reinício simples se for seguro e rápido.

### Controles

- `A`/`D` ou setas: mover.
- `E`: interagir / avançar diálogo.
- Pulo e corrida são opcionais no GDD. Excluir do escopo inicial. O obstáculo do Dia 2 pode usar interação simples para remover/desviar, desde que a leitura visual seja clara.

### Itens deliberadamente fora do escopo

Combate, inventário, segredos, colecionáveis, múltiplos finais, menu sofisticado, save/load, diálogos longos, sistema de quests, arte frame-a-frame extensa, refatoração ampla, nova engine, add-ons de grande porte. Não construir “o jogo definitivo” em uma jam de 48 horas.

## 3. Plano técnico modular

Primeiro mapear o código existente. O desenho abaixo é a arquitetura-alvo só se ainda não houver módulos equivalentes:

- **GameState (autoload):** `day`, progresso da madeira, machado obtido, presença do filho; avançar/resetar estados com funções explícitas.
- **SceneTransition (autoload, se necessário):** fade + troca de cena; garantir que o estado persistente não seja apagado por uma simples troca de cena.
- **Player:** movimento e animação separados da lógica de narrativa.
- **Interação:** um mecanismo comum de alvo/interação e prompt E; árvore/porta/filho/obstáculo/espírito implementam ações simples.
- **DialogueBox:** exibição e avanço de poucas linhas; bloquear input duplicado na mesma interação.
- **Forest/Loop Director:** acionar ida, anoitecer, retorno, variações dos Dias 1–3 e final.
- **Cenas principais:** casa interior, floresta e final; reutilizar cena com variações por dia quando isso evitar duplicação.
- **Arte e áudio:** armazenados separadamente da lógica; trocar placeholder sem reescrever sistemas.

Evitar abstrações desnecessárias. Só manter módulos separados se isso facilitar teste, trabalho paralelo ou substituição de conteúdo.

## 4. Distribuição dos agentes

O coordenador deve primeiro fazer o diagnóstico e acordar o contrato entre módulos. Depois, delegar em worktrees/branches isoladas quando o Ensemble estiver realmente usando isolamento Git. Não permitir que dois agentes alterem a mesma cena/script ao mesmo tempo.

### Agente coordenador / integrador

**Responsável por:** auditar o projeto, fechar escopo, definir contratos simples, manter este plano, evitar conflitos, integrar PRs/diffs, testar jornada completa, exportar e publicar a versão final.

**Não delegar:** decisão final de escopo, alterações concorrentes em `project.godot`/autoload principal, release final e checklist de submissão.

**Saída:** diagnóstico inicial; contrato de API/arquivos; release candidate; build testada; checklist final.

### Agente A — Gameplay / controles / interação

**Só começar após o diagnóstico e contrato do coordenador.**

**Escopo:** corrigir ou finalizar jogador, movimento, Input Map, prompt `E`, interações reutilizáveis, pegar machado e contagem de 3 árvores. Não alterar o sistema central de dia/cenas sem combinar com o coordenador.

**Aceite:** movimento responde; prompt fica coerente; cada árvore conta uma vez; o machado e a porta seguem o fluxo definido; nenhum erro novo no console.

### Agente B — Estado / loops / narrativa

**Só começar quando o coordenador definir a API de `GameState` e transições.**

**Escopo:** fluxo dos três dias, retorno/transição, variação do Dia 2, ausência do filho no Dia 3, encontro com espírito e final. Não editar o controlador principal do jogador se o Agente A já estiver nele.

**Aceite:** uma jornada reproduzível do Dia 1 até o final; dias não são pulados nem reiniciam indevidamente; o estado persiste entre cenas e reinicia corretamente num novo jogo.

### Agente C — Arte / atmosfera / rastreabilidade de assets

**Escopo:** encontrar poucos assets coesos e adequados ao jogo, verificar licença comercial por item, registrar tudo em `ASSETS_AND_AI.txt` e importar em pastas sem alterar lógica ou cenas principais sem coordenação. Pode preparar variantes de paleta, névoa, silhuetas, parallax simples e sons essenciais.

**Aceite:** cada recurso de terceiros tem criador, URL de origem, licença verificada e crédito; placeholders não foram quebrados; visual dos Dias 1–3 é distinto; assets sem licença clara ficam de fora.

### Agente D — QA / build (ativar depois da primeira integração jogável)

**Escopo inicial:** descobrir versão do Godot, preset de export existente e alvo que realmente funciona; verificar como abrir a build fora do editor. Depois, executar o checklist de smoke test e registrar bloqueios. Só editar gameplay com autorização do coordenador.

**Aceite:** build exportada abre numa máquina/ambiente de teste; jornada completa reproduzida; erros críticos listados e corrigidos antes da release candidate.

### Limite de paralelismo

Usar 2–3 agentes ativos de código por vez, mais coordenador. Agente de arte/assets pode atuar em paralelo em arquivos próprios. Se a equipe não tiver múltiplos workers realmente isolados, preferir tarefas sequenciais em vez de compartilhar os mesmos arquivos ao vivo.

## 5. Ordem de execução e cronograma limite (BRT)

### Bloco 0 — Reconhecimento e baseline (19:57–20:15, sábado)

- Conferir `git status`, `project.godot`, versão Godot, árvore de cenas/scripts, autoloads e export presets.
- Abrir a cena principal via editor/MCP, iniciar o jogo e capturar screenshot.
- Marcar cada item do MVP como `feito`, `parcial`, `quebrado` ou `ausente`.
- Confirmar o tema oficial revelado e apontar uma ligação clara com a história/mecânica atual. O GDD não identifica explicitamente o tema da jam; se necessário, fazer um ajuste temático pequeno, sem inflar escopo.
- Fazer teste rápido do alvo de export atual (Web se já configurado; Windows se é o caminho funcional mais rápido).
- Congelar escopo e comunicar contratos/arquivos aos agentes.

**Gate 20:15:** deve existir um diagnóstico e um alvo de build. Não reescrever o jogo por suposição.

### Bloco 1 — Garantir o caminho crítico (20:15–23:00)

- Corrigir movimento, interação, machado, corte de 3 árvores, trigger de anoitecer e retorno.
- Se já existir, testar e só corrigir defeitos.
- Fazer uma passagem completa, mesmo que com placeholders.
- Não começar polimento visual antes de a ida/volta funcionar.

**Gate 23:00:** jogador consegue iniciar, jogar, cortar madeira e concluir ao menos o retorno do Dia 1, ou há um bloqueio claramente identificado e com correção em andamento.

### Bloco 2 — Três dias e final (23:00–02:00, domingo)

- Avançar o dia de maneira determinística após o retorno.
- Dia 2: filho ainda presente; variação cromática e ao menos uma alteração solucionável.
- Dia 3: filho ausente/quarto vazio; encontro com espírito; final e fade.
- Confirmar reset para novo jogo.

**Gate 02:00:** a jornada completa tem de ser alcançável. Simplificar qualquer passo que impeça chegar ao final.

### Bloco 3 — Substituição de sprites e atmosfera (02:00–04:30)

- Trocar somente placeholders para os quais haja asset licenciado e coeso; se não houver, usar formas/silhuetas originais simples em vez de perder tempo procurando.
- Ajustar pivôs, escala, animations, colisões e offsets depois da troca.
- Aplicar paletas distintas por dia, névoa/fade, uma camada de profundidade/parallax apenas se barata.
- Adicionar áudio essencial (vento, passos ou machado/porta) apenas se houver recurso licenciado e integração simples.
- Atualizar imediatamente o registro de assets e IA.

**Gate 04:30:** não permitir que a troca visual quebre hitboxes ou progressão.

### Bloco 4 — Integração e teste completo (04:30–06:30)

- Mesclar os trabalhos em partes pequenas, ler diffs e resolver contratos.
- Executar a jornada completa, testar interação repetida, mudanças de cena, dia 3 e reinício.
- Verificar console, referências ausentes, erros de carregamento de recursos e áudio.
- Corrigir primeiro bugs que impeçam terminar o jogo.

### Bloco 5 — Export e teste fora do editor (06:30–08:00)

- Exportar cedo o alvo já escolhido. Para Web, testar a build exportada num navegador real; se Web bloquear a entrega e o export Windows funcionar, usar Windows como alvo principal e publicar na página do itch.io, conforme permitido pelo regulamento.
- Não gastar indefinidamente tentando consertar um target secundário. Manter o outro só se estiver comprovadamente funcional.
- Conferir que arquivos de build estão completos e que a página do itch pode executar/baixar o jogo.

### Bloco 6 — Release candidate e documentação (08:00–10:15)

- Congelar funcionalidades novas.
- Corrigir somente bugs prioritários de reprodução/entrega.
- Preparar a página do itch.io, créditos/lista de assets, declaração de IA e um pitch de até 5 minutos que explique a experiência, a ligação com o tema, o público-alvo, o diferencial e o plano de distribuição (não inventar monetização existente).
- Comparar `ASSETS_AND_AI.txt` com os recursos realmente importados e código produzido/modificado por IA.
- Conferir a build exportada do começo ao final.

**Gate 10:15:** release candidate funcional e sem novas funcionalidades planejadas.

### Bloco 7 — Playtest e entrega interna (10:15–11:00)

- **10:30:** realizar o playtest cruzado exigido: jogar pelo menos 2 jogos de outras equipes e registrar 3 observações no formulário do evento.
- Se os comentários indicarem um bloqueio real no próprio jogo, corrigir apenas se houver tempo para reexportar e testar novamente. Não fazer alterações estéticas arriscadas.
- Até **11:00**, concluir a entrega interna: build no itch.io, créditos/lista de assets, uso de IA declarado, pitch/material exigido pronto e cópias dos arquivos finais.

### Margem oficial (11:00–12:00)

Usar somente para conferir metadados/upload, preencher o que o regulamento ainda exigir e corrigir um bug impeditivo comprovado. Respeitar o congelamento oficial às 12:00. Não contar com esta margem para desenvolver funcionalidades novas.

## 6. Regra de produção da jam e histórico do projeto

O regulamento permite ideias, rascunhos e notas prévios e, em condições específicas, código-base genérico já público; proíbe arte, música, efeitos sonoros, roteiro, fases e mecânicas específicos do jogo já prontos antes da revelação do tema (itens 12.1–12.5). Isso não significa que um GDD ou uma ideia, por si só, prove descumprimento; o risco depende de quando e em que estado o conteúdo específico foi produzido.

- Confirmar que a implementação e os conteúdos específicos utilizados foram criados durante a jam após a revelação do tema.
- Não incorporar material pronto de um projeto anterior só para ganhar tempo.
- Se algum código-base genérico prévio for usado, confirmar que o repositório era público antes do evento e declarar o link na entrega, conforme item 12.2(b).
- Preservar o histórico real de commits; não o reescrever nem apagar para ocultar a origem das mudanças.
- Em caso de dúvida genuína sobre um material já existente, não assumir que é permitido: perguntar à organização.

## 7. Licenças, assets e IA — requisito de entrega

O regulamento exige:

- Build jogável publicada na página do jogo no itch.io.
- Créditos e lista de assets gratuitos de terceiros com links e licenças na página do jogo.
- Declaração de uso de IA; declarar conteúdo gerado ou modificado por IA e qual ferramenta foi usada.
- Anexo III “Declaração de Originalidade, Assets Gratuitos e IA” assinado por todos os integrantes.
- Capacidade de demonstrar histórico de versões/commits se solicitado.

`ASSETS_AND_AI.txt` é o registro de trabalho. Ele **não substitui** os créditos na página do itch.io, a lista para o pitch nem o Anexo III assinado.

Fontes iniciais possíveis (verificar a licença por item):

- Kenney Pixel Pack (asset page informa CC0): https://kenney.nl/assets/pixel-pack
- OpenGameArt (a licença varia por submissão; seguir os termos e atribuição): https://opengameart.org/content/faq
- Freesound (há licenças diferentes; aceitar apenas CC0 ou CC-BY compatível, nunca NC): https://freesound.org/help/faq/
- itch.io — assets gratuitos marcados para uso comercial, sempre conferir a licença do item: https://itch.io/game-assets/free/tag-commercial-use/tag-pixel-art
- Godot Asset Library — recursos gratuitos, mas licenças variam: https://docs.godotengine.org/en/stable/community/asset_library/what_is_assetlib.html

### Regras para o agente de assets

- Selecionar poucos recursos com estilo visual consistente; preferir CC0 ou CC-BY clara.
- Não usar asset pago, `NonCommercial`, licença desconhecida ou origem não verificável.
- Registrar nome do asset, autor, URL, licença e versão/arquivos usados; indicar modificações e a linha de crédito quando for necessário.
- Não transformar a procura de assets numa tarefa sem fim: estabeleça limite de 30 minutos por busca inicial, depois opte por silhuetas/placeholders consistentes.

## 8. Definição objetiva de pronto

A entrega está pronta quando todos os itens abaixo forem verdadeiros:

- [ ] Jogo abre na build exportada, fora do editor.
- [ ] Controles e prompt são compreensíveis.
- [ ] Casa → floresta → cortar 3 árvores → anoitecer → retorno funciona.
- [ ] Dia 1 → Dia 2 → Dia 3 funciona na ordem correta.
- [ ] A alteração/obstáculo do Dia 2 é visível e superável.
- [ ] Filho ausente e ambiente vazio no Dia 3.
- [ ] Espírito bloqueia a passagem e leva ao final.
- [ ] Fade, diálogos e transições não travam o fluxo.
- [ ] Novo jogo restaura estado corretamente.
- [ ] Não há erro crítico conhecido que impeça terminar a experiência.
- [ ] `ASSETS_AND_AI.txt` corresponde ao conteúdo entregue.
- [ ] Página do itch.io tem build, créditos/licenças e declaração de IA.
- [ ] Pitch e Anexo III estão prontos; todos os integrantes assinam o Anexo III.
- [ ] Playtest cruzado das 10:30 foi realizado e suas 3 observações enviadas.
- [ ] Release candidate finalizada até 11:00; congelamento oficial respeitado às 12:00.

## 9. Formato de resposta de cada agente

Ao finalizar uma tarefa, responder ao coordenador com:

1. **Resultado:** concluído/parcial/bloqueado.
2. **Arquivos alterados:** caminhos exatos.
3. **Comprovação:** teste executado, ferramenta MCP usada, captura/resultado, ou motivo pelo qual não foi possível testar.
4. **Riscos/pendências:** sem esconder regressões.
5. **Assets/IA:** tudo que foi incorporado ou gerado/modificado, com entradas acrescentadas a `ASSETS_AND_AI.txt`.

O coordenador só marca uma tarefa como concluída após verificar o diff e confirmar a aceitação no projeto integrado.
