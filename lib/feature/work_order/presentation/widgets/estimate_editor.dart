import 'package:flutter/material.dart';
import 'package:project_mobile_pdam/core/widget/app_state_page.dart';

class EstimateEditor extends StatefulWidget {
  const EstimateEditor({super.key});

  @override
  State<EstimateEditor> createState() => _EstimateEditorState();
}

class _EstimateEditorState extends AppStatePage<EstimateEditor> {
  @override
  Widget buildPage(BuildContext context) {
    return const Row(
      spacing: 16,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Text("Durasi Perpanjangan"), Text("5 Hari")],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Text("Tanggal Selesai Baru"), Text("2023-10-01 12:00:00")],
        ),
      ],
    );
  }
}
