import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:postapp/screens/home_screen.dart';
import 'package:postapp/screens/verify_email_screen.dart';

class SupabaseStream extends StatelessWidget {
  const SupabaseStream({super.key});

  @override
  Widget build(BuildContext context) {
    // Stream изменений сессии пользователя
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Что-то пошло не так!')),
          );
        }

        final session = snapshot.data?.session;
        final user = session?.user;

        if (user != null) {
          // Проверка, подтверждён ли email
          if (user.emailConfirmedAt == null) {
            return const VerifyEmailScreen();
          }
          return const HomeScreen();
        } else {
          // Если нет пользователя (не авторизован)
          return const HomeScreen();
        }
      },
    );
  }
}
