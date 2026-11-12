//! Prayer times for one day at one place, calculated on the device.
//!
//! Standard solar-position method (as published by PrayTimes.org): one
//! refinement pass, sunrise/sunset at 0.833 degrees below the horizon, and
//! the angle-based rule for latitudes where twilight does not end.

/// Which twilight angles to use for Fajr and Isha.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum CalcMethod {
    /// Fajr 18, Isha 17
    MuslimWorldLeague,
    /// Fajr 15, Isha 15
    NorthAmerica,
    /// Fajr 19.5, Isha 17.5
    Egyptian,
    /// Fajr 18.5, Isha 90 minutes after Maghrib
    UmmAlQura,
    /// Fajr 18, Isha 18
    Karachi,
}

/// Minutes after local midnight for each time.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct PrayerTimes {
    pub fajr: i32,
    pub sunrise: i32,
    pub dhuhr: i32,
    pub asr: i32,
    pub maghrib: i32,
    pub isha: i32,
}

enum Isha {
    Angle(f64),
    MinutesAfterMaghrib(f64),
}

fn angles(method: CalcMethod) -> (f64, Isha) {
    match method {
        CalcMethod::MuslimWorldLeague => (18.0, Isha::Angle(17.0)),
        CalcMethod::NorthAmerica => (15.0, Isha::Angle(15.0)),
        CalcMethod::Egyptian => (19.5, Isha::Angle(17.5)),
        CalcMethod::UmmAlQura => (18.5, Isha::MinutesAfterMaghrib(90.0)),
        CalcMethod::Karachi => (18.0, Isha::Angle(18.0)),
    }
}

fn julian_day(year: i32, month: u32, day: u32) -> f64 {
    let (mut y, mut m) = (year as f64, month as f64);
    if m <= 2.0 {
        y -= 1.0;
        m += 12.0;
    }
    let a = (y / 100.0).floor();
    let b = 2.0 - a + (a / 4.0).floor();
    (365.25 * (y + 4716.0)).floor() + (30.6001 * (m + 1.0)).floor() + day as f64 + b - 1524.5
}

/// (declination in degrees, equation of time in hours)
fn sun_position(jd: f64) -> (f64, f64) {
    let d = jd - 2451545.0;
    let g = (357.529 + 0.98560028 * d).rem_euclid(360.0).to_radians();
    let q = (280.459 + 0.98564736 * d).rem_euclid(360.0);
    let l = (q + 1.915 * g.sin() + 0.020 * (2.0 * g).sin())
        .rem_euclid(360.0)
        .to_radians();
    let e = (23.439 - 0.00000036 * d).to_radians();
    let ra = (e.cos() * l.sin())
        .atan2(l.cos())
        .to_degrees()
        .rem_euclid(360.0)
        / 15.0;
    let decl = (e.sin() * l.sin()).asin().to_degrees();
    // The equation of time is a matter of minutes; keep it near zero.
    let eqt = (q / 15.0 - ra + 12.0).rem_euclid(24.0) - 12.0;
    (decl, eqt)
}

struct Day {
    jd: f64,
    lat: f64,
}

impl Day {
    fn mid_day(&self, t: f64) -> f64 {
        let (_, eqt) = sun_position(self.jd + t);
        (12.0 - eqt).rem_euclid(24.0)
    }

    /// Hour at which the sun is `angle` degrees below the horizon; NaN if it
    /// never gets there on this day.
    fn sun_angle_time(&self, angle: f64, t: f64, before_noon: bool) -> f64 {
        let (decl, _) = sun_position(self.jd + t);
        let noon = self.mid_day(t);
        let (lat, decl) = (self.lat.to_radians(), decl.to_radians());
        let cos_h = (-angle.to_radians().sin() - decl.sin() * lat.sin()) / (decl.cos() * lat.cos());
        let h = cos_h.acos().to_degrees() / 15.0;
        if before_noon {
            noon - h
        } else {
            noon + h
        }
    }

    fn asr(&self, shadow_factor: f64, t: f64) -> f64 {
        let (decl, _) = sun_position(self.jd + t);
        let x = shadow_factor + (self.lat - decl).abs().to_radians().tan();
        let angle = -(1.0 / x).atan().to_degrees();
        self.sun_angle_time(angle, t, false)
    }
}

/// Prayer times for the given civil date.
///
/// `utc_offset_hours` is the device's offset from UTC on that date.
/// Returns `None` where the sun does not rise or set that day.
#[flutter_rust_bridge::frb(sync)]
#[allow(clippy::too_many_arguments)]
pub fn prayer_times(
    latitude: f64,
    longitude: f64,
    year: i32,
    month: u32,
    day: u32,
    utc_offset_hours: f64,
    method: CalcMethod,
    hanafi_asr: bool,
) -> Option<PrayerTimes> {
    let d = Day {
        jd: julian_day(year, month, day) - longitude / (15.0 * 24.0),
        lat: latitude,
    };
    let (fajr_angle, isha_rule) = angles(method);

    let sunrise = d.sun_angle_time(0.833, 6.0 / 24.0, true);
    let dhuhr = d.mid_day(12.0 / 24.0);
    let asr = d.asr(if hanafi_asr { 2.0 } else { 1.0 }, 13.0 / 24.0);
    let sunset = d.sun_angle_time(0.833, 18.0 / 24.0, false);
    if sunrise.is_nan() || sunset.is_nan() || asr.is_nan() {
        return None;
    }

    // Angle-based limit for places where twilight lasts all night.
    let night = (sunrise - sunset).rem_euclid(24.0);
    let mut fajr = d.sun_angle_time(fajr_angle, 5.0 / 24.0, true);
    let fajr_limit = night * fajr_angle / 60.0;
    if fajr.is_nan() || sunrise - fajr > fajr_limit {
        fajr = sunrise - fajr_limit;
    }
    let isha = match isha_rule {
        Isha::MinutesAfterMaghrib(m) => sunset + m / 60.0,
        Isha::Angle(a) => {
            let t = d.sun_angle_time(a, 18.0 / 24.0, false);
            let limit = night * a / 60.0;
            if t.is_nan() || t - sunset > limit {
                sunset + limit
            } else {
                t
            }
        }
    };

    let shift = utc_offset_hours - longitude / 15.0;
    let minutes = |h: f64| ((h + shift) * 60.0).round() as i32;
    let maghrib = minutes(sunset);
    Some(PrayerTimes {
        fajr: minutes(fajr),
        sunrise: minutes(sunrise),
        dhuhr: minutes(dhuhr),
        asr: minutes(asr),
        maghrib,
        isha: match isha_rule {
            Isha::MinutesAfterMaghrib(m) => maghrib + m as i32,
            Isha::Angle(_) => minutes(isha),
        },
    })
}
