// screens/user_info_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import './library_screen.dart'; // 두 번째 화면 임포트

// 서버의 기본 URL을 상수로 정의 (필요하다면 실제 서버 주소로 변경)
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

  // 데이터 유효성 검사
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

  // 서버로 정보를 전송하고 다음 화면으로 이동하는 공통 로직
  Future<void> _sendData(String endpoint, String successMessage) async {
    if (!_validateInput()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse('$_baseUrl/$endpoint'); // 예: http://localhost:3000/register
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
        // 서버 응답 바디를 파싱합니다.
        final responseData = json.decode(response.body) as Map<String, dynamic>;
        
        // **수정된 로직: 서버 응답에서 'id'와 'name'을 추출합니다.**
        
        // 고유 ID 추출 및 타입 변환
        int userId; 

        // 널 체크를 통해 int.tryParse() 결과를 userId에 안전하게 할당
        final parsedId = responseData['id'] is int 
                         ? responseData['id'] 
                         : int.tryParse(responseData['id'].toString());

        // 2. ID가 널이 아니면 할당하고, 널이면 런타임 오류가 날 수 있는 상황입니다.
        //    가장 간단하게는 이전에 만든 `parsedId`를 사용해야 합니다.
        
        if (parsedId == null) {
            // ID가 필수적이라면 이 오류 처리는 반드시 유지해야 합니다.
            setState(() {
                _errorMessage = '사용자 ID를 서버에서 받지 못했습니다.';
            });
            return;
        }
        userId = parsedId;

        // 사용자 이름 추출
        final String userName = responseData.containsKey('name') 
                                ? responseData['name'].toString() 
                                : '사용자'; // name이 없으면 기본값 설정
        
        // 사용자에게 성공 메시지와 이름/ID를 보여주고 화면 이동
        String displayMessage = '$successMessage';
        
        displayMessage += ' (ID: $userId)';
        
        // 이름 정보를 메시지에 추가
        displayMessage = '${userName}님, $displayMessage';


        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(displayMessage)),
        );
        
        // LibraryScreen으로 이동
        // 실제 앱에서는 userId 등을 LibraryScreen에 전달하여 상태 관리해야 할 수 있습니다.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (ctx) =>  LibraryScreen(
              userId: userId,
              userName: userName
            ),
          ),
        );
      } else {
        // 서버 응답 오류 처리
        setState(() {
          // 서버에서 구체적인 오류 메시지(예: responseData['message'])가 온다면 그것을 사용합니다.
          // 오류 발생 시에도 응답 바디를 디코딩하여 메시지 추출을 시도합니다.
          String? serverMessage;
          try {
             final errorData = json.decode(response.body) as Map<String, dynamic>;
             serverMessage = errorData['message']?.toString();
          } catch (_) {
            // JSON 파싱 실패 시
          }
          
          _errorMessage = '서버 통신 오류 (${response.statusCode}): ${serverMessage ?? '처리 실패'}';
        });
      }
    } catch (e) {
      // 네트워크 오류 처리
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('도서관 서비스 시작'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '서비스 이용을 위해 정보를 입력해주세요.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // 이름 입력 필드
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '이름',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 15),
            
            // 이메일 입력 필드
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: '이메일',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 30),
            
            // 오류 메시지 표시
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  '오류: $_errorMessage',
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            
            // 로딩 인디케이터
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              // 버튼 그룹
              Column(
                children: [
                  // 1. 처음 사용자 (회원가입) 버튼
                  ElevatedButton.icon(
                    onPressed: () => _sendData('create', '회원가입이 완료되었습니다.'),
                    icon: const Icon(Icons.person_add),
                    label: const Text('처음 사용자 (새로 등록)'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 15),
                  
                  // 2. 기존 사용자 (로그인) 버튼
                  OutlinedButton.icon(
                    onPressed: () => _sendData('login', '로그인이 완료되었습니다.'),
                    icon: const Icon(Icons.login),
                    label: const Text('기존 사용자 (로그인)'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}