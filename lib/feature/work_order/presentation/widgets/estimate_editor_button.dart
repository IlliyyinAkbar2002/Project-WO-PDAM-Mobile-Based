import 'package:flutter/material.dart';
import 'package:project_mobile_pdam/core/widget/app_state_page.dart';

class EstimateEditorButton extends StatefulWidget {
  const EstimateEditorButton({super.key});

  @override
  State<EstimateEditorButton> createState() => _EstimateEditorButtonState();
}

class _EstimateEditorButtonState extends AppStatePage<EstimateEditorButton> {
  @override
  Widget buildPage(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton(onPressed: () {}, child: const Text('Tunda')),
        ElevatedButton(onPressed: () {}, child: const Text('Perpanjang')),
      ],
    );
  }
}
