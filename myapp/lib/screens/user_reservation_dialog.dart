// screens/user_reservation_dialog.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UserReservationDialog extends StatefulWidget {
  final int userId;
  final String userName;

  const UserReservationDialog({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<UserReservationDialog> createState() => _UserReservationDialogState();
}

class _UserReservationDialogState extends State<UserReservationDialog> {
  late Future<List<Map<String, dynamic>>> _reservationsFuture;

  @override
  void initState() {
    super.initState();
    _reservationsFuture = _fetchUserReservations();
  }

  String _convertCodeToLocationName(String code) {
    const locationMap = {
      '1': '1F 제1열람실',
      '2': '1F 집중열람실',
      '3': '2F 제2열람실',
      '4': '2F 제3열람실',
      '5': '4F 제4열람실',
      '12': '4F 제4열람실(대학원)',
      '8': '1F 제1열람실(국제)',
      '10': '1F 벗터',
      '11': '2F 혜윰',
      '9': '2F 제2열람실(국제)',
    };
    return locationMap[code] ?? '알 수 없는 열람실 (코드: $code)';
  }

  Future<List<Map<String, dynamic>>> _fetchUserReservations() async {
    try {
      final url = Uri.parse("http://localhost:3000/users?userId=${widget.userId}");
      final res = await http.get(url);
    
      if (res.statusCode == 200) {
        final dynamic rawData = jsonDecode(res.body);
        
        if (rawData is List) {
          return rawData.cast<Map<String, dynamic>>();
        } 
      } else {
        debugPrint("HTTP request failed with status: ${res.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching user reservations: $e");
    }
    
    return [];
  }

  Future<void> _cancelReservation(int seatId, String locationCode) async {
    final url = Uri.parse("http://localhost:3000/seats");
    
    final bodyData = jsonEncode({
      'seatId': seatId,
      'userId': widget.userId,
      'location': locationCode,
    });

    try {
      final res = await http.delete(
        url,
        headers: {"Content-Type": "application/json"},
        body: bodyData, 
      );

      if (mounted) {
        if (res.statusCode == 200 || res.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("좌석 반납이 완료되었습니다!"),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {
            _reservationsFuture = _fetchUserReservations();
          });
        } else {
          final errorBody = jsonDecode(res.body);
          final errorMsg = errorBody['message'] ?? '반납에 실패했습니다. (코드: ${res.statusCode})';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("네트워크 오류로 반납에 실패했습니다."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: const EdgeInsets.only(left: 24, right: 24, bottom: 0),
    
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${widget.userName}님의 예약 현황',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: colorScheme.primary,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
      
      content: SizedBox(
        width: double.maxFinite,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _reservationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              );
            } else if (snapshot.hasError) {
              return Text('데이터를 불러오는데 실패했습니다: ${snapshot.error}');
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 30.0),
                child: Text('현재 예약된 좌석이 없습니다.', textAlign: TextAlign.center),
              );
            }

            final reservations = snapshot.data!;

            return ListView.builder(
              shrinkWrap: true,
              itemCount: reservations.length,
              itemBuilder: (context, index) {
                final item = reservations[index];
                final seatNumberString = item['name']?.toString() ?? '';
                final seatNumber = int.tryParse(seatNumberString);
                final locationCode = item['location']?.toString() ?? '코드 없음';
                
                final locationName = _convertCodeToLocationName(locationCode); 

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.chair_alt, color: colorScheme.primary, size: 30), // 좌석 아이콘
                    title: Text(
                      '$seatNumber번 좌석', 
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      locationName,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700, // 강렬한 취소 버튼 색상
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        if (seatNumber != null) {
                          _cancelReservation(seatNumber, locationCode);
                        } else {
                          debugPrint("캔슬 전송 못함: seatNumber가 유효하지 않음");
                        }
                      },
                      child: const Text('예약취소'),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      actionsPadding: const EdgeInsets.all(16),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            '닫기',
            style: TextStyle(color: colorScheme.secondary, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}