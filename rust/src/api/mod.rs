pub mod declination;
pub mod prayer;
pub mod qibla;

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}
