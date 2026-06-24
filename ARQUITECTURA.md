# TecStore Manager Dummy — Documentación Técnica

> Basado en `tecstore-manager-firebase`. La diferencia central: el seed de datos (productos y clientes) se obtiene de la API REST **dummyjson** en lugar de datos hardcodeados. Firebase Auth y Firestore permanecen como capas de autenticación y persistencia.

## Índice
1. [Cómo está organizado el proyecto](#1-cómo-está-organizado-el-proyecto)
2. [Escenas en el Storyboard](#2-escenas-en-el-storyboard)
3. [Navegación](#3-navegación)
4. [Componentes UIKit por pantalla](#4-componentes-uikit-por-pantalla)
5. [Componentes SwiftUI por pantalla](#5-componentes-swiftui-por-pantalla)
6. [Arquitectura MVC y MVVM](#6-arquitectura-mvc-y-mvvm)
7. [Cómo leer el código](#7-cómo-leer-el-código)
8. [Flujo de la aplicación](#8-flujo-de-la-aplicación)
9. [Persistencia: UserDefaults y Firebase](#9-persistencia-userdefaults-y-firebase)
10. [Integración Firebase](#10-integración-firebase)
11. [Integración REST API — dummyjson](#11-integración-rest-api--dummyjson)
12. [Historial de cambios](#12-historial-de-cambios)

---

## 1. Cómo está organizado el proyecto

```
tecstore-manager/
├── App/                    AppDelegate, SceneDelegate, lifecycle, GoogleService-Info.plist
├── Assets.xcassets/        Imágenes, iconos y colores semánticos
├── Base.lproj/             Main.storyboard + LaunchScreen
├── Core/                   Extensiones, Theme, utilidades compartidas
├── Models/                 Structs Codable de Firestore
├── Services/               Toda la lógica de red, persistencia y helpers
├── SwiftUI/                Pantallas en SwiftUI (una carpeta por pantalla)
│   ├── Busquedas/
│   ├── Hosting/            UIHostingControllers + ProductoImageView ← nuevo
│   ├── Inicio/
│   ├── Perfil/
│   ├── Reportes/
│   └── Ventas/
└── UIKit/                  ViewControllers en UIKit (una carpeta por feature)
    ├── Auth/
    ├── Clientes/
    ├── Menu/
    └── Productos/
```

### Principios que seguimos

- **Una carpeta por pantalla/feature**. Dentro de `SwiftUI/` y `UIKit/` cada pantalla tiene su propia carpeta.
- **Un archivo por responsabilidad**. Nunca mezclamos View + ViewModel en el mismo archivo.
- **Services compartidos**. Toda lógica de red, imágenes, geocoding, etc. vive en `Services/`, no dentro de `UIKit/`.
- **Auto Layout 100 % en storyboard** para UIKit. Los VCs no crean constraints por código.
- **Navegación principal por segues manuales** en `Main.storyboard`.

---

## 2. Escenas en el Storyboard

`Main.storyboard` contiene **26 escenas**. Las de tipo `UIHostingController` envuelven vistas SwiftUI y no tienen subvistas definidas en el storyboard — su contenido se configura en código.

| Escena | Tipo | Contenido en storyboard |
|---|---|---|
| Navigation Controller (auth) | `UINavigationController` | Root → BienvenidaVC |
| **Bienvenida** | `BienvenidaViewController` | Logo (2 capas), título, subtítulo, botones Iniciar sesión / Crear cuenta, footer label. Constraints completos. |
| **Login** | `LoginViewController` | ScrollView → logo, título, subtítulo, campos correo/contraseña con error labels, botones login/registrarse, seed label. Constraints completos. |
| **Registro** | `RegistroViewController` | ScrollView → logo, título, subtítulo, campos nombre/correo/contraseña/confirmar con error labels, botones registrarse/login. Constraints completos. |
| Menu View Controller | `MenuViewController` (UITabBarController) | 5 relationship segues a los 5 NavigationControllers. |
| Navigation Controller (×5) | `UINavigationController` | Uno por cada tab: Inicio, Productos, Clientes, Ventas, Configuración. |
| **Lista Productos** | `ListaProductosViewController` | TableView + UISegmentedControl (Todo/Con stock/Sin stock) + empty label. |
| **Formulario Producto** | `FormularioProductoViewController` | ScrollView → UIImageView foto, campos nombre/categoría/precio/stock, UISwitch estado. Constraints completos en storyboard. |
| **Detalle Producto** | `DetalleProductoViewController` | UIImageView foto, nombre label, card view con InfoRows. Constraints completos en storyboard. |
| **Lista Clientes** | `ListaClientesViewController` | TableView + empty label. |
| **Formulario Cliente** | `FormularioClienteViewController` | ScrollView → campos DNI/nombres/apellidos/teléfono/correo/dirección, UISwitch estado, MKMapView. Constraints completos en storyboard. |
| **Detalle Cliente** | `DetalleClienteViewController` | Card de contacto + MKMapView. Constraints completos en storyboard. |
| **Inicio** *(SwiftUI)* | `InicioViewController` (UIHostingController) | Solo contenedor vacío. Contenido: `InicioView`. |
| **Lista Ventas** *(SwiftUI)* | `ListaVentasViewController` (UIHostingController) | Solo contenedor vacío. Contenido: `ListaVentasView`. |
| **Configuración** *(SwiftUI)* | `PerfilViewController` (UIHostingController) | Solo contenedor vacío. Contenido: `PerfilView`. |
| **Acerca De** *(SwiftUI)* | `AcercaDeViewController` (UIHostingController) | Solo contenedor vacío. Contenido: `AcercaDeView`. |
| **Registro Venta** *(SwiftUI)* | `RegistroVentaViewController` (UIHostingController) | Solo contenedor vacío. Contenido: `RegistroVentaView`. |
| **Detalle Venta** *(SwiftUI)* | `DetalleVentaViewController` (UIHostingController) | Solo contenedor vacío. Contenido: `DetalleVentaView`. |
| **Búsquedas** *(SwiftUI)* | `BusquedasViewController` (UIHostingController) | Solo contenedor vacío. Contenido: `BusquedasView`. |
| **Reportes** *(SwiftUI)* | `ReportesViewController` (UIHostingController) | Solo contenedor vacío. Contenido: `ReportesView`. |
| **Stock Bajo** *(SwiftUI)* | `StockBajoViewController` (UIHostingController) | Solo contenedor vacío. Contenido: `StockBajoView`. |

---

## 3. Navegación

### Storyboard — action segues (sin identifier)
Disparados directamente por botones o celdas en IB:

| Origen | Destino | Disparador |
|---|---|---|
| Bienvenida | Login | Botón "Iniciar sesión" |
| Bienvenida | Registro | Botón "Crear cuenta" |
| Login | Registro | Botón "Crear cuenta nueva" |
| Lista Productos | Detalle Producto | Tap en celda |
| Detalle Producto | Formulario Producto (editar) | Botón "Editar" |
| Lista Productos | Formulario Producto (nuevo) | Botón "+" nav bar |
| Lista Clientes | Detalle Cliente | Tap en celda |
| Detalle Cliente | Formulario Cliente (editar) | Botón "Editar" |
| Lista Clientes | Formulario Cliente (nuevo) | Botón "+" nav bar |

### Storyboard — segues con identifier
Disparados desde código con `performSegue(withIdentifier:)`. Necesario porque el disparador está dentro de una vista SwiftUI que no puede conectarse directamente en IB:

| Identifier | Origen | Destino | Tipo |
|---|---|---|---|
| `showAcercaDe` | PerfilViewController | AcercaDeViewController | show |
| `showBusquedas` | InicioViewController | BusquedasViewController | show |
| `showReportes` | InicioViewController | ReportesViewController | show |
| `showStockBajo` | InicioViewController | StockBajoViewController | show |
| `showNuevaVentaModal` | InicioViewController | RegistroVentaViewController | **modal** |
| `showRegistroVenta` | ListaVentasViewController | RegistroVentaViewController | show |
| `showDetalleVenta` | ListaVentasViewController | DetalleVentaViewController | show |

### Programático (necesario — sin alternativa en storyboard)
| Acción | Dónde | Por qué |
|---|---|---|
| Reemplazar root con MenuViewController post-login | `SceneDelegate.switchToMenu()` | Cambiar el root VC de la ventana no tiene equivalente en storyboard |
| Reemplazar root con BienvenidaVC post-logout | `SceneDelegate.switchToAuth()` | Ídem |

### Back navigation — siempre código
`popViewController(animated:)` en Formulario Producto, Formulario Cliente y Registro. `dismiss()` en sheets SwiftUI. Esto es estándar en UIKit/SwiftUI — no existe "segue de vuelta" en storyboard.

---

## 4. Componentes UIKit por pantalla

| Componente | Pantalla(s) |
|---|---|
| `UILabel` | Todas las pantallas UIKit |
| `UITextField` | Login, Registro, Formulario Producto, Formulario Cliente |
| `UIButton` | Bienvenida, Login, Registro |
| `UITableView` | Lista Productos, Lista Clientes |
| `UISegmentedControl` | Lista Productos (filtro Todo / Con stock / Sin stock) |
| `UISwitch` | Formulario Producto (estado activo/inactivo), Formulario Cliente (estado) |
| `UIImageView` | Bienvenida (logo), Login (logo), Registro (logo), Detalle Producto (foto), Formulario Producto (foto) |
| `UIAlertController` | Todos los VCs vía extensión `UIViewController.showAlert(...)` |
| `UINavigationController` | Root del flujo auth + los 5 nav controllers de las tabs |
| `MKMapView` | Formulario Cliente (interactivo), Detalle Cliente (solo lectura) |

**Layout de celdas (código):** `ProductoCell` y `ClienteCell` son prototype cells registradas en el storyboard (clase + reuseIdentifier), pero su layout interno (subvistas, constraints, estilos) se construye 100% en `buildUI()` — el storyboard no define ninguna subvista dentro de ellas.

---

## 5. Componentes SwiftUI por pantalla

| Componente | Pantalla(s) |
|---|---|
| `Text` | Todas las vistas SwiftUI |
| `TextField` | Búsquedas, Registro Venta |
| `Button` | Todas las vistas SwiftUI |
| `List` | Inicio (stock bajo), Búsquedas (resultados), Lista Ventas |
| `Form` | Configuración (PerfilView), Acerca De, Cambiar Contraseña |
| `Toggle` | Configuración (modo oscuro) |
| `Picker` | Búsquedas, Registro Venta |
| `DatePicker` | Búsquedas, Lista Ventas |
| `Map` | Búsquedas (mapa de clientes) |
| `.sheet` | Lista Ventas (filtro), Registro Venta (confirmación), Configuración (cambiar contraseña), Búsquedas (detalle) |
| `NavigationStack` | Cambiar Contraseña sheet, Registro Venta sheet, Búsquedas sheets |
| `AsyncImage` | `ProductoImageView` — carga imágenes desde URLs de dummyjson ← nuevo |

**Integración con UIKit:** todas las vistas SwiftUI se montan en un `UIHostingController` que actúa como contenedor UIKit dentro del `UINavigationController` de la tab correspondiente.

---

## 6. Arquitectura MVC y MVVM

### MVC — pantallas UIKit simples

Las pantallas de lista/detalle simples (`ListaProductos`, `ListaClientes`, `DetalleProducto`, `DetalleCliente`) usan MVC: el ViewController recibe eventos de la UI, llama al Service (async) y actualiza la vista. Toda llamada a Firestore o Firebase Auth se ejecuta dentro de un `Task` para no bloquear el hilo principal.

```
UIButton (tap) → ListaProductosViewController.handleRefresh()
    → Task { try await ProductoService.shared.fetchAll() }
    → tableView.reloadData()
```

Paso de datos entre VCs mediante `prepare(for:sender:)`:
```swift
// ListaClientesViewController.swift
override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let dest = segue.destination as? DetalleClienteViewController,
       let cliente = sender as? FBCliente {
        dest.cliente = cliente   // el VC destino recibe el modelo directamente
    }
}
```

### MVVM — pantallas SwiftUI

El ViewModel expone `@Published` properties; la vista se suscribe automáticamente con `@ObservedObject`. Las llamadas async al Service se ejecutan dentro de `Task` en el ViewModel, que está marcado `@MainActor`.

```
RegistroVentaView (@ObservedObject viewModel)
    → viewModel.selectedCliente = c          // mutación
    → viewModel.$cartItems (Publisher)       // SwiftUI re-renderiza
    → Task { try await VentaService.shared.register(...) }
```

Ejemplo concreto de `ListaVentasViewModel`:
```swift
@MainActor
final class ListaVentasViewModel: ObservableObject {
    @Published var ventas: [FBVenta] = []
    @Published var isLoading = false

    func load() {
        isLoading = true
        Task {
            ventas = (try? await VentaService.shared.fetchAll()) ?? []
            isLoading = false
        }
    }
}
```

`ListaVentasView` solo lee `viewModel.ventas` y llama `viewModel.load()` en `.onAppear` — sin lógica de negocio.

### MVVM — pantallas UIKit complejas

Las pantallas con formularios y validación (`FormularioProducto`, `FormularioCliente`, `Login`, `Registro`) usan MVVM. El ViewModel expone closures que el VC implementa para actualizar la UI.

```swift
// RegistroViewController.swift
private func bindViewModel() {
    viewModel.onValidationErrors = { [weak self] validation in
        self?.apply(validation: validation)
    }
    viewModel.onLoading = { [weak self] isLoading in
        self?.registerButton.isEnabled = !isLoading
        self?.registerButton.alpha = isLoading ? 0.6 : 1
    }
    viewModel.onError = { [weak self] message in
        self?.showAlert(title: "Error al registrarse", message: message)
    }
    viewModel.onSuccess = {
        (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.switchToMenu()
    }
}
```

### ViewModels existentes

| ViewModel | Vista/VC |
|---|---|
| `InicioViewModel` | `InicioView` |
| `StockBajoViewModel` | `StockBajoView` |
| `ListaVentasViewModel` | `ListaVentasView` |
| `RegistroVentaViewModel` | `RegistroVentaView` |
| `DetalleVentaViewModel` | `DetalleVentaView` |
| `PerfilViewModel` | `PerfilView` (Configuración) |
| `AcercaDeViewModel` | `AcercaDeView` |
| `ReportesViewModel` | `ReportesView` |
| `BusquedasViewModel` | `BusquedasView` |
| `FormularioProductoViewModel` | `FormularioProductoViewController` |
| `ProductoImageService` | helper de imagen del formulario producto |
| `FormularioClienteViewModel` | `FormularioClienteViewController` |
| `ClienteLocationService` | helper de geocoding del formulario cliente |
| `LoginViewModel` | `LoginViewController` |
| `RegistroViewModel` | `RegistroViewController` |

---

## 7. Cómo leer el código

### Si vas a tocar una pantalla SwiftUI
1. Abre `SwiftUI/<Feature>/`.
2. Lee primero el `*ViewModel.swift`: ahí está el estado y la lógica.
3. Luego lee el `*View.swift`: es puro layout declarativo.
4. Si la pantalla se muestra desde UIKit, busca su `UIHostingController` en `SwiftUI/Hosting/HostingControllers.swift`.

### Si vas a tocar una pantalla UIKit
1. Abre `UIKit/<Feature>/`.
2. Si la pantalla es un formulario/auth, lee primero el `*ViewModel.swift`.
3. Luego lee el `*ViewController.swift`: solo configura outlets, actions y bindings.
4. El diseño visual está en `Main.storyboard`.

### Si vas a tocar persistencia o reglas de negocio
1. Ve a `Models/` para ver los structs Codable.
2. Ve a `Services/` para ver la lógica de cada dominio.
3. `Services/FirestoreService.swift` es el wrapper genérico sobre Firestore.

### Si vas a tocar imágenes de productos
- En **UIKit**: `UIImageView.setImage(from:placeholder:)` en `Core/Extensions.swift` — detecta si el path es URL, asset local, o archivo en Documents.
- En **SwiftUI**: usar `ProductoImageView(path:categoryIcon:categoryColor:)` en `SwiftUI/Hosting/ProductoImageView.swift`.

### Convenciones de nombres
- Vistas SwiftUI: `<Nombre>View`
- ViewModels: `<Nombre>ViewModel`
- ViewControllers UIKit: `<Nombre>ViewController`
- Services: `<Dominio>Service`
- Models: `FB<Nombre>` (FB = Firebase)

---

## 8. Flujo de la aplicación

```
Lanzamiento
    └─ SceneDelegate.scene(_:willConnectTo:)
          ├─ AppStyle.configureGlobalAppearance()
          ├─ Auth.auth().currentUser?  (caché local Firebase Auth)
          │       ├─ YES → MenuViewController (UITabBarController)
          │       └─ NO  → UINavigationController → BienvenidaViewController
          └─ Task { try? await SeederService.shared.seedIfNeeded() }
                   └─ solo en primer lanzamiento (flag en UserDefaults)
                        ├─ GET dummyjson.com/products?limit=20 → Firestore /productos
                        └─ GET dummyjson.com/users?limit=13   → Firestore /clientes

Auth
    BienvenidaVC ──(segue)──► LoginVC ──(segue)──► RegistroVC
                                 │
                         viewModel.login() / viewModel.register()
                                 │
                         SceneDelegate.switchToMenu()  ←─ cross-dissolve

Menu (5 tabs)
    Inicio      → Reportes / Búsquedas / Stock Bajo / Nueva Venta (segues con id)
    Productos   → Detalle → Formulario (segues sin id)
    Clientes    → Detalle → Formulario (segues sin id)
    Ventas      → Detalle / Nuevo Registro (segues con id)
    Configuración → Acerca De (segue "showAcercaDe")

Logout
    PerfilView → NotificationCenter.post(.userDidLogout)
    SceneDelegate.handleLogout() → Auth.auth().signOut() → switchToAuth()
```

---

## 9. Persistencia: UserDefaults y Firebase

### UserDefaults
Se usa para **preferencias y estado local únicamente**:

| Key | Tipo | Uso |
|---|---|---|
| `"darkModeEnabled"` | `Bool` | Preferencia de modo oscuro. Se lee en `SceneDelegate` al lanzar y se aplica con `window.overrideUserInterfaceStyle`. |
| `"seederCompleted_v1_dummy"` | `Bool` | Guard del seeder. Evita re-llamar a dummyjson y re-insertar datos en cada lanzamiento. |

> La sesión activa ya **no se guarda en UserDefaults** — Firebase Auth mantiene su propio estado persistente en el keychain del dispositivo. `Auth.auth().currentUser` devuelve el usuario cacheado sin red.

### Firebase Auth
Gestiona registro, login y sesión. Las credenciales se almacenan en el keychain del sistema operativo.

| Operación | API |
|---|---|
| Registro | `Auth.auth().createUser(withEmail:password:)` |
| Login | `Auth.auth().signIn(withEmail:password:)` |
| Logout | `Auth.auth().signOut()` |
| Sesión activa | `Auth.auth().currentUser` (síncrono, caché local) |
| Cambio de contraseña | `user.updatePassword(to:)` después de `reauthenticate` |

### Firestore (base de datos)
Cuatro colecciones de nivel raíz. Los datos de `productos` y `clientes` se poblaron desde dummyjson en el primer lanzamiento:

| Colección | Documento | Campos clave |
|---|---|---|
| `usuarios` | `{uid}` (= Firebase Auth uid) | `nombreCompleto`, `correo`, `fotoPerfil`, `fechaRegistro` |
| `productos` | ID auto | `nombre`, `codigo`, `categoria`, `precio`, `stock`, `estado`, `fotoProducto` (URL HTTPS), `fechaRegistro` |
| `clientes` | ID auto | `dni`, `nombres`, `apellidos`, `telefono`, `correo`, `direccion`, `estado`, `ubicacion`, `fechaRegistro` |
| `ventas` | ID auto | `usuarioID`, `clienteID`, `detalles` (array), `subtotal`, `igv`, `total`, `fechaVenta` |

> **`fotoProducto` es una URL HTTPS** (thumbnail de dummyjson) en lugar del nombre de un asset local. Las capas de imagen (`setImage(from:)` en UIKit y `ProductoImageView` en SwiftUI) detectan el prefijo `http` y cargan la imagen de forma async.

**Acceso genérico via `FirestoreService`** (`Services/FirestoreService.swift`): thin wrapper con operaciones (`fetchAll`, `fetch`, `add`, `set`, `update`, `delete`) que usan el soporte Codable del SDK para serialización automática.

---

## 10. Integración Firebase

### SDK y configuración

El proyecto usa **Firebase iOS SDK** integrado via Swift Package Manager (SPM).

Paquetes importados:
- `FirebaseAuth` — autenticación
- `FirebaseFirestore` — base de datos NoSQL
- `FirebaseFirestoreSwift` — soporte Codable (serialización automática)

El archivo `GoogleService-Info.plist` apunta al proyecto Firebase **`tecstore-manager-dummy`** y debe estar incluido en el target principal. **No se commitea** (está en `.gitignore`).

La inicialización ocurre en `AppDelegate.application(_:didFinishLaunchingWithOptions:)`:
```swift
FirebaseApp.configure()
```

### Modelos Codable (`Core/FirebaseModels.swift`)

Cada entidad de Firestore tiene un struct Swift con `Codable` y `@DocumentID`:

```swift
struct FBProducto: Codable, Identifiable {
    @DocumentID var id: String?
    var codigo:        String
    var nombre:        String
    var categoria:     String
    var precio:        Double
    var stock:         Int
    var fotoProducto:  String?   // URL HTTPS cuando fue seeded desde dummyjson
    var estado:        String
    var fechaRegistro: Date
}
```

Los modelos son: `FBUsuario`, `FBProducto`, `FBCliente`, `FBVenta`, `FBUbicacion`, `FBDetalleVenta`.

### FirestoreService (`Services/FirestoreService.swift`)

Wrapper genérico tipado sobre el SDK. Todas las funciones son `async throws`:

```swift
static func fetchAll<T: Decodable>(_ collection: String, as type: T.Type) async throws -> [T]
static func fetch<T: Decodable>(_ collection: String, id: String, as type: T.Type) async throws -> T?
static func set<T: Encodable>(_ collection: String, id: String, _ value: T) async throws
static func add<T: Encodable>(_ collection: String, _ value: T) async throws -> String
static func update(_ collection: String, id: String, _ fields: [String: Any]) async throws
static func delete(_ collection: String, id: String) async throws
```

### Capa de Services (`Services/`)

| Service | Responsabilidad |
|---|---|
| `AuthService` | Registro, login, logout, currentUsuario(), cambio de contraseña |
| `ProductoService` | CRUD de productos, generación de código, filtros por categoría/stock |
| `ClienteService` | CRUD de clientes, búsqueda por DNI, filtro por estado |
| `VentaService` | Registro de ventas, cálculo de totales (subtotal + 18% IGV), consulta por rango de fechas |
| `ReporteService` | Métricas agregadas: totales, ingresos por categoría, productos top, tendencia diaria |
| `UbicacionService` | Guardar y leer coordenadas GPS del cliente (campo embebido en documento cliente) |
| `SeederService` | Seed inicial desde dummyjson REST API → Firestore (ver sección 11) |
| `ProductoImageService` | Captura/redimensiona/guarda la foto de un producto en el directorio Documents |
| `ClienteLocationService` | Geocoding/reverse-geocoding con MapKit |

### Persistencia offline

Firestore tiene **caché local habilitada por defecto**. Las escrituras se encolan localmente si no hay red y se sincronizan automáticamente cuando la conexión se restaura.

### Reglas de seguridad Firestore

Para desarrollo/académico:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```
Solo usuarios autenticados pueden leer y escribir.

---

## 11. Integración REST API — dummyjson

Esta sección documenta la diferencia clave con `tecstore-manager-firebase`.

### Qué es dummyjson

`dummyjson.com` es una API REST pública que devuelve datos de prueba realistas (productos con imágenes, usuarios con dirección y coordenadas). No requiere autenticación. Se usa **únicamente en el seed inicial** — una vez que los datos están en Firestore, la app opera igual que la versión firebase.

### Endpoints usados

| Endpoint | Uso |
|---|---|
| `GET https://dummyjson.com/products?limit=20` | 20 productos con `title`, `category`, `price`, `stock`, `thumbnail` |
| `GET https://dummyjson.com/users?limit=13` | 13 usuarios con `firstName`, `lastName`, `phone`, `email`, `address` (incluyendo coordenadas GPS) |

### Flujo de seed

```
SeederService.seed()
    ├─ clearAllCollections()                   ← limpia Firestore
    ├─ seedUsuarios()                          ← hardcodeados (Firebase Auth no soporta usuarios externos)
    ├─ seedProductos()
    │       └─ URLSession GET /products?limit=20
    │               └─ map DJProduct → FBProducto → Firestore /productos
    ├─ seedClientes()
    │       └─ URLSession GET /users?limit=13
    │               └─ map DJUser → FBCliente → Firestore /clientes
    └─ seedVentas(usuarios, productos, clientes)  ← lógica interna sin cambios
```

### Mapeo de campos

**Productos** (`DJProduct` → `FBProducto`):

| dummyjson | FBProducto | Notas |
|---|---|---|
| `id` (Int) | `codigo` | `String(format: "PROD-%03d", index + 1)` |
| `title` | `nombre` | directo |
| `category` | `categoria` | mapeado a categorías en español (ver tabla abajo) |
| `price` | `precio` | redondeado a 2 decimales |
| `stock` | `stock` | directo |
| `thumbnail` | `fotoProducto` | URL HTTPS — guardada como String en Firestore |
| — | `estado` | `"Activo"` si `stock > 0`, `"Inactivo"` si no |

**Categorías** (dummyjson → app):

| dummyjson | App |
|---|---|
| `smartphones`, `laptops`, `tablets`, `mobile-accessories`, `computer-accessories-peripherals` | Tecnología |
| `mens-shirts`, `womens-dresses`, `tops`, `womens-shoes`, `mens-shoes` | Ropa |
| `sports-accessories`, `vehicle` | Deportes |
| `home-decoration`, `furniture`, `kitchen-accessories` | Hogar |
| `groceries` | Alimentos |
| `beauty`, `fragrances`, `skincare` | Otros |
| `sunglasses` | Electrónica |
| (cualquier otro) | Otros |

**Clientes** (`DJUser` → `FBCliente`):

| dummyjson | FBCliente | Notas |
|---|---|---|
| `firstName` | `nombres` | directo |
| `lastName` | `apellidos` | directo |
| `phone` | `telefono` | directo |
| `email` | `correo` | directo |
| `address.address` | `direccion` | directo |
| `address.coordinates.lat/lng` | `ubicacion.latitud/longitud` | coordenadas reales (EE.UU.) |
| `address.address` | `ubicacion.direccionReferencia` | directo |
| — | `dni` | `String(format: "%08d", (id * 7_654_321) % 100_000_000)` — DNI determinístico sin colisión |
| — | `estado` | siempre `"Activo"` |

> **Usuarios de Firebase Auth**: permanecen hardcodeados (3 cuentas con password). dummyjson no provee passwords, por lo que no es posible crear cuentas Auth desde sus usuarios.

### Carga de imágenes con URL

El campo `fotoProducto` ahora almacena una URL HTTPS en lugar de un nombre de asset. Se actualizaron dos capas:

**UIKit — `UIImageView.setImage(from:placeholder:)` (`Core/Extensions.swift`)**:
```swift
func setImage(from path: String?, placeholder: UIImage? = nil) {
    image = placeholder
    guard let path, !path.isEmpty else { return }
    if path.hasPrefix("http") {
        guard let url = URL(string: path) else { return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data, let loaded = UIImage(data: data) else { return }
            DispatchQueue.main.async { self?.image = loaded }
        }.resume()
    } else if let asset = UIImage(named: path) {
        image = asset
    } else {
        image = UIImage.fromDocuments(named: path) ?? placeholder
    }
}
```

**SwiftUI — `ProductoImageView` (`SwiftUI/Hosting/ProductoImageView.swift`)**:
```swift
struct ProductoImageView: View {
    let path: String?
    let categoryIcon: String
    let categoryColor: Color
    // Usa AsyncImage para URLs, UIImage para assets/archivos locales.
    // Fallback al ícono de categoría si no hay imagen disponible.
}
```

Usada en `StockBajoView` y `BusquedasView` (reemplaza el bloque `UIImage(named:) ?? UIImage.fromDocuments(named:)` que existía en ambas).

---

## 12. Historial de cambios

### tecstore-manager-dummy (este proyecto)
- **Seed desde dummyjson**: `SeederService.seedProductos()` y `seedClientes()` consumen la API REST de dummyjson y persisten los datos en Firestore. Los usuarios (Firebase Auth) y las ventas siguen siendo generados internamente.
- **Imágenes de productos por URL**: `fotoProducto` almacena URLs HTTPS. `setImage(from:)` en UIKit y `ProductoImageView` en SwiftUI manejan la carga async.
- **`ProductoImageView`**: nuevo componente SwiftUI en `SwiftUI/Hosting/` que centraliza la lógica de carga (URL / asset / archivo local / fallback icono).
- **Nuevo proyecto Firebase**: `tecstore-manager-dummy` — proyecto Firebase independiente del proyecto base.
- **`seededKey`**: cambiado a `seederCompleted_v1_dummy` para forzar re-seed en el nuevo proyecto.

### Heredado de tecstore-manager-firebase
- **MVVM completo en SwiftUI**: cada pantalla SwiftUI tiene su ViewModel inyectado desde `UIHostingController`.
- **MVVM en formularios UIKit**: `FormularioProducto`, `FormularioCliente`, `Login` y `Registro` usan ViewModels.
- **Services centralizados**: todos los services viven en `Services/`.
- **Auto Layout puro en storyboard**: los constraints de UIKit están en `Main.storyboard`.
- **Navegación por segues**: unificación de transiciones con `performSegue` y segues manuales.
- **Geocoding moderno**: `MKGeocodingRequest` / `MKReverseGeocodingRequest` en lugar de `CLGeocoder`.
- **Colores semánticos**: `secondarySystemBackground` para soporte light/dark mode.
