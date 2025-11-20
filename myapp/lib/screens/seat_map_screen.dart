// screens/seat_map_screen.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SeatMapScreen extends StatefulWidget {
  final Map<String, dynamic> libraryItem;
  final int selectedCampus;
  final int userId;
  final String location;

  const SeatMapScreen({
    super.key, 
    required this.libraryItem, 
    required this.selectedCampus, 
    required this.userId,
    required this.location
  });

  String get _campusName {
    return selectedCampus == 1 ? '국제캠퍼스' : '서울캠퍼스';
  }

  @override
  State<SeatMapScreen> createState() => _SeatMapScreenState();
}

class _SeatMapScreenState extends State<SeatMapScreen> {
  Set<int> _occupiedSeats = {};
  Set<int> _availableSeats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSeatStatus();
  }
  
  Future<void> _fetchSeatStatus() async {
    final String roomName = widget.libraryItem['name'] as String? ?? '0';
    String index = changeIndex(roomName);

    try {
      final uri = Uri.parse('http://localhost:3000/seats/$index');
      final res = await http.get(uri);

      if (res.statusCode == 200) {
        final dynamic rawData = jsonDecode(res.body);
        final Map<String, dynamic> seatData = rawData[0];
        final List<dynamic> occupiedList = seatData['occupied'] as List<dynamic>? ?? [];
        final List<dynamic> availableList = seatData['available'] as List<dynamic>? ?? [];

        setState(() {
          _occupiedSeats = occupiedList.cast<int>().toSet();
          _availableSeats = availableList.cast<int>().toSet();
          _isLoading = false;
        }); 
      } else {
        setState(() { _isLoading = false; });
        debugPrint('Error: Server response format unexpected.');
      }
    } catch(e) {
      setState(() { _isLoading = false; });
      debugPrint('Error fetching seat data: $e');
    }
  }

  Future<void> _reserveSeat(int seatNumber, int userId, String location) async {
    final uri = Uri.parse("http://localhost:3000/seats");
    String index = changeIndex(location);
    final bodyData = jsonEncode({
      'seatId': seatNumber,
      'userId': userId, 
      'location': index,
    });

    try {
      final res = await http.post(
        uri, 
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: bodyData
      );
      if(res.statusCode == 200 || res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${seatNumber}번 좌석이 예약되었습니다.', style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.blue.shade700,
            duration: const Duration(seconds: 2)
          )
        );
      }
    } catch(e) {
      debugPrint('$e');
    }
  }

  Widget _buildSummaryChip(String title, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        '$title $count 좌석',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

Widget _buildSeatMapLayout(int totalSeats) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (totalSeats == 0) {
      return const Center(child: Text('총 좌석 정보가 없습니다.'));
    }
    
    if (_occupiedSeats.isEmpty && _availableSeats.isEmpty) {
        return const Center(child: Text('좌석 정보를 불러올 수 없습니다.'));
    }

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: List.generate(totalSeats, (index) {
        final seatNumber = index + 1;
        
        // ✨ 상태 변수 (_occupiedSeats, _availableSeats)를 참조하여 좌석 상태 결정
        final bool isOccupied = _occupiedSeats.contains(seatNumber);
        final bool isAvailable = _availableSeats.contains(seatNumber);
        
        Color seatColor;
        
        if (isOccupied) {
          seatColor = Colors.red.shade700; // 사용 중
        } else if (isAvailable) {
          seatColor = Colors.green.shade700; // 이용 가능
        } else {
          seatColor = Colors.grey.shade400; 
        }

        return GestureDetector(
          onTap: () {
            if(isOccupied) {
              _reserveSeat(seatNumber, widget.userId, widget.location);
            } else if (isAvailable) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('빈 좌석입니다.', style: TextStyle(color: Colors.black)),
                  backgroundColor: Colors.yellow.shade200,
                  duration: const Duration(seconds: 2),
                )
              );
            }
          },
          child: Container(
            width: 35,
            height: 35,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: seatColor,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
            ),
            child: Text(
              '$seatNumber',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }),
    );
  }

@override
  Widget build(BuildContext context) {
    final String roomName = widget.libraryItem['name'] as String? ?? 'N/A';
    final int total = widget.libraryItem['total'] as int? ?? 0;
    final int occupied = widget.libraryItem['occupied'] as int? ?? 0;
    final int available = widget.libraryItem['available'] as int? ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget._campusName} ${roomName}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                _buildSummaryChip('총좌석', total, Colors.blue),
                const SizedBox(width: 8),
                _buildSummaryChip('사용중', occupied, Colors.red),
                const SizedBox(width: 8),
                _buildSummaryChip('사용가능', available, Colors.green),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              // ✨ 로딩 상태에 따라 다른 위젯 표시
              child: _buildSeatMapLayout(total),
            ),
          ),
          
          // 하단 버튼 추가
          Container(
            padding: const EdgeInsets.all(16.0),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  blurRadius: 5,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  String changeIndex(String roomName) {
    String index = '0';
    switch(roomName) {
      case '1F 제1열람실':
        index = '1';
        break;
      case '1F 집중열람실':
        index = '2';
        break;
      case '2F 제2열람실':
        index = '3';
        break;
      case '2F 제3열람실':
        index = '4';
        break;
      case '4F 제4열람실':
        index = '5';
        break;
      case '4F 제4열람실(대학원)':
        index = '12';
        break;
      case '1F 제1열람실(국제)':
        index = '8';
        break;
      case '1F 벗터':
        index = '10';
        break;
      case '2F 혜윰':
        index = '11';
        break;
      case '2F 제2열람실(국제)':
        index = '9';
        break;
    }
    return index;
  }

}