import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:uuid/uuid.dart';
import '../data/models/bill_item.dart';

class OcrService {
  Future<List<BillItem>> extractItemsFromImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer();

    try {
      final RecognizedText recognizedText = 
          await textRecognizer.processImage(inputImage);
      
      final items = _parseRecognizedText(recognizedText);
      return items;
    } finally {
      textRecognizer.close();
    }
  }

  List<BillItem> _parseRecognizedText(RecognizedText recognizedText) {
    final items = <BillItem>[];
    
    // Regex patterns for "Item Name" + "Price"
    // Assumption: Price is at the end of the line, possibly with currency symbol.
    final pricePattern = RegExp(r'\$?([\d,]+\.?\d{0,2})');
    
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final text = line.text;
        
        // Find ALL price matches in the line. Usually the last one is the item price.
        final matches = pricePattern.allMatches(text);
        if (matches.isNotEmpty) {
           // Take the last match as price (assuming right-aligned price)
           final priceMatch = matches.last;
           final priceStr = priceMatch.group(1)?.replaceAll(',', '');
           final price = double.tryParse(priceStr ?? '0') ?? 0.0;
           
           // Name is everything before the price
           String name = text.substring(0, priceMatch.start).trim();
           // Remove trailing non-alphanumeric chars from name if any (like dots)
           name = name.replaceAll(RegExp(r'[\.\-_]+$'), '').trim();
           
           if (name.isNotEmpty && price > 0) {
              items.add(BillItem(
                id: const Uuid().v4(),
                name: name,
                price: price,
              ));
           }
        }
      }
    }
    
    return items;
  }
}
