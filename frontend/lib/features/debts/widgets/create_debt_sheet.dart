import '../../../core/services/finance_api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../models/debt.dart';
import '../providers/debts_provider.dart';

class CreateDebtSheet extends StatefulWidget {
  final DebtType initialType;

  const CreateDebtSheet({
    super.key,
    this.initialType = DebtType.receivable,
  });

  static Future<void> show(BuildContext context, {DebtType initialType = DebtType.receivable}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateDebtSheet(initialType: initialType),
    );
  }

  @override
  State<CreateDebtSheet> createState() => _CreateDebtSheetState();
}

class _CreateDebtSheetState extends State<CreateDebtSheet> {
  final _formKey = GlobalKey<FormState>();
  final _personController = TextEditingController();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _conceptController = TextEditingController();

  late DebtType _selectedType;
  DateTime? _dueDate;
  final _draftId = FinanceApiService.newId('debt');
  final _createdAt = DateTime.now();
  bool _isSaving = false;

  final List<String> _receivablePresets = [
    'Ropa fiada feria',
    '1 docena parkas',
    'Préstamo en efectivo',
    'Saldo por flete',
    'Mercadería a consignación',
  ];

  final List<String> _payablePresets = [
    'Proveedor de telas',
    'Lote fardo de invierno',
    'Cuota de banco',
    'Alquiler atrasado',
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _dueDate = DateTime.now().add(const Duration(days: 7));
  }

  @override
  void dispose() {
    _personController.dispose();
    _phoneController.dispose();
    _amountController.dispose();
    _conceptController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _saveDebt() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
    if (amount <= 0) return;

    setState(() => _isSaving = true);

    final debtsProv = Provider.of<DebtsProvider>(context, listen: false);

    try {
      await debtsProv.addDebt(
        debtId: _draftId,
        createdAt: _createdAt,
        type: _selectedType,
        personName: _personController.text,
        phoneNumber: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        totalAmount: amount,
        dueDate: _dueDate,
        concept: _conceptController.text.isNotEmpty ? _conceptController.text : null,
      );
    } on FinanceSyncException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
      return;
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _selectedType == DebtType.receivable
              ? const Color(0xFF10B981)
              : const Color(0xFFEF4444),
          content: Text(
            _selectedType == DebtType.receivable
                ? '¡Cuenta por cobrar registrada para ${_personController.text}!'
                : '¡Cuenta por pagar registrada para ${_personController.text}!',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isReceivable = _selectedType == DebtType.receivable;
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
                  Text(
                    isReceivable ? 'Nueva Cuenta por Cobrar' : 'Nueva Cuenta por Pagar',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: tokens.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: tokens.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Selector Tipo: Me deben vs Debo
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: tokens.isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedType = DebtType.receivable),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isReceivable ? tokens.cardBg : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: isReceivable
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_downward_rounded,
                                size: 16,
                                color: isReceivable ? const Color(0xFF10B981) : tokens.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Me deben (Cobrar)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isReceivable ? FontWeight.bold : FontWeight.normal,
                                  color: isReceivable ? tokens.textPrimary : tokens.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedType = DebtType.payable),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !isReceivable ? tokens.cardBg : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: !isReceivable
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_upward_rounded,
                                size: 16,
                                color: !isReceivable ? const Color(0xFFEF4444) : tokens.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Debo a otros (Pagar)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: !isReceivable ? FontWeight.bold : FontWeight.normal,
                                  color: !isReceivable ? tokens.textPrimary : tokens.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Monto Total Pactado
              Text(
                'Monto acordado (Bs)',
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
                  prefixStyle: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isReceivable ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  ),
                  filled: true,
                  fillColor: tokens.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Ingresa el monto pactado';
                  final parsed = double.tryParse(val.replaceAll(',', '.'));
                  if (parsed == null || parsed <= 0) return 'Monto no válido';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Nombre de la persona o entidad
              Text(
                isReceivable ? '¿A quién le fiaste o prestaste?' : '¿A quién le debes? (Proveedor / Banco)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tokens.textSecondary),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _personController,
                decoration: InputDecoration(
                  hintText: isReceivable ? 'Ej: Carlos Mamani' : 'Ej: Distribuidora La Paz',
                  prefixIcon: Icon(Icons.person_outline_rounded, color: Theme.of(context).primaryColor),
                  filled: true,
                  fillColor: tokens.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Indica el nombre de la persona' : null,
              ),
              const SizedBox(height: 16),

              // Teléfono WhatsApp
              Text(
                'Teléfono / Celular (Para recordatorios por WhatsApp)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tokens.textSecondary),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'Ej: 78945612 o +591 78945612',
                  prefixIcon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF25D366)),
                  filled: true,
                  fillColor: tokens.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),

              // Concepto o motivo
              Text(
                'Concepto / Mercadería entregada',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tokens.textSecondary),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _conceptController,
                decoration: InputDecoration(
                  hintText: 'Ej: 1 docena medias y 2 chompas',
                  filled: true,
                  fillColor: tokens.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 8),

              // Chips de sugerencia rápida
              SizedBox(
                height: 30,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: (isReceivable ? _receivablePresets : _payablePresets).length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, idx) {
                    final suggestion = (isReceivable ? _receivablePresets : _payablePresets)[idx];
                    return ActionChip(
                      label: Text(suggestion, style: const TextStyle(fontSize: 11)),
                      padding: EdgeInsets.zero,
                      onPressed: () => setState(() => _conceptController.text = suggestion),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Fecha límite pactada (CU-3.1)
              Text(
                'Fecha límite acordada de pago',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tokens.textSecondary),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _selectDueDate,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: tokens.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 18, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 10),
                      Text(
                        _dueDate != null ? dateFormat.format(_dueDate!) : 'Seleccionar fecha',
                        style: TextStyle(fontSize: 13, color: tokens.textPrimary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Botón Guardar
              ElevatedButton(
                onPressed: _isSaving ? null : _saveDebt,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isReceivable ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        isReceivable ? 'Registrar Cuenta por Cobrar' : 'Registrar Cuenta por Pagar',
                        style: const TextStyle(
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
