import 'package:flutter/material.dart';
import '../../../../routes/pages.dart';

class LoginButton extends StatelessWidget {
  const LoginButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () {
          Navigator.pushReplacementNamed(context, AppPages.home);
        },
        child: const Text("Login"),
      ),
    );
  }
}