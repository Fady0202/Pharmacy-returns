import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({required this.returnRequestId, super.key});
  final String returnRequestId;
  @override
  State<ItemsScreen> createState() {
    return _ItemsScreenState();
  }

}

class _ItemsScreenState extends State<ItemsScreen> {
  final _storage = const FlutterSecureStorage();
  List<dynamic> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    try {
      final token = await _storage.read(key: 'token');
      final pharmacyId = await _storage.read(key: 'pharmacy_id');
      // fetches all items for a specific return request
      final response = await http.get(
        Uri.parse(
            'https://portal-test.rxmaxreturns.com/rxmax/pharmacies/$pharmacyId/returnrequests/${widget.returnRequestId}/items'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          _items = data;
          _isLoading = false;
        });
      } else {
        _showErrorDialog('Failed to load items.');
      }
    } catch (error) {
      _showErrorDialog('An error occurred. Please try again.');
    }
  }

  // a function to delete an item using a delete button
  Future<void> _deleteItem(String itemId) async {
    try {
      final token = await _storage.read(key: 'token');
      final pharmacyId = await _storage.read(key: 'pharmacy_id');
      final response = await http.delete(
        Uri.parse(
            'https://portal-test.rxmaxreturns.com/rxmax/pharmacies/$pharmacyId/returnrequests/${widget.returnRequestId}/items/$itemId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _items.removeWhere((item) => item['id'].toString() == itemId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item deleted successfully!')),
        );
      } else {
        _showErrorDialog('Failed to delete item.');
      }
    } catch (error) {
      _showErrorDialog('An error occurred. Please try again.');
    }
  }

  // a function update an item using ypdate button
  Future<void> _updateItemDescription(
      String itemId, String newDescription, int index) async {
    try {
      final token = await _storage.read(key: 'token');
      final pharmacyId = await _storage.read(key: 'pharmacy_id');
      final response = await http.put(
        Uri.parse(
            'https://portal-test.rxmaxreturns.com/rxmax/pharmacies/$pharmacyId/returnrequests/${widget.returnRequestId}/items/$itemId'),
        body: jsonEncode({
          "ndc": _items[index]['ndc'],
          'description': newDescription,
          "manufacturer": _items[index]['manufacturer'],
          "packageSize": _items[index]['packageSize'],
          "requestType": _items[index]['requestType'],
          "name": _items[index]['name'],
          "strength": _items[index]['strength'],
          "dosage": _items[index]['dosage'],
          "fullQuantity": _items[index]['fullQuantity'],
          "partialQuantity": _items[index]['partialQuantity'],
          "expirationDate": _items[index]['expirationDate'],
          "status": _items[index]['status'],
          "lotNumber": _items[index]['lotNumber'],
        }),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final updatedItem = jsonDecode(response.body);
        setState(() {
          // Update the item in the local list with the updated description
          _items.firstWhere(
                  (item) => item['id'].toString() == itemId)['description'] =
              updatedItem['description'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Item description updated successfully!')),
        );
      } else {
        _showErrorDialog('Failed to update item description.');
      }
    } catch (error) {
      _showErrorDialog("error");
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

  // pop up to let the user update the description
  void _showUpdateDescriptionDialog(String itemId, int index) {
    TextEditingController descriptionController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Description'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter new description:'),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(hintText: 'New Description'),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
          TextButton(
            child: const Text('Update'),
            onPressed: () {
              String newDescription = descriptionController.text.trim();
              if (newDescription.isNotEmpty) {
                _updateItemDescription(itemId, newDescription, index);
                Navigator.of(ctx).pop();
              }
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Items'),
          backgroundColor: const Color.fromARGB(122, 132, 202, 218)),
      // display some info about each item
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (ctx, index) {
                final item = _items[index];
                return ListTile(
                  title: Text(
                    item['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('NDC: ${item['ndc']}'),
                      Text('Manufacturer: ${item['manufacturer']}'),
                      Text('Package Size: ${item['packageSize']}'),
                      Text('Expiration Date: ${item['expirationDate']}'),
                      Text('Status: ${item['status']}'),
                      Text(
                        'Description: ${item['description'] ?? 'No description available'}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  // adding the icons
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          _deleteItem(item['id'].toString());
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          _showUpdateDescriptionDialog(
                              item['id'].toString(), index);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
