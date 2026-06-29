# GuildBeacon — Maquette dashboard (vision produit)

Référence UI pour l’implémentation post-0.3.0 : campagnes beacon, roster du soir, spotlight métiers, pipeline enrichi.

**Version doc :** 1.0 · **Cible addon :** 0.4.0+  
**DA :** `docs/art-direction.md` · **Vision :** `docs/vision-et-roadmap.md` §3  
**Code actuel :** `UI/Dashboard.lua` (4 onglets, balise monolithique à refactorer)

---

## 1. Principes layout

| Règle | Valeur |
|---|---|
| Fenêtre défaut | **720 × 600 px** (min 560×440, max 800×680) |
| Modes corps | `splitView` (liste 35 % + détail 65 %) · `beaconView` (campagnes 32 % + panneau 68 %) · `fullView` (réglages scroll) |
| Un seul mode visible | `Refresh()` bascule `SetShown` |
| Drag | Header + bande titre |
| Fermeture | × custom, Échap (`UISpecialFrames`) |
| Thème default | Accent bordeaux signal ; phosphor réservé thème `nox` |
| Footer | URL configurable ; vide par défaut (public) |

---

## 2. Chrome global (tous onglets)

```
┌─ wine 3px ─────────────────────────────────────────────────────────── [×] ┐
│ ◆ GuildBeacon · Tableau officiers                                       │
│ ─── hairline accent ─── gold rule 1px ───────────────────────────────── │
├─────────────────────────────────────────────────────────────────────────┤
│ Guilde ~48m · Roster OFF · 3 non-lus · 2 essais · simulation ON         │
├─────────────────────────────────────────────────────────────────────────┤
│ [À traiter 3] [Pipeline] [Campagnes] [Réglages]                         │
│       ▔▔▔▔ or 2px                                                         │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│                         (corps = onglet actif)                          │
│                                                                         │
├─────────────────────────────────────────────────────────────────────────┤
│ v0.4.0                                                          [?]     │
└─────────────────────────────────────────────────────────────────────────┘
```

### Bande statut (ligne sous header)

Contenu dynamique, texte `muted`, séparateurs ` · ` :

| Segment | Exemple | Source |
|---|---|---|
| Campagne guilde | `Guilde ~48m` ou `Guilde OFF` | prochain post campagne `guild` |
| Campagne roster | `Roster ~18m` · `fenêtre 18h30–20h30` ou `Roster OFF` | campagne `raid_night` |
| Inbox | `3 non-lus` | `Store:GetUnreadCount()` |
| Pipeline | `2 essais` | stats statut `trial` |
| Mode | `simulation ON` / `LIVE` | `beacon.dryRun` global |

Clic sur un segment : ouvre l’onglet concerné (campagnes pré-sélectionne la campagne).

### Onglets

| ID | Label FR | Label EN | Badge | Mode corps |
|---|---|---|---|---|
| `triage` | À traiter | Inbox | non-lus | splitView |
| `pipeline` | Pipeline | Pipeline | essais actifs (opt.) | splitView |
| `beacon` | Campagnes | Campaigns | campagnes ON (opt.) | beaconView |
| `settings` | Réglages | Settings | — | fullView scroll |

Renommage : **Balise** → **Campagnes** (reflète le modèle multi-campagnes).

### Footer

- Gauche : version (`v0.4.0`)
- Droite : lien optionnel (`{addon_url}`) ou bouton `?` → aide / première utilisation
- Plus de lien Khalandras imposé (thème public)

---

## 3. Onglet « À traiter » (triage)

Master–detail inchangé dans la structure, actions enrichies.

```
┌─ liste 35% ─────────────┬─ détail 65% ─────────────────────────────────┐
│ [Tout lire]  Filtre v   │  Joueur-Royaume                              │
│                         │  ● nouveau · il y a 12 min · M+ 2845           │
│ ◆ MP  Candidat-Rkt       │  ─────────────────────────────────────────── │
│   « cherche guilde heal»│  Messages                                   │
│ ◆ GU  Membre-Guild       │  ┌ inset ─────────────────────────────────┐  │
│   « je suis dispo soir»  │  │ W  il y a 12 min                       │  │
│   GU  Autre-Rkt          │  │ cherche guilde pour raid, heal rsh     │  │
│   « candidature dps»     │  └────────────────────────────────────────┘  │
│                         │  Tags  [heal] [soir] [+ tag]                   │
│                         │  Notes officier                                │
│                         │  ┌──────────────────────────────────────────┐  │
│                         │  │ Essai prévu mardi, bonne attitude        │  │
│                         │  └──────────────────────────────────────────┘  │
│                         │  Chronologie (3)                               │
│                         │  · statut new -> contacted · il y a 2 h      │
│                         │  ─────────────────────────────────────────── │
│                         │  [Répondre] [Pipeline] [Contacté] [Essai]    │
│                         │  [Rejeter]  [Archiver]                       │
└─────────────────────────┴────────────────────────────────────────────────┘
```

