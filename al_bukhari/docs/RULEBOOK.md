# Al Bukhari rulebook

Every change is checked against this file, on a device, before it counts as
done. Reference screenshots are in `docs/screenshots/`.

Store rules were read from Apple's and Google's own pages on 2026-11-10. Items
marked *(unconfirmed)* could not be read from an official page that day and must
be re-checked before submission.

## 1. How to check a change

```powershell
.\deploy.ps1 -Install
```

This builds the release APK and installs it on the connected phone or
emulator. Then walk through every tab and compare with `docs/screenshots/`
and section 4. Also check once with the phone's text size set to large.
For iOS, run the **iOS** workflow on GitHub and try the build on
appetize.io or TestFlight (see README).

`flutter analyze` must report no issues.

## 2. Store requirements

### Apple App Store

| # | Rule | Source | How we meet it |
|---|------|--------|----------------|
| A1 | Built with Xcode 26+ and the iOS 26 SDK; targets iOS 13+ | Upcoming requirements | Built on GitHub's macOS runner (`.github/workflows/ios.yml`); targets iOS 15 |
| A2 | Quotations of religious texts must be accurate, not misleading | 1.1.5 | Arabic text is shipped verbatim; the build script refuses a mismatched download; verse counts checked against the canon |
| A3 | Final build: no placeholder text, dead links or crashes | 2.1(a) | No "coming soon" screens; robot and monkey tests |
| A4 | Screenshots show the app in use, not a splash or title | 2.3.3 | Store screenshots are the reader, player, Qibla and prayer screens |
| A5 | App name is 30 characters or fewer | 2.3.7 | "Al Bukhari" |
| A6 | Rights secured for everything in the app, icon and screenshots | 2.3.9, 5.2.1, 5.2.2 | Section 5 lists every source and its licence |
| A7 | Public APIs only; background modes used only for their purpose | 2.5.1, 2.5.4 | No private APIs; no background mode declared |
| A8 | No hidden or dormant features | 2.5.19 | No feature flags, no debug screens |
| A9 | Useful and app-like, not a copy of what is widely available | 4.1, 4.2, 4.3(b) | Verse-repeat memorisation is the core; original design |
| A10 | If resources must be downloaded on first launch, say the size and ask first | 4.2.3(ii) | Nothing is downloaded on launch |
| A11 | Privacy policy linked in App Store Connect and inside the app | 5.1.1(i) | More > Privacy; hosted URL needed (owner task) |
| A12 | Purpose strings clearly describe each use of data | 5.1.1(ii) | One string, for location |
| A13 | Location used only where directly relevant, with consent | 5.1.5 | Asked only on the Qibla and Prayer screens |
| A14 | Free app: any tip or donation must use in-app purchase | 3.1.1 | No payments of any kind |
| A15 | Privacy manifest declares required-reason APIs *(unconfirmed)* | Upcoming requirements | `ios/Runner/PrivacyInfo.xcprivacy`, included in the app target |
| A16 | Screenshot pixel sizes *(unconfirmed)* | App Store Connect | Check the current sizes when uploading |

### Google Play

| # | Rule | Source | How we meet it |
|---|------|--------|----------------|
| G1 | New apps target Android 16 (API 36) | Target API requirements | `targetSdk = 36` |
| G2 | Native libraries support 16 KB pages | Page sizes guide | NDK r28 aligns by default; verify the Rust `.so` with `zipalign -c -P 16 -v 4` |
| G3 | Personal accounts created after 13 Nov 2023: closed test with 12 testers for 14 continuous days | Testing requirements | Owner task before production |
| G4 | Data safety form completed, even when nothing is collected | Data safety | Declare: no data collected, no data shared |
| G5 | Privacy policy on the listing and in the app: public https page, not a PDF | Prepare for review | Same policy as A11 |
| G6 | Request coarse location whenever fine is requested; foreground only | Target SDK page | We request **coarse only**, never background |
| G7 | Icon 512x512 PNG; feature graphic 1024x500; 2 to 8 phone screenshots | Preview assets | Icon done; feature graphic is an owner task |
| G8 | Short description is 80 characters or fewer | Preview assets | Written at listing time |

## 3. Privacy rules

1. No accounts, no ads, no analytics, no crash reporting SDKs.
2. Location is read as *approximate* only, used on the device, and saved only on
   the device, rounded to about a kilometre. It is never sent anywhere.
