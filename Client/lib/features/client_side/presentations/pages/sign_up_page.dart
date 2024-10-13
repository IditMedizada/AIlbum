// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:my_app/features/client_side/firebase_auth_implementation/firebase_auth_services.dart';
import 'package:my_app/features/client_side/presentations/pages/login_page.dart';
import 'package:my_app/features/client_side/presentations/pages/userId.dart';
import 'package:my_app/features/client_side/presentations/widgets/BaseScreen.dart';
import 'package:my_app/features/client_side/presentations/widgets/form_container_widget.dart';
import 'package:my_app/features/client_side/presentations/pages/gallery_sync.dart';
import 'package:my_app/main.dart';
import '../../../../global/common/toast.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // Firebase authentication service
  final FirebaseAuthService auth = FirebaseAuthService();
  bool isSignUp = false;
  TextEditingController usernameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController verifyPasswordController = TextEditingController();

  @override
  void dispose() {
    // Dispose controllers when the widget is destroyed
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    verifyPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Icon
                const Center(
                  child: Image(
                    image: AssetImage('assets/icon.png'),
                    width: 150.0,
                    height: 150.0,
                  ),
                ),
                const SizedBox(height: 30),

                // Title
                const Text(
                  "Create Your Account",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 91, 122, 152)),

                ),
                const SizedBox(height: 30),

                // Username Input
                FormContainerWidget(
                  controller: usernameController,
                  hintText: "Username",
                  isPasswordField: false,
                ),
                const SizedBox(height: 15),

                // Email Input
                FormContainerWidget(
                  controller: emailController,
                  hintText: "Email",
                  isPasswordField: false,
                ),
                const SizedBox(height: 15),

                // Password Input
                FormContainerWidget(
                  controller: passwordController,
                  hintText: "Password",
                  isPasswordField: true,
                ),
                const SizedBox(height: 15),

                // Verify Password Input
                FormContainerWidget(
                  controller: verifyPasswordController,
                  hintText: "Verify Password",
                  isPasswordField: true,
                ),
                const SizedBox(height: 30),

                // Sign Up Button
                GestureDetector(
                  onTap: () {
                    signUp();// Trigger sign-up process when button is pressed
                  },
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: isSignUp
                          ? const CircularProgressIndicator(
                              color: Colors.white,// Show a loader while signing up
                            )
                          : const Text(
                              "Sign Up",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Switch to Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already have an account?",
                      style: TextStyle(color: Color.fromARGB(255, 91, 122, 152)),
                    ),
                    const SizedBox(width: 5),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginPage()),
                          (route) => false,
                        );
                      },
                      child: const Text(
                        "Login",
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Sign up logic
  void signUp() async {
    String email = emailController.text;
    String password = passwordController.text;
    String verifyPassword = verifyPasswordController.text;
    // Display error if passwords don't match
    if (password != verifyPassword) {
      showToast(message: "Passwords do not match");
      return;
    }

    setState(() {
      isSignUp = true;
    });

    User? user = await auth.signUpEmailAndPassword(email, password);
    setState(() {
      isSignUp = false;
    });

    if (user != null) {
      showToast(message: 'User successfully created');
      final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      await GallerySync().createProcessedFile(userId);
      await saveUserId(userId);
      await initializeService();
      await Future.delayed(const Duration(seconds: 1));
      // isButtonEnabledNotifier.value = false;

      // Start background service to upload photos
      FlutterBackgroundService().invoke('upload_photos', {
        "userId": userId,
      });

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    } else {
      showToast(message: "Some error occurred");
    }
  }
}


