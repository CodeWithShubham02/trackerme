import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/super_admin_model.dart';

class LoginController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // TEXT CONTROLLERS
  // ============================================================

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // ============================================================
  // VARIABLES
  // ============================================================

  final selectedRole = "Admin".obs;

  final obscurePassword = true.obs;

  final isLoading = false.obs;

  // ============================================================
  // ROLE CHANGE
  // ============================================================

  void onRoleChanged(String? value) {
    if (value == null) return;

    selectedRole.value = value;

    emailController.clear();
    passwordController.clear();
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<void> login() async {
    switch (selectedRole.value) {
      case "Super Admin":
        await loginSuperAdmin();
        break;

      case "Admin":
        await loginAdmin();
        break;

      case "User":
        await loginUser();
        break;
    }
  }

  // ============================================================
  // SUPER ADMIN LOGIN
  // ============================================================

  Future<void> loginSuperAdmin() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty) {
      _showMessage(
        "Please enter email",
        isError: true,
      );
      return;
    }

    if (password.isEmpty) {
      _showMessage(
        "Please enter password",
        isError: true,
      );
      return;
    }

    try {
      isLoading.value = true;

      // ========================================================
      // FIREBASE EMAIL + PASSWORD LOGIN
      // ========================================================

      final credential =
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user == null) {
        throw Exception(
          "Firebase user not found.",
        );
      }

      // ========================================================
      // FIRESTORE
      //
      // super_admin/{Firebase UID}
      // ========================================================

      final document = await _firestore
          .collection("super_admin")
          .doc(user.uid)
          .get();

      if (!document.exists) {
        await _auth.signOut();

        throw Exception(
          "Super Admin profile not found.",
        );
      }

      final data = document.data();

      if (data == null) {
        await _auth.signOut();

        throw Exception(
          "Invalid Super Admin profile.",
        );
      }

      // ========================================================
      // MODEL
      // ========================================================

      final superAdmin =
      SuperAdminModel.fromFirestore(
        document.id,
        data,
      );

      // ========================================================
      // ROLE CHECK
      // ========================================================

      if (superAdmin.role != "super_admin") {
        await _auth.signOut();

        throw Exception(
          "This account is not a Super Admin.",
        );
      }

      // ========================================================
      // STATUS CHECK
      // ========================================================

      if (superAdmin.status != "active") {
        await _auth.signOut();

        throw Exception(
          "Super Admin account is inactive.",
        );
      }

      // ========================================================
      // SUCCESS
      // ========================================================

      _showMessage(
        "Super Admin Login Successful",
      );

      debugPrint(
        "Super Admin UID: ${superAdmin.id}",
      );

      debugPrint(
        "Super Admin Email: ${superAdmin.email}",
      );

      // ========================================================
      // DASHBOARD
      // ========================================================

      // Get.offAll(
      //   () => const SuperAdminDashboard(),
      // );

    } on FirebaseAuthException catch (e) {
      _showMessage(
        _firebaseAuthError(e),
        isError: true,
      );
    } catch (e) {
      _showMessage(
        e.toString().replaceFirst(
          "Exception: ",
          "",
        ),
        isError: true,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // ADMIN LOGIN
  // ============================================================

  Future<void> loginAdmin() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty) {
      _showMessage(
        "Please enter admin email",
        isError: true,
      );
      return;
    }

    if (password.isEmpty) {
      _showMessage(
        "Please enter password",
        isError: true,
      );
      return;
    }

    await loginWithFirebase(
      email: email,
      password: password,
      requiredRole: "admin",
    );
  }

  // ============================================================
  // USER LOGIN
  // ============================================================

  Future<void> loginUser() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty) {
      _showMessage(
        "Please enter User ID / Email",
        isError: true,
      );
      return;
    }

    if (password.isEmpty) {
      _showMessage(
        "Please enter password",
        isError: true,
      );
      return;
    }

    await loginWithFirebase(
      email: email,
      password: password,
      requiredRole: "user",
    );
  }

  // ============================================================
  // COMMON ADMIN / USER LOGIN
  // ============================================================

  Future<void> loginWithFirebase({
    required String email,
    required String password,
    required String requiredRole,
  }) async {
    try {
      isLoading.value = true;

      final credential =
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user == null) {
        throw Exception(
          "Firebase user not found.",
        );
      }

      final document = await _firestore
          .collection("users")
          .doc(user.uid)
          .get();

      if (!document.exists) {
        await _auth.signOut();

        throw Exception(
          "User profile not found.",
        );
      }

      final data = document.data();

      if (data == null) {
        await _auth.signOut();

        throw Exception(
          "Invalid user profile.",
        );
      }

      final role =
      data["role"]?.toString().toLowerCase();

      final status =
      data["status"]?.toString().toLowerCase();

      final cid =
          data["cid"]?.toString() ?? "";

      // ========================================================
      // ROLE CHECK
      // ========================================================

      if (role != requiredRole) {
        await _auth.signOut();

        throw Exception(
          "Invalid $requiredRole account.",
        );
      }

      // ========================================================
      // STATUS CHECK
      // ========================================================

      if (status != "active") {
        await _auth.signOut();

        throw Exception(
          "Your account is inactive.",
        );
      }

      // ========================================================
      // CID CHECK
      // ========================================================

      if (cid.isEmpty) {
        await _auth.signOut();

        throw Exception(
          "Company ID not assigned.",
        );
      }

      _showMessage(
        "Login successful",
      );

      // ========================================================
      // NAVIGATION
      // ========================================================

      if (requiredRole == "admin") {
        // Get.offAll(
        //   () => AdminDashboard(cid: cid),
        // );
      } else {
        // Get.offAll(
        //   () => UserDashboard(cid: cid),
        // );
      }
    } on FirebaseAuthException catch (e) {
      _showMessage(
        _firebaseAuthError(e),
        isError: true,
      );
    } catch (e) {
      _showMessage(
        e.toString().replaceFirst(
          "Exception: ",
          "",
        ),
        isError: true,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // FIREBASE ERROR
  // ============================================================

  String _firebaseAuthError(
      FirebaseAuthException e,
      ) {
    switch (e.code) {
      case "invalid-credential":
        return "Invalid email or password.";

      case "user-not-found":
        return "Account not found.";

      case "wrong-password":
        return "Incorrect password.";

      case "invalid-email":
        return "Invalid email address.";

      case "user-disabled":
        return "This account has been disabled.";

      case "too-many-requests":
        return "Too many attempts. Please try again later.";

      case "network-request-failed":
        return "Please check your internet connection.";

      default:
        return e.message ?? "Authentication failed.";
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
      String message, {
        bool isError = false,
      }) {
    Get.snackbar(
      isError ? "Error" : "Success",
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor:
      isError ? Colors.red : Colors.green,
      colorText: Colors.white,
      margin: const EdgeInsets.all(12),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();

    super.onClose();
  }
}