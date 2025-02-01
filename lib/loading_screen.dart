// ignore_for_file: use_build_context_synchronously

import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Loading extends StatefulWidget {
  const Loading({super.key});

  @override
  State<Loading> createState() => _LoadingState();
}

class _LoadingState extends State<Loading> {
  checkIfUserLoggedIn() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    await Future.delayed(const Duration(milliseconds: 500));
    User? user = auth.currentUser;
    if (user == null) {
      Navigator.popAndPushNamed(context, "/login");
    } else if (user.email!.endsWith('@student.ku.edu.np')) {
      Navigator.popAndPushNamed(context, "/student-dashboard");
    } else {
      Navigator.popAndPushNamed(context, "/teacher-dashboard");
    }
  }

  @override
  void initState() {
    checkIfUserLoggedIn();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
