# Energy Consumption in Intra-Body Nanomachine Networks
## Molecular Communication and Terahertz — Concise Literature Review

> **Context**: two communication paradigms for intra-body nanomachines are compared:
> **diffusion-based molecular communication (MC)** and **terahertz (THz) electromagnetic
> communication**. The focus is on energy costs per elementary operation.

---

## Part I — Diffusion-Based Molecular Communication

### Energy Model (Kuran et al., 2010)

Information is encoded in **messenger molecules** (e.g. insulin) released by a transmitter
nanomachine and detected by a receiver. Molecule propagation uses **zero added energy**
(Brownian motion driven by thermal energy). Energy is spent only at **emission**.

#### The four emission phases

Emission is modelled on cellular exocytosis (pancreatic β-cell analogy):

| Phase | Mechanism | Formula | Cost (insulin, r_unit = 10 µm) |
|---|---|---|---|
| **1. Synthesis** | Ribosome assembles amino acids. Each peptide bond = 1 ATP. | $E_S = 202.88 \times (n_{aa}-1)$ zJ | **10,144 zJ ≈ 10 aJ** per molecule |
| **2. Vesicle** | Golgi packages molecules in a lipid vesicle. Cost ∝ surface area. | $E_V = 83 \times 5 \times 4\pi r_v^2$ zJ | ≈ 13 zJ per vesicle |
| **3. Transport** | Motor proteins walk along microtubules, 8 nm per ATP step. | $E_C = 83 \lceil r_{unit}/(2 \times 8) \rceil$ zJ | ≈ 51,875 zJ per vesicle |
| **4. Fusion** | SNARE proteins fuse vesicle to membrane (~10 ATP). | $E_E = 83 \times 10$ zJ | = 830 zJ per vesicle |

> **Key constant**: 1 ATP = 83 zJ (Freitas, *Nanomedicine*, 1999).
>
> zepto :  z  = $$10^{-21}$$ 
>
> atto : a = $$10^{-18}$$
>
> femto : f = $$10^{-15}$$
>
> pico : p = $$10^{-12}$$

**Synthesis dominates**: the vesicle overhead (phases 2–4, ≈ 52.7 aJ per vesicle of 1540 molecules)
is only ~0.3 % of the per-molecule synthesis cost.

#### Total emission energy

$$E_T = n \cdot E_S + \left\lceil \frac{n}{c_v} \right\rceil (E_V + E_C + E_E)$$

where $n$ = molecules emitted, $c_v$ = vesicle capacity (≈ 1540 for insulin, r_v = 50 nm).

#### Energy cost per symbol

| Distance | Molecules needed | **E_T** |
|---|---|---|
| 1–2 µm | 10–100 | **0.15 – 1 fJ** |
| 2–8 µm | 100–500 | **1 – 5 fJ** |
| 8–32 µm | 500–5,000 | **5 – 500 fJ** |
| Power-budget per symbol (P = 4.5 pW) | — | **0.5 – 100 pJ** |

#### What is NOT modelled

The cost of **biomarker detection** (receptor–ligand binding, signal transduction) and
**gossip exchanges** between nanosensors are **not quantified** in any existing MC energy
model. This is an open gap in the literature.

---

## Part II — Terahertz Electromagnetic Communication (brief)

THz communication uses **100 fs EM pulses** from graphene antennas (0.1–10 THz band,
TS-OOK modulation). Energy is stored in a ZnO piezoelectric nanogenerator + ultra-nanocapacitor.

#### Energy cost per operation (Jornet & Akyildiz, 2012)

| Operation | Energy |
|---|---|
| 1 pulse transmitted (d ≤ 10 mm) | **1 pJ** |
| 1 pulse received | **0.1 pJ** |
| 200-bit packet TX | **≈ 100 pJ** |
| Optimal packet TX (48 bits) | **≈ 24 pJ** |
| Full capacitor capacity | **≈ 800 pJ** |

---

## Part III — MC vs. THz Comparison

| Criterion | MC (diffusion) | THz (EM) |
|---|---|---|
| Energy/symbol at < 10 µm | **0.1 – 10 fJ** ✓ | ≥ 1 pJ ✗ |
| Propagation energy | **Zero** ✓ | Included in E_pulse ✗ |
| Range | a few µm (direct) | a few cm ✓ |
| Data rate | 50–200 bit/s | kbit/s – Tbit/s ✓ |
| Biocompatibility | Intrinsic ✓ | To be demonstrated |
| Detection cost modelled | **œNo** | **No** |

> **Summary**: MC is **100–1000× more energy-efficient per symbol** than THz at
> intra-vascular scales (< 10 µm). THz is required for communication beyond a few mm
> and for node localisation. Neither paradigm currently models the cost of biomarker
> detection or inter-nanosensor gossip — this is the gap the AcCoRD energy extension
> addresses.

---

*Sources: Kuran et al. (2010), Jornet & Akyildiz (2012), Freitas (1999).*
