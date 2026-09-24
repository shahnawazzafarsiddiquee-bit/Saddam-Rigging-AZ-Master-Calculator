# Play Store listing – Saddam Rigging A-Z Calculator

Is folder mein Play Console ke liye sab kuch taiyar hai. Neeche wala text copy-paste karo.

## Files

| File | Play Console mein kahan |
|---|---|
| `icon-512.png` | Store listing → App icon (512 x 512) |
| `feature-graphic-1024x500.png` | Store listing → Feature graphic |
| `screenshots/01 … 06` | Store listing → Phone screenshots (sabhi 6 daalo) |
| AAB (`app-release.aab`) | Release → Create new release → App bundles |

AAB: GitHub → Actions → "Build Android APK" ka latest run → Artifacts → `saddam-rigging-play-store-aab` (zip ke andar `app-release.aab`).

## Store listing text

**App name** (30 akshar tak)

```
Saddam Rigging A-Z Calculator
```

**Short description** (80 akshar tak)

```
Rigging, crane lift, sling, shackle & HSE calculator for site riggers. Offline.
```

**Full description**

```
Saddam Rigging A-Z Master Calculator is a complete offline toolkit for riggers, lifting supervisors, crane operators and HSE teams.

RIGGING & LIFTING
• Sling angle, load share, WLL, shackle, wire rope, D/d ratio, centre of gravity, pad eye
• Sling length & angle for containers and pipes
• Crane Finder, crane boom & capacity, crane load chart, lift diagram
• Tandem (two-crane) lift, spreader beam, multi-point (3/4 point) lift
• Dynamic / shock load factor, wind check, ground bearing, pulling force

SLINGS & HARDWARE
• Hardware Quick Selector: web sling, round sling, wire rope, chain G80 / G100 in vertical, choker and basket hitch, 1 to 4 leg bridle, with shackle and master link
• Synthetic Sling Calculator: EN 1492 capacity table, colour code, polyester / nylon / polypropylene temperature and chemical check, pre-use reject checklist
• Bolt torque & rigging pad check

PLANS & SAFETY
• Lift Total Summary with PDF export and sign-off
• Lift plan generator and PDF, job logbook, reports
• Inspection checklist with photos, certificate expiry tracker, QR equipment register
• Material weights: steel sections, pipe, plate, concrete, tanks; unit converter

Works fully offline. No login, no ads. Your data stays on your phone.

Note: results are estimates. Always follow the crane load chart, sling certificate and an approved lift plan by a competent person.
```

**Release notes** (pehli release)

```
First release: rigging, crane and sling calculators, Hardware Quick Selector, Synthetic Sling Calculator (EN 1492), Tandem lift, Lift Total Summary with PDF.
```

**Category:** Tools  **Tags:** Engineering, Calculator
**Privacy policy URL** (PR merge hone ke baad chalega):

```
https://github.com/shahnawazzafarsiddiquee-bit/Saddam-Rigging-AZ-Master-Calculator/blob/main/PRIVACY_POLICY.md
```

## App content (Policy → App content) ke jawab

| Form | Jawab |
|---|---|
| Privacy policy | Upar wala link |
| Ads | No, my app does not contain ads |
| App access | All functionality is available without special access |
| Content rating | Category "Utility, Productivity, Communication or other" → sab sawaal "No" |
| Target audience | 18 and over |
| Data safety | "Does your app collect or share any of the required user data types?" → **No** (sab data sirf phone par rehta hai) |
| Government app | No |
| Financial features | My app doesn't provide any financial features |
| Health | No health features |
| News app | No |

## Upload kaise karein (step by step)

1. **Account:** play.google.com/console → developer account banao (ek baar 25 USD) → identity verify karo.
2. **Create app:** App name `Saddam Rigging A-Z Calculator`, Default language English, App, Free → declarations tick karke Create.
3. **Store listing:** Grow users → Store presence → Main store listing → upar ka text, icon, feature graphic, 6 screenshots daalo → Save.
4. **App content:** Policy → App content → upar ki table ke hisaab se har form bharo.
5. **Testing:** Naya personal account hai to Test and release → Testing → **Closed testing** → track banao → testers ki email list (kam se kam 12) → Create release → `app-release.aab` upload → release notes → Save → Review → Start rollout. 12 testers ko 14 din lagatar app install rakhna zaruri hai.
6. **Production:** 14 din baad Dashboard par "Apply for production" → sawaal bharo → approval ke baad Production → Create new release → wahi (ya naya) AAB → Rollout.
7. **Update:** Har update ke liye naya build chalao (Actions → Build Android APK → Run workflow), naya AAB download karke naya release banao. Version number apne aap badhta hai.

**Zaruri:** upload key (`saddam-upload-key.jks`) aur uska password surakshit rakho. Play par har update isi key se signed hona chahiye.
