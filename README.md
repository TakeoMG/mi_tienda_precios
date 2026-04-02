#  Mi Tienda - Precios

Una aplicación móvil moderna, rápida y profesional diseñada para el control de precios y ventas en pequeños negocios o tienditas en casa. Construida con **Flutter 3.x** y **Material 3**.

---

##  Características Principales
| Pantalla de Inicio | Módulo de Caja (Scanner) | Detalle de Producto | Metodo de filtrado de productos | Panel |
| :---: | :---: | :---: |
| <img src="screenshots/home.png" width="200"> | <img src="screenshots/caja.png" width="200"> | <img src="screenshots/editar.png" width="200"> | <img src="screenshots/filtro.png" width="200"> | <img src="screenshots/panel.png" width="200"> |
###  Gestión de Inventario Local
- **Persistencia Total:** Base de datos local con `sqflite` (funciona 100% offline).
- **Detalles del Producto:** Nombre, Categoría, Descripción, Precio y **Código de Barras**.
- **Búsqueda Inteligente:** Filtra productos por nombre o categoría en tiempo real.

###  Módulo de Caja (POS Móvil)
- **Escáner de Supermercado:** Usa la cámara para leer códigos de barras y sumar productos al instante.
- **Feedback Profesional:** Pitido real (`beep.mp3`) y vibración háptica al escanear.
- **Cálculo Automático:** Suma subtotales y total a cobrar sin necesidad de calculadora manual.
- **Búsqueda Manual:** Buscador integrado para productos sin código (frutas, verduras, etc.).

###  Herramientas de Administración
- **Importación Inteligente:** Carga listas masivas desde CSV evitando duplicados (actualiza precios automáticamente si el nombre coincide).
- **Exportación Segura:** Comparte tu lista de precios por WhatsApp, Gmail o Drive en formato Excel/CSV.
- **Seguridad:** Bloqueo de edición por defecto para evitar cambios accidentales.
- **Modo Oscuro:** Soporte nativo que se adapta al sistema para cuidar la vista.

---

##  Tecnologías Utilizadas

- **Lenguaje:** Dart
- **Framework:** Flutter (Material 3)
- **Base de Datos:** SQLite (`sqflite`)
- **Estado:** Provider
- **Librerías Clave:**
  - `mobile_scanner`: Para el reconocimiento de códigos de barras.
  - `audioplayers`: Para el feedback sonoro de caja.
  - `share_plus`: Para compartir archivos CSV.
  - `file_picker`: Para importar inventarios externos.
  - `intl`: Para el formato de moneda local ($).

---

##  Instalación y Uso

1. **Clonar el repositorio:**
   ```bash
   git clone https://github.com/TakeoMG/mi_tienda_precios.git

2. **Instalar dependencias:**
    flutter pub get

3. **Ejecutar en modo Release:**
    flutter run --release

##  Autor
Construido con ❤️ por Takeo para ayudar en la gestión del negocio familiar.