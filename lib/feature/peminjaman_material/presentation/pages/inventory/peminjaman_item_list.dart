import 'package:flutter/material.dart' hide MaterialState;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_mobile_pdam/core/utils/auth_storage.dart';
import 'package:project_mobile_pdam/core/utils/app_snackbar.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/domain/entities_material/material_entity.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/domain/entities_material/peminjaman_material_entity.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/presentation/bloc/material/material_bloc.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/presentation/bloc/material/material_event.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/presentation/bloc/material/material_state.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/presentation/pages/inventory/pengajuan_item.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/presentation/pages/inventory/form_kembali_material_page.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/users/spv/landing_page.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/users/staff/landing_page.dart';

class PeminjamanItemListPage extends StatefulWidget {
  final int? workOrderId;
  const PeminjamanItemListPage({super.key, this.workOrderId});

  @override
  State<PeminjamanItemListPage> createState() => _PeminjamanItemListPageState();
}

class _PeminjamanItemListPageState extends State<PeminjamanItemListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _searchQuery = '';
  int _activeSegment = 0; // 0: Stock/Inventory, 1: Borrowed for this WO
  List<MaterialEntity> _masterMaterials = [];
  List<PeminjamanMaterialEntity> _borrowedMaterials = [];

  bool get _isStaff {
    final user = AuthStorage.getUserSync();
    final roleId = user?['role_id'] as int?;
    return roleId == 3 && AuthStorage.getJabatanKodeSync() != 'SPV';
  }

  bool get _isSpv {
    final user = AuthStorage.getUserSync();
    final roleId = user?['role_id'] as int?;
    return roleId == 3 && AuthStorage.getJabatanKodeSync() == 'SPV';
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _fetchData() {
    context.read<MaterialBloc>().add(GetMasterMaterialsEvent());
    if (widget.workOrderId != null) {
      context.read<MaterialBloc>().add(
        GetPeminjamanByWoEvent(widget.workOrderId!),
      );
    }
  }

  void _navigateToRoleDashboard(BuildContext context) {
    final targetPage = _isSpv
        ? const SpvLandingPage()
        : const StaffLandingPage();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => targetPage),
      (route) => false,
    );
  }

  String _getMaterialAsset(String category, String name) {
    final lowerCat = category.toLowerCase();
    final lowerName = name.toLowerCase();

    if (lowerCat.contains('pipa') ||
        lowerCat.contains('pipe') ||
        lowerCat.contains('perpipaan')) {
      if (lowerName.contains('pvc')) {
        return 'assets/images/Pipe/Pipa-PVC.jpg';
      }
      if (lowerName.contains('galvanis') || lowerName.contains('galvanized')) {
        return 'assets/images/Pipe/Pipe-galvanized.jpg';
      }
      return 'assets/images/Pipe/Pipa HDPE.jpg';
    } else if (lowerCat.contains('fitting')) {
      if (lowerName.contains('valve')) {
        return 'assets/images/Fitting/Air-Valve-Reinforced-Nylon-fitting.png';
      }
      if (lowerName.contains('elbow')) {
        return 'assets/images/Fitting/Elbow-90-derajat-fitting.png';
      }
      if (lowerName.contains('reducer')) {
        return 'assets/images/Fitting/Jual-Reducer-fitting.png';
      }
      if (lowerName.contains('clamp') || lowerName.contains('saddle')) {
        return 'assets/images/Fitting/Pipe-Fitting-Saddle-Clamp.png';
      }
      if (lowerName.contains('socket') ||
          lowerName.contains('connector') ||
          lowerName.contains('penyambung')) {
        return 'assets/images/Fitting/Socket-Penyambung-Lurus-Fitting.png';
      }
      if (lowerName.contains('tee')) {
        return 'assets/images/Fitting/Tee-fitting.jpg';
      }
      return 'assets/images/Fitting/Socket-Penyambung-Lurus-Fitting.png';
    } else if (lowerCat.contains('sr')) {
      if (lowerName.contains('valve')) {
        return 'assets/images/SR/Ball-Valve-1_2-sr.png';
      }
      if (lowerName.contains('box')) {
        return 'assets/images/SR/Box-Meter_ Plug-sr.png';
      }
      if (lowerName.contains('3/4')) {
        return 'assets/images/SR/Water-Meter-3_4-sr.png';
      }
      return 'assets/images/SR/Water-Meter-1_2-sr.png';
    }

    return 'assets/images/logo_pdam.png';
  }

  @override
  Widget build(BuildContext context) {
    final isStaff = _isStaff;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: SafeArea(
          child: BlocConsumer<MaterialBloc, MaterialState>(
            listener: (context, state) {
              if (state is MaterialActionSuccess) {
                AppSnackbar.showSuccess(state.message);
                _fetchData();
              } else if (state is MaterialError) {
                AppSnackbar.showError(state.message);
              }
            },
            builder: (context, state) {
              if (state is MasterMaterialsLoaded) {
                _masterMaterials = state.materials;
              } else if (state is PeminjamanLoaded) {
                _borrowedMaterials = state.peminjamanList;
              }
              return Column(
                children: [
                  _buildHeader(context),
                  if (widget.workOrderId != null) _buildSegmentControl(),
                  Expanded(
                    child: _activeSegment == 0
                        ? _buildStockTab(state, isStaff)
                        : _buildBorrowedTab(state, isStaff),
                  ),
                  // if (!isStaff)
                  //   Container(
                  //     width: double.infinity,
                  //     padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  //     color: Colors.white,
                  //     child: Text(
                  //       'Mode SPV: hanya melihat stok item.',
                  //       textAlign: TextAlign.center,
                  //       style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  //         color: colors.foreground[500],
                  //         fontWeight: FontWeight.w600,
                  //       ),
                  //     ),
                  //   ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: Color(0xFF6A7282),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'PDAM Surabaya Office',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF6A7282),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _navigateToRoleDashboard(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.home_rounded,
                    size: 18,
                    color: Color(0xFF101828),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Inventory Material',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: const Color(0xFF101828),
              fontWeight: FontWeight.w800,
            ),
          ),
          if (_activeSegment == 0) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        const Icon(Icons.search, color: Color(0xFF99A1AF)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            cursorColor: const Color(0xFF155DFC),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: const Color(0xFF101828),
                                  fontWeight: FontWeight.w500,
                                ),
                            decoration: InputDecoration(
                              isCollapsed: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                              border: InputBorder.none,
                              hintText: 'Search materials...',
                              hintStyle: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: const Color(0xFF99A1AF),
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: Color(0xFF99A1AF),
                            ),
                            onPressed: () => _searchController.clear(),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildChipTab('All'),
                  const SizedBox(width: 8),
                  _buildChipTab('Perpipaan'),
                  const SizedBox(width: 8),
                  _buildChipTab('Fitting'),
                  const SizedBox(width: 8),
                  _buildChipTab('SR'),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFD1D5DC)),
        ],
      ),
    );
  }

  Widget _buildChipTab(String category) {
    final isActive = _selectedCategory == category;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF155DFC) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isActive ? Colors.transparent : const Color(0xFFE5E7EB),
          ),
        ),
        child: Center(
          child: Text(
            category,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isActive ? Colors.white : const Color(0xFF4A5565),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentControl() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(2),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _activeSegment = 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: _activeSegment == 0
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: _activeSegment == 0
                        ? const [
                            BoxShadow(
                              color: Color(0x0F000000),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Daftar Stok',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _activeSegment == 0
                          ? const Color(0xFF101828)
                          : const Color(0xFF6A7282),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _activeSegment = 1),
                child: Container(
                  decoration: BoxDecoration(
                    color: _activeSegment == 1
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: _activeSegment == 1
                        ? const [
                            BoxShadow(
                              color: Color(0x0F000000),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Peminjaman Saya',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _activeSegment == 1
                          ? const Color(0xFF101828)
                          : const Color(0xFF6A7282),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockTab(MaterialState state, bool isStaff) {
    if (state is MaterialLoading && _masterMaterials.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is MaterialError && _masterMaterials.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF6A7282),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _fetchData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF155DFC),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (state is MasterMaterialsLoaded ||
        state is PeminjamanLoaded ||
        state is MaterialActionSuccess ||
        _masterMaterials.isNotEmpty) {
      // Get loaded materials
      List<MaterialEntity> rawList = _masterMaterials;

      if (rawList.isEmpty) {
        return const Center(child: Text('Stok material kosong.'));
      }

      // Filter by category
      var filteredList = rawList;
      if (_selectedCategory != 'All') {
        filteredList = filteredList.where((m) {
          final cat = m.kategori ?? '';
          return cat.toLowerCase() == _selectedCategory.toLowerCase();
        }).toList();
      }

      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        filteredList = filteredList.where((m) {
          final name = (m.namaMaterial ?? '').toLowerCase();
          final code = (m.kodeMaterial ?? '').toLowerCase();
          return name.contains(_searchQuery) || code.contains(_searchQuery);
        }).toList();
      }

      if (filteredList.isEmpty) {
        return const Center(
          child: Text('Tidak ada material yang cocok dengan pencarian.'),
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        itemCount: filteredList.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final m = filteredList[index];
          return _buildStockCard(m, isStaff);
        },
      );
    }

    return const Center(child: Text('Memuat data material...'));
  }

  Widget _buildStockCard(MaterialEntity m, bool isStaff) {
    final available = m.stokTersedia;
    final imageAsset = _getMaterialAsset(
      m.kategori ?? '',
      m.namaMaterial ?? '',
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x80F3F4F6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 104,
                  height: 104,
                  color: const Color(0xFFF3F4F6),
                  child: Image.asset(
                    imageAsset,
                    width: 104,
                    height: 104,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFE5E7EB),
                      child: const Icon(
                        Icons.build_outlined,
                        color: Color(0xFF9CA3AF),
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: SizedBox(
                  height: 104,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          (m.kategori ?? 'UMUM').toUpperCase(),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF155DFC),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        m.namaMaterial ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: const Color(0xFF101828),
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Kode: ${m.kodeMaterial} • Satuan: ${m.satuan}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF6A7282),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 4,
                            backgroundColor: available > 0
                                ? const Color(0xFF00C950)
                                : const Color(0xFFDC2626),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$available ${m.satuan ?? ""} tersedia',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: const Color(0xFF4A5565),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (isStaff && widget.workOrderId != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEFF6FF),
                  foregroundColor: const Color(0xFF155DFC),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  if (widget.workOrderId == null) {
                    AppSnackbar.showWarning(
                      'Peminjaman material hanya dapat diajukan melalui halaman Detail Work Order.',
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PengajuanItemPage(
                        material: m,
                        workOrderId: widget.workOrderId!,
                      ),
                    ),
                  ).then((_) => _fetchData());
                },
                child: const Text(
                  'Request to Borrow',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBorrowedTab(MaterialState state, bool isStaff) {
    if (state is MaterialLoading && _borrowedMaterials.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    List<PeminjamanMaterialEntity> peminjamanList = _borrowedMaterials;

    if (peminjamanList.isEmpty) {
      if (state is MaterialError) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  state.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF6A7282),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _fetchData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF155DFC),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        );
      }
      return const Center(
        child: Text('Belum ada material yang dipinjam untuk WO ini.'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      itemCount: peminjamanList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final item = peminjamanList[index];
        return _buildBorrowedCard(item, isStaff);
      },
    );
  }

  Widget _buildBorrowedCard(PeminjamanMaterialEntity item, bool isStaff) {
    final matName =
        item.material?.namaMaterial ?? 'Material #${item.materialId}';
    final matCat = item.material?.kategori ?? 'Umum';
    final matSatuan = item.material?.satuan ?? '';
    final imageAsset = _getMaterialAsset(matCat, matName);
    final isBorrowed = item.status == 'DIPINJAM';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x80F3F4F6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 90,
                  height: 90,
                  color: const Color(0xFFF3F4F6),
                  child: Image.asset(
                    imageAsset,
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFE5E7EB),
                      child: const Icon(
                        Icons.build_outlined,
                        color: Color(0xFF9CA3AF),
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: SizedBox(
                  height: 90,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              matCat.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF6A7282),
                              ),
                            ),
                          ),
                          _buildStatusBadge(item.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        matName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: const Color(0xFF101828),
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Jumlah: ${item.jumlahPinjam} $matSatuan',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF374151),
                            ),
                          ),
                          if (item.jumlahKembali != null)
                            Text(
                              'Kembali: ${item.jumlahKembali} $matSatuan',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF059669),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (isStaff && isBorrowed) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEFF6FF),
                  foregroundColor: const Color(0xFF155DFC),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => FormKembaliMaterialPage(peminjaman: item),
                  ).then((_) => _fetchData());
                },
                child: const Text(
                  'Kembalikan Material',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String? status) {
    Color bg = const Color(0xFFF3F4F6);
    Color fg = const Color(0xFF6A7282);
    String label = status ?? 'UNKNOWN';

    if (status == 'DIPINJAM') {
      bg = const Color(0xFFFFF7ED);
      fg = const Color(0xFFEA580C);
    } else if (status == 'PENDING_KEMBALI') {
      bg = const Color(0xFFEFF6FF);
      fg = const Color(0xFF155DFC);
    } else if (status == 'DIKEMBALIKAN') {
      bg = const Color(0xFFECFDF5);
      fg = const Color(0xFF059669);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: fg),
      ),
    );
  }
}
