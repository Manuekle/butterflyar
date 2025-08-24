# 🦋 ButterflyAR

[![Flutter](https://img.shields.io/badge/Flutter-3.19.0-blue.svg)](https://flutter.dev/)
[![Platforms](https://img.shields.io/badge/platforms-Android%20|%20iOS%20|%20Web%20|%20Windows%20|%20macOS%20|%20Linux-lightgrey.svg)](https://flutter.dev/multi-platform/desktop)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](./CONTRIBUTING.md)

Una aplicación multiplataforma para explorar mariposas en Realidad Aumentada con un diseño minimalista y soporte para dark mode.

![ButterflyAR Logo](./assets/logo.png)

## 📋 Tabla de Contenidos

- [Características](#características)
- [Capturas de Pantalla](#capturas-de-pantalla)
- [Requisitos](#requisitos)
- [Instalación](#instalación)
- [Uso](#cómo-usar)
- [Estructura del Proyecto](#estructura-del-proyecto)
- [Contribución](#contribución)
- [Licencia](#licencia)
- [Contacto](#contacto)

## ✨ Características

### 🦋 Visualización en Realidad Aumentada

- Visualiza modelos 3D realistas de mariposas en tu entorno
- Interactúa con las mariposas usando gestos táctiles
- Ajusta el tamaño y la rotación de los modelos

### 📱 Multiplataforma

- Compatible con dispositivos móviles (Android/iOS)
- Soporte para escritorio (Windows, macOS, Linux)
- Versión web accesible desde cualquier navegador moderno

### 🎨 Diseño Moderno

- Interfaz de usuario intuitiva y minimalista
- Soporte para modo oscuro/claro
- Animaciones fluidas y transiciones suaves

### 📚 Catálogo Completo

- Información detallada de cada especie
- Fotos de alta calidad
- Datos científicos y curiosidades

### 🔍 Escaneo de Códigos QR

- Escanea códigos QR para desbloquear especies especiales
- Comparte tus descubrimientos fácilmente


## 📸 Capturas de Pantalla

| Móvil | Escritorio |
|-------|------------|
| ![Vista principal en móvil](./screenshots/mobile_home.jpg) | ![Experiencia AR en escritorio](./screenshots/desktop_ar.jpg) |
| *Vista principal en móvil* | *Experiencia AR en escritorio* |


## 🚀 Requisitos

- Flutter SDK (versión 3.19.0 o superior)
- Dart SDK (versión 3.3.0 o superior)
- Para desarrollo web: Chrome 84+ o Edge 84+
- Para desarrollo de escritorio: Ver [requisitos de Flutter Desktop](https://docs.flutter.dev/desktop)


## ⚙️ Instalación

### Requisitos Previos

1. **Instala Flutter**
   - Sigue la [guía oficial de instalación](https://docs.flutter.dev/get-started/install)
   - Asegúrate de que Flutter esté en tu PATH
   - Verifica la instalación con:
     ```bash
     flutter doctor
     ```

2. **Clona el repositorio**
   ```bash
   git clone https://github.com/Manuekle/butterflyar.git
   cd butterflyar
   ```

3. **Obtén las dependencias**
   ```bash
   flutter pub get
   ```

4. **Ejecuta la aplicación**
   ```bash
   # Para web
   flutter run -d chrome --web-renderer html
   
   # Para Android
   flutter run -d <device_id>
   
   # Para iOS
   cd ios
   pod install
   cd ..
   flutter run
   
   # Para escritorio
   flutter config --enable-<platform>-desktop
   flutter run -d <platform>
   ```

## 🚀 Cómo Usar

### Dispositivos Móviles (Android/iOS)
1. **Prepara tu dispositivo**
   - Android: Activa la opción "Modo desarrollador" y "Depuración USB"
   - iOS: Conecta tu dispositivo y confía en el certificado de desarrollador

2. **Ejecuta la aplicación**
   ```bash
   # Para Android
   flutter run -d <device_id>
   
   # Para iOS
   flutter run -d <device_id>
   ```

### Navegador Web
1. **Ejecuta en modo desarrollo**
   ```bash
   flutter run -d chrome --web-renderer html --web-port 3000
   ```
   La aplicación estará disponible en `http://localhost:3000`

### Escritorio (Windows/macOS/Linux)
1. **Habilita el soporte de escritorio**
   ```bash
   flutter config --enable-<platform>-desktop
   ```

2. **Ejecuta la aplicación**
   ```bash
   flutter run -d <windows|macos|linux>
   ```

## 🛠️ Dependencias Principales

| Paquete | Versión | Propósito |
|---------|---------|-----------|
| `flutter` | ^3.19.0 | SDK principal |
| `provider` | ^6.1.1 | Gestión de estado y tema |
| `ar_flutter_plugin` | ^1.0.0 | Realidad Aumentada |
| `qr_code_scanner` | ^1.0.1 | Escaneo de códigos QR |
| `shared_preferences` | ^2.2.2 | Almacenamiento local |
| `cached_network_image` | ^3.3.1 | Caché de imágenes |
| `url_launcher` | ^6.2.2 | Abrir enlaces externos |

Para instalar todas las dependencias:

```bash
flutter pub get
```

## 🏗️ Estructura del Proyecto

```text
lib/
├── main.dart           # Punto de entrada de la aplicación
├── app/               # Configuración de la aplicación
├── models/            # Modelos de datos
├── screens/           # Pantallas principales
├── services/          # Lógica de negocio y servicios
├── utils/             # Utilidades y helpers
├── widgets/           # Componentes reutilizables
└── assets/
    ├── images/        # Imágenes estáticas
    ├── species/       # Modelos 3D y datos de mariposas
    └── translations/  # Archivos de internacionalización
```

## 🦋 Gestión de Especies

La aplicación utiliza una estructura modular para gestionar las diferentes especies de mariposas. Cada especie se define en el directorio `assets/species/`.

### Estructura de Archivos

```text
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
```

## 👥 Contribución

¡Las contribuciones son bienvenidas! Por favor, lee nuestras pautas de contribución antes de enviar un Pull Request.

1. Haz un fork del repositorio
2. Crea una rama para tu característica (`git checkout -b feature/AmazingFeature`)
3. Haz commit de tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Haz push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

### 🐛 Reportar Errores

Por favor, reporta los errores [creando un nuevo issue](https://github.com/Manuekle/butterflyar/issues) con una descripción clara del problema, pasos para reproducirlo e información de tu entorno.

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Consulta el archivo [LICENSE](LICENSE) para más información.

## 📧 Contacto

- **Manuel** - [@tu_usuario](https://github.com/Manuekle)
- **Correo electrónico**: tu@email.com
- **Sitio web**: https://tusitio.com

## 🙏 Agradecimientos

- A todos los colaboradores que han ayudado a mejorar este proyecto
- A la comunidad de Flutter por su increíble ecosistema
- A los creadores de los paquetes de código abierto utilizados en este proyecto
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
