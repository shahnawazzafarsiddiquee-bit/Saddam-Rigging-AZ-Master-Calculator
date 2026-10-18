# Upgrade feature matrix

Phase 2 verified checkpoint (run 39073629975: analysis, 82 tests, debug APK passed). Existing means some relevant implementation is present, not that the requested professional behavior is complete. No upgrade phase is marked tested before its CI evidence exists.

| # | Feature | Existing | Upgraded | New | Tested | Status |
|---|---|---|---|---|---|---|
| 1 | Main navigation | Partial | No | No | No | Audit mapped; upgrade pending |
| 2 | Smart home dashboard | Partial | No | No | No | Audit mapped; upgrade pending |
| 3 | Site environment snapshot | No | No | No | No | Implementation pending |
| 4 | Wind module | Partial | Yes | No | Partial | Universal limits removed; full configured wind/weather/BLE remains pending |
| 5 | BLE anemometer | No | No | No | No | Pending implementation and external configuration/template/device evidence |
| 6 | Smart radius | No | No | No | No | Implementation pending |
| 7 | Pick/max/set radius | No | No | No | No | Implementation pending |
| 8 | Boom geometry | Partial | No | No | No | Audit mapped; upgrade pending |
| 9 | Crane charts | Partial | Yes | No | Yes | Representative chart explicitly unverified; exact rows only; manufacturer import/configuration still pending |
| 10 | Gross hook load and utilization | Partial | Yes | Yes | Yes | Shared gross-load and utilization engine; explicit accessory/hook masses; verified source gate |
| 11 | Crane finder | Partial | No | No | No | Audit mapped; upgrade pending |
| 12 | Ground bearing | Partial | Yes | Yes | Yes | Shared pressure/mat math; existing form upgraded; soil/engineering approval still external |
| 13 | Verified ground source | No | No | Yes | Yes | Source/revision/approver inputs and verification gates in existing ground screen |
| 14 | Outrigger mats | Partial | Yes | Yes | Partial | Required/provided area and utilization math tested; structural mat design/drawing pending |
| 15 | Outrigger reaction | No | No | No | No | Implementation pending |
| 16 | Crane visualizer | Partial | No | No | No | Audit mapped; upgrade pending |
| 17 | Synthetic sling | Partial | No | No | No | Audit mapped; upgrade pending |
| 18 | Web sling | Partial | No | No | No | Audit mapped; upgrade pending |
| 19 | Sling colour reference | Partial | No | No | No | Audit mapped; upgrade pending |
| 20 | Body vs inspection colour | No | No | No | No | Implementation pending |
| 21 | Sling tag OCR | No | No | No | No | Implementation pending |
| 22 | Sling angle | Partial | Yes | Yes | Yes | Both conventions and 90 degree case; actual configuration WLL/source; form edit invalidation |
| 23 | Load share | Partial | Yes | Yes | Partial | Two-point and symmetric effective-leg math tested; full unequal multi-point geometry pending |
| 24 | CG | Partial | Yes | Yes | Yes | Existing CG screen supports XYZ; engine and offset cases tested |
| 25 | Wire rope | Partial | Yes | No | Partial | Finite/overflow validation and estimate labels; inspection/asset lifecycle still pending |
| 26 | Chain sling | Partial | No | No | No | Audit mapped; upgrade pending |
| 27 | Round sling | Partial | No | No | No | Audit mapped; upgrade pending |
| 28 | Shackle calculator | Partial | Yes | Yes | Partial | Catalogue no longer clamps overload; verified manufacturer derating engine; source datasets still required |
| 29 | Shackle inspection | Partial | No | No | No | Audit mapped; upgrade pending |
| 30 | Hook inspection | Partial | No | No | No | Audit mapped; upgrade pending |
| 31 | Master link inspection | Partial | No | No | No | Audit mapped; upgrade pending |
| 32 | Pad eye | Partial | Yes | No | Partial | Invalid input/overflow guards only; engineering calculation/report extension pending |
| 33 | Beam assets | No | No | No | No | Implementation pending |
| 34 | Rigging compatibility | Partial | No | No | No | Audit mapped; upgrade pending |
| 35 | Edge protection | Partial | No | No | No | Audit mapped; upgrade pending |
| 36 | Rigging diagram builder | Partial | No | No | No | Audit mapped; upgrade pending |
| 37 | Rigging kits | No | No | No | No | Implementation pending |
| 38 | Asset selection | No | No | No | No | Implementation pending |
| 39 | Equipment QR | Partial | No | No | No | Audit mapped; upgrade pending |
| 40 | NFC | No | No | No | No | Pending implementation and external configuration/template/device evidence |
| 41 | Digital inspections | Partial | No | No | No | Audit mapped; upgrade pending |
| 42 | Web sling inspection | Partial | No | No | No | Audit mapped; upgrade pending |
| 43 | Inspection statuses | Partial | No | No | No | Audit mapped; upgrade pending |
| 44 | Quarantine | Partial | No | No | No | Audit mapped; upgrade pending |
| 45 | Scrap/destroy | No | No | No | No | Implementation pending |
| 46 | AI photo screening | No | No | No | No | Pending implementation and external configuration/template/device evidence |
| 47 | Certificates | Partial | No | No | No | Audit mapped; upgrade pending |
| 48 | Certificate OCR | No | No | No | No | Pending implementation and external configuration/template/device evidence |
| 49 | MTR | No | No | No | No | Pending implementation and external configuration/template/device evidence |
| 50 | Competency | No | No | No | No | Pending implementation and external configuration/template/device evidence |
| 51 | User roles | No | No | No | No | Pending implementation and external configuration/template/device evidence |
| 52 | Company/project | No | No | No | No | Pending implementation and external configuration/template/device evidence |
| 53 | Lift wizard | Partial | No | No | No | Audit mapped; upgrade pending |
| 54 | Critical classification | Partial | No | No | No | Audit mapped; upgrade pending |
| 55 | Tandem lift | Partial | No | Yes | Partial | Shared tandem load split and utilization math tested; complete UI/configuration/approval pending |
| 56 | Blind lift | No | No | No | No | Implementation pending |
| 57 | Power lines | No | No | No | No | Implementation pending |
| 58 | Exclusion zone | No | No | No | No | Implementation pending |
| 59 | Crane inspection | Partial | No | No | No | Audit mapped; upgrade pending |
| 60 | Permit to lift | No | No | No | No | Implementation pending |
| 61 | JSA | Partial | No | No | No | Audit mapped; upgrade pending |
| 62 | TBT | Partial | No | No | No | Audit mapped; upgrade pending |
| 63 | Hand signals | No | No | No | No | Implementation pending |
| 64 | Near miss | No | No | No | No | Implementation pending |
| 65 | Emergency | No | No | No | No | Implementation pending |
| 66 | Live lift | No | No | No | No | Implementation pending |
| 67 | Approval workflow | No | No | No | No | Pending implementation and external configuration/template/device evidence |
| 68 | Digital signature | No | No | No | No | Pending implementation and external configuration/template/device evidence |
| 69 | Revisions | Partial | No | No | No | Audit mapped; upgrade pending |
| 70 | Audit trail | No | No | No | No | Implementation pending |
| 71 | Exact PDF template | No | No | No | No | Pending implementation and external configuration/template/device evidence |
| 72 | PDF autofill | No | No | No | No | Pending implementation and external configuration/template/device evidence |
| 73 | PDF visual test | No | No | No | No | Pending implementation and external configuration/template/device evidence |
| 74 | Lift package | Partial | No | No | No | Audit mapped; upgrade pending |
| 75 | Weight verification | No | No | No | No | Implementation pending |
| 76 | Pre-lift photos | Partial | No | No | No | Audit mapped; upgrade pending |
| 77 | Quick field check | No | No | No | No | Implementation pending |
| 78 | Calculation summary | Partial | Yes | Yes | Partial | Explicit gross load and missing-data gates; full integrated lift package pending |
| 79 | Result statuses | Partial | Yes | Yes | Partial | Shared result statuses in upgraded modules; unchanged legacy modules still need audit |
| 80 | Offline operation | Partial | No | No | No | Audit mapped; upgrade pending |
| 81 | Cloud sync | No | No | No | No | Pending implementation and external configuration/template/device evidence |
| 82 | Sync conflicts | No | No | No | No | Pending implementation and external configuration/template/device evidence |
| 83 | Management dashboard | No | No | No | No | Implementation pending |
| 84 | Toolroom | No | No | No | No | Implementation pending |
| 85 | Equipment transfer | No | No | No | No | Implementation pending |
| 86 | Reports | Partial | No | No | No | Audit mapped; upgrade pending |
| 87 | Excel/CSV export | No | No | No | No | Implementation pending |
| 88 | Global search | Partial | No | No | No | Audit mapped; upgrade pending |
| 89 | Translations | No | No | No | No | Pending implementation and external configuration/template/device evidence |
| 90 | Voice entry | Partial | Yes | No | Partial | Typed wind command no longer uses universal limits; actual speech input pending |
| 91 | Notifications | Partial | No | No | No | Audit mapped; upgrade pending |
| 92 | AI assistant | No | No | No | No | Pending implementation and external configuration/template/device evidence |
| 93 | Approved library | No | No | No | No | Pending implementation and external configuration/template/device evidence |
| 94 | Calculation sources | No | No | Yes | Partial | Engine source classification and method/warnings; full reference library pending |
| 95 | Calculation engine | No | No | Yes | Yes | Dedicated pure-Dart calculation engine with typed results and source gates |
| 96 | Units | Partial | Yes | Yes | Yes | Canonical kg/m/N/Pa/m/s and dimension-checked metric/imperial conversion |
| 97 | Validation | Partial | Yes | Yes | Partial | Finite/domain/overflow checks in upgraded calculators; all assets/permits not yet gated |
| 98 | Automated calculation tests | No | No | Yes | Yes | 82 tests passed in run 39073629975; added native/journal checks under verification |
| 99 | Edge tests | No | No | Yes | Partial | Angles, zero/missing ratings, overload, CG, source gates tested; device outages pending |
| 100 | Visual regression | No | No | Yes | Partial | Original palette/button assertions and 53 screen construction checks; pixel regression pending |
| 101 | Migration tests | No | No | Yes | Partial | Frozen v1 schemas/12-table restore/IDs/blobs tests pass; native update check in progress |
| 102 | Performance | Partial | No | No | No | Audit mapped; upgrade pending |
| 103 | Security | Partial | No | No | No | Audit mapped; upgrade pending |
| 104 | Weather key security | No | No | No | No | Pending implementation and external configuration/template/device evidence |
| 105 | Incomplete-data handling | Partial | Yes | Yes | Partial | Upgraded modules display incomplete until source verification; legacy modules remain to audit |
| 106 | Human authorization | Partial | Yes | Yes | Partial | Engine results always require human authorization; full role workflow pending |
| 107 | Feature flags | No | No | No | No | Implementation pending |
| 108 | Phased delivery | No | No | Yes | Partial | Baseline and phases 1/2 APKs built; phase 2 native validation in progress |
| 109 | Preserve existing features | Partial | Yes | No | Partial | Existing screens/routes retained; no schema deletion or redesign; broader regression pending |
| 110 | Feature matrix | No | No | Yes | Manual | All 113 requirements tracked; partial items explicitly identified |
| 111 | Deliverables | No | No | No | No | Implementation pending |
| 112 | Final report | No | No | No | No | Implementation pending |
| 113 | Decision-support limits | Partial | Yes | Yes | Partial | Source/assumption/warning detail in shared result UI; broader legacy checks still pending |
