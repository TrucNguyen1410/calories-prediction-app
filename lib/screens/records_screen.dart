import 'package:flutter/material.dart';

class RecordsScreen extends StatefulWidget {
  final String title;
  
  const RecordsScreen({Key? key, required this.title}) : super(key: key);

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Danh sách thành viên'),
      ),
    );
  }
}
