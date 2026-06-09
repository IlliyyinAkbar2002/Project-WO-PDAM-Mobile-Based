import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:project_mobile_pdam/core/common/input_chip/bloc/chip_field_bloc.dart';
import 'package:project_mobile_pdam/feature/work_order/data/data_source/remote/form_remote_data_source.dart';
import 'package:project_mobile_pdam/feature/work_order/data/data_source/remote/location_type_remote_data_source.dart';
import 'package:project_mobile_pdam/feature/work_order/data/data_source/remote/master_location_remote_data_source.dart';
import 'package:project_mobile_pdam/feature/work_order/data/data_source/remote/progress_detail_remote_data_source.dart';
import 'package:project_mobile_pdam/feature/work_order/data/data_source/remote/spl_remote_data_source.dart';
import 'package:project_mobile_pdam/feature/work_order/data/data_source/remote/laporan_workorder_remote.dart';
import 'package:project_mobile_pdam/feature/work_order/data/repositories/laporan_workorder_repository_impl.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/repositories/laporan_workorder_repository.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/usecases/create_laporan_workorder_usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/data/data_source/remote/user_remote_data_source.dart';
import 'package:project_mobile_pdam/feature/work_order/data/data_source/remote/work_order_progress_remote_data_source.dart';
import 'package:project_mobile_pdam/feature/work_order/data/data_source/remote/work_order_lembur_remote_data.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/repositories/work_order_lembur_repository.dart';
import 'package:project_mobile_pdam/feature/work_order/data/repositories/work_order_lembur_repository_impl.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/usecases/work_order_lembur_progress_usecases/get_work_order_lembur_progress_detail_usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/usecases/work_order_lembur_progress_usecases/get_work_order_lembur_progresses_usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/usecases/work_order_lembur_progress_usecases/update_work_order_lembur_progress_usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/usecases/work_order_lembur_progress_usecases/resubmit_lembur_progress_usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/usecases/work_order_lembur_progress_usecases/get_lembur_progress_quota_usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/usecases/work_order_lembur_progress_usecases/get_lembur_progress_by_member_usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/lembur_bloc.dart';
import 'package:project_mobile_pdam/feature/work_order/data/data_source/remote/work_order_type_remote_data_source.dart';
import 'package:project_mobile_pdam/feature/work_order/data/repositories/form_repository_impl.dart';
import 'package:project_mobile_pdam/feature/work_order/data/repositories/location_type_repository_impl.dart';
import 'package:project_mobile_pdam/feature/work_order/data/repositories/master_location_repository_impl.dart';
import 'package:project_mobile_pdam/feature/work_order/data/repositories/progress_detail_repository_impl.dart';
import 'package:project_mobile_pdam/feature/work_order/data/repositories/spl_repository_impl.dart';
import 'package:project_mobile_pdam/feature/work_order/data/repositories/user_repository_impl.dart';
import 'package:project_mobile_pdam/feature/work_order/data/repositories/work_order_progress_repository_impl.dart';
import 'package:project_mobile_pdam/feature/work_order/data/repositories/work_order_type_repository_impl.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/repositories/form_repository.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/repositories/location_type_repository.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/repositories/master_location_repository.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/repositories/progress_detail_repository.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/repositories/spl_repository.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/repositories/user_repository.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/repositories/work_order_progress_repository.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/repositories/work_order_type_repository.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/usecases/form_usecases/get_forms_usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/usecases/location_type_usecases/get_location_type_detail_usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/usecases/location_type_usecases/get_location_types_usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/usecases/master_location_usecases/get_master_locations_usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/usecases/progress_detail_usecases/get_progress_details_usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/usecases/progress_detail_usecases/update_progress_detail_usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/usecases/spl_usecases/create_spl_usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/usecases/spl_usecases/get_spl_detail.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/usecases/spl_usecases/update_spl_usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/usecases/user_usecases/get_user_detail_usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/usecases/user_usecases/get_users_usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/usecases/work_order_progress_usecases/get_work_order_progress_detail_usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/usecases/work_order_progress_usecases/get_work_order_progresses_usecases.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/usecases/work_order_progress_usecases/update_work_order_progress_usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/usecases/work_order_progress_usecases/resubmit_progress_usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/usecases/work_order_progress_usecases/get_progress_quota_usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/usecases/work_order_progress_usecases/get_progress_by_member_usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/usecases/work_order_type_usecases/get_work_order_type_detail_usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/usecases/work_order_type_usecases/get_work_order_types_usecase.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/data/remote/material_remote_data_source.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/domain/repository/material_repository_impl.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/domain/repository/material_repository.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/domain/usecases_material/get_master_materials.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/domain/usecases_material/get_peminjaman_by_wo.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/domain/usecases_material/pinjam_material.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/domain/usecases_material/kembalikan_material.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/presentation/bloc/material/material_bloc.dart';
import '/feature/work_order/data/data_source/remote/work_order_remote_data_source.dart';
import '/feature/work_order/data/repositories/work_order_repository_impl.dart';
import '/feature/work_order/domain/repositories/work_order_repository.dart';
import '/feature/work_order/domain/usecases/get_work_orders_usecase.dart';
import '/feature/work_order/domain/usecases/create_work_order_usecase.dart';
import '/feature/work_order/domain/usecases/get_work_order_detail_usecase.dart';
import '/feature/work_order/domain/usecases/update_work_order_usecase.dart';
import '/feature/work_order/domain/usecases/delete_work_order_usecase.dart';
import '/feature/work_order/presentation/bloc/work_order_bloc.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/journal_draft_cubit.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/laporan_workorder_cubit.dart';
import 'package:project_mobile_pdam/feature/work_order/data/data_source/remote/notification_remote_data_source.dart';
import 'package:project_mobile_pdam/feature/work_order/data/repositories/notification_repository_impl.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/repositories/notification_repository.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/usecases/notification_usecases/get_notifications_usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/usecases/notification_usecases/mark_notification_as_read_usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/notification_bloc.dart';


