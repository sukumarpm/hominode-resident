import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/image_upload_service.dart';

class ImageUploadWidget extends StatefulWidget {
  final String collectionPath;
  final String documentId;
  final String fieldName;
  final String? folder;
  final Function(String url) onUploadSuccess;
  final Function(String error)? onUploadError;
  final bool includeMetadata;
  final Map<String, dynamic>? additionalData;

  const ImageUploadWidget({
    super.key,
    required this.collectionPath,
    required this.documentId,
    required this.fieldName,
    required this.onUploadSuccess,
    this.folder,
    this.onUploadError,
    this.includeMetadata = false,
    this.additionalData,
  });

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  final ImagePicker _imagePicker = ImagePicker();
  final ImageUploadService _uploadService = ImageUploadService();
  bool _isUploading = false;
  double _uploadProgress = 0;

  Future<void> _pickAndUploadImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        _isUploading = true;
        _uploadProgress = 0;
      });

      final result = widget.includeMetadata
          ? await _uploadService.uploadImageWithMetadataToFirestore(
              imagePath: pickedFile.path,
              collectionPath: widget.collectionPath,
              documentId: widget.documentId,
              fieldName: widget.fieldName,
              folder: widget.folder,
              additionalData: widget.additionalData,
            )
          : await _uploadService.uploadImageToCloudinaryAndFirestore(
              imagePath: pickedFile.path,
              collectionPath: widget.collectionPath,
              documentId: widget.documentId,
              fieldName: widget.fieldName,
              folder: widget.folder,
              additionalData: widget.additionalData,
            );

      setState(() {
        _isUploading = false;
        _uploadProgress = 1;
      });

      if (result['success']) {
        widget.onUploadSuccess(result['url']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Image uploaded successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(result['message'] ?? 'Upload failed');
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      widget.onUploadError?.call(e.toString());
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

  Future<void> _pickAndUploadFromCamera() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        _isUploading = true;
        _uploadProgress = 0;
      });

      final result = widget.includeMetadata
          ? await _uploadService.uploadImageWithMetadataToFirestore(
              imagePath: pickedFile.path,
              collectionPath: widget.collectionPath,
              documentId: widget.documentId,
              fieldName: widget.fieldName,
              folder: widget.folder,
              additionalData: widget.additionalData,
            )
          : await _uploadService.uploadImageToCloudinaryAndFirestore(
              imagePath: pickedFile.path,
              collectionPath: widget.collectionPath,
              documentId: widget.documentId,
              fieldName: widget.fieldName,
              folder: widget.folder,
              additionalData: widget.additionalData,
            );

      setState(() {
        _isUploading = false;
        _uploadProgress = 1;
      });

      if (result['success']) {
        widget.onUploadSuccess(result['url']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Image uploaded successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(result['message'] ?? 'Upload failed');
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      widget.onUploadError?.call(e.toString());
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
                onPressed: _pickAndUploadImage,
                icon: const Icon(Icons.image),
                label: const Text('Gallery'),
              ),
              ElevatedButton.icon(
                onPressed: _pickAndUploadFromCamera,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
              ),
            ],
          ),
      ],
    );
  }
}
