# HolyVerso (holy-mobile)

Aplicación Flutter que muestra el “Versículo del día”, permite elegir la versión bíblica y sincroniza el verso con widgets nativos en iOS y Android.

## Requisitos
- Flutter 3.19+ y Dart 3.
- Toolchain para iOS (Xcode) y/o Android (Android SDK + emulador/dispositivo).

## Configuración de backend
- El `baseApiUrl` se define en `lib/core/config/app_config.dart` (método `AppConfig.load()`).
- Ajusta el valor a la URL del backend (ej. `https://api.tu-dominio.com`). En el futuro puede moverse a `--dart-define`, flavors o archivos `.env`.

## Ejecutar
- Instalar dependencias: `flutter pub get`.
- Correr en emulador/dispositivo: `flutter run -d <device-id>`.
- Habilitar null-safety y análisis estándar: `flutter analyze` antes de abrir PR.

## Arquitectura y stack
- Estado: Riverpod (`ProviderScope` en `main.dart`).
- Ruteo: GoRouter (`app_router.dart`).
- Red: Dio con inyección de token y timeout en `api_client.dart`.
- Capas: `data/` (clients/repos), `domain/` (entidades), `presentation/` (screens/state).
- Temas: `lib/core/theme/app_theme.dart` define light/dark con paleta cálida (dorado/teal) y tipografía Manrope.
- i18n: `lib/core/l10n/app_localizations.dart` centraliza las cadenas (es predeterminado, en como base secundaria). `MaterialApp` ya declara `localizationsDelegates`, `supportedLocales` y `locale: es`.

## Widgets nativos
- Flutter guarda el verso en almacenamiento compartido vía `WidgetSyncService` → `WidgetVerseStorage` → `MethodChannel` `bible_widget/shared_verse`.
- iOS: App Group (ej. `group.biblewidget.app`) con clave `widgetVerse`; `AppDelegate.swift` escribe el JSON recibido por canal y dispara `WidgetCenter.shared.reloadAllTimelines()` cuando Flutter llama `refreshWidgets`. El stub de WidgetKit está en `ios/WidgetVerseExtension/WidgetVerseWidget.swift` (placeholder amistoso + timeline cada ~12h); habilita el App Group tanto en Runner como en la extensión.
- Android: SharedPreferences (`bible_widget_prefs`/`widgetVerse`), `BibleWidgetProvider` lee y refresca widgets; `refreshWidgets` envía broadcast de actualización.

## Funcionalidades Principales
- ✅ Autenticación de usuarios (registro, login, recuperación de contraseña)
- ✅ Versículo del día personalizado por versión bíblica
- ✅ Widgets nativos para iOS (WidgetKit) y Android (AppWidget)
- ✅ Selección de versiones de la Biblia
- ✅ **Compartir versículos como imágenes hermosas** 🆕
  - Generación automática de imágenes con diseño profesional
  - Optimizadas para redes sociales (1080x1920px)
  - Opción de compartir como texto o imagen
  - Ver documentación: `../docs/front/10-verse-as-image-implementation.md`

## Pruebas
- Unit y widget tests en `test/`.
- Casos clave: selección de versión (VersionsController), mapeo `/verse/today` a `VerseOfTheDay`/`WidgetVerse`, render básico de `VerseOfTheDayScreen`.
- Ejecutar todo: `flutter test`.
