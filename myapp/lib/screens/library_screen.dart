// screens/library_screen.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import '../screens/seat_map_screen.dart'; 
import 'package:http/http.dart' as http;

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  // 캠퍼스 탭 상태 관리: 0 = 서울캠퍼스, 1 = 국제캠퍼스
  int _selectedCampus = 0;

  @override
  void initState() {
    super.initState();
    fetchSeoulData();
  }

  // 테이블 데이터 예시 (기능은 유지)
  List<Map<String, dynamic>> _seoulData = [
    // 서울캠퍼스 데이터 유지
    {'name': '1F 제1열람실', 'total': 202, 'occupied': 49, 'available': 361, 'time': '00:00~ 24:00', 'usage': 0.12, 'extra': '24'},
    {'name': '1F 집중열람실', 'total': 46, 'occupied': 50, 'available': 102, 'time': '06:00~ 24:00', 'usage': 0.33, 'extra': ''},
    {'name': '2F 제2열람실', 'total': 315, 'occupied': 25, 'available': 163, 'time': '06:00~ 24:00', 'usage': 0.13, 'extra': '컴퓨터'},
    {'name': '2F 제3열람실', 'total': 151, 'occupied': 17, 'available': 309, 'time': '06:00~ 24:00', 'usage': 0.05, 'extra': '컴퓨터'},
    {'name': '4F 제4열람실', 'total': 137, 'occupied': 17, 'available': 309, 'time': '06:00~ 24:00', 'usage': 0.05, 'extra': ''},
    {'name': '4F 제4열람실(대학원)', 'total': 12, 'occupied': 17, 'available': 309, 'time': '06:00~ 24:00', 'usage': 0.05, 'extra': ''},
  ];

  List<Map<String, dynamic>> _internationalData = [
    // 국제캠퍼스 데이터 유지
    {'name': '1F 제1열람실(국제)', 'total': 410, 'occupied': 10, 'available': 190, 'time': '00:00~ 24:00', 'usage': 0.05, 'extra': '컴퓨터'},
    {'name': '1F 벗터', 'total': 152, 'occupied': 30, 'available': 70, 'time': '06:00~ 24:00', 'usage': 0.30, 'extra': '컴퓨터'},
    {'name': '1F 혜윰', 'total': 188, 'occupied': 30, 'available': 70, 'time': '06:00~ 24:00', 'usage': 0.30, 'extra': '컴퓨터'},
    {'name': '2F 제2열람실(국제)', 'total': 326, 'occupied': 30, 'available': 70, 'time': '06:00~ 24:00', 'usage': 0.30, 'extra': '컴퓨터'},
  ];
  
  void convertServerDataToSeoul(List<Map<String, dynamic>> data) {
    data.forEach((item) {
      final int occupied = item['occupied'];
      final int available = item['available'];
      final int total = occupied + available;
      final String location = item['name'];
    
      switch(location) {
        case '1':
          _seoulData[0]['total'] = total;
          _seoulData[0]['occupied'] = occupied;
          _seoulData[0]['available'] = available;
          _seoulData[0]['usage'] = total > 0 ? occupied / total : 0.0;
          break;
        case '2':
          _seoulData[1]['total'] = total;
          _seoulData[1]['occupied'] = occupied;
          _seoulData[1]['available'] = available;
          _seoulData[1]['usage'] = total > 0 ? occupied / total : 0.0;
          break;
        case '3':
          _seoulData[2]['total'] = total;
          _seoulData[2]['occupied'] = occupied;
          _seoulData[2]['available'] = available;
          _seoulData[2]['usage'] = total > 0 ? occupied / total : 0.0;
          break;
        case '4':
          _seoulData[3]['total'] = total;
          _seoulData[3]['occupied'] = occupied;
          _seoulData[3]['available'] = available;
          _seoulData[3]['usage'] = total > 0 ? occupied / total : 0.0;
          break;
        case '5':
          _seoulData[4]['total'] = total;
          _seoulData[4]['occupied'] = occupied;
          _seoulData[4]['available'] = available;
          _seoulData[4]['usage'] = total > 0 ? occupied / total : 0.0;
          break;
        case '12':
          _seoulData[5]['total'] = total;
          _seoulData[5]['occupied'] = occupied;
          _seoulData[5]['available'] = available;
          _seoulData[5]['usage'] = total > 0 ? occupied / total : 0.0;
          break;
      }
    });
  }

  void convertServerDataToInternational(List<Map<String, dynamic>> data) {
    data.forEach((item) {
      final int occupied = item['occupied'];
      final int available = item['available'];
      final int total = occupied + available;
      final String location = item['name'];
    
      switch(location) {
        case '8':
          _internationalData[0]['total'] = total;
          _internationalData[0]['occupied'] = occupied;
          _internationalData[0]['available'] = available;
          _internationalData[0]['usage'] = total > 0 ? occupied / total : 0.0;
          break;
        case '9':
          _internationalData[3]['total'] = total;
          _internationalData[3]['occupied'] = occupied;
          _internationalData[3]['available'] = available;
          _internationalData[3]['usage'] = total > 0 ? occupied / total : 0.0;
          break;
        case '10':
          _internationalData[1]['total'] = total;
          _internationalData[1]['occupied'] = occupied;
          _internationalData[1]['available'] = available;
          _internationalData[1]['usage'] = total > 0 ? occupied / total : 0.0;
          break;
        case '11':
          _internationalData[2]['total'] = total;
          _internationalData[2]['occupied'] = occupied;
          _internationalData[2]['available'] = available;
          _internationalData[2]['usage'] = total > 0 ? occupied / total : 0.0;
          break;
      }
    });
  }

  Future<void> fetchSeoulData() async {
    final res = await http.get(Uri.parse("http://localhost:3000/seats"));
    final dynamic data = jsonDecode(res.body);

    if (data is List) {
      final List<Map<String, dynamic>> json = data
          .cast<Map<String, dynamic>>()
          .toList();

      setState(() {
        convertServerDataToSeoul(json);
      });
    } else {
        // 응답이 리스트가 아닐 경우 오류 처리
        throw Exception('Server response is not a list.');
    }
  }

  Future<void> fetchInternationalData() async {
    final res = await http.get(Uri.parse("http://localhost:3000/seats"));
    final dynamic data = jsonDecode(res.body);

    if (data is List) {
      final List<Map<String, dynamic>> json = data
          .cast<Map<String, dynamic>>()
          .toList();

      setState(() {
        convertServerDataToInternational(json);
      });
    } else {
        // 응답이 리스트가 아닐 경우 오류 처리
        throw Exception('Server response is not a list.');
    }
  }
  
  // 좌석배정 버튼 클릭 시 SeatMapScreen으로 이동하는 함수
  void _navigateToSeatMap(Map<String, dynamic> item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SeatMapScreen(libraryItem: item, selectedCampus: _selectedCampus,),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> currentData =
        _selectedCampus == 0 ? _seoulData : _internationalData;

    // 합계 계산 로직 유지
    int totalSum = currentData.fold(0, (sum, item) => sum + item['total'] as int);
    int occupiedSum = currentData.fold(0, (sum, item) => sum + item['occupied'] as int);
    int availableSum = currentData.fold(0, (sum, item) => sum + item['available'] as int);
    double usageSum = totalSum > 0 ? occupiedSum / totalSum : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const SizedBox(width: 8),
            Text(
              '경희대학교 중앙도서관',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () { 
                        setState(() { _selectedCampus = 0; }); 
                        fetchSeoulData();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 18.0),
                        color: _selectedCampus == 0 ? Theme.of(context).hintColor : Colors.transparent,
                        child: Column(
                          children: [
                            Icon(Icons.menu_book, color: Colors.white, size: 30),
                            SizedBox(height: 8),
                            Text('서울캠퍼스', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () { 
                        setState(() { _selectedCampus = 1; }); 
                        fetchInternationalData();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 18.0),
                        color: _selectedCampus == 1 ? Theme.of(context).hintColor : Colors.transparent,
                        child: Column(
                          children: [
                            Icon(Icons.apartment, color: Colors.white, size: 30),
                            SizedBox(height: 8),
                            Text('국제캠퍼스', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            const SizedBox(height: 24),
            
            // 중앙도서관 테이블 섹션
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                '중앙도서관',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 12),

            // 테이블 데이터를 리스트 형태로 표시 (기존 로직 유지)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: currentData.length,
              itemBuilder: (context, index) {
                final item = currentData[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['name'], style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('전체좌석: ${item['total']}', style: Theme.of(context).textTheme.bodyMedium),
                                Text('사용중: ${item['occupied']}', style: Theme.of(context).textTheme.bodyMedium),
                                Text('이용가능: ${item['available']}', style: Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('운영시간: ${item['time']}', style: Theme.of(context).textTheme.bodyMedium),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: 120,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(5),
                                    child: LinearProgressIndicator(
                                      value: item['usage'],
                                      backgroundColor: Colors.grey[200],
                                      color: Colors.orange[700],
                                      minHeight: 10,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text('${(item['usage'] * 100).toStringAsFixed(0)}%',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color.fromARGB(255, 205, 108, 11),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // 탭 이동 함수 연결
                            ElevatedButton(
                              onPressed: () => _navigateToSeatMap(item),
                              style: Theme.of(context).elevatedButtonTheme.style,
                              child: const Text('좌석예약'),
                            ),
                            if (item['extra'] == '24')
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Text('24H', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                              )
                            else if (item['extra'] == '컴퓨터')
                              const Icon(Icons.computer, size: 28, color: Colors.grey),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // 합계 섹션 (기존 로직 유지)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              color: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('합계', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('전체좌석: $totalSum', style: Theme.of(context).textTheme.bodyMedium),
                            Text('사용중: $occupiedSum', style: Theme.of(context).textTheme.bodyMedium),
                            Text('이용가능: $availableSum', style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('이용률', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: 120,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: LinearProgressIndicator(
                                  value: usageSum,
                                  backgroundColor: Colors.grey[200],
                                  color: Colors.orange[700],
                                  minHeight: 10,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('${(usageSum * 100).toStringAsFixed(0)}%',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}