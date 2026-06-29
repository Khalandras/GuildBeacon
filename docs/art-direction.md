# GuildBeacon — Direction artistique

Document de référence pour l’addon WoW, le site **khalandras.eu/guildbeacon** et tout produit satellite (dashboard web, Discord, exports).

**Version doc :** 2.0 · **Addon :** 0.3.0+  
**Source de vérité code :** `Core/Branding.lua`, `Core/Widgets.lua`, `UI/Dashboard.lua`

---

## 1. Positionnement

GuildBeacon est un **outil métier pour officiers de guilde** : inbox de recrutement, pipeline candidats, balise de messages. Ce n’est pas un addon « fantasy décoratif ».

| Axe | Choix |
|---|---|
| Registre | Professionnel, sobre, crédible |
| Densité | Compacte — beaucoup d’info, peu de padding superflu |
| Motion | Quasi nulle (pas d’animations) |
| Iconographie | Textures Blizzard natives (chat, guilde) |
| Public | Officiers — sessions courtes, usage fréquent |

**Phrase guide :** *Console de recrutement de guilde premium, pas addon de cosplay.*

---

## 2. Identité de marque

### 2.1 Nom

| Partie | Couleur | Hex | Usage |
|---|---|---|---|
| **Guild** | Or Khalandras | `#d4af37` | Institution, sérieux, structure |
| **Beacon** | Phosphor `#b794f6` (UI) / Bordeaux `#8c2a3a` (TOC, signal) | Signal, accent bar header, marque |

**WoW chat titre :** `|cffd4af37Guild|r|cffb794f6Beacon|r` (dashboard) · `|cffd4af37Guild|r|cff8c2a3aBeacon|r` (liste addons)  
**CSS / web :** `.brand-guild { color: #d4af37 }` · `.brand-beacon { color: #8c2a3a }`

### 2.2 Logo

Pas de logo vectoriel dédié aujourd’hui. Le logotype **est** le mot bicolore. Sur le web : texte HTML/CSS, pas d’image raster sauf favicon future.

### 2.3 Relation Khalandras

- **Standalone :** palette autonome, zéro dépendance visuelle.
- **Avec KhalandrasUICore :** texture d’accent optionnelle via `Branding:GetAccentTexture()`.
- **khalandras.eu :** même palette or/bordeaux que KhalandrasUI ; GuildBeacon = produit guilde, pas satellite UI générique.

---

## 3. Palette complète

### 3.1 Couleurs structurelles

| Token | Hex | RGB (0–255) | Rôle |
|---|---|---|---|
| `gold` | `#d4af37` | 212, 175, 55 | Titres, onglet actif, badges, noms, non-lus |
| `bordeaux` | `#8c2a3a` | 140, 42, 58 | Marque « Beacon », barre d’accent |
| `muted` | `#9a8b7f` | 154, 139, 127 | Métadonnées, timestamps, corps secondaire |

### 3.2 Fonds & surfaces (addon WoW — DA NØX)

Textures `WHITE8X8` + teinte vertex. **Pas de `BackdropTemplate`** (évite les carrés magenta).

| Token | Hex | Rôle |
|---|---|---|
| `abyss` | `#040408` | Fond fenêtre principale |
| `bgPrimary` | `#08080e` | Corps master–detail |
| `bgSecondary` | `#0e0c14` | Listes scroll, status, footer |
| `bgElevated` | `#141018` | Panneau détail, sections encadrées |
| `bgSurface` | `#1a1522` | Onglet actif, ligne sélectionnée |
| `nox` | `#2d1848` | Wash header (22 % alpha) |
| `phosphor` | `#b794f6` | Sigil, scrollbar, glow header |
| `wine` | `#6b1d3a` | Barre signal 3 px sous le chrome fenêtre |
| `border` | `#3a3248` | Contours 1 px, séparateurs |

### 3.3 Sémantique statuts (pipeline)

| Statut | RGB | Hex approx. | Intention |
|---|---|---|---|
| `new` | 212, 175, 55 | `#d4af37` | À traiter — même or que la marque |
| `contacted` | 89, 166, 242 | `#59a6f2` | Suivi en cours |
| `trial` | 166, 115, 242 | `#a673f2` | Phase d’évaluation |
| `accepted` | 89, 217, 115 | `#59d973` | Résolu positivement |
| `rejected` | 217, 89, 89 | `#d95959` | Clôturé négativement |
| `archived` | 128, 128, 128 | `#808080` | Hors pipeline actif |

### 3.4 Alertes & modes

| État | Couleur | Usage |
|---|---|---|
| Alerte / danger | `rgb(230, 90, 90)` | Mode LIVE non confirmé, posts bloqués |
| Simulation (dry-run) | Or `#d4af37` | Statut barre, historique `[dry-run]` |
| Live armé | Rouge/orange | Confirmation requise avant post guilde |
| Données test | `rgb(230, 153, 51)` | Badge `[TEST]` |

