import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ReturnRequestsScreen extends StatefulWidget {
  const ReturnRequestsScreen({super.key});

  @override
  State<ReturnRequestsScreen> createState() {
    return _ReturnRequestsScreenState();
  }
}

class _ReturnRequestsScreenState extends State<ReturnRequestsScreen> {
  final _storage = const FlutterSecureStorage();
  List<dynamic> _returnRequests = [];
  List<dynamic> _wholesalers = [];
  late VoidCallback _listener;

  @override
  void initState() {
    super.initState();
    _listener = () {
      _fetchReturnRequests();
    };
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ModalRoute.of(context)!
          .addLocalHistoryEntry(LocalHistoryEntry(onRemove: _listener));
    });
  }

  // update the page each time the screen en navigated into
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchReturnRequests();
  }

  @override
  void dispose() {
    // clean listener when this widget is disposed
    ModalRoute.of(context)!
        .removeLocalHistoryEntry(LocalHistoryEntry(onRemove: _listener));
    super.dispose();
  }

  Future<void> _fetchReturnRequests() async {
    final token = await _storage.read(key: 'token');
    final pharmacyId = await _storage.read(key: 'pharmacy_id');
    // fetches the wholeseller name
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
        _wholesalers = data;
      });
    }
    // fetches all the return requests to display, PS. maximum 15 request
    final url =
        'https://portal-test.rxmaxreturns.com/rxmax/pharmacies/$pharmacyId/returnrequests';

    final responseReq = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (responseReq.statusCode == 200) {
      final List<dynamic> data = jsonDecode(responseReq.body)['content'];
      setState(() {
        _returnRequests = data;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Return Requests'),
          backgroundColor: const Color.fromARGB(122, 132, 202, 218)),
      body: ListView.builder(
        // iterate over each request and display them
        itemCount: _returnRequests.length,
        itemBuilder: (context, index) {
          final request = _returnRequests[index]['returnRequest'];
          final status = request['returnRequestStatus'];
          final serviceType = request['serviceType'];
          final wholesalerName =
              _wholesalers.isNotEmpty ? _wholesalers[0]['name'] : 'Unknown';
          final itemsCount = _returnRequests[index]["numberOfItems"];

          return ListTile(
            title: Text('ID: ${request['id']}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Created At: ${_formatDateTime(request['createdAt'])}'),
                Text('Status: $status'),
                Text('Service Type: $serviceType'),
                if (wholesalerName != null) Text('Wholesaler: $wholesalerName'),
              ],
            ),
            // button that displays the items
            trailing: ElevatedButton(
              onPressed: () {
                if (itemsCount > 0) {
                  Navigator.pushNamed(context, '/items',
                      arguments: request['id']);
                }
              },
              child: Text('Items: $itemsCount'),
            ),
          );
        },
      ),
      //button for creating new return requests
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/createReturnRequest');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // convert time to readable form
  String _formatDateTime(int timestamp) {
    return DateTime.fromMillisecondsSinceEpoch(timestamp).toString();
  }
}
