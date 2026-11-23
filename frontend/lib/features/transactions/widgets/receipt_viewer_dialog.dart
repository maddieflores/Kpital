import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_design_tokens.dart';

class ReceiptViewerDialog extends StatelessWidget {
  final String imagePath;
  final String? title;
  final String? amountFormatted;

  const ReceiptViewerDialog({
    super.key,
    required this.imagePath,
    this.title,
    this.amountFormatted,
  });

  static void show(
    BuildContext context, {
    required String imagePath,
    String? title,
    String? amountFormatted,
  }) {
    showDialog(
      context: context,
      builder: (_) => ReceiptViewerDialog(
        imagePath: imagePath,
        title: title,
        amountFormatted: amountFormatted,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isNetwork = imagePath.startsWith('http://') || imagePath.startsWith('https://');

    return Dialog(
      backgroundColor: tokens.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title ?? 'Comprobante de Transferencia',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: tokens.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (amountFormatted != null)
                        Text(
                          amountFormatted!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: tokens.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: isNetwork
                    ? Image.network(
                        imagePath,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => _errorPlaceholder(tokens),
                      )
                    : kIsWeb
                        ? Image.network(
                            imagePath,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => _errorPlaceholder(tokens),
                          )
                        : Image.file(
                            File(imagePath),
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => _errorPlaceholder(tokens),
                          ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_rounded, size: 16, color: Theme.of(context).primaryColor),
                const SizedBox(width: 6),
                Text(
                  'Comprobante QR adjunto guardado',
                  style: TextStyle(fontSize: 12, color: tokens.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorPlaceholder(AppDesignTokens tokens) {
    return Container(
      height: 180,
      color: tokens.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported_outlined, color: tokens.textSecondary, size: 40),
            const SizedBox(height: 8),
            Text(
              'No se pudo cargar la vista previa del comprobante',
              style: TextStyle(fontSize: 12, color: tokens.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
