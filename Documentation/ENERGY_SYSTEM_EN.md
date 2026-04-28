# AcCoRD — Nanosensor Energy Management System

## Overview

This modified version of AcCoRD adds an **energy reservoir system** for actors
(nanosensor transmitters and receivers). Each actor can have a finite energy reservoir
that drains and recharges according to two modes:

| Mode | Description |
|------|-------------|
| **Passive (always active)** | Continuous drain/recharge at each microscopic time step |
| **Active (on event)** | Drain/recharge during emission (active actor) or detection (passive actor) |

When energy reaches 0, the actor is **disabled** for the remainder of the simulation repeat.

---

## Modified Files

| File | Changes |
|------|---------|
| `src/actor.h` | New energy fields in `actorStructSpec3D` (config) and `actorStruct3D` (runtime) |
| `src/actor.c` | `resetActors()` initializes energy at the start of each repeat |
| `src/file_io.c` | JSON parsing of new energy parameters |
| `src/accord.c` | Energy logic integrated into main simulation loop |
| `src/chem_rxn.h/.c` | Optional reaction-level energy costs support |

---

## New JSON Parameters per Actor

All fields are **optional**. If `"Is Energy Enabled?"` is absent or `false`,
the actor behaves exactly like in the original AcCoRD.

```json
"Is Energy Enabled?":       true,
"Energy Initial":           1.0,
"Energy Max":               1.0,
"Energy Drain Passive":     0.5,
"Energy Cost Active":       0.05,
"Energy Harvest Passive":   0.3,
"Energy Harvest Active":    0.0
```

### Parameter Details

| Parameter | Type | Description |
|-----------|------|-------------|
| `Is Energy Enabled?` | bool | Enable energy management for this actor |
| `Energy Initial` | double | Energy at the start of each repeat (arbitrary units, e.g., Joules) |
| `Energy Max` | double | Maximum reservoir capacity |
| `Energy Drain Passive` | double | Passive drain (units/second) — continuous idle power consumption |
| `Energy Cost Active` | double | Cost per active event (emission for active actor, molecule detection for passive) |
| `Energy Harvest Passive` | double | Passive recharge (units/second) — continuous ambient harvesting |
| `Energy Harvest Active` | double | Gain per active event |

---

## New JSON Parameters per Chemical Reaction (Optional)

Chemical reactions can now define their own energy costs, allowing fine-grained control:

```json
"Is Energy Enabled?":   true,
"Energy Cost Type":     "detection",
"Energy Cost Value":    1e-4,
"Energy Cost Unit":     "per_reaction"
```

### Reaction Energy Parameter Details

| Parameter | Type | Description |
|-----------|------|-------------|
| `Is Energy Enabled?` | bool | Enable energy costs for this reaction |
| `Energy Cost Type` | string | Category: `"detection"`, `"communication"`, `"custom"` |
| `Energy Cost Value` | double | Energy consumed per reaction (Joules or arbitrary units) |
| `Energy Cost Unit` | string | `"per_reaction"` or `"per_product"` |

---

## Internal Logic (accord.c)

```
At each MICRO time step:
  For each actor with energy enabled:
    energyCurrent -= energyDrainPassive * dt
    energyCurrent += energyHarvestPassive * dt
    energyCurrent = clamp(energyCurrent, 0, energyMax)
    if energyCurrent == 0 → bEnergyDepleted = true, nextTime = INFINITY

At each actor event:
  1. Apply passive drain/harvest up to tCur
  2. Check if energy > 0, otherwise skip
  3. Execute action (emission or detection)
  4. Apply active cost/gain:
     - Active actor (fireEmission): energyCurrent -= energyCostActive
     - Passive actor (addObservation): energyCurrent -= energyCostActive × num_molecules_detected
     - Chemical reaction: energyCurrent -= reactionEnergyCost (if defined)
```

---

## Compilation

```bash
cd AcCoRD_energy/src

# Linux / Debian / Ubuntu
gcc -O2 -std=c99 -Wall \
    accord.c actor.c actor_data.c base.c chem_rxn.c \
    cJSON.c erfcx.c err_fcts.c file_io.c im_w_of_x.c \
    meso.c micro_molecule.c mol_release.c observations.c \
    pcg_basic.c rand_accord.c region.c subvolume.c \
    timer_accord.c w_of_z.c \
    -lm -o accord_energy

# Windows (MinGW)
gcc -O2 -std=c99 -Wall [same .c files] -lm -o accord_energy.exe

# macOS (with Homebrew)
gcc -O2 -std=c99 -Wall \
    accord.c actor.c actor_data.c base.c chem_rxn.c \
    cJSON.c erfcx.c err_fcts.c file_io.c im_w_of_x.c \
    meso.c micro_molecule.c mol_release.c observations.c \
    pcg_basic.c rand_accord.c region.c subvolume.c \
    timer_accord.c w_of_z.c \
    -lm -o accord_energy
```

Precompiled binaries are also available in `bin/`:
- `accord_energy_linux` — Linux x86_64 executable

---

## Example Simulation

### Configuration File: `accord_config_sample_energy.txt`

Basic energy-managed simulation with:
- 1 active biomarker transmitter (with energy budget)
- 1 passive nanosensor receiver (energy-constrained)
- 1 global observer (no energy constraints)

