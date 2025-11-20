// screens/user_info_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import './library_screen.dart'; 

const String _baseUrl = 'http://localhost:3000/users';

class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({super.key});

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // 데이터 유효성 검사 (로직 유지)
  bool _validateInput() {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      setState(() {
        _errorMessage = '이름과 이메일을 모두 입력해주세요.';
      });
      return false;
    }
    setState(() {
      _errorMessage = null;
    });
    return true;
  }

  // 서버로 정보를 전송하고 다음 화면으로 이동하는 공통 로직 (로직 유지)
  Future<void> _sendData(String endpoint, String successMessage) async {
    if (!_validateInput()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse('$_baseUrl/$endpoint');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': _nameController.text,
          'email': _emailController.text,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body) as Map<String, dynamic>;
        
        int userId; 
        final parsedId = responseData['id'] is int 
                         ? responseData['id'] 
                         : int.tryParse(responseData['id'].toString());

        if (parsedId == null) {
            setState(() {
                _errorMessage = '사용자 ID를 서버에서 받지 못했습니다.';
            });
            return;
        }
        userId = parsedId;

        final String userName = responseData.containsKey('name') 
                                ? responseData['name'].toString() 
                                : '사용자'; 

        String displayMessage = '${userName}님, $successMessage (ID: $userId)';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(displayMessage)),
        );
        
        // LibraryScreen으로 이동 (userId와 userName 전달)
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (ctx) =>  LibraryScreen(
              userId: userId,
              userName: userName
            ),
          ),
        );
      } else {
        // 서버 오류 처리
        setState(() {
          String? serverMessage;
          try {
             final errorData = json.decode(response.body) as Map<String, dynamic>;
             serverMessage = errorData['message']?.toString();
          } catch (_) {}
          
          _errorMessage = '서버 통신 오류 (${response.statusCode}): ${serverMessage ?? '처리 실패'}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '네트워크 오류가 발생했습니다: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme customColorScheme = ColorScheme.fromSeed(
      seedColor: const Color.fromARGB(255, 245, 16, 0), 
      brightness: Brightness.light,
    );
    final colorScheme = customColorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background, 
      appBar: AppBar(
        title: const Text(
          '쿠머',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: colorScheme.primary, 
        foregroundColor: colorScheme.onPrimary, 
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '환영합니다!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '계속하려면 이름과 이메일을 입력해주세요.',
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: '사용자 이름',
                  prefixIcon: const Icon(Icons.person_outline),
                  filled: true,
                  fillColor: colorScheme.surfaceVariant.withOpacity(0.2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none, 
                  ),
                ),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: '이메일 주소',
                  prefixIcon: const Icon(Icons.email_outlined),
                  filled: true,
                  fillColor: colorScheme.surfaceVariant.withOpacity(0.2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 40),
              
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    '❌ $_errorMessage',
                    style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              
              _isLoading
                  ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
                  : Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _sendData('create', '회원가입이 완료되었습니다.'),
                          icon: const Icon(Icons.app_registration),
                          label: const Text('새로 등록하고 시작하기'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 55),
                            backgroundColor: colorScheme.primary, 
                            foregroundColor: colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        OutlinedButton.icon(
                          onPressed: () => _sendData('login', '로그인이 완료되었습니다.'),
                          icon: const Icon(Icons.login),
                          label: const Text('기존 사용자 로그인'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 55),
                            side: BorderSide(color: colorScheme.primary, width: 1.5), 
                            foregroundColor: colorScheme.primary, 
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}