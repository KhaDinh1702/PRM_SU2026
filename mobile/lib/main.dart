import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PRM Project',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HealthCheckPage(),
    );
  }
}

class HealthCheckPage extends StatefulWidget {
  const HealthCheckPage({super.key});

  @override
  State<HealthCheckPage> createState() => _HealthCheckPageState();
}

class _HealthCheckPageState extends State<HealthCheckPage> {
  String _status = 'Chưa kết nối';
  bool _isLoading = false;

  Future<void> checkBackend() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Lưu ý: Thay đổi URL nếu chạy trên Emulator (10.0.2.2) hoặc thiết bị thật
      final response = await http.get(Uri.parse('http://localhost:5000/api/health'));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _status = 'Backend OK: ${data['message']}';
        });
      } else {
        setState(() {
          _status = 'Lỗi: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Không thể kết nối Backend: $e';
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
        title: const Text('Backend Health Check'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Trạng thái Backend:',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            _isLoading 
              ? const CircularProgressIndicator()
              : Text(
                  _status,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                  textAlign: TextAlign.center,
                ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : checkBackend,
              child: const Text('Kiểm tra ngay'),
            ),
          ],
        ),
      ),
    );
  }
}
