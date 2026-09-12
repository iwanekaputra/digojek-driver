class AppConfig {
  static const String appName = "DeliQ Delivery";
  static const bool isDemoMode = true;
  static const String languageDefault = "id";
  static final Map<String, AppLanguage> languagesSupported = {
    "en": AppLanguage("English"),
    "ar": AppLanguage("عربى"),
    "pt": AppLanguage("Portugal"),
    "fr": AppLanguage("Français"),
    "id": AppLanguage("Bahasa Indonesia"),
    "es": AppLanguage("Español"),
    "it": AppLanguage("italiano"),
    "tr": AppLanguage("Türk"),
    "sw": AppLanguage("Kiswahili"),
    "de": AppLanguage("Deutsch"),
    "ro": AppLanguage("Română"),
  };
}

class AppLanguage {
  final String name;
  // final Map<String, String> values;
  AppLanguage(this.name);
}
