import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:postapp/screens/home_screen.dart';
import 'package:postapp/screens/login_screen.dart';

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Если данные есть и пользователь авторизован
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;

          if (user == null) {
            // Если пользователь не авторизован, переходим на страницу авторизации
            return const LoginScreen();
          } else {
            // Если пользователь авторизован, переходим на главную страницу
            return const HomeScreen();
          }
        }

        // Пока идет загрузка, можно показать индикатор загрузки
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}