**Key features**:
- Biomarker drain: 2.0 J/s (fast depletion)
- Biomarker harvest: 1.5 J/s (net negative energy balance)
- Nanosensor drain: 0.5 J/s (slower depletion)
- Nanosensor harvest: 0.8 J/s (net positive energy balance → sustainable)

### Running the Simulation

```bash
./src/accord_energy config/accord_config_sample_energy.txt
```

### Output Files

- `results/accord_sample_energy_SEED42.txt` — Detailed observation log (times, positions, molecule counts)
- `results/accord_sample_energy_SEED42_summary.txt` — Compact summary with energy statistics per actor:
  ```json
  {
    "EnergyActor 0": {
      "EnergyDepleted": "NO",
      "EnergyFinal": 0.425000,
      "EnergyMin": 0.425000,
      "EnergyMax": 0.950000,
      "EnergyMean": 0.687500,
      "Time": [0.0, 5e-3, 1e-2, ...],
      "Energy": [0.950000, 0.897500, 0.845000, ...]
    }
  }
  ```

---

## Advanced Configuration: Biomarker-Nanosensor Network

See file: `accord_config_sample_energy_biomarker_nanosensor.txt`

This template models:
- **4 molecule types**:
  - Type 0: Biomarker (BM) — signal released by source
  - Type 1: Nanosensor Idle (NM) — passive receiver, awaiting detection
  - Type 2: Nanosensor Detected (NM₁) — state after detecting biomarker
  - Type 3: Nanosensor Informed (NM₂) — state after receiving information via gossip

- **4 chemical reactions** (with reaction-level energy costs):
  1. **Biomarker-Nanosensor Detection**: BM + NM → NM₁ (Cost: 1e-4 J)
  2. **Nanosensor Information Gossip**: NM + NM₁ → NM₁ + NM₂ (Cost: 0.5e-4 J)
  3. **Gossip Amplification**: NM + NM₂ → 2×NM₂ (Cost: 0.5e-4 J)
  4. **Biomarker Redetection via Gossip**: BM + NM₂ → NM₁ (Cost: 1e-4 J)

This structure enables realistic simulation of distributed biosensing networks where:
- Detection is costly (requires active sensing)
- Communication/gossip is lower cost (passive information relay)
- Information spreads through the network via multiple redundant paths

---

## Energy Accounting and Monitoring

### Summary Statistics

The `_summary.txt` file reports per-actor energy statistics:

| Statistic | Meaning |
|-----------|---------|
| `EnergyDepleted` | YES if actor ran out of energy; NO otherwise |
| `EnergyFinal` | Final energy level at end of simulation |
| `EnergyMin` | Minimum energy reached during simulation |
| `EnergyMax` | Maximum energy reached during simulation |
| `EnergyMean` | Average energy level over simulation duration |
| `Time[]` | Time points where energy was sampled (one per frame) |
| `Energy[]` | Energy values at corresponding times |

### Interpreting Energy Traces

1. **Flat Energy Trace** → Energy is constant (either disabled or harvesting = draining)
2. **Sawtooth Pattern** → Passive drain followed by active events causing sharp drops
3. **Exponential Decay** → No harvesting; actor approaching depletion
4. **Oscillating Trace** → Rapid cycling between energy states (check for conflicting rates)

---

## Comparison: Original vs. Energy-Managed

### Original AcCoRD Behavior
```
- Actors always active
- No resource constraints
- Unlimited molecule emission/detection
- Ideal for theoretical analysis
```

### Energy-Managed AcCoRD
```
- Actors may become inactive when energy depleted
- Realistic resource constraints
- Energy-aware communication strategies required
- Better models biological/nanoscale systems
```

---

## Related Documentation

- **GUIDE_CONFIGURATION_ENERGY_SYSTEM_EN.md** — Comprehensive configuration guide with examples
- **ENERGY_SYSTEM.md** — Original French version (legacy)
- **README.md** — Main AcCoRD simulator documentation

---

## Version Information

- **Base Simulator**: AcCoRD v1.4.2 (2020-02-12)
- **Energy System**: v1.0 (April 2026)
- **Author**: Energy Management Extension
- **License**: New BSD (same as AcCoRD)

---

## Troubleshooting

| Issue | Likely Cause | Solution |
|-------|--------------|----------|
| Actors deplete immediately | `Energy_Drain_Passive` too high | Increase `Energy_Initial` or reduce drain |
| Energy never changes in output | `Energy_Cost_Active = 0` and `Energy_Harvest_Passive = Energy_Drain_Passive` | Adjust parameters or check simulation time |
| Simulation unusually slow | Energy checking overhead (rare) | Verify reasonable parameter ranges |
| Unexpected actor disabling | Energy depletion (expected) | Review energy balance: `Harvest >= Drain + (EventRate × Cost)` |

---

## References

- Original AcCoRD: https://github.com/adamjgnoel/AcCoRD
- Molecular Communication: Farsad et al., "Molecular Communication: Channel Model and Physical Layer Techniques", IEEE Transactions on Molecular, Biological and Multi-Scale Communications (2016)
- Nanosensor Energy Constraints: Inspired by real nanomachine power budgets (~picojoules per operation)
