#!/usr/bin/env bun
// Crée labels, projet GitHub, statuts, champs et issues depuis un backlog JSON. Rejouable sans doublon.
// Usage : bun board.ts <backlog.json> [--dry-run]
import { readFileSync } from "fs";
import { spawnSync } from "child_process";

type Backlog = {
  issues_repo: string;
  project: { owner: string; title: string; number: number | null };
  issues: BacklogIssue[];
};
type BacklogIssue = {
  key: string;
  title: string;
  body: string;
  labels: string[];
  points: number;
  priority: "P0" | "P1" | "P2" | "P3";
  status?: string;
  verified?: boolean;
  subrepo?: string | null;
};

const STATUSES: { name: string; color: string; description: string; from?: string }[] = [
  { name: "Backlog", color: "GRAY", description: "Identifié, pas encore planifié" },
  { name: "À faire", color: "BLUE", description: "Retenu pour la prochaine passe", from: "Todo" },
  { name: "En cours", color: "YELLOW", description: "En cours de réalisation", from: "In Progress" },
  { name: "Bloqué", color: "RED", description: "En attente d une information, d une donnée ou d une décision" },
  { name: "Review", color: "PURPLE", description: "Implémenté, en attente de relecture et de test" },
  { name: "Fait", color: "GREEN", description: "Livré et vérifié", from: "Done" },
];
const PRIORITIES: { name: string; color: string; description: string }[] = [
  { name: "P0", color: "RED", description: "Critique : le livrable est faux ou inutilisable" },
  { name: "P1", color: "ORANGE", description: "Haute : à faire avant la prochaine livraison" },
  { name: "P2", color: "YELLOW", description: "Normale : quand l occasion se présente" },
  { name: "P3", color: "GRAY", description: "Basse : plus tard, ou en attente d un prérequis" },
];
const LABELS: [string, string, string][] = [
  ["bug", "d73a4a", "Défaut constaté ou défaillance silencieuse"],
  ["produit", "0e8a16", "Fonctionnalité ou contrôle manquant côté livrable"],
  ["qualité", "fbca04", "Robustesse, lisibilité, dette technique"],
  ["tests", "5319e7", "Couverture de test et CI"],
  ["documentation", "0075ca", "Documentation à corriger ou compléter"],
  ["vérifié", "c5def5", "Constat mesuré sur les données réelles ou les journaux"],
  ["complexité: 1", "e6f2e6", "Planning poker : trivial"],
  ["complexité: 2", "cce8cc", "Planning poker : simple"],
  ["complexité: 3", "a8d8a8", "Planning poker : quelques heures"],
  ["complexité: 5", "7fc47f", "Planning poker : une journée, plusieurs fichiers"],
  ["complexité: 8", "4fa64f", "Planning poker : conception nécessaire"],
  ["complexité: 13", "2e7d2e", "Planning poker : chantier, à découper"],
];
const DEFAULT_LABELS_TO_DROP = [
  "accessibility", "duplicate", "enhancement", "good first issue", "help wanted", "invalid",
  "question", "wontfix",
];

const [file, ...flags] = process.argv.slice(2);
if (!file) {
  console.error("usage : bun board.ts <backlog.json> [--dry-run]");
  process.exit(2);
}
const dryRun = flags.includes("--dry-run");
const backlog = JSON.parse(readFileSync(file, "utf8")) as Backlog;
const repo = backlog.issues_repo;
const owner = backlog.project.owner;

function gh(args: string[], { mutating = true } = {}): string {
  if (dryRun && mutating) {
    console.log(`  [dry-run] gh ${args.map((a) => (a.includes(" ") ? JSON.stringify(a.slice(0, 60)) : a)).join(" ")}`);
    return "";
  }
  const r = spawnSync("gh", args, { encoding: "utf8" });
  if (r.status !== 0) {
    if (dryRun) {
      console.log(`  [dry-run] lecture impossible (${r.stderr.trim().split("\n")[0]}), considérée vide`);
      return "";
    }
    throw new Error(`gh ${args.slice(0, 3).join(" ")} : ${r.stderr.trim()}`);
  }
  return r.stdout.trim();
}
const json = <T>(s: string): T => JSON.parse(s || "null") as T;

