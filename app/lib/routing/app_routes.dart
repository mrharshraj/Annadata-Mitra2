/// Named routes preserving the Stitch hierarchy:
/// splash → welcome → sign-in → location → farm → crop → shell(home…).
abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String welcome = '/welcome';
  static const String signIn = '/sign-in';
  static const String locationSetup = '/location-setup';
  static const String farmProfile = '/farm-profile';
  static const String addCrop = '/add-crop';

  // Shell branches
  static const String home = '/home';
  static const String weather = '/home/weather';
  static const String forecast = '/home/weather/forecast';
  static const String advisory = '/home/advisory';

  static const String crops = '/crops';
  static const String cropDetails = '/crops/details';
  static const String scanner = '/crops/scanner';

  static const String askAi = '/ai';
  static const String aiConversation = '/ai/conversation';

  static const String tasks = '/tasks';
  static const String taskDetails = '/tasks/details';
  static const String timeline = '/tasks/timeline';

  static const String fields = '/profile/fields';
  static const String profile = '/profile';
}
