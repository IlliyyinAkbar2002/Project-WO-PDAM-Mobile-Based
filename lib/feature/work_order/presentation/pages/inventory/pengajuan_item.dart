import 'package:flutter/material.dart';

class BorrowItemData {
  final String brand;
  final String name;
  final String description;
  final int availableCount;
  final String imageUrl;

  const BorrowItemData({
    required this.brand,
    required this.name,
    required this.description,
    required this.availableCount,
    required this.imageUrl,
  });
}

class PengajuanItemPage extends StatefulWidget {
  final BorrowItemData item;

  const PengajuanItemPage({super.key, required this.item});

  @override
  State<PengajuanItemPage> createState() => _PengajuanItemPageState();
}

class _PengajuanItemPageState extends State<PengajuanItemPage> {
  final _formKey = GlobalKey<FormState>();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _purposeController = TextEditingController();
  bool _isSuccess = false;
  bool _isFormFilled = false;

  @override
  void initState() {
    super.initState();
    _startDateController.addListener(_onFormChanged);
    _endDateController.addListener(_onFormChanged);
    _purposeController.addListener(_onFormChanged);
  }

  void _onFormChanged() {
    final filled =
        _startDateController.text.trim().isNotEmpty &&
        _endDateController.text.trim().isNotEmpty &&
        _purposeController.text.trim().isNotEmpty;
    if (filled == _isFormFilled) return;
    setState(() => _isFormFilled = filled);
  }

  @override
  void dispose() {
    _startDateController.removeListener(_onFormChanged);
    _endDateController.removeListener(_onFormChanged);
    _purposeController.removeListener(_onFormChanged);
    _startDateController.dispose();
    _endDateController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (selected == null) return;
    final day = selected.day.toString().padLeft(2, '0');
    final month = selected.month.toString().padLeft(2, '0');
    final year = selected.year.toString();
    controller.text = '$day/$month/$year';
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSuccess = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final offset = Tween<Offset>(
            begin: const Offset(0, 0.03),
            end: Offset.zero,
          ).animate(animation);
          return SlideTransition(
            position: offset,
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: _isSuccess
            ? _SuccessState(
                key: const ValueKey('success_state'),
                onBack: () => Navigator.pop(context),
              )
            : _BorrowRequestForm(
                key: const ValueKey('form_state'),
                item: widget.item,
                formKey: _formKey,
                startDateController: _startDateController,
                endDateController: _endDateController,
                purposeController: _purposeController,
                onPickStartDate: () => _pickDate(_startDateController),
                onPickEndDate: () => _pickDate(_endDateController),
                isFormFilled: _isFormFilled,
                onSubmit: _submit,
              ),
      ),
    );
  }
}

class _BorrowRequestForm extends StatelessWidget {
  final BorrowItemData item;
  final GlobalKey<FormState> formKey;
  final TextEditingController startDateController;
  final TextEditingController endDateController;
  final TextEditingController purposeController;
  final VoidCallback onPickStartDate;
  final VoidCallback onPickEndDate;
  final bool isFormFilled;
  final VoidCallback onSubmit;

  const _BorrowRequestForm({
    super.key,
    required this.item,
    required this.formKey,
    required this.startDateController,
    required this.endDateController,
    required this.purposeController,
    required this.onPickStartDate,
    required this.onPickEndDate,
    required this.isFormFilled,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFF3F4F6)),
              ),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF9FAFB),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Borrow Request',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28 * 0.64,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF101828),
                    ),
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFF3F4F6)),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          item.imageUrl,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 64,
                            height: 64,
                            color: const Color(0xFFF3F4F6),
                            child: const Icon(Icons.image_not_supported_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: const Color(0xFF101828),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Available: ${item.availableCount}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF6A7282),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle(
                        icon: Icons.calendar_month_outlined,
                        title: 'Borrowing Period',
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _DateField(
                              label: 'Start Date',
                              controller: startDateController,
                              onTap: onPickStartDate,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _DateField(
                              label: 'End Date',
                              controller: endDateController,
                              onTap: onPickEndDate,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _SectionTitle(
                        icon: Icons.info_outline_rounded,
                        title: 'Justification',
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: purposeController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: 'Please explain why you need this equipment...',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.all(16),
                          hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFF99A1AF),
                            fontWeight: FontWeight.w500,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Justification wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Clear justifications help expedite the approval process.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: const Color(0xFF99A1AF),
                        ),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: isFormFilled
                                ? const Color(0xFF155DFC)
                                : const Color(0xFF8EC5FF),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shadowColor: const Color(0x40155DFC),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: onSubmit,
                          child: const Text(
                            'Submit Request',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF98A2B3)),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: const Color(0xFF111827),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.controller,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF6A7282),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          readOnly: true,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: 'dd/mm/yyyy',
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Pilih tanggal';
            }
            return null;
          },
        ),
      ],
    );
  }
}

class _SuccessState extends StatelessWidget {
  final VoidCallback onBack;

  const _SuccessState({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF16A34A),
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Request Sent!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Your request has been submitted for approval. We will notify you shortly.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF111827),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: onBack,
                  child: const Text('Back to Inventory'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
