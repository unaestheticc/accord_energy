# AcCoRD Energy System Integration - Implementation Notes

## Architecture Overview

The energy management system for AcCoRD is designed with a three-layer architecture:

### Layer 1: Actor-Level Energy (Already Implemented)
- **Location**: `src/actor.h`, `src/actor.c`, `src/accord.c`
- **Features**:
  - Per-actor energy reservoirs with capacity limits
  - Passive drain (continuous power consumption)
  - Passive harvesting (continuous energy gain)
  - Active costs/gains per emission event (for transmitters)
  - Active costs per detection event (for passive receivers)
- **Applied**: Every `MICRO` time step for passive effects; at each actor event for active effects

### Layer 2: Reaction-Level Energy Costs (New - Partial Implementation)
- **Location**: `src/chem_rxn.h` (structure), `src/file_io.c` (parsing)
- **Features**:
  - Optional energy costs associated with specific chemical reactions
  - Categorization of reaction types (`"detection"`, `"communication"`, `"custom"`)
  - Flexible cost scaling (`"per_reaction"` or `"per_product"`)
- **Status**: 
  - ✅ Structure definitions added
  - ✅ JSON parsing implemented
  - ⏳ Runtime application needs implementation in `src/accord.c` and `src/micro_molecule.c`

### Layer 3: Region-Level Energy Resources (Future Enhancement)
- Could support localized energy sources/sinks
- Would enable modeling of energy harvesting from environment

---

## Current Implementation Status

### ✅ Completed

1. **Chemical Reaction Structure Extension** (`src/chem_rxn.h`)
   - Added fields: `bEnergyEnabled`, `energyCostType`, `energyCostValue`, `energyCostUnit`
   - Maintains backward compatibility (default `false`)

2. **JSON Configuration Parsing** (`src/file_io.c`)
   - Parses `"Is Energy Enabled?"`, `"Energy Cost Type"`, `"Energy Cost Value"`, `"Energy Cost Unit"`
   - Provides sensible defaults if fields missing
   - Validates cost values (must be ≥ 0)

3. **Documentation**
   - Complete configuration guide with examples
   - API reference for new fields
   - Best practices and troubleshooting

### ⏳ In Progress / Pending

1. **Runtime Application of Reaction Costs** (`src/accord.c`, `src/micro_molecule.c`)
   - Need to identify where chemical reactions are executed in simulation
   - Implement energy deduction when reaction occurs
   - Handle case where reactant species belong to energy-managed actors

2. **Testing Suite**
   - Compile and verify syntax
   - Run test configurations
   - Compare energy balance equations against expected behavior

---

## How to Apply Reaction Energy Costs (Implementation Guide)

### Where Reactions Happen

In AcCoRD's hybrid architecture, chemical reactions occur in two regimes:

#### Microscopic Regime (Stochastic, Event-Driven)
- Located in: `src/micro_molecule.c`, `src/subvolume.c`
- **Second-order reactions** (bimolecular): Occur when two molecules get within binding radius
- **First-order reactions** (unimolecular): Degradation, decay, transitions
- Implementation: Search for `binding radius`, `fireReaction`, or similar logic

#### Mesoscopic Regime (Deterministic/Stochastic)
- Located in: `src/meso.c`
- **Propensity-based reactions**: Calculated based on concentrations
- Implementation: Propensity-driven chemical reaction events

### Implementation Strategy

#### Option A: Direct Integration (Recommended)

1. When a chemical reaction fires (bimolecular in microscopic or propensity event in mesoscopic):
   - Retrieve the `chem_rxn_struct` for that reaction
   - Check `bEnergyEnabled` flag
   - If enabled:
     - Calculate energy cost: `energyCostValue × (energyCostUnit == "per_product" ? numProducts : 1)`
     - Identify actors managing the reactant molecule types
     - Deduct energy from those actors
     - If any actor depleted, handle state changes

2. **Pseudocode**:
```c
// When reaction fires:
if (reaction.bEnergyEnabled) {
    double costPerReaction = reaction.energyCostValue;
    if (strcmp(reaction.energyCostUnit, "per_product") == 0) {
        // Count total products
        int numProducts = 0;
        for (int i = 0; i < NUM_MOL_TYPES; i++) {
            numProducts += reaction.products[i];
        }
        costPerReaction *= numProducts;
    }
    
    // Deduct from actors managing reactants
    for (int i = 0; i < NUM_MOL_TYPES; i++) {
        if (reaction.reactants[i] > 0) {
            // Find actor managing molecule type i
            // Deduct cost: actor.energyCurrent -= costPerReaction
        }
    }
}
```

