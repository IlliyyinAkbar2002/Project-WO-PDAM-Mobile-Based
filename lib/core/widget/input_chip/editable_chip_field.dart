import 'dart:async';
import 'package:flutter/material.dart';
import 'package:project_mobile_pdam/core/widget/app_state_page.dart';
import 'package:project_mobile_pdam/core/widget/input_chip/add_chip.dart';
import 'package:project_mobile_pdam/core/widget/input_chip/input_suggestion.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/user_entity.dart';
import 'chips_input.dart';

class EditableChipField extends StatefulWidget {
  final bool isReadOnly;
  final List<UserEntity> userList;
  final List<UserEntity> initialSelectedUsers;
  final Function(List<UserEntity>) onChanged;
  const EditableChipField({
    super.key,
    this.isReadOnly = false,
    required this.userList,
    this.initialSelectedUsers = const [], // ✅ Default kosong agar tidak error
    required this.onChanged,
  });

  @override
  EditableChipFieldState createState() => EditableChipFieldState();
}

class EditableChipFieldState extends AppStatePage<EditableChipField> {
  final GlobalKey<ChipsInputState<String>> _chipsInputKey =
      GlobalKey<ChipsInputState<String>>();
  final FocusNode _chipFocusNode = FocusNode();
  List<UserEntity> _users = [];
  List<UserEntity> _suggestions = [];
  Timer? _debounce;

  List<UserEntity> get users => _users;

  @override
  void initState() {
    super.initState();
    _users = List<UserEntity>.from(widget.initialSelectedUsers);

    _chipFocusNode.addListener(() {
      if (!_chipFocusNode.hasFocus) {
        debugPrint("Focus lost, clearing suggestions");
        setState(() {
          _suggestions = []; // Hapus daftar saran saat kehilangan fokus
        });
      }
    });
  }

  @override
  void dispose() {
    _chipFocusNode.removeListener(
      () {},
    ); // Hapus listener untuk menghindari memory leak
    super.dispose();
  }

  @override
  Widget buildPage(BuildContext context) {
    return Column(
      children: <Widget>[
        ChipsInput<UserEntity>(
          key: _chipsInputKey,
          labelText: 'Petugas',
          hintText: 'Tambahkan petugas',
          focusNode: _chipFocusNode,
          isReadOnly: widget.isReadOnly,
          values: _users,
          onChanged: _onChanged,
          onSubmitted: _onSubmitted,
          chipBuilder: _chipBuilder,
          onTextChanged: _onSearchChanged,
        ),
        if (_suggestions.isNotEmpty)
          SizedBox(
            height: 200,
            child: ListView.builder(
              itemCount: _suggestions.length,
              itemBuilder: (BuildContext context, int index) {
                return InputSuggestion(
                  '${_suggestions[index].employee?.name} ${_suggestions[index].employee?.nip}',
                  onTap: () => _selectSuggestion(_suggestions[index]),
                );
              },
            ),
          ),
      ],
    );
  }

  void setUsers(List<UserEntity> selectedUsers) {
    setState(() {
      _users = selectedUsers;
    });
  }

  Future<void> _onSearchChanged(String value) async {
    if (value.isEmpty) {
      setState(() {
        _suggestions = [];
      });
      return;
    }

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final List<UserEntity> results = await _suggestionCallback(value);
      setState(() {
        _suggestions = results.where((user) => !_users.contains(user)).toList();
        debugPrint('Suggestions Updated: $_suggestions');
      });
    });
  }

  Widget _chipBuilder(BuildContext context, UserEntity user) {
    return AddChip(
      chip:
          '${user.employee?.name} ${user.employee?.nip}', // ✅ Hanya email yang dikirim
      onDeleted: (String assignee) => _onChipDeleted(user),
      onSelected: (String assignee) => _onChipTapped(user),
    );
  }

  void _selectSuggestion(UserEntity user) {
    setState(() {
      _users.add(user);
      _suggestions = [];
    });
    widget.onChanged(_users);
  }

  void _onChipDeleted(UserEntity user) {
    setState(() {
      _users.remove(user);
      _suggestions = [];
    });
    widget.onChanged(_users);
  }

  void _onChipTapped(UserEntity user) {
    // Implementasikan jika diperlukan aksi saat chip diketuk
  }

  void _onSubmitted(String text) {
    final String trimmedText = text.trim();
    final exists = widget.userList.any(
      (user) => '${user.employee?.name} ${user.employee?.nip}' == trimmedText,
    );

    if (trimmedText.isNotEmpty && exists) {
      final user = widget.userList.firstWhere(
        (user) => '${user.employee?.name} ${user.employee?.nip}' == trimmedText,
      );
      setState(() {
        _users.add(user);
        _suggestions = [];
      });
    }
  }

  void _onChanged(List<UserEntity> users) {
    setState(() {
      _users = users;
    });
    widget.onChanged(_users);
  }

  FutureOr<List<UserEntity>> _suggestionCallback(String text) {
    debugPrint(
      "User List: ${widget.userList.map((e) => '${e.employee?.name} ${e.employee?.nip}').toList()}",
    );
    debugPrint("Searching for: $text");

    if (text.isNotEmpty) {
      final results = widget.userList
          .where(
            (user) => '${user.employee?.name} ${user.employee?.nip}'
                .toLowerCase()
                .contains(text.toLowerCase()),
          )
          .toList();

      debugPrint(
        "Filtered Results: ${results.map((e) => '${e.employee?.name} ${e.employee?.nip}').toList()}",
      );
      return results;
    }
    return <UserEntity>[];
  }

  void clear() {
    setState(() {
      _users.clear();
    });
  }
}
