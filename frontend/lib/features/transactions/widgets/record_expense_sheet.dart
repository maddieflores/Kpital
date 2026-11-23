import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../providers/transactions_provider.dart';

class RecordExpenseSheet extends StatefulWidget {
  final String? preselectedAccountId;

  const RecordExpenseSheet({
    super.key,
    this.preselectedAccountId,
  });

  static Future<void> show(BuildContext context, {String? preselectedAccountId}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RecordExpenseSheet(preselectedAccountId: preselectedAccountId),
    );
  }

  @override
  State<RecordExpenseSheet> createState() => _RecordExpenseSheetState();
}

class _RecordExpenseSheetState extends State<RecordExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedAccountId;
  bool _isEssential = true; // CU-2.2: true = Gasto Fijo, false = Gasto Hormiga
  String _selectedCategory = 'Alquiler';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isSaving = false;

  final List<String> _fixedCategories = [
    'Alquiler',
    'Luz, Agua e Internet',
    'Insumos / Mercadería',
    'Transporte / Flete',
    'Salud y Farmacia',
    'Educación',
  ];

  final List<String> _antCategories = [
    'Comida al paso / Salteñas',
    'Antojo / Dulces',
    'Refresco / Café',
    'Taxi / Gustito',
    'Gasto impulsivo',
  ];

  @override
  void initState() {
    super.initState();
    final accountsProv = Provider.of<AccountsProvider>(context, listen: false);
    final accounts = accountsProv.operationalAccounts;
    if (accounts.isNotEmpty) {
      _selectedAccountId = widget.preselectedAccountId ?? accounts.first.id;
    }
    _selectedCategory = _fixedCategories.first;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 10)),
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

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una cuenta de salida.')),
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

    await txProv.recordExpense(
      accountsProvider: accountsProv,
      accountId: account.id,
      accountName: account.name,
      amount: amount,
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      isEssential: _isEssential,
      transactionDate: fullDateTime,
    );

    setState(() => _isSaving = false);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFEF4444),
          content: Text(
            'Gasto de ${AccountsProvider.formatAmount(amount)} descontado de ${account.name}',
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

    final currentCategories = _isEssential ? _fixedCategories : _antCategories;

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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_upward_rounded, color: Color(0xFFEF4444), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Registrar Gasto Rápido (CU-2.1)',
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

              // Monto del Gasto
              Text(
                'Monto del gasto (Bs)',
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
                  prefixStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
                  filled: true,
                  fillColor: tokens.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Ingresa el monto del gasto';
                  final parsed = double.tryParse(val.replaceAll(',', '.'));
                  if (parsed == null || parsed <= 0) return 'Monto no válido';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // CU-2.2: Clasificación de Gasto Fijo vs Gasto Hormiga
              Text(
                'Clasificación del Gasto (CU-2.2)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tokens.textSecondary),
              ),
              const SizedBox(height: 8),
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
                        onTap: () {
                          setState(() {
                            _isEssential = true;
                            _selectedCategory = _fixedCategories.first;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _isEssential ? tokens.cardBg : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _isEssential
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
                                Icons.home_work_outlined,
                                size: 16,
                                color: _isEssential ? const Color(0xFF3366D6) : tokens.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Gasto Fijo / Necesario',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: _isEssential ? FontWeight.bold : FontWeight.normal,
                                  color: _isEssential ? tokens.textPrimary : tokens.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isEssential = false;
                            _selectedCategory = _antCategories.first;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !_isEssential ? tokens.cardBg : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: !_isEssential
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
                                Icons.fastfood_outlined,
                                size: 16,
                                color: !_isEssential ? const Color(0xFFF59E0B) : tokens.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Gasto Hormiga 🐜',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: !_isEssential ? FontWeight.bold : FontWeight.normal,
                                  color: !_isEssential ? tokens.textPrimary : tokens.textSecondary,
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
              const SizedBox(height: 14),

              // Selector de Categoría
              Text(
                'Categoría',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tokens.textSecondary),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: currentCategories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(cat, style: const TextStyle(fontSize: 11)),
                    selected: isSelected,
                    selectedColor: _isEssential
                        ? const Color(0xFF3366D6).withOpacity(0.18)
                        : const Color(0xFFF59E0B).withOpacity(0.2),
                    onSelected: (val) => setState(() => _selectedCategory = cat),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // ¿En qué se gastó exactamente? (CU-2.1)
              Text(
                '¿En qué se gastó exactamente?',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tokens.textSecondary),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  hintText: _isEssential
                      ? 'Ej: Alquiler del mes o pago de luz'
                      : 'Ej: 2 empanadas y jugo en el mercado',
                  prefixIcon: Icon(
                    _isEssential ? Icons.receipt_long_outlined : Icons.cookie_outlined,
                    color: _isEssential ? const Color(0xFF3366D6) : const Color(0xFFF59E0B),
                  ),
                  filled: true,
                  fillColor: tokens.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Indica el detalle del gasto' : null,
              ),
              const SizedBox(height: 16),

              // Cuenta de Salida (Efectivo/QR)
              Text(
                'Cuenta de salida / Método de pago',
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

              // Fecha y Hora
              Row(
                children: [
                  Expanded(
                    child: InkWell(
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
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
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
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Botón Guardar Gasto
              ElevatedButton(
                onPressed: _isSaving ? null : _saveExpense,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
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
                        'Registrar Gasto',
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
