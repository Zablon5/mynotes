import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mynotes/firebase_options.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
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
        title: const Text('Login'),
      ),
      body: FutureBuilder(
        future: Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ),
        builder: (context, snapshot) {
          switch (snapshot.connectionState){
            case ConnectionState.done:
            return Column(
            children: [
              TextField(
                controller: _email,
                enableSuggestions: false,
                autocorrect: false,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'Enter Your Email'),
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
                  
                  try{
                  final UserCredential = await FirebaseAuth.instance.
                  signInWithEmailAndPassword(
                    email: email, 
                    password: password,
                    );
                    
                  print(UserCredential);
                  }on FirebaseAuthException catch (e){
                    
                    print(e.code);
                  }
                  
                },
                child: const Text("Log-In"),
              ),
              TextButton(
                onPressed:(){
                  Navigator.of(context).pushNamedAndRemoveUntil("/register", (route) => false);
                },
                child: const Text("Not registered yet? Register Here!"),)
      
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
