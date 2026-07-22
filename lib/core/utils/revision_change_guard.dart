import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class RevisionBaseline {
  final String description;
  final Set<String> imageUrls;
  final Map<String, dynamic> formData;

  RevisionBaseline({
    required String description,
    required Iterable<dynamic> images,
    required Map<String, dynamic> formData,
  }) : description = description.trim(),
       imageUrls = images.whereType<String>().toSet(),
       formData = Map.of(formData);

  /// `true` bila TIDAK ada perubahan pada deskripsi, foto, maupun field yang
  /// tercantum di [editableKeys] — artinya resubmit revisi harus ditolak.
  ///
  /// [editableKeys] = key field yang benar-benar tampil/editable di form.
  /// `_formData` halaman bisa berisi key bawaan lain (mis. `nama_aset` dari
  /// fase Mulai) yang tidak editable di form Selesai — key tersebut sengaja
  /// tidak dibandingkan agar tidak "lolos palsu".
  bool isUnchanged({
    required String description,
    required List<dynamic> images,
    required Map<String, dynamic> formData,
    required Iterable<String> editableKeys,
  }) {
    if (description.trim() != this.description) return false;

    // Foto baru (file lokal) = perubahan.
    if (images.any((image) => image is XFile)) return false;

    // Foto lama dihapus/berubah = perubahan.
    final currentUrls = images.whereType<String>().toSet();
    if (!setEquals(currentUrls, imageUrls)) return false;

    for (final key in editableKeys) {
      // 'tahapan' dikecualikan: di mode Selesai dropdown terkunci di 4 dan
      // baseline server bisa null untuk data lama → rawan false-positive.
      if (key == 'tahapan') continue;
      if (_normalize(formData[key]) != _normalize(this.formData[key])) {
        return false;
      }
    }
    return true;
  }

  static String _normalize(dynamic value) {
    if (value == null) return '';
    if (value is DateTime) {
      return _formatDate(value.isUtc ? value.toLocal() : value);
    }
    final text = value.toString().trim();
    // Hanya string berpola tanggal ISO (yyyy-MM-dd...) yang diparse —
    // DateTime.tryParse juga menerima angka polos (mis. "20250101" sebagai
    // yyyyMMdd) sehingga nilai seperti nomor meter bisa salah ternormalisasi.
    if (_isoDatePrefix.hasMatch(text)) {
      final parsed = DateTime.tryParse(text);
      if (parsed != null) {
        return _formatDate(parsed.isUtc ? parsed.toLocal() : parsed);
      }
    }
    return text;
  }

  static final RegExp _isoDatePrefix = RegExp(r'^\d{4}-\d{2}-\d{2}');

  static String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
