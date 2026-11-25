import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../auth/providers/auth_provider.dart';

class UserProfileDetailsScreen extends StatefulWidget {
  const UserProfileDetailsScreen({super.key});

  @override
  State<UserProfileDetailsScreen> createState() => _UserProfileDetailsScreenState();
}

class _UserProfileDetailsScreenState extends State<UserProfileDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  late TextEditingController _fullNameController;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String _selectedCurrency = 'BOB';
  bool _isSavingProfile = false;
  bool _isSavingPassword = false;

  bool _obscureCurrentPass = true;
  bool _obscureNewPass = true;
  bool _obscureConfirmPass = true;

  final ImagePicker _picker = ImagePicker();

  static const List<String> _presetAvatars = [
    '👑', '💎', '🚀', '💼', '🌸', '🦁', '🐱', '🦊',
    '⚡', '🎯', '🦄', '🐼', '🌟', '🍕', '🏆', '🔥',
  ];

  @override
  void initState() {
    super.initState();
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final user = authProv.currentUser;

    _fullNameController = TextEditingController(text: user.fullName);
    _usernameController = TextEditingController(text: user.username);
    _emailController = TextEditingController(text: user.email);
    _phoneController = TextEditingController(text: user.phoneNumber);
    _selectedCurrency = user.currency.isNotEmpty ? user.currency : 'BOB';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context); // Cierra el modal de selección
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

        if (mounted) {
          final authProv = Provider.of<AuthProvider>(context, listen: false);
          await authProv.updateProfile(avatarUrl: base64Image);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Foto de perfil actualizada correctamente'),
                backgroundColor: Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo cargar la imagen: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _selectPresetAvatar(String emoji) async {
    Navigator.pop(context);
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    await authProv.updateProfile(avatarUrl: 'emoji:$emoji');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Avatar $emoji seleccionado con éxito'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _removePhoto() async {
    Navigator.pop(context);
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    await authProv.updateProfile(clearAvatar: true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto eliminada. Se usarán tus iniciales.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showAvatarOptions(BuildContext context, UserModel user) {
    final tokens = context.tokens;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final primary = themeProvider.currentIdentity.primary;

    showModalBottomSheet(
      context: context,
      backgroundColor: tokens.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: tokens.textSecondary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Foto de perfil & Avatar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Elige cómo quieres que te identifiquen en Kpital',
                  style: TextStyle(
                    fontSize: 13,
                    color: tokens.textSecondary,
                  ),
                ),
                const SizedBox(height: 18),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.camera_alt_rounded, color: primary, size: 20),
                  ),
                  title: const Text('Tomar foto con la cámara', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () => _pickImage(ImageSource.camera),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.photo_library_rounded, color: Color(0xFF10B981), size: 20),
                  ),
                  title: const Text('Elegir de la galería', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mood_rounded, color: Color(0xFFF59E0B), size: 20),
                  ),
                  title: const Text('Elegir avatar o emoji prediseñado', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showPresetAvatarsSheet(context);
                  },
                ),
                if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                    ),
                    title: const Text('Eliminar foto (usar iniciales)', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.redAccent)),
                    onTap: _removePhoto,
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPresetAvatarsSheet(BuildContext context) {
    final tokens = context.tokens;

    showModalBottomSheet(
      context: context,
      backgroundColor: tokens.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: tokens.textSecondary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Elige un avatar divertido',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  alignment: WrapAlignment.center,
                  children: _presetAvatars.map((emoji) {
                    return InkWell(
                      onTap: () => _selectPresetAvatar(emoji),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: tokens.isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.black.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: tokens.isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveProfileData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSavingProfile = true);
    final authProv = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProv.updateProfile(
      fullName: _fullNameController.text.trim(),
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      currency: _selectedCurrency,
    );

    if (mounted) {
      setState(() => _isSavingProfile = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Datos actualizados correctamente'),
              ],
            ),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProv.errorMessage ?? 'No se pudieron guardar los datos'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _updatePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    final current = _currentPasswordController.text;
    final replacement = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    if (replacement != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Las nuevas contraseñas no coinciden'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSavingPassword = true);
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProv.updatePassword(current, replacement);

    if (mounted) {
      setState(() => _isSavingPassword = false);
      if (success) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.lock_reset, color: Colors.white),
                SizedBox(width: 8),
                Text('Contraseña cambiada exitosamente'),
              ],
            ),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProv.errorMessage ?? 'Contraseña actual incorrecta o sesión expirada'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProv = Provider.of<AuthProvider>(context);
    final user = authProv.currentUser;
    final primary = themeProvider.currentIdentity.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil & Datos'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // CABECERA CON AVATAR EDITABLE
          Center(
            child: Column(
              children: [
                UserAvatar(
                  user: user,
                  radius: 54,
                  showEditBadge: true,
                  onTap: () => _showAvatarOptions(context, user),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => _showAvatarOptions(context, user),
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  label: const Text(
                    'Cambiar foto de perfil',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: primary,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    backgroundColor: primary.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                if (user.isOwner)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, size: 14, color: Colors.amber),
                        SizedBox(width: 4),
                        Text(
                          'Cuenta Owner · Creadora',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // SECCIÓN 1: DATOS PERSONALES
          Text(
            'DATOS PERSONALES',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: tokens.cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: tokens.isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Nombre completo
                  TextFormField(
                    controller: _fullNameController,
                    decoration: InputDecoration(
                      labelText: 'Nombre Completo',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      filled: true,
                      fillColor: tokens.isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Ingresa tu nombre completo';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Nombre de usuario (@username)
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Nombre de usuario',
                      prefixIcon: const Icon(Icons.alternate_email),
                      helperText: 'Identificador único en la plataforma',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      filled: true,
                      fillColor: tokens.isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Ingresa un nombre de usuario';
                      if (v.trim().length < 3) return 'Mínimo 3 caracteres';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Correo electrónico
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Correo Electrónico',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      filled: true,
                      fillColor: tokens.isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Ingresa tu correo';
                      if (!v.contains('@') || !v.contains('.')) return 'Ingresa un correo válido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Teléfono / WhatsApp
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Teléfono / WhatsApp',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      hintText: '+591 70000000',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      filled: true,
                      fillColor: tokens.isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Moneda Principal
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCurrency,
                    decoration: InputDecoration(
                      labelText: 'Moneda Principal',
                      prefixIcon: const Icon(Icons.monetization_on_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      filled: true,
                      fillColor: tokens.isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'BOB', child: Text('Bolivianos (BOB - Bs)')),
                      DropdownMenuItem(value: 'USD', child: Text('Dólares Americanos (USD - \$)')),
                      DropdownMenuItem(value: 'EUR', child: Text('Euros (EUR - €)')),
                      DropdownMenuItem(value: 'PEN', child: Text('Soles Peruanos (PEN - S/)')),
                      DropdownMenuItem(value: 'ARS', child: Text('Pesos Argentinos (ARS - \$)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCurrency = val);
                    },
                  ),
                  const SizedBox(height: 22),

                  FilledButton.icon(
                    onPressed: _isSavingProfile ? null : _saveProfileData,
                    icon: _isSavingProfile
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(
                      _isSavingProfile ? 'Guardando...' : 'Guardar Cambios de Perfil',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // SECCIÓN 2: SEGURIDAD Y CONTRASEÑA
          Text(
            'SEGURIDAD Y CONTRASEÑA',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: tokens.cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: tokens.isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: Form(
              key: _passwordFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.lock_rounded, color: Colors.redAccent, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cambiar contraseña',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: tokens.textPrimary,
                              ),
                            ),
                            Text(
                              'Usa al menos 12 caracteres para mayor seguridad',
                              style: TextStyle(
                                fontSize: 12,
                                color: tokens.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Contraseña actual
                  TextFormField(
                    controller: _currentPasswordController,
                    obscureText: _obscureCurrentPass,
                    decoration: InputDecoration(
                      labelText: 'Contraseña Actual',
                      prefixIcon: const Icon(Icons.key_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureCurrentPass ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscureCurrentPass = !_obscureCurrentPass),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      filled: true,
                      fillColor: tokens.isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Ingresa tu contraseña actual';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Nueva contraseña
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: _obscureNewPass,
                    decoration: InputDecoration(
                      labelText: 'Nueva Contraseña',
                      helperText: 'Mínimo 12 caracteres',
                      prefixIcon: const Icon(Icons.lock_reset),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureNewPass ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscureNewPass = !_obscureNewPass),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      filled: true,
                      fillColor: tokens.isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Ingresa la nueva contraseña';
                      if (v.length < 12) return 'La nueva contraseña debe tener al menos 12 caracteres';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Confirmar contraseña
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPass,
                    decoration: InputDecoration(
                      labelText: 'Confirmar Nueva Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirmPass ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      filled: true,
                      fillColor: tokens.isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Confirma tu nueva contraseña';
                      if (v != _newPasswordController.text) return 'Las contraseñas no coinciden';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  OutlinedButton.icon(
                    onPressed: _isSavingPassword ? null : _updatePassword,
                    icon: _isSavingPassword
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.security_update_good_rounded),
                    label: Text(
                      _isSavingPassword ? 'Actualizando...' : 'Actualizar Contraseña',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: primary, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 36),
        ],
      ),
    );
  }
}
