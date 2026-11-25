import '../../../core/services/finance_api_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../models/account.dart';
import '../providers/accounts_provider.dart';

class CreateEditAccountSheet extends StatefulWidget {
  final Account? accountToEdit;
  final bool initialIsVault;

  const CreateEditAccountSheet({
    super.key,
    this.accountToEdit,
    this.initialIsVault = false,
  });

  static Future<void> show(
    BuildContext context, {
    Account? accountToEdit,
    bool initialIsVault = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateEditAccountSheet(
        accountToEdit: accountToEdit,
        initialIsVault: initialIsVault,
      ),
    );
  }

  @override
  State<CreateEditAccountSheet> createState() => _CreateEditAccountSheetState();
}

class _CreateEditAccountSheetState extends State<CreateEditAccountSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _balanceController;
  late TextEditingController _targetController;

  late bool _isVault;
  late AccountType _selectedType;
  late String _selectedColorHex;

  final List<String> _colorOptions = [
    '#3366D6', // Azul Primario
    '#10B981', // Esmeralda / Efectivo
    '#8B5CF6', // Violeta / Bóvedas
    '#F59E0B', // Ámbar / Alertas
    '#06B6D4', // Cian
    '#EC4899', // Rosa
    '#F97316', // Naranja
    '#475569', // Gris pizarra
  ];

  final List<String> _accountPresets = [
    'Banco Unión (QR)',
    'Efectivo en mano',
    'BCP Soli',
    'Banco FIE',
    'Banco Sol',
    'BNB',
    'Tigo Money',
  ];

  final List<String> _vaultPresets = [
    'Fardo de Invierno',
    'Lote Mayorista Ropa',
    'Fondo de Emergencia',
    'Alquiler Tienda',
    'Ahorro Aguinaldo',
  ];

  @override
  void initState() {
    super.initState();
    final acc = widget.accountToEdit;
    _isVault = acc?.isSavingsVault ?? widget.initialIsVault;
    _nameController = TextEditingController(text: acc?.name ?? '');
    _balanceController = TextEditingController(
      text: acc != null ? acc.balance.toStringAsFixed(2) : '',
    );
    _targetController = TextEditingController(
      text: acc?.targetAmount != null ? acc!.targetAmount!.toStringAsFixed(2) : '',
    );
    _selectedType = acc?.type ?? (_isVault ? AccountType.savingsVault : AccountType.bank);
    _selectedColorHex = acc?.colorHex ?? (_isVault ? '#8B5CF6' : '#3366D6');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  final _draftId = FinanceApiService.newId('acc');
  bool _isSaving = false;

  Future<void> _save() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final balance = double.tryParse(_balanceController.text.replaceAll(',', '.')) ?? 0.0;
    final target = _isVault
        ? double.tryParse(_targetController.text.replaceAll(',', '.'))
        : null;

    final provider = Provider.of<AccountsProvider>(context, listen: false);

    setState(() => _isSaving = true);
    try {
      if (widget.accountToEdit != null) {
        final updated = widget.accountToEdit!.copyWith(
          name: name,
          type: _isVault ? AccountType.savingsVault : _selectedType,
          balance: balance,
          isSavingsVault: _isVault,
          targetAmount: target,
          colorHex: _selectedColorHex,
        );
        await provider.updateAccount(updated, previousBalance: widget.accountToEdit!.balance);
      } else {
        await provider.addAccount(
          accountId: _draftId,
          name: name,
          type: _isVault ? AccountType.savingsVault : _selectedType,
          initialBalance: balance,
          isSavingsVault: _isVault,
          targetAmount: target,
          colorHex: _selectedColorHex,
        );
      }
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

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isEditing = widget.accountToEdit != null;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Indicador superior
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

              // Encabezado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing
                        ? (_isVault ? 'Editar Bóveda' : 'Editar Cuenta')
                        : (_isVault ? 'Nueva Bóveda de Ahorro' : 'Nueva Cuenta'),
                    style: TextStyle(
                      fontSize: 18,
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

              // Toggle Selector: Cuenta de Gasto vs Bóveda Protegida (CU-4.2 / CU-4.3)
              if (!isEditing)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: tokens.isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.black.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isVault = false;
                              _selectedType = AccountType.bank;
                              _selectedColorHex = '#3366D6';
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !_isVault ? tokens.cardBg : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: !_isVault
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
                                  Icons.account_balance_wallet_outlined,
                                  size: 16,
                                  color: !_isVault ? Theme.of(context).primaryColor : tokens.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Cuenta Regular',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: !_isVault ? FontWeight.bold : FontWeight.normal,
                                    color: !_isVault ? tokens.textPrimary : tokens.textSecondary,
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
                              _isVault = true;
                              _selectedType = AccountType.savingsVault;
                              _selectedColorHex = '#8B5CF6';
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _isVault ? tokens.cardBg : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: _isVault
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
                                  Icons.lock_rounded,
                                  size: 16,
                                  color: _isVault ? const Color(0xFF8B5CF6) : tokens.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Bóveda Protegida',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: _isVault ? FontWeight.bold : FontWeight.normal,
                                    color: _isVault ? tokens.textPrimary : tokens.textSecondary,
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

              // Chip informativo sobre la Bóveda (CU-4.3)
              if (_isVault)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_rounded, color: Color(0xFF8B5CF6), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'El saldo de esta bóveda estará bloqueado y no sumará a tu disponible para gastar diario.',
                          style: TextStyle(fontSize: 12, color: tokens.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),

              // Selector de tipo si es cuenta regular
              if (!_isVault) ...[
                Text(
                  'Tipo de cuenta',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tokens.textSecondary),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Banco'),
                      selected: _selectedType == AccountType.bank,
                      onSelected: (val) => setState(() => _selectedType = AccountType.bank),
                    ),
                    ChoiceChip(
                      label: const Text('Efectivo'),
                      selected: _selectedType == AccountType.cash,
                      onSelected: (val) => setState(() => _selectedType = AccountType.cash),
                    ),
                    ChoiceChip(
                      label: const Text('Billetera / QR'),
                      selected: _selectedType == AccountType.digitalWallet,
                      onSelected: (val) => setState(() => _selectedType = AccountType.digitalWallet),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],

              // Nombre de la cuenta
              Text(
                _isVault ? 'Nombre de la Meta / Bóveda' : 'Nombre de la cuenta',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tokens.textSecondary),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: _isVault ? 'Ej: Meta: 8.000 Bs Fardo Invierno' : 'Ej: Banco Unión QR',
                  filled: true,
                  fillColor: tokens.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  prefixIcon: Icon(
                    _isVault ? Icons.flag_rounded : _selectedType.defaultIcon,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Ingresa un nombre' : null,
              ),
              const SizedBox(height: 8),

              // Chips de sugerencias rápidas locales
              SizedBox(
                height: 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: (_isVault ? _vaultPresets : _accountPresets).length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final suggestion = (_isVault ? _vaultPresets : _accountPresets)[idx];
                    return ActionChip(
                      label: Text(suggestion, style: const TextStyle(fontSize: 11)),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        setState(() {
                          _nameController.text = suggestion;
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Saldo Actual
              Text(
                _isVault ? 'Monto ahorrado actualmente (Bs)' : 'Saldo inicial (Bs)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tokens.textSecondary),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _balanceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: '0.00',
                  prefixText: 'Bs  ',
                  filled: true,
                  fillColor: tokens.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Ingresa un monto inicial';
                  final parsed = double.tryParse(val.replaceAll(',', '.'));
                  if (parsed == null || parsed < 0) return 'Monto no válido';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Meta objetivo si es bóveda (CU-4.2)
              if (_isVault) ...[
                Text(
                  'Meta de ahorro objetivo (Bs)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tokens.textSecondary),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _targetController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: 'Ej: 8000.00',
                    prefixText: 'Bs  ',
                    filled: true,
                    fillColor: tokens.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Ingresa el monto de la meta';
                    final parsed = double.tryParse(val.replaceAll(',', '.'));
                    if (parsed == null || parsed <= 0) return 'Monto meta no válido';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
              ],

              // Selector de color distintivo
              Text(
                'Color distintivo',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tokens.textSecondary),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _colorOptions.map((hex) {
                  final color = Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
                  final isSelected = _selectedColorHex == hex;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColorHex = hex),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: tokens.textPrimary, width: 2.5)
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 18, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Botón Guardar
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(int.parse('FF${_selectedColorHex.replaceAll('#', '')}', radix: 16)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  isEditing ? 'Guardar Cambios' : (_isVault ? 'Crear Bóveda de Ahorro' : 'Crear Cuenta'),
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
