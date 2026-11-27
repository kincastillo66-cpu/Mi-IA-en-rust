use std::ffi::{CStr, CString};
use std::os::raw::c_char;

#[no_mangle]
pub extern "C" fn procesar_texto(input: *const c_char) -> *mut c_char {
    // 1. Convertimos el texto que llega de Flutter a un formato que Rust entienda
    let c_str = unsafe { CStr::from_ptr(input) };
    let texto_recibido = c_str.to_str().unwrap_or("Error al leer el texto");

    // 2. Aquí es donde el "cerebro" procesa el mensaje. 
    // Por ahora solo lo repetirá con un prefijo para probar la conexión.
    let respuesta = format!("🧠 Rust dice: Recibí tu mensaje '{}'. ¡Pronto conectaré la IA aquí!", texto_recibido);

    // 3. Devolvemos el texto a Flutter
    CString::new(respuesta).unwrap().into_raw()
}

#[no_mangle]
pub extern "C" fn liberar_memoria(ptr: *mut c_char) {
    // Función vital para que la app no consuma toda la RAM
    if ptr.is_null() { return; }
    unsafe {
        let _ = CString::from_raw(ptr);
    }
}