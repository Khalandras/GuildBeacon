# GuildBeacon — Vision, roadmap et déploiement

Document de synthèse : positionnement produit, agent de réflexion GM/RL, état du code, lots de travail, portes de déploiement (CurseForge, Wago), passage Nox → grand public.

**Version doc :** 1.2 · **Addon de référence :** 0.3.0+  
**Complète :** `README.md`, `docs/art-direction.md`, `CHANGELOG.md`

---

## 1. Positionnement

### 1.1 Ce qu'est GuildBeacon

Addon WoW **standalone** pour officiers de guilde : balise de recrutement, inbox MP/chat guilde, pipeline candidats.

| Axe | Choix |
|---|---|
| Public | Officiers (GM, recruteur, RL impliqué dans le roster) |
| Registre | Outil métier sobre, pas fantasy décoratif |
| Sessions | Courtes, usage fréquent |
| Versions WoW | Retail prioritaire ; Classic/Era en option documentée |

**Phrase guide :** *Console de recrutement de guilde premium, pas addon de cosplay.*

### 1.2 Ce que GuildBeacon n'est pas

Volontairement hors périmètre (marché saturé ou hors ADN) :

- Loot council, DPS meters, logs combat
- Invite mass, planner M+ complet
- Surveillance toxique des membres

Inspiration possible des workflows MRT / RCLootCouncil / Details, pas de clone de leurs features.

### 1.3 Définition de « complet »

GuildBeacon **complet** (vision long terme, Porte C) :

- Cycle recrutement fermé : premier contact → trial → accepté/rejeté
- Continuité multi-officier (données guilde partagées)
- Templates MP, métriques, trial structuré
- Sync web **optionnelle** (khalandras.eu ou autre)
- Déployable et recommandable sans support personnel du dev

GuildBeacon **deployable plateformes** (Porte A) est un seuil plus bas : voir section 6.

### 1.4 Relation Khalandras / Nox / public

| Couche | Nox (interne Khalandras) | Public (CurseForge, Wago) |
|---|---|---|
| Identité visuelle | DA NØX : abyss, phosphor `#b794f6`, wine, sigil losange | Thème **default** : or + bordeaux signal, fonds sobres, sans violet NØX par défaut |
| Distribution | khalandras.eu/guildbeacon, Discord Khalandras | GitHub issues, fiche store, pas de lien imposé |
| Sync cloud | Dashboard Khalandras + bot Discord | Export/import JSON suffit ; sync = opt-in |
| Licence | ARR Khalandras (actuel) | À trancher avant Porte A (ARR source visible ou licence permissive) |

**Principe repo unique :** un addon, thèmes + modules optionnels, pas deux forks.

- **GuildBeacon** = marque produit neutre
- **khalandras.eu** = un canal de sync parmi d'autres, pas le cœur du produit public

---

## 2. État actuel (0.3.0)

### 2.1 En place

| Zone | Contenu |
|---|---|
| **Core** | Bootstrap, EventBus, ProfileManager, ModuleManager, Widgets, Branding, Logger, TestHarness |
| **Beacon** | Scheduler, rotation templates/canaux, jitter, anti-spam, pause instance/combat, dry-run + confirmation live |
| **Inbox** | Capture MP, BNet whisper, chat guilde (mots-clés) |
| **Candidates** | Statuts (`new`, `contacted`, `trial`, `accepted`, `rejected`, `archived`), notes, timeline, enrichissement Raider.IO optionnel |
| **UI** | Dashboard : triage, pipeline, beacon, settings ; export JSON ; slash commands |
| **Données** | `GuildBeaconDB`, profils par personnage, migrations DB v15 |
| **Locales** | FR + EN |

### 2.2 Manques structurels

- Données **par profil perso**, pas encore par guilde
- Statut `trial` sans workflow dédié (dates, objectifs, checklist)
- Pas de templates MP / réponses structurées depuis le dashboard
- Pas d'import JSON (export seul)
- Pas de sync web (annoncée README, hors client)
- CHANGELOG arrêté en 0.2.0 alors que le code est en 0.3.0
- DA et copy encore orientées Nox/Khalandras (footer portal, phosphor par défaut)

### 2.3 Architecture cible

```
Core/       Bootstrap, EventBus, profils, widgets, thèmes
Modules/    Beacon, Inbox, Candidates (+ futurs : Templates, Trial, Brief)
UI/         Dashboard, ConfigPanel, slash commands
docs/       art-direction, vision-et-roadmap, patchnotes
```

Sync future : companion lit export JSON → dashboard web + Discord (hors client WoW).

