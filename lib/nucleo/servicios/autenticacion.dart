import 'package:firebase_auth/firebase_auth.dart';

class AuthService {

  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool get esInvitado {
    final user = _auth.currentUser;
    if (user == null) return false;
    return user.isAnonymous;
  }

  bool get estaLogueado {
    return _auth.currentUser != null;
  }

}