# AcCoRD Energy Management System - Configuration Guide

## Overview

The Energy Management System for AcCoRD extends the molecular communication simulator with realistic energy constraints for nanosensors and biomolecular actors. This guide explains how to configure energy-aware simulations using the JSON-based configuration format.

## Table of Contents

1. [System Architecture](#system-architecture)
2. [Energy Parameters for Actors](#energy-parameters-for-actors)
3. [Energy Costs in Chemical Reactions](#energy-costs-in-chemical-reactions)
4. [Configuration Examples](#configuration-examples)
5. [Molecule Types Reference](#molecule-types-reference)
6. [Output and Monitoring](#output-and-monitoring)

## System Architecture

### Energy Model

The energy management system models a dual-layer energy consumption model:

1. **Passive Energy Drain**: Constant energy loss over time (e.g., idle circuitry, sensing overhead)
   - Formula: `Energy_t = Energy_{t-1} - (Energy_Drain_Passive × Δt)`

2. **Active Energy Cost**: Discrete energy loss during events (detection, transmission, information exchange)
   - Applied at the moment a chemical reaction occurs

3. **Passive Energy Harvesting**: Constant energy gain over time (e.g., ambient energy, kinetic harvesting)
   - Formula: `Energy_t = Energy_t + (Energy_Harvest_Passive × Δt)`

4. **Active Energy Harvesting**: Discrete energy gain during specific events
   - Applied at the moment certain reactions complete

5. **Energy Depletion**: When energy reaches zero, the actor becomes inactive and cannot participate in further reactions or detections.

### Molecule Types Convention (Biomarker-Nanosensor Model)

The recommended configuration uses 4 molecule types to represent a biomarker detection network:

| Index | Name | Description |
|-------|------|-------------|
| 0 | Biomarker (BM) | Released by an active source; triggers nanosensor detection |
| 1 | Nanosensor - Idle (NM) | Initial state; can react with biomarkers |
| 2 | Nanosensor - Detected (NM₁) | State after detecting a biomarker |
| 3 | Nanosensor - Informed (NM₂) | State after receiving gossip information from another nanosensor |

---

## Energy Parameters for Actors

Energy parameters are defined within each actor specification in the `"Actor Specification"` array.

### Actor Energy Fields

```json
"Is Energy Enabled?": true,
"Energy Initial": 1.0,
"Energy Max": 1.0,
"Energy Drain Passive": 2.0,
"Energy Cost Active": 0.05,
"Energy Harvest Passive": 1.5,
"Energy Harvest Active": 0.0
```

### Parameter Descriptions

| Parameter | Type | Units | Description |
|-----------|------|-------|-------------|
| `Is Energy Enabled?` | Boolean | — | Enable energy management for this actor (default: `false`) |
| `Energy Initial` | Double | Joules* | Starting energy level at simulation start |
| `Energy Max` | Double | Joules* | Maximum reservoir capacity (energy is clamped to [0, Energy Max]) |
| `Energy Drain Passive` | Double | Joules/second | Continuous energy drain (always active) |
| `Energy Cost Active` | Double | Joules/event | Energy cost per active event (emission for active actors; detection for passive actors)** |
| `Energy Harvest Passive` | Double | Joules/second | Continuous energy gain (e.g., from ambient harvesting) |
| `Energy Harvest Active` | Double | Joules/event | Energy gained per active event |

**Units are arbitrary; use consistent energy units throughout (e.g., Joules, arbitrary units)*

**For actors with energy enabled, this value applies to emissions (active) or base detections (passive) unless overridden by reaction-specific costs.*

### Example Actor Configuration

```json
{
  "Notes": "Nanosensor receiver with energy constraints",
  "Is Location Defined by Regions?": false,
  "Shape": "Sphere",
  "Outer Boundary": [0, 2e-6, 0, 5e-6],
  "Is Actor Active?": false,
  "Start Time": 1e-10,
  "Action Interval": 1e-4,
  "Is Actor Activity Recorded?": true,
  "Is Time Recorded with Activity?": true,
  "Is Molecule Type Observed?": [true, true, true, true],
  "Is Molecule Position Observed?": [true, false, false, false],
  
  "Is Energy Enabled?": true,
  "Energy Initial": 0.5,
  "Energy Max": 1.0,
  "Energy Drain Passive": 0.5,
  "Energy Cost Active": 1e-4,
  "Energy Harvest Passive": 0.8,
  "Energy Harvest Active": 0.0
}
```

---

## Energy Costs in Chemical Reactions

Energy costs can be assigned at the **chemical reaction level**, allowing fine-grained control over which reactions consume energy and how much.

### Reaction Energy Fields

```json
"Is Energy Enabled?": true,
"Energy Cost Type": "detection",
"Energy Cost Value": 1e-4,
"Energy Cost Unit": "per_reaction"
```

### Parameter Descriptions

| Parameter | Type | Values | Description |
|-----------|------|--------|-------------|
| `Is Energy Enabled?` | Boolean | `true` / `false` | Enable energy costs for this reaction |
| `Energy Cost Type` | String | `"detection"`, `"communication"`, `"custom"` | Categorizes the type of reaction for tracking and reporting |
| `Energy Cost Value` | Double | ≥ 0 | Energy consumed per reaction event (in Joules or arbitrary units) |
| `Energy Cost Unit` | String | `"per_reaction"`, `"per_product"` | Determines cost scaling: per single reaction or per molecule product |

### Energy Cost Application Rules

1. **Detection Events**: When a passive actor records a molecule (frequency determined by `Action Interval`), the `Energy Cost Active` from the actor definition is applied, unless overridden by a reaction-specific cost.

2. **Chemical Reaction Events**: When a chemical reaction occurs (molecules collide and react):
   - Energy is deducted from **all reactant molecules** involved.
   - If a reactant molecule type is not bound to any actor, no energy is deducted.
   - If multiple actors manage the same molecule type, the cost may be distributed or applied to each independently (implementation-specific).

3. **Product Creation**: When products are generated, they inherit the energy state of the parent actors (if applicable).

### Example Reactions with Energy Costs

#### Biomarker Detection (Energy-Intensive)
```json
{
  "Label": "Biomarker-Nanosensor Detection (BM + NM → NM_detected)",
  "Is Reaction Reversible?": false,
  "Surface Reaction?": false,
  "Default Everywhere?": true,
  "Reactants": [1, 1, 0, 0],
  "Products": [0, 0, 1, 0],
  "Reaction Rate": 1e9999,
  "Binding Radius": 0.025e-6,
  "Is Energy Enabled?": true,
  "Energy Cost Type": "detection",
  "Energy Cost Value": 1e-4,
  "Energy Cost Unit": "per_reaction"
}
```
**Interpretation**: When a biomarker (molecule 0) collides with a nanosensor (molecule 1), the reaction produces a detected nanosensor (molecule 2). The actor managing molecule 1 (or 2) pays 1e-4 Joules for this detection event.

#### Information Gossip (Lower Cost)
```json
{
  "Label": "Nanosensor Information Gossip (NM + NM_detected → NM_detected + NM_gossip)",
  "Is Reaction Reversible?": false,
  "Surface Reaction?": false,
  "Default Everywhere?": true,
  "Reactants": [0, 1, 1, 0],
  "Products": [0, 0, 1, 1],
  "Reaction Rate": 1e9999,
  "Binding Radius": 2e-6,
  "Is Energy Enabled?": true,
  "Energy Cost Type": "communication",
  "Energy Cost Value": 0.5e-4,
  "Energy Cost Unit": "per_reaction"
}
```
**Interpretation**: When an idle nanosensor (molecule 1) meets a detected nanosensor (molecule 2), they share information. The reaction costs half the detection energy (0.5e-4 Joules) per nanosensor involved.

---

## Configuration Examples

### Example 1: Simple Energy-Managed Point Source and Receiver

```json
{
  "Description": "Basic energy-managed communication",
  "Output Filename": "energy_simple_demo",
  "Chemical Properties": {
    "Number of Molecule Types": 1,
    "Diffusion Coefficients": [1e-9],
    "Global Flow Type": "None",
    "Chemical Reaction Specification": []
  },
  "Environment": {
    "Subvolume Base Size": 1e-12,
    "Region Specification": [
      {
        "Label": "A",
        "Shape": "Sphere",
        "Type": "Normal",
        "Anchor Coordinate": [0, 0, 0],
        "Radius": 1e9999
      }
    ],
    "Actor Specification": [
      {
        "Notes": "Transmitter with energy budget",
        "Is Location Defined by Regions?": false,
        "Shape": "Point",
        "Outer Boundary": [0, 0, 0],
        "Is Actor Active?": true,
        "Start Time": 0,
        "Is Actor Independent?": true,
        "Action Interval": 5e-3,
        "Is Actor Activity Recorded?": true,
        "Release Interval": 1e-3,
        "Modulation Scheme": "CSK",
        "Modulation Strength": 100,
        "Is Molecule Type Released?": [true],
        "Is Energy Enabled?": true,
        "Energy Initial": 1.0,
        "Energy Max": 1.0,
        "Energy Drain Passive": 2.0,
        "Energy Cost Active": 0.05,
        "Energy Harvest Passive": 1.5,
        "Energy Harvest Active": 0.0
      },
      {
        "Notes": "Receiver with energy constraints",
        "Is Location Defined by Regions?": false,
        "Shape": "Sphere",
        "Outer Boundary": [0, 2e-6, 0, 0.5e-6],
        "Is Actor Active?": false,
        "Start Time": 1e-10,
        "Is Actor Independent?": true,
        "Action Interval": 1e-4,
        "Is Actor Activity Recorded?": true,
        "Is Molecule Type Observed?": [true],
        "Is Molecule Position Observed?": [false],
        "Is Energy Enabled?": true,
        "Energy Initial": 0.5,
        "Energy Max": 1.0,
        "Energy Drain Passive": 0.5,
        "Energy Cost Active": 1e-4,
        "Energy Harvest Passive": 0.8,
        "Energy Harvest Active": 0.0
      }
    ]
  }
}
```

### Example 2: Biomarker-Nanosensor Network (Recommended Template)

See file: `accord_config_sample_energy_biomarker_nanosensor.txt`

This configuration models:
- Biomarker emission from an active source
- Nanosensor detection of biomarkers (high energy cost)
- Information gossip between nanosensors (lower energy cost)
- Passive energy harvesting for continuous operation

---

## Molecule Types Reference

### Four-Molecule Biomarker-Nanosensor Model

| Index | Name | Role | Typical Energy Costs |
|-------|------|------|----------------------|
| 0 | Biomarker | Signal molecule; actively emitted | Emission: 0.05 J/mol |
| 1 | Nanosensor (Idle) | Initial state; consumes energy continuously | Drain: 0.5 J/s |
| 2 | Nanosensor (Detected) | State after detection; may harvest energy | Detection cost: 1e-4 J/reaction |
| 3 | Nanosensor (Informed) | State after receiving gossip; still constrained | Communication: 0.5e-4 J/reaction |

### Chemical Reactions Overview

| # | Reaction | Reactants | Products | Purpose | Energy Cost |
|---|----------|-----------|----------|---------|-------------|
| 1 | BM + NM → NM₁ | [1,1,0,0] | [0,0,1,0] | Initial detection | 1e-4 J |
| 2 | NM + NM₁ → NM₁ + NM₂ | [0,1,1,0] | [0,0,1,1] | First gossip | 0.5e-4 J |
| 3 | NM + NM₂ → 2×NM₂ | [0,1,0,1] | [0,0,0,2] | Gossip amplification | 0.5e-4 J |
| 4 | BM + NM₂ → NM₁ | [1,0,0,1] | [0,0,1,0] | Re-detection via gossip | 1e-4 J |

---

## Output and Monitoring

### Summary File Format

When energy management is enabled, the summary file (`_summary.txt`) includes energy statistics for each actor:

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

### Key Metrics

| Metric | Meaning |
|--------|---------|
| `EnergyDepleted` | Whether the actor ran out of energy during simulation |
| `EnergyFinal` | Energy level at simulation end |
| `EnergyMin` | Minimum energy reached during simulation |
| `EnergyMax` | Maximum energy reached during simulation |
| `EnergyMean` | Average energy level during simulation |
| `Time` | Time points where energy was sampled |
| `Energy` | Energy values at corresponding time points |

### Interpreting Results

1. **If `EnergyDepleted = YES`**: The actor ceased operation. Review if drain rates or costs are too high for the harvesting rate.
2. **If `EnergyMean` is very high**: Actors are over-provisioned; consider reducing initial energy or increasing drain to simulate more realistic constraints.
3. **If energy oscillates wildly**: May indicate rapid cycling between high-energy and low-energy states. Check for conflicting drain/harvest rates.

---

## Best Practices

### 1. Energy Balance

Ensure `Energy_Harvest >= Energy_Drain` (in the long run) for sustained operation:

```
Average Energy Gain = Energy_Harvest_Passive (J/s)
Average Energy Loss = Energy_Drain_Passive + (Event_Rate × Energy_Cost_Active)
```

### 2. Reaction-Level Costs

Use reaction-level energy costs to model **specific detection or communication modes**:
- High cost for sensitive detection
- Lower cost for gossip or information relay

### 3. Monitoring Energy Depletion

Add passive actors as energy observers to track when actors become inactive:
```json
"Is Actor Activity Recorded?": true,
"Is Time Recorded with Activity?": true
```

### 4. Testing Energy Impact

Run simulations with and without energy to quantify performance degradation:
- Baseline: `"Is Energy Enabled?": false`
- Constrained: `"Is Energy Enabled?": true` with realistic costs

---

## Advanced Topics

### Custom Molecule Types

Extend beyond the 4-molecule model by:
1. Increasing `"Number of Molecule Types"`
2. Adding new diffusion coefficients
3. Defining new reactions with specific energy costs

### Dynamic Energy Sources

Model energy injection via:
- High `Energy_Harvest_Active` values during specific reaction types
- Multiple actors with different harvest rates

### Heterogeneous Networks

Assign different energy parameters to different actors:
```json
"Is Energy Enabled?": true,
"Energy Drain Passive": 0.5    // Low-power node
```
vs.
```json
"Is Energy Enabled?": true,
"Energy Drain Passive": 5.0    // High-power node
```

---

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| Actors deplete immediately | `Energy_Drain_Passive` too high | Increase `Energy_Initial` or reduce drain rate |
| No energy variation in output | `Energy_Cost_Active = 0` | Set reaction-level costs or increase active events |
| Simulation too slow | High `Energy_Cost_Value` triggering frequent actor disabling | Review cost distribution; ensure events can complete |
| Unexpected reaction rates | Reaction energy costs blocking reactions | Verify `Is Energy Enabled?` is `true` only where intended |

---

## References

- **Main Simulator**: AcCoRD (Actor-based Communication via Reaction-Diffusion)
- **Documentation**: https://warwick.ac.uk/fac/sci/eng/staff/ajgn/software/accord/
- **Energy Model**: Based on realistic nanomachine energy constraints in molecular communication
- **Configuration Format**: JSON (RFC 7159)

---

**Version**: 1.0  
**Last Updated**: April 2026  
**Author**: AcCoRD Energy Management System  
