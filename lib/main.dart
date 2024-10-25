import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:chat_gpt_app/model.dart';

void main() {
  runApp(ChatGptApp());
}

class ChatGptApp extends StatefulWidget {
  ChatGptApp({super.key});

  @override
  State<ChatGptApp> createState() => _ChatGptAppState();
}

class _ChatGptAppState extends State<ChatGptApp> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _canSendMessage = false;

  ChatRoom _room = ChatRoom(
    chats: [],
    createdAt: DateTime.now(),
  );

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    try {
      // assets에서 api_key.txt 파일을 읽음
      String apiKey = await rootBundle.loadString('assets/api_key.txt');
      // 불필요한 공백 제거
      apiKey = apiKey.trim();

      // Gemini 초기화
      Gemini.init(apiKey: apiKey);
    } catch (e) {
      print("Error loading API key: $e");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text(
            "GPT",
            style: TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
        ),
        body: Stack(
          children: [
            if (_room.chats.isEmpty)
              Align(
                alignment: Alignment.center,
                child: Image.asset(
                  "assets/logo.png",
                  width: 40,
                  height: 40,
                ),
              ),

            ListView(
              padding: EdgeInsets.only(bottom: 100),
              children: [
                for (var chat in _room.chats)
                  chat.isMe
                      ? _buildMyChatBubble(chat)
                      : _buildGptChatBubble(chat),
              ],
            ),

            Align(
              alignment: Alignment.bottomCenter,
              child: _buildTextField(),
            ),
          ],
        ),
        backgroundColor: Colors.white,
      ),
    );
  }

  Widget _buildGptChatBubble(ChatMessage chat) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(
            left: 20,
            top: 5,
          ),
          child: Image.asset(
            "assets/logo.png",
            width: 20,
            height: 20,
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 300,
            ),
            margin: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 5,
              bottom: 40,
            ),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(chat.text),
          ),
        ),
      ],
    );
  }

  Widget _buildMyChatBubble(ChatMessage chat) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 250,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        margin: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: 20,
        ),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(chat.text),
      ),
    );
  }

  Widget _buildTextField() {
    return Container(
      margin: EdgeInsets.only(left: 16, right: 16, bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        onSubmitted: (text) {
          _sendMessage();
        },
        onChanged: (text) {
          setState(() {
            _canSendMessage = text.isNotEmpty;
          });
        },
        decoration: InputDecoration(
          hintText: "메시지",
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            vertical: 15,
            horizontal: 15,
          ),
          suffixIcon: IconButton(
            icon: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: _canSendMessage ? Colors.black : Colors.black12,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Icon(
                Icons.arrow_upward_rounded,
                color: Colors.white,
              ),
            ),
            onPressed: () {
              _sendMessage();
            },
          ),
        ),
        style: TextStyle(
          fontSize: 14,
        ),
      ),
    );
  }

  void _sendMessage() {
    _focusNode.unfocus();

    final ChatMessage chat = ChatMessage(
      isMe: true,
      text: _controller.text,
      sentAt: DateTime.now(),
    );

    setState(() {
      _room.chats.add(chat);
      _canSendMessage = false;
    });

    String question = _controller.text;
    question +=
        " 자 삼행시가 뭔지 알려줄게요. 삼행시는 맨 앞 글자로 시작하는 문장을 각각 만들어주는거야. 예를 들어, 플러터이면, '플'로 시작하는 문장을 적어주면 돼.";

    Gemini.instance.streamGenerateContent(question).listen((event) {
      print(event.output);

      setState(() {
        _room.chats.last.text += (event.output ?? "");
      });
    });

    _room.chats.add(
      ChatMessage(isMe: false, text: "", sentAt: DateTime.now()),
    );

    _controller.clear();
  }
}
