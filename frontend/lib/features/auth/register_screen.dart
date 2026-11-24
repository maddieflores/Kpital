import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/kpital_logo.dart';
import 'login_screen.dart';
import 'providers/auth_provider.dart';
import '../../main.dart';

/// Pantalla 4B: Registro / Crear cuenta
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController(text: '+591 ');
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = true;
  String _selectedCurrency = 'Bs · Boliviano (BOB)';

  final List<String> _currencies = [
    'Bs · Boliviano (BOB)',
    '\$ · Dólar Estadounidense (USD)',
    '€ · Euro (EUR)',
    'S/ · Sol Peruano (PEN)',
    '\$ · Peso Argentino (ARS)',
  ];

  void _submitRegister() {
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, acepta los términos y condiciones de privacidad.'),
          backgroundColor: Color(0xFF8261B8),
        ),
      );
      return;
    }

    final authProv = Provider.of<AuthProvider>(context, listen: false);
    if (_nameController.text.trim().isNotEmpty) {
      authProv.updateProfile(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      );
    }

    // Navegar directamente al Dashboard
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      (route) => false,
    );
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _goToDemo() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      (route) => false,
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Términos y Privacidad'),
        content: const SingleChildScrollView(
          child: Text(
            'En Kpital protegemos la privacidad de tus finanzas. '
            'Toda tu información está cifrada y bajo tu control total. '
            'No compartimos tus datos con terceros ni entidades comerciales sin tu consentimiento explícito.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido', style: TextStyle(color: Color(0xFF8261B8))),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryPurple = Color(0xFF8261B8);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const KpitalAppBar(
        showBackButton: true,
        showWordmark: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // Título y bienvenida
              const Text(
                'Tu tranquilidad empieza aquí',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  color: Color(0xFF1E1A29),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Un pequeño paso para tomar el control.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6E6879),
                ),
              ),

              const SizedBox(height: 28),

              // 1. Nombre completo
              _buildFieldLabel('Nombre completo'),
              _buildTextField(
                controller: _nameController,
                hintText: '¿Cómo te llamas?',
                keyboardType: TextInputType.name,
              ),

              const SizedBox(height: 18),

              // 2. Correo electrónico
              _buildFieldLabel('Correo electrónico'),
              _buildTextField(
                controller: _emailController,
                hintText: 'ejemplo@correo.com',
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 18),

              // 3. Número de teléfono
              _buildFieldLabel('Número de teléfono'),
              _buildTextField(
                controller: _phoneController,
                hintText: '+591 70000000',
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 18),

              // 4. Contraseña
              _buildFieldLabel('Contraseña'),
              _buildTextField(
                controller: _passwordController,
                hintText: '8 caracteres, mayúscula y núm...',
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: primaryPurple,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),

              const SizedBox(height: 18),

              // 5. Confirmar contraseña
              _buildFieldLabel('Confirmar contraseña'),
              _buildTextField(
                controller: _confirmPasswordController,
                hintText: 'Repite tu contraseña',
                obscureText: _obscureConfirmPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: primaryPurple,
                  ),
                  onPressed: () {
                    setState(
                        () => _obscureConfirmPassword = !_obscureConfirmPassword);
                  },
                ),
              ),

              const SizedBox(height: 18),

              // 6. Moneda predeterminada
              _buildFieldLabel('Moneda predeterminada'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E0EC)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCurrency,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down,
                        color: primaryPurple),
                    items: _currencies.map((currency) {
                      return DropdownMenuItem<String>(
                        value: currency,
                        child: Text(
                          currency,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E1A29),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedCurrency = val);
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // 7. Checkbox Términos y condiciones
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: Checkbox(
                      value: _acceptedTerms,
                      activeColor: primaryPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      side: const BorderSide(color: Color(0xFFB0A9BB)),
                      onChanged: (val) {
                        setState(() => _acceptedTerms = val ?? false);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Acepto los términos y privacidad',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF4A4458),
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: _showTermsDialog,
                          child: const Text(
                            'Leer términos',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: primaryPurple,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 26),

              // Botón "Crear mi cuenta"
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _submitRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryPurple,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shadowColor: primaryPurple.withOpacity(0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Crear mi cuenta',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Separador "o continúa a tu ritmo"
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade200)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      'o continúa a tu ritmo',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade200)),
                ],
              ),

              const SizedBox(height: 20),

              // ¿Ya tienes cuenta? Inicia sesión
              Center(
                child: GestureDetector(
                  onTap: _goToLogin,
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        color: Color(0xFF4A4458),
                      ),
                      children: [
                        TextSpan(text: '¿Ya tienes cuenta? '),
                        TextSpan(
                          text: 'Inicia sesión',
                          style: TextStyle(
                            color: primaryPurple,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Modo demo
              Center(
                child: TextButton(
                  onPressed: _goToDemo,
                  child: const Text(
                    'Explorar modo demo',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: primaryPurple,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Subtítulo de aviso simulado
              Center(
                child: Text(
                  'Acceso simulado · No utilices credenciales reales',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E1A29),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    const primaryPurple = Color(0xFF8261B8);
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFFB0A9BB)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        filled: true,
        fillColor: const Color(0xFFFAFAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5E0EC)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5E0EC)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryPurple, width: 1.8),
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
