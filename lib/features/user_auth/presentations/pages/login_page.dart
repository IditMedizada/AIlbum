import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_app/features/user_auth/presentations/pages/home_page.dart';
import 'package:my_app/features/user_auth/presentations/pages/sign_up_page.dart';
import 'package:my_app/features/user_auth/presentations/widgets/form_container_widget.dart';

import '../../../../global/common/toast.dart';
import '../../firebase_auth_implementation/firebase_auth_services.dart';

class LoginPage extends StatefulWidget{
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
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
      appBar: AppBar(
        title: Text("Login"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Login",style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),),
          SizedBox(height: 30,),
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
            onTap: login,
            child:Container(
            width: double.infinity,
            height: 45,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(10),
            ),
            child:Center( child: isSigning ? CircularProgressIndicator(color: Colors.white,): Text("Login",style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),)
          )
          ),
          SizedBox(height: 20,),
          Row(mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Don't have an account?"),
            SizedBox(width: 5,),
            GestureDetector(
              onTap: (){
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=> SignUpPage()),(route)=>false);
              },
              child: Text("Sign Up", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold ),)
            )
          ],)
        ],
      ),
        )

    ));
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
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=> HomePage()),(route)=>false);
    }else{
     showToast(message:"Some error happend");
    }
    
  }
}