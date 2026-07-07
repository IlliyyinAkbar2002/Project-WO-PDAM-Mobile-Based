import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:project_mobile_pdam/core/seed/maps_seed_model.dart';
import 'package:project_mobile_pdam/core/utils/app_snackbar.dart';
import 'package:project_mobile_pdam/core/utils/auth_storage.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/user_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/work_order_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/usecases/get_work_orders_usecase.dart';
import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/core/constants/work_order_constants.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_bloc.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_event.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_state.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/profile/profile_view_data.dart';
import 'package:project_mobile_pdam/core/widget/location_picker.dart';
import 'package:project_mobile_pdam/service/service_locator.dart';

class PengajuanLemburPage extends StatelessWidget {
  const PengajuanLemburPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WorkOrderBloc>(
      create: (_) => sl<WorkOrderBloc>(),
      child: const _PengajuanLemburPage(),
    );
  }
}

class _PengajuanLemburPage extends StatefulWidget {
  const _PengajuanLemburPage();

  @override
  State<_PengajuanLemburPage> createState() => _PengajuanLemburPageState();
}

class _PengajuanLemburPageState extends State<_PengajuanLemburPage> {
  final TextEditingController _durasiController = TextEditingController(
    text: '2',
  );
  final TextEditingController _alasanController = TextEditingController();
  final TextEditingController _lokasiController = TextEditingController();

  List<UserEntity> _availableUsers = const [];
  // Internal selection state
  String? _selectedWorkType;
  final List<UserEntity> _selectedMembers = [];

  DateTime? _tanggalLembur;
  TimeOfDay? _jamMulai;

  // Opsional; nilai persis enum BE: rendah | sedang | tinggi | urgent.
  String? _prioritas;
  double? _latitude;
  double? _longitude;
  int? _locationId;
  int? _koordinatorUserId;

  double? _woRefLat;
  double? _woRefLng;
  int? _woRefRadius;

  static const List<({String value, String label})> _prioritasOptions = [
    (value: 'rendah', label: 'Rendah'),
    (value: 'sedang', label: 'Sedang'),
    (value: 'tinggi', label: 'Tinggi'),
    (value: 'urgent', label: 'Urgent'),
  ];

  bool _isSubmitting = false;
  bool _usersRequested = false;

  List<WorkOrderEntity> _availableWorkOrders = const [];
  WorkOrderEntity? _selectedWorkOrder;
  bool _loadingWorkOrders = false;

  ({String name, String npp, String jabatan}) _getEmployeeInfo() {
    final user = AuthStorage.getUserSync() ?? <String, dynamic>{};
    final employee =
        (user['employee'] as Map<String, dynamic>?) ?? <String, dynamic>{};

    final name =
        (employee['name'] ?? user['name'] ?? '-').toString().trim().isEmpty
        ? '-'
        : (employee['name'] ?? user['name']).toString();

    final rawNpp =
        employee['employee_id'] ?? employee['nip'] ?? employee['npp'];
    final npp = (rawNpp == null || rawNpp.toString().trim().isEmpty)
        ? '-'
        : rawNpp.toString();

    final jabatan = ProfileViewDataResolver.resolvePositionLabel(user);

    return (name: name, npp: npp, jabatan: jabatan);
  }

  int? _callerDepartemenId() {
    final user = AuthStorage.getUserSync();
    final employee = user?['employee'];
    final dynamic raw =
        user?['departemen_id'] ??
        (employee is Map
            ? (employee['department_id'] ?? employee['departemen_id'])
            : null);
    return raw is int ? raw : int.tryParse(raw?.toString() ?? '');
  }

  List<UserEntity> _filterEligibleMembers(List<UserEntity> users) {
    const allowed = {'staff', 'staff senior'};
    return users.where((u) {
      final jabatan = u.employee?.jabatan?.trim().toLowerCase();
      return jabatan != null && allowed.contains(jabatan);
    }).toList();
  }

  bool _isStaffSenior(UserEntity u) {
    return (u.employee?.jabatan ?? '').trim().toLowerCase() == 'staff senior';
  }

