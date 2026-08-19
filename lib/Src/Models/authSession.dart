import 'package:sistem_cormex/Src/Models/appUser.dart';

class AuthSession {
  const AuthSession({required this.user, required this.sessionToken});

  final AppUser user;
  final String sessionToken;
}
