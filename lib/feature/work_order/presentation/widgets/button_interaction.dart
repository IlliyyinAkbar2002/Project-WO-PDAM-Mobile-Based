import 'package:flutter/material.dart';
import 'package:project_mobile_pdam/core/widget/app_state_page.dart';

class ButtonInteraction extends StatefulWidget {
  final int? status;
  final Function(String)? onPressed;
  final VoidCallback? onDefaultPressed;
  final bool isDisabled;

  const ButtonInteraction({
    super.key,
    this.status,
    this.onPressed,
    this.onDefaultPressed,
    this.isDisabled = false,
  });

  @override
  State<ButtonInteraction> createState() => _ButtonInteractionState();
}

class _ButtonInteractionState extends AppStatePage<ButtonInteraction> {
  @override
  Widget buildPage(BuildContext context) {
    return widget.onPressed != null
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color.danger,
                    ),
                    onPressed: () => _showConfirmationDialog(),
                    child: const Text('Tolak'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color.status[2],
                    ),
                    onPressed: () => widget.onPressed?.call('Accept'),
                    child: const Text('Setujui'),
                  ),
                ),
              ],
            ),
          )
        : Center(
            child: Container(
              width: 180,
              height: 60,
              margin: const EdgeInsets.only(top: 16, bottom: 16),
              child: ElevatedButton(
                onPressed: widget.isDisabled ? null : widget.onDefaultPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D499B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                ),
                child: Text(
                  _buttonTextString(),
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          );
  }

  String _buttonTextString() {
    switch (widget.status) {
      case 1:
        return 'Belum disetujui';
      case 2:
        return 'Disetujui';
      case 3:
        return 'Revisi';
      case 4:
        return 'Ditolak';
      case 5:
        return 'Pengecekan';
      case 6:
        return 'Selesai';
      case 7:
        return 'In Progress';
      case 8:
        return 'Freeze';
      default:
        return 'Ajukan';
    }
  }

  void _showConfirmationDialog() {
    showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi'),
          content: const Text('Apakah Anda yakin ingin melanjutkan aksi ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                widget.onPressed?.call('Reject');
                Navigator.of(context).pop(true);
              },
              child: const Text('Ya'),
            ),
          ],
        );
      },
    );
  }
}
