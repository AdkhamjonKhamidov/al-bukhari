// Builds the app's bundled data. Run once when the sources change:
//
//   node tool/build_data.mjs
//
// assets/quran/quran.json.gz   Arabic (Tanzil Uthmani, verbatim), English
//                              (Saheeh International) and English
//                              transliteration, from the keyless Al Quran
//                              Cloud API. Non-commercial terms apply.
// assets/places/cities.tsv.gz  Every city over 15,000 people (GeoNames,
//                              CC BY 4.0) for offline place search.
//
// The script stops on anything unexpected, so bad data can never ship.
import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { gzipSync, inflateRawSync } from 'node:zlib';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');

function save(path, text) {
  const out = join(root, path);
  mkdirSync(dirname(out), { recursive: true });
  const raw = Buffer.from(text);
  const packed = gzipSync(raw, { level: 9 });
  writeFileSync(out, packed);
  console.log(`${path}: ${raw.length} -> ${packed.length} bytes`);
}

async function get(url) {
  const res = await fetch(url);
  if (!res.ok) throw new Error(`${url}: HTTP ${res.status}`);
  return res;
}

// ---------------------------------------------------------------- Quran
async function quran() {
  const edition = async (id) => (await (await get(`https://api.alquran.cloud/v1/quran/${id}`)).json()).data.surahs;
  const [ar, en, tr] = await Promise.all(['quran-uthmani', 'en.sahih', 'en.transliteration'].map(edition));
  if ([ar, en, tr].some((e) => e.length !== 114)) throw new Error('expected 114 surahs');

  const clean = (s) => s.replace(/﻿/g, '').trim();
  const letters = (s) => s.replace(/[^ء-يٱ ]/g, '');
  const basmala = clean(ar[0].ayahs[0].text);
  const basmalaTr = clean(tr[0].ayahs[0].text);
  const words = basmala.split(' ').length;

  let total = 0;
  const surahs = ar.map((s, i) => {
    if (s.ayahs.length !== en[i].ayahs.length || s.ayahs.length !== tr[i].ayahs.length) {
      throw new Error(`surah ${s.number}: verse counts differ`);
    }
    const ayahs = s.ayahs.map((a, j) => {
      let text = clean(a.text);
      // The source prefixes the Basmala to verse 1 of most surahs; the app
      // shows it as a heading instead. The verse itself is untouched.
      if (j === 0 && s.number !== 1 && s.number !== 9) {
        const parts = text.split(' ');
        if (letters(parts.slice(0, words).join(' ')) !== letters(basmala)) {
          throw new Error(`surah ${s.number}: Basmala not found`);
        }
        text = parts.slice(words).join(' ');
      }
      total++;
      return [text, clean(en[i].ayahs[j].text), clean(tr[i].ayahs[j].text)];
    });
    return {
      n: s.number,
      ar: clean(s.name).replace(/^سُورَةُ\s*/, ''),
      en: s.englishName,
      meaning: s.englishNameTranslation,
      place: s.revelationType,
      ayahs,
    };
  });
  if (total !== 6236) throw new Error(`expected 6236 verses, got ${total}`);
  save('assets/quran/quran.json.gz', JSON.stringify({ basmala, basmalaTr, surahs }));
}

// ---------------------------------------------------------------- Places
/** Reads the single file inside a zip archive. */
function unzipOne(buf) {
  if (buf.readUInt32LE(0) !== 0x04034b50) throw new Error('not a zip');
  const method = buf.readUInt16LE(8);
  // Sizes live in the central directory when bit 3 is set; find it from the end.
  const eocd = buf.lastIndexOf(Buffer.from([0x50, 0x4b, 0x05, 0x06]));
  const cd = buf.readUInt32LE(eocd + 16);
  const size = buf.readUInt32LE(cd + 20);
  const start = 30 + buf.readUInt16LE(26) + buf.readUInt16LE(28);
  const data = buf.subarray(start, start + size);
  return method === 8 ? inflateRawSync(data) : data;
}

async function places() {
  const base = 'https://download.geonames.org/export/dump/';
  const countries = new Map();
  for (const line of (await (await get(base + 'countryInfo.txt')).text()).split('\n')) {
    if (!line || line.startsWith('#')) continue;
    const f = line.split('\t');
    countries.set(f[0], f[4]);
  }
  const zip = Buffer.from(await (await get(base + 'cities15000.zip')).arrayBuffer());
  const rows = [];
  for (const line of unzipOne(zip).toString('utf8').split('\n')) {
    const f = line.split('\t');
    if (f.length < 18) continue;
    const [name, ascii, alternates, lat, lon, cc, pop, tz] = [f[1], f[2], f[3], f[4], f[5], f[8], +f[14], f[17]];
    if (!countries.has(cc) || !tz) continue;
    // Big cities also answer to their common English spellings (Makkah, Madinah).
    const aliases = new Set([ascii]);
    if (pop >= 500000) {
      for (const a of alternates.split(',')) {
        if (/^[A-Z][A-Za-z' -]{2,29}$/.test(a)) aliases.add(a);
      }
    }
    aliases.delete(name);
    rows.push({ pop, line: [name, [...aliases].join('|'), cc, (+lat).toFixed(3), (+lon).toFixed(3), tz].join('\t') });
  }
  if (rows.length < 30000) throw new Error(`only ${rows.length} cities`);
  rows.sort((a, b) => b.pop - a.pop);
  const header = [...countries].map(([c, n]) => `${c}=${n}`).join('\t');
  save('assets/places/cities.tsv.gz', [header, ...rows.map((r) => r.line)].join('\n'));
}

await Promise.all([quran(), places()]);
