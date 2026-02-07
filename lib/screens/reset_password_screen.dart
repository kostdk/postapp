import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:postapp/services/auth_check.dart';
import 'package:postapp/services/snack_bar.dart';
import 'package:postapp/style/app_style.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController emailTextInputController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;

  @override
  void dispose() {
    emailTextInputController.dispose();
    super.dispose();
  }

  Future<void> resetPassword() async {
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final isValid = formKey.currentState!.validate();
    if (!isValid) return;

    try {
      // Отправка письма на сброс пароля
      await supabase.auth.resetPasswordForEmail(
        emailTextInputController.text.trim(),
        // redirectTo: 'https://your-app-url.com', // можно указать redirect URL
      );

      const snackBar = SnackBar(
        content: Text('Password reset e-mail sent. Check your inbox.'),
        backgroundColor: Colors.green,
      );

      scaffoldMessenger.showSnackBar(snackBar);

      // Переход на AuthCheck
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthCheck()),
      );
    } on AuthException catch (e) {
      // Ошибка от Supabase
      SnackBarService.showSnackBar(context, e.message, true);
    } catch (e) {
      SnackBarService.showSnackBar(context, 'Unexpected error: $e', true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text('Reset password', style: AppStyle.mainTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              TextFormField(
                style: AppStyle.mainContent,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                controller: emailTextInputController,
                validator: (email) =>
                    email != null && !EmailValidator.validate(email)
                        ? 'Enter correct e-mail'
                        : null,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter e-mail',
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: resetPassword,
                child: Center(
                  child: Text('Reset password', style: AppStyle.mainContent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
