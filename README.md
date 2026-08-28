# ICS55 ECOS PLL

This repository contains the integration package for the `PLL_TOP` hard macro. The layout follows the view-oriented convention used by open PDKs.

Version: `PLL_V02p1`

License: to be determined.

## Package layout

```text
README.md
verilog/             # behavioral and blackbox Verilog
lef/                 # physical abstract
lib/                 # Liberty abstract
```

The package contains four integration files:

- `verilog/PLL_TOP.behavioral.v`: behavioral simulation model.
- `verilog/PLL_TOP.blackbox.v`: blackbox declaration for synthesis and netlist elaboration.
- `lef/PLL_TOP.lef`: 200 um by 120 um physical abstract.
- `lib/PLL_TOP_typ.lib`: Liberty abstract for the `ics55_typ` operating condition (1.20 V, 25 C); no timing arcs are included.

GDS and CDL are not included.

## Use the package

Use the behavioral view in simulation and the blackbox view during synthesis or netlist elaboration. Use LEF for placement/routing. The Liberty view provides cell and pin data only; it does not model generated-clock latency, jitter, or lock time.

The package is for integration, not standalone tapeout. Physical implementation and signoff require the matching PDK and its published views.

Recommended configuration sequence:

1. Apply `AVDD/AVSS`, `DVDD/DVSS`, and `DVDD_DRV/DVSS_DRV`.
2. Drive `REFCLK` between 5 MHz and 40 MHz.
3. Set `N`, `SELECT`, `OD`, and `BP` before asserting `EN`.
4. Assert `EN` and allow approximately 15 us for startup.

## Interface and frequency behavior

| Group | Signals |
| --- | --- |
| Supplies | `AVDD`, `AVSS`, `DVDD`, `DVSS`, `DVDD_DRV`, `DVSS_DRV` |
| Inputs | `REFCLK`, `EN`, `BP`, `N[7:0]`, `SELECT`, `OD[1:0]` |
| Outputs | `CKOUT1`, `CKOUT2`, `CKTST` |

```text
KSELECT = (SELECT == 0) ? 1 : 2
DOUT    = 1, 2, 4, 8 for OD = 00, 01, 10, 11
FVCO    = FREFCLK * N * KSELECT
```

In PLL mode (`BP=0`), `FCKOUT1=FCKOUT2=FVCO/DOUT`. In bypass mode (`BP=1`), the behavioral model makes both main outputs follow `REFCLK`; this release does not include electrical characterization for bypass mode. The model drives `CKTST=FVCO/64`.

## Specification summary

| Item | Value |
| --- | --- |
| Process | ICS55, 55 nm |
| Supply voltage | 1.08 V to 1.32 V (1.20 V nominal) |
| Junction temperature (`TJ`) | -40 C to 125 C (25 C nominal) |
| Reference clock | 5 MHz to 40 MHz |
| VCO range | 500 MHz to 1200 MHz before output division |
| Feedback divider | `N` = 17 to 255 |
| Output dividers | 1, 2, 4, 8 |
| Startup time | 15 us typical |
| Typical operating current | 1500 uA |
| Period jitter | 30 ps typical |
| Macro size | 200 um x 120 um |

## Silicon status

This version of `PLL_TOP` has been fabricated as part of an SoC and operated successfully during board bring-up.

## Naming convention

The library name follows the [open-pdks IP naming convention](https://github.com/fossi-foundation/open-pdks#ip-naming-conventions) `<pdk-family>_<provider-tag>_<kind>`: `ics55_ecos_pll`. Existing cell names such as `PLL_TOP` remain unchanged.

For another ICS55 package using the same view-oriented layout, see [ICsprout 55 IO](https://github.com/openecos-projects/icsprout55-pdk/tree/main/IP/IO/ICsprout_55LLULP1233_IO_251013).
