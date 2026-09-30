# herdr — ce qui a été vérifié (herdr 0.9.2, 30 septembre 2026)

Le binaire fait foi : `herdr <groupe>` sans sous-commande imprime l'aide du groupe.
Ne jamais lancer `herdr` nu depuis un agent (ça ouvre le TUI). Les commandes de
contrôle renvoient du JSON ; lire les identifiants dedans, ne pas les deviner.

## Pré-requis

```bash
test "${HERDR_ENV:-}" = 1          # sinon : on n'est pas dans herdr, s'arrêter
printf '%s\n' "$HERDR_WORKSPACE_ID" "$HERDR_PANE_ID"
```

## Worktree = sous-espace

```bash
herdr worktree create --workspace "$HERDR_WORKSPACE_ID" --branch <branche> --base main \
  --path <chemin-absolu> --label <libellé> --no-focus
```

Crée le worktree git **et** un workspace herdr lié au workspace source (il apparaît
sous lui dans la barre latérale). Le JSON de retour porte le workspace et le pane
racine ; `workspace create` renvoie `.result.workspace`, `.result.tab`,
`.result.root_pane` — le lanceur lit `.result.root_pane.pane_id // .result.root_pane`
et affiche le JSON brut si la clé manque. `--trust-repository` n'est pas une option
de relance : ne l'ajouter qu'après avoir vérifié le dépôt.

`herdr worktree list` et `herdr workspace list` pour l'état.

## Amorcer un worktree

Ce que git n'emporte pas : `node_modules`, les liens symboliques ignorés, les
références de non-régression hors git. Le lanceur exécute la commande d'amorçage du
projet dans le pane racine et attend un marqueur :

```bash
herdr pane run <pane> "<commande> && echo AMORCE-OK"
herdr pane wait-output <pane> --match "AMORCE-OK" --timeout 300000
```

`pane wait-output` cherche aussi dans ce qui est déjà affiché — **y compris la
commande tapée**, où le marqueur figure en clair. Utiliser un marqueur calculé qui ne
s'écrit pas tel quel : `echo AMORCE-$((2*100))-FIN` et attendre `AMORCE-200-FIN`.
Vérifier ensuite l'effet (`ls node_modules`) plutôt que croire le marqueur.

Le shell de l'outil Bash de Claude Code est **zsh** : `set -- $var` ne découpe pas
les mots. Écrire les boucles avec `${a%% *}` / `${a##* }` ou des commandes explicites.

## Démarrer et piloter un agent

```bash
herdr agent start <nom> --kind claude --pane <pane> --timeout 60000 -- \
  --model claude-opus-5-5 --permission-mode auto --disallowedTools "<liste>"
```

Le pane doit être à un prompt shell interactif. `start` ne rend la main qu'une fois
Claude détecté et prêt. Le nom suit `[a-z][a-z0-9_-]{0,31}` et doit être unique.

```bash
herdr agent prompt <nom> "<texte>"                             # envoie et rend la main aussitôt
herdr agent prompt <nom> "<texte>" --wait --timeout 3600000   # --timeout exige --wait
herdr agent wait <nom> --timeout 7200000                       # attendre done/blocked, à lancer en arrière-plan
herdr agent wait <nom> --until blocked --timeout 120000        # attendre une question
herdr agent read <nom> --source recent-unwrapped --lines 200   # lire la sortie
herdr agent get <nom>                                          # état
herdr agent send-keys <nom> esc                                # interrompre
```

Dans le JSON de `agent get` / `agent list`, l'état est `.result.agent.agent_status`
(pas `status`), le nom `.result.agent.name`, la prêteté `interactive_ready`.

États : `idle` et `done` = prêt pour une entrée ; `blocked` = question ou demande
d'approbation à l'écran ; `working` ; `unknown` = présent mais non classé, **ne
prouve pas une fin**. `prompt --wait` attend un `working` observé dans les cinq
secondes, sinon `agent_prompt_stalled` : un texte long passe en collage bracketé,
c'est prévu.

Un `prompt` vers un agent `blocked` est refusé (`agent_blocked`) : lire l'écran,
décider, répondre par `send-keys` ou `prompt`, puis seulement envoyer la suite.

`agent read` lit le terminal, pas la conversation : un compte rendu long peut être
tronqué. D'où le repli « écris-le aussi dans un fichier » dans la consigne commune.

## Attendre depuis la tour sans bloquer

`herdr agent wait` bloque le shell. Depuis Claude Code, le lancer avec
`run_in_background` : la tour est réveillée quand la commande sort, sans polling.
Un `wait` par agent, en parallèle.

## Pièges rencontrés

- **Un texte dans la zone de saisie d'un agent idle n'est pas de l'utilisateur.** Claude
  Code y affiche une suggestion automatique (texte grisé, non envoyé). L'utilisateur ne
  parle pas aux sous-agents ; s'il le fait, il n'y laisse pas de texte non envoyé. Un
  `agent prompt` remplace la suggestion : envoyer sans hésiter.

- **Mémoire de Claude Code par chemin.** Vérifié par sonde : un worktree, même sous
  `.claude/worktrees/`, ouvre un projet neuf `-Users-…-<chemin-du-worktree>` sans
  aucune mémoire. Le lanceur lie `memory` vers celle du projet principal.
- **`~/.claude/CLAUDE.md` est un lien** vers les dotfiles ; écrire sur la cible.
- **Les règles de travail stables** (pas de commit sans demande, ne pas dépasser la
  demande, mesurer avant d'affirmer) doivent être dans `~/.claude/CLAUDE.md`, pas en
  mémoire, précisément parce que la mémoire ne suit pas les worktrees.
- **Branche créée depuis `origin/main`** (`git switch -c x origin/main`) : git la fait
  suivre `origin/main`, et un `git push` sans argument pousserait sur `main`. Faire
  `git branch --unset-upstream` aussitôt. Empiler sur le HEAD local n'a pas ce piège.
- Ne jamais `workspace close --group` pour contourner `workspace_group_close_required`.
- Ne jamais `herdr server stop` depuis une session active.
