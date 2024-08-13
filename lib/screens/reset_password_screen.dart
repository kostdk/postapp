import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:postapp/services/auth_check.dart';
import 'package:postapp/services/snack_bar.dart';
import 'package:postapp/style/app_style.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  TextEditingController emailTextInputController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  
  @override
  void dispose() {
    emailTextInputController.dispose();

    super.dispose();
  }

  Future<void> resetPassword() async {
    final navigator = Navigator.of(context);
    final scaffoldMassager = ScaffoldMessenger.of(context);

    final isValid = formKey.currentState!.validate();
    if (!isValid) return;

    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: emailTextInputController.text.trim());
    } on FirebaseAuthException catch (e) {
      print(e.code);

      if (e.code == 'user-not-found') {
        SnackBarService.showSnackBar(
          context,
          'This e-mail not registered',
          true,
        );
        return;
      } else {
        SnackBarService.showSnackBar(
          context,
          'Unkown error! Try again or tell us.',
          true,
        );
        return;
      }
    }

    const snackBar = SnackBar(
      content: Text('Password changed. Check your e-mail'),
      backgroundColor: Colors.green,
    );

    scaffoldMassager.showSnackBar(snackBar);
    
    navigator.push(MaterialPageRoute(builder: (context)=> AuthCheck()));
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text('Reset password', style:(AppStyle.mainTitle)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              TextFormField(
                style:(AppStyle.mainContent),
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
                child: Center(child: Text('Reset password',style:(AppStyle.mainContent),)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
