class AuthSession {
  static bool isLoggedIn = false;
  static bool isGuest = false;
  static String? token;
  static Map<String, dynamic>? user;

  static void enterGuestMode() {
    isLoggedIn = false;
    isGuest = true;
    token = null;
    user = null;
  }

  static void enterUserMode({
    required String? authToken,
    required Map<String, dynamic>? currentUser,
  }) {
    isLoggedIn = true;
    isGuest = false;
    token = authToken;
    user = currentUser;
  }

  static void clear() {
    isLoggedIn = false;
    isGuest = false;
    token = null;
    user = null;
  }
}
