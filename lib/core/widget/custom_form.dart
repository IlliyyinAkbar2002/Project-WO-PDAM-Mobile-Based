import 'package:flutter/material.dart';
import 'package:project_mobile_pdam/core/widget/app_state_page.dart';

enum InputType { text, dropdown }

class CustomForm<T> extends StatefulWidget {
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final String hintText;
  final String labelText;
  final bool obscureText;
  final int? minLines;
  final int? maxLines;
  final TextInputType keyboardType;
  final FocusNode? focusNode;
  final bool enabled;
  final bool readOnly;
  final void Function()? onTap;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final InputType inputType;
  final List<DropdownMenuItem<T>>? dropdownItems;
  final T? dropdownValue;
  final void Function(T?)? onDropdownChanged;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final List<Widget>? chips;

  const CustomForm({
    super.key,
    this.controller,
    required this.hintText,
    required this.labelText,
    this.suffixIcon,
    this.prefixIcon,
    this.validator,
    this.obscureText = false,
    this.minLines,
    this.maxLines,
    this.keyboardType = TextInputType.text,
    this.focusNode,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
    this.inputType = InputType.text,
    this.dropdownItems,
    this.dropdownValue,
    this.onDropdownChanged,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.chips,
  });

  @override
  State<CustomForm<T>> createState() => _CustomFormState<T>();
}

class _CustomFormState<T> extends AppStatePage<CustomForm<T>> {
  bool _isPasswordVisible = true;

  /// Filters dropdown items to ensure unique values
  /// Keeps the first occurrence of each value
  List<DropdownMenuItem<T>> _getUniqueDropdownItems(
    List<DropdownMenuItem<T>>? items,
    TextStyle? style,
  ) {
    if (items == null || items.isEmpty) return [];

    final seenValues = <T>{};
    final uniqueItems = <DropdownMenuItem<T>>[];

    for (final item in items) {
      if (!seenValues.contains(item.value)) {
        seenValues.add(item.value as T);
        uniqueItems.add(
          DropdownMenuItem<T>(
            value: item.value,
            child: DefaultTextStyle.merge(style: style, child: item.child),
          ),
        );
      }
    }

    return uniqueItems;
  }

  @override
  Widget buildPage(BuildContext context) {
    final inputStyle = textTheme.titleLarge;
    const defaultInputPadding = EdgeInsets.symmetric(
      vertical: 12,
      horizontal: 16,
    );

    // Safety check: ensure dropdownValue exists in uniqueItems
    T? dropdownValue = widget.dropdownValue;
    List<DropdownMenuItem<T>> uniqueItems = [];
    if (widget.inputType == InputType.dropdown) {
      uniqueItems = _getUniqueDropdownItems(widget.dropdownItems, inputStyle);
      final hasValue = uniqueItems.any(
        (item) => item.value == widget.dropdownValue,
      );
      if (!hasValue) {
        dropdownValue = null;
      }
    }

    return Align(
      alignment: AlignmentDirectional.topStart,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          widget.labelText.isNotEmpty
              ? Text(
                  widget.labelText,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D499B),
                    letterSpacing: -0.3,
                    height: 1.67,
                  ),
                )
              : const SizedBox.shrink(),
          widget.labelText.isNotEmpty
              ? const SizedBox(height: 6)
              : const SizedBox.shrink(),
          SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                (widget.chips != null && widget.chips!.isNotEmpty)
                    ? Wrap(
                        spacing: 4, // Jarak antar chip horizontal
                        children: widget.chips!,
                      )
                    : const SizedBox.shrink(),
                widget.inputType == InputType.text
                    ? TextFormField(
                        style: inputStyle,
                        readOnly: widget.readOnly,
                        minLines: widget.minLines,
                        maxLines: widget.maxLines,
                        keyboardType: widget.keyboardType,
                        controller: widget.controller,
                        validator: widget.validator,
                        onTap: widget.onTap,
                        obscureText: widget.obscureText && _isPasswordVisible,
                        focusNode: widget.focusNode,
                        enabled: widget.enabled,
                        onChanged: (value) {
                          widget.onChanged?.call(value);
                        },
                        onFieldSubmitted: (value) {
                          // Gunakan onFieldSubmitted untuk TextFormField
                          widget.onSubmitted?.call(value);
                          widget.focusNode?.unfocus();
                        },
                        decoration: InputDecoration(
                          hintText: widget.hintText,
                          hintStyle: const TextStyle(color: Color(0xFF8797AE)),
                          isDense: true,
                          contentPadding: defaultInputPadding,
                          prefixIcon: widget.prefixIcon,
                          suffixIcon:
                              widget.suffixIcon ??
                              (widget.obscureText
                                  ? IconButton(
                                      icon: Icon(
                                        _isPasswordVisible
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Colors.black,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isPasswordVisible =
                                              !_isPasswordVisible;
                                        });
                                      },
                                    )
                                  : null),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(
                              color: Color(0xFFAFBACA),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(
                              color: Color(0xFFAFBACA),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(
                              color: Color(0xFF2D499B),
                              width: 1.5,
                            ),
                          ),
                        ),
                      )
                    : DropdownButtonFormField<T>(
                        key: ValueKey(dropdownValue),
                        style: inputStyle,
                        initialValue: dropdownValue,
                        items: uniqueItems,
                        onChanged: widget.enabled
                            ? widget.onDropdownChanged
                            : null,
                        decoration: InputDecoration(
                          hintText: widget.hintText,
                          isDense: true,
                          contentPadding: defaultInputPadding,
                          filled: true,
                          fillColor: const Color(0xFFE9EFF6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Colors.transparent,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Colors.transparent,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Colors.transparent,
                            ),
                          ),
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
