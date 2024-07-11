import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CreateReturnRequestScreen extends StatefulWidget {
  const CreateReturnRequestScreen({super.key});
  @override
  State<CreateReturnRequestScreen> createState() {
    return _CreateReturnRequestScreenState();
  }
}

class _CreateReturnRequestScreenState extends State<CreateReturnRequestScreen> {
  final _storage = const FlutterSecureStorage();
  String _serviceType = 'EXPRESS_SERVICE';
  String _wholesalerId = '';
  List<Map<String, dynamic>> _wholesalers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchWholesalers();
  }

  Future<void> _fetchWholesalers() async {
    final token = await _storage.read(key: 'token');
    final pharmacyId = await _storage.read(key: 'pharmacy_id');
    // fetches the wholesalers for the dropsown choice, PS. mfeesh gher wahda :(

    final response = await http.get(
      Uri.parse(
          'https://portal-test.rxmaxreturns.com/rxmax/pharmacies/$pharmacyId/wholesalers'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        _wholesalers =
            data.map((item) => Map<String, dynamic>.from(item)).toList();
        _wholesalerId =
            _wholesalers.isNotEmpty ? _wholesalers[0]['id'].toString() : '';
      });
    }
  }

  Future<void> _createReturnRequest() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await _storage.read(key: 'token');
      final pharmacyId = await _storage.read(key: 'pharmacy_id');
      // this creates a new return request in server
      final response = await http.post(
        Uri.parse(
            'https://portal-test.rxmaxreturns.com/rxmax/pharmacies/$pharmacyId/returnrequests'),
        body: jsonEncode({
          'serviceType': _serviceType,
          'wholesalerId': _wholesalerId,
        }),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        // if created successfuly, navigate to Add Item Screen
        Navigator.pushReplacementNamed(context, '/addItem',
            arguments: responseData['id']);
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Return Request'),
          backgroundColor: const Color.fromARGB(122, 132, 202, 218)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButton<String>(
                    value: _serviceType,
                    onChanged: (String? newValue) {
                      setState(() {
                        _serviceType = newValue!;
                      });
                    },
                    items: <String>['EXPRESS_SERVICE', 'FULL_SERVICE']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  DropdownButton<String>(
                    value: _wholesalerId,
                    onChanged: (String? newValue) {
                      setState(() {
                        _wholesalerId = newValue!;
                      });
                    },
                    items: _wholesalers.map((wholesaler) {
                      return DropdownMenuItem<String>(
                        value: wholesaler['id'].toString(),
                        child: Text(wholesaler['name']),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _createReturnRequest,
                    child: const Text('Create Return Request'),
                  ),
                ],
              ),
      ),
    );
  }
}
