# Catador

Es mi diario de restaurantes. Cada vez que voy a comer a un lugar, guardo una visita con la foto de lo que pedí, lo que me gustó y lo que no (lo dicto con la voz) y la ubicación del restaurante. Cuando regreso al mismo lugar y escribo su nombre, la app me muestra lo que pedí la vez pasada y qué opiné, así no repito un platillo que no me gustó.

## Problema que resuelve

Casi siempre se me olvida qué fue lo que pedí en un restaurante, si estuvo bueno y hasta dónde quedaba. Catador junta todo en un solo lugar: foto, opinión y mapa.

## Qué hace

- **Lista de visitas** con foto, restaurante, lo que pedí y calificación.
- **Detalle de la visita** con la foto en grande, lo que pedí, lo que me gustó, lo que no, un botón para abrir Google Maps y las otras veces que fui al mismo lugar.
- **Formulario de nueva visita**:
  - Foto con la cámara o desde la galería.
  - Dictado por voz (micrófono) para "lo que me gustó" y "lo que no me gustó".
  - Ubicación GPS que se captura al guardar.
  - Sugerencias de restaurantes que ya visité y, al elegir uno, el resumen de la última vez.

## Cómo cumple la rúbrica

| Requerimiento | Dónde está |
|---|---|
| Scaffold, AppBar y Drawer | `lista_screen.dart`, `widgets/app_drawer.dart` |
| Rutas y Navigator | `app/routes.dart` (`onGenerateRoute`, `Navigator.pushNamed`) |
| Hero y transiciones | `widgets/foto_visita.dart` (Hero lista a detalle), transición propia de deslizar y desvanecer para el formulario |
| SQLite | `data/sqlite_visita_repository.dart` (guarda ruta de la foto y coordenadas) |
| try-catch y FutureBuilder | repositorio y servicios lanzan `AppException`; `lista_screen.dart` y `detalle_screen.dart` usan `FutureBuilder` |
| Cámara y galería | `services/image_service.dart` (image_picker) |
| Micrófono y dictado | `services/dictation_service.dart` (speech_to_text) |
| GPS y mapas | `services/location_service.dart` (geolocator) y `services/map_launcher.dart` (abre Google Maps con las coordenadas) |

## Arquitectura por capas

```
lib/
  main.dart                      Arranque y tema
  app/
    app_dependencies.dart        Decide qué implementación se usa de cada contrato
    routes.dart                  Rutas con nombre
  models/visita.dart             Entidad Visita
  data/
    visita_repository.dart       Contrato del repositorio
    sqlite_visita_repository.dart  Implementación con SQLite
    app_exception.dart           Error propio con mensaje para el usuario
  services/                      Un contrato y una implementación por cada gadget
  screens/                       Lista, detalle y formulario
  widgets/                       Piezas reutilizables de la interfaz
  utils/formato.dart             Formato de fechas y estrellas
```

Traté de seguir los principios SOLID:

- **Responsabilidad única:** cada clase hace una cosa. El modelo guarda datos, el repositorio guarda en SQLite, cada servicio maneja un gadget y las pantallas solo muestran la interfaz.
- **Abierto/cerrado:** para guardar en otro lado (SharedPreferences, una API) escribo otro repositorio sin tocar las pantallas.
- **Sustitución de Liskov:** cualquier implementación de un contrato se puede usar en lugar de otra.
- **Segregación de interfaces:** los contratos son chicos (`ImageService`, `LocationService`, `DictationService`, `MapLauncher`) y las pantallas solo reciben los que usan.
- **Inversión de dependencias:** las pantallas dependen de contratos abstractos y reciben las implementaciones por constructor desde `app_dependencies.dart`.

## Cómo correrlo

1. Tener Flutter y un emulador o celular Android.
2. `flutter pub get`
3. `flutter run`

Permisos que usa (ya están en el `AndroidManifest.xml`): cámara, micrófono, ubicación e internet. La primera vez que uso cada gadget, Android pide el permiso.

Nota para el emulador: el dictado necesita el micrófono virtual (en Extended controls, Microphone) y que el emulador tenga servicios de Google. La ubicación se puede cambiar en Extended controls, Location. Abrir Google Maps funciona con un enlace web, así que no necesita API key.

## Paquetes

`sqflite`, `path`, `path_provider`, `image_picker`, `speech_to_text`, `geolocator`, `url_launcher`
