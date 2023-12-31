import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hello/login.dart';
import 'package:flutter_hello/painter_page.dart';
import 'package:flutter_hello/uploader.dart';
import 'package:flutter_hello/webrct.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'board.dart';
import 'board_list_view.dart';

import 'dart:io';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'CS Application'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  late String storedAccessToken;
  late String storedTel;
  bool isLoading = false;

  final List<Board> boards = [];

  final TextEditingController _messageController = TextEditingController();

  final picker = ImagePicker();
  List<XFile?> multiImage = []; // 갤러리에서 여러 장의 사진을 선택해서 저장할 변수
  List<XFile?> images = []; // 가져온 사진들을 보여주기 위한 변수

  Future<void> loadDataFromServer() async {
    // Set loading state to true
    setState(() {
      isLoading = true;
    });

    Map<String, dynamic> requestBody = {
      'noOfDisplay': 30,
      'tel': storedTel,
    };

    if (kDebugMode) {
      print('executing async getlist');
    }

    try{
      var response = await http.post(Uri.parse('http://10.100.203.62:8080/api/board/list'),
        headers: <String, String>{
          'Authorization': 'Bearer:$storedAccessToken',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'noOfDisplay': requestBody['noOfDisplay'].toString(),
          'tel': requestBody['tel'],
        },
      ).timeout(const Duration(seconds: 5));

      if(response.statusCode == 200){
        List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));
        boards.clear();
        for (var jsonBoard in jsonList) {
          // 밑에  setState()에서 UI가 새로 그려지니 여기는 없어도 될 듯합니다
          Board board = Board.fromJson(jsonBoard);
          boards.add(board);
        }
        if (kDebugMode) {
          print('Get list success : ${response.body}');
        }
      } else {
        if (kDebugMode) {
          print('Response body: ${response.body}, ${response.statusCode}');
        }
      }
    } catch (e) {
      if (e is TimeoutException) {
        if (kDebugMode) {
          print('Request timed out');
        }
      } else {
        if (kDebugMode) {
          print('Error loading data: $e');
        }
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> loadUserInfoFromSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    storedAccessToken = prefs.getString('accessToken') ?? '';
    storedTel = prefs.getString('tel') ?? '';
    if (kDebugMode) {
      print("storedAccessToken : $storedAccessToken");
    }
  }

  void moveToLogin() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage(title: "Login")),
    );

    if (kDebugMode) {
      print("result $result");
    }
    if (result == true) {
      await loadUserInfoFromSharedPreferences();
      if (storedAccessToken.isNotEmpty) {
        if (kDebugMode) {
          print("Reload data after login: $storedAccessToken");
        }
        loadDataFromServer();
      }
    }
  }

  void sendMessage() async {

    Map<String, dynamic> requestBody = {
      'customerTel': storedTel,
      'tel': storedTel,
      'content' : 'TEXT',
      'message' : _messageController.text,
    };

    try {
      var response = await http.post(
        Uri.parse('http://10.100.203.62:8080/api/board/create'),
        headers: <String, String>{
          'Authorization': 'Bearer:$storedAccessToken',
        },
        body: {
          'customerTel': requestBody['customerTel'].toString(),
          'tel': requestBody['tel'].toString(),
          'message': requestBody['message'].toString(),
          'content': requestBody['content'].toString()
        },
      );
      print(response.body);
      loadDataFromServer();
    }
    catch(e){
      print(e);
    }
  }

  // Add this function to reload data when returning from WebrtcPage
  void returnFromOtherPage() {
    loadDataFromServer();
  }

  void _moveToWebrtc() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebrtcPage(title: "Webrtc"),
      ),
    );

    // This code will be executed when returning from WebrtcPage
    returnFromOtherPage();
  }

  void _moveToPainterPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PainterPage(title: "Painter"),
      ),
    );

    // This code will be executed when returning from WebrtcPage
    returnFromOtherPage();
  }

  void _pickImage() async {
    XFile? image = await picker.pickImage(source: ImageSource.camera);
    print('image file path : ${image?.path}');

    if (image != null) {
      var uploader = Uploader("사진파일", storedAccessToken, storedTel, "IMAGE", image.path);
      try {
        await uploader.upload();
        print('Upload successful');
        // Proceed to load data from the server after a successful upload
        loadDataFromServer();
      } catch (e) {
        print('Upload failed: $e');
        // Handle the error, perhaps show a user-friendly message
      }
    }
  }

  void _showFloatingMenu(BuildContext context) async {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(context)!.context.findRenderObject() as RenderBox;

    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset(0, button.size.height), ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    await showMenu(
      context: context,
      position: position,
      items: [
        PopupMenuItem(
          child: const Text('사진 전송'),
          onTap: () {
            _pickImage();
          },
        ),
        PopupMenuItem(
          child: const Text('그림 그려 전송'),
          onTap: () {
            _moveToPainterPage();
          },
        ),
        // Add more items as needed
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home : Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
        ),
        body: Column(
          children: [
            Expanded(
              child: Center(
                child: isLoading
                    ? const CircularProgressIndicator()
                    : BoardListView(boards: boards),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      _showFloatingMenu(context);
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(0.0), // Set the border radius to 0 for a rectangular shape
                      ),
                    ),
                    child: const Icon(Icons.more_vert_outlined),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        labelText: 'Message',
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: sendMessage,
                    child: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomAppBar(
          child : Row (
            children: [
              ElevatedButton(
                  onPressed: moveToLogin,
                  child: const Icon(Icons.login)),
              ElevatedButton(
                  onPressed: _moveToWebrtc,
                  child: const Text('webrtc')
              ),
            ],
          )
        ),
      ),
    );
  }
}



