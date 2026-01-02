import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/ocr_service.dart';
import '../../data/models/bill_item.dart';
import 'bill_review_screen.dart';

class CaptureBillScreen extends ConsumerStatefulWidget {
  const CaptureBillScreen({super.key});

  @override
  ConsumerState<CaptureBillScreen> createState() => _CaptureBillScreenState();
}

class _CaptureBillScreenState extends ConsumerState<CaptureBillScreen> {
  final _ocrService = OcrService();
  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);
      
      if (pickedFile != null) {
        setState(() => _isLoading = true);
        
        final items = await _ocrService.extractItemsFromImage(pickedFile.path);
        
        if (mounted) {
          setState(() => _isLoading = false);
          _navigateToReview(items);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scanning receipt: $e')),
        );
      }
    }
  }

  void _navigateToReview(List<BillItem> items) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BillReviewScreen(initialItems: items),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Capture Bill')),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Scan Receipt'),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Upload from Gallery'),
                  ),
                  const SizedBox(height: 32),
                  TextButton(
                    onPressed: () => _navigateToReview([]), // Empty items for manual
                    child: const Text('Enter Manually'),
                  ),
                ],
              ),
      ),
    );
  }
}
