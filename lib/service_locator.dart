import 'package:get_it/get_it.dart';
import 'package:project_mobile_pdam/core/common/input_chip/bloc/chip_field_bloc.dart';
import 'package:project_mobile_pdam/feature/work_order/data/data_source/remote/form_remote_data_source.dart';
import 'package:project_mobile_pdam/feature/work_order/data/data_source/remote/location_type_remote_data_source.dart';
import 'package:project_mobile_pdam/feature/work_order/data/data_source/remote/master_location_remote_data_source.dart';
import 'package:project_mobile_pdam/feature/work_order/data/data_source/remote/progress_detail_remote_data_source.dart';
import 'package:project_mobile_pdam/feature/work_order/data/data_source/remote/spl_remote_data_source.dart';
import 'package:project_mobile_pdam/feature/work_order/data/data_source/remote/user_remote_data_source.dart';
import 'package:project_mobile_pdam/feature/work_order/data/data_source/remote/work_order_progress_remote_data_source.dart';
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
import 'package:project_mobile_pdam/feature/work_order/domain/usecases/spl_usecases/get_spl_detail.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/usecases/spl_usecases/update_spl_usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/usecases/user_usecases/get_user_detail_usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/usecases/user_usecases/get_users_usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/usecases/work_order_progress_usecases/get_work_order_progress_detail_usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/usecases/work_order_progress_usecases/get_work_order_progresses_usecases.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/usecases/work_order_progress_usecases/update_work_order_progress_usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/usecases/work_order_type_usecases/get_work_order_type_detail_usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/usecases/work_order_type_usecases/get_work_order_types_usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/data/data_source/remote/material_remote_data_source.dart';
import 'package:project_mobile_pdam/feature/work_order/data/repository/material_repository_impl.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/repository/material_repository.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/usecases/get_master_materials.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/usecases/get_peminjaman_by_wo.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/usecases/pinjam_material.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/usecases/kembalikan_material.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/material/material_bloc.dart';
import '/feature/work_order/data/data_source/remote/work_order_remote_data_source.dart';
import '/feature/work_order/data/repositories/work_order_repository_impl.dart';
import '/feature/work_order/domain/repositories/work_order_repository.dart';
import '/feature/work_order/domain/usecases/get_work_orders_usecase.dart';
import '/feature/work_order/domain/usecases/create_work_order_usecase.dart';
import '/feature/work_order/domain/usecases/get_work_order_detail_usecase.dart';
import '/feature/work_order/domain/usecases/update_work_order_usecase.dart';
import '/feature/work_order/domain/usecases/delete_work_order_usecase.dart';
import '/feature/work_order/presentation/bloc/work_order_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  try {
    print("🔧 Memulai inisialisasi dependency...");

    // **1️⃣ Data Sources**
    sl.registerLazySingleton<WorkOrderRemoteDataSource>(
      () => WorkOrderRemoteDataSource(),
    );
    print("✅ WorkOrderRemoteDataSource terdaftar");

    sl.registerLazySingleton<WorkOrderTypeRemoteDataSource>(
      () => WorkOrderTypeRemoteDataSource(),
    );
    print("✅ WorkOrderTypeRemoteDataSource terdaftar");

    sl.registerLazySingleton<LocationTypeRemoteDataSource>(
      () => LocationTypeRemoteDataSource(),
    );
    print("✅ LocationTypeRemoteDataSource terdaftar");

    sl.registerLazySingleton<UserRemoteDataSource>(
      () => UserRemoteDataSource(),
    );
    print("✅ UserRemoteDataSource terdaftar");

    sl.registerLazySingleton<SplRemoteDataSource>(() => SplRemoteDataSource());

    sl.registerLazySingleton<WorkOrderProgressRemoteDataSource>(
      () => WorkOrderProgressRemoteDataSource(),
    );
    print("✅ WorkOrderProgressRemoteDataSource terdaftar");

    sl.registerLazySingleton<ProgressDetailRemoteDataSource>(
      () => ProgressDetailRemoteDataSource(),
    );
    print("✅ ProgressDetailRemoteDataSource terdaftar");

    sl.registerLazySingleton<FormRemoteDataSource>(
      () => FormRemoteDataSource(),
    );
    print("✅ FormRemoteDataSource terdaftar");

    sl.registerLazySingleton<MasterLocationRemoteDataSource>(
      () => MasterLocationRemoteDataSource(),
    );
    print("✅ MasterLocationRemoteDataSource terdaftar");

    sl.registerLazySingleton<MaterialRemoteDataSource>(
      () => MaterialRemoteDataSource(),
    );
    print("✅ MaterialRemoteDataSource terdaftar");

    // **2️⃣ Repository**
    sl.registerLazySingleton<WorkOrderRepository>(
      () => WorkOrderRepositoryImpl(sl<WorkOrderRemoteDataSource>()),
    );
    print("✅ WorkOrderRepository terdaftar");

    sl.registerLazySingleton<WorkOrderTypeRepository>(
      () => WorkOrderTypeRepositoryImpl(
        sl<WorkOrderTypeRemoteDataSource>(), // remoteDataSource
      ),
    );
    print("✅ WorkOrderTypeRepository terdaftar");

    sl.registerLazySingleton<LocationTypeRepository>(
      () => LocationTypeRepositoryImpl(
        sl<LocationTypeRemoteDataSource>(), // remoteDataSource
      ),
    );
    print("✅ LocationTypeRepository terdaftar");

    sl.registerLazySingleton<UserRepository>(
      () => UserRepositoryImpl(
        sl<UserRemoteDataSource>(), // remoteDataSource
      ),
    );
    print("✅ UserRepository terdaftar");

    sl.registerLazySingleton<SplRepository>(
      () => SplRepositoryImpl(
        sl<SplRemoteDataSource>(), // remoteDataSource
      ),
    );
    print("✅ SplRepository terdaftar");

    sl.registerLazySingleton<WorkOrderProgressRepository>(
      () => WorkOrderProgressRepositoryImpl(
        sl<WorkOrderProgressRemoteDataSource>(), // remoteDataSource
      ),
    );
    print("✅ WorkOrderProgressRepository terdaftar");

    sl.registerLazySingleton<ProgressDetailRepository>(
      () => ProgressDetailRepositoryImpl(
        sl<ProgressDetailRemoteDataSource>(), // localDataSource
      ),
    );
    print("✅ ProgressDetailRepository terdaftar");

    sl.registerLazySingleton<FormRepository>(
      () => FormRepositoryImpl(
        sl<FormRemoteDataSource>(), // localDataSource
      ),
    );
    print("✅ FormRepository terdaftar");

    sl.registerLazySingleton<MasterLocationRepository>(
      () => MasterLocationRepositoryImpl(
        sl<MasterLocationRemoteDataSource>(), // remoteDataSource
      ),
    );
    print("✅ MasterLocationRepository terdaftar");

    sl.registerLazySingleton<MaterialRepository>(
      () => MaterialRepositoryImpl(
        sl<MaterialRemoteDataSource>(),
      ),
    );
    print("✅ MaterialRepository terdaftar");

    // **4️⃣ Use Cases**
    sl.registerLazySingleton(
      () => GetWorkOrdersUseCase(sl<WorkOrderRepository>()),
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

    //progress
    sl.registerLazySingleton(
      () => GetProgressByWorkOrderIdUsecase(sl<WorkOrderProgressRepository>()),
    );
    sl.registerLazySingleton(
      () =>
          GetWorkOrderProgressDetailUsecase(sl<WorkOrderProgressRepository>()),
    );
    sl.registerLazySingleton(
      () => UpdateWorkOrderProgressUseCase(sl<WorkOrderProgressRepository>()),
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
    sl.registerLazySingleton(() => GetMasterMaterials(sl<MaterialRepository>()));
    sl.registerLazySingleton(() => GetPeminjamanByWo(sl<MaterialRepository>()));
    sl.registerLazySingleton(() => PinjamMaterial(sl<MaterialRepository>()));
    sl.registerLazySingleton(() => KembalikanMaterial(sl<MaterialRepository>()));

    print("✅ Semua use case terdaftar");

    // **5️⃣ Bloc**
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

        //progress
        sl<GetProgressByWorkOrderIdUsecase>(),
        sl<GetWorkOrderProgressDetailUsecase>(),
        sl<UpdateWorkOrderProgressUseCase>(),

        //progress detail
        sl<GetProgressDetailsUsecase>(),
        sl<UpdateProgressDetailUseCase>(),

        //form
        sl<GetFormByWorkOrderTypeIdUsecase>(),

        //master location
        sl<GetMasterLocationsUsecase>(),
      ),
    );
    print("✅ WorkOrderBloc terdaftar");

    // Register ChipFieldBloc
    sl.registerFactory(() => ChipFieldBloc());
    print("✅ ChipFieldBloc terdaftar");

    sl.registerFactory(
      () => MaterialBloc(
        getMasterMaterials: sl<GetMasterMaterials>(),
        getPeminjamanByWo: sl<GetPeminjamanByWo>(),
        pinjamMaterial: sl<PinjamMaterial>(),
        kembalikanMaterial: sl<KembalikanMaterial>(),
      ),
    );
    print("✅ MaterialBloc terdaftar");

    print("🎉 Semua dependency berhasil diinisialisasi!");
  } catch (e, stacktrace) {
    print("❌ Gagal menginisialisasi dependency: $e");
    print(stacktrace);
    rethrow; // ⚠️ Rethrow agar main.dart tahu ada error
  }
}
