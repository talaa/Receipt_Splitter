import 'package:url_launcher/url_launcher.dart';
import '../data/models/person.dart';

class ShareService {
  static Future<void> sharePaymentRequest(Person person, double amount) async {
    final message = 'Hey ${person.name}, your share for the bill is \$${amount.toStringAsFixed(2)}. Please pay me via Instapay or Cash.';
    final encodedMessage = Uri.encodeComponent(message);
    
    // Attempt WhatsApp
    final whatsappUrl = Uri.parse('whatsapp://send?text=$encodedMessage');
    // Attempt SMS
    final smsUrl = Uri.parse('sms:?body=$encodedMessage'); // body param standard for sms

    if (person.phoneNumber != null) {
       // If phone number exists, we can target specific number
       // final specificUrl = Uri.parse('whatsapp://send?phone=${person.phoneNumber}&text=$encodedMessage');
       // For now generic share or specific if possible.
    }

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl);
      } else {
        await launchUrl(smsUrl);
      }
    } catch (e) {
      // Fallback or error handling
      print('Could not launch share url: $e');
    }
  }
}
