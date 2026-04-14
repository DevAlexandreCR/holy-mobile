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
  String get connectionUnavailableMessage =>
      _string('connectionUnavailableMessage');
  String get sessionExpiredMessage => _string('sessionExpiredMessage');
  String get unableToRefreshRightNowMessage =>
      _string('unableToRefreshRightNowMessage');
  String get showingLastAvailableContentMessage =>
      _string('showingLastAvailableContentMessage');
  String get showingLastAvailableSessionMessage =>
      _string('showingLastAvailableSessionMessage');
  String get unexpectedVerseFormat => _string('unexpectedVerseFormat');
  String get unexpectedChapterFormat => _string('unexpectedChapterFormat');

  String get loginTitle => _string('loginTitle');
  String get loginHeadline => _string('loginHeadline');
  String get loginSubtitle => _string('loginSubtitle');
  String get emailLabel => _string('emailLabel');
  String get passwordLabel => _string('passwordLabel');
  String get loginAction => _string('loginAction');
  String get forgotPassword => _string('forgotPassword');
  String get createAccount => _string('createAccount');
  String get continueWithoutAccount => _string('continueWithoutAccount');
  String get guestAccessTitle => _string('guestAccessTitle');
  String get guestAccessFreeMessage => _string('guestAccessFreeMessage');
  String get guestAccessFeatureMessage => _string('guestAccessFeatureMessage');
  String get guestCtaTitle => _string('guestCtaTitle');
  String get guestCtaAction => _string('guestCtaAction');
  String get loginRequiredMessage => _string('loginRequiredMessage');
  String get deleteAccountTitle => _string('deleteAccountTitle');
  String get deleteAccountSubtitle => _string('deleteAccountSubtitle');
  String get deleteAccountConfirm => _string('deleteAccountConfirm');
  String get deleteAccountCancel => _string('deleteAccountCancel');
  String get deleteAccountSuccess => _string('deleteAccountSuccess');
  String get deleteAccountError => _string('deleteAccountError');
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
  String get resetPasswordTitle => _string('resetPasswordTitle');
  String get resetPasswordHeadline => _string('resetPasswordHeadline');
  String get resetPasswordSubtitle => _string('resetPasswordSubtitle');
  String get tokenLabel => _string('tokenLabel');
  String get missingTokenError => _string('missingTokenError');
  String get resetPasswordAction => _string('resetPasswordAction');
  String get passwordResetSuccess => _string('passwordResetSuccess');

  String get verseScreenTitle => _string('verseScreenTitle');
  String get verseOfDayTag => _string('verseOfDayTag');
  String get verseSubtitle => _string('verseSubtitle');
  String get verseSectionTitle => _string('verseSectionTitle');
  String get updateAction => _string('updateAction');
  String get shareAction => _string('shareAction');
  String get shareTooltip => _string('shareTooltip');
  String get shareOptionsTitle => _string('shareOptionsTitle');
  String get shareAsImage => _string('shareAsImage');
  String get shareAsImageDescription => _string('shareAsImageDescription');
  String get shareAsText => _string('shareAsText');
  String get shareAsTextDescription => _string('shareAsTextDescription');
  String get shareImageError => _string('shareImageError');
  String get settingsTooltip => _string('settingsTooltip');
  String get shareSubject => _string('shareSubject');
  String get verseLoadError => _string('verseLoadError');
  String get verseRequestError => _string('verseRequestError');
  String get errorRetry => _string('errorRetry');
  String get readFullChapter => _string('readFullChapter');
  String get readFullChapterSubtitle => _string('readFullChapterSubtitle');
  String get widgetPromptTitle => _string('widgetPromptTitle');
  String get widgetPromptBody => _string('widgetPromptBody');
  String get widgetPromptPrimaryAction => _string('widgetPromptPrimaryAction');
  String get widgetPromptDismissAction => _string('widgetPromptDismissAction');
  String get widgetSetupTitle => _string('widgetSetupTitle');
  String get widgetSetupAndroidSubtitle =>
      _string('widgetSetupAndroidSubtitle');
  String get widgetSetupIosSubtitle => _string('widgetSetupIosSubtitle');
  String get widgetSetupAndroidStepOne => _string('widgetSetupAndroidStepOne');
  String get widgetSetupAndroidStepTwo => _string('widgetSetupAndroidStepTwo');
  String get widgetSetupAndroidStepThree =>
      _string('widgetSetupAndroidStepThree');
  String get widgetSetupIosStepOne => _string('widgetSetupIosStepOne');
  String get widgetSetupIosStepTwo => _string('widgetSetupIosStepTwo');
  String get widgetSetupIosStepThree => _string('widgetSetupIosStepThree');
  String get widgetSetupRefreshAction => _string('widgetSetupRefreshAction');
  String get chapterReaderTitle => _string('chapterReaderTitle');
  String get chapterLoading => _string('chapterLoading');
  String get chapterLoadError => _string('chapterLoadError');
  String get chapterTextSize => _string('chapterTextSize');
  String get chapterResetText => _string('chapterResetText');
  String get chapterRequestError => _string('chapterRequestError');
  String get savedVersesTitle => _string('savedVersesTitle');
  String get viewSavedAction => _string('viewSavedAction');
  String get savedVerseToastAdded => _string('savedVerseToastAdded');
  String get savedVerseToastRemoved => _string('savedVerseToastRemoved');
  String get savedVersesEmptyTitle => _string('savedVersesEmptyTitle');
  String get savedVersesEmptySubtitle => _string('savedVersesEmptySubtitle');
  String get savedVersesEmptyCta => _string('savedVersesEmptyCta');
  String get savedLibraryVersesTab => _string('savedLibraryVersesTab');
  String get savedLibraryDevotionalsTab =>
      _string('savedLibraryDevotionalsTab');
  String get savedDevotionalsEmptyTitle =>
      _string('savedDevotionalsEmptyTitle');
  String get savedDevotionalsEmptySubtitle =>
      _string('savedDevotionalsEmptySubtitle');
  String get savedDevotionalsEmptyCta => _string('savedDevotionalsEmptyCta');
  String get savedDevotionalOpenAction => _string('savedDevotionalOpenAction');
  String get verseSearchTitle => _string('verseSearchTitle');
  String get verseSearchTooltip => _string('verseSearchTooltip');
  String get verseSearchPlaceholder => _string('verseSearchPlaceholder');
  String get verseSearchRecentTitle => _string('verseSearchRecentTitle');
  String get verseSearchEmptyTitle => _string('verseSearchEmptyTitle');
  String get verseSearchEmptySubtitle => _string('verseSearchEmptySubtitle');
  String get verseSearchNoResults => _string('verseSearchNoResults');
  String get verseSearchNoResultsSubtitle =>
      _string('verseSearchNoResultsSubtitle');
  String get verseSearchShareImageDisabled =>
      _string('verseSearchShareImageDisabled');
  String get verseSearchVoiceUnavailable =>
      _string('verseSearchVoiceUnavailable');

  String get settingsTitle => _string('settingsTitle');
  String get navHomeLabel => _string('navHomeLabel');
  String get navDevotionalsLabel => _string('navDevotionalsLabel');
  String get navSearchLabel => _string('navSearchLabel');
  String get navSavedLabel => _string('navSavedLabel');
  String get navProfileLabel => _string('navProfileLabel');
  String get navSettingsLabel => _string('navSettingsLabel');
  String get navUsersLabel => _string('navUsersLabel');
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

  String get devotionalsTitle => _string('devotionalsTitle');
  String get devotionalsAll => _string('devotionalsAll');
  String get devotionalsPublic => _string('devotionalsPublic');
  String get devotionalsMine => _string('devotionalsMine');
  String get devotionalsForYou => _string('devotionalsForYou');
  String get devotionalsFollowing => _string('devotionalsFollowing');
  String get devotionalsDrafts => _string('devotionalsDrafts');
  String get devotionalsPublished => _string('devotionalsPublished');
  String get devotionalsArchived => _string('devotionalsArchived');
  String get devotionalsStatusLabel => _string('devotionalsStatusLabel');
  String get devotionalsExpand => _string('devotionalsExpand');
  String get devotionalsCollapse => _string('devotionalsCollapse');
  String get devotionalsEmptyTitle => _string('devotionalsEmptyTitle');
  String get devotionalsEmptySubtitle => _string('devotionalsEmptySubtitle');
  String get devotionalsContentMissing => _string('devotionalsContentMissing');
  String get devotionalsLoginToComment => _string('devotionalsLoginToComment');
  String get devotionalsShareFooter => _string('devotionalsShareFooter');
  String get devotionalsLoadError => _string('devotionalsLoadError');
  String get devotionalsSaveError => _string('devotionalsSaveError');
  String get devotionalsImageUploadError =>
      _string('devotionalsImageUploadError');
  String get devotionalsModerationUnavailable =>
      _string('devotionalsModerationUnavailable');
  String get devotionalImageAlreadyAttached =>
      _string('devotionalImageAlreadyAttached');

  String get createDevotional => _string('createDevotional');
  String get editDevotional => _string('editDevotional');
  String get devotionalTitleLabel => _string('devotionalTitleLabel');
  String get devotionalTitleHint => _string('devotionalTitleHint');
  String get devotionalContentLabel => _string('devotionalContentLabel');
  String get devotionalContentHint => _string('devotionalContentHint');
  String get devotionalEditorFullscreenTitle =>
      _string('devotionalEditorFullscreenTitle');
  String get devotionalEditorDone => _string('devotionalEditorDone');
  String get devotionalHideKeyboard => _string('devotionalHideKeyboard');
  String get devotionalEditorTapToEdit => _string('devotionalEditorTapToEdit');
  String get coverImage => _string('coverImage');
  String get devotionalSelectCover => _string('devotionalSelectCover');
  String get devotionalChangeCover => _string('devotionalChangeCover');
  String get devotionalCoverAdjustHint => _string('devotionalCoverAdjustHint');
  String get devotionalCoverCenter => _string('devotionalCoverCenter');
  String get primaryVerseReferences => _string('primaryVerseReferences');
  String get addVerseReference => _string('addVerseReference');
  String get primaryVerseReference => _string('primaryVerseReference');
  String get devotionalReferenceHint => _string('devotionalReferenceHint');
  String get devotionalBookLabel => _string('devotionalBookLabel');
  String get devotionalChapterLabel => _string('devotionalChapterLabel');
  String get devotionalVerseStartLabel => _string('devotionalVerseStartLabel');
  String get devotionalVerseEndLabel => _string('devotionalVerseEndLabel');
  String get devotionalEmojiLabel => _string('devotionalEmojiLabel');
  String get saveDraft => _string('saveDraft');
  String get preview => _string('preview');
  String get publish => _string('publish');
  String get devotionalPublished => _string('devotionalPublished');
  String get devotionalSaved => _string('devotionalSaved');
  String get devotionalTitleRequired => _string('devotionalTitleRequired');
  String get devotionalPrimaryReferenceRequired =>
      _string('devotionalPrimaryReferenceRequired');
  String get devotionalPublishBlocked => _string('devotionalPublishBlocked');
  String get devotionalImageRejected => _string('devotionalImageRejected');
  String get devotionalImageModerationInProgress =>
      _string('devotionalImageModerationInProgress');
  String get devotionalPublishingAction =>
      _string('devotionalPublishingAction');
  String get devotionalArchivingAction => _string('devotionalArchivingAction');
  String get devotionalPublishingFeedback =>
      _string('devotionalPublishingFeedback');
  String get devotionalArchivingFeedback =>
      _string('devotionalArchivingFeedback');
  String get devotionalPublishedMovedMessage =>
      _string('devotionalPublishedMovedMessage');
  String get devotionalArchivedMovedMessage =>
      _string('devotionalArchivedMovedMessage');
  String get devotionalPublishHelperNeedsMoreReflection =>
      _string('devotionalPublishHelperNeedsMoreReflection');
  String get devotionalPublishNeedsMoreReflection =>
      _string('devotionalPublishNeedsMoreReflection');
  String get devotionalPublishError => _string('devotionalPublishError');
  String get devotionalFeedSavedToast => _string('devotionalFeedSavedToast');
  String get devotionalFeedFollowingInline =>
      _string('devotionalFeedFollowingInline');
  String get devotionalFeedSignalSavedByOthers =>
      _string('devotionalFeedSignalSavedByOthers');
  String get devotionalFeedSignalHighCompletion =>
      _string('devotionalFeedSignalHighCompletion');
  String get devotionalFeedSignalHighShare =>
      _string('devotionalFeedSignalHighShare');
  String get devotionalFeedSignalFollowedAuthor =>
      _string('devotionalFeedSignalFollowedAuthor');
  String get devotionalFeedSignalFeatured =>
      _string('devotionalFeedSignalFeatured');
  String get devotionalFeedBadgeTrending =>
      _string('devotionalFeedBadgeTrending');
  String get devotionalFeedBadgeRecommended =>
      _string('devotionalFeedBadgeRecommended');
  String get devotionalFeedOpenCta => _string('devotionalFeedOpenCta');
  String get devotionalFeedRitualTitle => _string('devotionalFeedRitualTitle');
  String get devotionalFeedCompletedToday =>
      _string('devotionalFeedCompletedToday');
  String get devotionalFeedPendingToday =>
      _string('devotionalFeedPendingToday');
  String get devotionalFeedCompletedMessage =>
      _string('devotionalFeedCompletedMessage');
  String get devotionalFeedPendingMessage =>
      _string('devotionalFeedPendingMessage');
  String get devotionalFeedDailyFeaturedLabel =>
      _string('devotionalFeedDailyFeaturedLabel');
  String get devotionalFeedReadTimeLabel =>
      _string('devotionalFeedReadTimeLabel');
  String get devotionalPublishModerationInProgress =>
      _string('devotionalPublishModerationInProgress');
  String get devotionalPublishModerationHelper =>
      _string('devotionalPublishModerationHelper');
  String get devotionalDetailTitle => _string('devotionalDetailTitle');
  String get devotionalSave => _string('devotionalSave');
  String get devotionalOpenDetail => _string('devotionalOpenDetail');
  String get devotionalArchiveAction => _string('devotionalArchiveAction');
  String get devotionalCommentsEmpty => _string('devotionalCommentsEmpty');
  String get devotionalCommentsEmptyTitle =>
      _string('devotionalCommentsEmptyTitle');
  String get devotionalCommentsEmptySubtitle =>
      _string('devotionalCommentsEmptySubtitle');
  String get devotionalMinutesShort => _string('devotionalMinutesShort');
  String get devotionalModerationClear => _string('devotionalModerationClear');
  String get devotionalModerationUnderReview =>
      _string('devotionalModerationUnderReview');
  String get devotionalModerationRestricted =>
      _string('devotionalModerationRestricted');
  String get devotionalReportAction => _string('devotionalReportAction');
  String get devotionalReportTitle => _string('devotionalReportTitle');
  String get devotionalReportDetailsHint =>
      _string('devotionalReportDetailsHint');
  String get devotionalReportSuccess => _string('devotionalReportSuccess');
  String get devotionalReportInappropriate =>
      _string('devotionalReportInappropriate');
  String get devotionalReportOffensive => _string('devotionalReportOffensive');
  String get devotionalReportSexual => _string('devotionalReportSexual');
  String get devotionalReportViolence => _string('devotionalReportViolence');
  String get devotionalReportSpam => _string('devotionalReportSpam');
  String get devotionalReportImage => _string('devotionalReportImage');
  String get devotionalReportMisleading =>
      _string('devotionalReportMisleading');
  String get devotionalReportOther => _string('devotionalReportOther');
  String get devotionalReflectionPrompt =>
      _string('devotionalReflectionPrompt');
  String get devotionalsFeedEmptyTitle => _string('devotionalsFeedEmptyTitle');
  String get devotionalsFeedEmptySubtitle =>
      _string('devotionalsFeedEmptySubtitle');
  String get devotionalsFollowingEmptyTitle =>
      _string('devotionalsFollowingEmptyTitle');
  String get devotionalsFollowingEmptySubtitle =>
      _string('devotionalsFollowingEmptySubtitle');
  String get devotionalsFollowingBadge => _string('devotionalsFollowingBadge');
  String get devotionalsMyEmptyTitle => _string('devotionalsMyEmptyTitle');
  String get devotionalsMyEmptySubtitle =>
      _string('devotionalsMyEmptySubtitle');
  String get likesLabel => _string('likesLabel');
  String get commentsLabel => _string('commentsLabel');
  String get viewsLabel => _string('viewsLabel');
  String get shareDevotional => _string('shareDevotional');
  String get writeComment => _string('writeComment');
  String get cancelAction => _string('cancelAction');
  String get saveAction => _string('saveAction');
  String get savedAction => _string('savedAction');
  String get creatorProfileTitle => _string('creatorProfileTitle');
  String get creatorProfileEdit => _string('creatorProfileEdit');
  String get creatorProfileFollowers => _string('creatorProfileFollowers');
  String get creatorProfileFollowing => _string('creatorProfileFollowing');
  String get creatorProfilePublished => _string('creatorProfilePublished');
  String get creatorProfileDevotionalsSection =>
      _string('creatorProfileDevotionalsSection');
  String get creatorProfileEmpty => _string('creatorProfileEmpty');
  String get creatorProfileFollow => _string('creatorProfileFollow');
  String get creatorProfileUnfollow => _string('creatorProfileUnfollow');
  String get creatorProfileFollowError => _string('creatorProfileFollowError');
  String get creatorProfileLoadError => _string('creatorProfileLoadError');
  String get creatorProfileSaveError => _string('creatorProfileSaveError');
  String get creatorProfileEditTitle => _string('creatorProfileEditTitle');
  String get creatorProfileChangeAvatar =>
      _string('creatorProfileChangeAvatar');
  String get creatorProfileRemoveAvatar =>
      _string('creatorProfileRemoveAvatar');
  String get creatorProfileSaving => _string('creatorProfileSaving');
  String get creatorProfileAvatarFallback =>
      _string('creatorProfileAvatarFallback');
  String get creatorProfileEditFootnote =>
      _string('creatorProfileEditFootnote');
  String get creatorHandleLabel => _string('creatorHandleLabel');
  String get creatorHandleHint => _string('creatorHandleHint');
  String get creatorHandleTaken => _string('creatorHandleTaken');
  String get creatorHandleInvalid => _string('creatorHandleInvalid');
  String get creatorBioLabel => _string('creatorBioLabel');
  String get creatorBioHint => _string('creatorBioHint');
  String get creatorAvatarRejected => _string('creatorAvatarRejected');

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
      'connectionUnavailableMessage':
          'No hay conexión disponible en este momento.',
      'sessionExpiredMessage':
          'Tu sesión venció. Inicia sesión nuevamente para continuar.',
      'unableToRefreshRightNowMessage':
          'No pudimos actualizar la información en este momento.',
      'showingLastAvailableContentMessage':
          'Te mostramos el último contenido disponible.',
      'showingLastAvailableSessionMessage':
          'Te mostramos tu última sesión disponible mientras se restablece la conexión.',
      'unexpectedVerseFormat': 'Formato de versículo inesperado.',
      'unexpectedChapterFormat': 'Formato de capítulo inesperado.',
      'loginTitle': 'Iniciar sesión',
      'loginHeadline': 'Bienvenido de nuevo',
      'loginSubtitle': 'Ingresa para continuar con tu experiencia bíblica.',
      'emailLabel': 'Correo electrónico',
      'passwordLabel': 'Contraseña',
      'loginAction': 'Entrar',
      'forgotPassword': '¿Olvidaste tu contraseña?',
      'createAccount': 'Crear cuenta nueva',
      'continueWithoutAccount': 'Continuar sin cuenta',
      'guestAccessTitle': 'Explora como invitado',
      'guestAccessFreeMessage':
          'La app es completamente gratis y siempre lo será.',
      'guestAccessFeatureMessage':
          'Para compartir, guardar, cambiar versión y configurar el widget necesitas una cuenta.',
      'guestCtaTitle': 'Desbloquea todas las funciones',
      'guestCtaAction': 'Crear cuenta gratis',
      'loginRequiredMessage': 'Inicia sesión para continuar.',
      'deleteAccountTitle': 'Eliminar cuenta',
      'deleteAccountSubtitle':
          'Esta acción elimina tu cuenta y tus datos guardados. No se puede deshacer.',
      'deleteAccountConfirm': 'Eliminar cuenta',
      'deleteAccountCancel': 'Cancelar',
      'deleteAccountSuccess': 'Cuenta eliminada correctamente.',
      'deleteAccountError':
          'No pudimos eliminar tu cuenta. Inténtalo nuevamente.',
      'welcomeBack': '¡Bienvenido de nuevo!',
      'missingEmailError': 'Ingresa tu correo',
      'invalidEmailError': 'Correo inválido',
      'missingPasswordError': 'Ingresa tu contraseña',
      'shortPasswordError': 'Debe tener al menos 8 caracteres',
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
      'resetPasswordTitle': 'Restablecer contraseña',
      'resetPasswordHeadline': 'Crea una nueva contraseña',
      'resetPasswordSubtitle':
          'Ingresa el código que recibiste y elige tu nueva contraseña.',
      'tokenLabel': 'Código de recuperación',
      'missingTokenError': 'Ingresa el código de recuperación',
      'resetPasswordAction': 'Actualizar contraseña',
      'passwordResetSuccess':
          'Tu contraseña fue actualizada. Inicia sesión con la nueva.',
      'verseScreenTitle': 'Versículo del día',
      'verseOfDayTag': 'Versículo de hoy',
      'verseSubtitle': 'Renueva tu espíritu con la palabra diaria.',
      'verseSectionTitle': 'Palabra viva',
      'updateAction': 'Actualizar',
      'shareAction': 'Compartir',
      'shareTooltip': 'Compartir',
      'shareOptionsTitle': 'Compartir versículo',
      'shareAsImage': 'Compartir como imagen',
      'shareAsImageDescription': 'Crea una imagen hermosa del versículo',
      'shareAsText': 'Compartir como texto',
      'shareAsTextDescription': 'Comparte el texto del versículo',
      'shareImageError': 'No se pudo generar la imagen. Inténtalo nuevamente.',
      'settingsTooltip': 'Configuración',
      'shareSubject': 'Versículo de hoy',
      'verseLoadError': 'No pudimos cargar el versículo de hoy.',
      'verseRequestError':
          'No pudimos cargar el versículo. Inténtalo nuevamente.',
      'readFullChapter': 'Leer capítulo completo',
      'readFullChapterSubtitle': 'Abre el capítulo con controles de lectura',
      'widgetPromptTitle': 'Lleva este versículo a tu pantalla de inicio',
      'widgetPromptBody':
          'Agrega el widget de HolyVerso para volver a encontrar la palabra de hoy sin abrir la app.',
      'widgetPromptPrimaryAction': 'Cómo agregarlo',
      'widgetPromptDismissAction': 'Recordármelo en 7 días',
      'widgetSetupTitle': 'Agrega el widget de HolyVerso',
      'widgetSetupAndroidSubtitle':
          'Sigue estos pasos para tener el versículo del día en tu pantalla de inicio.',
      'widgetSetupIosSubtitle':
          'Sigue estos pasos para tener el versículo del día en tu iPhone.',
      'widgetSetupAndroidStepOne':
          'Mantén presionada un área vacía de tu pantalla de inicio.',
      'widgetSetupAndroidStepTwo': 'Toca Widgets y busca HolyVerso.',
      'widgetSetupAndroidStepThree':
          'Arrastra el widget a la pantalla y suéltalo donde prefieras.',
      'widgetSetupIosStepOne':
          'Mantén presionada la pantalla de inicio y toca Editar pantalla de inicio.',
      'widgetSetupIosStepTwo': 'Toca el botón + y busca HolyVerso.',
      'widgetSetupIosStepThree': 'Elige el widget y toca Agregar widget.',
      'widgetSetupRefreshAction': 'Ya lo agregué',
      'chapterReaderTitle': 'Capítulo completo',
      'chapterLoading': 'Cargando capítulo...',
      'chapterLoadError': 'No pudimos cargar el capítulo completo.',
      'chapterTextSize': 'Tamaño del texto',
      'chapterResetText': 'Restablecer',
      'chapterRequestError':
          'No pudimos cargar el capítulo. Inténtalo nuevamente.',
      'savedVersesTitle': 'Versículos guardados',
      'viewSavedAction': 'Ver guardados',
      'savedVerseToastAdded': 'Guardado en tus versículos',
      'savedVerseToastRemoved': 'Eliminado de guardados',
      'savedVersesEmptyTitle': 'Aún no tienes versículos guardados',
      'savedVersesEmptySubtitle':
          'Guarda tus versículos favoritos para releerlos y compartirlos.',
      'savedVersesEmptyCta': 'Descubrir versículo diario',
      'savedLibraryVersesTab': 'Versículos',
      'savedLibraryDevotionalsTab': 'Devocionales',
      'savedDevotionalsEmptyTitle': 'Aún no tienes devocionales guardados',
      'savedDevotionalsEmptySubtitle':
          'Guarda los devocionales que quieras releer con calma más tarde.',
      'savedDevotionalsEmptyCta': 'Ver devocionales',
      'savedDevotionalOpenAction': 'Abrir devocional',
      'verseSearchTitle': 'Buscar versículos',
      'verseSearchTooltip': 'Buscar versículos',
      'verseSearchPlaceholder': 'Busca un versículo o pasaje',
      'verseSearchRecentTitle': 'Búsquedas recientes',
      'verseSearchEmptyTitle': 'Busca por referencia',
      'verseSearchEmptySubtitle':
          'Escribe algo como "Juan 3:16" o "Salmos 23".',
      'verseSearchNoResults': 'Sin resultados',
      'verseSearchNoResultsSubtitle':
          'No encontramos coincidencias para tu búsqueda.',
      'verseSearchShareImageDisabled':
          'Este pasaje es muy largo para compartirlo como imagen.',
      'verseSearchVoiceUnavailable':
          'La búsqueda por voz estará disponible pronto.',
      'errorRetry': 'Reintentar',
      'settingsTitle': 'Configuración',
      'navHomeLabel': 'Palabra',
      'navDevotionalsLabel': 'Devocionales',
      'navSearchLabel': 'Búsqueda',
      'navSavedLabel': 'Guardados',
      'navProfileLabel': 'Perfil',
      'navSettingsLabel': 'Ajustes',
      'navUsersLabel': 'Usuarios',
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
      'devotionalsTitle': 'Devocionales',
      'devotionalsAll': 'Todos',
      'devotionalsPublic': 'Público',
      'devotionalsMine': 'Mis devocionales',
      'devotionalsForYou': 'Para ti',
      'devotionalsFollowing': 'Siguiendo',
      'devotionalsDrafts': 'Borradores',
      'devotionalsPublished': 'Publicados',
      'devotionalsArchived': 'Archivados',
      'devotionalsStatusLabel': 'Estado',
      'devotionalsExpand': 'Leer completo',
      'devotionalsCollapse': 'Mostrar menos',
      'devotionalsEmptyTitle': 'Aún no hay devocionales',
      'devotionalsEmptySubtitle':
          'Muy pronto encontrarás reflexiones y devocionales para tu día.',
      'devotionalsContentMissing': 'Este devocional aún no tiene contenido.',
      'devotionalsLoginToComment':
          'Inicia sesión para comentar y participar en la comunidad.',
      'devotionalsShareFooter': 'Comparte este devocional con alguien.',
      'devotionalsLoadError': 'No pudimos cargar el devocional.',
      'devotionalsSaveError': 'No pudimos guardar el devocional.',
      'devotionalsImageUploadError':
          'No pudimos subir la imagen. Inténtalo nuevamente.',
      'devotionalsModerationUnavailable':
          'La revisión de contenido no está disponible en este momento. Inténtalo de nuevo.',
      'devotionalImageAlreadyAttached':
          'Esta imagen ya está asociada a otro borrador. Vuelve a abrir el devocional e inténtalo de nuevo.',
      'createDevotional': 'Crear devocional',
      'editDevotional': 'Editar devocional',
      'devotionalTitleLabel': 'Título del devocional',
      'devotionalTitleHint': 'Ej. Un nuevo comienzo',
      'devotionalContentLabel': 'Contenido',
      'devotionalContentHint': 'Escribe aquí tu reflexión...',
      'devotionalEditorFullscreenTitle': 'Editor',
      'devotionalEditorDone': 'Listo',
      'devotionalHideKeyboard': 'Ocultar teclado',
      'devotionalEditorTapToEdit': 'Toca para editar en pantalla completa',
      'coverImage': 'Imagen de portada',
      'devotionalSelectCover': 'Seleccionar imagen',
      'devotionalChangeCover': 'Cambiar imagen',
      'devotionalCoverAdjustHint': 'Arrastra la imagen para centrarla mejor.',
      'devotionalCoverCenter': 'Centrar',
      'primaryVerseReferences': 'Referencias bíblicas principales',
      'addVerseReference': 'Agregar referencia',
      'primaryVerseReference': 'Referencia principal',
      'devotionalReferenceHint':
          'Agrega al menos una referencia bíblica principal.',
      'devotionalBookLabel': 'Libro',
      'devotionalChapterLabel': 'Capítulo',
      'devotionalVerseStartLabel': 'Verso inicial',
      'devotionalVerseEndLabel': 'Verso final (opcional)',
      'devotionalEmojiLabel': 'Insertar emoji',
      'saveDraft': 'Guardar borrador',
      'preview': 'Vista previa',
      'publish': 'Publicar',
      'devotionalPublished': 'Devocional publicado exitosamente.',
      'devotionalSaved': 'Devocional guardado.',
      'devotionalTitleRequired': 'El título es obligatorio.',
      'devotionalPrimaryReferenceRequired':
          'Agrega al menos una referencia principal.',
      'devotionalPublishBlocked':
          'No pudimos publicar el devocional por una revisión de contenido.',
      'devotionalImageRejected':
          'La imagen fue rechazada. Puedes continuar y publicar solo texto.',
      'devotionalImageModerationInProgress': 'Revisando imagen...',
      'devotionalPublishingAction': 'Publicando...',
      'devotionalArchivingAction': 'Archivando...',
      'devotionalPublishingFeedback':
          'Estamos publicando tu devocional y actualizando su estado.',
      'devotionalArchivingFeedback':
          'Estamos archivando tu devocional y actualizando la lista.',
      'devotionalPublishedMovedMessage':
          'Devocional publicado. Ahora lo encuentras en Publicados.',
      'devotionalArchivedMovedMessage':
          'Devocional archivado. Ahora lo encuentras en Archivados.',
      'devotionalPublishHelperNeedsMoreReflection':
          'Para publicarlo, desarrolla un poco más la reflexión. Necesitas al menos 45 palabras y 3 oraciones o 2 párrafos con contenido.',
      'devotionalPublishNeedsMoreReflection':
          'Aún no está listo para publicar. Desarrolla un poco más la reflexión: necesitas al menos 45 palabras y 3 oraciones o 2 párrafos con contenido.',
      'devotionalPublishError': 'No pudimos publicar el devocional.',
      'devotionalFeedSavedToast': 'Guardado para volver luego',
      'devotionalFeedFollowingInline': 'Lo sigues',
      'devotionalFeedSignalSavedByOthers': 'Muchos lo están guardando',
      'devotionalFeedSignalHighCompletion': 'Se está leyendo hasta el final',
      'devotionalFeedSignalHighShare': 'Se está compartiendo',
      'devotionalFeedSignalFollowedAuthor': 'Viene de alguien que sigues',
      'devotionalFeedSignalFeatured': 'Destacado en HolyVerso',
      'devotionalFeedBadgeTrending': 'En tendencia',
      'devotionalFeedBadgeRecommended': 'Recomendado',
      'devotionalFeedOpenCta': 'Esto es para ti',
      'devotionalFeedRitualTitle': 'Tu ritual de hoy',
      'devotionalFeedCompletedToday': 'Completado hoy',
      'devotionalFeedPendingToday': 'Pendiente hoy',
      'devotionalFeedCompletedMessage':
          'Ya marcaste tu lectura del día. Si quieres, sigue explorando.',
      'devotionalFeedPendingMessage':
          'Haz una lectura completa hoy para mantener viva tu racha.',
      'devotionalFeedDailyFeaturedLabel': 'Devocional de hoy',
      'devotionalFeedReadTimeLabel': 'Tiempo estimado',
      'devotionalPublishModerationInProgress':
          'Revisando tu devocional antes de publicarlo...',
      'devotionalPublishModerationHelper':
          'Esto puede tardar unos segundos. No cierres esta pantalla.',
      'devotionalDetailTitle': 'Detalle del devocional',
      'devotionalSave': 'Guardar',
      'devotionalOpenDetail': 'Leer completo',
      'devotionalArchiveAction': 'Archivar',
      'devotionalCommentsEmpty': 'Todavía no hay comentarios.',
      'devotionalCommentsEmptyTitle': 'Sé el primero en comentar',
      'devotionalCommentsEmptySubtitle': 'Comparte tu reflexión',
      'devotionalMinutesShort': 'min',
      'devotionalModerationClear': 'Visible',
      'devotionalModerationUnderReview': 'En revisión',
      'devotionalModerationRestricted': 'Restringido',
      'devotionalReportAction': 'Reportar',
      'devotionalReportTitle': 'Reportar devocional',
      'devotionalReportDetailsHint': 'Cuéntanos un poco más (opcional)',
      'devotionalReportSuccess': 'Tu reporte fue enviado.',
      'devotionalReportInappropriate': 'Contenido inapropiado',
      'devotionalReportOffensive': 'Ofensivo',
      'devotionalReportSexual': 'Contenido sexual',
      'devotionalReportViolence': 'Violencia',
      'devotionalReportSpam': 'Spam',
      'devotionalReportImage': 'Imagen inapropiada',
      'devotionalReportMisleading': 'Contenido engañoso',
      'devotionalReportOther': 'Otro motivo',
      'devotionalReflectionPrompt': 'Tómate un momento para reflexionar',
      'devotionalsFeedEmptyTitle': 'Todavía no hay devocionales en el feed',
      'devotionalsFeedEmptySubtitle':
          'Cuando la comunidad publique nuevos devocionales, aparecerán aquí.',
      'devotionalsFollowingEmptyTitle': 'Aún no sigues a creadores cristianos',
      'devotionalsFollowingEmptySubtitle':
          'Sigue a alguien desde un devocional para ver aquí sus publicaciones recientes.',
      'devotionalsFollowingBadge': 'Siguiendo',
      'devotionalsMyEmptyTitle': 'Aún no tienes devocionales',
      'devotionalsMyEmptySubtitle':
          'Crea tu primer devocional y compártelo con la comunidad.',
      'likesLabel': 'Me gusta',
      'commentsLabel': 'Comentarios',
      'viewsLabel': 'Vistas',
      'shareDevotional': 'Compartir',
      'writeComment': 'Escribe un comentario...',
      'cancelAction': 'Cancelar',
      'saveAction': 'Guardar',
      'savedAction': 'Guardado',
      'creatorProfileTitle': 'Perfil',
      'creatorProfileEdit': 'Editar perfil',
      'creatorProfileFollowers': 'Seguidores',
      'creatorProfileFollowing': 'Siguiendo',
      'creatorProfilePublished': 'Publicados',
      'creatorProfileDevotionalsSection': 'Devocionales públicos',
      'creatorProfileEmpty':
          'Este perfil todavía no tiene devocionales públicos visibles.',
      'creatorProfileFollow': 'Seguir',
      'creatorProfileUnfollow': 'Dejar de seguir',
      'creatorProfileFollowError':
          'No pudimos actualizar el seguimiento en este momento.',
      'creatorProfileLoadError': 'No pudimos cargar este perfil.',
      'creatorProfileSaveError': 'No pudimos guardar tu perfil.',
      'creatorProfileEditTitle': 'Editar perfil',
      'creatorProfileChangeAvatar': 'Cambiar foto',
      'creatorProfileRemoveAvatar': 'Quitar foto',
      'creatorProfileSaving': 'Guardando...',
      'creatorProfileAvatarFallback': 'Perfil',
      'creatorProfileEditFootnote':
          'Tu camino es único; tu perfil refleja tu jornada.',
      'creatorHandleLabel': 'Usuario público',
      'creatorHandleHint': 'Ej. luz_para_hoy',
      'creatorHandleTaken': 'Ese usuario ya está en uso.',
      'creatorHandleInvalid':
          'Usa entre 3 y 30 caracteres con letras, números, punto o guion bajo.',
      'creatorBioLabel': 'Biografía corta',
      'creatorBioHint': 'Cuéntale a la comunidad quién eres en pocas palabras.',
      'creatorAvatarRejected':
          'La imagen no fue aprobada. Guardamos los demás cambios.',
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
      'connectionUnavailableMessage': 'No connection is available right now.',
      'sessionExpiredMessage':
          'Your session expired. Please sign in again to continue.',
      'unableToRefreshRightNowMessage':
          'We could not refresh the information right now.',
      'showingLastAvailableContentMessage':
          'Showing the last available content.',
      'showingLastAvailableSessionMessage':
          'Showing your last available session while the connection comes back.',
      'unexpectedVerseFormat': 'Unexpected verse format.',
      'unexpectedChapterFormat': 'Unexpected chapter format.',
      'loginTitle': 'Sign in',
      'loginHeadline': 'Welcome back',
      'loginSubtitle': 'Sign in to continue your Bible journey.',
      'emailLabel': 'Email',
      'passwordLabel': 'Password',
      'loginAction': 'Sign in',
      'forgotPassword': 'Forgot your password?',
      'createAccount': 'Create new account',
      'continueWithoutAccount': 'Continue without account',
      'guestAccessTitle': 'Explore as a guest',
      'guestAccessFreeMessage':
          'The app is completely free and always will be.',
      'guestAccessFeatureMessage':
          'To share, save, change versions, and set up the widget you need an account.',
      'guestCtaTitle': 'Unlock all features',
      'guestCtaAction': 'Create free account',
      'loginRequiredMessage': 'Please sign in to continue.',
      'deleteAccountTitle': 'Delete account',
      'deleteAccountSubtitle':
          'This action deletes your account and saved data. It cannot be undone.',
      'deleteAccountConfirm': 'Delete account',
      'deleteAccountCancel': 'Cancel',
      'deleteAccountSuccess': 'Account deleted successfully.',
      'deleteAccountError':
          'We could not delete your account. Please try again.',
      'welcomeBack': 'Welcome back!',
      'missingEmailError': 'Enter your email',
      'invalidEmailError': 'Invalid email',
      'missingPasswordError': 'Enter your password',
      'shortPasswordError': 'Must be at least 8 characters',
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
      'resetPasswordTitle': 'Reset password',
      'resetPasswordHeadline': 'Create a new password',
      'resetPasswordSubtitle':
          'Enter the code you received and choose your new password.',
      'tokenLabel': 'Recovery code',
      'missingTokenError': 'Enter the recovery code',
      'resetPasswordAction': 'Update password',
      'passwordResetSuccess':
          'Your password was updated. Sign in with the new one.',
      'verseScreenTitle': 'Verse of the Day',
      'verseOfDayTag': 'Verse of the day',
      'verseSubtitle': 'Refresh your spirit with the daily word.',
      'verseSectionTitle': 'Living word',
      'updateAction': 'Refresh',
      'shareAction': 'Share',
      'shareTooltip': 'Share',
      'shareOptionsTitle': 'Share verse',
      'shareAsImage': 'Share as image',
      'shareAsImageDescription': 'Create a beautiful image of the verse',
      'shareAsText': 'Share as text',
      'shareAsTextDescription': 'Share the verse text',
      'shareImageError': 'Could not generate the image. Please try again.',
      'settingsTooltip': 'Settings',
      'shareSubject': 'Verse of the day',
      'verseLoadError': 'We could not load the verse of the day.',
      'verseRequestError': 'We could not load the verse. Please try again.',
      'readFullChapter': 'Read full chapter',
      'readFullChapterSubtitle': 'Open the full chapter with reading controls',
      'widgetPromptTitle': 'Bring this verse to your home screen',
      'widgetPromptBody':
          'Add the HolyVerso widget so today’s word is one glance away without opening the app.',
      'widgetPromptPrimaryAction': 'How to add it',
      'widgetPromptDismissAction': 'Remind me in 7 days',
      'widgetSetupTitle': 'Add the HolyVerso widget',
      'widgetSetupAndroidSubtitle':
          'Follow these steps to keep the verse of the day on your home screen.',
      'widgetSetupIosSubtitle':
          'Follow these steps to keep the verse of the day on your iPhone.',
      'widgetSetupAndroidStepOne':
          'Press and hold an empty area on your home screen.',
      'widgetSetupAndroidStepTwo': 'Tap Widgets and look for HolyVerso.',
      'widgetSetupAndroidStepThree':
          'Drag the widget to the screen and drop it where you want.',
      'widgetSetupIosStepOne':
          'Press and hold the home screen, then tap Edit Home Screen.',
      'widgetSetupIosStepTwo': 'Tap the + button and search for HolyVerso.',
      'widgetSetupIosStepThree': 'Choose the widget and tap Add Widget.',
      'widgetSetupRefreshAction': 'I added it',
      'chapterReaderTitle': 'Full chapter',
      'chapterLoading': 'Loading chapter...',
      'chapterLoadError': 'We could not load the full chapter.',
      'chapterTextSize': 'Text size',
      'chapterResetText': 'Reset',
      'chapterRequestError': 'We could not load the chapter. Please try again.',
      'savedVersesTitle': 'Saved verses',
      'viewSavedAction': 'View saved',
      'savedVerseToastAdded': 'Saved to your verses',
      'savedVerseToastRemoved': 'Removed from saved',
      'savedVersesEmptyTitle': 'You have no saved verses yet',
      'savedVersesEmptySubtitle':
          'Save your favorite verses to read and share later.',
      'savedVersesEmptyCta': 'See verse of the day',
      'savedLibraryVersesTab': 'Verses',
      'savedLibraryDevotionalsTab': 'Devotionals',
      'savedDevotionalsEmptyTitle': 'You have no saved devotionals yet',
      'savedDevotionalsEmptySubtitle':
          'Save the devotionals you want to revisit when you need them most.',
      'savedDevotionalsEmptyCta': 'Browse devotionals',
      'savedDevotionalOpenAction': 'Open devotional',
      'verseSearchTitle': 'Search verses',
      'verseSearchTooltip': 'Search verses',
      'verseSearchPlaceholder': 'Search a verse or passage',
      'verseSearchRecentTitle': 'Recent searches',
      'verseSearchEmptyTitle': 'Search by reference',
      'verseSearchEmptySubtitle':
          'Try something like "John 3:16" or "Psalm 23".',
      'verseSearchNoResults': 'No results',
      'verseSearchNoResultsSubtitle':
          'We could not find matches for your search.',
      'verseSearchShareImageDisabled':
          'This passage is too long to share as an image.',
      'verseSearchVoiceUnavailable': 'Voice search is coming soon.',
      'errorRetry': 'Retry',
      'settingsTitle': 'Settings',
      'navHomeLabel': 'Word',
      'navDevotionalsLabel': 'Devotionals',
      'navSearchLabel': 'Search',
      'navSavedLabel': 'Saved',
      'navProfileLabel': 'Profile',
      'navSettingsLabel': 'Settings',
      'navUsersLabel': 'Users',
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
      'devotionalsTitle': 'Devotionals',
      'devotionalsAll': 'All',
      'devotionalsPublic': 'Public',
      'devotionalsMine': 'My devotionals',
      'devotionalsForYou': 'For You',
      'devotionalsFollowing': 'Following',
      'devotionalsDrafts': 'Drafts',
      'devotionalsPublished': 'Published',
      'devotionalsArchived': 'Archived',
      'devotionalsStatusLabel': 'Status',
      'devotionalsExpand': 'Read full',
      'devotionalsCollapse': 'Show less',
      'devotionalsEmptyTitle': 'No devotionals yet',
      'devotionalsEmptySubtitle':
          'Soon you will find reflections and devotionals for your day.',
      'devotionalsContentMissing': 'This devotional has no content yet.',
      'devotionalsLoginToComment': 'Sign in to comment and join the community.',
      'devotionalsShareFooter': 'Share this devotional with someone.',
      'devotionalsLoadError': 'We could not load the devotional.',
      'devotionalsSaveError': 'We could not save the devotional.',
      'devotionalsImageUploadError':
          'We could not upload the image. Please try again.',
      'devotionalsModerationUnavailable':
          'Content review is unavailable right now. Please try again.',
      'devotionalImageAlreadyAttached':
          'This image is already attached to another draft. Reopen the devotional and try again.',
      'createDevotional': 'Create devotional',
      'editDevotional': 'Edit devotional',
      'devotionalTitleLabel': 'Devotional title',
      'devotionalTitleHint': 'e.g. A fresh start',
      'devotionalContentLabel': 'Content',
      'devotionalContentHint': 'Write your reflection here...',
      'devotionalEditorFullscreenTitle': 'Editor',
      'devotionalEditorDone': 'Done',
      'devotionalHideKeyboard': 'Hide keyboard',
      'devotionalEditorTapToEdit': 'Tap to edit in full screen',
      'coverImage': 'Cover image',
      'devotionalSelectCover': 'Select image',
      'devotionalChangeCover': 'Change image',
      'devotionalCoverAdjustHint': 'Drag the image to frame it better.',
      'devotionalCoverCenter': 'Center',
      'primaryVerseReferences': 'Primary Bible references',
      'addVerseReference': 'Add reference',
      'primaryVerseReference': 'Primary reference',
      'devotionalReferenceHint': 'Add at least one primary reference.',
      'devotionalBookLabel': 'Book',
      'devotionalChapterLabel': 'Chapter',
      'devotionalVerseStartLabel': 'Starting verse',
      'devotionalVerseEndLabel': 'Ending verse (optional)',
      'devotionalEmojiLabel': 'Insert emoji',
      'saveDraft': 'Save draft',
      'preview': 'Preview',
      'publish': 'Publish',
      'devotionalPublished': 'Devotional published successfully.',
      'devotionalSaved': 'Devotional saved.',
      'devotionalTitleRequired': 'Title is required.',
      'devotionalPrimaryReferenceRequired':
          'Add at least one primary reference.',
      'devotionalPublishBlocked':
          'We could not publish the devotional due to content review.',
      'devotionalImageRejected':
          'The image was rejected. You can continue and publish text only.',
      'devotionalImageModerationInProgress': 'Reviewing image...',
      'devotionalPublishingAction': 'Publishing...',
      'devotionalArchivingAction': 'Archiving...',
      'devotionalPublishingFeedback':
          'We are publishing your devotional and updating its status.',
      'devotionalArchivingFeedback':
          'We are archiving your devotional and updating the list.',
      'devotionalPublishedMovedMessage':
          'Devotional published. You can now find it in Published.',
      'devotionalArchivedMovedMessage':
          'Devotional archived. You can now find it in Archived.',
      'devotionalPublishHelperNeedsMoreReflection':
          'To publish it, develop the reflection a bit more. You need at least 45 words and 3 sentences or 2 paragraphs with substance.',
      'devotionalPublishNeedsMoreReflection':
          'This devotional is not ready to publish yet. Develop the reflection a bit more: you need at least 45 words and 3 sentences or 2 paragraphs with substance.',
      'devotionalPublishError': 'We could not publish the devotional.',
      'devotionalFeedSavedToast': 'Saved for later',
      'devotionalFeedFollowingInline': 'You follow them',
      'devotionalFeedSignalSavedByOthers': 'Many people are saving it',
      'devotionalFeedSignalHighCompletion': 'People are reading it to the end',
      'devotionalFeedSignalHighShare': 'People are sharing it',
      'devotionalFeedSignalFollowedAuthor': 'It comes from someone you follow',
      'devotionalFeedSignalFeatured': 'Featured in HolyVerso',
      'devotionalFeedBadgeTrending': 'Trending',
      'devotionalFeedBadgeRecommended': 'Recommended',
      'devotionalFeedOpenCta': 'This is for you',
      'devotionalFeedRitualTitle': 'Your ritual today',
      'devotionalFeedCompletedToday': 'Completed today',
      'devotionalFeedPendingToday': 'Pending today',
      'devotionalFeedCompletedMessage':
          'You already marked today’s reading. Keep exploring if you want.',
      'devotionalFeedPendingMessage':
          'Complete a reading today to keep your streak alive.',
      'devotionalFeedDailyFeaturedLabel': 'Today’s devotional',
      'devotionalFeedReadTimeLabel': 'Estimated time',
      'devotionalPublishModerationInProgress':
          'Reviewing your devotional before publishing...',
      'devotionalPublishModerationHelper':
          'This can take a few seconds. Do not close this screen.',
      'devotionalDetailTitle': 'Devotional detail',
      'devotionalSave': 'Save',
      'devotionalOpenDetail': 'Read full',
      'devotionalArchiveAction': 'Archive',
      'devotionalCommentsEmpty': 'There are no comments yet.',
      'devotionalCommentsEmptyTitle': 'Be the first to comment',
      'devotionalCommentsEmptySubtitle': 'Share your reflection',
      'devotionalMinutesShort': 'min',
      'devotionalModerationClear': 'Visible',
      'devotionalModerationUnderReview': 'Under review',
      'devotionalModerationRestricted': 'Restricted',
      'devotionalReportAction': 'Report',
      'devotionalReportTitle': 'Report devotional',
      'devotionalReportDetailsHint': 'Tell us more (optional)',
      'devotionalReportSuccess': 'Your report was submitted.',
      'devotionalReportInappropriate': 'Inappropriate content',
      'devotionalReportOffensive': 'Offensive',
      'devotionalReportSexual': 'Sexual content',
      'devotionalReportViolence': 'Violence',
      'devotionalReportSpam': 'Spam',
      'devotionalReportImage': 'Inappropriate image',
      'devotionalReportMisleading': 'Misleading content',
      'devotionalReportOther': 'Other',
      'devotionalReflectionPrompt': 'Take a moment to reflect',
      'devotionalsFeedEmptyTitle': 'There are no devotionals in the feed yet',
      'devotionalsFeedEmptySubtitle':
          'When the community publishes new devotionals, they will appear here.',
      'devotionalsFollowingEmptyTitle':
          'You are not following any creators yet',
      'devotionalsFollowingEmptySubtitle':
          'Follow someone from a devotional to see their recent posts here.',
      'devotionalsFollowingBadge': 'Following',
      'devotionalsMyEmptyTitle': 'You do not have devotionals yet',
      'devotionalsMyEmptySubtitle':
          'Create your first devotional and share it with the community.',
      'likesLabel': 'Likes',
      'commentsLabel': 'Comments',
      'viewsLabel': 'Views',
      'shareDevotional': 'Share',
      'writeComment': 'Write a comment...',
      'cancelAction': 'Cancel',
      'saveAction': 'Save',
      'savedAction': 'Saved',
      'creatorProfileTitle': 'Profile',
      'creatorProfileEdit': 'Edit profile',
      'creatorProfileFollowers': 'Followers',
      'creatorProfileFollowing': 'Following',
      'creatorProfilePublished': 'Published',
      'creatorProfileDevotionalsSection': 'Public devotionals',
      'creatorProfileEmpty':
          'This profile does not have visible public devotionals yet.',
      'creatorProfileFollow': 'Follow',
      'creatorProfileUnfollow': 'Unfollow',
      'creatorProfileFollowError': 'We could not update the follow state.',
      'creatorProfileLoadError': 'We could not load this profile.',
      'creatorProfileSaveError': 'We could not save your profile.',
      'creatorProfileEditTitle': 'Edit profile',
      'creatorProfileChangeAvatar': 'Change photo',
      'creatorProfileRemoveAvatar': 'Remove photo',
      'creatorProfileSaving': 'Saving...',
      'creatorProfileAvatarFallback': 'Profile',
      'creatorProfileEditFootnote':
          'Your path is unique; your profile reflects your journey.',
      'creatorHandleLabel': 'Public handle',
      'creatorHandleHint': 'e.g. light_for_today',
      'creatorHandleTaken': 'That handle is already taken.',
      'creatorHandleInvalid':
          'Use 3 to 30 characters with letters, numbers, periods, or underscores.',
      'creatorBioLabel': 'Short bio',
      'creatorBioHint': 'Tell the community who you are in a few words.',
      'creatorAvatarRejected':
          'The image was not approved. We still saved the other changes.',
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
