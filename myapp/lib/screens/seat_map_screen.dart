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

// 4. 기존 _buildSummaryChip은 그대로 사용 (StatefulWidget의 State 내부 메서드로 이동)
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
    
    // 좌석 정보가 있지만 서버에서 받은 데이터가 비어있는 경우 (사용 가능한 좌석 없음)
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
          // 데이터가 불분명하거나 서버에서 해당 좌석 번호를 보내지 않은 경우 (비어있음/예외 처리)
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
    // 열람실 정보
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
          // 상단 요약 정보
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

          // 좌석 배치도 영역
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
//   @override
//   Widget build(BuildContext context) {
//     // 열람실 정보
//     final String roomName = libraryItem['name'] as String? ?? 'N/A';
//     final int total = libraryItem['total'] as int? ?? 0;
//     final int occupied = libraryItem['occupied'] as int? ?? 0;
//     final int available = libraryItem['available'] as int? ?? 0;

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           '$_campusName ${roomName}',
//           style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.close),
//             onPressed: () => Navigator.of(context).pop(),
//           ),
//         ],
//       ),
//       body: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // 상단 요약 정보
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Row(
//               children: [
//                 _buildSummaryChip('총좌석', total, Colors.blue),
//                 const SizedBox(width: 8),
//                 _buildSummaryChip('사용중', occupied, Colors.red),
//                 const SizedBox(width: 8),
//                 _buildSummaryChip('사용가능', available, Colors.green),
//               ],
//             ),
//           ),
//           const Divider(height: 1),

//           // 좌석 배치도 영역
//           Expanded(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.all(16.0),
//               child: _buildSeatMapLayout(total), // 좌석 배치도 시뮬레이션
//             ),
//           ),
          
//           // 하단 버튼 추가
//           Container(
//             padding: const EdgeInsets.all(16.0),
//             width: double.infinity,
//             decoration: BoxDecoration(
//               color: Colors.white,
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.grey.withOpacity(0.5),
//                   blurRadius: 5,
//                   offset: const Offset(0, -3),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // 요약 정보를 표시하는 칩 위젯 (SeatMapScreen 클래스 내부에 정의)
//   Widget _buildSummaryChip(String title, int count, Color color) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: color),
//       ),
//       child: Text(
//         '$title $count 좌석',
//         style: TextStyle(
//           color: color,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//     );
//   }

//   // 간단한 좌석 배치도 시뮬레이션 (SeatMapScreen 클래스 내부에 정의)
//   Widget _buildSeatMapLayout(int totalSeats) {
//     return Wrap(
//       spacing: 8.0,
//       runSpacing: 8.0,
//       children: List.generate(totalSeats, (index) {
//         final seatNumber = index + 1;
//         // 임의의 사용 상태
//         final isOccupied = seatNumber % 10 == 0;
//         final isReserved = seatNumber % 20 == 0;
        
//         Color seatColor;
//         if (isOccupied) {
//           seatColor = Colors.red.shade700;
//         } else if (isReserved) {
//           seatColor = Colors.orange.shade700;
//         } else {
//           seatColor = Colors.green.shade700;
//         }

//         return GestureDetector(
//           onTap: () {
//             // 좌석 선택 기능 추가
//             // print('Seat $seatNumber selected');
//           },
//           child: Container(
//             width: 35,
//             height: 35,
//             alignment: Alignment.center,
//             decoration: BoxDecoration(
//               color: seatColor,
//               borderRadius: BorderRadius.circular(4),
//               border: Border.all(color: Colors.white.withOpacity(0.5), width: 1), // 테두리 추가
//             ),
//             child: Text(
//               '$seatNumber',
//               style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
//             ),
//           ),
//         );
//       }),
//     );
//   }
// }


