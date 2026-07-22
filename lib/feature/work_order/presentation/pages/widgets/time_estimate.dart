import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_mobile_pdam/core/utils/app_snackbar.dart';
import 'package:project_mobile_pdam/core/widget/app_state_page.dart';

class TimeEstimate extends StatefulWidget {
  final bool isOvertime;
  final bool isReadOnly;
  final bool hideStartDateTime;
  final Function(DateTime?, int?, String?, DateTime?) onChanged;
  final DateTime? startDateTime;
  final int? duration;
  final String? durationUnit;
  final DateTime? endDateTime;
  final int? status;

  const TimeEstimate({
    super.key,
    required this.isOvertime,
    this.isReadOnly = false,
    this.hideStartDateTime = false,
    required this.onChanged,
    this.startDateTime,
    this.duration,
    this.durationUnit,
    this.endDateTime,
    this.status,
  });

  @override
  State<TimeEstimate> createState() => _TimeEstimateState();
}

class _TimeEstimateState extends AppStatePage<TimeEstimate> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  DateTime? selectedEndDate;
  TimeOfDay? selectedEndTime;
  DateTime? endDateTime;

  @override
  void initState() {
    super.initState();
    _initialValue();
  }

  @override
  void didUpdateWidget(TimeEstimate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.startDateTime != oldWidget.startDateTime ||
        widget.endDateTime != oldWidget.endDateTime) {
      _initialValue();
      if (selectedTime != null) {
        _timeController.text = selectedTime!.format(context);
      }
      if (selectedEndTime != null) {
        _endTimeController.text = selectedEndTime!.format(context);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (selectedTime != null) {
      _timeController.text = selectedTime!.format(
        context,
      ); // ✅ Pindahkan ke sini
    }
    if (selectedEndTime != null) {
      _endTimeController.text = selectedEndTime!.format(
        context,
      );
    }
  }

  void _initialValue() {
    selectedDate = widget.startDateTime?.toLocal();
    selectedTime = widget.startDateTime != null
        ? TimeOfDay.fromDateTime(widget.startDateTime!.toLocal())
        : null;

    endDateTime = widget.endDateTime?.toLocal();
    selectedEndDate = widget.endDateTime?.toLocal();
    selectedEndTime = widget.endDateTime != null
        ? TimeOfDay.fromDateTime(widget.endDateTime!.toLocal())
        : null;

    _dateController.text = selectedDate != null
        ? DateFormat('yyyy-MM-dd').format(selectedDate!)
        : '';
    _timeController.text = selectedTime != null
        ? "${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}"
        : '';

    _endDateController.text = selectedEndDate != null
        ? DateFormat('yyyy-MM-dd').format(selectedEndDate!)
        : '';
    _endTimeController.text = selectedEndTime != null
        ? "${selectedEndTime!.hour.toString().padLeft(2, '0')}:${selectedEndTime!.minute.toString().padLeft(2, '0')}"
        : '';
  }

  @override
  Widget buildPage(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Container with border
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFAFBACA)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                "Estimasi Waktu Work Order",
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D499B),
                  letterSpacing: -0.3,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 16),

              // Mulai row
              if (!widget.hideStartDateTime) ...[
                Row(
                  children: [
                    SizedBox(
                      width: 50,
                      child: Text(
                        "Mulai",
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D3643),
                          letterSpacing: -0.2,
                          height: 1.71,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    Expanded(
                      flex: 3,
                      child: _buildSmallInput(
                        controller: _dateController,
                        hintText: 'Pilih Tanggal',
                        onTap: (widget.isReadOnly) ? null : _selectDate,
                      ),
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      flex: 2,
                      child: _buildSmallInput(
                        controller: _timeController,
                        hintText: 'Jam',
                        onTap: (widget.isReadOnly) ? null : _selectTime,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),
              ],

              // Selesai row
              Row(
                children: [
                  SizedBox(
                    width: 50,
                    child: Text(
                      "Selesai",
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3643),
                        letterSpacing: -0.2,
                        height: 1.71,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  Expanded(
                    flex: 3,
                    child: _buildSmallInput(
                      controller: _endDateController,
                      hintText: 'Pilih Tanggal',
                      onTap: (widget.isReadOnly) ? null : _selectEndDate,
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    flex: 2,
                    child: _buildSmallInput(
                      controller: _endTimeController,
                      hintText: 'Jam',
                      onTap: (widget.isReadOnly) ? null : _selectEndTime,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSmallInput({
    required TextEditingController controller,
    required String hintText,
    VoidCallback? onTap,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
    bool readOnly = true,
  }) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFDCE0E5)),
      ),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF14181F),
          letterSpacing: -0.2,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF8797AE),
            letterSpacing: -0.2,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }


  Future<void> _selectDate() async {
    final DateTime today = DateTime.now();
    final DateTime minDate = DateTime(today.year, today.month, today.day);
    final DateTime initial =
        (selectedDate != null && !selectedDate!.isBefore(minDate))
        ? selectedDate!
        : minDate;
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: minDate,
      lastDate: DateTime(today.year + 10),
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
        _dateController.text = "${pickedDate.toLocal()}".split(' ')[0];
        _calculateEndDateTime();
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
      initialEntryMode: TimePickerEntryMode.input,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (pickedTime != null) {
      setState(() {
        selectedTime = pickedTime;
        _timeController.text = pickedTime.format(context);
        _calculateEndDateTime();
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime today = DateTime.now();
    final DateTime minDate = selectedDate ?? DateTime(today.year, today.month, today.day);
    final DateTime initial =
        (selectedEndDate != null && !selectedEndDate!.isBefore(minDate))
        ? selectedEndDate!
        : minDate;
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: minDate,
      lastDate: DateTime(today.year + 10),
    );

    if (pickedDate != null) {
      // Cegat langsung: selesai harus setelah mulai (kalau data sudah lengkap).
      if (selectedEndTime != null &&
          !_isEndAfterStart(
            DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              selectedEndTime!.hour,
              selectedEndTime!.minute,
            ),
          )) {
        AppSnackbar.showError("Waktu selesai harus setelah waktu mulai.");
        return;
      }
      setState(() {
        selectedEndDate = pickedDate;
        _endDateController.text = "${pickedDate.toLocal()}".split(' ')[0];
        _calculateEndDateTime();
      });
    }
  }

  Future<void> _selectEndTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedEndTime ?? TimeOfDay.now(),
      initialEntryMode: TimePickerEntryMode.input,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (pickedTime != null) {
      // Cegat langsung: selesai harus setelah mulai (kalau data sudah lengkap).
      if (selectedEndDate != null &&
          !_isEndAfterStart(
            DateTime(
              selectedEndDate!.year,
              selectedEndDate!.month,
              selectedEndDate!.day,
              pickedTime.hour,
              pickedTime.minute,
            ),
          )) {
        AppSnackbar.showError("Waktu selesai harus setelah waktu mulai.");
        return;
      }
      setState(() {
        selectedEndTime = pickedTime;
        _endTimeController.text = pickedTime.format(context);
        _calculateEndDateTime();
      });
    }
  }

  /// True kalau [candidateEnd] jatuh setelah waktu mulai. Kalau tanggal/jam
  /// mulai belum lengkap, kembalikan true (validasi jatuh ke tombol Ajukan).
  bool _isEndAfterStart(DateTime candidateEnd) {
    if (selectedDate == null || selectedTime == null) return true;
    final DateTime start = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );
    return candidateEnd.isAfter(start);
  }

  void _calculateEndDateTime() {
    DateTime? startDateTime;
    if (selectedDate != null && selectedTime != null) {
      startDateTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        selectedTime!.hour,
        selectedTime!.minute,
      );
    }

    if (selectedEndDate != null && selectedEndTime != null) {
      setState(() {
        endDateTime = DateTime(
          selectedEndDate!.year,
          selectedEndDate!.month,
          selectedEndDate!.day,
          selectedEndTime!.hour,
          selectedEndTime!.minute,
        );
      });
    }

    widget.onChanged(
      startDateTime,
      null,
      null,
      endDateTime,
    );
  }
}