| Élément | Comportement |
|---|---|
| Losange `◆` (texture) | Non-lu ; disparaît au clic / marquer lu |
| Icône canal | `W` whisper · `GU` guilde · `BN` Battle.net |
| Filtre | Non-lus · Canal · Aujourd’hui |
| **Répondre** | Ouvre whisper pré-rempli (template statut `new`) |
| **Pipeline** | Passe statut + bascule onglet pipeline sur la fiche |
| Clic droit ligne | Marquer lu · Archiver · Ouvrir pipeline · Copier nom |

Barre triage (sous onglets, au-dessus liste) : `[Tout lire]` · filtre déroulant · compteur.

---

## 4. Onglet « Pipeline »

Toolbar + master–detail.

```
┌─ toolbar ───────────────────────────────────────────────────────────────┐
│ [Rechercher...]  Statut v  [Tous][Essais][Nouveaux]  Tri: Recent v     │
│ Assigné: [Moi v] [Tous]                                                  │
└─────────────────────────────────────────────────────────────────────────┘
┌─ liste ─────────────────┬─ détail ──────────────────────────────────────┐
│ Heal-Royaume      essai │  Heal-Royaume                                 │
│ · trial · M+ 2845       │  ● essai · assigné Khalandras · 3 msgs        │
│ Dps2-Royaume      nouveau│  ─────────────────────────────────────────── │
│ Melee-Rkt         contacté│  Fiche essai (si statut trial)              │
│ ...                     │  ┌ inset ─────────────────────────────────┐  │
│                         │  │ Début: 24/06 · Objectif: 3 raids       │  │
│                         │  │ [x] Raid 1  [ ] Raid 2  [ ] Raid 3     │  │
│                         │  └────────────────────────────────────────┘  │
│                         │  Tags · Notes · Messages · Chronologie       │
│                         │  [Répondre] [Accepté] [Rejeté] [RIO]         │
└─────────────────────────┴────────────────────────────────────────────────┘
```

| Élément | Vision |
|---|---|
| Filtre **Essais** | `status == trial` |
| **Assigné** | Filtre `assignedTo` (Lot 4 store guilde) |
| Encart **Fiche essai** | Visible si `trial` ; checklist raids (Lot 5) |
| Bouton **RIO** | Refresh enrichissement manuel |

---

## 5. Onglet « Campagnes » (ex-Balise)

Nouveau mode `beaconView` : sidebar campagnes + panneau contextuel.

### 5.1 Vue d’ensemble (défaut)

```
┌─ sidebar 32% ───────────┬─ panneau 68% ────────────────────────────────┐
│ CAMPAGNES               │  Vue d'ensemble                               │
│                         │  Mode: simulation ON  [ ] Passer en LIVE      │
│ [ON]  Guilde            │  [ ] Je confirme les posts canal guilde       │
│       ~48 min · 2/8 jr  │  ─────────────────────────────────────────── │
│                         │  Prochains posts                              │
│ [OFF] Roster ce soir    │  · Guilde      ~48 min  [guilde]              │
│       Activer ce soir   │  · Roster      --        (inactif)            │
│                         │  · Spotlight   lun.      [guilde]              │
│ [OFF] Spotlight         │  ─────────────────────────────────────────── │
│       hebdo             │  Aperçu prochain (Guilde)                     │
│                         │  ┌ inset ─────────────────────────────────┐  │
│ [OFF] Mention addon     │  │ [MaGuilde] On recrute pour Ny'alotha.  │  │
│       mensuel           │  │ MP Khalandras : spec, dispo.           │  │
│                         │  └────────────────────────────────────────┘  │
│ ─────────────────       │  [Poster maintenant v]  [Aperçu tout]         │
│ + Nouvelle campagne     │  ─────────────────────────────────────────── │
│   (horizon)             │  Posts récents (toutes campagnes)             │
│                         │  · il y a 1 h · LIVE · guilde · « On recrute…»│
└─────────────────────────┴────────────────────────────────────────────────┘
```

