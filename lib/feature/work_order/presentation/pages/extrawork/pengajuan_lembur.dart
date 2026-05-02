import 'package:flutter/material.dart';

class PengajuanLemburPage extends StatefulWidget {
  const PengajuanLemburPage({super.key});

  @override
  State<PengajuanLemburPage> createState() => _PengajuanLemburPageState();
}

class _PengajuanLemburPageState extends State<PengajuanLemburPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: CustomAppBar(title: 'Pengajuan Lembur'),
      body: Column(
        children: [
          Text('Pengajuan Lembur'),
        ],
      ),
    );
  }
}