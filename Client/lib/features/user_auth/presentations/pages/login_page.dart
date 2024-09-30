// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:my_app/features/user_auth/presentations/pages/albums.dart';
import 'package:my_app/features/user_auth/presentations/pages/sign_up_page.dart';
import 'package:my_app/features/user_auth/presentations/widgets/form_container_widget.dart';
import 'package:my_app/main.dart';
import '../../../../global/common/toast.dart';
import '../../firebase_auth_implementation/firebase_auth_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget{
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  bool isSigning = false;
  final FirebaseAuthService auth = FirebaseAuthService();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
  @override
Widget build(BuildContext context) {
  return Scaffold(
    body: Container(
      // Set the background image here
      decoration: const BoxDecoration(
        image: DecorationImage(
                image: AssetImage('assets/backgroud.jpg'), 
          fit: BoxFit.cover, 
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon in the center
              const Center(
                child: Image(
                  image: AssetImage('assets/icon.png'),
                  width: 150.0,  // Adjust the size as needed
                  height: 150.0,
                ),
              ),
              const SizedBox(height: 50,), // Adjust the height for padding
              const Text(
                "Welcome Back",
                style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30,),
              FormContainerWidget(
                controller: emailController,
                hintText: "Email",
                isPasswordField: false,
              ),
              const SizedBox(height: 10,),
              FormContainerWidget(
                controller: passwordController,
                hintText: "Password",
                isPasswordField: true,
              ),
              const SizedBox(height: 30,),
              GestureDetector(
                onTap: login,
                child: Container(
                  width: double.infinity,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: isSigning
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Login",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 20,),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account?"),
                  const SizedBox(width: 5,),
                  GestureDetector(
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
    ),
  );
}


    void login() async{
    setState(() {
      isSigning = true;
    });
    String email = emailController.text;
    String password = passwordController.text;

    User? user = await auth.signInWithEmailAndPassword(email, password);
    setState(() {
      isSigning = false;
    });
    if (user != null){
      showToast(message: 'User is successfuly sign in');
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if(userId != null ){ 
         await saveUserId(userId);

    // Check if the service is already running before starting it
    final serviceStatus = await service.isRunning();
    if (!serviceStatus) {
      try {
        service.startService();
      } catch (e) {
        print("Error starting service: $e");
        showToast(message: "Failed to start background service.");
      }
    } else {
      print("Service is already running.");
    }
            // Start the background service to upload photos
        FlutterBackgroundService().invoke('night_mode', {
        "userId": userId,
        });
      }
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=> const Albums()),(route)=>false);
    }else{
     showToast(message:"Some error happend");
    }
    
  }

  // Save user ID
Future<void> saveUserId(String userId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('userId', userId);
}

// Retrieve user ID
Future<String?> getUserId() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('userId');
}
}
