import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ============================================================
  // FIREBASE
  // ============================================================

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController emailController =
  TextEditingController();

  final TextEditingController passwordController =
  TextEditingController();

  final TextEditingController otpController =
  TextEditingController();

  // ============================================================
  // VARIABLES
  // ============================================================

  String selectedRole = "Admin";

  bool obscurePassword = true;

  bool isLoading = false;

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    otpController.dispose();

    super.dispose();
  }

  // ============================================================
  // ROLE CHANGE
  // ============================================================

  void onRoleChanged(String? value) {
    if (value == null) return;

    setState(() {
      selectedRole = value;

      emailController.clear();
      passwordController.clear();
      otpController.clear();
    });
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<void> login() async {
    if (selectedRole == "Super Admin") {
      await loginSuperAdmin();
    } else if (selectedRole == "Admin") {
      await loginAdmin();
    } else {
      await loginUser();
    }
  }

  // ============================================================
  // SUPER ADMIN
  // ============================================================

  Future<void> loginSuperAdmin() async {
    final email =
    emailController.text.trim();

    final password =
    passwordController.text.trim();

    if (email.isEmpty) {
      showMessage(
        "Please enter email",
        isError: true,
      );
      return;
    }

    if (password.isEmpty) {
      showMessage(
        "Please enter password",
        isError: true,
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final credential =
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid =
          credential.user!.uid;

      final userDoc =
      await _firestore
          .collection("users")
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        await _auth.signOut();

        throw Exception(
          "User profile not found",
        );
      }

      final data =
      userDoc.data()!;

      final role =
      data["role"]
          ?.toString()
          .toLowerCase();

      final status =
      data["status"]
          ?.toString()
          .toLowerCase();

      if (role != "super_admin") {
        await _auth.signOut();

        throw Exception(
          "This account is not a Super Admin account",
        );
      }

      if (status != "active") {
        await _auth.signOut();

        throw Exception(
          "Super Admin account is inactive",
        );
      }

      if (!mounted) return;

      showOtpDialog();

    } on FirebaseAuthException catch (e) {
      showMessage(
        firebaseAuthError(e),
        isError: true,
      );
    } catch (e) {
      showMessage(
        e.toString().replaceFirst(
          "Exception: ",
          "",
        ),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // ADMIN LOGIN
  // ============================================================

  Future<void> loginAdmin() async {
    final email =
    emailController.text.trim();

    final password =
    passwordController.text.trim();

    if (email.isEmpty) {
      showMessage(
        "Please enter admin email",
        isError: true,
      );
      return;
    }

    if (password.isEmpty) {
      showMessage(
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
    final email =
    emailController.text.trim();

    final password =
    passwordController.text.trim();

    if (email.isEmpty) {
      showMessage(
        "Please enter User ID / Email",
        isError: true,
      );
      return;
    }

    if (password.isEmpty) {
      showMessage(
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
  // COMMON FIREBASE LOGIN
  // ============================================================

  Future<void> loginWithFirebase({
    required String email,
    required String password,
    required String requiredRole,
  }) async {
    setState(() {
      isLoading = true;
    });

    try {
      final credential =
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid =
          credential.user!.uid;

      final userDoc =
      await _firestore
          .collection("users")
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        await _auth.signOut();

        throw Exception(
          "User profile not found",
        );
      }

      final data =
      userDoc.data()!;

      final role =
      data["role"]
          ?.toString()
          .toLowerCase();

      final status =
      data["status"]
          ?.toString()
          .toLowerCase();

      final cid =
          data["cid"]?.toString() ?? "";

      // --------------------------------------------------------
      // ROLE CHECK
      // --------------------------------------------------------

      if (role != requiredRole) {
        await _auth.signOut();

        throw Exception(
          "Invalid $requiredRole account",
        );
      }

      // --------------------------------------------------------
      // STATUS CHECK
      // --------------------------------------------------------

      if (status != "active") {
        await _auth.signOut();

        throw Exception(
          "Your account is inactive",
        );
      }

      // --------------------------------------------------------
      // CID CHECK
      // --------------------------------------------------------

      if (cid.isEmpty) {
        await _auth.signOut();

        throw Exception(
          "Company ID not assigned",
        );
      }

      if (!mounted) return;

      showMessage(
        "Login successful",
      );

      // --------------------------------------------------------
      // NAVIGATION
      // --------------------------------------------------------

      if (requiredRole == "admin") {

        // Example:
        //
        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(
        //     builder: (_) => AdminDashboard(
        //       cid: cid,
        //     ),
        //   ),
        // );

      } else {

        // Example:
        //
        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(
        //     builder: (_) => UserDashboard(
        //       cid: cid,
        //     ),
        //   ),
        // );
      }

    } on FirebaseAuthException catch (e) {
      showMessage(
        firebaseAuthError(e),
        isError: true,
      );
    } catch (e) {
      showMessage(
        e.toString().replaceFirst(
          "Exception: ",
          "",
        ),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // OTP DIALOG
  // ============================================================

  void showOtpDialog() {
    otpController.clear();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.security,
                color: Color(0xff2563EB),
              ),
              SizedBox(width: 10),
              Text("Verification"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Enter the 6-digit OTP from your Authenticator App.",
              ),

              const SizedBox(height: 20),

              TextField(
                controller: otpController,
                keyboardType:
                TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
                decoration: InputDecoration(
                  hintText: "000000",
                  counterText: "",
                  border: OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await _auth.signOut();

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text("Cancel"),
            ),

            ElevatedButton(
              onPressed: verifySuperAdminOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                const Color(0xff2563EB),
                foregroundColor:
                Colors.white,
              ),
              child: const Text(
                "Verify",
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // VERIFY SUPER ADMIN OTP
  // ============================================================

  Future<void> verifySuperAdminOtp() async {
    final otp =
    otpController.text.trim();

    if (otp.length != 6) {
      showMessage(
        "Please enter 6 digit OTP",
        isError: true,
      );
      return;
    }

    /*
    IMPORTANT:

    Yahan Authenticator App ka TOTP
    Firebase MFA ke through verify karna
    chahiye.

    Simple Firestore document me OTP
    store karke compare MAT karna.

    Firebase Authentication MFA /
    TOTP ko use karna recommended hai.
    */

    showMessage(
      "Firebase MFA verification setup required",
    );
  }

  // ============================================================
  // FIREBASE AUTH ERROR
  // ============================================================

  String firebaseAuthError(
      FirebaseAuthException e,
      ) {
    switch (e.code) {
      case "invalid-credential":
        return "Invalid email or password";

      case "user-not-found":
        return "Account not found";

      case "wrong-password":
        return "Incorrect password";

      case "invalid-email":
        return "Invalid email address";

      case "user-disabled":
        return "This account has been disabled";

      case "too-many-requests":
        return "Too many attempts. Please try again later";

      case "network-request-failed":
        return "Please check your internet connection";

      default:
        return e.message ??
            "Authentication failed";
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void showMessage(
      String message, {
        bool isError = false,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
        isError
            ? Colors.red
            : Colors.green,
        behavior:
        SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(12),
      ),
      enabledBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
      focusedBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(12),
        borderSide:
        const BorderSide(
          color: Color(0xff2563EB),
          width: 1.5,
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    final bool isSuperAdmin =
        selectedRole == "Super Admin";

    return Scaffold(
      backgroundColor:
      const Color(0xffF5F7FB),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
            const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints:
              const BoxConstraints(
                maxWidth: 440,
              ),
              child: Column(
                children: [

                  // ==================================================
                  // LOGO
                  // ==================================================

                  Container(
                    height: 80,
                    width: 80,
                    decoration:
                    BoxDecoration(
                      color:
                      const Color(0xff2563EB),
                      borderRadius:
                      BorderRadius.circular(
                        20,
                      ),
                    ),
                    child: const Icon(
                      Icons
                          .location_history,
                      color: Colors.white,
                      size: 45,
                    ),
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  const Text(
                    "Track Me",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  Text(
                    "Attendance & Workforce Management",
                    style: TextStyle(
                      color:
                      Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(
                    height: 28,
                  ),

                  // ==================================================
                  // CARD
                  // ==================================================

                  Container(
                    padding:
                    const EdgeInsets.all(22),
                    decoration:
                    BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                      BorderRadius.circular(
                        20,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                          Colors.black
                              .withOpacity(
                            0.06,
                          ),
                          blurRadius: 25,
                          offset:
                          const Offset(
                            0,
                            8,
                          ),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                      children: [

                        const Text(
                          "Welcome Back",
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),

                        const SizedBox(
                          height: 5,
                        ),

                        Text(
                          "Sign in to continue",
                          style: TextStyle(
                            color:
                            Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),

                        const SizedBox(
                          height: 22,
                        ),

                        // ROLE
                        DropdownButtonFormField<
                            String>(
                          value:
                          selectedRole,
                          decoration:
                          inputDecoration(
                            label: "Login As",
                            hint:
                            "Select role",
                            icon:
                            Icons
                                .manage_accounts_outlined,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value:
                              "Super Admin",
                              child:
                              Text(
                                "Super Admin",
                              ),
                            ),
                            DropdownMenuItem(
                              value:
                              "Admin",
                              child:
                              Text(
                                "Admin",
                              ),
                            ),
                            DropdownMenuItem(
                              value:
                              "User",
                              child:
                              Text(
                                "User",
                              ),
                            ),
                          ],
                          onChanged:
                          onRoleChanged,
                        ),

                        const SizedBox(
                          height: 16,
                        ),

                        // EMAIL / USER ID
                        TextField(
                          controller:
                          emailController,
                          decoration:
                          inputDecoration(
                            label:
                            isSuperAdmin ||
                                selectedRole ==
                                    "Admin"
                                ? "Email"
                                : "User ID / Email",
                            hint:
                            isSuperAdmin ||
                                selectedRole ==
                                    "Admin"
                                ? "Enter email"
                                : "Enter User ID / Email",
                            icon:
                            Icons
                                .person_outline,
                          ),
                        ),

                        // PASSWORD
                        if (!isSuperAdmin) ...[
                          const SizedBox(
                            height: 16,
                          ),

                          TextField(
                            controller:
                            passwordController,
                            obscureText:
                            obscurePassword,
                            decoration:
                            inputDecoration(
                              label:
                              "Password",
                              hint:
                              "Enter password",
                              icon:
                              Icons
                                  .lock_outline,
                            ).copyWith(
                              suffixIcon:
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    obscurePassword =
                                    !obscurePassword;
                                  });
                                },
                                icon: Icon(
                                  obscurePassword
                                      ? Icons
                                      .visibility_outlined
                                      : Icons
                                      .visibility_off_outlined,
                                ),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(
                          height: 22,
                        ),

                        // LOGIN
                        SizedBox(
                          width:
                          double.infinity,
                          height: 50,
                          child:
                          ElevatedButton(
                            onPressed:
                            isLoading
                                ? null
                                : login,
                            style:
                            ElevatedButton
                                .styleFrom(
                              backgroundColor:
                              const Color(
                                0xff2563EB,
                              ),
                              foregroundColor:
                              Colors.white,
                              shape:
                              RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius
                                    .circular(
                                  12,
                                ),
                              ),
                            ),
                            child:
                            isLoading
                                ? const SizedBox(
                              height: 22,
                              width: 22,
                              child:
                              CircularProgressIndicator(
                                strokeWidth:
                                2,
                                color:
                                Colors.white,
                              ),
                            )
                                : Text(
                              isSuperAdmin
                                  ? "Continue"
                                  : "Login",
                              style:
                              const TextStyle(
                                fontWeight:
                                FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}