**Règle :** rouge = danger uniquement, jamais décoratif.

---

## 4. Typographie

### 4.1 Addon WoW

Fonts **Blizzard natives** uniquement — pas de police custom.

| Niveau | Font object | Taille | Couleur |
|---|---|---|---|
| Titre fenêtre | `GameFontNormal` | 16 px | Or `rgb(212, 175, 55)` |
| Section / nom candidat | `GameFontNormal` | 14 px | Or |
| Corps liste | `GameFontHighlight` | 12 px | `textPrimary` |
| Métadonnées | `GameFontHighlightSmall` | défaut | `textSecondary` |

**Sigil :** losange texture (rotation 45°), jamais le caractère Unicode `◈` (non supporté en jeu).

Hiérarchie par **couleur + taille**, pas par graisse exotique.

### 4.2 khalandras.eu (recommandé)

| Élément | Font stack | Poids |
|---|---|---|
| Titres page | `system-ui, -apple-system, Segoe UI, sans-serif` | 600 |
| Corps | idem | 400 |
| Code / IDs | `ui-monospace, Consolas, monospace` | 400 |

Tailles suggérées : H1 28px · H2 20px · corps 15px · small 13px · line-height 1.5.

---

## 5. Composants UI (addon)

### 5.1 Fenêtre dashboard (`/gb`)

| Propriété | Valeur |
|---|---|
| Taille défaut | **720 × 600 px** (min 560×440, max 800×680) |
| Position | Déplaçable, sauvegardée (`ui.framePoint`) |
| Fermeture | Bouton × custom, **Échap** (`UISpecialFrames`) |
| Drag | Header + bande titre uniquement |

**Maquette détaillée (vision 0.4+) :** `docs/dashboard-maquette.md` (campagnes, roster du soir, pipeline essai, réglages par sections).

**Chrome global :**

```
┌─ wine 3px ─────────────────────────────────────────────────────── [×] ┐
│ ◆ GuildBeacon · Tableau officiers                                     │
│ ─── hairline accent ─── gold rule ──────────────────────────────────── │
├───────────────────────────────────────────────────────────────────────┤
│ Guilde ~48m · Roster OFF · 3 non-lus · 2 essais · simulation ON       │
├───────────────────────────────────────────────────────────────────────┤
│ [À traiter 3] [Pipeline] [Campagnes] [Réglages]                       │
│       ▔▔▔▔ or 2px                                                       │
├────────────────────────────┬──────────────────────────────────────────┤
│ (splitView ou beaconView)  │                                          │
├────────────────────────────┴──────────────────────────────────────────┤
│ v0.4.0                                                          [?]   │
└───────────────────────────────────────────────────────────────────────┘
```

Onglet **Campagnes** remplace **Balise** : sidebar campagnes (guilde, roster, spotlight, promo) + panneau détail. Voir maquette §5.

### 5.1b Modes corps

| Mode | Onglets | Layout |
|---|---|---|
| `splitView` | À traiter, Pipeline | Liste 35 % + détail 65 % |
| `beaconView` | Campagnes | Sidebar 32 % + panneau 68 % |
| `fullView` | Réglages | Scroll pleine largeur |

Une seule vue visible à la fois (`Refresh` bascule `SetShown`).

### 5.2 Onglets segmentés

| État | Fond | Texte | Soulignement |
|---|---|---|---|
| Inactif | transparent | `textMuted` | aucun |
| Hover | `bgHover` 55 % | `textSecondary` | — |
| Actif | `bgSurface` | `textPrimary` | **or 2 px** |
| Badge compteur | — | or, à droite du label | — |

Onglets : **À traiter** · **Pipeline** · **Campagnes** · **Réglages**

### 5.3 Layout master–detail et campagnes

- **splitView** : triage + pipeline (liste + détail).
- **beaconView** : campagnes (sidebar + panneau détail / éditeur).
- **fullView** : réglages (pleine largeur corps, scroll).
- Une seule vue visible à la fois (`Refresh` bascule `SetShown`).
- Séparateur vertical 1 px `border` entre colonnes.

### 5.4 Boutons & formulaires

- Boutons **outline custom** (`CreateButton`) : variants `primary` (wine), `secondary`, `ghost`, `danger`.
- Fermeture **×** custom (traits, pas `UIPanelCloseButton`).
- Champs texte : fond `bgPrimary`, sans bordure Blizzard (`StyleEditBox`).
- Scrollbar : piste `bgElevated`, curseur **phosphor** 6 px.
- Tooltips : `GameTooltip` fond sombre.

