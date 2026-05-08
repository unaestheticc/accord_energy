# AcCoRD_energy — Guide de configuration

AcCoRD_energy simule la communication moléculaire dans un environnement biologique (artériole, tissu, etc.) avec un système de gestion de l'énergie pour les nanocapteurs. Ce guide explique comment écrire un fichier de configuration JSON et comment lancer une simulation.

---

## Lancer une simulation

```bash
# Compiler
cd src && bash build_accord_opt_dub
cp ../bin/accord_dub.out ../bin/accord_energy_linux

# Exécuter
./bin/accord_energy_linux config/mon_fichier.txt
```

Les fichiers de résultats sont écrits dans `results/`.

---

## Structure générale du fichier de configuration

Le fichier est au format **JSON**. Il contient quatre sections principales :

```json
{
  "Description": "...",
  "Output Filename": "nom_sortie",
  "Warning Override": false,
  "Simulation Control": { ... },
  "Chemical Properties": { ... },
  "Environment": { ... }
}
```

| Champ | Description |
|-------|-------------|
| `"Description"` | Texte libre décrivant la simulation |
| `"Output Filename"` | Préfixe des fichiers de sortie (ex. `"arteriole_test"` → `results/arteriole_test_SEED1.txt`) |
| `"Warning Override"` | `true` pour ignorer les avertissements non-bloquants |

---

## 1. Simulation Control

```json
"Simulation Control": {
  "Number of Repeats": 1,
  "Final Simulation Time": 0.025,
  "Global Microscopic Time Step": 1e-5,
  "Random Number Seed": 1,
  "Max Number of Progress Updates": 100
}
```

| Paramètre | Description |
|-----------|-------------|
| `"Number of Repeats"` | Nombre de réalisations indépendantes |
| `"Final Simulation Time"` | Durée totale de la simulation (secondes) |
| `"Global Microscopic Time Step"` | Pas de temps microscopique (secondes). Doit être suffisamment petit par rapport aux temps de réaction |
| `"Random Number Seed"` | Graine du générateur aléatoire (reproductibilité) |
| `"Max Number of Progress Updates"` | Fréquence d'affichage de la progression |

---

## 2. Chemical Properties

### 2.1 Types de molécules

```json
"Chemical Properties": {
  "Number of Molecule Types": 4,
  "Diffusion Coefficients": [2.2644e-12, 5.6610e-14, 5.6610e-14, 5.6610e-14],
  "Global Flow Type": "None",
  ...
}
```

Les molécules sont indexées de `0` à `N-1`. Dans `energy.txt` :

| Index | Nom | Coefficient de diffusion (m²/s) |
|-------|-----|--------------------------------|
| 0 | Biomarqueur (BM) | 2.2644e-12 |
| 1 | Nanocapteur inactif (NM) | 5.6610e-14 |
| 2 | Nanocapteur ayant détecté (NM_detected) | 5.6610e-14 |
| 3 | Nanocapteur informé par gossip (NM_gossip) | 5.6610e-14 |

`"Global Flow Type"` peut être `"None"` ou `"Uniform"` (un vecteur global est alors requis).

### 2.2 Réactions chimiques

Chaque réaction est un objet dans `"Chemical Reaction Specification"` :

```json
{
  "Label": "Détection (BM + NM → NM_detected)",
  "Is Reaction Reversible?": false,
  "Surface Reaction?": false,
  "Default Everywhere?": true,
  "Exception Regions": [],
  "Reactants": [1, 1, 0, 0],
  "Products":  [0, 0, 1, 0],
  "Reaction Rate": 1e9999,
  "Binding Radius": 1.025e-6
}
```

| Paramètre | Description |
|-----------|-------------|
| `"Reactants"` | Stœchiométrie des réactifs (un entier par type de molécule) |
| `"Products"` | Stœchiométrie des produits |
| `"Reaction Rate"` | Constante de réaction (m³/s ou s⁻¹). `1e9999` = réaction instantanée |
| `"Binding Radius"` | Distance de réaction bimolécylaire (mètres) |
| `"Default Everywhere?"` | `true` = réaction active dans toutes les régions sauf exceptions |
| `"Exception Regions"` | Liste de labels de régions à exclure |

### 2.3 Réactions avec coût énergétique

Pour activer la consommation d'énergie sur une réaction, ajouter dans l'objet réaction :

```json
"Is Energy Enabled?": true,
"Energy Cost Type": "detection",
"Energy Cost Value": 9e-5,
"Energy Cost Unit": "per_reaction"
```

