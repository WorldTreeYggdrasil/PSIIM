import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SubmitView extends StatefulWidget {
  final String accessToken;

  SubmitView({required this.accessToken});

  @override
  _SubmitViewState createState() => _SubmitViewState();
}

class _SubmitViewState extends State<SubmitView> {
  late MobileScannerController controller;
  bool isScanning = false;

  Future<void> sendAchievement(int monumentId, int userId) async {
    var url = Uri.parse(
        'https://psiim-82a14bc94a7d.herokuapp.com/api/achievements/achieve');
    var response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer ${widget.accessToken}',
      },
      body: jsonEncode(<String, dynamic>{
        'lon': '',
        'lat': '',
        'photo': '',
        'monumentId': monumentId,
        'userId': userId,
      }),
    );

    if (response.statusCode == 200) {
      print('Achievement sent successfully');
    } else {
      print('Failed to send achievement: ${response.statusCode}');
    }
  }

  Future<int> getUserId(String accessToken) async {
    var url = Uri.parse('http://192.168.1.2:8080/api/user');
    var response = await http.get(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      return data['id'];
    } else {
      throw Exception('Failed to get user ID');
    }
  }

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController();
    controller.start();

    controller.barcodes.listen((barcode) {
      if (isScanning) {
        String displayvalue = barcode.raw.toString();
        var match = RegExp(r'displayValue: (\d+)').firstMatch(displayvalue);
        String extractedNumber = '';
        if (match != null) {
          extractedNumber = match.group(1) ?? '';
        }
        int extractedNumberInt = int.parse(extractedNumber);
        print('Scanned barcode: $displayvalue');
        isScanning = false;
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Scan Result'),
              content: Text(
                  'Scanned barcode: $displayvalue\nExtracted number: $extractedNumber'),
              actions: <Widget>[
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                    getUserId(widget.accessToken).then((userId) {
                      sendAchievement(extractedNumberInt, userId);
                    });
                  },
                ),
              ],
            );
          },
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          MobileScanner(controller: controller),
          Positioned(
            top: 60.0,
            left: 40.0,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Icons.arrow_back),
              color: Colors.blue,
            ),
          ),
          Positioned(
            bottom: 20.0,
            left: MediaQuery.of(context).size.width / 2 - 28,
            child: FloatingActionButton(
              onPressed: () => setState(() {
                isScanning = true;
              }),
              child: Icon(Icons.camera),
            ),
          ),
        ],
      ),
    );
  }
}
