import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:pharmacy/screens/items_screen.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({required this.returnRequestId, super.key});
  final String returnRequestId;

  @override
  State<AddItemScreen> createState() {
    return _AddItemScreenState();
  }
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _storage = const FlutterSecureStorage();

  final _ndcController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _fullQuantityController = TextEditingController();
  final _partialQuantityController = TextEditingController();
  final _expirationDateController = TextEditingController();
  final _lotNumberController = TextEditingController();
  bool _isAdded = false;

  Future<void> _addItem() async {
    setState(() {
      _isAdded = true;
    });

    try {
      // Add the logic to add an item to the return request using the widget.returnRequestId
      final pharmacyId = await _storage.read(key: 'pharmacy_id');
      final token = await _storage.read(key: 'token');

      // adds a new item to a specific return request
      final response = await http.post(
        Uri.parse(
            'https://portal-test.rxmaxreturns.com/rxmax/pharmacies/$pharmacyId/returnrequests/${widget.returnRequestId}/items'),
        body: jsonEncode({
          'ndc': _ndcController.text,
          'description': _descriptionController.text,
          'manufacturer': _manufacturerController.text,
          'packageSize': '200',
          'requestType': 'csc',
          'name': 'fady',
          "strength": "strong",
          "dosage": "alssot",
          'fullQuantity': _fullQuantityController.text,
          'partialQuantity': _partialQuantityController.text,
          'expirationDate': _expirationDateController.text,
          "status": "PENDING",
          'lotNumber': _lotNumberController.text,
        }),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item added successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add item!')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error adding item. Please try again!')),
      );
    } finally {
      _ndcController.clear();
      _descriptionController.clear();
      _manufacturerController.clear();
      _fullQuantityController.clear();
      _partialQuantityController.clear();
      _expirationDateController.clear();
      _lotNumberController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Item'),
          backgroundColor: const Color.fromARGB(122, 132, 202, 218)),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _ndcController,
                  decoration: const InputDecoration(labelText: 'NDC'),
                ),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                TextField(
                  controller: _manufacturerController,
                  decoration: const InputDecoration(labelText: 'Manufacturer'),
                ),
                TextField(
                  controller: _fullQuantityController,
                  decoration: const InputDecoration(labelText: 'Full Quantity'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _partialQuantityController,
                  decoration:
                      const InputDecoration(labelText: 'Partial Quantity'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _expirationDateController,
                  decoration:
                      const InputDecoration(labelText: 'Expiration Date'),
                ),
                TextField(
                  controller: _lotNumberController,
                  decoration: const InputDecoration(labelText: 'Lot Number'),
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // a button to continually adding new items until user go to return requests or check the new items added
                    ElevatedButton(
                      onPressed: _addItem,
                      child: const Text('Add Item'),
                    ),
                    const SizedBox(width: 20),
                    // button to check new items added, PS. only appers after adding at least one item
                    !_isAdded
                        ? const SizedBox()
                        : ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ItemsScreen(
                                      returnRequestId: widget.returnRequestId),
                                ),
                              );
                            },
                            child: const Text('Check Items'),
                          ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
