import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool downloading = false;
  var progressString = "0%";
  String downloadStart = "...جاري التنزيل";

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  String downloadableUrl;

  String filePath;
  var error = '';

  Future<void> requestPermission() async {
    try {
      final status = await Permission.storage.request();
      PermissionStatus _permissionStatus = status;
      if (_permissionStatus.isGranted) {
        _openFile(downloadableUrl);
      } else if (_permissionStatus.isDenied) {
        _showError('من فضلك اسمح بالدخول للمساحة الداخلية من اعدادت الجهاز');
      } else if (_permissionStatus.isPermanentlyDenied) {
        _showError('من فضلك اسمح بالدخول للمساحة الداخلية من اعدادت الجهاز');
        AppSettings.openAppSettings();
      }
    } on PlatformException catch (e) {
      if (e.code == 'PERMISSION_DENIED') {
        error = 'من فضلك اسمح للمساحة الداخلية بالدخول من اعدادت الجهاز';
      } else if (e.code == 'PERMISSION_DENIED_NEVER_ASK') {
        error =
            'Permission denied - please ask the user to enable it from the app settings';
      }
      if (Platform.isIOS)
        _showError('من فضلك اسمح للمساحة الداخلية بالدخول من اعدادت الجهاز');
    } catch (_) {
      if (Platform.isIOS)
        _showError('من فضلك اسمح للمساحة الداخلية بالدخول من اعدادت الجهاز');

      return;
    }
  }

  Future<void> downloadFile(String url) async {
    Dio dio = Dio();
    setState(() {
      progressString = "0%";
      downloadStart = "...جاري التنزيل";
      downloading = true;
      _isDownloadContainerVisible = true;
    });
    try {
      await dio.download(url, filePath, onReceiveProgress: (rec, total) {
        print("Rec: $rec , Total: $total");
        setState(() {
          progressString = ((rec / total) * 100).toStringAsFixed(0) + "%";
        });
      });
    } catch (e) {
      print(e);
    }

    setState(() {
      downloading = false;
      progressString = "";
      downloadStart = "";
      isBtnVisible = true;
    });
    print("Download completed");
  }

  void _openFile(String url) async {
    var dir;
    if (Platform.isAndroid) {
      dir = (await getExternalStorageDirectory()).path;
    } else {
      dir = (await getApplicationDocumentsDirectory()).path;
    }
    filePath = "$dir/${url.substring(url.lastIndexOf('/') + 1)}";
    print("file path $filePath");
    File file = new File(filePath);
    var isExist = await file.exists();
    if (isExist) {
      print('file exists----------');
      await OpenFile.open(filePath);
      setState(() {
        _isDownloadContainerVisible = false;
        isBtnVisible = false;
      });
    } else {
      print('file does not exist----------');
      downloadFile(url);
    }
  }

  void _showError(String error) {
    _scaffoldKey.currentState.hideCurrentSnackBar();
    _scaffoldKey.currentState.showSnackBar(
      SnackBar(
        content: Text(
          error,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  double progress = 0;
  bool isBtnVisible = false;
  var _isDownloadContainerVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You have pushed the button this many times:',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: () {
        setState(() {
          _isDownloadContainerVisible = false;
        });
        print(filePath);
        _openFile(
            'https://drive.google.com/uc?export=download&id=1J0nmYzjxCz-Tks3k9uEFADQ-un3kJLli');
      }),
    );
  }
}
