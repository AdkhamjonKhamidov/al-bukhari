//! Direction and distance to the Kaaba. Pure maths, no I/O.

const KAABA_LAT: f64 = 21.4225;
const KAABA_LON: f64 = 39.8262;
const EARTH_RADIUS_KM: f64 = 6371.0088;

/// Initial great-circle bearing to the Kaaba, in degrees clockwise from
/// true north (0..360).
#[flutter_rust_bridge::frb(sync)]
pub fn qibla_bearing(latitude: f64, longitude: f64) -> f64 {
    let phi = latitude.to_radians();
    let phi_k = KAABA_LAT.to_radians();
    let d_lambda = (KAABA_LON - longitude).to_radians();
    let y = d_lambda.sin();
    let x = phi.cos() * phi_k.tan() - phi.sin() * d_lambda.cos();
    y.atan2(x).to_degrees().rem_euclid(360.0)
}

/// Great-circle distance to the Kaaba in kilometres.
#[flutter_rust_bridge::frb(sync)]
pub fn distance_to_kaaba_km(latitude: f64, longitude: f64) -> f64 {
    let phi1 = latitude.to_radians();
    let phi2 = KAABA_LAT.to_radians();
    let d_phi = phi2 - phi1;
    let d_lambda = (KAABA_LON - longitude).to_radians();
    let a = (d_phi / 2.0).sin().powi(2) + phi1.cos() * phi2.cos() * (d_lambda / 2.0).sin().powi(2);
    2.0 * EARTH_RADIUS_KM * a.sqrt().asin()
}
