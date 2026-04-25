import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('Fetch all users', (WidgetTester tester) async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      await Firebase.initializeApp();
      print('Firebase initialized.');
    } catch (e) {
      print('Firebase init error (might already be initialized): $e');
    }

    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      print('--- ALL USERS IN FIRESTORE ---');
      for (final doc in snapshot.docs) {
        final data = doc.data();
        print('User ID: ${doc.id}');
        print('  Name: ${data['name']}');
        print('  Email: ${data['email']}');
        print('  Phone: ${data['phone']}');
        print('---------------------------');
      }
    } catch (e) {
      print('Error fetching users: $e');
    }
  });
}
