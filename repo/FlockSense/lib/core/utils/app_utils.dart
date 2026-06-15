class AppUtils {
  AppUtils._();

  static bool isStringEmpty(String? value) {
    return value == null || value.trim().isEmpty;
  }
}
