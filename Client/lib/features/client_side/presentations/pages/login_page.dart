// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:my_app/features/client_side/presentations/pages/albums.dart';
import 'package:my_app/features/client_side/presentations/pages/gallery_sync.dart';
import 'package:my_app/features/client_side/presentations/pages/sign_up_page.dart';
import 'package:my_app/features/client_side/presentations/pages/userId.dart';
import 'package:my_app/features/client_side/presentations/widgets/BaseScreen.dart';
import 'package:my_app/features/client_side/presentations/widgets/form_container_widget.dart';
import 'package:my_app/main.dart';
import '../../../../global/common/toast.dart';
import '../../firebase_auth_implementation/firebase_auth_services.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  // Indicates if the login process is ongoing
  bool isSigning = false;
  // Instance of FirebaseAuthService for authentication
  final FirebaseAuthService auth = FirebaseAuthService();
  // Controller for email input field
  TextEditingController emailController = TextEditingController();
  // Controller for password input field
  TextEditingController passwordController = TextEditingController();

  @override
  // Clean up the controllers when the widget is disposed
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Center(
                child: Image(
                  image: AssetImage('assets/icon.png'),
                  width: 150.0,
                  height: 150.0,
                ),
              ),
              const SizedBox(height: 50),
              const Text(
                "Welcome Back",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 91, 122, 152)),
              ),
              const SizedBox(height: 30),
              FormContainerWidget(
                controller: emailController,
                hintText: "Email",
                isPasswordField: false,
              ),
              const SizedBox(height: 10),
              FormContainerWidget(
                controller: passwordController,
                hintText: "Password",
                isPasswordField: true,
              ),
              const SizedBox(height: 30),
              // Login button
              GestureDetector(
                  onTap: () {
                    login();// Call login function when tapped
                  },
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      // Show a progress indicator while signing in
                      child: isSigning
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              "Login",
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
              Row(
                // Redirect to sign up page if the user does not have an account
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account?", style: TextStyle(color: Color.fromARGB(255, 91, 122, 152))),
                  const SizedBox(width: 5),
                  GestureDetector(
                    // Navigate to sign-up page and remove all previous routes
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const SignUpPage()),
                        (route) => false,
                      );
                    },
                    child: const Text(
                      "Sign Up",
                      style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Login function to authenticate the user
  void login() async {
    setState(() {
      isSigning = true;
    });
    String email = emailController.text;
    String password = passwordController.text;
    // Attempt to sign in the user using FirebaseAuthService
    User? user = await auth.signInWithEmailAndPassword(email, password);
    setState(() {
      isSigning = false;
    });
    if (user != null) {
      showToast(message: 'User successfully signed in');
      // Get the current user's UID from FirebaseAuth
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        // Save the userId locally, initialize background services, and trigger night_mode
        await saveUserId(userId);
        await initializeService();
        await Future.delayed(const Duration(seconds: 1));
        FlutterBackgroundService().invoke('night_mode', {"userId": userId});
        // Check if the user's photos have already been processed
        bool? isProcess = await GallerySync().checkProcessedStatus(userId);
        if(isProcess != null && isProcess){
          isButtonEnabledNotifier.value = true;
        }else{
          isButtonEnabledNotifier.value = false;
        }
      }

      Navigator.pushAndRemoveUntil(
          context, MaterialPageRoute(builder: (context) => const Albums()), (route) => false);
    } else {
      showToast(message: "Some error happened");
    }
  }
}