import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AuthenticatorOtpDialog extends StatefulWidget {
  final MultiFactorResolver resolver;
  final String enrollmentId;

  const AuthenticatorOtpDialog({
    super.key,
    required this.resolver,
    required this.enrollmentId,
  });

  @override
  State<AuthenticatorOtpDialog> createState() =>
      _AuthenticatorOtpDialogState();
}

class _AuthenticatorOtpDialogState
    extends State<AuthenticatorOtpDialog> {

  final otpController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  Future<void> verify() async {
    final code = otpController.text.trim();

    if (code.length != 6) {
      Get.snackbar(
        "Invalid Code",
        "Enter 6-digit authenticator code.",
      );

      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      // ------------------------------------------------
      // Create TOTP assertion
      // ------------------------------------------------

      final assertion =
      await TotpMultiFactorGenerator
          .getAssertionForSignIn(
        widget.enrollmentId,
        code,
      );

      // ------------------------------------------------
      // Resolve Firebase MFA
      // ------------------------------------------------

      await widget.resolver.resolveSignIn(
        assertion,
      );

      if (!mounted) return;

      Get.back(result: true);

    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        "Verification Failed",
        e.message ?? "Invalid authenticator code.",
      );

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        e.toString(),
      );

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.security),
          SizedBox(width: 10),
          Text("Authenticator"),
        ],
      ),

      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          const Text(
            "Open your Authenticator app and "
                "enter the 6-digit code.",
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          TextField(
            controller: otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: "Authenticator Code",
              hintText: "123456",
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),

      actions: [

        TextButton(
          onPressed: isLoading
              ? null
              : () => Get.back(result: false),
          child: const Text("Cancel"),
        ),

        ElevatedButton(
          onPressed: isLoading ? null : verify,
          child: isLoading
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          )
              : const Text("Verify"),
        ),
      ],
    );
  }
}