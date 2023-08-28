import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartx_flutter_app/backend/server_response.dart';
import 'package:smartx_flutter_app/helper/firebase_auth_helper.dart';
import 'package:smartx_flutter_app/helper/firestore_database_helper.dart';
import 'package:smartx_flutter_app/helper/shared_preference_helpert.dart';
import 'package:smartx_flutter_app/extension/string_extention.dart';

import '../../../models/user_model.dart';

class SignUpController extends GetxController {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController cPasswordController = TextEditingController();
  Rx<bool> isPasswordVisible = Rx<bool>(true);
  Rx<bool> isTerms = Rx<bool>(false);
  Rx<bool> isPasswordVisible2 = Rx<bool>(true);

  void togglePasswordVisible() => isPasswordVisible(!isPasswordVisible.value);
  void togglePasswordVisible2() => isPasswordVisible2(!isPasswordVisible2.value);
  void toggleIsTermsCheck() => isTerms(!isTerms.value);
  final Rx<String> isPasswordError = Rx<String>('');
  final Rx<String> isCPasswordError = Rx<String>('');
  final Rx<String> isEmailError = Rx<String>('');
  final FirebaseAuthHelper _firebaseAuthHelper = FirebaseAuthHelper.instance();
  final SharedPreferenceHelper _sharedPreferenceHelper =
      SharedPreferenceHelper.instance;
  final FirestoreDatabaseHelper _firestoreDatabaseHelper =
      FirestoreDatabaseHelper.instance();
  changeVisibility(){
    isPasswordVisible.value = !(isPasswordVisible.value);
    print(isPasswordVisible);
    print("visibility");
  }
  Future<String?> createAccount(String userEmail, String password) async {
    print(userEmail);
    print(password);
    try {
      final userCredential =
          await _firebaseAuthHelper.signUp(userEmail, password);
      final userUid = userCredential.user?.uid;
      if (userUid == null) return null;

      final user = userCredential.user;
      if (user == null) return null;
      final email = user.email;
      if (email == null) return null;

      final userData = UserModel(
          firstName: '',
          email: user.email ?? '',
          fcmToken: '',
          id: user.uid,
          lastName: '');

      final checkPrevious = await _firestoreDatabaseHelper.getUser(userData.id);
      if (checkPrevious == null) {
        _firestoreDatabaseHelper.addUser(userData);
        await _sharedPreferenceHelper.insertUser(userData);
        await _sharedPreferenceHelper.savePassword(password);
      } else {
        await _sharedPreferenceHelper.insertUser(userData);
        await _sharedPreferenceHelper.savePassword(password);
      }

      return '';
    } on FirebaseAuthException catch (e) {
      return _firebaseAuthHelper
          .getErrorMessage(e)
          ?.removeExceptionTextIfContains;
    } catch (e) {
      return null;
    }
  }
}