#### Option B: Post-Processing (Simpler, Less Accurate)

1. Track number of each reaction type that fired
2. At simulation end, calculate total energy consumed
3. Apply as adjustment to actor energy curves

**Advantage**: Minimal code changes  
**Disadvantage**: Less realistic (doesn't prevent reactions when energy depleted)

---

## Configuration Examples

### Basic Reaction with Energy Cost

```json
{
  "Label": "Detection reaction with cost",
  "Is Reaction Reversible?": false,
  "Surface Reaction?": false,
  "Default Everywhere?": true,
  "Reaction Rate": 1e9999,
  "Binding Radius": 0.025e-6,
  "Reactants": [1, 1, 0, 0],
  "Products": [0, 0, 1, 0],
  "Is Energy Enabled?": true,
  "Energy Cost Type": "detection",
  "Energy Cost Value": 1e-4,
  "Energy Cost Unit": "per_reaction"
}
```

### Communication Reaction (Lower Cost)

```json
{
  "Label": "Gossip communication",
  "Is Reaction Reversible?": false,
  "Surface Reaction?": false,
  "Default Everywhere?": true,
  "Reaction Rate": 1e9999,
  "Binding Radius": 2e-6,
  "Reactants": [0, 1, 1, 0],
  "Products": [0, 0, 1, 1],
  "Is Energy Enabled?": true,
  "Energy Cost Type": "communication",
  "Energy Cost Value": 0.5e-4,
  "Energy Cost Unit": "per_reaction"
}
```

### No Energy Cost Reaction

```json
{
  "Label": "Dilution/decay",
  "Is Reaction Reversible?": false,
  "Surface Reaction?": false,
  "Default Everywhere?": true,
  "Reaction Rate": 1.0,
  "Binding Radius": 0,
  "Reactants": [1, 0, 0, 0],
  "Products": [0, 0, 0, 0],
  "Is Energy Enabled?": false
}
```

---

## Testing and Validation

### Compilation Checks

```bash
cd src
gcc -O2 -std=c99 -Wall \
    accord.c actor.c actor_data.c base.c chem_rxn.c \
    cJSON.c erfcx.c err_fcts.c file_io.c im_w_of_x.c \
    meso.c micro_molecule.c mol_release.c observations.c \
    pcg_basic.c rand_accord.c region.c subvolume.c \
    timer_accord.c w_of_z.c \
    -lm -o accord_energy

# Check for errors related to:
# - chem_rxn.h structure changes
# - file_io.c parsing additions
# - actor.h energy fields
```

### Runtime Tests

1. **No-Cost Baseline**: Run simulation without reaction costs to establish baseline
2. **With Costs**: Run identical simulation with reaction costs enabled
3. **Energy Depletion**: Verify actors correctly stop reacting when energy = 0
4. **Cost Verification**: Sum costs from output and verify against expected energy consumption

### Validation Metrics

| Metric | Validation |
|--------|-----------|
| `energyFinal` | Should be < initial if costs applied and time step sufficient |
| `energyDepletion` rate | Should approximately match formula: `drain - harvest + reactionCosts/timeAverage` |
| Total molecule count | Should match if no energy-dependent reaction blocking |
| Energy conservation | Total cost of all reactions ≤ Total energy consumed by actors |

---

## Migration Path

### Current State (v1.0)
- ✅ Actor-level energy parameters fully functional
- ✅ Configuration parsing for reaction-level energy fields
- ⏳ Runtime application of reaction-level costs

### Next Steps (v1.1)
1. Identify exact locations in `micro_molecule.c` where reactions execute
2. Add energy cost calculation and deduction logic
3. Handle edge cases:
   - Multiple actors managing same molecule type
   - Reactions with fractional stoichiometry
   - Boundary conditions (regions with/without actors)
4. Extensive testing and validation

### Future Enhancements (v1.2+)
- Region-level energy sources/sinks
- Actor mobility with energy constraints
- Dynamic energy harvesting based on local conditions
- Network-wide energy coordination protocols

---

## References

- **Base Simulator**: AcCoRD v1.4.2, https://github.com/adamjgnoel/AcCoRD
- **Energy Model**: Inspired by real nanomachine power budgets (picojoules per operation)
- **Configuration Format**: JSON (RFC 7159)
- **Implementation Language**: ANSI C (C99)

---

**Version**: 1.0  
**Author**: AcCoRD Energy Management System  
**License**: New BSD (same as AcCoRD)