| Paramètre | Valeurs possibles | Description |
|-----------|-------------------|-------------|
| `"Is Energy Enabled?"` | `true` / `false` | Active le coût énergétique |
| `"Energy Cost Type"` | `"detection"` | Réaction de détection d'un biomarqueur par un nanocapteur |
| | `"communication"` | Réaction de gossip (échange d'information entre nanocapteurs) |
| `"Energy Cost Value"` | Nombre réel | Montant d'énergie consommé |
| `"Energy Cost Unit"` | `"per_reaction"` | Coût par réaction élémentaire |

> **Important :** seules les réactions avec `"Energy Cost Type": "detection"` ou `"communication"` sont tracées dans les logs d'énergie. Les autres types sont ignorés.

**Exemple complet — `energy.txt`** (8 réactions) :

```json
"Chemical Reaction Specification": [
  {
    "Label": "Detection (BM + NM → NM_detected)",
    "Reactants": [1, 1, 0, 0],  "Products": [0, 0, 1, 0],
    "Reaction Rate": 1e9999,    "Binding Radius": 1.025e-6,
    "Is Energy Enabled?": true,
    "Energy Cost Type": "detection",
    "Energy Cost Value": 9e-5,
    "Energy Cost Unit": "per_reaction"
  },
  {
    "Label": "Gossip (NM + NM_detected → NM_detected + NM_gossip)",
    "Reactants": [0, 1, 1, 0],  "Products": [0, 0, 1, 1],
    "Reaction Rate": 1e9999,    "Binding Radius": 2e-6,
    "Is Energy Enabled?": true,
    "Energy Cost Type": "communication",
    "Energy Cost Value": 1e-5,
    "Energy Cost Unit": "per_reaction"
  }
]
```

---

## 3. Environment

### 3.1 Régions

```json
"Environment": {
  "Subvolume Base Size": 1e-6,
  "Region Specification": [ ... ]
}
```

`"Subvolume Base Size"` : taille de base des sous-volumes mésoscopiques (mètres).

Chaque région est un objet :

```json
{
  "Notes": "Capillaire principal",
  "Label": "Capillary1",
  "Parent Label": "",
  "Shape": "Rectangular Box",
  "Type": "Normal",
  "Anchor Coordinate": [0, 15e-6, 0],
  "Integer Subvolume Size": 1,
  "Is Region Microscopic?": true,
  "Number of Subvolumes Per Dimension": [22, 9, 9],
  "Local Flow": [
    {
      "Is Molecule Type Affected?": [true, false, false, false],
      "Flow Type": "Uniform",
      "Flow Vector": [1.5e-3, 0, 0]
    }
  ]
}
```

| Paramètre | Description |
|-----------|-------------|
| `"Shape"` | `"Rectangular Box"` ou `"Sphere"` |
| `"Type"` | `"Normal"` (région de simulation standard) |
| `"Anchor Coordinate"` | Coin inférieur-gauche `[x, y, z]` (boîte) ou centre (sphère) |
| `"Number of Subvolumes Per Dimension"` | Nombre de sous-volumes en x, y, z |
| `"Is Region Microscopic?"` | `true` = simulation microscopique (diffusion individuelle), `false` = mésoscopique |
| `"Local Flow"` | Vecteur de flux local par type de molécule |
| `"Parent Label"` | Label de la région parente (pour les régions imbriquées), `""` si aucune |

### 3.2 Acteurs

Un acteur est une entité qui émet ou observe des molécules dans une zone géométrique.

#### Acteur actif (émetteur de molécules)

```json
{
  "Notes": "Biomarker source",
  "Is Location Defined by Regions?": false,
  "Shape": "Rectangular Box",
  "Outer Boundary": [0, 0.0001e-6, 16e-6, 23e-6, 1e-6, 8e-6],
  "Is Actor Active?": true,
  "Start Time": 0,
  "Is There Max Number of Actions?": false,
  "Is Actor Independent?": true,
  "Action Interval": 1e9999,
  "Is Actor Activity Recorded?": true,
  "Random Number of Molecules?": false,
  "Random Molecule Release Times?": false,
  "Release Interval": 0,
  "Slot Interval": 0,
  "Modulation Scheme": "Burst",
  "Modulation Strength": 1,
  "Number of Molecules": 1,
  "Is Molecule Type Released?": [true, false, false, false]
}
```

| Paramètre | Description |
|-----------|-------------|
| `"Outer Boundary"` | Pour une boîte : `[xmin, xmax, ymin, ymax, zmin, zmax]` |
| `"Action Interval"` | Intervalle entre deux émissions (s). `1e9999` = une seule émission |
| `"Modulation Scheme"` | `"Burst"` = émet toutes les molécules d'un coup |
| `"Number of Molecules"` | Nombre de molécules émises par action |
| `"Is Molecule Type Released?"` | Tableau booléen : quel type est émis |

#### Acteur passif (observateur)

```json
{
  "Notes": "Observer",
  "Is Location Defined by Regions?": true,
  "List of Regions Defining Location": ["Capillary1", "Capillary2"],
  "Is Actor Active?": false,
  "Start Time": 1e-10,
  "Is There Max Number of Actions?": false,
  "Is Actor Independent?": true,
  "Action Interval": 1e-4,
  "Is Actor Activity Recorded?": true,
  "Is Time Recorded with Activity?": true,
  "Is Molecule Type Observed?": [true, true, true, true],
  "Is Molecule Position Observed?": [true, true, true, true]
}
```

---

## 4. Système d'énergie — Nanocapteurs

Le système d'énergie s'applique aux **acteurs actifs** qui déploient des nanocapteurs. Chaque acteur peut représenter un **réseau de nanocapteurs** avec un bilan énergétique individuel.

### 4.1 Paramètres de l'acteur avec énergie

```json
{
  "Notes": "Nanosensor network transmitter 1 (energy enabled)",
  "Is Location Defined by Regions?": false,
  "Shape": "Rectangular Box",
  "Outer Boundary": [15e-6, 15.0001e-6, 15e-6, 24e-6, 0, 9e-6],
  "Is Actor Active?": true,
  "Start Time": 0,
  "Is There Max Number of Actions?": false,
  "Is Actor Independent?": true,
  "Action Interval": 1e9999,
  "Is Actor Activity Recorded?": true,
  "Random Number of Molecules?": false,
  "Random Molecule Release Times?": false,
  "Release Interval": 0,
  "Slot Interval": 0,
  "Modulation Scheme": "Burst",
  "Modulation Strength": 25,
  "Number of Molecules": 25,
  "Is Molecule Type Released?": [false, true, false, false],
  "Is Energy Enabled?": true,
  "Energy Initial": 3e-4,
  "Energy Max": 3e-4,
  "Energy Drain Passive": 4e-8,
  "Energy Harvest Passive": 0
}
```

`"Number of Molecules"` et `"Modulation Strength"` doivent être **identiques** : ils définissent le nombre de nanocapteurs (unités) dans ce groupe. Chaque molécule émise correspond à un nanocapteur individuel suivi séparément.

| Paramètre énergétique | Description |
|-----------------------|-------------|
| `"Is Energy Enabled?"` | Active le suivi énergétique pour cet acteur |
| `"Energy Initial"` | Énergie de départ de chaque nanocapteur (Joules) |
| `"Energy Max"` | Énergie maximale stockable (Joules, ≥ Energy Initial) |
| `"Energy Drain Passive"` | Drain passif par pas de temps microscopique (Joules/pas). Modélise la consommation au repos |
| `"Energy Harvest Passive"` | Récolte passive d'énergie par pas de temps (Joules/pas). Modélise la collecte d'énergie ambiante |

### 4.2 Interactions entre énergie et réactions

Quand un nanocapteur participe à une réaction avec coût énergétique :

1. Le simulateur vérifie si l'unité concernée a assez d'énergie.
2. Si oui, l'énergie est déduite et la réaction a lieu.
3. Si non, la réaction est **bloquée** (la molécule reste inchangée).
4. Quand `energieCourante ≤ 0`, le nanocapteur est marqué **déplété** (`EnergyDepleted: YES`) et ne peut plus réagir.

### 4.3 Résumé des coûts dans `energy.txt`

| Réaction | Type | Coût |
|----------|------|------|
| BM + NM → NM_detected | `detection` | 9e-5 J |
| BM + NM_detected → NM_detected | `detection` | 9e-5 J |
| BM + NM_gossip → NM_detected | `detection` | 9e-5 J |
| NM + NM_detected → NM_detected + NM_gossip | `communication` | 1e-5 J |
| NM + NM_gossip → 2×NM_gossip | `communication` | 1e-5 J |
| NM_gossip + NM_gossip → 2×NM_gossip | `communication` | 1e-5 J |
| NM_detected + NM_detected → NM_detected + NM_gossip | `communication` | 1e-5 J |
| NM_detected + NM_gossip → NM_detected + NM_gossip | `communication` | 1e-5 J |

Avec `Energy Initial = 3e-4 J`, un nanocapteur peut effectuer environ **3 détections** (3 × 9e-5 = 2.7e-4 J) ou **30 gossips** (30 × 1e-5 = 3e-4 J) avant d'être déplété.

---

## 5. Fichiers de sortie

Pour un fichier `"Output Filename": "arteriole_test"` avec `"Random Number Seed": 1`, deux fichiers sont générés :

### `results/arteriole_test_SEED1.txt`

Fichier texte principal. Pour chaque réalisation :
- Observations des acteurs passifs (comptage de molécules, positions)
- **Section énergie** pour chaque acteur énergie-activé :

```
EnergyActor 56:
    EnergyDepleted: NO
    EnergyFinal: 0.003120
    EnergyMin: 0.003120
    EnergyMax: 0.007499
    EnergyMean: 0.005039
    Time:
        1.0000e-05 2.0000e-05 ...
    Energy:
        0.000300 0.000299 ...
    NumNanomachines: 25
    Nanomachine 0:
        EnergyDepleted: NO
        EnergyFinal: 0.000190
        EnergyMin: 0.000190
        EnergyMax: 0.000300
        EnergyMean: 0.000244
        Energy:
            0.000300 0.000299 ...
        DetectionCount: 0
        DetectionReactionTimes:
            []
        GossipCount: 1
        GossipReactionTimes:
            [(9.1900e-03,[25],receive,56,21)]
    ...
    DepletedUnits: 0 / 25
```

**Format des événements de réaction** : `(temps,[biomarkerIDs],direction,actor_partenaire,nm_partenaire)`

| Champ | Description |
|-------|-------------|
| `temps` | Instant de la réaction (secondes) |
| `[biomarkerIDs]` | IDs des biomarqueurs connus au moment de l'événement |
| `direction` | `receive` (le NM reçoit), `send` (le NM envoie), `send & receive` (les deux) |
| `actor_partenaire` | ID de l'acteur partenaire (`-1` pour une détection directe de BM) |
| `nm_partenaire` | ID du nanocapteur partenaire (`0` pour une détection directe de BM) |

### `results/arteriole_test_SEED1_summary.txt`

Fichier JSON de synthèse. Contient `"NanomachineEnergySummary"` avec les statistiques par nanocapteur et les événements détaillés :

```json
"NanomachineEnergySummary": [{
  "ActorID": 56,
  "NumNanomachines": 25,
  "Nanomachines": [{
    "NanomachineID": 0,
    "EnergyDepleted": false,
    "EnergyFinal": 0.000190,
    "EnergyMin": 0.000190,
    "EnergyMax": 0.000300,
    "EnergyMean": 0.000244,
    "DetectionCount": 0,
    "GossipCount": 1,
    "DetectionTimes": [],
    "GossipTimes": [{
      "time": 0.009190,
      "bmIDs": [25],
      "dir": "receive",
      "partner_actor": 56,
      "partner_nm": 21
    }]
  }]
}]
```

---

## 6. Exemple complet — `energy.txt`

**Scénario** : artériole en forme de L avec 5 sections de capillaire. Des biomarqueurs (BM) sont injectés à plusieurs points d'entrée et dérivent avec le flux sanguin. Quatre groupes de 25 nanocapteurs sont déployés le long du trajet. Les NM se détectent et se gossipent.

```
Structure :
  BM sources (55 points)         → [type 0, 1 molécule chacun]
  NM groups (4 × 25 = 100 NM)   → [type 1, énergie activée]
  Observer (all regions)         → passif, enregistre tout

Régions (capillaires) :
  Capillary1 : [0→22µm, 15→24µm, 0→9µm]  flux : (1.5e-3, 0, 0) m/s
  Capillary2 : [22→30µm, 15→20µm, 0→9µm] flux : (1.5e-3, -1e-3, -1e-3) m/s
  Capillary3 : [22→30µm, 0→15µm, 0→8µm]  flux : (0, -1.335e-3, 0) m/s
  Capillary4 : [22→28µm, 20→24µm, 0→9µm] flux : (1.5e-3, 1e-3, -1e-3) m/s
  Capillary5 : [22→28µm, 24→40µm, 0→6µm] flux : (0, 1e-3, 0) m/s

Énergie par NM :
  Initial = Max = 3e-4 J
  Drain passif = 4e-8 J/pas (1e-5 s)  → 4e-3 J/s
  Coût détection = 9e-5 J  (≈3 détections max)
  Coût gossip    = 1e-5 J  (≈30 gossips max)
```

Pour lancer :

```bash
./bin/accord_energy_linux config/energy.txt
```

---

## 7. Conseils pratiques

**Choisir le pas de temps** : `DT_MICRO` doit satisfaire `DT_MICRO < (r_binding)² / (6 × D_max)` pour que les molécules rapides ne "sautent" pas par-dessus les sites de liaison.

**Calibrer l'énergie** : avec `Energy Initial = E₀` et un coût de détection `c_det`, le nanocapteur peut effectuer au maximum `⌊E₀ / c_det⌋` détections en ignorant le drain passif. Tenir compte du drain : `E₀ - N_steps × drain_passif` donne l'énergie résiduelle après `N_steps` pas de temps.

**Identifier les acteurs dans la sortie** : les acteurs sont numérotés dans l'ordre de leur déclaration dans `"Actor Specification"`, en commençant à 0. L'acteur 56 dans `energy.txt` est le 57ème acteur déclaré (les 55 sources BM + le 1er groupe NM).

**Recompiler après modification du code** :
```bash
cd src && bash build_accord_opt_dub
cp ../bin/accord_dub.out ../bin/accord_energy_linux
```
