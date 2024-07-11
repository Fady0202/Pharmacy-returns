import 'package:flutter/material.dart';
import 'package:pharmacy/screens/login_screen.dart';
import 'package:pharmacy/screens/add_item_screen.dart';
import 'package:pharmacy/screens/create_return_request_screen.dart';
import 'package:pharmacy/screens/return_request_screen.dart';
import 'package:pharmacy/screens/items_screen.dart';

void main() {
  runApp(PharmacyReturnApp());
}

class PharmacyReturnApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pharmacy Return App',
      initialRoute: '/',
      // Intializing my screens routs
      routes: {
        '/': (context) => LoginScreen(),
        '/returnRequests': (context) => ReturnRequestsScreen(),
        '/createReturnRequest': (context) => CreateReturnRequestScreen(),
        '/addItem': (context) => AddItemScreen(returnRequestId: ModalRoute.of(context)!.settings.arguments.toString()),
        '/items': (context) => ItemsScreen(returnRequestId: ModalRoute.of(context)!.settings.arguments.toString()),
      },
    );
  }
}