  Future<void> _loadWorkOrders() async {
    setState(() => _loadingWorkOrders = true);
    try {
      final usecase = sl<GetWorkOrdersUseCase>();
      final result = await usecase(
        WorkOrderParams(
          page: 1,
          limit: 100,
          // status_id 12 → BE memfilter status string 'Pending'.
          status: const [WorkOrderStatusId.ditugaskanKeSpv],
        ),
      );

      List<WorkOrderEntity>? data;
      if (result is DataSuccess<List<WorkOrderEntity>>) {
        data = result.data;
      } else if (result is PaginatedDataSuccess<List<WorkOrderEntity>>) {
        data = result.data;
      }

      if (data != null) {
        final myPegawaiId = AuthStorage.getUserSync()?['pegawai_id'] as int?;
        final filtered = (myPegawaiId == null)
            ? const <WorkOrderEntity>[]
            : data
                  .where(
                    (wo) =>
                        wo.assignedToPegawaiId == myPegawaiId &&
                        wo.splId == null,
                  )
                  .toList();
        setState(() => _availableWorkOrders = filtered);
      }
    } catch (e) {
      debugPrint("Error loading work orders: $e");
    } finally {
      if (mounted) {
        setState(() => _loadingWorkOrders = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadWorkOrders();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bloc = context.read<WorkOrderBloc>();
      if (!_usersRequested) {
        _usersRequested = true;
        // Scope picker ke departemen pemohon agar BE tidak menolak anggota
        // lintas-departemen (422). Jabatan disaring FE-side via
        // _filterEligibleMembers (lihat listener UsersLoaded).
        bloc.add(GetUsersEvent(departemenId: _callerDepartemenId()));
      }
    });
  }

  @override
  void dispose() {
    _durasiController.dispose();
    _alasanController.dispose();
    _lokasiController.dispose();
    super.dispose();
  }

  Future<void> _pickTanggalLembur() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initialDate =
        (_tanggalLembur != null && !_tanggalLembur!.isBefore(today))
        ? _tanggalLembur!
        : today;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() => _tanggalLembur = picked);
    }
  }

  Future<void> _pickJamMulai() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _jamMulai ?? const TimeOfDay(hour: 16, minute: 0),
    );
    if (time != null) {
      if (time.hour < 16) {
        AppSnackbar.showError(
          'Jam mulai lembur harus di atas pukul 15:00 (mulai pukul 16:00).',
        );
        return;
      }
      setState(() => _jamMulai = time);
    }
  }

  Future<void> _pickWorkOrder() async {
    if (_availableWorkOrders.isEmpty && !_loadingWorkOrders) {
      AppSnackbar.showInfo('Tidak ada daftar pekerjaan aktif.');
      return;
    }

    final result = await showModalBottomSheet<WorkOrderEntity>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
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
                    'Pilih Pekerjaan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _loadingWorkOrders
                        ? const Center(child: CircularProgressIndicator())
                        : _availableWorkOrders.isEmpty
                        ? const Center(child: Text('Tidak ada pekerjaan aktif'))
                        : ListView.separated(
                            controller: scrollController,
                            itemCount: _availableWorkOrders.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (_, index) {
                              final wo = _availableWorkOrders[index];
                              final isSelected =
                                  _selectedWorkOrder?.id == wo.id;
                              return ListTile(
                                title: Text(
                                  wo.title,
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? const Color(0xFF2563EB)
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                                subtitle: Text(
                                  'Jenis: ${wo.workOrderType?.name ?? "Tidak ada tipe"}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        color: Color(0xFF2563EB),
                                      )
                                    : null,
                                onTap: () {
                                  Navigator.pop(sheetCtx, wo);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        _selectedWorkOrder = result;
        _applyParityFromWorkOrder(result);
      });
    }
  }

  void _applyParityFromWorkOrder(WorkOrderEntity wo) {
    _selectedWorkType = wo.workOrderType?.name;

    // Simpan apa adanya (lowercase) walau tidak ada di whitelist, supaya field
    // read-only tetap menampilkan prioritas WO yang valid namun tak terduga.
    final rawPrioritas = wo.prioritas?.trim().toLowerCase();
    _prioritas = (rawPrioritas == null || rawPrioritas.isEmpty)
        ? null
        : rawPrioritas;

    // Lokasi: teks lokasi WO (fallback ke nama master-location), hormati
    // maxLength 255.
    final woLokasi = (wo.lokasiText?.trim().isNotEmpty == true)
        ? wo.lokasiText!.trim()
        : (wo.assignment?.location?.nama.trim() ?? '');
    _lokasiController.text = woLokasi.length > 255
        ? woLokasi.substring(0, 255)
        : woLokasi;

    // Titik peta: hanya jika koordinat asli ditemukan. Jangan pernah 0,0.
    final coords = _coordsFromWorkOrder(wo);
    _latitude = coords?.$1;
    _longitude = coords?.$2;
    _locationId = (coords != null)
        ? (wo.assignment?.locationId ?? wo.assignment?.location?.id)
        : null;

    // Acuan lokasi WO untuk validasi jarak titik peta lembur.
    _woRefLat = coords?.$1;
    _woRefLng = coords?.$2;
    _woRefRadius = wo.assignment?.location?.radiusMeter;
  }

  (double, double)? _coordsFromWorkOrder(WorkOrderEntity wo) {
    final assignment = wo.assignment;
    if (assignment == null) return null;

    final lat = assignment.latitude;
    final lng = assignment.longitude;
    if (lat != null && lng != null && !(lat == 0 && lng == 0)) {
      return (lat, lng);
    }

    final loc = assignment.location;
    if (loc != null && !(loc.latitude == 0 && loc.longitude == 0)) {
      return (loc.latitude, loc.longitude);
    }
    return null;
  }

  /// Label tampilan untuk prioritas WO terpilih (read-only), atau null jika
  /// WO tidak punya prioritas. Nilai di luar whitelist tetap ditampilkan dengan
  /// title-case sebagai fallback agar field tidak pernah blank.
  String? get _prioritasLabel {
    final raw = _prioritas;
    if (raw == null || raw.isEmpty) return null;
    for (final opt in _prioritasOptions) {
      if (opt.value == raw) return opt.label;
    }
    return raw[0].toUpperCase() + raw.substring(1);
  }

  Future<void> _pickMembers() async {
    if (_availableUsers.isEmpty) {
      AppSnackbar.showInfo('Daftar pegawai belum tersedia.');
      return;
    }
    // Snapshot selection so user can cancel.
    final tempSelected = <int>{
      for (final m in _selectedMembers)
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
                        'Pilih Anggota Tim',
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
                          itemCount: _availableUsers.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, index) {
                            final user = _availableUsers[index];
                            final id = user.id;
                            final checked =
                                id != null && tempSelected.contains(id);
                            final name =
                                user.employee?.name ?? user.email ?? '-';
                            final subtitle = [
                              if (user.employee?.nip != null)
                                'NPP: ${user.employee?.nip}',
                              if (user.employee?.jabatan != null)
                                user.employee!.jabatan!,
                            ].join(' · ');
                            return CheckboxListTile(
                              value: checked,
                              onChanged: id == null
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
                              title: Text(name),
                              subtitle: subtitle.isEmpty
                                  ? null
                                  : Text(subtitle),
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
                            final picked = _availableUsers
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
        _selectedMembers
          ..clear()
          ..addAll(result);

        if (_koordinatorUserId != null &&
            !_selectedMembers.any((m) => m.id == _koordinatorUserId)) {
          _koordinatorUserId = null;
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatJamMulaiDisplay(TimeOfDay? time) {
    if (time == null) return 'Pilih jam mulai';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatSelesaiPreview() {
    if (_tanggalLembur == null || _jamMulai == null) {
      return 'Selesai akan dihitung otomatis';
    }
    final durasi = int.tryParse(_durasiController.text.trim()) ?? 0;
    final mulai = DateTime(
      _tanggalLembur!.year,
      _tanggalLembur!.month,
      _tanggalLembur!.day,
      _jamMulai!.hour,
      _jamMulai!.minute,
    );
    final selesai = mulai.add(Duration(hours: durasi));
    final jam = selesai.hour.toString().padLeft(2, '0');
    final menit = selesai.minute.toString().padLeft(2, '0');

    // Check if end time crosses midnight (00:00 next day)
    final startMins = _jamMulai!.hour * 60 + _jamMulai!.minute;
    final totalMins = startMins + (durasi * 60);
    if (totalMins > 1440) {
      return 'Selesai: ${_formatDate(selesai)} $jam:$menit WIB (Melebihi batas pukul 00:00)';
    }

    return 'Selesai: ${_formatDate(selesai)} $jam:$menit WIB';
  }

  /// Validate form and return null if OK, otherwise an error message.
  String? _validate() {
    if (_selectedWorkOrder == null) {
      return 'Pekerjaan wajib dipilih.';
    }
    if (_selectedWorkType == null) {
      return 'Jenis pekerjaan wajib dipilih.';
    }
    if (_tanggalLembur == null) {
      return 'Tanggal lembur wajib dipilih.';
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (_tanggalLembur!.isBefore(today)) {
      return 'Tanggal lembur tidak boleh kurang dari hari ini.';
    }
    if (_jamMulai == null) {
      return 'Jam mulai wajib dipilih.';
    }
    if (_jamMulai!.hour < 16) {
      return 'Jam mulai lembur harus di atas pukul 15:00 (mulai pukul 16:00).';
    }
    final estimasi = int.tryParse(_durasiController.text.trim());
    if (estimasi == null || estimasi <= 0) {
      return 'Estimasi waktu lembur tidak valid.';
    }

    // Check if end time crosses midnight (00:00 next day)
    final startMins = _jamMulai!.hour * 60 + _jamMulai!.minute;
    final totalMins = startMins + (estimasi * 60);
    if (totalMins > 1440) {
      return 'Waktu lembur tidak boleh melebihi pukul 00:00 (tengah malam).';
    }

    if (_alasanController.text.trim().isEmpty) {
      return 'Alasan lembur wajib diisi.';
    }
    if (_selectedMembers.isEmpty) {
      return 'Anggota tim wajib dipilih.';
    }
    if (_koordinatorUserId == null) {
      return 'Koordinator wajib dipilih (jabatan Staff Senior).';
    }
    final koordinatorMatches = _selectedMembers.where(
      (m) => m.id == _koordinatorUserId,
    );
    if (koordinatorMatches.isEmpty || !_isStaffSenior(koordinatorMatches.first)) {
      return 'Koordinator harus berjabatan Staff Senior.';
    }
    if (_latitude == null || _longitude == null) {
      return 'Titik peta wajib dipilih. Ketuk peta untuk menandai lokasi lembur.';
    }
    // Titik peta lembur tidak boleh jauh dari lokasi WO (acuan pengaduan).
    if (_woRefLat != null && _woRefLng != null) {
      final radius = (_woRefRadius ?? MapsSeedModel.defaultRadiusMeter)
          .toDouble();
      final dist = Geolocator.distanceBetween(
        _woRefLat!,
        _woRefLng!,
        _latitude!,
        _longitude!,
      );
      if (dist > radius) {
        return 'Titik peta lembur harus berada di sekitar lokasi WO '
            '(maks ${radius.round()} m).';
      }
    }
    return null;
  }

  Map<String, dynamic> _buildPayload() {
    final tanggal =
        '${_tanggalLembur!.year.toString().padLeft(4, '0')}-${_tanggalLembur!.month.toString().padLeft(2, '0')}-${_tanggalLembur!.day.toString().padLeft(2, '0')}';
    final jamMulai =
        '${_jamMulai!.hour.toString().padLeft(2, '0')}:${_jamMulai!.minute.toString().padLeft(2, '0')}';
    // KONTRAK members = pegawai_id (m_pegawai.id). UserModel.id dari
    // /v1/pegawai/filter MEMANG pegawai_id (PegawaiController@getPegawaiByFilter
    // mengembalikan id = pegawai.id), dan BE lembur (pegawai-centric)
    // memvalidasi members.* sebagai exists:m_pegawai,id. JANGAN ubah ke users.id.
    //
    // KOORDINATOR/PIC: BE TIDAK membaca koordinator_user_id. PIC = anggota
    // PERTAMA pada urutan insert (LemburApprovalService::attachMembers
    // sortBy('id') = urutan insert = urutan array members). Maka koordinator
    // terpilih diletakkan paling depan; .toSet() (LinkedHashSet) mempertahankan
    // urutan saat dedup.
    final orderedMembers = <UserEntity>[
      ..._selectedMembers.where((u) => u.id == _koordinatorUserId),
      ..._selectedMembers.where((u) => u.id != _koordinatorUserId),
    ];
    final memberIds = orderedMembers
        .map((u) => u.id)
        .whereType<int>()
        .toSet()
        .toList();
    final payload = {
      'judul_pekerjaan': _selectedWorkOrder?.title ?? '',
      'jenis_pekerjaan': _selectedWorkType,
      'tanggal_lembur': tanggal,
      'jam_mulai': jamMulai,
      'estimasi_jam': int.parse(_durasiController.text.trim()),
      'alasan_lembur': _alasanController.text.trim(),
      'members': memberIds,
      'work_order_id': _selectedWorkOrder?.id,
      'workorder_id': _selectedWorkOrder?.id,
    };

    if (_prioritas != null) {
      payload['prioritas'] = _prioritas;
    }
    final lokasi = _lokasiController.text.trim();
    if (lokasi.isNotEmpty) {
      payload['lokasi'] = lokasi;
      payload['nama_lokasi'] = lokasi;
    }
    if (_latitude != null && _longitude != null) {
      payload['latitude'] = double.parse(_latitude!.toStringAsFixed(7));
      payload['longitude'] = double.parse(_longitude!.toStringAsFixed(7));
    }
    if (_koordinatorUserId != null) {
      payload['koordinator_user_id'] = _koordinatorUserId;
    }

    return payload;
  }

  void _submit() {
    if (_isSubmitting) return;
    final error = _validate();
    if (error != null) {
      AppSnackbar.showError(error);
      return;
    }
    setState(() => _isSubmitting = true);
    context.read<WorkOrderBloc>().add(CreateSplEvent(_buildPayload()));
  }

  void _showSuccessDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'success',
      barrierColor: Colors.black.withValues(alpha: 0.25),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(color: Colors.black.withValues(alpha: 0.15)),
              ),
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1F000000),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8F8EE),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Color(0xFF16A34A),
                          size: 44,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Pengajuan Terkirim!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Pengajuan lembur Anda telah berhasil terkirim dan sedang menunggu persetujuan.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF475569),
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: Builder(
                          builder: (dialogCtx) => ElevatedButton(
                            onPressed: () {
                              // Tutup dialog & halaman pengajuan.
                              Navigator.of(dialogCtx).pop();
                              if (mounted && Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              minimumSize: const Size.fromHeight(48),
                            ),
                            child: const Text('Kembali ke Beranda'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: BlocListener<WorkOrderBloc, WorkOrderState>(
        listenWhen: (prev, curr) => prev != curr,
        listener: (context, state) {
          if (state is UsersLoaded) {
            setState(() {
              _availableUsers = _filterEligibleMembers(state.users);
              // Drop selections that no longer exist in the latest list.
              _selectedMembers.removeWhere(
                (u) => !_availableUsers.any((au) => au.id == u.id),
              );
            });
          } else if (state is SplCreated && _isSubmitting) {
            setState(() => _isSubmitting = false);
            _showSuccessDialog();
          } else if (state is WorkOrderError && _isSubmitting) {
            setState(() => _isSubmitting = false);
            AppSnackbar.showError(state.message);
          }
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFF5F7FB),
          body: SafeArea(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  color: Colors.white,
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        color: const Color(0xFF0F172A),
                      ),
                      const Expanded(
                        child: Text(
                          'Pengajuan Lembur',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Column(
                      children: [
                        Builder(
                          builder: (context) {
                            final info = _getEmployeeInfo();
                            return _SectionCard(
                              title: 'Informasi Pegawai',
                              child: Column(
                                children: [
                                  _InfoRow(
                                    label: 'Nama Pegawai',
                                    value: info.name,
                                  ),
                                  const SizedBox(height: 8),
                                  _InfoRow(label: 'NPP', value: info.npp),
                                  const SizedBox(height: 8),
                                  _InfoRow(
                                    label: 'Jabatan',
                                    value: info.jabatan,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _SectionCard(
                          title: 'Detail Lembur',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _FieldLabel('Judul Pekerjaan'),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: _pickWorkOrder,
                                borderRadius: BorderRadius.circular(12),
                                child: InputDecorator(
                                  decoration: _inputDecoration(
                                    hint: 'Pilih pekerjaan...',
                                    suffixIcon: _loadingWorkOrders
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.arrow_drop_down),
                                  ),
                                  child: Text(
                                    _selectedWorkOrder == null
                                        ? 'Pilih pekerjaan...'
                                        : _selectedWorkOrder!.title,
                                    style: TextStyle(
                                      color: _selectedWorkOrder == null
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const _FieldLabel('Jenis Pekerjaan'),
                              const SizedBox(height: 6),
                              InputDecorator(
                                decoration: _inputDecoration(
                                  hint: 'Pilih jenis pekerjaan...',
                                  fillColor: const Color(0xFFF1F5F9),
                                ),
                                child: Text(
                                  _selectedWorkType ??
                                      'Pilih jenis pekerjaan...',
                                  style: TextStyle(
                                    color: _selectedWorkType == null
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const _FieldLabel('Tanggal Lembur'),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: _pickTanggalLembur,
                                borderRadius: BorderRadius.circular(12),
                                child: InputDecorator(
                                  decoration: _inputDecoration(
                                    hint: 'Pilih tanggal lembur...',
                                    suffixIcon: const Icon(
                                      Icons.calendar_today,
                                    ),
                                  ),
                                  child: Text(
                                    _tanggalLembur == null
                                        ? 'Pilih tanggal lembur...'
                                        : _formatDate(_tanggalLembur),
                                    style: TextStyle(
                                      color: _tanggalLembur == null
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'Estimasi Waktu Lembur',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: _pickJamMulai,
                                      borderRadius: BorderRadius.circular(12),
                                      child: InputDecorator(
                                        decoration: _inputDecoration(
                                          hint: 'Mulai',
                                        ),
                                        child: Text(
                                          _formatJamMulaiDisplay(_jamMulai),
                                          style: TextStyle(
                                            color: _jamMulai == null
                                                ? const Color(0xFF94A3B8)
                                                : const Color(0xFF0F172A),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: _durasiController,
                                      keyboardType: TextInputType.number,
                                      onChanged: (_) => setState(() {}),
                                      decoration: _inputDecoration(
                                        hint: '2',
                                        suffixText: 'Jam',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Text(
                                  _formatSelesaiPreview(),
                                  style: const TextStyle(
                                    color: Color(0xFF334155),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              const _FieldLabel('Prioritas'),
                              const SizedBox(height: 6),
                              InputDecorator(
                                decoration: _inputDecoration(
                                  hint: 'Prioritas pekerjaan...',
                                  fillColor: const Color(0xFFF1F5F9),
                                ),
                                child: Text(
                                  _prioritasLabel ?? 'Mengikuti prioritas WO',
                                  style: TextStyle(
                                    color: _prioritasLabel == null
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const _FieldLabel('Lokasi'),
                              const SizedBox(height: 6),
                              InputDecorator(
                                decoration: _inputDecoration(
                                  hint: 'Lokasi pekerjaan...',
                                  fillColor: const Color(0xFFF1F5F9),
                                ),
                                child: Text(
                                  _lokasiController.text.isEmpty
                                      ? 'Mengikuti lokasi WO'
                                      : _lokasiController.text,
                                  style: TextStyle(
                                    color: _lokasiController.text.isEmpty
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF475569),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const _FieldLabel(
                                    'Titik Peta Work Order Lembur',
                                  ),
                                  const Spacer(),
                                  if (_latitude != null && _longitude != null)
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _latitude = null;
                                          _longitude = null;
                                          _locationId = null;
                                        });
                                      },
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 0,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        foregroundColor: const Color(
                                          0xFFEF4444,
                                        ),
                                      ),
                                      child: const Text('Hapus Pin'),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: LocationPicker(
                                  isStatic: true,
                                  isReadOnly: false,
                                  latitude: _latitude,
                                  longitude: _longitude,
                                  onLocationSelected:
                                      (
                                        lat,
                                        long, {
                                        locationId,
                                        radiusMeter,
                                        locationName,
                                      }) {
                                        setState(() {
                                          _latitude = lat;
                                          _longitude = long;
                                          _locationId = locationId;
                                        });
                                      },
                                ),
                              ),
                              const SizedBox(height: 6),
                              if (_selectedWorkOrder != null &&
                                  (_latitude == null || _longitude == null))
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFFCD34D),
                                    ),
                                  ),
                                  child: const Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        size: 18,
                                        color: Color(0xFFB45309),
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Titik peta belum dipilih. Ketuk peta untuk menandai lokasi lembur. '
                                          'Penanda merah saat ini hanya posisi awal peta, bukan lokasi tersimpan.',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF92400E),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Text(
                                  _selectedWorkOrder == null
                                      ? 'Pilih pekerjaan untuk menentukan titik peta.'
                                      : 'Titik peta harus berada di sekitar lokasi WO.',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const _FieldLabel('Anggota Tim'),
                                  const Spacer(),
                                  TextButton.icon(
                                    onPressed: _pickMembers,
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text('Pilih'),
                                  ),
                                ],
                              ),
                              if (_selectedMembers.isNotEmpty)
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    'Pilih anggota tim, lalu tentukan koordinator (Staff Senior) pada field Koordinator di bawah.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              if (_selectedMembers.isEmpty)
                                Text(
                                  _availableUsers.isEmpty
                                      ? 'Memuat daftar pegawai...'
                                      : 'Belum ada anggota dipilih',
                                  style: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 13,
                                  ),
                                )
                              else
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _selectedMembers.map((m) {
                                    final name =
                                        m.employee?.name ??
                                        m.email ??
                                        'User #${m.id}';
                                    final isKoordinator =
                                        _koordinatorUserId == m.id;
                                    return InputChip(
                                      label: Text(name),
                                      avatar: isKoordinator
                                          ? const Icon(
                                              Icons.star,
                                              color: Colors.orange,
                                              size: 16,
                                            )
                                          : null,
                                      deleteIcon: const Icon(
                                        Icons.close,
                                        size: 18,
                                      ),
                                      onDeleted: () {
                                        setState(() {
                                          _selectedMembers.remove(m);
                                          if (_koordinatorUserId == m.id) {
                                            _koordinatorUserId = null;
                                          }
                                        });
                                      },
                                      selected: isKoordinator,
                                      selectedColor: Colors.orange.withValues(
                                        alpha: 0.15,
                                      ),
                                      backgroundColor: const Color(0xFFE2E8F0),
                                      showCheckmark: false,
                                      side: BorderSide(
                                        color: isKoordinator
                                            ? Colors.orange
                                            : Colors.transparent,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              const SizedBox(height: 12),
                              const _FieldLabel('Koordinator (PIC)'),
                              const SizedBox(height: 6),
                              Builder(
                                builder: (context) {
                                  final seniorMembers = _selectedMembers
                                      .where(_isStaffSenior)
                                      .toList();
                                  final value =
                                      seniorMembers.any(
                                        (m) => m.id == _koordinatorUserId,
                                      )
                                      ? _koordinatorUserId
                                      : null;
                                  return DropdownButtonFormField<int>(
                                    key: ValueKey(value),
                                    initialValue: value,
                                    isExpanded: true,
                                    decoration: _inputDecoration(
                                      hint: 'Pilih koordinator dari tim',
                                    ),
                                    hint: Text(
                                      seniorMembers.isEmpty
                                          ? 'Tidak ada anggota Staff Senior'
                                          : 'Pilih koordinator dari tim',
                                      style: const TextStyle(
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                    items: seniorMembers
                                        .map(
                                          (m) => DropdownMenuItem<int>(
                                            value: m.id,
                                            child: Text(
                                              m.employee?.name ??
                                                  m.email ??
                                                  'User #${m.id}',
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: seniorMembers.isEmpty
                                        ? null
                                        : (val) => setState(
                                            () => _koordinatorUserId = val,
                                          ),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              const _FieldLabel('Alasan Lembur'),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _alasanController,
                                maxLines: 4,
                                decoration: _inputDecoration(
                                  hint: 'Tuliskan alasan lembur...',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(52),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.4,
                                    ),
                                  )
                                : const Text(
                                    'Ajukan Lembur',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration({
  required String hint,
  Widget? suffixIcon,
  String? suffixText,
  Color? fillColor,
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
    suffixIcon: suffixIcon,
    suffixText: suffixText,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    filled: true,
    fillColor: fillColor ?? Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF2563EB)),
    ),
  );
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF1E293B),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: const TextStyle(color: Color(0xFF64748B))),
        ),
        const Text(':  '),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
