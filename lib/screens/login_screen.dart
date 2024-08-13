import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:postapp/screens/home_screen.dart';
import 'package:postapp/screens/reset_password_screen.dart';
import 'package:postapp/screens/signup_screen.dart';
import 'package:postapp/services/snack_bar.dart';
import 'package:postapp/style/app_style.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isHiddenPassword = true;
  TextEditingController emailTextInputController = TextEditingController();
  TextEditingController passwordTextInputController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailTextInputController.dispose();
    passwordTextInputController.dispose();

    super.dispose();
  }

  void togglePasswordView() {
    setState(() {
      isHiddenPassword = !isHiddenPassword;
    });
  }

  Future<void> login() async {
    final navigator = Navigator.of(context);

    final isValid = formKey.currentState!.validate();
    if (!isValid) return;

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailTextInputController.text.trim(),
        password: passwordTextInputController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      print(e.code);

      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        SnackBarService.showSnackBar(
          context,
          'Wrong e-mail or password. Try again',
          true,
        );
        return;
      } else {
        SnackBarService.showSnackBar(
          context,
          'Unknown erroe! Try again or tell us',
          true,
        );
        return;
      }
    }

    navigator.push(MaterialPageRoute(builder: (context)=> HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text('Sign in',style:(AppStyle.mainTitle)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              TextFormField(
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                controller: emailTextInputController,
                validator: (email) =>
                    email != null && !EmailValidator.validate(email)
                        ? 'Enter valid e-mail'
                        : null,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter e-mail',
                ),
              ),
              const SizedBox(height: 30),
              TextFormField(
                autocorrect: false,
                controller: passwordTextInputController,
                obscureText: isHiddenPassword,
                validator: (value) => value != null && value.length < 6
                    ? 'Min 6 symbols'
                    : null,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: 'Enter password',
                  suffix: InkWell(
                    onTap: togglePasswordView,
                    child: Icon(
                      isHiddenPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: login,
                child: Center(child: Text('Sign in',style:(AppStyle.mainContent))),
              ),
              const SizedBox(height: 30),
              TextButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context)=> SignUpScreen())),
                child: Text(
                  'Register',
                  style:(AppStyle.mainContent)
                  ),
                ),
              
              TextButton(
                onPressed: () =>
                  navigator.push(MaterialPageRoute(builder: (context)=> ResetPasswordScreen())),
                child: Text('Reset password',style:(AppStyle.mainContent)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
