# Al Bukhari: structure and priorities

## Structure

```
rust/src/api/            Memory-safe core, no network
  qibla.rs               Bearing and distance to the Kaaba
  declination.rs         Magnetic declination (true north on Android)
  prayer.rs              Prayer times for a date, place and method
lib/
  main.dart              Start-up, with a Try again state
  app.dart               Theme, light status bar, four-tab shell
  theme/                 Palette, type, brand mark, star lattice and arch shapes
  data/                  Quran model, city search, saved settings
  core/                  Rust wrapper, GPS, compass, place time zones
  features/
    quran/               Surah list, reader, player (verse/range/surah loops),
                         audio store
    qibla/               Compass screen and dial
    prayer/              Today's times and sun path
    places/              "Set your place" screen and the place picker
    more/                Settings, sources, privacy policy
assets/                  Quran text (gzip), city list (gzip), fonts, icon,
                         privacy policy
docs/                    Rulebook, priorities, reference screenshots
tool/build_data.mjs      Rebuilds the bundled Quran text and city list
deploy.ps1               Build / install / store bundle
```

How data is kept small:

- Quran text with translation and phonetics: 2.9 MB of JSON, shipped as
  0.9 MB gzip, unpacked off the main thread at start-up.
- City list: 1.7 MB, shipped as 0.7 MB gzip, read the first time a place is
  searched.
- Audio: 64 kbps per verse, downloaded once and kept on the phone (up to
  200 MB, oldest removed first). The next verse is fetched while the current
  one plays, so ranges and surahs play without gaps.

## Priorities

**Built (first release, Android)**
1. Quran in Arabic, English and phonetic English; all 114 surahs offline.
2. Repeat a verse, a range or a whole surah, 1/3/5/10 times or forever.
3. Two reciters: Al-Husary (default), Alafasy.
4. Continue where you left off; surah search.
5. Qibla compass with alignment vibration.
6. Prayer times, Hanafi by default, in the place's own time zone.
7. Place by GPS, city search or typed coordinates, all on the phone.
8. Privacy policy, sources and licences inside the app.

**Next**
1. Audio that keeps playing with the screen locked (needs a media service and
   a store declaration).
2. Download a whole surah for offline use (with the size shown first).
3. Bookmarks.
4. Prayer-time notifications (local only).

**Later**
1. Dark theme for night reading.
2. More reciters and translations (each needs its licence checked).
3. iOS release (needs a Mac).

## Owner tasks

1. Google Play developer account; 12-tester closed test if it is a new
   personal account.
2. Release signing key.
3. Host `assets/legal/privacy.md` at a public https address.
4. Confirm the bundle id (`com.albukhari.app`).
5. Confirm the translation choice and its non-commercial terms.
6. Try it on a real phone: compass accuracy, audio, GPS.
