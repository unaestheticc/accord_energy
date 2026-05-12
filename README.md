# AcCoRD_energy — Configuration Guide

AcCoRD_energy simulates molecular communication in a biological environment (arteriole, tissue, etc.) with an energy management system for nanosensors. This guide explains how to write a JSON configuration file and how to run a simulation.

---

## Running a simulation

### Linux

```bash
# Compile
cd src && bash build_accord_opt_dub
cp ../bin/accord_dub.out ../bin/accord_energy_linux

# Run
./bin/accord_energy_linux config/my_config.txt
```

Result files are written to `results/`.

---

### Windows

#### Prerequisites

Install [MinGW-w64](https://www.mingw-w64.org/) to get `gcc` on Windows. The recommended method is via [MSYS2](https://www.msys2.org/):

1. Download and install MSYS2 from [msys2.org](https://www.msys2.org/).
2. Open the **MSYS2 MinGW 64-bit** terminal and run:

```bash
pacman -S mingw-w64-x86_64-gcc
```

1. Add `C:\msys64\mingw64\bin` to your Windows `PATH` environment variable so that `gcc` is accessible from the Command Prompt.

#### Compile

Open a **Command Prompt** (cmd) in the project root and run:

```bat
cd src
build_accord_opt_win.bat
```

This produces `bin\accord_win.exe`.

#### Run

From the project root in Command Prompt:

```bat
bin\accord_win.exe config\my_config.txt
```

Result files are written to `results\`.

---

## General structure of the configuration file

The file uses **JSON** format with four main sections:

```json
{
  "Description": "...",
  "Output Filename": "output_name",
  "Warning Override": false,
  "Simulation Control": { ... },
  "Chemical Properties": { ... },
  "Environment": { ... }
}
```

| Field | Description |
|-------|-------------|
| `"Description"` | Free text describing the simulation |
| `"Output Filename"` | Prefix for output files (e.g. `"arteriole_test"` → `results/arteriole_test_SEED1.txt`) |
| `"Warning Override"` | `true` to suppress non-blocking warnings |

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

| Parameter | Description |
|-----------|-------------|
| `"Number of Repeats"` | Number of independent realizations |
| `"Final Simulation Time"` | Total simulation duration (seconds) |
| `"Global Microscopic Time Step"` | Microscopic time step (seconds). Must be small enough relative to reaction timescales |
| `"Random Number Seed"` | Random number generator seed (reproducibility) |
| `"Max Number of Progress Updates"` | How often progress is printed to console |

---

## 2. Chemical Properties

### 2.1 Molecule types

```json
"Chemical Properties": {
  "Number of Molecule Types": 4,
  "Diffusion Coefficients": [2.2644e-12, 5.6610e-14, 5.6610e-14, 5.6610e-14],
  "Global Flow Type": "None",
  ...
}
```

Molecules are indexed from `0` to `N-1`. In `energy.txt`:

| Index | Name | Diffusion coefficient (m^2/s) |
| --- | --- | --- |
| 0 | Biomarker (BM) | 2.2644e-12 |
| 1 | Inactive nanosensor (NM) | 5.6610e-14 |
| 2 | Detection-confirmed nanosensor (NM_detected) | 5.6610e-14 |
| 3 | Gossip-informed nanosensor (NM_gossip) | 5.6610e-14 |

`"Global Flow Type"` can be `"None"` or `"Uniform"` (a global flow vector is then required).

### 2.2 Chemical reactions

Each reaction is an object inside `"Chemical Reaction Specification"`:

```json
{
  "Label": "Detection (BM + NM -> NM_detected)",
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

| Parameter | Description |
|-----------|-------------|
| `"Reactants"` | Reactant stoichiometry (one integer per molecule type) |
| `"Products"` | Product stoichiometry |
| `"Reaction Rate"` | Reaction rate constant (m^3/s or s^-1). `1e9999` = instantaneous reaction |
| `"Binding Radius"` | Bimolecular reaction distance (metres) |
| `"Default Everywhere?"` | `true` = reaction active in all regions except exceptions |
| `"Exception Regions"` | List of region labels to exclude |

### 2.3 Reactions with energy cost

To enable energy consumption on a reaction, add to the reaction object:

```json
"Is Energy Enabled?": true,
"Energy Cost Type": "detection",
"Energy Cost Value": 9e-5,
"Energy Cost Unit": "per_reaction"
```

| Parameter | Possible values | Description |
| --- | --- | --- |
| `"Is Energy Enabled?"` | `true` / `false` | Enables energy cost for this reaction |
| `"Energy Cost Type"` | `"detection"` | Detection of a biomarker by a nanosensor |
| | `"communication"` | Gossip reaction (information exchange between nanosensors) |
| `"Energy Cost Value"` | Real number | Amount of energy consumed |
| `"Energy Cost Unit"` | `"per_reaction"` | Cost per elementary reaction event |

> **Important:** only reactions with `"Energy Cost Type": "detection"` or `"communication"` are tracked in the energy logs. Other types are ignored.

**Full example — `energy.txt`** (8 reactions):

```json
"Chemical Reaction Specification": [
  {
    "Label": "Detection (BM + NM -> NM_detected)",
    "Reactants": [1, 1, 0, 0],  "Products": [0, 0, 1, 0],
    "Reaction Rate": 1e9999,    "Binding Radius": 1.025e-6,
    "Is Energy Enabled?": true,
    "Energy Cost Type": "detection",
    "Energy Cost Value": 9e-5,
    "Energy Cost Unit": "per_reaction"
  },
  {
    "Label": "Gossip (NM + NM_detected -> NM_detected + NM_gossip)",
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

### 3.1 Regions

```json
"Environment": {
  "Subvolume Base Size": 1e-6,
  "Region Specification": [ ... ]
}
```

`"Subvolume Base Size"`: base size of mesoscopic subvolumes (metres).

Each region is an object:

```json
{
  "Notes": "Main capillary",
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

| Parameter | Description |
|-----------|-------------|
| `"Shape"` | `"Rectangular Box"` or `"Sphere"` |
| `"Type"` | `"Normal"` (standard simulation region) |
| `"Anchor Coordinate"` | Lower-left corner `[x, y, z]` (box) or centre (sphere) |
| `"Number of Subvolumes Per Dimension"` | Number of subvolumes along x, y, z |
| `"Is Region Microscopic?"` | `true` = microscopic simulation (individual diffusion), `false` = mesoscopic |
| `"Local Flow"` | Local flow vector per molecule type |
| `"Parent Label"` | Label of the parent region (for nested regions), `""` if none |

### 3.2 Actors

An actor is an entity that emits or observes molecules within a geometric zone.

#### Active actor (molecule emitter)

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

| Parameter | Description |
|-----------|-------------|
| `"Outer Boundary"` | For a box: `[xmin, xmax, ymin, ymax, zmin, zmax]` |
| `"Action Interval"` | Interval between emissions (s). `1e9999` = single emission |
| `"Modulation Scheme"` | `"Burst"` = releases all molecules at once |
| `"Number of Molecules"` | Number of molecules released per action |
| `"Is Molecule Type Released?"` | Boolean array: which molecule type is emitted |

#### Passive actor (observer)

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

## 4. Energy system — Nanosensors

The energy system applies to **active actors** that deploy nanosensors. Each actor can represent a **nanosensor network** with individual energy budgets.

### 4.1 Energy actor parameters

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

`"Number of Molecules"` and `"Modulation Strength"` must be **identical**: they define the number of nanosensors (units) in this group. Each emitted molecule corresponds to one individually tracked nanosensor.

| Energy parameter | Description |
| --- | --- |
| `"Is Energy Enabled?"` | Enables energy tracking for this actor |
| `"Energy Initial"` | Starting energy of each nanosensor (Joules) |
| `"Energy Max"` | Maximum storable energy (Joules, >= Energy Initial) |
| `"Energy Drain Passive"` | Passive drain per microscopic time step (J/step). Models idle power consumption |
| `"Energy Harvest Passive"` | Passive energy harvest per time step (J/step). Models ambient energy collection |

### 4.2 Energy and reaction interaction

When a nanosensor participates in a reaction with an energy cost:

1. The simulator checks whether the unit has enough energy.
2. If yes, energy is deducted and the reaction proceeds.
3. If no, the reaction is **blocked** (the molecule remains unchanged).
4. When `currentEnergy <= 0`, the nanosensor is marked **depleted** (`EnergyDepleted: YES`) and can no longer react.

### 4.3 Cost summary for `energy.txt`

| Reaction | Type | Cost |
|----------|------|------|
| BM + NM -> NM_detected | `detection` | 9e-5 J |
| BM + NM_detected -> NM_detected | `detection` | 9e-5 J |
| BM + NM_gossip -> NM_detected | `detection` | 9e-5 J |
| NM + NM_detected -> NM_detected + NM_gossip | `communication` | 1e-5 J |
| NM + NM_gossip -> 2xNM_gossip | `communication` | 1e-5 J |
| NM_gossip + NM_gossip -> 2xNM_gossip | `communication` | 1e-5 J |
| NM_detected + NM_detected -> NM_detected + NM_gossip | `communication` | 1e-5 J |
| NM_detected + NM_gossip -> NM_detected + NM_gossip | `communication` | 1e-5 J |

With `Energy Initial = 3e-4 J`, a nanosensor can perform approximately **3 detections** (3 x 9e-5 = 2.7e-4 J) or **30 gossip exchanges** (30 x 1e-5 = 3e-4 J) before depletion.

---

## 5. Output files

For `"Output Filename": "arteriole_test"` with `"Random Number Seed": 1`, two files are generated:

### `results/arteriole_test_SEED1.txt`

Main text file. For each realization:

- Passive actor observations (molecule counts, positions)
- **Energy section** for each energy-enabled actor:

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

**Reaction event format**: `(time,[biomarkerIDs],direction,partner_actor,partner_nm)`

| Field | Description |
|-------|-------------|
| `time` | Reaction timestamp (seconds) |
| `[biomarkerIDs]` | IDs of known biomarkers at the time of the event |
| `direction` | `receive` (NM receives), `send` (NM sends), `send & receive` (both) |
| `partner_actor` | Partner actor ID (`-1` for direct BM detection) |
| `partner_nm` | Partner nanosensor ID (`0` for direct BM detection) |

### `results/arteriole_test_SEED1_summary.txt`

JSON summary file. Contains `"NanomachineEnergySummary"` with per-nanosensor statistics and detailed events:

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

## 6. Full example — `energy.txt`

**Scenario**: L-shaped arteriole with 5 capillary sections. Biomarkers (BM) are injected at multiple entry points and drift with the blood flow. Four groups of 25 nanosensors are deployed along the path. NMs detect biomarkers and share information via gossip.

```
Structure:
  BM sources (55 points)         -> [type 0, 1 molecule each]
  NM groups (4 x 25 = 100 NM)   -> [type 1, energy enabled]
  Observer (all regions)         -> passive, records everything

Regions (capillaries):
  Capillary1: [0->22um, 15->24um, 0->9um]  flow: (1.5e-3, 0, 0) m/s
  Capillary2: [22->30um, 15->20um, 0->9um] flow: (1.5e-3, -1e-3, -1e-3) m/s
  Capillary3: [22->30um, 0->15um, 0->8um]  flow: (0, -1.335e-3, 0) m/s
  Capillary4: [22->28um, 20->24um, 0->9um] flow: (1.5e-3, 1e-3, -1e-3) m/s
  Capillary5: [22->28um, 24->40um, 0->6um] flow: (0, 1e-3, 0) m/s

Energy per NM:
  Initial = Max = 3e-4 J
  Passive drain = 4e-8 J/step (1e-5 s) -> 4e-3 J/s
  Detection cost = 9e-5 J  (~3 detections max)
  Gossip cost    = 1e-5 J  (~30 gossip exchanges max)
```

To run:

```bash
./bin/accord_energy_linux config/energy.txt
```

To visualise nanomachine energy over time using the MATLAB script, run the following from the project root (replace `arteriole_test_SEED1.txt` with your output filename):

```matlab
addpath('matlab')
plotNanomachineEnergy('results/arteriole_test_SEED1.txt')
```

---

## 7. Practical tips

**Choosing the time step**: `DT_MICRO` should satisfy `DT_MICRO < (r_binding)^2 / (6 * D_max)` so that fast molecules do not jump past binding sites.

**Calibrating energy**: with `Energy Initial = E0` and a detection cost `c_det`, a nanosensor can perform at most `floor(E0 / c_det)` detections ignoring passive drain. Accounting for drain: `E0 - N_steps * passive_drain` gives the residual energy after `N_steps` time steps.

**Identifying actors in the output**: actors are numbered in declaration order inside `"Actor Specification"`, starting from 0. Actor 56 in `energy.txt` is the 57th declared actor (55 BM sources + the 1st NM group).

**Recompile after modifying the source**:
```bash
cd src && bash build_accord_opt_dub
cp ../bin/accord_dub.out ../bin/accord_energy_linux
```
