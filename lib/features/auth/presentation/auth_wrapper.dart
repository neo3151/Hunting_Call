import 'package:flutter/material.dart';
import '../../../injection_container.dart' as di;
import '../../auth/domain/auth_repository.dart';
import 'login_screen.dart';
import '../../home/presentation/home_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  String? userId;

  @override
  void initState() {
    super.initState();
    di.sl<AuthRepository>().onAuthStateChanged.listen((user) {
      if (mounted) {
        setState(() {
          userId = user;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return const LoginScreen();
    }
    return HomeScreen(userId: userId!);
  }
}
