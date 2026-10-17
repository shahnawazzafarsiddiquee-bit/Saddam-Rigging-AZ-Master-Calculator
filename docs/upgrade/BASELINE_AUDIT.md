# Preserved baseline audit

Source application: Saddam Rigging A-Z Master Calculator (Flutter/Dart).
Baseline application commit: `9a1965f22c7529bb02d6225900353c5a0b873f1e`.
Upgrade branch: `upgrade/rigsafe-super-pro`.
Baseline CI commit: `377a21c01bcbdf505d6f58935fe1d63f799e4303`.
Baseline CI run: `39051201748` (debug APK build and artifact upload succeeded).

## Existing architecture and modules

- Material 3 Flutter app. Main routes plus direct Navigator routes and two Dart part libraries.
- Calculations currently distributed across original calculator screens, advanced calculators, synthetic sling, hardware selector and planning screens.
- Existing tools include sling angle/load sharing/WLL/shackle/wire rope/D-d/CG/pad eye, tandem/spreader/dynamic/multipoint/bolt torque, material weights, units, boom geometry, ground bearing, wind, crane finder/charts/OCR, synthetic slings, diagrams and total summary.
- Equipment register and offline QR; two inspection paths, photo history, certificates, logbook and favourites.
- Lift plan forms, generated PDF documents, JSA, risk assessment, TBT and reports.
- OCR: Google ML Kit; PDF import rasterized with printing; generated PDF engine: pdf + printing.
- Voice feature is a text command parser using keyboard dictation, not an integrated speech service.
- No authentication, cloud synchronization, BLE protocol, NFC integration or official immutable critical-lift PDF template found.
- No existing test directory. CI skipping tests is not evidence of passing application tests.

## Data preservation

| File | Version | Tables |
|---|---|---|
| saddam_rigging_master.db | 1 | Equipment, Inspection, Calculations, LiftPlans, SafetyRecords, Reports |
| rigging_pro.db | 1 | chart, certs |
| rigging_pro2.db | 1 | lifts, inspections, photos, favs |

Production device databases are not available in this checkout. Migration tests must use faithful schema fixtures, and must not be reported as an actual production-device migration.
Existing backup exports only the first database. Restore deletes before validation and reassigns primary keys; it needs correction before schema upgrades.
Inspection photos are database blobs; report PDFs are external files referenced by path.

## Visual and installation identity

- Preserve lib/app/theme.dart and existing widgets/routes.
- Existing orange primary 0xFFFF6F00; navy 0xFF15335C, navyLight 0xFF2A4E85; background 0xFF1E1E1E; cards 0xFF2A2E33; text 0xFFECEFF1.
- Existing status palette: success 0xFF2E7D32, danger 0xFFC62828, warning 0xFFF9A825.
- Existing screenshots in play_store/screenshots are historical reference assets, not newly captured runtime verification.
- Preserve Android application ID com.saddam.rigging.azmaster and existing signing identity. Actual in-place installation must still be verified on a device.

## Safety issues to address in existing modules

- Universal wind 20/32 km/h limits appear in wind, summary, PDF, voice and dashboard tips.
- Representative crane tables interpolate/clamp radii and can show SAFE without approved configuration.
- Several calculators label mathematical checks SAFE without adequate WLL/source/inspection evidence.
- Missing/invalid values are frequently coerced to zero; finite-number and boundary validation is incomplete.
- Crane finder lacks inspection/certificate/configuration validity gates.
- OCR values lack persistent source/revision/verification metadata.
- Inspection rejection is not transactionally linked to equipment quarantine.
- Backup is incomplete and non-atomic; chart replacements delete previous data.

## External prerequisites

Exact critical-lift PDF overlay requires the original user-supplied PDF; no template will be fabricated.
Approved manufacturer charts/derating, site rules, weather credentials, BLE device protocol, role identity provider and cloud endpoint must be configured before those integrations can be verified.

## File inventory