---

## 3. Beacon : campagnes et messages automatiques

### 3.1 Le souci (deux besoins, un seul moteur aujourd'hui)

Un GM/RL a **deux annonces différentes** qui ne doivent pas se mélanger :

| Besoin | Exemple | Rythme typique | Canal |
|---|---|---|---|
| **Guilde** | « On recrute pour progresser, MP pour candidater » | Toutes les 45–90 min, hors soirs raid | Canal guilde |
| **Roster du soir** | « Ce soir 20h30, il nous manque un heal et un range » | Toutes les 15–25 min, **fenêtre courte** avant le raid | Canal guilde (parfois say/yell en ville) |

Aujourd'hui le module Beacon fait **une seule chose** : un timer global, une rotation de templates génériques (`default`, `raid`), placeholders `{guild}`, `{player}`, `{realm}`, `{class}`. Pas de notion de soir raid, de rôles manquants, ni de fenêtre horaire.

Résultat concret pour l'officier :

- Il poste le message guilde au moment où il voulait chercher un remplaçant raid, ou l'inverse.
- Il ne peut pas dire « ce template seulement le mardi de 18h à 20h30 ».
- Le template `raid` est statique : il ne dit pas **quoi** manque ce soir.
- Si la rotation envoie le même texte deux fois de suite, l'anti-spam bloque (bien pour le spam, mal pour « toujours besoin heal »).
- La balise ne tourne que sur **le client de l'officier connecté** : offline = silence.

C'est le cœur du problème : **recrutement structurel guilde** vs **comblement roster ponctuel** sont deux campagnes, pas deux lignes dans la même rotation.

### 3.2 Contraintes WoW (non négociables)

| Contrainte | Impact design |
|---|---|
| `SendChatMessage` local | Un seul perso en ligne peut poster ; pas de serveur central |
| Throttle Blizzard | Intervalles trop courts = messages ignorés ou kick ; garder min 5 min guilde, plutôt 15+ en continu |
| Combat / instance | Déjà géré (`pauseInCombat`, `pauseInInstance`) ; à conserver par campagne |
| Grade officier | Poster canal guilde = officier ; déjà vérifié |
| Pas de MP auto vers inconnus | La balise = **annonce** ; les réponses arrivent dans l'Inbox (MP entrants) |
| Classic / Retail | Mêmes principes ; canaux et APIs à tester par version |
| Spam social | Trop poster = membres mutent le canal ; plafond **posts/jour** par campagne |

L'addon ne peut pas « inviter » ou « forcer » des joueurs. Il **annonce** au bon moment avec le bon texte ; l'Inbox capte les candidats.

### 3.3 Modèle cible : Campagnes (pas un beacon monolithique)

Remplacer la config `beacon` unique par des **campagnes** indépendantes, chacune avec son scheduler logique.

```
Campagne
├── id, label, enabled
├── type : "guild" | "raid_night" | "custom"
├── schedule
│   ├── intervalMinutes + jitterMinutes
│   ├── windows[]          -- ex. Mar/Jeu 17:00–20:30
│   ├── maxPostsPerDay     -- plafond anti-fatigue
│   └── onlyOnRaidDays     -- bool (lié au calendrier guilde)
├── channels[]             -- guild, say, yell
├── templates[]            -- une ou plusieurs, avec conditions
├── antiSpam
│   ├── minSecondsBetweenPosts
│   └── allowRepeatAfter   -- pour roster : répéter le même besoin après N min
└── state                  -- lastPostedAt, postsToday, templateIndex...
```

**Règle produit :** une campagne active = un objectif. Jamais mélanger « recrute guilde » et « besoin heal ce soir » dans la même rotation.

#### Campagne type « Guilde »

- Intervalle long (45–120 min), fenêtre large ou 24/7 hors heures raid configurées.
- Templates stables, rotation optionnelle entre angles (M+, raid, social).
- Plafond bas (ex. 8 posts/jour max).

#### Campagne type « Roster du soir »

