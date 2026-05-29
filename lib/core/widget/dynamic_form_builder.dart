import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:project_mobile_pdam/core/widget/app_state_page.dart';
import 'package:project_mobile_pdam/core/widget/custom_form.dart';
import 'package:project_mobile_pdam/core/widget/image_picker.dart';

class DynamicFormBuilder extends StatefulWidget {
  final List<Map<String, dynamic>> fields;
  final Map<String, dynamic> formData;
  final Function(String, dynamic) onFieldChanged;
  final Map<
    String,
    Widget Function(
      Map<String, dynamic>,
      Map<String, dynamic>,
      Function(String, dynamic),
    )
  >
  customWidgets;
  final bool readOnly;

  const DynamicFormBuilder({
    super.key,
    required this.fields,
    required this.formData,
    required this.onFieldChanged,
    required this.customWidgets,
    this.readOnly = false,
  });

  @override
  State<DynamicFormBuilder> createState() => _DynamicFormBuilderState();
}

class _DynamicFormBuilderState extends AppStatePage<DynamicFormBuilder> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    // Inisialisasi controller hanya untuk field teks
    for (var field in widget.fields) {
      if (field['type'] == 'text' ||
          field['type'] == 'textarea' ||
          field['type'] == 'tanggal' ||
          field['type'] == 'date') {
        String initialText = '';
        final isDateType = field['type'] == 'tanggal' || field['type'] == 'date';
        if (isDateType &&
            widget.formData[field['key']] is DateTime) {
          initialText = DateFormat(
            'dd/MM/yyyy',
          ).format(widget.formData[field['key']]);
        } else if (isDateType &&
            widget.formData[field['key']] is String) {
          // Tangani jika backend mengembalikan string tanggal
          try {
            final date = DateTime.parse(widget.formData[field['key']]);
            initialText = DateFormat('dd/MM/yyyy').format(date);
          } catch (e) {
            initialText = '';
          }
        } else {
          initialText = widget.formData[field['key']]?.toString() ?? '';
        }
        _controllers[field['key']] = TextEditingController(text: initialText);
      }
    }
  }

  @override
  void dispose() {
    // Bersihkan semua controller saat widget dihapus
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget buildPage(BuildContext context) {
    return Column(
      children: widget.fields
          .where((field) {
            final showIf = field["showIf"];
            if (showIf == null) {
              return true; // Show the field if "showIf" is not defined
            } else if (showIf is bool) {
              return showIf; // Use the boolean value directly
            } else if (showIf is Function) {
              return showIf(widget.formData); // Call the function with formData
            }
            return false; // Default to not showing the field if "showIf" is invalid
          })
          .map((field) {
            bool isReadOnly = field["isReadOnly"] ?? false;
            bool isDisabled = field["isDisabled"] ?? false;

            switch (field["type"]) {
              case "text":
                return Column(
                  children: [
                    CustomForm(
                      hintText: field["hint"],
                      labelText: field["label"],
                      keyboardType: TextInputType.text,
                      controller: _controllers[field["key"]],
                      readOnly: isReadOnly || widget.readOnly,
                      onChanged: (value) {
                        if (!isReadOnly && !widget.readOnly) {
                          widget.onFieldChanged(field["key"], value);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                );

              case "textarea":
                return Column(
                  children: [
                    CustomForm(
                      hintText: field["hint"],
                      labelText: field["label"],
                      keyboardType: TextInputType.multiline,
                      controller: _controllers[field["key"]],
                      readOnly: isReadOnly || widget.readOnly,
                      maxLines: field["maxLines"] ?? 4,
                      onChanged: (value) {
                        if (!isReadOnly && !widget.readOnly) {
                          widget.onFieldChanged(field["key"], value);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                );

              case "dropdown":
                debugPrint("Dropdown id: ${field["key"]}");
                debugPrint("Dropdown parent: ${field["parent"]}");
                debugPrint("Dropdown option: ${field["options"]}");
                final options = _getFilteredOptions(field);
                debugPrint(
                  "Dropdown ${field["key"]} - isDisabled: $isDisabled",
                );
                return Column(
                  children: [
                    CustomForm(
                      hintText: field["hint"],
                      labelText: field["label"],
                      inputType: InputType.dropdown,
                      dropdownItems: options.map((option) {
                        return DropdownMenuItem<dynamic>(
                          value: option["value"],
                          child: Text(
                            option["label"].toString(),
                            style: textTheme.titleLarge,
                          ),
                        );
                      }).toList(),
                      dropdownValue: widget.formData[field["key"]],
                      enabled:
                          !isDisabled &&
                          !widget.readOnly, // ✅ Buat disabled jika perlu
                      onDropdownChanged: (value) {
                        if (!isDisabled && !widget.readOnly) {
                          widget.onFieldChanged(field["key"], value);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                );

              case "date":
                return Column(
                  children: [
                    CustomForm(
                      controller: _controllers[field["key"]],
                      hintText: field["hint"],
                      labelText: field["label"],
                      readOnly: true,
                      enabled: !isDisabled && !widget.readOnly,
                      onTap: (isReadOnly)
                          ? null
                          : () => _selectDate(field["key"]),
                    ),
                    const SizedBox(height: 10),
                  ],
                );

              case 'image':
                return Row(
                  children: [
                    Column(
                      children: [
                        Text(
                          field['label'] ?? 'Unggah Gambar',
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        ImagePickerField(
                          singleImage: true,
                          initialImage: widget.formData[field['key']],
                          enabled: !isReadOnly && !widget.readOnly,
                          onChanged: (image) {
                            if (!isDisabled && !widget.readOnly) {
                              widget.onFieldChanged(field['key'], image);
                              debugPrint(
                                'Image field ${field['key']} updated: ${image is XFile ? image.path : null}',
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ],
                );

              case "chip":
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(field["label"], style: const TextStyle(fontSize: 16)),
                    Wrap(
                      children: (field["options"] as List<Map<String, dynamic>>)
                          .map((option) {
                            bool isSelected =
                                (widget.formData[field["key"]] ?? []).contains(
                                  option["id"],
                                );
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4.0,
                              ),
                              child: ChoiceChip(
                                label: Text(option["name"]),
                                selected: isSelected,
                                onSelected: (selected) {
                                  final selectedList = List<int>.from(
                                    widget.formData[field["key"]] ?? [],
                                  );
                                  if (selected) {
                                    selectedList.add(option["id"]);
                                  } else {
                                    selectedList.remove(option["id"]);
                                  }
                                  widget.onFieldChanged(
                                    field["key"],
                                    selectedList,
                                  );
                                },
                              ),
                            );
                          })
                          .toList(),
                    ),
                  ],
                );

              case "custom":
                if (widget.customWidgets.containsKey(field["key"])) {
                  return Column(
                    children: [
                      widget.customWidgets[field["key"]]!(
                        field,
                        widget.formData,
                        widget.onFieldChanged,
                      ),
                      const SizedBox(height: 10),
                    ],
                  );
                }
                return const SizedBox();

              default:
                return const SizedBox();
            }
          })
          .toList(),
    );
  }

  Future<void> _selectDate(String fieldKey) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: widget.formData[fieldKey] is DateTime
          ? widget.formData[fieldKey]
          : DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 10),
      lastDate: DateTime(DateTime.now().year + 10),
    );

    if (pickedDate != null) {
      setState(() {
        // Simpan sebagai DateTime di formData
        widget.onFieldChanged(fieldKey, pickedDate);
        // Tampilkan dalam format DD/MM/YYYY di controller
        _controllers[fieldKey]?.text = DateFormat(
          'dd/MM/yyyy',
        ).format(pickedDate);
      });
    }
  }

  List<Map<String, dynamic>> _getFilteredOptions(Map<String, dynamic> field) {
    final List<Map<String, dynamic>> options = field["options"];

    final parentFieldId = field["parent"];
    if (parentFieldId == null || parentFieldId == 0) {
      // Tidak ada parent, ambil semua option
      return options;
    }

    // Ambil nilai yang dipilih di parent-nya
    final selectedParentValue = widget.formData[parentFieldId.toString()];
    debugPrint(
      "Selected parent value for $parentFieldId: $selectedParentValue",
    );
    if (selectedParentValue == null) return [];

    return options
        .where((opt) => opt["optionParent"] == selectedParentValue)
        .toList();
  }
}
