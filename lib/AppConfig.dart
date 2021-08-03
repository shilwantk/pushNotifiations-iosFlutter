class AppConfig {
  static const APP_ID = '7da0598b2479ac782ca31c6d418c22bd';

  static bool isValidEmail(String emailId) {
    return RegExp(
            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(emailId);
  }
}
