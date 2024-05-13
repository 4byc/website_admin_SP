import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smartparking_admin_web_portal/screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String adminEmail = "";
  String adminPassword = "";

  allowAdminToLogin() async {
    SnackBar snackBar = const SnackBar(
      content: Text(
        "Checking Credentials, Please wait...",
        style: TextStyle(
          fontSize: 16,
          color: Colors.black,
        ),
      ),
      backgroundColor: Colors.blueAccent,
      duration: Duration(seconds: 6),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);

    User? currentAdmin;
    await FirebaseAuth.instance
        .signInWithEmailAndPassword(
      email: adminEmail,
      password: adminPassword,
    )
        .then((fAuth) {
      currentAdmin = fAuth.user;
    }).catchError((onError) {
      //display error message
      final snackBar = SnackBar(
        content: Text(
          "Error Occurred: " + onError.toString(),
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        duration: const Duration(seconds: 5),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    });

    if (currentAdmin != null) {
      await FirebaseFirestore.instance
          .collection("admins")
          .doc(currentAdmin!.uid)
          .get()
          .then((snap) {
        if (snap.exists) {
          Navigator.push(
              context, MaterialPageRoute(builder: (c) => const HomeScreen()));
        } else {
          SnackBar snackBar = const SnackBar(
            content: Text(
              "No record found, you are not an admin.",
              style: TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            backgroundColor: Colors.blueAccent,
            duration: Duration(seconds: 6),
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * .5,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  //image
                  Image.asset("images/icon.png"),

                  //email text field
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        adminEmail = value;
                      });
                    },
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                    decoration: const InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.blue,
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.cyan,
                          width: 2,
                        ),
                      ),
                      hintText: "Email",
                      hintStyle: TextStyle(color: Colors.grey),
                      icon: Icon(
                        Icons.email,
                        color: Colors.cyan,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  //password text field
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        adminPassword = value;
                      });
                    },
                    obscureText: true,
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                    decoration: const InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.blue,
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.cyan,
                          width: 2,
                        ),
                      ),
                      hintText: "Password",
                      hintStyle: TextStyle(color: Colors.grey),
                      icon: Icon(
                        Icons.admin_panel_settings,
                        color: Colors.cyan,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 30,
                  ),

                  //button login
                  ElevatedButton(
                    onPressed: () {
                      allowAdminToLogin();
                    },
                    style: ButtonStyle(
                      padding: MaterialStateProperty.all(
                          const EdgeInsets.symmetric(
                              horizontal: 100, vertical: 20)),
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.blue),
                      foregroundColor:
                          MaterialStateProperty.all<Color>(Colors.cyan),
                    ),
                    child: Text(
                      "Login",
                      style: TextStyle(
                        color: Colors.white,
                        letterSpacing: 2,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