### 5.5 Tooltips

`GameTooltip` standard : titre blanc, corps `rgb(204, 191, 179)`.

---

## 6. Mapping khalandras.eu

### 6.1 Pages prévues

| Page | URL suggérée | DA |
|---|---|---|
| Accueil produit | `/guildbeacon` | Hero bicolore, screenshot dashboard |
| Patch notes | `/guildbeacon/patchnotes/{version}` | Même structure que KhalandrasUI |
| Dashboard web (futur) | `/guildbeacon/app` | Reprend layout master–detail + tokens |

### 6.2 Variables CSS (à inclure sur le site)

```css
:root {
  --gb-gold: #d4af37;
  --gb-bordeaux: #8c2a3a;
  --gb-muted: #9a8b7f;
  --gb-bg: #0f0e0c;
  --gb-surface: #141210;
  --gb-surface-elevated: #1a1714;
  --gb-border: rgba(89, 71, 51, 0.9);
  --gb-text: #e8e4df;
  --gb-text-muted: #9a8b7f;
  --gb-danger: #e65a5a;
  --gb-success: #59d973;
}
```

### 6.3 Discord (embeds release)

Aligné sur `git-release-patchnotes.mdc` :

| Champ | Valeur |
|---|---|
| Couleur embed principale | `#d4af37` (or) |
| Accent / footer | `#8c2a3a` (bordeaux) |
| Canal suggéré | `#guildbeacon-updates` |
| Lien patch notes | `https://khalandras.eu/guildbeacon/patchnotes/{version}` |

### 6.4 Export JSON → dashboard web

Les candidats exportés (`/gb export`) alimenteront le dashboard khalandras.eu. Côté web :

- Reprendre les **couleurs de statut** (section 3.3).
- Badge `[TEST]` si `person.test === true` ou body contient `[GB_TEST]`.
- Timeline : même ordre chronologique inverse que l’addon.

---

## 7. Principes directeurs (checklist)

1. **Or = structure** — navigation, titres, éléments actifs.
2. **Bordeaux = signal** — marque, accent, urgence modérée.
3. **Muted = contexte** — tout ce qui n’exige pas d’action immédiate.
4. **Rouge = danger** — LIVE, confirmations, erreurs.
5. **Vanilla-first** — icônes chat/guilde Blizzard ; contrôles custom seulement quand le template casse la DA.
6. **Pas de `BackdropTemplate`** ni glyphes Unicode décoratifs en jeu.
7. **Pas de dégradés, pas d’ombres portées, pas d’animations** (addon et web).
7. **Cohérence Khalandras** — même or/bordeaux que l’écosystème, ton sobre.

---

## 8. Anti-patterns (interdits)

- Palette arc-en-ciel sur les statuts hors sémantique définie.
- Boutons custom qui ne ressemblent plus à WoW **sauf** le design system `Widgets.lua` validé.
- Glyphe `◈` ou tout caractère non rendu par les fonts WoW.
- `BackdropTemplate` / `SetBackdrop` sur les frames addon (carré magenta).
- Texte marketing criard dans l’UI (« SUPER RECRUTEMENT !!! »).
- Fond clair dans l’addon (non prévu).
- Logo ou illustration fantasy lourde qui concurrence l’info.
- Emojis comme icônes de statut (réservé au web si vraiment nécessaire).

---

## 9. Évolutions prévues

| Priorité | Élément | Notes |
|---|---|---|
| P1 | Favicon SVG bicolore | `G` or + point bordeaux |
| P1 | Screenshot officiel dashboard | Page khalandras.eu |
| P2 | Sync visuelle KhalandrasUICore | Texture accent partagée |
| P2 | Thème web dashboard | CSS variables ci-dessus |
| P3 | Sons discrets (nouveau MP) | Optionnel, désactivé par défaut |

---

## 10. Références code

| Fichier | Contenu DA |
|---|---|
| `Core/Branding.lua` | Tokens `gold`, `bordeaux`, `muted` ; `Title()` |
| `Core/Widgets.lua` | `STATUS_COLORS`, backdrops, tabs, rows, badges |
| `UI/Dashboard.lua` | Layout, status bar, master–detail |
| `GuildBeacon.toc` | Titre coloré addon list |
| `.cursor/rules/git-release-patchnotes.mdc` | Couleurs Discord |

---

## 11. Changelog document

| Version | Date | Changements |
|---|---|---|
| 1.0 | 2025-06-24 | Création initiale — post refonte dashboard v0.3.0 |
| 2.0 | 2025-06-24 | DA NØX alignée code : tokens abyss/phosphor, layout chaîné, maquette canvas |
| 2.1 | 2026-06-29 | Chrome campagnes ; maquette détaillée → `docs/dashboard-maquette.md` |
