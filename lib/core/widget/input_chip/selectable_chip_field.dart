import 'package:flutter/material.dart';
import 'package:project_mobile_pdam/core/utils/app_snackbar.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/user_entity.dart';


class SelectableChipField extends StatefulWidget {
  final bool isReadOnly;
  final List<UserEntity> userList;
  final List<UserEntity> initialSelectedUsers;
  final Function(List<UserEntity>) onChanged;
  final int? coordinatorId;
  const SelectableChipField({
    super.key,
    this.isReadOnly = false,
    required this.userList,
    this.initialSelectedUsers = const [],
    required this.onChanged,
    this.coordinatorId,
  });

  @override
  State<SelectableChipField> createState() => _SelectableChipFieldState();
}

class _SelectableChipFieldState extends State<SelectableChipField> {
  List<UserEntity> _selected = [];

  @override
  void initState() {
    super.initState();
    _selected = List<UserEntity>.from(widget.initialSelectedUsers);
  }

  Future<void> _pickMembers() async {
    if (widget.userList.isEmpty) {
      AppSnackbar.showInfo('Daftar pegawai belum tersedia.');
      return;
    }
    // Snapshot seleksi agar user bisa membatalkan tanpa mengubah data.
    final tempSelected = <int>{
      for (final m in _selected)
        if (m.id != null) m.id!,
    };
    final result = await showModalBottomSheet<List<UserEntity>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (_, scrollController) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Pilih Petugas',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.separated(
                          controller: scrollController,
                          itemCount: widget.userList.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, index) {
                            final user = widget.userList[index];
                            final id = user.id;
                            final checked =
                                id != null && tempSelected.contains(id);
                            final name =
                                user.employee?.name ?? user.email ?? '-';
                            final isBusy = user.isBusy;
                            final busyWorkorder = user.busyWorkorderName?.trim();
                            final subtitle = [
                              if (user.employee?.nip != null)
                                'NPP: ${user.employee?.nip}',
                              if (user.employee?.jabatan != null)
                                user.employee!.jabatan!,
                              if (isBusy)
                                busyWorkorder != null && busyWorkorder.isNotEmpty
                                    ? 'Sedang mengerjakan Work Order'
                                    : 'Masih memegang WO yang belum selesai',
                            ].join(' · ');
                            return CheckboxListTile(
                              value: checked,
                              onChanged: (id == null || isBusy)
                                  ? null
                                  : (val) {
                                      setSheetState(() {
                                        if (val == true) {
                                          tempSelected.add(id);
                                        } else {
                                          tempSelected.remove(id);
                                        }
                                      });
                                    },
                              title: Text(
                                name,
                                style: isBusy
                                    ? const TextStyle(color: Color(0xFF94A3B8))
                                    : null,
                              ),
                              subtitle: subtitle.isEmpty
                                  ? null
                                  : Text(
                                      subtitle,
                                      style: isBusy
                                          ? const TextStyle(
                                              color: Color(0xFFB45309),
                                            )
                                          : null,
                                    ),
                              controlAffinity: ListTileControlAffinity.leading,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            final picked = widget.userList
                                .where(
                                  (u) =>
                                      u.id != null &&
                                      tempSelected.contains(u.id),
                                )
                                .toList();
                            Navigator.pop(sheetCtx, picked);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            minimumSize: const Size.fromHeight(46),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Simpan'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        _selected = result;
      });
      widget.onChanged(_selected);
    }
  }

  void _removeMember(UserEntity user) {
    setState(() {
      _selected.remove(user);
    });
    widget.onChanged(_selected);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Petugas',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D499B),
                letterSpacing: -0.3,
                height: 1.67,
              ),
            ),
            const Spacer(),
            if (!widget.isReadOnly)
              TextButton.icon(
                onPressed: _pickMembers,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Pilih'),
              ),
          ],
        ),
        if (_selected.isEmpty)
          Text(
            widget.userList.isEmpty
                ? 'Daftar pegawai belum tersedia'
                : 'Belum ada petugas dipilih',
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selected.map((m) {
              final name = m.employee?.name ?? m.email ?? 'User #${m.id}';
              final isKoordinator =
                  widget.coordinatorId != null && m.id == widget.coordinatorId;
              return InputChip(
                label: Text(
                  name,
                  style: const TextStyle(color: Color(0xFF0F172A)),
                ),
                avatar: isKoordinator
                    ? const Icon(Icons.star, color: Colors.orange, size: 16)
                    : null,
                selected: isKoordinator,
                selectedColor: Colors.orange.withValues(alpha: 0.15),
                backgroundColor: const Color(0xFFE2E8F0),
                showCheckmark: false,
                side: BorderSide(
                  color: isKoordinator ? Colors.orange : Colors.transparent,
                ),
                deleteIcon: widget.isReadOnly
                    ? null
                    : const Icon(Icons.close, size: 18),
                onDeleted: widget.isReadOnly ? null : () => _removeMember(m),
                onPressed: widget.isReadOnly ? () {} : null,
              );
            }).toList(),
          ),
      ],
    );
  }
}