final sl = GetIt.instance;

Future<void> init() async {
  try {
    debugPrint("🔧 Memulai inisialisasi dependency...");

    // **1️⃣ Data Sources**
    sl.registerLazySingleton<WorkOrderRemoteDataSource>(
      () => WorkOrderRemoteDataSource(),
    );
    debugPrint("✅ WorkOrderRemoteDataSource terdaftar");

    sl.registerLazySingleton<NotificationRemoteDataSource>(
      () => NotificationRemoteDataSource(),
    );
    debugPrint("✅ NotificationRemoteDataSource terdaftar");

    sl.registerLazySingleton<WorkOrderTypeRemoteDataSource>(
      () => WorkOrderTypeRemoteDataSource(),
    );
    debugPrint("✅ WorkOrderTypeRemoteDataSource terdaftar");

    sl.registerLazySingleton<LocationTypeRemoteDataSource>(
      () => LocationTypeRemoteDataSource(),
    );
    debugPrint("✅ LocationTypeRemoteDataSource terdaftar");

    sl.registerLazySingleton<UserRemoteDataSource>(
      () => UserRemoteDataSource(),
    );
    debugPrint("✅ UserRemoteDataSource terdaftar");

    sl.registerLazySingleton<SplRemoteDataSource>(() => SplRemoteDataSource());

    sl.registerLazySingleton<WorkOrderProgressRemoteDataSource>(
      () => WorkOrderProgressRemoteDataSource(),
    );
    debugPrint("✅ WorkOrderProgressRemoteDataSource terdaftar");

    sl.registerLazySingleton<ProgressDetailRemoteDataSource>(
      () => ProgressDetailRemoteDataSource(),
    );
    debugPrint("✅ ProgressDetailRemoteDataSource terdaftar");

    sl.registerLazySingleton<FormRemoteDataSource>(
      () => FormRemoteDataSource(),
    );
    debugPrint("✅ FormRemoteDataSource terdaftar");

    sl.registerLazySingleton<MasterLocationRemoteDataSource>(
      () => MasterLocationRemoteDataSource(),
    );
    debugPrint("✅ MasterLocationRemoteDataSource terdaftar");

    sl.registerLazySingleton<MaterialRemoteDataSource>(
      () => MaterialRemoteDataSource(),
    );
    debugPrint("✅ MaterialRemoteDataSource terdaftar");

    sl.registerLazySingleton<LaporanWorkorderRemoteDataSource>(
      () => LaporanWorkorderRemoteDataSourceImpl(),
    );
    debugPrint("✅ LaporanWorkorderRemoteDataSource terdaftar");

    sl.registerLazySingleton<WorkOrderLemburRemoteDataSource>(
      () => WorkOrderLemburRemoteDataSource(),
    );
    debugPrint("✅ WorkOrderLemburRemoteDataSource terdaftar");

    // **2️⃣ Repository**
    sl.registerLazySingleton<WorkOrderRepository>(
      () => WorkOrderRepositoryImpl(sl<WorkOrderRemoteDataSource>()),
    );
    debugPrint("✅ WorkOrderRepository terdaftar");

    sl.registerLazySingleton<NotificationRepository>(
      () => NotificationRepositoryImpl(sl<NotificationRemoteDataSource>()),
    );
    debugPrint("✅ NotificationRepository terdaftar");

    sl.registerLazySingleton<WorkOrderTypeRepository>(
      () => WorkOrderTypeRepositoryImpl(
        sl<WorkOrderTypeRemoteDataSource>(), // remoteDataSource
      ),
    );
    debugPrint("✅ WorkOrderTypeRepository terdaftar");

    sl.registerLazySingleton<LocationTypeRepository>(
      () => LocationTypeRepositoryImpl(
        sl<LocationTypeRemoteDataSource>(), // remoteDataSource
      ),
    );
    debugPrint("✅ LocationTypeRepository terdaftar");

    sl.registerLazySingleton<UserRepository>(
      () => UserRepositoryImpl(
        sl<UserRemoteDataSource>(), // remoteDataSource
      ),
    );
    debugPrint("✅ UserRepository terdaftar");

    sl.registerLazySingleton<SplRepository>(
      () => SplRepositoryImpl(
        sl<SplRemoteDataSource>(), // remoteDataSource
      ),
    );
    debugPrint("✅ SplRepository terdaftar");

    sl.registerLazySingleton<WorkOrderProgressRepository>(
      () => WorkOrderProgressRepositoryImpl(
        sl<WorkOrderProgressRemoteDataSource>(), // remoteDataSource
      ),
    );
    debugPrint("✅ WorkOrderProgressRepository terdaftar");

    sl.registerLazySingleton<ProgressDetailRepository>(
      () => ProgressDetailRepositoryImpl(
        sl<ProgressDetailRemoteDataSource>(), // localDataSource
      ),
    );
    debugPrint("✅ ProgressDetailRepository terdaftar");

    sl.registerLazySingleton<FormRepository>(
      () => FormRepositoryImpl(
        sl<FormRemoteDataSource>(), // localDataSource
      ),
    );
    debugPrint("✅ FormRepository terdaftar");

    sl.registerLazySingleton<MasterLocationRepository>(
      () => MasterLocationRepositoryImpl(
        sl<MasterLocationRemoteDataSource>(), // remoteDataSource
      ),
    );
    debugPrint("✅ MasterLocationRepository terdaftar");

    sl.registerLazySingleton<MaterialRepository>(
      () => MaterialRepositoryImpl(sl<MaterialRemoteDataSource>()),
    );
    debugPrint("✅ MaterialRepository terdaftar");

    sl.registerLazySingleton<LaporanWorkorderRepository>(
      () => LaporanWorkorderRepositoryImpl(
        sl<LaporanWorkorderRemoteDataSource>(),
      ),
    );
    debugPrint("✅ LaporanWorkorderRepository terdaftar");

    sl.registerLazySingleton<WorkOrderLemburRepository>(
      () => WorkOrderLemburRepositoryImpl(
        sl<WorkOrderLemburRemoteDataSource>(),
      ),
    );
    debugPrint("✅ WorkOrderLemburRepository terdaftar");

    // **4️⃣ Use Cases**
    sl.registerLazySingleton(
      () => GetWorkOrdersUseCase(sl<WorkOrderRepository>()),
    );
    sl.registerLazySingleton(
      () => GetNotificationsUseCase(sl<NotificationRepository>()),
    );
    sl.registerLazySingleton(
      () => MarkNotificationAsReadUseCase(sl<NotificationRepository>()),
    );
    sl.registerLazySingleton(
      () => CreateWorkOrderUseCase(sl<WorkOrderRepository>()),
    );
    sl.registerLazySingleton(
      () => GetWorkOrderDetailUseCase(sl<WorkOrderRepository>()),
    );
    sl.registerLazySingleton(
      () => UpdateWorkOrderUseCase(sl<WorkOrderRepository>()),
    );
    sl.registerLazySingleton(
      () => DeleteWorkOrderUseCase(sl<WorkOrderRepository>()),
    );

    sl.registerLazySingleton(
      () => CreateLaporanWorkorderUseCase(sl<LaporanWorkorderRepository>()),
    );

    //work order type
    sl.registerLazySingleton(
      () => GetWorkOrderTypesUsecase(sl<WorkOrderTypeRepository>()),
    );
    sl.registerLazySingleton(
      () => GetWorkOrderTypeDetailUsecase(sl<WorkOrderTypeRepository>()),
    );

    //location type
    sl.registerLazySingleton(
      () => GetLocationTypesUsecase(sl<LocationTypeRepository>()),
    );
    sl.registerLazySingleton(
      () => GetLocationTypeDetailUsecase(sl<LocationTypeRepository>()),
    );

    //user
    sl.registerLazySingleton(() => GetUsersUsecase(sl<UserRepository>()));
    sl.registerLazySingleton(() => GetUserDetailUsecase(sl<UserRepository>()));

    //spl
    // sl.registerLazySingleton(() => GetSplsUsecase(sl<SplRepository>()));
    sl.registerLazySingleton(() => GetSplDetailUseCase(sl<SplRepository>()));
    sl.registerLazySingleton(() => UpdateSplUseCase(sl<SplRepository>()));
    sl.registerLazySingleton(() => CreateSplUseCase(sl<SplRepository>()));

    //progress
    sl.registerLazySingleton(
      () => GetProgressByWorkOrderIdUsecase(sl<WorkOrderProgressRepository>()),
    );
    
    // lembur progress
    sl.registerLazySingleton(() => GetLemburProgressByWorkOrderIdUsecase(sl<WorkOrderLemburRepository>()));
    sl.registerLazySingleton(() => GetWorkOrderLemburProgressDetailUsecase(sl<WorkOrderLemburRepository>()));
    sl.registerLazySingleton(() => UpdateWorkOrderLemburProgressUseCase(sl<WorkOrderLemburRepository>()));
    sl.registerLazySingleton(() => ResubmitLemburProgressUseCase(sl<WorkOrderLemburRepository>()));
    sl.registerLazySingleton(() => GetLemburProgressQuotaUseCase(sl<WorkOrderLemburRepository>()));
    sl.registerLazySingleton(() => GetLemburProgressByMemberUseCase(sl<WorkOrderLemburRepository>()));
    sl.registerLazySingleton(
      () =>
          GetWorkOrderProgressDetailUsecase(sl<WorkOrderProgressRepository>()),
    );
    sl.registerLazySingleton(
      () => UpdateWorkOrderProgressUseCase(sl<WorkOrderProgressRepository>()),
    );
    sl.registerLazySingleton(
      () => ResubmitProgressUseCase(sl<WorkOrderProgressRepository>()),
    );
    sl.registerLazySingleton(
      () => GetProgressQuotaUseCase(sl<WorkOrderProgressRepository>()),
    );
    sl.registerLazySingleton(
      () => GetProgressByMemberUseCase(sl<WorkOrderProgressRepository>()),
    );

    //progress detail
    sl.registerLazySingleton(
      () => GetProgressDetailsUsecase(sl<ProgressDetailRepository>()),
    );
    sl.registerLazySingleton(
      () => UpdateProgressDetailUseCase(sl<ProgressDetailRepository>()),
    );

    //form
    sl.registerLazySingleton(
      () => GetFormByWorkOrderTypeIdUsecase(sl<FormRepository>()),
    );

    //master location
    sl.registerLazySingleton(
      () => GetMasterLocationsUsecase(sl<MasterLocationRepository>()),
    );

    //material
    sl.registerLazySingleton(
      () => GetMasterMaterials(sl<MaterialRepository>()),
    );
    sl.registerLazySingleton(() => GetPeminjamanByWo(sl<MaterialRepository>()));
    sl.registerLazySingleton(() => PinjamMaterial(sl<MaterialRepository>()));
    sl.registerLazySingleton(
      () => KembalikanMaterial(sl<MaterialRepository>()),
    );

    debugPrint("✅ Semua use case terdaftar");

    // **5️⃣ Bloc**
    sl.registerFactory(
      () => LaporanWorkorderCubit(sl<CreateLaporanWorkorderUseCase>()),
    );
    sl.registerFactory(
      () => NotificationBloc(
        sl<GetNotificationsUseCase>(),
        sl<MarkNotificationAsReadUseCase>(),
      ),
    );
    debugPrint("✅ NotificationBloc terdaftar");
    sl.registerFactory(
      () => WorkOrderBloc(
        sl<GetWorkOrdersUseCase>(),
        sl<GetWorkOrderDetailUseCase>(),
        sl<CreateWorkOrderUseCase>(),
        sl<UpdateWorkOrderUseCase>(),
        sl<DeleteWorkOrderUseCase>(),

        //work order type
        sl<GetWorkOrderTypesUsecase>(),
        sl<GetWorkOrderTypeDetailUsecase>(),

        //location type
        sl<GetLocationTypesUsecase>(),
        sl<GetLocationTypeDetailUsecase>(),

        //user
        sl<GetUsersUsecase>(),
        sl<GetUserDetailUsecase>(),

        //spl
        sl<GetSplDetailUseCase>(),
        sl<UpdateSplUseCase>(),
        sl<CreateSplUseCase>(),

        //progress
        sl<GetProgressByWorkOrderIdUsecase>(),
        sl<GetWorkOrderProgressDetailUsecase>(),
        sl<UpdateWorkOrderProgressUseCase>(),
        sl<ResubmitProgressUseCase>(),
        sl<GetProgressQuotaUseCase>(),
        sl<GetProgressByMemberUseCase>(),

        //progress detail
        sl<GetProgressDetailsUsecase>(),
        sl<UpdateProgressDetailUseCase>(),

        //form
        sl<GetFormByWorkOrderTypeIdUsecase>(),

        //master location
        sl<GetMasterLocationsUsecase>(),
      ),
    );
    debugPrint("✅ WorkOrderBloc terdaftar");

    // Register ChipFieldBloc
    sl.registerFactory(() => ChipFieldBloc());
    debugPrint("✅ ChipFieldBloc terdaftar");

    sl.registerFactory(
      () => MaterialBloc(
        getMasterMaterials: sl<GetMasterMaterials>(),
        getPeminjamanByWo: sl<GetPeminjamanByWo>(),
        pinjamMaterial: sl<PinjamMaterial>(),
        kembalikanMaterial: sl<KembalikanMaterial>(),
      ),
    );
    debugPrint("✅ MaterialBloc terdaftar");

    sl.registerLazySingleton(() => JournalDraftCubit());
    debugPrint("✅ JournalDraftCubit terdaftar");

    sl.registerFactory(
      () => LemburBloc(
        getLemburProgressByWorkOrderIdUsecase: sl<GetLemburProgressByWorkOrderIdUsecase>(),
        getWorkOrderLemburProgressDetailUsecase: sl<GetWorkOrderLemburProgressDetailUsecase>(),
        updateWorkOrderLemburProgressUseCase: sl<UpdateWorkOrderLemburProgressUseCase>(),
        resubmitLemburProgressUseCase: sl<ResubmitLemburProgressUseCase>(),
        getLemburProgressQuotaUseCase: sl<GetLemburProgressQuotaUseCase>(),
        getLemburProgressByMemberUseCase: sl<GetLemburProgressByMemberUseCase>(),
        workOrderLemburRepository: sl<WorkOrderLemburRepository>(),
      ),
    );
    debugPrint("✅ LemburBloc terdaftar");

    debugPrint("🎉 Semua dependency berhasil diinisialisasi!");
  } catch (e, stacktrace) {
    debugPrint("❌ Gagal menginisialisasi dependency: $e");
    debugPrint("Stacktrace: $stacktrace");
    rethrow; // ⚠️ Rethrow agar main.dart tahu ada error
  }
}
