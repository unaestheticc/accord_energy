# Documentation - AcCoRD Energy Management System

Welcome. This folder contains all project documentation in English.

## Start Here

- For quick usage in 5 minutes: [QUICK_START.md](QUICK_START.md)
- For architecture and project scope: [REFACTORING_SUMMARY_EN.md](REFACTORING_SUMMARY_EN.md)
- For full configuration details: [GUIDE_CONFIGURATION_ENERGY_SYSTEM_EN.md](GUIDE_CONFIGURATION_ENERGY_SYSTEM_EN.md)
- For implementation details (Phase 2): [IMPLEMENTATION_NOTES_EN.md](IMPLEMENTATION_NOTES_EN.md)

## File Guide

- [QUICK_START.md](QUICK_START.md): Fast onboarding and runnable commands.
- [EXECUTIVE_SUMMARY_EN.md](EXECUTIVE_SUMMARY_EN.md): Short English summary of completed work and remaining tasks.
- [REFACTORING_SUMMARY_EN.md](REFACTORING_SUMMARY_EN.md): Full project refactoring report.
- [GUIDE_CONFIGURATION_ENERGY_SYSTEM_EN.md](GUIDE_CONFIGURATION_ENERGY_SYSTEM_EN.md): Complete configuration manual.
- [ENERGY_SYSTEM_EN.md](ENERGY_SYSTEM_EN.md): Technical behavior and energy model details.
- [IMPLEMENTATION_NOTES_EN.md](IMPLEMENTATION_NOTES_EN.md): Developer guide and runtime integration notes.
- [PROJECT_STATUS.md](PROJECT_STATUS.md): Current status and roadmap.
- [INDEX.md](INDEX.md): Full documentation index.

## Quick Simulation Command

```bash
cd /home/mathis/Documents/FIB/I2R/AcCoRD_energy
./src/accord_energy config/accord_config_sample_energy_biomarker_nanosensor.txt
```

## Notes

- Molecule model: BM, NM, NM_1, NM_2.
- Reaction-level energy costs are defined directly in configuration reactions.
- Existing configurations remain backward compatible.

If you need one single entry point, use [INDEX.md](INDEX.md).
