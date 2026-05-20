import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _durationTypeController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  DateTime? endDateTime;
  int _duration = 0;
  String _selectedDurationType = '';
  final List<String> normalDurationOptions = ['Jam', 'Hari', 'Bulan'];

  String _normalizeDurationUnit(String? value) {
    // Alternatif selain trim(): Menghapus semua karakter spasi putih (spasi, enter, tab)
    final String normalized = (value ?? '').replaceAll(RegExp(r'\s+'), '').toLowerCase();
    if (normalized == 'jam' ||
        normalized == 'j' ||
        normalized == 'h' ||
        normalized == 'hour' ||
        normalized == 'hours') {
      return 'Jam';
    }
    if (normalized == 'hari' ||
        normalized == 'd' ||
        normalized == 'day' ||
        normalized == 'days') {
      return 'Hari';
    }
    if (normalized == 'bulan' ||
        normalized == 'b' ||
        normalized == 'bln' ||
        normalized == 'month' ||
        normalized == 'months') {
      return 'Bulan';
    }
    return '';
  }

  @override
  void initState() {
    super.initState();
    _updateDurationType();
    _initialValue();
  }

  @override
  void didUpdateWidget(TimeEstimate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.startDateTime != oldWidget.startDateTime ||
        widget.duration != oldWidget.duration ||
        widget.durationUnit != oldWidget.durationUnit ||
        widget.endDateTime != oldWidget.endDateTime) {
      _initialValue();
      if (selectedTime != null) {
        _timeController.text = selectedTime!.format(context);
      }
    }
    if (widget.isOvertime != oldWidget.isOvertime) {
      _updateDurationType();
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
  }

  void _initialValue() {
    selectedDate = widget.startDateTime;
    selectedTime = widget.startDateTime != null
        ? TimeOfDay.fromDateTime(widget.startDateTime!)
        : null;

    _duration = widget.duration ?? 0;
    _selectedDurationType = widget.isOvertime
        ? 'Jam'
        : _normalizeDurationUnit(widget.durationUnit);
    endDateTime = widget.endDateTime;

    _dateController.text = selectedDate != null
        ? DateFormat('yyyy-MM-dd').format(selectedDate!)
        : '';
    _timeController.text = selectedTime != null
        ? "${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}"
        : '';
    _durationController.text = _duration > 0 ? _duration.toString() : '';
    _durationTypeController.text = _selectedDurationType;
  }

  void _updateDurationType() {
    setState(() {
      _selectedDurationType = widget.isOvertime
          ? 'Jam'
          : _normalizeDurationUnit(widget.durationUnit);
      _durationTypeController.text = _selectedDurationType; // Update text field
    });
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

              // Durasi row
              Row(
                children: [
                  SizedBox(
                    width: 50,
                    child: Text(
                      "Durasi",
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
                    child: _buildSmallInput(
                      controller: _durationController,
                      hintText: '',
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        _duration = int.tryParse(value) ?? 0;
                        _calculateEndDateTime();
                      },
                      readOnly: widget.isReadOnly,
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    flex: 2,
                    child: widget.isOvertime
                        ? _buildDisabledUnitSelector()
                        : _buildUnitDropdown(),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              // Selesai row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
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
                  Flexible(
                    child: Text(
                      (endDateTime != null)
                          ? _formatEndDateTime(endDateTime!)
                          : "-",
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF3D4A5C),
                        letterSpacing: -0.2,
                        height: 1.71,
                      ),
                      textAlign: TextAlign.right,
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

  Widget _buildUnitDropdown() {
    final String? selectedValue =
        normalDurationOptions.contains(_selectedDurationType)
        ? _selectedDurationType
        : null;

    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFDCE0E5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedValue,
          hint: const Text(
            'H/J/B',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF14181F),
              letterSpacing: -0.2,
            ),
          ),
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, size: 20),
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF14181F),
            letterSpacing: -0.2,
          ),
          items: normalDurationOptions
              .map(
                (duration) =>
                    DropdownMenuItem(value: duration, child: Text(duration)),
              )
              .toList(),
          onChanged: widget.isReadOnly
              ? null
              : (value) {
                  setState(() {
                    _selectedDurationType = value!;
                    _durationTypeController.text = value;
                    _calculateEndDateTime();
                  });
                },
        ),
      ),
    );
  }

  Widget _buildDisabledUnitSelector() {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFFD7DFE9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFDCE0E5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      child: const Text(
        'Jam',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF14181F),
          letterSpacing: -0.2,
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

  void _calculateEndDateTime() {
    if (selectedDate != null && selectedTime != null) {
      DateTime startDateTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        selectedTime!.hour,
        selectedTime!.minute,
      );

      DateTime calculatedEndDateTime;
      int durationValue = int.tryParse(_durationController.text) ?? 0;

      if (_selectedDurationType == 'Jam') {
        calculatedEndDateTime = startDateTime.add(
          Duration(hours: durationValue),
        );
      } else if (_selectedDurationType == 'Hari') {
        calculatedEndDateTime = startDateTime.add(
          Duration(days: durationValue),
        );
      } else if (_selectedDurationType == 'Bulan') {
        calculatedEndDateTime = DateTime(
          startDateTime.year,
          startDateTime.month + durationValue, // ✅ Tambahkan bulan langsung
          startDateTime.day,
          startDateTime.hour,
          startDateTime.minute,
        );
      } else {
        calculatedEndDateTime =
            startDateTime; // Jika unit tidak dikenal, biarkan tetap sama
      }

      setState(() {
        endDateTime = calculatedEndDateTime;
      });

      widget.onChanged(
        startDateTime,
        durationValue,
        _selectedDurationType,
        endDateTime,
      );
    }
  }

  String _formatEndDateTime(DateTime dateTime) {
    final DateFormat formatter = DateFormat('EEEE, dd MMMM yyyy HH:mm \'WIB\'');
    return formatter.format(dateTime);
  }
}
