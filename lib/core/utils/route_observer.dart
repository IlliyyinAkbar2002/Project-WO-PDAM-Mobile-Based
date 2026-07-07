import 'package:flutter/material.dart';

/// Observer global untuk mendeteksi saat sebuah halaman kembali aktif (route di
/// atasnya di-pop) lewat `RouteAware.didPopNext`. Dipakai dashboard untuk
/// memuat ulang datanya, karena `WorkOrderBloc` global ([main.dart]) dibagi ke
/// semua halaman list sehingga state-nya bisa ditimpa saat navigasi.
final RouteObserver<PageRoute<dynamic>> appRouteObserver =
    RouteObserver<PageRoute<dynamic>>();
