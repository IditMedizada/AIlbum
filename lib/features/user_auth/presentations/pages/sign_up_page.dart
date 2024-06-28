import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_app/features/user_auth/firebase_auth_implementation/firebase_auth_services.dart';
import 'package:my_app/features/user_auth/presentations/pages/home_page.dart';
import 'package:my_app/features/user_auth/presentations/pages/login_page.dart';
import 'package:my_app/features/user_auth/presentations/widgets/form_container_widget.dart';

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
      appBar: AppBar(
        title: Text("SignUp"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Sign Up",style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),),
          SizedBox(height: 30,),
          FormContainerWidget(
            controller: usernameController,
            hintText: "Username",
            isPasswordField: false,
          ),
          SizedBox(height: 10,),
          FormContainerWidget(
            controller: emailController,
            hintText: "Email",
            isPasswordField: false,
          ),
          SizedBox(height: 10,),
          FormContainerWidget(
            controller: passwordController,
            hintText: "Password",
            isPasswordField: true,
          ),
          SizedBox(height: 30,),
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
            child:Center( child: isSignUp ? CircularProgressIndicator(color:Colors.white,): Text("SignUp",style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),)
          )
          ),
          SizedBox(height: 20,),
          Row(mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Already have an account?"),
            SizedBox(width: 5,),
            GestureDetector(
              onTap: (){
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=> LoginPage()),(route)=>false);
              },
              child: Text("login", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold ),)
            )
          ],)
        ],
      ),
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
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=> HomePage()),(route)=>false);
    }else{
       showToast(message:"Some error happend");
    }
    
  }
}