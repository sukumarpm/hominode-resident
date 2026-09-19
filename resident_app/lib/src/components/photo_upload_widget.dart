import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Reusable photo upload widget with camera/gallery selection
/// Matches the design from Add Family Member modal
class PhotoUploadWidget extends StatefulWidget {
  final String? initialPhotoUrl;
  final Function(String? photoPath) onPhotoChanged;
  final String label;
  final bool isOptional;
  final bool allowMultiple;
  final List<String>? initialPhotos;

  const PhotoUploadWidget({
    super.key,
    this.initialPhotoUrl,
    required this.onPhotoChanged,
    this.label = 'Attach photo',
    this.isOptional = true,
    this.allowMultiple = false,
    this.initialPhotos,
  });

  @override
  State<PhotoUploadWidget> createState() => _PhotoUploadWidgetState();
}

class _PhotoUploadWidgetState extends State<PhotoUploadWidget> {
  String? _photoUrl;
  File? _photoFile;
  final ImagePicker _picker = ImagePicker();
  List<String> _photos = [];
  final List<File> _photoFiles = [];

  @override
  void initState() {
    super.initState();
    _photoUrl = widget.initialPhotoUrl;
    if (widget.allowMultiple && widget.initialPhotos != null) {
      _photos = List.from(widget.initialPhotos!);
    }
  }

  Future<void> _pickPhoto() async {
    try {
      // Show source selection dialog
      final ImageSource? source = await showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Select Photo Source',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Color(0xFF0E4778),
                    ),
                  ),
                  title: const Text(
                    'Camera',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Take a new photo'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.photo_library,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                  title: const Text(
                    'Gallery',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Choose from gallery'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      );

      if (source == null) return;

      if (widget.allowMultiple) {
        // Pick multiple images
        final List<XFile> images = await _picker.pickMultiImage(
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 85,
        );

        if (images.isNotEmpty) {
          setState(() {
            for (var image in images) {
              _photos.add(image.path);
              _photoFiles.add(File(image.path));
            }
          });
          widget.onPhotoChanged(_photos.join(','));
        }
      } else {
        // Pick single image
        final XFile? image = await _picker.pickImage(
          source: source,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 85,
        );

        if (image != null) {
          setState(() {
            _photoFile = File(image.path);
            _photoUrl = image.path;
          });
          widget.onPhotoChanged(image.path);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _removePhoto() {
    setState(() {
      _photoUrl = null;
      _photoFile = null;
    });
    widget.onPhotoChanged(null);
  }

  void _removePhotoAt(int index) {
    setState(() {
      _photos.removeAt(index);
      _photoFiles.removeAt(index);
    });
    widget.onPhotoChanged(_photos.isEmpty ? null : _photos.join(','));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.isOptional ? '${widget.label} (optional)' : widget.label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 12),
        if (widget.allowMultiple)
          _buildMultiplePhotosView()
        else
          _buildSinglePhotoView(),
      ],
    );
  }

  Widget _buildSinglePhotoView() {
    if (_photoUrl != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE6E9EC)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: const Color(0xFFF3F4F6),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: _photoFile != null
                    ? Image.file(
                        _photoFile!,
                        fit: BoxFit.cover,
                        width: 48,
                        height: 48,
                      )
                    : _photoUrl!.startsWith('http')
                    ? Image.network(
                        _photoUrl!,
                        fit: BoxFit.cover,
                        width: 48,
                        height: 48,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.image,
                            size: 24,
                            color: Color(0xFF9CA3AF),
                          );
                        },
                      )
                    : Image.file(
                        File(_photoUrl!),
                        fit: BoxFit.cover,
                        width: 48,
                        height: 48,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.image,
                            size: 24,
                            color: Color(0xFF9CA3AF),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Photo attached',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  GestureDetector(
                    onTap: _pickPhoto,
                    child: const Text(
                      'Change photo',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF0E4778),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _removePhoto,
              icon: const Icon(Icons.close, size: 20, color: Color(0xFF9CA3AF)),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: _pickPhoto,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE6E9EC), width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.file_upload_outlined,
              size: 24,
              color: Color(0xFF111827),
            ),
            SizedBox(width: 10),
            Text(
              'Upload photo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiplePhotosView() {
    return Column(
      children: [
        if (_photos.isNotEmpty) ...[
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _photos.asMap().entries.map((entry) {
              return _buildPhotoThumbnail(entry.key, entry.value);
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],
        InkWell(
          onTap: _pickPhoto,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE6E9EC), width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.file_upload_outlined,
                  size: 24,
                  color: Color(0xFF111827),
                ),
                SizedBox(width: 10),
                Text(
                  'Upload photos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoThumbnail(int index, String imagePath) {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFFF3F4F6),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(imagePath),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(
                    Icons.broken_image,
                    color: Color(0xFF9CA3AF),
                    size: 32,
                  ),
                );
              },
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removePhotoAt(index),
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }
}
