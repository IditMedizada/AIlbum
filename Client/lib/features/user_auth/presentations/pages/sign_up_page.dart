import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:my_app/features/user_auth/firebase_auth_implementation/firebase_auth_services.dart';
import 'package:my_app/features/user_auth/presentations/pages/login_page.dart';
import 'package:my_app/features/user_auth/presentations/widgets/form_container_widget.dart';
import 'package:my_app/main.dart';

import '../../../../global/common/toast.dart';

class SignUpPage extends StatefulWidget{
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final FirebaseAuthService auth = FirebaseAuthService();
  bool isSignUp = false;
  TextEditingController usernameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    usernameController.dispose();
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
          const Text("Create your account",style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),),
          const SizedBox(height: 30,),
          FormContainerWidget(
            controller: usernameController,
            hintText: "Username",
            isPasswordField: false,
          ),
          const SizedBox(height: 10,),
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
            onTap: (){
              signUp();
            },
            child:Container(
            width: double.infinity,
            height: 45,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(10),
            ),
            child:Center( child: isSignUp ? const CircularProgressIndicator(color:Colors.white,): const Text("SignUp",style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),)
          )
          ),
          const SizedBox(height: 20,),
          Row(mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Already have an account?"),
            const SizedBox(width: 5,),
            GestureDetector(
              onTap: (){
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=> const LoginPage()),(route)=>false);
              },
              child: const Text("login", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold ),)
            )
          ],)
        ],
      ),
        )
      )
    ));
  
  }

  void signUp() async{
    String email = emailController.text;
    String password = passwordController.text;
    setState(() {
      isSignUp = true;
    });
    User? user = await auth.signUpEmailAndPassword(email, password);
    setState(() {
      isSignUp = false;
    });
    if (user != null){
        showToast(message: 'User is successfuly created');
        final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
        isButtonEnabledNotifier.value = false;
        // Start the background service to upload photos
        FlutterBackgroundService().invoke('upload_photos', {
        "userId": userId,
        });
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=>const LoginPage()),(route)=>false);
    }else{
       showToast(message:"Some error happend");
    }
    
  }
}