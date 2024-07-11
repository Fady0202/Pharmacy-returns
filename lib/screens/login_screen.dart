import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() {
    return _LoginScreenState();
  }
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storage = const FlutterSecureStorage();

  //variable to help display a loading sign
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });
    // configure username and password
    try {
      final response = await http.post(
        Uri.parse('https://portal-test.rxmaxreturns.com/rxmax/auth'),
        body: jsonEncode({
          'username': _usernameController.text,
          'password': _passwordController.text,
        }),
        headers: {'Content-Type': 'application/json'},
      );
      // checks if the response was succefull
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        // saves the token for later communications
        await _storage.write(key: 'token', value: responseData["token"]);
        final token = await _storage.read(key: 'token');

        // gets ids of the pharmacies and chooses on of them
        const urlPharmacies =
            'https://portal-test.rxmaxreturns.com/rxmax/pharmacies/management';

        final responsePharmacies = await http.get(
          Uri.parse(urlPharmacies),
          headers: {'Authorization': 'Bearer $token'},
        );
        // print(jsonDecode(responsePharmacies.body).toString());
        await _storage.write(
            key: 'pharmacy_id',
            value: jsonDecode(responsePharmacies.body)[7]["pharmacyId"]
                .toString());

        //navigate to Return Requests screen
        Navigator.of(context).pushReplacementNamed('/returnRequests');
      } else {
        _showErrorDialog(
            'Login failed. Please check your credentials and try again.');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('Okay'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Login'),
          backgroundColor: const Color.fromARGB(122, 132, 202, 218)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _login,
                    child: const Text('Login'),
                  ),
          ],
        ),
      ),
    );
  }
}
