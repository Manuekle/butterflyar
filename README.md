# 🦋 ButterflyAR

Aplicación Flutter multiplataforma (Android, iOS, Web, Windows, macOS y Linux) para explorar mariposas en Realidad Aumentada con un diseño minimalista y soporte para dark mode.

## 📱 Características

- Visualización de mariposas en Realidad Aumentada
- Soporte para múltiples plataformas
- Interfaz intuitiva y fácil de usar
- Modo oscuro
- Integración con códigos QR
- Catálogo de especies de mariposas

## 🚀 Instalación Rápida

1. **Instala Flutter** ([Guía oficial](https://docs.flutter.dev/get-started/install))

2. Clona el repositorio y accede al directorio:

   ```bash
   git clone https://github.com/Manuekle/butterflyar.git
   cd butterflyar
   ```

3. Instala las dependencias:

   ```bash
   flutter pub get
   ```

## ▶️ Cómo Ejecutar la Aplicación

### Android

1. Conecta un dispositivo o inicia un emulador
2. Ejecuta:

   ```bash
   flutter run -d android
   ```

### iOS

1. Requiere Mac con Xcode instalado
2. Conecta un dispositivo iOS o inicia el simulador
3. Ejecuta:

   ```bash
   flutter run -d ios
   ```

4. Si es la primera vez, configura tu cuenta de desarrollador en Xcode

---

## 🛠️ Dependencias Principales

- `flutter` - SDK principal
- `provider` - Gestión de estado y tema
- `ar_flutter_plugin` - Integración con Realidad Aumentada
- `qr_code_scanner` - Escaneo de códigos QR
- `shared_preferences` - Almacenamiento local de preferencias

Todas las dependencias están configuradas en `pubspec.yaml`. Para actualizarlas:

```bash
flutter pub get
```

## 🦋 Gestión de Especies

La aplicación utiliza una estructura modular para gestionar las diferentes especies de mariposas. Cada especie se define en el directorio `assets/species/`.

### Estructura de Archivos

```
butterflyar/
├── assets/
│   ├── species/
│   │   ├── monarca/
│   │   │   ├── metadata.json
│   │   │   ├── model.glb
│   │   │   └── preview.png
│   │   └── ...
```

### metadata.json

Cada especie debe tener un archivo `metadata.json` con la siguiente estructura:

```json
{
  "name": "Nombre Común",
  "scientificName": "Nombre Científico",
  "description": "Descripción detallada de la especie...",
  "habitat": "Descripción del hábitat...",
  "conservationStatus": "Estado de conservación...",
  "model": "species/nombre_especie/model.glb",
  "previewImage": "species/nombre_especie/preview.png"
}
```

### Ejemplo de `metadata.json`

```json
{
  "name": "Mariposa Monarca",
  "scientificName": "Danaus plexippus",
  "imageAsset": "assets/images/monarca.png",
  "modelAsset": "assets/models/mariposa.glb"
}
```

### ¿Cómo agregar una mariposa?

1. Crea una carpeta dentro de `species/` con el nombre de la mariposa (ejemplo: `species/morpho/`).
2. Dentro, crea el archivo `metadata.json` como el ejemplo de arriba.
3. Coloca la imagen en `assets/images/` y el modelo `.glb` en `assets/models/`.
4. ¡Listo! La app los detectará automáticamente.

---

## 🟦 Integración QR por área

Puedes asociar cada área del sendero a una especie usando códigos QR. Así, el usuario escanea el QR en el área y la app muestra directamente la mariposa correspondiente en AR.

### ¿Cómo funciona?

- Imprime un QR para cada área, codificando el nombre o ID de la especie (ejemplo: `monarca`, `morpho`, `azulreal`).
- El usuario escanea el QR desde la app.
- La app detecta el código y carga automáticamente la experiencia AR de la mariposa asociada.

### ¿Cómo implementarlo en la app?

1. Agrega un botón "Escanear QR" en la pantalla principal o de selección.
2. Al escanear, busca la especie cuyo nombre coincida con el QR y navega directo a la experiencia AR.
3. Puedes generar QRs fácilmente en línea (por ejemplo, [https://www.qr-code-generator.com/](https://www.qr-code-generator.com/)).

### Ejemplo de flujo QR

1. El QR de la zona 1 contiene el texto: `monarca`.
2. El usuario escanea el QR.
3. La app busca la especie `monarca` y muestra la mariposa en RA.

---

## 📁 Estructura del Proyecto

```
butterflyar/
├── android/           # Configuración específica de Android
├── ios/               # Configuración específica de iOS
├── lib/               # Código fuente de la aplicación
│   ├── models/        # Modelos de datos
│   ├── screens/       # Pantallas de la aplicación
│   ├── services/      # Servicios y lógica de negocio
│   ├── utils/         # Utilidades y helpers
│   ├── widgets/       # Widgets reutilizables
│   └── main.dart      # Punto de entrada de la aplicación
├── assets/            # Recursos estáticos
│   ├── species/       # Modelos 3D y metadatos de especies
│   └── images/        # Imágenes de la interfaz de usuario
├── test/              # Pruebas unitarias y de widget
└── pubspec.yaml       # Configuración de dependencias
```

---

## ❓ Troubleshooting y Consejos

- Si no ves el modelo en RA:
  - Verifica permisos de cámara.
  - El modelo `.glb` debe estar bien exportado y referenciado.
  - Usa dispositivos compatibles con ARCore (Android) o ARKit (iOS).
- Para agregar más mariposas, repite el flujo de assets y modelo en el código.
- Mantén los modelos optimizados para evitar caídas de rendimiento.

---

## 📚 Recursos Útiles

- [Documentación Flutter](https://docs.flutter.dev/)
- [ar_flutter_plugin](https://pub.dev/packages/ar_flutter_plugin)
- [Optimización de modelos glTF](https://github.com/KhronosGroup/glTF-Tutorials)

---
