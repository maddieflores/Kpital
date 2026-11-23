import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/debt.dart';

class WhatsAppHelper {
  /// CU-3.3: Limpia y normaliza el número telefónico para WhatsApp
  static String normalizePhoneNumber(String rawNumber) {
    String cleaned = rawNumber.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    // Si es un número boliviano de 8 dígitos (ej. 76543210 o 61234567), anteponemos el código de país 591
    if (cleaned.length == 8 && (cleaned.startsWith('7') || cleaned.startsWith('6'))) {
      cleaned = '591$cleaned';
    }
    return cleaned;
  }

  /// CU-3.3: Genera mensaje pre-redactado cordial y respetuoso para cobro
  static String generateFriendlyReminderMessage(DebtModel debt) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final dueDateStr = debt.dueDate != null ? dateFormat.format(debt.dueDate!) : 'próximamente';

    return 'Hola *${debt.personName}* 👋, te saludo cordialmente.\n\n'
        'Te escribo para recordarte con mucho aprecio que tienes un saldo pendiente de *Bs ${debt.remainingAmount.toStringAsFixed(2)}* '
        '${debt.concept != null && debt.concept!.isNotEmpty ? "correspondiente a (${debt.concept}) " : ""}'
        'pactado para el *$dueDateStr*.\n\n'
        '¿Me confirmas si te queda cómodo realizar el abono por QR de Banco Unión o en efectivo? Quedo muy atento/a, ¡muchas gracias!';
  }

  /// Abre la conversación de WhatsApp con el mensaje pre-cargado
  static Future<bool> sendReminder(DebtModel debt) async {
    if (debt.phoneNumber == null || debt.phoneNumber!.trim().isEmpty) {
      return false;
    }

    final phone = normalizePhoneNumber(debt.phoneNumber!);
    final message = generateFriendlyReminderMessage(debt);
    final encodedMessage = Uri.encodeComponent(message);

    final url = Uri.parse('https://wa.me/$phone?text=$encodedMessage');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      return true;
    } else {
      // Fallback a URL web
      final webUrl = Uri.parse('https://api.whatsapp.com/send?phone=$phone&text=$encodedMessage');
      if (await canLaunchUrl(webUrl)) {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        return true;
      }
    }
    return false;
  }
}