| File | SHA-256 |
|---|---|
| .github/workflows/build_apk.yml | a6a220c3f7bd885121ca1ccb4e8dacd1b4c1a5461834e2c8a58516d754bc9ce3 |
| .github/workflows/release_apk.yml | 66b9530db4b87e5b0dacf56f24dd24784021289132fbac40f0866ad37c7385f6 |
| .github/workflows/rigsafe-upgrade.yml | 465f33cfe6431f0ae2f69f7081c38807043b1c7314d65daa5a52a5422185a7b1 |
| PRIVACY_POLICY.md | b0eed2ac896d7140697ae8ac055fb2c8d335619dc523797a1392039fb77887b8 |
| README.md | c99a0c6e0dfd6b060a0648bd87c88c22936bd714100e2cce5aff1c44b0953c58 |
| analysis_options.yaml | 7463c6b7af8142a2dcf3f80efc777520f24ac670def643fcd10ac63bf6590d7d |
| android/app/build.gradle | 0a91a4f484444ac7c6278441400be99e6bc9c923faf5c049f66667dff2ef8a27 |
| android/app/src/main/AndroidManifest.xml | 1d2b2bf998953687185799b09faf9a16389fd5a31a00a7d14d5dea32f54bccb4 |
| android/app/src/main/res/drawable/launch_background.xml | 7afbeb514b6f94b66b6dccc653b8620406c7daf49e53e173bf8560059d1e0a3f |
| android/app/src/main/res/values/styles.xml | 5655281e440a12e47433b862f52b71b8a8d3627a18ef04758ef5a82c863291d2 |
| android/build.gradle | b7d2068c506515a52dca36c762cd0854f79b1dbfa08e84982d216da38dc52990 |
| android/gradle.properties | 0c2b46fd6d2e6d3b45b78ee0beaa34b0a0b2d6b14b11a6153c4e51465cb67962 |
| android/settings.gradle | 99a41d99e224c4aea5ef46f283a63f8a10282cf93711bb945255f0d1e380539f |
| lib/app/routes.dart | 2dcf8f7c1120036060d03dafd8b8e2132fbda4e3e8811f2a42cb0f73ed474395 |
| lib/app/theme.dart | 6b7abdd1187067301ffe9c6ab24589c4424099efe908084e2fccf10f72627d91 |
| lib/calculators/cog.dart | a548b8d818bfa3319c51b88ad6d056e9485536cd9318e8cc98c2808f2ca93b85 |
| lib/calculators/dd_ratio.dart | cd36d081f3a02ea2fa4e4f7afb97d603d4e8101c70752c3a377dcc2d809ad3db |
| lib/calculators/load_share.dart | 5b82e498aa09fdb1f0a7ecf737133948421a49d710a296b666efdc70ff399fb2 |
| lib/calculators/pad_eye.dart | bc00d43b724bf79452183604cbc93b8a93addf3406347aa8586329cc8f1d11b9 |
| lib/calculators/shackle.dart | 86e6a179e95c1a012d5d6c8a2073b8e9de2421046bf1fd1916f51b29b89c9f3c |
| lib/calculators/sling_angle.dart | d413e0167ccb17eb282ef4579b2776e2a9ff35d65f6b7b28558bb927eb18b663 |
| lib/calculators/wire_rope.dart | 01b02253a3e57287765bda3963d0cb6ac77b4025d7cb2a0041d6941e6221a109 |
| lib/calculators/wll.dart | 4f54ac605db0976729286a92dbd3d22349e82f80da65b5d20c614766d44a29d9 |
| lib/database/sqlite_helper.dart | ac91cfe97614c4c08b0029c84fc9c4f9061facae0e8188e6ba63757d5db16ad3 |
| lib/main.dart | edaad9e99052d39c198f0616727f8147af2bd631e03041b9fdb52fc149ecae8c |
| lib/models/equipment_model.dart | a22e7484bacabfe3861cf833fee2c2ec24b582c72907f5109fc8cd7a69308b07 |
| lib/models/inspection_model.dart | 1850a70dc6b06b9e860f268cf49e7e200c791d160b0867282917c446183b0a33 |
| lib/models/lift_model.dart | 61b9bb88df223f9f93b606671df37e837609e49b5f7de56ecbe85bbaeca880a0 |
| lib/screens/advanced_calculators.dart | 9fbd485749dae07afba4c63b912ed7c3f1869ddd0e2670d2a0fa79304f638186 |
| lib/screens/crane_planning.dart | f49192eb896ca4849901a6f3a35d5a70838fe277c8afba0f0b2f52b877a72138 |
| lib/screens/dashboard.dart | be503b913e958365cc9737f14b645da20da3bc0de0fa9ddf1c95d5487cd5351b |
| lib/screens/equipment.dart | f1974fd65f5e9d99a071b3dc89c7d5a572c866d3a783f2465d5852ba0cb389cf |
| lib/screens/hardware_selector.dart | 67bfc66dba1820bef3d5e362b77742c9c06b992d0b459add3b8a8e34c625023e |
| lib/screens/hse.dart | 6d73fa11d5a9c988549998699656c07d03a2a893ef34a28fea0ef75a4a160e6b |
| lib/screens/lift_plan.dart | 657818e57db257b6d056b8dfd1b2f057e7c8d53dae13eced220278db5019edbc |
| lib/screens/lift_total_summary.dart | dc949a22de5b408e6ce8634dc4ade7d28e2395ca22a5ae1d8c2d3a310c439115 |
| lib/screens/material_calculators.dart | 11bc2f2a39d8914f162d0d1c7c110737090fe848b9f1474b384e7fea0de5f130 |
| lib/screens/pro2_db.dart | 6f52eb7515364f4effc76e5c1c5d65a633b03c5e9de32ebe6b54ed6182427e69 |
| lib/screens/pro2_diagram.dart | dedefa91e7460a5a14e87556fca528e00c7019cf87ea991062f8d4311795e572 |
| lib/screens/pro2_inspect.dart | f76926b725e7e5643d5212466f1d3dd5fe442641b1074f62cb086a8cf6dfb667 |
| lib/screens/pro2_inspect_view.dart | e76a9eafb512c6cede82f4ef6ebaaee45e46100ac60012a4aea478baa5b36189 |
| lib/screens/pro2_logbook.dart | 37e392d7b3966e17e40cf68beff6fed5a276bcaf4b6a0c30c0fcf36d37eb82c3 |
| lib/screens/pro2_voice.dart | 4b233a22621e162ffff527749fa26d4e387853d0ccabe84cb3676c034fa1c0fc |
| lib/screens/reports.dart | e8c5f08a3286d0e489160a590203b3e7297c5cfe249088b51f7df8f860a33369 |
| lib/screens/rigging_advanced.dart | c34851b60305ea1c13afab94978239bec4d565e3b5a5d21398032525e8ea79f7 |
| lib/screens/rigging_pro.dart | dc0d932a63336e86f4378c0300bca212658df986f493f9a0444c6aa42fd44420 |
| lib/screens/rigging_pro2.dart | 949ed5e0cd35b0bad8f93ffc80b3c6df04037f1a7c770c3116ae15035099a5e6 |
| lib/screens/rigging_pro_capacity.dart | 727827e23855ffa23d2b860b97b0ac4528935ca2519d181e56ff0f3798337926 |
| lib/screens/rigging_pro_cert.dart | 4d742cb2549dc004f4156cc6e929ff481a7c3cd5ec41603e1a7c3a62f3f7db65 |
| lib/screens/rigging_pro_chart.dart | f7b7b9f1969540090e6e4792a5fc6f265790a774adfe035b491639c023de716e |
| lib/screens/rigging_pro_chartedit.dart | afd6fcffca40691ccdf4b20494cef1012178089c304ec946d5686505e91564fa |
| lib/screens/rigging_pro_db.dart | 953c5b5835b6710e1db5888bad621a827392ef4d9a593115e091e3188c5424e2 |
| lib/screens/rigging_pro_finder.dart | 53207668f9af68c4cb995e172957e181655073025be7225fed6aba073454c71e |
| lib/screens/rigging_pro_ocr.dart | 9605dfa407a7b8b1d674912a950c55c57d197e5de81726cf0e6480855497420b |
| lib/screens/rigging_pro_pdf.dart | 5c74c845789f907b0bd991027a90491e5b5c8d0323c3eec3b283c510c836bcfc |
| lib/screens/rigging_pro_pdfkit.dart | 11e27cbd260f03351e65786d4ba2d17821a76788a895998698eaa428d8015471 |
| lib/screens/rigging_pro_pull.dart | d0560bd61433137e9a6dfd7c4c450675578b99ac1e25cf69887284098a3bbc5f |
| lib/screens/rigging_pro_section.dart | d035c1f8891285f243e754f167270807f80a7dcb227d68a1c94284bea725571a |
| lib/screens/rigging_tools.dart | caa12a53af566b053fbf029949e728777f8a919bbf000d2a08b4fdc3963cae5a |
| lib/screens/settings.dart | 726fa231caceadb8c7419ede3e1277ddbb00fde212d6f82e5eb39a55d58fa645 |
| lib/screens/synthetic_sling.dart | fbf7226d498af0905dd45eddd28bb73002d35d58ab902a69dd219d3db829cadb |
| lib/screens/unit_converter.dart | a69b8591e3f80c77a9c7b599e7be71340744eb059f8d2c98d076cf7cfefd6eb7 |
| lib/services/backup_service.dart | eb672506863f662f02f6d74a01b89f3ea4e3e22c2c387fef3566b7270826f340 |
| lib/services/pdf_service.dart | 772e9b61a758a87b8ae585a651f94714c11c8d06bdf32e0c6b7c467d90f9c3a0 |
| lib/services/qr_service.dart | 6ee30ceebc722ce73d0c794536ea9069579200cb1c4d863f6225b8a73fde3678 |
| play_store/README.md | 784e4269966296007c083d5a8f97ce55f6cc92b96efebc6bb96a7a5134774401 |
| pubspec.yaml | 6b582da3a0d348244c83db9f69809d62b4becc53026f47b98953c86b33cb05ab |
