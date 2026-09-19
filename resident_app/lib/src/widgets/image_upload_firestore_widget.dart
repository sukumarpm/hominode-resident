import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/image_firestore_service.dart';

/// Image Upload Widget - Firestore Flow Function Pattern
/// Uploads image directly to Firestore and handles real-time updates
class ImageUploadFirestoreWidget extends StatefulWidget {
  final String collectionPath;
  final String documentId;
  final String fieldName;
  final String? folder;
  final Function(ImageResult result) onUploadComplete;
  final Function(ImageResult result)? onError;

  const ImageUploadFirestoreWidget({
    super.key,
    required this.collectionPath,
    required this.documentId,
    required this.fieldName,
    required this.onUploadComplete,
    this.folder,
    this.onError,
  });

  @override
  State<ImageUploadFirestoreWidget> createState() =>
      _ImageUploadFirestoreWidgetState();
}

class _ImageUploadFirestoreWidgetState
    extends State<ImageUploadFirestoreWidget> {
  final ImagePicker _imagePicker = ImagePicker();
  final ImageFirestoreService _imageService = ImageFirestoreService.instance;
  bool _isUploading = false;
  double _uploadProgress = 0;

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        _isUploading = true;
        _uploadProgress = 0;
      });

      // Upload to Firestore
      final result = await _imageService.uploadImageToFirestore(
        imagePath: pickedFile.path,
        collectionPath: widget.collectionPath,
        documentId: widget.documentId,
        fieldName: widget.fieldName,
        folder: widget.folder,
      );

      setState(() {
        _isUploading = false;
        _uploadProgress = 1;
      });

      if (result.success) {
        widget.onUploadComplete(result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message ?? 'Image uploaded successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(result.message ?? 'Upload failed');
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      final errorResult = ImageResult.failure(message: e.toString());
      widget.onError?.call(errorResult);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_isUploading)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Uploading image... ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => _pickAndUploadImage(ImageSource.gallery),
                icon: const Icon(Icons.image),
                label: const Text('Gallery'),
              ),
              ElevatedButton.icon(
                onPressed: () => _pickAndUploadImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
              ),
            ],
          ),
      ],
    );
  }
}
