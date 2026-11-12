//! Magnetic declination from the NOAA World Magnetic Model, so a magnetic
//! compass heading can be turned into a true-north heading on the device.

use world_magnetic_model::time::Date;
use world_magnetic_model::uom::si::angle::degree;
use world_magnetic_model::uom::si::f32::{Angle, Length};
use world_magnetic_model::uom::si::length::meter;
use world_magnetic_model::GeomagneticField;

fn declination_on(latitude: f64, longitude: f64, year: i32, day_of_year: u16) -> Option<f64> {
    let date = Date::from_ordinal_date(year, day_of_year).ok()?;
    let field = GeomagneticField::new(
        Length::new::<meter>(0.0),
        Angle::new::<degree>(latitude as f32),
        Angle::new::<degree>(longitude as f32),
        date,
    )
    .ok()?;
    Some(field.declination().get::<degree>() as f64)
}

/// Degrees to add to a magnetic heading to get a true heading (east positive).
///
/// The bundled model covers a fixed range of years. Outside it the nearest
/// covered year is used: declination drifts slowly, so this stays far closer
/// than applying no correction at all.
#[flutter_rust_bridge::frb(sync)]
pub fn magnetic_declination(latitude: f64, longitude: f64, year: i32, day_of_year: u16) -> f64 {
    let day = day_of_year.clamp(1, 365);
    declination_on(latitude, longitude, year, day)
        .or_else(|| {
            (2020..=2034)
                .rev()
                .find_map(|y| declination_on(latitude, longitude, y, 1))
        })
        .unwrap_or(0.0)
}