3. Qibla, magnetic declination and prayer times are calculated in the Rust core
   with no network call.
4. The only network requests the app makes are verse audio files from
   `cdn.islamic.network`, and only after the user presses play. Each verse is
   downloaded once and then played from the phone.
5. A new dependency is allowed only after its source is checked for network
   calls and identifiers.

## 4. Design rules

Palette (fixed): green `#5D866C`, tan `#C2A68C`, sand `#E6D8C3`, paper
`#F5F5F0`, sky `#A6C8E2`. Text colours are derived for contrast and listed in
`lib/theme/palette.dart`.

1. Body text contrast is at least 7:1; secondary text and text on
   colour at least 4.5:1; large marks and fills at least 3:1.
2. Raw green `#5D866C` is never used for small text on paper (3.8:1). Use
   `greenDeep` for text, and raw green for fills, rules and large marks.
3. Each colour has one job: green = Quran and "active", sky = time and
   direction, tan = rules and quiet marks, sand = raised surfaces.
4. The page is a manuscript page, not a dashboard: content sits on paper,
   separated by hairline rules. No floating card grids, no drop shadows, no
   gradients, no glass blur, no emoji as icons, no rows of pill chips.
5. Arabic is the hero: Amiri Quran, at least 26pt, line height 2.0 or more so
   marks never collide, right-to-left, never truncated or letter-spaced.
6. Translation is set in Newsreader (serif); interface labels and numerals in
   Instrument Sans. No third family.
7. Touch targets are at least 48x48. Every icon button has a label for screen
   readers.
8. Nothing clips or overflows at text sizes 1.0, 1.3 and 2.0, on a
   small phone, a large phone, a tablet and in landscape.
9. One primary action per screen. Motion only where it carries meaning (the
   compass turns; nothing bounces).
10. Every screen has a designed empty, loading and refused-permission state.
11. **Few words.** A label is one to three plain words. No instructions, no
    sentences on working screens: position, colour and shape do the guiding.
    Numbers beat words ("2 / 5", "×3", "23°"). Sentences are allowed only on
    the Privacy and Sources pages.
12. Brand: the minaret mark appears on the launch screen, the Quran tab header
    and the More tab. Nowhere else, so it stays a signature and not wallpaper.

## 5. Content sources and licences

| Content | Source | Terms | Shown in app |
|---------|--------|-------|--------------|
| Arabic text (Uthmani, Hafs from Asim) | Tanzil Project, via Al Quran Cloud API | Verbatim copies only; credit Tanzil and link tanzil.net | More > Sources |
| English translation | Saheeh International (Jeddah), via Tanzil / Al Quran Cloud | **Non-commercial use only**; credit translator | More > Sources |
| Verse audio | Mahmoud Khalil Al-Husary (default), Mishary Alafasy; Islamic Network CDN, 64 kbps | Free non-commercial redistribution; reciters may ask for removal | More > Sources |
| Fonts | Amiri Quran, Newsreader, Instrument Sans | SIL Open Font License 1.1 | Licence files in `assets/fonts/` |
| Logo | Kalyan Minaret mark, supplied by the owner | Owner's own work | Launch, Quran, More |

Consequence: the app must stay free, with no ads or purchases, unless written
permission is obtained from the translation's publisher and the reciters.

### Hanafi defaults

- Asr: Hanafi (shadow twice the object's length). Other schools selectable.
- Method: Karachi (Fajr 18 degrees, Isha 18 degrees). Others selectable.
- Recitation and text: Hafs from Asim.
- These are calculation defaults, not rulings. The Sources page tells users to
  check with their mosque.

## 6. Engineering rules

1. Calculations live in Rust (`rust/src/api/`). Dart draws screens.
2. Layers depend downwards only: theme < data < core < features < app.
   Features do not import each other (the shared place screens live in
   `features/places/`).
3. Small files, one job each.
4. Each part that can fail has its own failure state: start-up (Try again),
   location (retry or choose a city), audio (Offline, retry), polar days.
5. No state-management or routing packages; `ChangeNotifier` and `Navigator`.
6. Only code that ships stays in the project. No test suites or dev tooling
   are kept; checks are done on a device before each release.
7. If something does not work after an honest attempt, remove it completely
   before trying another approach.
