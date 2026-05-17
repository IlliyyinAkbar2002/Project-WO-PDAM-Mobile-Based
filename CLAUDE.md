# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Mobile app for PDAM (water utility company) work order management. Built with Flutter (SDK ^3.9.2). The app handles work order creation, assignment, progress tracking, material borrowing, and reporting for field staff, supervisors, and managers.

Backend is a Laravel API accessed via REST endpoints at `/api/v1/`.

## Commands

```bash
# Get dependencies
flutter pub get

# Run code generation (retrofit, build_runner)
dart run build_runner build --delete-conflicting-outputs

# Run on device/emulator
flutter run

# Run tests
flutter test
flutter test test/core/resource/data_state_test.dart  # single test

# Analyze
flutter analyze
```

## Environment Setup

Copy `.env.example` to `.env` and fill in:
- `ENVIRONMENT` — development/production
- `BACKEND_DOMAIN` — API base URL
- `GOOGLE_MAPS_API` — Google Maps API key

## Architecture

Clean Architecture with three layers per feature:

```
lib/feature/<feature_name>/
├── data/
│   ├── data_source/remote/   — API calls (extend RemoteDatasource)
│   ├── models/               — JSON serialization, toEntity()/fromEntity()
│   └── repositories/         — Repository implementations
├── domain/
│   ├── entities/             — Pure domain objects
│   ├── repositories/         — Abstract repository contracts
│   └── usecases/             — Single-responsibility use cases
└── presentation/
    ├── bloc/                 — BLoC state management
    └── pages/                — UI widgets
```

### Key Patterns

- **Dependency Injection**: `get_it` configured in `lib/service/service_locator.dart`. All data sources, repositories, use cases, and blocs are registered there.
- **State Management**: `flutter_bloc`. Main blocs: `WorkOrderBloc`, `MaterialBloc`, `JournalDraftCubit`.
- **Networking**: `Dio` via `RemoteDatasource` base class (`lib/core/resource/remote_data_source.dart`). Auth token injected automatically. Error responses parsed by `ApiErrorInterceptor` into `ApiException`.
- **Data Flow**: `DataState<T>` sealed hierarchy — `DataSuccess<T>`, `DataFailed<T>`, `PaginatedDataSuccess<T>`.
- **Use Cases**: Extend `UseCase<ReturnType, Params>`. Use `NoParams` when no input needed.
- **Config**: `AppConfig` loads `.env` via `flutter_dotenv` at startup.
- **Auth**: Token stored in `flutter_secure_storage`, accessed via `AuthStorage`.

### Features

- `work_order` — Core feature: CRUD, assignment, progress tracking, SPL, forms, location
- `peminjaman_material` — Material borrowing/returning linked to work orders
- `auth` — Login/register

### UI Conventions

- Base widget classes: `AppStatePage`, `AppStatelessWidget` in `lib/core/widget/`
- Shared widgets: `lib/core/widget/` (location picker, dynamic form builder, custom app bar, etc.)
- Role-based landing pages under `presentation/pages/users/` (staff, spv) and `pages/manajer/`
- Work order pages split by flow: `wo_masuk/` (incoming), `wo_keluar/` (outgoing), `approval/`

## API Conventions

- Endpoints prefixed with `/v1/` (e.g., `/v1/workorder`, `/v1/workorder/:id/assign-staff`)
- Paginated responses return `{ data: [...], totalPages: int, currentPage: int }`
- Error responses follow Laravel format: `{ message: "...", errors: { field: [...] } }`
- Remote data sources extend `RemoteDatasource` and use its `get()`, `post()`, `put()`, `delete()` methods which handle auth headers automatically

## Language

UI strings and error messages are in Bahasa Indonesia.
