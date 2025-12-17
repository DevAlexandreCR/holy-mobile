import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('es'), Locale('en')];

  static const localizationsDelegates = [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  String get appTitle => _string('appTitle');
  String get splashPreparing => _string('splashPreparing');
  String get splashConfigError => _string('splashConfigError');
  String get splashSessionError => _string('splashSessionError');
  String get splashReady => _string('splashReady');
  String get splashLoading => _string('splashLoading');

  String get genericError => _string('genericError');
  String get networkError => _string('networkError');
  String get unexpectedVerseFormat => _string('unexpectedVerseFormat');

  String get loginTitle => _string('loginTitle');
  String get loginHeadline => _string('loginHeadline');
  String get loginSubtitle => _string('loginSubtitle');
  String get emailLabel => _string('emailLabel');
  String get passwordLabel => _string('passwordLabel');
  String get loginAction => _string('loginAction');
  String get forgotPassword => _string('forgotPassword');
  String get createAccount => _string('createAccount');
  String get welcomeBack => _string('welcomeBack');
  String get missingEmailError => _string('missingEmailError');
  String get invalidEmailError => _string('invalidEmailError');
  String get missingPasswordError => _string('missingPasswordError');
  String get shortPasswordError => _string('shortPasswordError');

  String get registerTitle => _string('registerTitle');
  String get registerHeadline => _string('registerHeadline');
  String get registerSubtitle => _string('registerSubtitle');
  String get nameLabel => _string('nameLabel');
  String get confirmPasswordLabel => _string('confirmPasswordLabel');
  String get missingNameError => _string('missingNameError');
  String get passwordMismatchError => _string('passwordMismatchError');
  String get registerAction => _string('registerAction');
  String get alreadyHaveAccount => _string('alreadyHaveAccount');
  String get accountCreated => _string('accountCreated');

  String get forgotPasswordTitle => _string('forgotPasswordTitle');
  String get forgotPasswordHeadline => _string('forgotPasswordHeadline');
  String get forgotPasswordSubtitle => _string('forgotPasswordSubtitle');
  String get sendLink => _string('sendLink');
  String get backToLogin => _string('backToLogin');
  String get instructionsSent => _string('instructionsSent');

  String get verseScreenTitle => _string('verseScreenTitle');
  String get verseOfDayTag => _string('verseOfDayTag');
  String get verseSubtitle => _string('verseSubtitle');
  String get verseSectionTitle => _string('verseSectionTitle');
  String get updateAction => _string('updateAction');
  String get shareAction => _string('shareAction');
  String get shareTooltip => _string('shareTooltip');
  String get settingsTooltip => _string('settingsTooltip');
  String get shareSubject => _string('shareSubject');
  String get verseLoadError => _string('verseLoadError');
  String get verseRequestError => _string('verseRequestError');
  String get errorRetry => _string('errorRetry');

  String get settingsTitle => _string('settingsTitle');
  String get preferencesTitle => _string('preferencesTitle');
  String get preferencesSubtitle => _string('preferencesSubtitle');
  String get bibleVersionsTitle => _string('bibleVersionsTitle');
  String get bibleVersionsSubtitle => _string('bibleVersionsSubtitle');
  String get versionsUpdateSuccess => _string('versionsUpdateSuccess');
  String get versionsUpdateError => _string('versionsUpdateError');
  String get versionsLoadError => _string('versionsLoadError');
  String get versionsEmpty => _string('versionsEmpty');

  String get authRequestFailed => _string('authRequestFailed');
  String get authUnexpectedError => _string('authUnexpectedError');
  String get authInvalidCredentials => _string('authInvalidCredentials');

  String _string(String key) {
    final langCode =
        supportedLocales.any(
          (localeOption) => localeOption.languageCode == locale.languageCode,
        )
        ? locale.languageCode
        : 'es';

    return _localizedValues[langCode]?[key] ??
        _localizedValues['es']![key] ??
        key;
  }

  static const _localizedValues = <String, Map<String, String>>{
    'es': {
      'appTitle': 'HolyVerso',
      'splashPreparing': 'Preparando tu experiencia...',
      'splashConfigError': 'Error al cargar configuración',
      'splashSessionError': 'No se pudo validar tu sesión',
      'splashReady': 'Listo para comenzar',
      'splashLoading': 'Cargando configuración...',
      'genericError': 'Ocurrió un error inesperado. Inténtalo nuevamente.',
      'networkError': 'Verifica tu conexión a internet.',
      'unexpectedVerseFormat': 'Formato de versículo inesperado.',
      'loginTitle': 'Iniciar sesión',
      'loginHeadline': 'Bienvenido de nuevo',
      'loginSubtitle': 'Ingresa para continuar con tu experiencia bíblica.',
      'emailLabel': 'Correo electrónico',
      'passwordLabel': 'Contraseña',
      'loginAction': 'Entrar',
      'forgotPassword': '¿Olvidaste tu contraseña?',
      'createAccount': 'Crear cuenta nueva',
      'welcomeBack': '¡Bienvenido de nuevo!',
      'missingEmailError': 'Ingresa tu correo',
      'invalidEmailError': 'Correo inválido',
      'missingPasswordError': 'Ingresa tu contraseña',
      'shortPasswordError': 'Debe tener al menos 6 caracteres',
      'registerTitle': 'Crear cuenta',
      'registerHeadline': 'Regístrate',
      'registerSubtitle': 'Crea tu cuenta para personalizar tus lecturas.',
      'nameLabel': 'Nombre completo',
      'confirmPasswordLabel': 'Confirmar contraseña',
      'missingNameError': 'Ingresa tu nombre',
      'passwordMismatchError': 'Las contraseñas no coinciden',
      'registerAction': 'Registrarse',
      'alreadyHaveAccount': 'Ya tengo una cuenta',
      'accountCreated': 'Cuenta creada. ¡Bienvenido!',
      'forgotPasswordTitle': 'Recuperar contraseña',
      'forgotPasswordHeadline': '¿Olvidaste tu contraseña?',
      'forgotPasswordSubtitle': 'Te enviaremos instrucciones a tu correo.',
      'sendLink': 'Enviar enlace',
      'backToLogin': 'Volver a iniciar sesión',
      'instructionsSent': 'Te enviamos instrucciones a tu correo.',
      'verseScreenTitle': 'Versículo del día',
      'verseOfDayTag': 'Versículo de hoy',
      'verseSubtitle': 'Renueva tu espíritu con la palabra diaria.',
      'verseSectionTitle': 'Palabra viva',
      'updateAction': 'Actualizar',
      'shareAction': 'Compartir',
      'shareTooltip': 'Compartir',
      'settingsTooltip': 'Configuración',
      'shareSubject': 'Versículo de hoy',
      'verseLoadError': 'No pudimos cargar el versículo de hoy.',
      'verseRequestError':
          'No pudimos cargar el versículo. Inténtalo nuevamente.',
      'errorRetry': 'Reintentar',
      'settingsTitle': 'Configuración',
      'preferencesTitle': 'Preferencias',
      'preferencesSubtitle':
          'Elige tu traducción favorita para sincronizar el versículo diario.',
      'bibleVersionsTitle': 'Versiones de la Biblia',
      'bibleVersionsSubtitle': 'Selecciona la versión que prefieras leer',
      'versionsUpdateSuccess': 'Versión actualizada.',
      'versionsUpdateError': 'No pudimos guardar tu preferencia.',
      'versionsLoadError':
          'No pudimos cargar las versiones. Inténtalo nuevamente.',
      'versionsEmpty': 'Aún no hay versiones disponibles.',
      'authRequestFailed':
          'No se pudo completar la solicitud. Inténtalo nuevamente.',
      'authUnexpectedError': 'Algo salió mal. Inténtalo nuevamente.',
      'authInvalidCredentials':
          'Correo o contraseña incorrectos. Verifica tus datos.',
    },
    'en': {
      'appTitle': 'HolyVerso',
      'splashPreparing': 'Preparing your experience...',
      'splashConfigError': 'Could not load configuration',
      'splashSessionError': 'Session could not be validated',
      'splashReady': 'Ready to start',
      'splashLoading': 'Loading configuration...',
      'genericError': 'Something went wrong. Please try again.',
      'networkError': 'Check your internet connection.',
      'unexpectedVerseFormat': 'Unexpected verse format.',
      'loginTitle': 'Sign in',
      'loginHeadline': 'Welcome back',
      'loginSubtitle': 'Sign in to continue your Bible journey.',
      'emailLabel': 'Email',
      'passwordLabel': 'Password',
      'loginAction': 'Sign in',
      'forgotPassword': 'Forgot your password?',
      'createAccount': 'Create new account',
      'welcomeBack': 'Welcome back!',
      'missingEmailError': 'Enter your email',
      'invalidEmailError': 'Invalid email',
      'missingPasswordError': 'Enter your password',
      'shortPasswordError': 'Must be at least 6 characters',
      'registerTitle': 'Create account',
      'registerHeadline': 'Sign up',
      'registerSubtitle': 'Create your account to personalize your readings.',
      'nameLabel': 'Full name',
      'confirmPasswordLabel': 'Confirm password',
      'missingNameError': 'Enter your name',
      'passwordMismatchError': 'Passwords do not match',
      'registerAction': 'Sign up',
      'alreadyHaveAccount': 'I already have an account',
      'accountCreated': 'Account created. Welcome!',
      'forgotPasswordTitle': 'Recover password',
      'forgotPasswordHeadline': 'Forgot your password?',
      'forgotPasswordSubtitle': 'We will send instructions to your email.',
      'sendLink': 'Send link',
      'backToLogin': 'Back to sign in',
      'instructionsSent': 'We sent instructions to your email.',
      'verseScreenTitle': 'Verse of the Day',
      'verseOfDayTag': 'Verse of the day',
      'verseSubtitle': 'Refresh your spirit with the daily word.',
      'verseSectionTitle': 'Living word',
      'updateAction': 'Refresh',
      'shareAction': 'Share',
      'shareTooltip': 'Share',
      'settingsTooltip': 'Settings',
      'shareSubject': 'Verse of the day',
      'verseLoadError': 'We could not load the verse of the day.',
      'verseRequestError': 'We could not load the verse. Please try again.',
      'errorRetry': 'Retry',
      'settingsTitle': 'Settings',
      'preferencesTitle': 'Preferences',
      'preferencesSubtitle':
          'Choose your favorite translation for the daily verse.',
      'bibleVersionsTitle': 'Bible versions',
      'bibleVersionsSubtitle': 'Select the version you prefer to read',
      'versionsUpdateSuccess': 'Version updated.',
      'versionsUpdateError': 'We could not save your preference.',
      'versionsLoadError': 'We could not load the versions. Please try again.',
      'versionsEmpty': 'No versions available yet.',
      'authRequestFailed': 'Request could not be completed. Please try again.',
      'authUnexpectedError': 'Something went wrong. Please try again.',
      'authInvalidCredentials':
          'Incorrect email or password. Please check your credentials.',
    },
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (supported) => supported.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
