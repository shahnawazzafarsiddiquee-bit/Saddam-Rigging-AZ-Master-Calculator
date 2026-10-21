# Upgrade feature matrix

One combined application. This matrix tracks all 113 requested requirements; a row marked Partial is not a completed enterprise module.

Verified Phase 8: run 39564576329, source a68143004001e4d5fc8abe292479d2ee55ff4f61, 146 tests, debug/universal APK and AAB, native same-key update and backup/rollback passed. VersionCode 1023. Owner-signed exports retain the exact application payload. See TEST_REPORT.md for limits.

| # | Feature | Existing | Upgraded | New | Tested | Status |
|---|---|---|---|---|---|---|
| 1 | Main navigation | Partial | No | No | No | Audit mapped; upgrade pending |
| 2 | Smart home dashboard | Partial | No | No | No | Audit mapped; upgrade pending |
| 3 | Site environment snapshot | No | Yes | Yes | Partial | Reusable point-in-time snapshot, optional permission-based Android GPS/manual fallback, connectivity, manual weather and wind; frozen links in lift/inspection/JSA. Real GPS field testing pending. |
| 4 | Wind module | Partial | Yes | Yes | Partial | Manual speed/gust/direction/source/time and documented limits with age checks; stored snapshots and PDF. Weather/BLE are interfaces, not active integrations; no background live monitoring. |
| 5 | BLE anemometer | No | No | Yes | Partial | WindProvider interface and tested BLE/weather/manual source priority; actual device discovery, pairing and protocol decoder pending. |
| 6 | Smart radius | Partial | Yes | Yes | Partial | Existing boom route supports manual, site coordinates, scaled drawing and offset boom geometry with field-verification record. GPS is not used for radius; AR pending. |
| 7 | Pick/max/set radius | No | No | Yes | Yes | Separate calculated and independently verified pick/maximum/set values with verifier/time; maximum must cover endpoints. Full lift-wizard attachment remains pending. |
| 8 | Boom geometry | Partial | Yes | Yes | Partial | Shared geometry and diagram retained; manufacturer geometry override prohibited; height/offset boundaries tested. |
| 9 | Crane charts | Partial | Yes | Yes | Partial | Source/configuration metadata, exact rows, verified OCR draft, persistent imported document and archived old rows on replacement/withdrawal; no assumed interpolation. Field OCR review pending. |
| 10 | Gross hook load and utilization | Partial | Yes | Yes | Yes | Shared gross-load and utilization engine; explicit accessory/hook masses; verified source gate |
| 11 | Crane finder | Partial | Yes | No | Partial | Actual gross mass, exact pick/max/set matches and registered inspected/certified crane filter; recommendations require final confirmation. Height/clearance and availability scheduling not automated. |
| 12 | Ground bearing | Partial | Yes | Yes | Yes | Manufacturer reaction or identified engineering estimate, canonical pressure/mat math, immutable records and frozen lift attachment; no self-weight-based guessed reaction. |
| 13 | Verified ground source | No | No | Yes | Yes | Source/revision/approver inputs and verification gates in existing ground screen |
| 14 | Outrigger mats | Partial | Yes | Yes | Partial | Pad/mat dimensions, thickness/type/count and scaled plan drawing; quantity does not inflate single-outrigger area. Structural mat adequacy still requires engineering verification. |
| 15 | Outrigger reaction | No | No | Yes | Yes | Explicit sourced manufacturer or engineering-estimate reaction with crane/configuration/quadrant; no generated reaction or GPS soil capacity. |
| 16 | Crane visualizer | Partial | No | No | No | Audit mapped; upgrade pending |
| 17 | Synthetic sling | Partial | Yes | Yes | Partial | Existing form upgraded with tag/configuration/source verification and tested assembly-factor math; complete asset linkage pending |
| 18 | Web sling | Partial | Yes | Yes | Partial | Vertical/choker/basket/double-basket/bridle with supplied approved assembly factor; no universal rating assumed |
| 19 | Sling colour reference | Partial | Yes | No | Partial | Reference chart marked UNVERIFIED; tag required; managed standard/manufacturer/revision datasets pending |
| 20 | Body vs inspection colour | No | No | Yes | Partial | Separate fields and result metadata; persistent inspection-period lifecycle pending |
| 21 | Sling tag OCR | No | No | No | No | Implementation pending |
| 22 | Sling angle | Partial | Yes | Yes | Yes | Both conventions and 90 degree case; actual configuration WLL/source; form edit invalidation |
| 23 | Load share | Partial | Yes | Yes | Partial | Two-point and symmetric effective-leg math tested; full unequal multi-point geometry pending |
| 24 | CG | Partial | Yes | Yes | Yes | XYZ math/input and offset cases tested; requested top/side visual views pending |
| 25 | Wire rope | Partial | Yes | No | Partial | Wire-rope validation plus manufacturer-criteria inspection checklist; physical inspection remains a competent-person task |
| 26 | Chain sling | Partial | Yes | No | Partial | Chain inspection checklist includes grade/diameter/master-link/legs; dedicated asset attributes and complete calculation UI pending |
| 27 | Round sling | Partial | Yes | No | Partial | Synthetic verification and round-sling inspection linked to registered asset, certificate and QR history |
| 28 | Shackle calculator | Partial | Yes | Yes | Partial | Catalogue no longer clamps overload; verified manufacturer derating engine; source datasets still required |
| 29 | Shackle inspection | Partial | Yes | No | Partial | Dedicated body/pin/threads/wear/corrosion/marking/side-load inspection; offline transaction tested |
| 30 | Hook inspection | Partial | Yes | No | Partial | Dedicated opening/twist/wear/crack/latch/swivel/ID checklist; no invented rejection dimensions |
| 31 | Master link inspection | Partial | Yes | Yes | Partial | Dedicated wear/stretch/distortion/crack/heat/corrosion/WLL checklist |
| 32 | Pad eye | Partial | Yes | No | Partial | Invalid input/overflow guards only; engineering calculation/report extension pending |
| 33 | Beam assets | No | No | No | No | Implementation pending |
| 34 | Rigging compatibility | Partial | No | No | No | Audit mapped; upgrade pending |
| 35 | Edge protection | Partial | Yes | Yes | Partial | Damage and sharp unprotected edge gates tested; full compatibility library pending |
| 36 | Rigging diagram builder | Partial | No | No | No | Audit mapped; upgrade pending |
| 37 | Rigging kits | No | No | No | No | Implementation pending |
| 38 | Asset selection | No | Yes | Yes | Partial | Lift Plan selects current registered/certified equipment; revalidates at save. Required-WLL/fit auto-selection pending |
| 39 | Equipment QR | Partial | Yes | No | Partial | QR asset view links to prefilled inspection and history; camera/device scan still needs field testing |
| 40 | NFC | No | No | No | No | Pending implementation and external configuration/template/device evidence |
| 41 | Digital inspections | Partial | Yes | No | Partial | Eleven dedicated categories plus preserved legacy category; photos/project/procedure/inspector and typed attestation; identity not authenticated |
| 42 | Web sling inspection | Partial | Yes | No | Partial | Web-sling checklist covers requested damage categories; incomplete and unjustified N/A cannot pass |
| 43 | Inspection statuses | Partial | Yes | Yes | Yes | PASS/HOLD/REJECT rules; REJECT quarantines atomically; rollback and all-N/A tests passed |
| 44 | Quarantine | Partial | Yes | No | Yes | Quarantined gear blocked at lift save; PASS does not release quarantine; audit/history retained. Authorized release workflow pending |
| 45 | Scrap/destroy | No | No | No | No | Implementation pending |
| 46 | AI photo screening | No | No | No | No | Pending implementation and external configuration/template/device evidence |
| 47 | Certificates | Partial | No | No | No | Audit mapped; upgrade pending |
| 48 | Certificate OCR | No | No | No | No | Pending implementation and external configuration/template/device evidence |
| 49 | MTR | No | No | No | No | Pending implementation and external configuration/template/device evidence |
| 50 | Competency | No | No | No | No | Pending implementation and external configuration/template/device evidence |
| 51 | User roles | No | No | No | No | Pending implementation and external configuration/template/device evidence |
| 52 | Company/project | No | No | No | No | Pending implementation and external configuration/template/device evidence |
| 53 | Lift wizard | Partial | Yes | No | Partial | Existing form validates weight and selected equipment at save; records equipment snapshot. Complete 13-step wizard pending |
| 54 | Critical classification | Partial | No | No | No | Audit mapped; upgrade pending |
| 55 | Tandem lift | Partial | No | Yes | Partial | Shared tandem load split and utilization math tested; complete UI/configuration/approval pending |
| 56 | Blind lift | No | No | No | No | Implementation pending |
| 57 | Power lines | No | No | No | No | Implementation pending |
| 58 | Exclusion zone | No | No | No | No | Implementation pending |
| 59 | Crane inspection | Partial | Yes | No | Partial | Crane pre-use checklist added to existing inspection workflow; configured permit gating pending |
| 60 | Permit to lift | No | No | No | No | Implementation pending |
| 61 | JSA | Partial | Yes | No | Partial | Existing JSA can retain a frozen site/environment snapshot; complete risk/signature workflow pending. |
| 62 | TBT | Partial | No | No | No | Audit mapped; upgrade pending |
| 63 | Hand signals | No | No | No | No | Implementation pending |
| 64 | Near miss | No | No | No | No | Implementation pending |
| 65 | Emergency | No | No | No | No | Implementation pending |
| 66 | Live lift | No | No | No | No | Implementation pending |
| 67 | Approval workflow | No | No | No | No | Pending implementation and external configuration/template/device evidence |
| 68 | Digital signature | No | No | No | No | Pending implementation and external configuration/template/device evidence |
| 69 | Revisions | Partial | No | No | No | Audit mapped; upgrade pending |
| 70 | Audit trail | No | Yes | Yes | Partial | Inspection/quarantine events, frozen lift snapshots, and chart revision archive; application-wide audit/approval identity pending. |
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
| 90 | Voice entry | Partial | Yes | No | Partial | Existing typed/keyboard-mic command shows parsed crane values and routes missing data to Finder; no guessed 0.5-ton rigging or automatic rope selection. Dedicated speech integration pending. |
| 91 | Notifications | Partial | No | No | No | Audit mapped; upgrade pending |
| 92 | AI assistant | No | No | No | No | Pending implementation and external configuration/template/device evidence |
| 93 | Approved library | No | No | No | No | Pending implementation and external configuration/template/device evidence |
| 94 | Calculation sources | No | No | Yes | Partial | Engine source classification and method/warnings; full reference library pending |
| 95 | Calculation engine | No | No | Yes | Yes | Dedicated tested engine; remaining legacy UI calculations still need integration |
| 96 | Units | Partial | Yes | Yes | Yes | Canonical units and converter tested; app-wide unit preference and remaining legacy integration pending |
| 97 | Validation | Partial | Yes | Yes | Partial | Finite/domain/overflow checks in upgraded calculators; all assets/permits not yet gated |
| 98 | Automated calculation tests | No | No | Yes | Yes | 146 tests passed through Phase 8, including chart/finder and transaction regression. Native same-key update and backup also verified separately. |
| 99 | Edge tests | No | No | Yes | Partial | Angles, zero/missing ratings, overload, CG, source gates tested; device outages pending |
| 100 | Visual regression | No | No | Yes | Partial | Original palette assertions, 53 screen constructions and native dashboard/equipment/synthetic screenshots pass; full pixel regression pending |
| 101 | Migration tests | No | No | Yes | Partial | 12-table IDs/photos and native same-key update/rollback pass through Phase 8. Owner key differs from published APK; production device migration unverified. |
| 102 | Performance | Partial | No | No | No | Audit mapped; upgrade pending |
| 103 | Security | Partial | No | No | No | Audit mapped; upgrade pending |
| 104 | Weather key security | No | No | No | No | Pending implementation and external configuration/template/device evidence |
| 105 | Incomplete-data handling | Partial | Yes | Yes | Partial | Upgraded modules display incomplete until source verification; legacy modules remain to audit |
| 106 | Human authorization | Partial | Yes | Yes | Partial | Engine results always require human authorization; full role workflow pending |
| 107 | Feature flags | No | No | No | No | Implementation pending |
| 108 | Phased delivery | No | No | Yes | Partial | Phases 0-8 checkpoints built/tested; later enterprise phases incomplete. Each deliverable remains one combined app. |
| 109 | Preserve existing features | Partial | Yes | No | Partial | Existing screens/routes retained; no schema deletion or redesign; broader regression pending |
| 110 | Feature matrix | No | No | Yes | Manual | All 113 requirements tracked; partial items explicitly identified |
| 111 | Deliverables | No | No | Yes | Partial | Existing source branch and draft PR5; combined universal APK/AAB build pipeline; owner signing does not establish published-key update compatibility. |
| 112 | Final report | No | No | Yes | Partial | Checkpoint report delivered; full enterprise completion pending |
| 113 | Decision-support limits | Partial | Yes | Yes | Partial | Source/assumption/warning detail in shared result UI; broader legacy checks still pending |