// ---- 1. labels
console.log("Labels");
const subrepos = [...new Set(backlog.issues.map((i) => i.subrepo).filter(Boolean))] as string[];
for (const [name, color, description] of [
  ...LABELS,
  ...subrepos.map((s): [string, string, string] => [`dépôt: ${s}`, "bfdadc", `Sous-dépôt ${s}`]),
]) {
  gh(["label", "create", name, "--repo", repo, "--color", color, "--description", description, "--force"]);
}
const existingLabels = json<{ name: string }[]>(gh(["label", "list", "--repo", repo, "--limit", "100", "--json", "name"], { mutating: false }) || "[]").map((l) => l.name);
for (const name of DEFAULT_LABELS_TO_DROP.filter((l) => existingLabels.includes(l))) {
  gh(["label", "delete", name, "--repo", repo, "--yes"]);
}
console.log(`  ${LABELS.length + subrepos.length} labels en place`);

// ---- 2. projet
console.log("Projet");
type Project = { number: number; id: string; title: string };
let project: Project | undefined;
const projects = json<{ projects: Project[] }>(gh(["project", "list", "--owner", owner, "--limit", "50", "--format", "json"], { mutating: false }) || '{"projects":[]}').projects;
if (backlog.project.number != null) project = projects.find((p) => p.number === backlog.project.number);
project ??= projects.find((p) => p.title === backlog.project.title);
if (!project) {
  const created = gh(["project", "create", "--owner", owner, "--title", backlog.project.title, "--format", "json"]);
  project = dryRun ? { number: 0, id: "PVT_dry", title: backlog.project.title } : json<Project>(created);
  console.log(`  créé : #${project.number}`);
} else console.log(`  rattaché : #${project.number} « ${project.title} »`);
try {
  gh(["project", "link", String(project.number), "--owner", owner, "--repo", repo]);
} catch (e) {
  if (!String(e).includes("already")) throw e;
}

// ---- 3. champs
console.log("Champs");
type Field = { id: string; name: string; type: string; options?: { id: string; name: string }[] };
const fields = () =>
  json<{ fields: Field[] }>(gh(["project", "field-list", String(project!.number), "--owner", owner, "--format", "json"], { mutating: false }) || '{"fields":[]}').fields;
let allFields = fields();
const field = (name: string) => allFields.find((f) => f.name === name);

const optionsLiteral = (opts: { id?: string; name: string; color: string; description: string }[]) =>
  opts
    .map((o) => `{${o.id ? `id: ${JSON.stringify(o.id)}, ` : ""}name: ${JSON.stringify(o.name)}, color: ${o.color}, description: ${JSON.stringify(o.description)}}`)
    .join(", ");
const updateOptions = (fieldId: string, opts: { id?: string; name: string; color: string; description: string }[]) =>
  gh(["api", "graphql", "-f", `query=mutation { updateProjectV2Field(input: {fieldId: ${JSON.stringify(fieldId)}, singleSelectOptions: [${optionsLiteral(opts)}]}) { projectV2Field { ... on ProjectV2SingleSelectField { options { id name } } } } }`]);

const status = field("Status");
if (status?.options) {
  const wanted = STATUSES.map((s) => {
    const existing = status.options!.find((o) => o.name === s.name) ?? status.options!.find((o) => o.name === s.from);
    return { id: existing?.id, name: s.name, color: s.color, description: s.description };
  });
  const unchanged = status.options.length === wanted.length && wanted.every((w, i) => w.id === status.options![i]?.id && w.name === status.options![i]?.name);
  if (unchanged) console.log("  Status : déjà conforme");
  else {
    updateOptions(status.id, wanted);
    console.log(`  Status : ${STATUSES.map((s) => s.name).join(" → ")}`);
  }
} else console.log("  Status : champ introuvable (dry-run ou projet vide)");

if (!field("Points")) {
  gh(["project", "field-create", String(project.number), "--owner", owner, "--name", "Points", "--data-type", "NUMBER", "--format", "json"]);
  console.log("  Points : créé");
} else console.log("  Points : présent");

