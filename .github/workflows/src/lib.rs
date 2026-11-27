// src/lib.rs
#[no_mangle]
pub extern "C" fn saludar_desde_rust() -> *const u8 {
    b"¡Hola! Soy el cerebro de Rust, listo para procesar IA.\0".as_ptr()
}
