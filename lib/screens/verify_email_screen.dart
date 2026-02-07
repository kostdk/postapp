import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:postapp/screens/home_screen.dart';
import 'package:postapp/services/snack_bar.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool isEmailVerified = false;
  bool canResendEmail = true;
  Timer? timer;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();

    final user = supabase.auth.currentUser;
    isEmailVerified = user?.emailConfirmedAt != null;

    if (!isEmailVerified) {
      sendVerificationEmail();

      timer = Timer.periodic(
        const Duration(seconds: 5), // проверяем каждые 5 секунд
        (_) => checkEmailVerified(),
      );
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> checkEmailVerified() async {
    // Обновляем данные пользователя
    await supabase.auth.refreshSession();
    final user = supabase.auth.currentUser;

    setState(() {
      isEmailVerified = user?.emailConfirmedAt != null;
    });

    if (isEmailVerified) timer?.cancel();
  }

  Future<void> sendVerificationEmail() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // В последних версиях updateUser бросает исключение при ошибке
      await supabase.auth.updateUser(
        UserAttributes(email: user.email),
      );

      // Письмо отправлено успешно
      setState(() => canResendEmail = false);
      await Future.delayed(const Duration(seconds: 5));
      setState(() => canResendEmail = true);

      if (mounted) {
        SnackBarService.showSnackBar(
          context,
          'Письмо с подтверждением отправлено на ${user.email}',
          false,
        );
      }
    } catch (e) {
      print('Ошибка отправки письма: $e');
      if (mounted) {
        SnackBarService.showSnackBar(
          context,
          'Ошибка отправки письма: $e',
          true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return isEmailVerified
        ? const HomeScreen()
        : Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              title: const Text('Подтвердите ваш e-mail'),
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Письмо отправлено на ваш e-mail',
                      style: TextStyle(fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: canResendEmail ? sendVerificationEmail : null,
                      icon: const Icon(Icons.email),
                      label: const Text('Отправить снова'),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () async {
                        timer?.cancel();
                        await supabase.auth.signOut();
                      },
                      child: const Text(
                        'Отмена',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
  }
}