if (!field("Priorité")) {
  gh(["project", "field-create", String(project.number), "--owner", owner, "--name", "Priorité", "--data-type", "SINGLE_SELECT", "--single-select-options", PRIORITIES.map((p) => p.name).join(","), "--format", "json"]);
  allFields = dryRun ? allFields : fields();
  const prio = field("Priorité");
  if (prio?.options) updateOptions(prio.id, PRIORITIES.map((p) => ({ id: prio.options!.find((o) => o.name === p.name)?.id, ...p })));
  console.log("  Priorité : créé (P0 → P3)");
} else console.log("  Priorité : présent");
allFields = dryRun ? allFields : fields();

const pointsField = field("Points");
const prioField = field("Priorité");
const statusField = field("Status");
const optionId = (f: Field | undefined, name: string) => f?.options?.find((o) => o.name === name)?.id;

// ---- 4. issues
console.log("Issues");
type Existing = { number: number; title: string; url: string };
const existing = json<Existing[]>(gh(["issue", "list", "--repo", repo, "--state", "all", "--limit", "500", "--json", "number,title,url"], { mutating: false }) || "[]");
type Item = { id: string; content?: { number?: number } };
const items = () =>
  json<{ items: Item[] }>(gh(["project", "item-list", String(project!.number), "--owner", owner, "--limit", "500", "--format", "json"], { mutating: false }) || '{"items":[]}').items;
let allItems = items();

let created = 0;
let reused = 0;
for (const issue of backlog.issues) {
  const title = issue.subrepo ? `[${issue.subrepo}] ${issue.title}` : issue.title;
  const labels = [
    ...issue.labels,
    `complexité: ${issue.points}`,
    ...(issue.verified ? ["vérifié"] : []),
    ...(issue.subrepo ? [`dépôt: ${issue.subrepo}`] : []),
  ];
  const head = issue.subrepo ? `**Dépôt.** ${issue.subrepo}\n\n` : "";
  const body = `${head}${issue.body.trim()}\n\n---\n**Complexité (planning poker) : ${issue.points}**`;

  let found = existing.find((e) => e.title === title);
  if (found) reused++;
  else {
    const url = gh(["issue", "create", "--repo", repo, "--title", title, "--body", body, "--label", labels.join(",")]);
    found = { number: dryRun ? 0 : Number(url.split("/").pop()), title, url: url || "(dry-run)" };
    existing.push(found);
    created++;
  }
  if (dryRun) {
    console.log(`  ${issue.priority} ${issue.points}  ${title}`);
    continue;
  }

  let item = allItems.find((i) => i.content?.number === found!.number);
  if (!item) {
    try {
      item = json<Item>(gh(["project", "item-add", String(project.number), "--owner", owner, "--url", found.url, "--format", "json"]));
    } catch (e) {
      if (!String(e).includes("already exists")) throw e;
      allItems = items();
      item = allItems.find((i) => i.content?.number === found!.number);
    }
  }
  if (!item) throw new Error(`item du projet introuvable pour #${found.number}`);
  const edit = (args: string[]) =>
    gh(["project", "item-edit", "--project-id", project!.id, "--id", item!.id, ...args, "--format", "json", "--jq", ".id"]);
  if (pointsField) edit(["--field-id", pointsField.id, "--number", String(issue.points)]);
  const prioId = optionId(prioField, issue.priority);
  if (prioId) edit(["--field-id", prioField!.id, "--single-select-option-id", prioId]);
  const statusId = optionId(statusField, issue.status ?? "Backlog");
  if (statusId) edit(["--field-id", statusField!.id, "--single-select-option-id", statusId]);
  console.log(`  #${found.number}  ${issue.priority} ${issue.points}  ${title}`);
}

console.log(`\n${created} issue(s) créée(s), ${reused} déjà présente(s).`);
console.log(`Projet : https://github.com/${owner.includes("/") ? owner : `users/${owner}`}/projects/${project.number}`);
console.log(`À faire à la main dans l'interface du projet :
  - vue kanban : Board, grouper par Status, somme des Points ;
  - vue liste : Table, trier par Priorité puis Points ;
  - ⋯ → Workflows : activer « Item closed → Set status: Fait ».`);
