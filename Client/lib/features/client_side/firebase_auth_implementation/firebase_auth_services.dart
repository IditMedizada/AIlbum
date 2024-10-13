import 'package:firebase_auth/firebase_auth.dart';
import '../../../global/common/toast.dart';

class FirebaseAuthService{
  // Creating a service class for handling Firebase Authentication logic.
  FirebaseAuth auth = FirebaseAuth.instance;

  // A method to sign up a new user using email and password. It returns a `User` object if successful or `null` if not.
  Future<User?> signUpEmailAndPassword(String email, String password) async {
    try{
      // Using FirebaseAuth to create a new user account with the provided email and password. 
      // If successful, the method returns a `UserCredential` object.
      //This object provides details about the authenticated user and additional metadata.
      UserCredential credential = await auth.createUserWithEmailAndPassword(email: email, password: password);
      // Returning the `User` object from the `UserCredential`, which represents the newly created user.
      return credential.user;
    }on FirebaseAuthException catch(e){
       if (e.code == 'email-already-in-use') {
        showToast(message: 'The email address is already in use.');
      }
    }
    return null;
  }
  // A method to sign in an existing user using email and password. It returns a `User` object if successful or `null` if not.
  Future<User?> signInWithEmailAndPassword(String email, String password)async{
    try{
      // Using FirebaseAuth to sign in a user with the provided email and password. 
      // If successful, the method returns a `UserCredential` object.
      UserCredential credential = await auth.signInWithEmailAndPassword(email: email, password: password);
      return credential.user;
    }on FirebaseAuthException catch(e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        showToast(message: 'Invalid email or password.');
      }
    }
    return null;
  }
}