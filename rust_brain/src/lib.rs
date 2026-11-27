
#[no_mangle]
pub extern "C" fn saludar_desde_rust() -> *const u8 {
    b"Hola desde el cerebro en Rust!\0".as_ptr()
}