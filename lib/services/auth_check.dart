import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:postapp/screens/home_screen.dart';
import 'package:postapp/screens/login_screen.dart';
import 'package:postapp/screens/verify_email_screen.dart';

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  Stream<AuthState>? _authStream;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAuthStream();
    });
  }

  void _initializeAuthStream() {
    try {
      setState(() {
        _authStream = Supabase.instance.client.auth.onAuthStateChange;
      });
    } catch (e) {
      print('Ошибка инициализации auth stream: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_authStream == null) {
      return const LoginScreen();
    }

    return StreamBuilder<AuthState>(
      stream: _authStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const LoginScreen();
        }

        final session = snapshot.data?.session;
        final user = session?.user;

        // Если есть пользователь
        if (snapshot.connectionState == ConnectionState.active) {
          if (user != null) {
            // Проверка подтверждённого email
            if (user.emailConfirmedAt == null) {
              return const VerifyEmailScreen();
            }
            return const HomeScreen();
          } else {
            // Пользователь не авторизован
            return const LoginScreen();
          }
        }

        // Пока идет загрузка состояния
        return const LoginScreen();
      },
    );
  }
}
