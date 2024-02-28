import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mynotes/constants/routes.dart';
// Remove the unused import directive
// import 'package:mynotes/constants/routes.dart';
import 'package:mynotes/firebase_options.dart';
import 'package:mynotes/utilities/show_error_dialog.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  late final TextEditingController _email;
  late final TextEditingController _password;

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
      ),
      body: FutureBuilder(
        future: Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              return Column(
                children: [
                  TextField(
                    controller: _email,
                    enableSuggestions: false,
                    autocorrect: false,
                    keyboardType: TextInputType.emailAddress,
                    decoration:
                        const InputDecoration(hintText: 'Enter Your Email'),
                  ),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration:
                        const InputDecoration(hintText: "Enter Your Password"),
                  ),
                  TextButton(
                    onPressed: () async {
                      final email = _email.text;
                      final password = _email.text;
                      try {
                        await FirebaseAuth.instance
                            .createUserWithEmailAndPassword(
                          email: email,
                          password: password,
                        );
                        final user = FirebaseAuth.instance.currentUser;
                        await user?.sendEmailVerification();
                        Navigator.of(context)
                            .pushNamed(Routes.verifyEmailRoute);
                      } on FirebaseAuthException catch (e) {
                        final error = e.toString();

                        if (error.contains("weak-password")) {
                          await showErrorDialog(
                            context,
                            "Weak Password",
                          );
                        } else if (error.contains('email-already-in-use')) {
                          await showErrorDialog(
                            context,
                            'Email is Already in use',
                          );
                        } else if (error.contains('invalid-email')) {
                          await showErrorDialog(
                            context,
                            'This is an invalid email address',
                          );
                        } else {
                          await showErrorDialog(
                            context,
                            "Error:${e.code}",
                          );
                        }
                      }
                    },
                    child: const Text('Register'),
                  ),
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                            Routes.loginRoute, (route) => false);
                      },
                      child: const Text("Already registered? Login here!"))
                ],
              );
            default:
              return const Text("Loading...");
          }
        },
      ),
    );
  }
}
