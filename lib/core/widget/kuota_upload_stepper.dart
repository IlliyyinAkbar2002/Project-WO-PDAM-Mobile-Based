import 'package:flutter/material.dart';

class KuotaUploadStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final TextStyle titleStyle;
  final BoxDecoration? decoration;
  final EdgeInsetsGeometry? padding;

  const KuotaUploadStepper({
    super.key,
    required this.value,
    required this.onChanged,
    required this.titleStyle,
    this.decoration,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: decoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Kuota Upload Progress', style: titleStyle),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildButton(
                icon: Icons.remove,
                onPressed: value > 2 ? () => onChanged(value - 2) : null,
              ),
              const SizedBox(width: 32),
              Column(
                children: [
                  Text(
                    '$value',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const Text(
                    'kali upload',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              const SizedBox(width: 32),
              _buildButton(
                icon: Icons.add,
                onPressed: value < 10 ? () => onChanged(value + 2) : null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'minimal 2 · maksimal 10',
              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({required IconData icon, VoidCallback? onPressed}) {
    final bool disabled = onPressed == null;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: disabled ? const Color(0xFFE2E8F0) : const Color(0xFFCBD5E1),
          ),
          color: disabled ? const Color(0xFFF8FAFC) : Colors.white,
        ),
        child: Icon(
          icon,
          color: disabled ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
          size: 24,
        ),
      ),
    );
  }
}
