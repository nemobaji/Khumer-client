// screens/seat_map_screen.dart

import 'package:flutter/material.dart';

class SeatMapScreen extends StatelessWidget {
  final Map<String, dynamic> libraryItem;
  final int selectedCampus;

  const SeatMapScreen({super.key, required this.libraryItem, required this.selectedCampus});

  String get _campusName {
    return selectedCampus == 1 ? '국제캠퍼스' : '서울캠퍼스';
  }

  @override
  Widget build(BuildContext context) {
    // 열람실 정보
    final String roomName = libraryItem['name'] as String? ?? 'N/A';
    final int total = libraryItem['total'] as int? ?? 0;
    final int occupied = libraryItem['occupied'] as int? ?? 0;
    final int available = libraryItem['available'] as int? ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '$_campusName ${roomName}',
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
              child: _buildSeatMapLayout(total), // 좌석 배치도 시뮬레이션
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

  // 요약 정보를 표시하는 칩 위젯 (SeatMapScreen 클래스 내부에 정의)
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

  // 간단한 좌석 배치도 시뮬레이션 (SeatMapScreen 클래스 내부에 정의)
  Widget _buildSeatMapLayout(int totalSeats) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: List.generate(totalSeats, (index) {
        final seatNumber = index + 1;
        // 임의의 사용 상태
        final isOccupied = seatNumber % 10 == 0;
        final isReserved = seatNumber % 20 == 0;
        
        Color seatColor;
        if (isOccupied) {
          seatColor = Colors.red.shade700;
        } else if (isReserved) {
          seatColor = Colors.orange.shade700;
        } else {
          seatColor = Colors.green.shade700;
        }

        return GestureDetector(
          onTap: () {
            // 좌석 선택 기능 추가
            // print('Seat $seatNumber selected');
          },
          child: Container(
            width: 35,
            height: 35,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: seatColor,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white.withOpacity(0.5), width: 1), // 테두리 추가
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
}


