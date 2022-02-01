import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final SmsQuery _query = SmsQuery();
  List<SmsMessage> _messages = [];

  @override
  void initState() {
    Permission.sms.request();
    super.initState();
  }

  Future<List<SmsMessage>> getAllSMS() async => _query.getAllSms;

  bool isLoading = false;

  Future<void> generateReport() async {
    setState(() => isLoading = true);
    var excel = Excel.createExcel();

    Sheet mSheet = excel['mSMS'];

    for (int i = 0; i < _messages.length; i++) {
      var cell = mSheet.cell(CellIndex.indexByString('A${i + 1}'));
      cell.value = _messages[i].sender;
    }

    var onValue = excel.encode();

    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;

    File(join('$appDocPath/mysms.xlsx'))
      ..createSync(recursive: true)
      ..writeAsBytesSync(onValue ?? []);

    setState(() => isLoading = false);
    await Share.shareFiles(['$appDocPath/mysms.xlsx'], text: 'My SMS');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('SMS Inbox'),
        ),
        body: FutureBuilder<List<SmsMessage>>(
          future: getAllSMS(),
          builder: (_, snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.waiting:
                return const Center(child: CircularProgressIndicator());
              default:
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  _messages = snapshot.data ?? [];
                  return ListView.builder(
                    itemCount: _messages.length,
                    itemBuilder: (_, index) {
                      final sms = _messages[index];
                      return ListTile(
                        title: Text(sms.sender ?? 'UNKNOWN SENDER'),
                        subtitle: Text(sms.body ?? 'EMPTY BODY'),
                      );
                    },
                  );
                }
            }
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => generateReport(),
          child: isLoading
              ? const CircularProgressIndicator()
              : const Icon(Icons.send),
        ),
      ),
    );
  }
}
