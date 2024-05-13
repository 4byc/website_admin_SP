import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartparking_admin_web_portal/authentication/login_screen.dart';
import 'package:smartparking_admin_web_portal/screens/analytics_history_screen.dart';
import 'package:smartparking_admin_web_portal/screens/manage_users_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MaterialApp(
    home: HomeScreen(),
  ));
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _timeText = "";
  String _dateText = "";
  String _adminName = "Admin"; // Default name

  String _formatCurrentLiveTime(DateTime time) {
    return DateFormat("HH:mm:ss").format(time); // Changed to 24-hour format
  }

  String _formatCurrentDate(DateTime date) {
    return DateFormat("dd MMMM, yyyy").format(date);
  }

  void _getCurrentLiveTime() {
    final DateTime timeNow = DateTime.now();
    final String liveTime = _formatCurrentLiveTime(timeNow);
    final String liveDate = _formatCurrentDate(timeNow);

    if (this.mounted) {
      setState(() {
        _timeText = liveTime;
        _dateText = liveDate;
      });
    }
  }

  Future<void> _showLogoutConfirmationDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text('Are you sure you want to log out?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Logout'),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();

    _getCurrentLiveTime();
    _retrieveAdminName();
    Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      _getCurrentLiveTime();
    });
  }

  void _retrieveAdminName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final adminSnapshot = await FirebaseFirestore.instance
          .collection('admins')
          .doc(user.uid)
          .get();
      final adminData = adminSnapshot.data();
      if (adminData != null) {
        setState(() {
          _adminName = adminData['name'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.cyan],
              begin: FractionalOffset(0, 0),
              end: FractionalOffset(1, 0),
              stops: [0, 1],
              tileMode: TileMode.clamp,
            ),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Welcome, $_adminName",
              style: const TextStyle(
                fontSize: 16,
                letterSpacing: 1,
                color: Colors.white,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _timeText,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _dateText,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        centerTitle: true,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Your main content here
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.cyan],
                  begin: FractionalOffset(0, 0),
                  end: FractionalOffset(1, 0),
                  stops: [0, 1],
                  tileMode: TileMode.clamp,
                ),
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.people),
              title: Text('Manage Users'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          ManageUsersScreen()), // Navigate to user management page
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.analytics),
              title: Text('Analytics and History'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          AnalyticsHistoryScreen()), // Navigate to analytics and history page
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                // Navigate to settings page
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () {
                _showLogoutConfirmationDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
