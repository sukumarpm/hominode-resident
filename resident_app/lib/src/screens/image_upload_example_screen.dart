import 'package:flutter/material.dart';
import '../services/image_upload_service.dart';
import '../widgets/image_upload_widget.dart';

/// Example screen showing how to integrate image upload with Cloudinary and Firestore
/// 
/// Usage in your complaint/profile/marketplace screens:
/// 1. Create a document in Firestore first
/// 2. Use ImageUploadWidget to upload images
/// 3. The URL is automatically saved to Firestore
class ImageUploadExampleScreen extends StatefulWidget {
  final String documentId;
  final String collectionPath;

  const ImageUploadExampleScreen({
    super.key,
    required this.documentId,
    required this.collectionPath,
  });

  @override
  State<ImageUploadExampleScreen> createState() =>
      _ImageUploadExampleScreenState();
}

class _ImageUploadExampleScreenState extends State<ImageUploadExampleScreen> {
  String? _uploadedImageUrl;
  final ImageUploadService _uploadService = ImageUploadService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Upload Example'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display uploaded image
            if (_uploadedImageUrl != null)
              Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(_uploadedImageUrl!),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[300],
                ),
                child: const Center(
                  child: Text('No image uploaded yet'),
                ),
              ),
            const SizedBox(height: 24),

            // Upload widget
            Text(
              'Upload Image',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ImageUploadWidget(
              collectionPath: widget.collectionPath,
              documentId: widget.documentId,
              fieldName: 'imageUrl',
              folder: 'complaints', // Organize in Cloudinary
              includeMetadata: true,
              additionalData: {
                'imageUploadedAt': DateTime.now().toIso8601String(),
              },
              onUploadSuccess: (url) {
                setState(() {
                  _uploadedImageUrl = url;
                });
              },
              onUploadError: (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $error'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Info section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How it works:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '1. Click Gallery or Camera button\n'
                    '2. Select or take an image\n'
                    '3. Image uploads to Cloudinary\n'
                    '4. URL is saved to Firestore\n'
                    '5. Image displays above',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Example: How to use in a complaint submission screen
class ComplaintWithImageExample extends StatefulWidget {
  const ComplaintWithImageExample({super.key});

  @override
  State<ComplaintWithImageExample> createState() =>
      _ComplaintWithImageExampleState();
}

class _ComplaintWithImageExampleState extends State<ComplaintWithImageExample> {
  final ImageUploadService _uploadService = ImageUploadService();
  String? _complaintId;
  String? _uploadedImageUrl;
  bool _isSubmitting = false;

  Future<void> _submitComplaintWithImage() async {
    if (_complaintId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create complaint first')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Image is already uploaded via ImageUploadWidget
      // Just submit the complaint
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complaint submitted with image'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Complaint with Image'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Complaint form fields
            TextField(
              decoration: InputDecoration(
                labelText: 'Complaint Title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 24),

            // Image upload section
            Text(
              'Attach Image',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (_uploadedImageUrl != null)
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(_uploadedImageUrl!),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                child: const Center(
                  child: Text('No image selected'),
                ),
              ),
            const SizedBox(height: 16),
            ImageUploadWidget(
              collectionPath: 'complaints',
              documentId: _complaintId ?? 'temp',
              fieldName: 'imageUrl',
              folder: 'complaints',
              onUploadSuccess: (url) {
                setState(() {
                  _uploadedImageUrl = url;
                });
              },
            ),
            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitComplaintWithImage,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit Complaint'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
