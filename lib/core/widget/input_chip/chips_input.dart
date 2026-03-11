import 'package:flutter/material.dart';
import 'package:project_mobile_pdam/core/widget/app_state_page.dart';
import 'package:project_mobile_pdam/core/widget/custom_form.dart';

class ChipsInput<T> extends StatefulWidget {
  const ChipsInput({
    super.key,
    this.focusNode,
    this.isReadOnly = false,
    required this.values,
    required this.chipBuilder,
    required this.onChanged,
    this.onChipTapped,
    this.onSubmitted,
    this.onTextChanged,
    required this.labelText,
    required this.hintText,
  });

  final FocusNode? focusNode;
  final bool isReadOnly;
  final List<T> values;
  final String labelText;
  final String hintText;

  final ValueChanged<List<T>> onChanged;
  final ValueChanged<T>? onChipTapped;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onTextChanged;

  final Widget Function(BuildContext context, T data) chipBuilder;

  @override
  State<ChipsInput<T>> createState() => ChipsInputState<T>();
}

class ChipsInputState<T> extends AppStatePage<ChipsInput<T>> {
  @visibleForTesting
  late final ChipsInputEditingController<T> controller;

  String _previousText = '';
  TextSelection? _previousSelection;

  @override
  void initState() {
    super.initState();

    controller = ChipsInputEditingController<T>(<T>[
      ...widget.values,
    ], widget.chipBuilder);
    controller.addListener(_textListener);

    widget.focusNode?.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    controller.removeListener(_textListener);
    widget.focusNode?.removeListener(_onFocusChange);
    controller.dispose();

    super.dispose();
  }

  void _textListener() {
    final String currentText = controller.text;

    if (_previousSelection != null) {
      final int currentNumber = countReplacements(currentText);
      final int previousNumber = countReplacements(_previousText);

      // Ambil posisi cursor dari _previousSelection
      final int cursorEnd = _previousSelection!.extentOffset;
      final int cursorStart = _previousSelection!.baseOffset;

      // Buat salinan nilai chip yang ada
      final List<T> valuesCopy = <T>[...widget.values];

      if (currentNumber < previousNumber &&
          currentNumber != valuesCopy.length) {
        if (cursorStart == cursorEnd) {
          // Jika selection tidak terseleksi, artinya user menghapus satu chip.
          // Jika cursor berada di posisi 0, hapus chip pertama (indeks 0),
          // jika tidak, hapus chip di posisi (cursorStart - 1).
          int indexToRemove = cursorStart == 0 ? 0 : cursorStart - 1;
          if (indexToRemove < valuesCopy.length) {
            valuesCopy.removeAt(indexToRemove);
          }
        } else {
          // Jika selection memiliki range (tidak collapsed),
          // hapus chip dari indeks min(cursorStart, cursorEnd) hingga max(cursorStart, cursorEnd).
          int startIndex = cursorStart < cursorEnd ? cursorStart : cursorEnd;
          int endIndex = cursorStart < cursorEnd ? cursorEnd : cursorStart;

          // Pastikan indeks berada dalam batas list
          startIndex = startIndex.clamp(0, valuesCopy.length);
          endIndex = endIndex.clamp(0, valuesCopy.length);
          if (startIndex < endIndex) {
            valuesCopy.removeRange(startIndex, endIndex);
          }
        }
        if (valuesCopy.length != widget.values.length) {
          widget.onChanged(valuesCopy);
        }
      }
    }

    _previousText = currentText;
    _previousSelection = controller.selection;
  }

  void _onFocusChange() {
    if (widget.focusNode != null && !widget.focusNode!.hasFocus) {
      debugPrint("Focus lost, clearing input");
      clearInput();
    }
  }

  void clearInput() {
    final String char = String.fromCharCode(
      ChipsInputEditingController.kObjectReplacementChar,
    );
    final int length = widget.values.length;
    controller.value = TextEditingValue(
      text: char * length,
      selection: TextSelection.collapsed(offset: length),
    );
  }

  static int countReplacements(String text) {
    return text.codeUnits
        .where(
          (int u) => u == ChipsInputEditingController.kObjectReplacementChar,
        )
        .length;
  }

  @override
  Widget buildPage(BuildContext context) {
    controller.updateValues(<T>[...widget.values]);

    return widget.isReadOnly
        ? SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.labelText,
                  style: textTheme.headlineMedium?.copyWith(
                    color: color.primary[500],
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  children: widget.values
                      .map((T v) => widget.chipBuilder(context, v))
                      .toList(),
                ),
              ],
            ),
          )
        : CustomForm(
            focusNode: widget.focusNode,
            labelText: widget.labelText,
            hintText: widget.hintText,
            chips: widget.values
                .map((T v) => widget.chipBuilder(context, v))
                .toList(),
            minLines: 1,
            maxLines: null,
            textInputAction: TextInputAction.done,
            controller: controller,
            onChanged: (String value) =>
                widget.onTextChanged?.call(controller.textWithoutReplacements),
            onSubmitted: (String value) =>
                widget.onSubmitted?.call(controller.textWithoutReplacements),
          );
  }
}

class ChipsInputEditingController<T> extends TextEditingController {
  ChipsInputEditingController(this.values, this.chipBuilder)
    : super(text: String.fromCharCode(kObjectReplacementChar) * values.length);

  static const int kObjectReplacementChar = 0xFFFE;

  List<T> values;

  final Widget Function(BuildContext context, T data) chipBuilder;

  void updateValues(List<T> values) {
    if (values.length != this.values.length) {
      final String char = String.fromCharCode(kObjectReplacementChar);
      final int length = values.length;
      value = TextEditingValue(
        text: char * length,
        selection: TextSelection.collapsed(offset: length),
      );
      this.values = values;
    }
  }

  String get textWithoutReplacements {
    final String char = String.fromCharCode(kObjectReplacementChar);
    return text.replaceAll(RegExp(char), '');
  }

  String get textWithReplacements => text;

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    return TextSpan(
      style: style,
      children: [
        // Hanya menampilkan teks input yang belum dikonversi menjadi chip
        if (textWithoutReplacements.isNotEmpty)
          TextSpan(text: textWithoutReplacements),
      ],
    );
  }
}
