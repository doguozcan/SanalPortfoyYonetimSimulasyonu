import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sanal_portfoy_yonetim_simulasyonu/constants/functions/customShowDialog.dart'
    as CSD;
import 'package:sanal_portfoy_yonetim_simulasyonu/services/database.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  var rememberValue = false;
  final TextEditingController mailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController balanceController = TextEditingController();
  bool wantedToBeInLeaderBoard = false;

  Future signUp() async {
    try {
      UserCredential result =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: mailController.text.trim(),
        password: passwordController.text.trim(),
      );
      await DatabaseService(uid: result.user!.uid).updateUserData(
          nameController.text,
          surnameController.text,
          mailController.text,
          double.parse(balanceController.text),
          wantedToBeInLeaderBoard);
      CSD.CustomShowDialog.showDialog(context,
          "User created and verification email sent to ${mailController.text.trim()}. Do not forget to check spam folder!");
    } on FirebaseAuthException catch (e) {
      CSD.CustomShowDialog.showDialog(context, e.message.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(elevation: 0),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SingleChildScrollView(
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                AnimatedTextKit(
                  animatedTexts: [
                    TypewriterAnimatedText(
                      'Sign Up!',
                      textStyle: const TextStyle(
                        fontSize: 32.0,
                        fontWeight: FontWeight.bold,
                      ),
                      speed: const Duration(milliseconds: 200),
                    ),
                  ],
                  totalRepeatCount: 4,
                  pause: const Duration(milliseconds: 1000),
                  displayFullTextOnTap: true,
                  stopPauseOnTap: true,
                ),
                const SizedBox(
                  height: 60,
                ),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) => EmailValidator.validate(value!)
                            ? null
                            : "Please enter a valid email",
                        maxLines: 1,
                        controller: mailController,
                        decoration: InputDecoration(
                          hintText: 'Enter your email',
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              validator: (value) {
                                if (value != null && value.length < 2) {
                                  return 'Please enter a valid name';
                                } else {
                                  return null;
                                }
                              },
                              maxLines: 1,
                              controller: nameController,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.person),
                                hintText: 'Your name',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Expanded(
                            child: TextFormField(
                              validator: (value) {
                                if (value != null && value.length < 2) {
                                  return 'Please enter a valid surname';
                                } else {
                                  return null;
                                }
                              },
                              maxLines: 1,
                              controller: surnameController,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.person_outlined),
                                hintText: 'Your surname',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      TextFormField(
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                        maxLines: 1,
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.key),
                          hintText: 'Enter your password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      TextFormField(
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your balance';
                          } else if (double.parse(value) < 1000) {
                            return 'Please choose a balance greated than 999';
                          }
                          return null;
                        },
                        maxLines: 1,
                        controller: balanceController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.attach_money_rounded),
                          hintText: 'Enter the balance',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      CheckboxListTile(
                        title: const Text(
                          'Do you want to be in the leaderboard?',
                          style: TextStyle(fontSize: 14),
                        ),
                        value: wantedToBeInLeaderBoard,
                        onChanged: (value) => setState(
                          () {
                            wantedToBeInLeaderBoard = !wantedToBeInLeaderBoard;
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            signUp();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.fromLTRB(40, 15, 40, 15),
                        ),
                        child: const Text(
                          'Sign up',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
