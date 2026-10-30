# GitHub Projects par `gh` — ce qui a été vérifié (gh 2.x, septembre 2026)

## Pré-requis

Le jeton `gh` doit porter le scope `project` :

```bash
gh api -i user 2>&1 | grep -i "^x-oauth-scopes"
gh auth refresh -s project        # interactif : l'utilisateur le lance lui-même
```

Sans lui, `gh project create` échoue ; tout le reste (issues, labels) marche.

## Créer ou rattacher

```bash
gh project create --owner <login> --title "<titre>" --format json   # → .number, .id (PVT_…)
gh project link <number> --owner <login> --repo <owner/repo>
gh project list --owner <login> --format json                        # pour rattacher un existant
```

## Champs et options

```bash
gh project field-list <number> --owner <login> --format json
gh project field-create <number> --owner <login> --name Points --data-type NUMBER --format json
gh project field-create <number> --owner <login> --name "Priorité" --data-type SINGLE_SELECT \
  --single-select-options "P0,P1,P2,P3" --format json
```

`field-create` ne sait pas mettre de description sur les options ; pour les
descriptions et couleurs, et pour **renommer les statuts par défaut** (Todo / In
Progress / Done), passer par GraphQL `updateProjectV2Field` avec la liste complète
des options. **Passer l'`id` des options existantes** pour les conserver : un
statut recréé sans son id perd les vues et les items qui le référencent.

```graphql
mutation {
  updateProjectV2Field(input: {
    fieldId: "<PVTSSF_…>",
    singleSelectOptions: [
      {id: "<existant>", name: "Backlog", color: GRAY, description: "…"},
      {name: "À faire", color: BLUE, description: "…"},
      …
    ]
  }) { projectV2Field { ... on ProjectV2SingleSelectField { options { id name } } } }
}
```

Le workflow intégré « Item closed → Set status » suit l'option par id : renommer
« Done » en « Fait » en conservant l'id garde le workflow actif.

## Items

```bash
gh project item-add <number> --owner <login> --url <issue-url> --format json    # → .id (PVTI_…)
gh project item-list <number> --owner <login> --limit 100 --format json          # .items[].content.number, .status, .points
gh project item-edit --project-id <PVT_…> --id <PVTI_…> --field-id <…> --number 3
gh project item-edit --project-id <PVT_…> --id <PVTI_…> --field-id <…> --single-select-option-id <id>
```

**Auto-add.** Quand le workflow « auto-add to project » est actif, une issue
fraîchement créée est déjà dans le projet et `item-add` répond
`Content already exists in this project`. Toujours chercher l'item par
`item-list … | select(.content.number==N)` avant d'ajouter, et ne renseigner les
champs qu'après.

**Vues.** Aucune API : le kanban et la liste triée se créent à la main dans
l'interface. Le dire à l'utilisateur, avec les deux à créer.

## Issues et labels

```bash
gh label create <nom> --color <hex> --description "…" --force      # idempotent
gh label delete <nom> --yes
gh issue create --title "…" --body "…" --label "a,b,c"              # → url
gh issue comment <N> --body "…"
gh pr view <N> --json closingIssuesReferences --jq '[.[].number]'   # le vrai lien PR → issue
```

`Closes: #N`, `fixes #N`, `Closes owner/repo#N` sont tous reconnus par GitHub ; une
regex maison ne l'est pas. Cross-dépôt (méta-dépôt), la fermeture ne se fait que si
l'auteur du merge a les droits sur les deux dépôts.

## Pièges d'outillage

- Le shell de l'outil Bash de Claude Code est **zsh** : `set -- $var` ne découpe
  pas ; un script bun/TypeScript est plus sûr qu'une boucle shell pour créer trente
  issues.
- Un `$(cat <<'EOF' … EOF)` avec un `'` à l'intérieur d'un `${…:?message}` casse le
  quoting bash : pas d'apostrophe dans les messages de paramètre.
- Le numéro d'une issue créée se lit dans l'URL renvoyée par `gh issue create`
  (`${url##*/}`).