- Intervalle court (15–30 min) mais **uniquement dans la fenêtre pré-raid**.
- Templates **conditionnels** : ne poster « besoin heal » que si le slot heal est vide.
- `allowRepeatAfter` : même message autorisé toutes les 20 min (le besoin n'a pas changé).
- Arrêt auto à l'heure de départ raid ou quand roster complet (slots remplis).

### 3.4 Templates : statiques, contextuels, conditionnels

**Niveau 1 — Statique (existant, à enrichir)**

Placeholders actuels : `{guild}`, `{player}`, `{realm}`, `{class}`.

À ajouter :

| Placeholder | Source |
|---|---|
| `{contact}` | Officier recruteur configuré ou `{player}` |
| `{raid_day}` | Calendrier guilde (ex. « Mardi ») |
| `{raid_time}` | Heure raid du jour |
| `{raid_name}` | Nom libre (ex. « Ny'alotha » / tier actuel) |
| `{needs}` | Liste rôles manquants (ex. « heal, chasseur distance ») |
| `{needs_short}` | « heal » ou « complet » si roster OK |

**Niveau 2 — Conditionnel**

Chaque template peut avoir des **conditions** (toutes optionnelles) :

```lua
-- conceptuel
conditions = {
    needsRole = "heal",       -- poster seulement si heal manquant
    minOpenSlots = 1,         -- au moins N trous
    rosterNotFull = true,
    campaignType = "raid_night",
}
```

Le moteur choisit le **premier template dont les conditions passent**, sinon fallback « roster complet » ou silence (ne pas spam « on recrute » quand c'est plein).

**Niveau 3 — Lié à l'Inbox (horizon)**

Si `{needs}` = heal et qu'un MP arrive avec tag heal candidat, suggestion à l'officier (pas d'auto-réponse). Hors scope envoi auto.

### 3.5 Roster du jour : saisie manuelle d'abord

Pas besoin d'intégration raid frame pour le MVP. Le RL remplit **une fiche soir** dans l'onglet Beacon :

```
Soir du 2026-06-29 — 20h30
Composition cible : 2T / 4H / 10 DPS (config guilde)
Présents / confirmés : (saisie rapide ou cases)
Manques : [ ] tank  [x] heal  [ ] melee  [x] range
```

`{needs}` est dérivé des cases cochées. Si tout est décoché (complet), la campagne `raid_night` **ne poste pas** ou poste un template « roster complet, merci » une seule fois.

Évolution plus tard (Lot 6) : mémoriser les habitués, streak absences, brief pré-raid. Pas bloquant pour les campagnes.

### 3.6 Calendrier guilde

Config minimale partagée (idéalement Lot 4 store guilde) :

```lua
raidCalendar = {
    { weekday = 2, time = "20:30", label = "Raid prog" },  -- 2 = Mardi
    { weekday = 4, time = "20:30", label = "Raid farm" },
}
```

La campagne `raid_night` calcule :

- fenêtre début = `time - preWindowMinutes` (ex. 120 min avant)
- fenêtre fin = `time` ou `time + 15 min`
- hors fenêtre : scheduler dormant, pas de tick inutile

### 3.7 Anti-spam par campagne

Problème actuel : un seul `lastPostedBody` global.

Évolution :

| Règle | Guilde | Roster soir |
|---|---|---|
| `minSecondsBetweenPosts` | 300–900 | 900–1800 (15–30 min) |
| `allowRepeatAfter` | 0 (éviter doublon) | 1200–1800 (même besoin OK) |
| `maxPostsPerDay` | 6–10 | 4–6 |
| Duplicate body | bloqué | autorisé après `allowRepeatAfter` |

Compteur `postsToday` remis à zéro au reset quotidien serveur ou minuit local.

### 3.8 UX dashboard (onglet Beacon)

Découper l'onglet en :

1. **Vue d'ensemble** : campagnes actives, prochain post par campagne, mode dry/live
2. **Éditeur campagne** : intervalle, fenêtres, canaux, plafonds
3. **Éditeur templates** : corps, placeholders cliquables, aperçu live
4. **Fiche roster du soir** (si type `raid_night`) : cases manques, heure, aperçu `{needs}`
5. **Historique** : par campagne (pas un seul fil global)

Garde-fous existants à conserver : dry-run par défaut, checkbox live + popup confirmation.

### 3.9 Exemples de templates

**Guilde (intervalle 60 min, canal guilde)**

```
[{guild}] Guilde francophone recrute pour raid {raid_name}. MP {contact} : spec, dispo, expérience.
```

**Roster soir (fenêtre 18h30–20h30, intervalle 20 min, condition heal ou range manquant)**

```
[{guild}] Ce soir {raid_time} : il nous manque {needs_short}. MP {contact} si dispo (trial ok).
```

**Roster complet (une fois, puis silence)**

```
[{guild}] Roster complet pour ce soir {raid_time}. Merci à tous.
```

### 3.10 Qui fait tourner la balise ?

Tant que Lot 4 (store guilde) n'est pas là :

- Documenter : **un officier désigné** laisse l'addon actif sur son main les soirs raid.
- Option future : détection « plusieurs officiers en ligne » → un seul leader beacon via sync léger (timestamp `beaconLeader` dans store guilde). Pas MVP.

### 3.11 Découpage implémentation

| Étape | Contenu | Lot |
|---|---|---|
| **A** | Éditeur templates + placeholders `{contact}`, `{raid_time}`, `{needs}` en dur dans le template | Lot 1 |
| **B** | Fiche roster du soir + dérivation `{needs}` | Lot 1–2 |
| **C** | Refactor `beacon` → `campaigns[]`, 2 campagnes par défaut (guilde + raid_night) | Lot 2 |
| **D** | Fenêtres horaires + `raidCalendar` | Lot 2 |
| **E** | Anti-spam par campagne + `maxPostsPerDay` | Lot 2 |
| **F** | Templates conditionnels (`needsRole`, `rosterNotFull`) | Lot 2–5 |
| **G** | Campagnes dans store guilde + leader offline | Lot 4 |
| **H** | Bibliothèque spotlight + promo addon (section 3.13) | Lot 2 |

**MVP campagnes (Porte A)** : A + B + C simplifié (2 campagnes fixes, fenêtre manuelle « activer roster ce soir » sans calendrier auto). Suffisant pour ne plus mélanger les deux usages.

### 3.12 Migration depuis le beacon actuel

- `beacon` devient `campaigns[1]` type `guild` avec les champs actuels.
- Ajout `campaigns[2]` type `raid_night`, `enabled = false` par défaut.
- `Scheduler` itère les campagnes actives, chacune avec son prochain `nextPostAt`.
- Migration DB : `profile.beacon` → `profile.campaigns` + rétrocompat lecture `beacon` une version.

### 3.13 Promotion addon et mise en avant des métiers

Les messages auto ne servent pas qu'à recruter des joueurs. Ils peuvent aussi **faire connaître l'outil** (à la guilde, aux candidats, aux autres officiers) et **présenter les features** au fil du temps. À condition de ne pas transformer le canal guilde en pub.

#### Trois niveaux de « promo » (du plus acceptable au plus risqué)

| Niveau | Cible | Exemple | Fréquence max |
|---|---|---|---|
| **A — Processus** | Candidats et membres | « MP {contact} avec spec, dispo et expérience » | Dans chaque message recrutement (naturel) |
| **B — Éducation feature** | Membres de ta guilde | « Les candidatures sont centralisées, répondez sur le canal ou en MP » | 1× / semaine, campagne dédiée |
| **C — Marque addon** | Externe / transparence | « Recrutement géré avec GuildBeacon » + lien | 1× / mois, opt-in explicite |

Le niveau A n'est pas de la pub : c'est du **call-to-action recrutement** qui montre en passant que la guilde est organisée. C'est le meilleur marketing (les candidats voient un process clair).

Le niveau B fait la promo des **métiers** de l'addon sans nommer CurseForge : inbox, pipeline, trial, roster du soir. Utile pour que les membres sachent comment candidater correctement.

Le niveau C est **désactivé par défaut** en thème public. Réservé aux officiers qui veulent assumer la transparence ou au thème Khalandras (lien khalandras.eu/guildbeacon optionnel).

#### Campagnes type « métiers » (feature spotlight)

Quatrième famille de campagnes, à part de guilde / roster :

```
type = "spotlight"
intervalMinutes = 10080   -- 1× par semaine
maxPostsPerDay = 1
enabled = false par défaut
```

Rotation de templates **un métier par message**, tirés d'une bibliothèque livrée avec l'addon :

| Métier (feature) | Message type (FR) |
|---|---|
| Inbox | « Pour candidater : MP un officier ou utilisez les mots-clés sur ce canal. On centralise les demandes. » |
| Pipeline | « Les essais (trial) durent en général X soirs. Précisez vos dispos dans votre premier MP. » |
| Roster soir | « Les remplaçants raid sont cherchés via ce canal les soirs de raid. Surveillez l'heure {raid_time}. » |
| Trial | « En période d'essai, la présence et la communication comptent autant que la perf. » |
| Export / continuité | (officiers seulement, canal officier ou note interne, pas canal guilde) |

Chaque template spotlight a un `featureId` pour stats internes (« quel métier a été mis en avant ») et pour ne pas répéter le même deux semaines de suite.

#### Promotion de l'addon lui-même

**Dans le canal guilde (membres + candidats)**

- Pas de lien CurseForge à chaque rotation : spam et mauvaise image.
- Formulation acceptable, rare : « Recrutement organisé via GuildBeacon » une fois par mois si l'officier coche « promo addon ».
- Placeholder `{addon_name}` → `GuildBeacon`, `{addon_url}` → configurable (GitHub, CurseForge, khalandras.eu). Vide par défaut en thème public.

**Hors canal guilde (où la promo est légitime)**

- Footer dashboard (déjà là, à rendre configurable Lot 0).
- Export JSON : champ `meta.generator = "GuildBeacon x.y.z"` discret.
- Patch notes / fiche store : marketing normal.
- Message auto **say/yell en ville** : campagne séparée, désactivée par défaut, pour recrutement + mention addon (comme les guildes qui /yell). Très encadré : plafond 2–3 posts/jour, fenêtre courte.

**Promotion des futurs métiers (roadmap)**

Quand une feature sort (trial, brief, sync web), ajouter un template spotlight en **bibliothèque mise à jour** avec l'addon. Pas de message « achetez la v2 » : plutôt « nouvelle option : suivi des essais dans le pipeline ». Les officiers activent la campagne spotlight s'ils veulent l'annoncer à la guilde.

#### Règles produit (anti-pub toxique)

1. **Opt-in** : campagnes `spotlight` et `addon_promo` off par défaut.
2. **Plafond strict** : max 1 post/semaine spotlight, 1 post/mois marque addon.
3. **Jamais mélangé au roster urgent** : si campagne `raid_night` active, suspendre spotlight ce soir.
4. **Pas de MP auto promo** vers des joueurs non initiés.
5. **Conformité Blizzard** : pas de pub payante, pas de lien commercial agressif ; éducation process guilde OK.
6. **Thème public** : `{addon_url}` vide sauf saisie officier ; pas de Khalandras imposé.
7. **Valeur d'abord** : chaque message spotlight doit aider candidat ou membre, pas seulement vendre l'addon.

#### Placeholders promo

| Placeholder | Défaut public | Usage |
|---|---|---|
| `{addon_name}` | `GuildBeacon` | Signature optionnelle |
| `{addon_url}` | vide | Lien CurseForge / GitHub si officier remplit |
| `{addon_tagline}` | locale | « Inbox et pipeline candidats pour officiers » |
| `{feature_hint}` | selon template spotlight | Une ligne sur le métier du jour |

#### Exemples

**Spotlight inbox (hebdo, canal guilde)**

```
[{guild}] Candidats : MP {contact} avec spec, dispo et objectifs. On lit tous les messages.
```

**Promo addon rare (mensuel, opt-in)**

```
[{guild}] Recrutement {guild} : MP {contact}. Organisation interne via {addon_name}.
```

Avec URL seulement si l'officier l'a configurée :

```
... via {addon_name} ({addon_url}).
```

**Roster + CTA process (pas de marque addon)**

```
[{guild}] Ce soir {raid_time} : besoin {needs_short}. MP {contact} si dispo — précisez spec et ilvl.
```

#### Implémentation

| Étape | Contenu | Lot |
|---|---|---|
| **H** | Bibliothèque templates `spotlight` + `featureId` | Lot 2 |
| **I** | Campagne type `spotlight` + plafonds | Lot 2 |
| **J** | Placeholders `{addon_name}`, `{addon_url}`, `{addon_tagline}` | Lot 2 |
| **K** | Option settings « Autoriser mention addon dans les campagnes » | Lot 0–2 |
| **L** | Suspension spotlight si `raid_night` active | Lot 2 |
| **M** | Templates spotlight livrés à chaque release (patch notes) | Process release |

#### Effet attendu

- **Candidats** : comprennent comment postuler → plus de MPs structurés → l'Inbox brille sans pub criarde.
- **Membres** : savent qu'il y a un process les soirs raid.
- **Autres guildes / officiers** : voient une guilde organisée ; certains cherchent l'outil (effet bouche-à-oreille, objectif CurseForge).
- **Écosystème Khalandras** : lien optionnel, pas le message principal.

La promo la plus efficace reste un **recrutement propre** : guilde qui répond vite, messages clairs, trial suivi. L'addon se vend par le résultat visible, pas par « TÉLÉCHARGEZ MAINTENANT ».

---

## 4. Grille de réflexion GM/RL (7 piliers)

Référence permanente pour prioriser les features et l'agent de réflexion produit.

| Pilier | Question centrale |
|---|---|
| Recrutement | Qui entre, avec quelles preuves, qui décide ? |
| Roster | Qui joue quoi, bench, alts, dispos ? |
| Présence | Qui manque, patterns, conséquences ? |
| Communication | Quel message, quel canal, quelle urgence ? |
| Progression | Objectifs, essais, trial period ? |
| Santé guilde | Burnout, turnover (sans surveillance toxique) |
| Continuité | Si le GM part, qu'est-ce qui survit ? |

### 3.1 Idées différenciantes (banque)

| Pilier | Idée peu couverte ailleurs |
|---|---|
| Recrutement | Scorecard candidat : tags structurés (spec, dispo, attitude) |
| Roster | Heatmap couverture rôle (saisie 30 s, pas spreadsheet) |
| Présence | Streak d'absence manuel, alerte « 3e absence sans message » |
| Communication | Templates MP liés au statut pipeline |
| Progression | Objectif trial explicite + checklist par soir |
| Santé guilde | Turnover tracker (trials/mois, taux acceptation) |
| Continuité | Handoff pack : export « si je quitte » |

---

## 5. Prompt agent « Cerveau GM/RL »

À utiliser en rule Cursor (`GuildBeacon/.cursor/rules/cerveau-gm-rl.mdc`) ou en tête de session réflexion produit (pas implémentation).

```markdown
# Rôle : Cerveau GM/RL — GuildBeacon

Tu es l'agent de réflexion produit pour un GM/RL WoW (Classic, SoD, Retail).
Tu ne codes pas par défaut. Tu analyses, priorises, proposes, challenge.

## Utilisateur
Officier actif qui construit des outils métier WoW.
Contexte : GuildBeacon (recrutement, inbox, pipeline candidats).
Vision : console officier sobre ; sync future optionnelle.
Contraintes : standalone, zéro dépendance hard, APIs WoW variables.

## Mission à chaque demande
1. Reformuler le besoin en workflow réel (qui, quand, sous quelle pression).
2. Séparer GM vs RL si les besoins divergent.
3. Proposer 2–4 options : safe (MVP), originale (différenciante), ambitieuse (horizon).
4. Par option : problème résolu, données, APIs par version, risques, effort S/M/L.
5. S'inspirer des workflows existants, ne pas cloner MRT/RCLootCouncil/etc.
6. Modèle de données abstrait d'abord, dégradation gracieuse si API absente.
7. Respecter la DA : outil métier, densité, pas de fantasy décoratif.
8. Finir par une recommandation unique + critères de succès mesurables en jeu.

## Anti-patterns
- Features sans action concrète en 30 s d'usage raid/soir
- Dashboards à 10 clics pour une info visible ailleurs
- Données sensibles sans opt-in
- Dépendance tierce (RIO, WCL) comme condition d'usage
- Ton marketing ou « assistant IA » dans les propositions UI

## Format
- Court, direct, français si l'utilisateur parle français.
- Feature proposée : nom interne, user story, module cible.

## Déclencheurs
- « Idée » → brainstorming filtré par les 7 piliers
- « Priorise » → matrice impact / effort / unicité
- « Faisable en Lua ? » → APIs, events, SavedVariables, combat lockdown
- « Original » → au moins une idée non industrialisée dans les addons populaires
```

**Usage recommandé :** un chat « cerveau » (produit), un chat « implémentation » (Lua).  
**Amorçage type :** *« Cerveau GM/RL : [contexte]. Propose 3 pistes (safe / originale / ambitieuse), recommande une pour la prochaine version. »*

---

## 6. Portes de déploiement

Trois seuils distincts. **Listable sur CurseForge/Wago = Porte A minimum.**

### Porte A — Listable (beta publique)

- Addon stable, parcours compréhensible en 10 min sans aide vocale
- Thème public par défaut, pas de marque Khalandras forcée
- README + fiche store FR/EN, screenshots thème default
- Licence et privacy indiquées
- Un testeur **hors guilde Nox** a validé le parcours

### Porte B — Recommandable (release stable)

- Boucle recrutement fermée + multi-officier (données guilde)
- Trial structuré ou équivalent différenciant
- Doc claire, support via issues publiques
- Retail documenté ; Classic supporté ou « retail only » explicite

### Porte C — Produit mature (1.0)

- Brief officier, métriques, handoff pack
- Sync web optionnelle
- Onboarding soigné, roadmap publique

La plupart des addons vivent longtemps entre Porte A et Porte B. Ne pas retarder la publication en attendant Lot 4 ou 7.

---

## 7. Lots de travail

Chaque lot : scope, sortie, porte visée.

### Lot 0 — Fondations publiques

**Scope**

- Système de thèmes : `default` (public) vs `nox` (option ou détection KhalandrasUICore)
- Tokens centralisés dans `Branding.lua` / `Widgets.lua` (plus de couleurs NØX en dur)
- Footer configurable (vide, URL perso, Khalandras si thème nox)
- Locales : retirer références Khalandras des strings par défaut public
- CHANGELOG 0.3.x à jour ; note privacy (local only, pas de télémétrie)
- README orienté installateur externe

**Sortie :** un GM externe ne voit pas Nox ni khalandras.eu sans l'avoir choisi.

**Porte :** prérequis à tout. Pas listable seul.

---

### Lot 1 — Cœur recrutement solo

**Scope**

- Stabiliser 0.3.x (migrations, TestHarness, QA manuelle)
- Triage + pipeline + beacon + settings sans régression
- Éditeur templates beacon + **fiche roster du soir** (`{needs}`)
- Purge / rétention messages et archivés
- Menu clic droit triage (archiver, lu, ouvrir pipeline)
- Début refactor **campagnes** : 2 profils (guilde / roster soir), activation manuelle « ce soir »

**Sortie :** un officier solo gère le recrutement sur un perso ; peut poster guilde et roster sans mélanger les messages.

**Porte :** alpha interne.

---

### Lot 2 — Réponses et pipeline enrichi

**Scope**

- Templates MP par statut (`new`, `contacted`, `trial`, …)
- **Campagnes beacon** : intervalles et fenêtres par campagne, anti-spam par campagne, calendrier raid
- **Templates conditionnels** (poster seulement si rôle manquant)
- Bouton répondre (whisper pré-rempli, pas d'envoi auto)
- Tags candidat (spec, dispo, etc.)
- Stats conversion (new → trial → accepted)
- Import JSON avec merge intelligent

**Sortie :** boucle message → décision → réponse dans l'addon.

**Porte :** candidat **Porte A** (avec Lot 0 + Lot 3).

---

### Lot 3 — Packaging et confiance

**Scope**

- Fiche CurseForge/Wago : screenshots thème default, pitch FR/EN
- TOC, semver, notes de version par release
- Panneau « Première utilisation » (inbox, beacon dry-run, live confirm)
- `/gb help` et tooltips autonomes
- Minimap / broker optionnel, badge non-lus
- Issues GitHub publiques
- Classic : TOC + fallbacks, ou badge « Retail only » sur la fiche

**Sortie :** publish sans honte.

**Porte :** **ouvre les plateformes** (avec Lot 0 + Lot 2).

---

### Lot 4 — Données guilde (multi-officier)

**Scope**

- `GuildBeaconDB.guildStores[guildKey]` + migration profil → guilde
- Config UI perso vs données guilde partagées
- Permissions grade officier ; `updatedBy` / `updatedAt`
- Export guilde filtré, backup clipboard

**Sortie :** plusieurs officiers, même pipeline.

**Porte :** **Porte B**.

---

### Lot 5 — Trial métier

**Scope**

- Fiche trial : dates, objectifs, checklist par soir
- Timeline `trial_session`
- Filtre / badge trials actifs
- Rappel pré-raid opt-in
- Transition trial → accepted/rejected avec raison

**Sortie :** le statut `trial` devient un processus.

**Porte :** différenciation Porte B+.

---

### Lot 6 — Brief officier (léger)

**Scope**

- Popup brief optionnelle avant soir raid
- Roster couverture manuel (tank/heal/melee/range)
- Flags absence + streak
- Jours raid en config

**Sortie :** préparation recrutement en 2 min, pas addon raid.

**Porte :** nice-to-have avant 1.0, pas bloquant plateformes.

---

### Lot 7 — Sync Khalandras (optionnel)

**Scope**

- Schéma export v2, import site khalandras.eu
- Dashboard web + bot Discord
- Activé seulement si opt-in explicite « Sync cloud »

**Sortie :** écosystème Khalandras, pas dépendance utilisateur CurseForge.

**Porte :** post Porte A ; parallélisable avec Lot 4–5.

---

### Lot 8 — Maturité 1.0

**Scope**

- Handoff pack
- Métriques turnover / conversion
- Son nouveau MP (off par défaut)
- Tests Classic si déclaré supporté
- Roadmap publique trimestrielle

**Sortie :** vision « complète » section 1.3.

**Porte :** **Porte C**.

---

## 8. Enchaînement et priorités

```
Lot 0 ──┬── Lot 1 ── Lot 2 ── Lot 3  ══► PORTE A (listable beta)
        │
        └── thème public en parallèle de Lot 1–2

Lot 4 ── Lot 5 ── Lot 6  ══► PORTE B (recommandable)

Lot 7 (sync optionnelle)     Lot 8  ══► PORTE C (1.0 mature)
```

**Chemin le plus court vers CurseForge :** Lot 0 → Lot 1 → Lot 2 → Lot 3.

**Ne pas attendre** Lot 4 ou 7 pour publier. Documenter en beta : « v0.x = un officier, export JSON pour partager ».

---

## 9. Checklist Porte A (publish)

- [ ] Thème `default` actif sans violet NØX ni lien Khalandras forcé
- [ ] Parcours validé : install → `/gb` → MP capturé → pipeline → beacon dry-run → export JSON
- [ ] README + description store FR/EN
- [ ] Screenshots thème default
- [ ] Pas de crash reload / logout connu
- [ ] Licence et privacy indiquées
- [ ] Version semver + changelog par release
- [ ] Beta testeur hors guilde Nox OK sans vocal

---

## 10. Améliorations projet (transverses)

### 9.1 Architecture thème

Extraire les couleurs NØX vers un registre de thèmes :

```lua
-- conceptuel
Branding:GetTheme()  → { gold, accent, signal, bgPrimary, ... }
Branding:SetTheme("default" | "nox")
```

Thème `default` : accent bordeaux `#8c2a3a` (aligné TOC), pas phosphor violet.

### 9.2 Produit vs canal

Footer, README, patch notes : liens génériques par défaut (repo GitHub ou futur site neutre). Khalandras = opt-in.

### 9.3 Modèle guilde

Risque crédibilité publique : silo par perso. Lot 4 sépare « addon perso » et « outil guilde ». Acceptable en beta solo si documenté.

### 9.4 Pitch plateforme

> *Recruitment inbox, candidate pipeline and scheduled guild beacon for officers.*

Pas « console NØX Khalandras ».

### 9.5 Licence

Décider avant Porte A : ARR source visible vs MIT/LGPL pour contributions.

### 9.6 Tests sans WoW

Étendre TestHarness : import/export, migrations DB, merge candidats.

### 9.7 Documentation

| Fichier | Rôle |
|---|---|
| `README.md` | Installateur externe |
| `docs/vision-et-roadmap.md` | Ce document |
| `docs/art-direction.md` | DA détaillée (à scinder futur : `themes/default.md`, `themes/nox.md`) |
| `docs/patchnotes/` | Notes par version |
| `.cursor/rules/` | Workflow dev, pas dans le zip CurseForge |

### 9.8 Module boundary

Brief (Lot 6) reste recrutement-centric. Pas de dérive raid/loot/DPS.

---

## 11. Référence fonctionnelle actuelle

### 10.1 Commandes

| Commande | Action |
|---|---|
| `/gb` | Ouvre le dashboard (triage) |
| `/gb dashboard` | Tableau officiers |
| `/gb config` | Réglages |
| `/gb beacon start\|stop\|preview\|now` | Balise |
| `/gb export` | Export candidats JSON |
| `/gb status` | État modules + stats |
| `/gb resetui` | Réinitialise géométrie UI |

### 10.2 Modules et statuts candidats

**Modules :** Beacon, Inbox, Candidates.

**Statuts :** `new`, `contacted`, `trial`, `accepted`, `rejected`, `archived`.

**SavedVariables :** `GuildBeaconDB`.

### 10.3 Direction artistique (résumé)

Voir `docs/art-direction.md` pour le détail.

| Token | Hex | Usage |
|---|---|---|
| Or | `#d4af37` | Structure, titres, actif |
| Phosphor | `#b794f6` | Accent NØX (thème nox) |
| Bordeaux | `#8c2a3a` / wine `#6b1d3a` | Signal, marque |
| Muted | `#9a8b7f` | Métadonnées |

Règles : pas de `BackdropTemplate`, pas d'animations, vanilla-first pour les icônes.

---

## 12. Horizon post-1.0 (optionnel)

À traiter seulement après traction plateformes :

- Intégration WCL lecture seule
- Identité cross-char / alts
- Module M+ roster
- Suggestions IA de réponses (risque ton + privacy)
- App mobile compagnon

---

## 13. Changelog document

| Version | Date | Changements |
|---|---|---|
| 1.0 | 2026-06-29 | Création : synthèse vision, agent cerveau, lots, portes A/B/C, Nox vs public |
| 1.1 | 2026-06-29 | Section 3 : campagnes beacon, templates auto guilde vs roster du soir |
| 1.2 | 2026-06-29 | Section 3.13 : promo addon et campagnes spotlight métiers/features |