### 5.2 Détail campagne « Guilde »

```
┌─ sidebar ───────────────┬─ panneau ────────────────────────────────────┐
│ [ON]  Guilde      <<<   │  Campagne · Guilde                           │
│ [OFF] Roster            │  ─────────────────────────────────────────── │
│ ...                     │  [x] Active   Type: guild                     │
│                         │  Intervalle [60] min  Jitter [5] min          │
│                         │  Max posts / jour [8]                         │
│                         │  Canaux [x] Guilde  [ ] Say  [ ] Yell         │
│                         │  Fenêtre: [x] 24h/24  ou  jours/heures...     │
│                         │  ─────────────────────────────────────────── │
│                         │  Templates (rotation)                         │
│                         │  ┌ 1. Recrutement général          [Edit] ┐ │
│                         │  │ [{guild}] On recrute ! MP {contact}...   │ │
│                         │  └─────────────────────────────────────────┘ │
│                         │  ┌ 2. Recrutement raid             [Edit] ┐ │
│                         │  │ [{guild}] Raid {raid_name}...           │ │
│                         │  └─────────────────────────────────────────┘ │
│                         │  [+ Template]                                 │
│                         │  Placeholders: {guild} {contact} {raid_name}  │
└─────────────────────────┴────────────────────────────────────────────────┘
```

### 5.3 Détail campagne « Roster ce soir »

```
┌─ sidebar ───────────────┬─ panneau ────────────────────────────────────┐
│ [ON]  Guilde            │  Campagne · Roster ce soir                   │
│ [ON]  Roster      <<<   │  ─────────────────────────────────────────── │
│ ...                     │  [x] Active ce soir   Heure raid [20:30]     │
│                         │  Fenêtre pré-raid: de [18:30] à [20:30]       │
│                         │  Intervalle [20] min · Max [6] posts / jour   │
│                         │  ─────────────────────────────────────────── │
│                         │  ROSTER DU SOIR                               │
│                         │  Cible: 2T / 4H / 10 DPS (depuis calendrier)  │
│                         │  Manques:                                     │
│                         │  [ ] Tank   [x] Heal   [ ] Mêlée   [x] Range  │
│                         │  → {needs} = « heal, chasseur distance »       │
│                         │  ─────────────────────────────────────────── │
│                         │  Template actif (si manques > 0)              │
│                         │  ┌ inset ─────────────────────────────────┐  │
│                         │  │ [{guild}] Ce soir {raid_time}: besoin   │  │
│                         │  │ {needs_short}. MP {contact}.            │  │
│                         │  └────────────────────────────────────────┘  │
│                         │  Si roster complet: silence ou 1× « complet » │
└─────────────────────────┴────────────────────────────────────────────────┘
```

### 5.4 Détail campagne « Spotlight »

```
│  Campagne · Spotlight métiers                                              │
│  [ ] Active   1 post / semaine · canal guilde                              │
│  ─────────────────────────────────────────────────────────────────────── │
│  Rotation features (cocher celles à inclure):                              │
│  [x] Inbox    [x] Trial    [ ] Roster    [ ] Export                        │
│  Prochain: « MP un officier avec spec et dispos » (feature inbox)          │
│  [Prévisualiser]                                                           │
│  Note: suspendue automatiquement si Roster ce soir actif                    │
```

### 5.5 Éditeur template (panneau modal ou remplace détail)

```
┌─ Éditer template ─────────────────────────────────────────────── [×] ─┐
│ Nom: [Recrutement général]                                            │
│ Corps:                                                                │
│ ┌─────────────────────────────────────────────────────────────────┐   │
│ │ [{guild}] Guilde FR recrute. MP {contact} : spec, dispo.       │   │
│ └─────────────────────────────────────────────────────────────────┘   │
│ Insérer: [guild] [contact] [raid_time] [needs] [addon_name]           │
│ Aperçu live:                                                          │
│ [MaGuilde] Guilde FR recrute. MP Khalandras : spec, dispo.            │
│ Conditions (optionnel):                                               │
│ [ ] Poster seulement si rôle heal manquant                            │
│ [Annuler]                                    [Enregistrer]            │
└───────────────────────────────────────────────────────────────────────┘
```

