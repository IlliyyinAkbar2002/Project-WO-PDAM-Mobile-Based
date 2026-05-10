import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project_mobile_pdam/config/app_config.dart';
import 'package:project_mobile_pdam/core/widget/app_state_page.dart';

class ImagePickerField extends StatefulWidget {
  final List<dynamic> initialImages; // Untuk multi-image
  final dynamic initialImage; // Untuk single-image
  final Function(dynamic) onChanged; // List<XFile> atau XFile?
  final bool enabled;
  final bool singleImage;

  const ImagePickerField({
    super.key,
    this.initialImages = const [],
    this.initialImage,
    required this.onChanged,
    this.enabled = true,
    this.singleImage = false,
  });

  @override
  State<ImagePickerField> createState() => _ImagePickerFieldState();
}

class _ImagePickerFieldState extends AppStatePage<ImagePickerField> {
  final ImagePicker _picker = ImagePicker();
  List<dynamic> _imageFiles = [];
  dynamic _singleImage;

  @override
  void initState() {
    super.initState();
    if (widget.singleImage) {
      _singleImage = widget.initialImage;
    } else {
      _imageFiles = List.from(widget.initialImages);
    }
  }

  @override
  void didUpdateWidget(covariant ImagePickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.singleImage) {
      if (widget.initialImage != oldWidget.initialImage) {
        _singleImage = widget.initialImage;
      }
    } else {
      if (widget.initialImages != oldWidget.initialImages &&
          widget.initialImages.length != _imageFiles.length) {
        _imageFiles = List.from(widget.initialImages);
      }
    }
  }

  void _pickImagesFromGallery() async {
    if (widget.singleImage) {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _singleImage = pickedFile;
        });
        widget.onChanged(pickedFile);
      }
    } else {
      final pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _imageFiles.addAll(pickedFiles);
        });
        widget.onChanged(_imageFiles);
      }
    }
  }

  void _pickImageFromCamera() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      if (widget.singleImage) {
        setState(() {
          _singleImage = pickedFile;
        });
        widget.onChanged(pickedFile);
      } else {
        setState(() {
          _imageFiles.add(pickedFile);
        });
        widget.onChanged(_imageFiles);
      }
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(
                widget.singleImage ? 'Pilih Gambar' : 'Pilih dari Galeri',
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImagesFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(
                widget.singleImage ? 'Ambil Foto' : 'Ambil dari Kamera',
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),
          ],
        ),
      ),
    );
  }

  String getFullImageUrl(String path) {
    if (path.startsWith('http')) return path; // Sudah URL lengkap
    return AppConfig.baseStorageUrl + path;
  }

  @override
  Widget buildPage(BuildContext context) {
    if (widget.singleImage) {
      Widget imageWidget;
      if (_singleImage is XFile) {
        imageWidget = Image.file(
          File((_singleImage as XFile).path),
          width: 100,
          height: 100,
          fit: BoxFit.cover,
        );
      } else if (_singleImage is String) {
        imageWidget = Image.network(
          getFullImageUrl(_singleImage as String), // Gunakan helper
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.broken_image, size: 50),
        );
      } else {
        imageWidget = Container(); // Kosong jika tidak ada gambar
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_singleImage != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imageWidget,
                ),
                if (widget.enabled)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _singleImage = null;
                        });
                        widget.onChanged(null);
                      },
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          if (widget.enabled)
            GestureDetector(
              onTap: _showImageSourcePicker,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                child: Icon(
                  _singleImage == null ? Icons.add_a_photo : Icons.edit,
                  size: 28,
                  color: Colors.grey,
                ),
              ),
            ),
        ],
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ..._imageFiles.map((item) {
          // item sekarang bisa XFile atau String (URL path)
          Widget displayItemWidget;
          String? itemIdentifier; // Untuk key atau keperluan remove

          if (item is XFile) {
            displayItemWidget = Image.file(
              File(item.path),
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            );
            itemIdentifier =
                item.path; // Path XFile bisa jadi identifier unik sementara
          } else if (item is String) {
            displayItemWidget = Image.network(
              getFullImageUrl(item), // Gunakan helper di sini
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 100,
                  height: 100,
                  color: Colors.grey[200],
                  child: const Icon(
                    Icons.broken_image,
                    size: 50,
                    color: Colors.grey,
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: 100,
                  height: 100,
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
            );
            itemIdentifier = item; // URL string bisa jadi identifier unik
          } else {
            // Seharusnya tidak terjadi jika _imageFiles hanya berisi XFile atau String
            displayItemWidget = const SizedBox(
              width: 100,
              height: 100,
              child: Icon(Icons.error, color: Colors.red),
            );
            itemIdentifier = UniqueKey().toString();
          }

          return Stack(
            key: ValueKey(
              itemIdentifier,
            ), // Memberikan key unik untuk setiap item
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: displayItemWidget,
              ),
              if (widget.enabled)
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _imageFiles.remove(item);
                      });
                      widget.onChanged(_imageFiles);
                    },
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          );
        }), // Jangan lupa toList() setelah map
        if (widget.enabled)
          GestureDetector(
            onTap: _showImageSourcePicker,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: const Icon(
                Icons.add_a_photo,
                size: 28,
                color: Colors.grey,
              ),
            ),
          ),
      ],
    );
  }
}
