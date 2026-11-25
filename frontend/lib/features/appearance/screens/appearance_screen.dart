import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/theme/theme_provider.dart';
import '../widgets/live_preview_card.dart';

class AppearanceScreen extends StatefulWidget {
  final int? initialTabIndex;
  const AppearanceScreen({super.key, this.initialTabIndex});

  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {
  final TextEditingController _hexController = TextEditingController(text: "#E5EAE7");

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final tokens = context.tokens;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Estilos & Apariencia"),
        centerTitle: false,
        actions: [
          TextButton.icon(
            onPressed: () {
              themeProvider.resetToOriginal();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Apariencia restaurada a Azul Tecnológico predeterminado."),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text("Restaurar original"),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Identidad de la aplicación
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: tokens.cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: tokens.isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Identidad de la aplicación", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  "Tu color principal permanece, independientemente del fondo.",
                  style: TextStyle(color: tokens.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                ...AppVisualIdentities.all.map((id) {
                  final isSelected = themeProvider.currentIdentity.id == id.id;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? id.primary.withOpacity(0.08) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? id.primary : Colors.black.withOpacity(0.06),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: ListTile(
                      onTap: () => themeProvider.setIdentity(id),
                      dense: true,
                      leading: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(color: id.primary, shape: BoxShape.circle),
                      ),
                      title: Text(
                        id.name,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? id.primary : tokens.textPrimary,
                        ),
                      ),
                      trailing: isSelected ? Icon(Icons.check, color: id.primary, size: 20) : null,
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Modo de visualización
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: tokens.cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: tokens.isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Modo de visualización", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _buildModeButton(context, themeProvider, DisplayMode.claro, "Claro", Icons.wb_sunny_outlined),
                    const SizedBox(width: 8),
                    _buildModeButton(context, themeProvider, DisplayMode.oscuro, "Oscuro", Icons.nightlight_outlined),
                    const SizedBox(width: 8),
                    _buildModeButton(context, themeProvider, DisplayMode.automatico, "Automático", Icons.settings_suggest_outlined),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  "Automático utiliza la preferencia de tu dispositivo. Un fondo elegido tiene prioridad.",
                  style: TextStyle(color: tokens.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Elige tu fondo
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: tokens.cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: tokens.isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Elige tu fondo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 14),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: AppBackgroundPresets.all.length,
                  itemBuilder: (context, i) {
                    final preset = AppBackgroundPresets.all[i];
                    final isSelected = themeProvider.bgType == 'preset' && themeProvider.selectedPresetId == preset.id;

                    return InkWell(
                      onTap: () => themeProvider.setBackgroundPreset(preset.id),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: preset.color,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? themeProvider.currentIdentity.primary : Colors.grey.withOpacity(0.3),
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        alignment: Alignment.bottomLeft,
                        child: Text(
                          preset.name,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: preset.color.computeLuminance() < 0.45 ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 18),

                // Un color a tu medida
                const Text("Un color a tu medida", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: themeProvider.effectiveBackgroundColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.withOpacity(0.4)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _hexController,
                        decoration: InputDecoration(
                          hintText: "HEX #E5EAE7",
                          prefixText: "HEX ",
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        themeProvider.setCustomHexBackground(_hexController.text);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeProvider.currentIdentity.primary.withOpacity(0.15),
                        foregroundColor: themeProvider.currentIdentity.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text("Aplicar color"),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Degradados elegantes
                const Text("Degradados elegantes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 10),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: AppGradientPresets.all.length,
                  itemBuilder: (context, i) {
                    final grad = AppGradientPresets.all[i];
                    final isSelected = themeProvider.bgType == 'gradient' && themeProvider.selectedGradientId == grad.id;

                    return InkWell(
                      onTap: () => themeProvider.setGradientBackground(grad.id),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: grad.gradient,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? themeProvider.currentIdentity.primary : Colors.grey.withOpacity(0.3),
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        alignment: Alignment.bottomLeft,
                        child: Text(
                          grad.name,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: grad.colors.first.computeLuminance() < 0.45 ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),

                Center(
                  child: TextButton.icon(
                    onPressed: () => themeProvider.resetBackgroundOnly(),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text("Restaurar solo el fondo"),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Tu vista previa • En tiempo real
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Tu vista previa",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "En tiempo real",
                    style: TextStyle(color: tokens.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          LivePreviewCard(
            identity: themeProvider.currentIdentity,
            scaffoldBg: themeProvider.effectiveBackgroundColor,
            gradient: themeProvider.effectiveGradient,
            isDark: themeProvider.themeData.brightness == Brightness.dark,
          ),
          const SizedBox(height: 24),

          // Botón Guardar apariencia
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () async {
                await themeProvider.savePreferences();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: themeProvider.currentIdentity.primary,
                      content: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 10),
                          Text("Apariencia guardada en este dispositivo con éxito.", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: themeProvider.currentIdentity.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
              ),
              icon: const Icon(Icons.check),
              label: const Text("Guardar apariencia", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Column(
              children: [
                Text(
                  "Solo cambia tu estilo, no tus finanzas.",
                  style: TextStyle(color: tokens.textSecondary, fontSize: 12),
                ),
                Text(
                  "Las preferencias se guardan en este dispositivo.",
                  style: TextStyle(color: tokens.textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 14),
                Text(
                  "Kpital • Tu capital, en calma.",
                  style: TextStyle(color: tokens.textSecondary.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildModeButton(BuildContext context, ThemeProvider theme, DisplayMode mode, String label, IconData icon) {
    final isSelected = theme.displayMode == mode;
    return Expanded(
      child: InkWell(
        onTap: () => theme.setDisplayMode(mode),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? theme.currentIdentity.primary.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? theme.currentIdentity.primary : Colors.grey.withOpacity(0.3),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? theme.currentIdentity.primary : context.tokens.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? theme.currentIdentity.primary : context.tokens.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
