import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../providers/transactions_provider.dart';

class RecordIncomeSheet extends StatefulWidget {
  final String? preselectedAccountId;

  const RecordIncomeSheet({
    super.key,
    this.preselectedAccountId,
  });

  static Future<void> show(BuildContext context, {String? preselectedAccountId}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RecordIncomeSheet(preselectedAccountId: preselectedAccountId),
    );
  }

  @override
  State<RecordIncomeSheet> createState() => _RecordIncomeSheetState();
}

class _RecordIncomeSheetState extends State<RecordIncomeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _contactController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedAccountId;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  String? _receiptImagePath;
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  final List<String> _contactSuggestions = [
    'Mariana Vargas',
    'Carlos Mendoza',
    'Juan Carlos Paz',
    'Distribuidora Textil',
    'Cliente QR Mostrador',
  ];

  @override
  void initState() {
    super.initState();
    final accountsProv = Provider.of<AccountsProvider>(context, listen: false);
    final accounts = accountsProv.operationalAccounts;
    if (accounts.isNotEmpty) {
      _selectedAccountId = widget.preselectedAccountId ?? accounts.first.id;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _contactController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (file != null) {
        setState(() {
          _receiptImagePath = file.path;
        });
      }
    } catch (e) {
      debugPrint('Error al seleccionar imagen: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo acceder a la cámara o galería.')),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _saveIncome() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una cuenta receptora.')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
    if (amount <= 0) return;

    setState(() => _isSaving = true);

    final accountsProv = Provider.of<AccountsProvider>(context, listen: false);
    final txProv = Provider.of<TransactionsProvider>(context, listen: false);

    final account = accountsProv.accounts.firstWhere((a) => a.id == _selectedAccountId);

    final fullDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    await txProv.recordIncome(
      accountsProvider: accountsProv,
      accountId: account.id,
      accountName: account.name,
      amount: amount,
      contactName: _contactController.text,
      description: _descriptionController.text.isNotEmpty
          ? _descriptionController.text
          : 'Transferencia recibida',
      receiptImagePath: _receiptImagePath,
      transactionDate: fullDateTime,
      category: 'Transferencia QR / Ingreso',
    );

    setState(() => _isSaving = false);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF10B981),
          content: Text(
            '¡Transferencia de ${AccountsProvider.formatAmount(amount)} ingresada a ${account.name}!',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final accountsProv = Provider.of<AccountsProvider>(context);
    final operationalAccounts = accountsProv.operationalAccounts;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomInset + 20,
      ),
      decoration: BoxDecoration(
        color: tokens.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barra superior de agarre
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: tokens.textSecondary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Título
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_downward_rounded, color: Color(0xFF10B981), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Registrar Transferencia',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: tokens.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: tokens.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Monto recibido (Grande y destacado)
              Text(
                'Monto transferido (Bs)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tokens.textSecondary),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: tokens.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: '0.00',
                  prefixText: 'Bs  ',
                  prefixStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                  filled: true,
                  fillColor: tokens.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Ingresa el monto recibido';
                  final parsed = double.tryParse(val.replaceAll(',', '.'));
                  if (parsed == null || parsed <= 0) return 'Monto no válido';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Nombre de quién transfirió (CU-1.1)
              Text(
                '¿Quién realizó la transferencia?',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tokens.textSecondary),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _contactController,
                decoration: InputDecoration(
                  hintText: 'Ej: Mariana Vargas (o Cliente QR)',
                  prefixIcon: Icon(Icons.person_outline_rounded, color: Theme.of(context).primaryColor),
                  filled: true,
                  fillColor: tokens.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Indica el nombre de la persona' : null,
              ),
              const SizedBox(height: 8),

              // Sugerencias de contactos
              SizedBox(
                height: 30,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _contactSuggestions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, idx) => ActionChip(
                    label: Text(_contactSuggestions[idx], style: const TextStyle(fontSize: 11)),
                    padding: EdgeInsets.zero,
                    onPressed: () => setState(() => _contactController.text = _contactSuggestions[idx]),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // A qué cuenta ingresó el dinero (CU-1.1)
              Text(
                'Cuenta de ingreso',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tokens.textSecondary),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: tokens.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedAccountId,
                    isExpanded: true,
                    dropdownColor: tokens.cardBg,
                    items: operationalAccounts.map((acc) {
                      return DropdownMenuItem<String>(
                        value: acc.id,
                        child: Row(
                          children: [
                            Icon(acc.icon, size: 18, color: acc.color),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${acc.name} (${AccountsProvider.formatAmount(acc.balance)})',
                                style: TextStyle(fontSize: 13, color: tokens.textPrimary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedAccountId = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Fecha y Hora de la transferencia
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fecha',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tokens.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _selectDate,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: tokens.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today_outlined, size: 16, color: tokens.textSecondary),
                                const SizedBox(width: 8),
                                Text(
                                  dateFormat.format(_selectedDate),
                                  style: TextStyle(fontSize: 13, color: tokens.textPrimary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hora',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tokens.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _selectTime,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: tokens.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.access_time_rounded, size: 16, color: tokens.textSecondary),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedTime.format(context),
                                  style: TextStyle(fontSize: 13, color: tokens.textPrimary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Detalle o Concepto
              Text(
                'Concepto / Detalle (Opcional)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tokens.textSecondary),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  hintText: 'Ej: Anticipo fardo o compra docenas',
                  filled: true,
                  fillColor: tokens.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 18),

              // CU-1.2: Adjuntar comprobante / foto QR
              Text(
                'Comprobante o Captura QR',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tokens.textSecondary),
              ),
              const SizedBox(height: 8),

              if (_receiptImagePath == null)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.photo_library_outlined, size: 18),
                        label: const Text('Galería / Captura', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.camera_alt_outlined, size: 18),
                        label: const Text('Tomar Foto', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                )
              else
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: tokens.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 50,
                          height: 50,
                          child: kIsWeb
                              ? Image.network(_receiptImagePath!, fit: BoxFit.cover)
                              : Image.file(File(_receiptImagePath!), fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.check_circle, color: Color(0xFF10B981), size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'Comprobante adjuntado',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Text(
                              'Listo para guardarse',
                              style: TextStyle(fontSize: 11, color: tokens.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                        onPressed: () => setState(() => _receiptImagePath = null),
                        tooltip: 'Eliminar comprobante',
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Botón Guardar Transferencia
              ElevatedButton(
                onPressed: _isSaving ? null : _saveIncome,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Registrar Transferencia en Cuenta',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