---

## 6. Onglet « Réglages »

Scroll vertical, sections repliables.

```
┌─ scroll ────────────────────────────────────────────────────────────────┐
│ ▼ INBOX                                                                 │
│   [x] Capturer MP    [x] Capturer chat guilde    Mots-clés [edit]      │
│   Rétention max [300] messages                                          │
│ ─────────────────────────────────────────────────────────────────────── │
│ ▼ CANDIDATS                                                             │
│   [x] Enrichissement Raider.IO    [x] Auto à la réception               │
│   Statuts par défaut · Tags suggérés                                    │
│ ─────────────────────────────────────────────────────────────────────── │
│ ▼ CAMPAGNES (global)                                                    │
│   [x] Officiers uniquement    Grade min [1]                              │
│   [x] Pause en instance    [x] Pause en combat                          │
│   Anti-spam global min [300] s                                          │
│   Calendrier raid: Mar 20h30 · Jeu 20h30  [Modifier]                    │
│ ─────────────────────────────────────────────────────────────────────── │
│ ▼ RÉPONSES MP (templates statut)                                        │
│   new · contacted · trial · accepted  [Éditer chaque]                   │
│ ─────────────────────────────────────────────────────────────────────── │
│ ▼ APPARENCE                                                             │
│   Thème [Default v] [Nox]    Échelle [100%]                             │
│   Footer lien [                    ]  (vide = aucun)                  │
│   [x] Autoriser mention addon dans campagnes promo                      │
│ ─────────────────────────────────────────────────────────────────────── │
│ ▼ DONNÉES                                                               │
│   [Exporter JSON]  [Importer JSON]  [Purger archivés]                    │
│ ─────────────────────────────────────────────────────────────────────── │
│ ▼ DIAGNOSTICS                                      [Replier ^]          │
│   Simulation inbox · Dry beacon tick · Tag [GB_TEST]                    │
│   [Reset UI]                                                            │
└─────────────────────────────────────────────────────────────────────────┘
```

Les réglages **par campagne** restent dans l’onglet Campagnes. Cette vue = defaults globaux + inbox + candidats + apparence.

---

## 7. États et feedback

| État | Traitement visuel |
|---|---|
| simulation ON | Texte `info` dans statut + bandeau discret campagnes |
| LIVE sans confirm | Texte `error` · boutons poster désactivés · lien réglages |
| Campagne active | Pastille `success` dans sidebar |
| Roster urgent (manques + fenêtre) | Segment statut `warning` · badge onglet Campagnes |
| Nouveau MP | Badge onglet À traiter + losange liste |
| Trial actif | Badge pipeline optionnel |

Popup confirmation LIVE (existant, conservé) :

```
Poster ce message sur le canal guilde ?
[Message tronqué…]
[Annuler]  [Confirmer]
```

---

## 8. Responsive (redimensionnement)

| Largeur | Adaptation |
|---|---|
| ≥ 680 | Layout nominal 35/65 ou 32/68 |
| 560–679 | Liste 40 %, police corps inchangée, toolbar pipeline wrap |
| min 560 | Masquer sous-titres liste, truncate 40 car. |

Hauteur < 480 : masquer chronologie détail, garder messages + actions.

---

## 9. Mapping implémentation

| Maquette | Fichier / module | Priorité |
|---|---|---|
| Chrome + statut multi-campagnes | `Dashboard.lua` | Lot 2 |
| Renommer onglet Balise → Campagnes | Locales + `TAB_IDS` | Lot 1 |
| `beaconView` + sidebar | `Dashboard.lua` | Lot 2 |
| Fiche roster soir | `Modules/Beacon/` ou `Modules/Campaigns/` | Lot 1–2 |
| Templates éditeur | `Dashboard.lua` + `Templates.lua` | Lot 1 |
| Fiche essai pipeline | `Dashboard.lua` detail | Lot 5 |
| Tags + Répondre | `Dashboard.lua` + store | Lot 2 |
| Settings sections | `RenderSettings()` | Lot 1–2 |
| Thème default footer vide | Lot 0 |

`layoutVersion` : passer à **12** lors du refactor `beaconView`.

---

## 10. Changelog document

| Version | Date | Changements |
|---|---|---|
| 1.0 | 2026-06-29 | Maquette complète alignée vision campagnes, roster, spotlight, pipeline enrichi |
