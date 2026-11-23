import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/theme/theme_provider.dart';
import '../widgets/live_preview_card.dart';

class AppearanceScreen extends StatefulWidget {
  final int initialTabIndex;
  const AppearanceScreen({super.key, this.initialTabIndex = 2});

  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _hexController = TextEditingController(text: "#E5EAE7");

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTabIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: themeProvider.currentIdentity.primary,
          unselectedLabelColor: tokens.textSecondary,
          indicatorColor: themeProvider.currentIdentity.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: "Propuestas\nvisuales"),
            Tab(text: "Explorar\ncolores"),
            Tab(text: "Personalización"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVisualProposalsTab(context, themeProvider),
          _buildColorExplorerTab(context, themeProvider),
          _buildCustomizationTab(context, themeProvider),
        ],
      ),
    );
  }

  // PESTAÑA 1: PROPUESTAS VISUALES (A, B, C, D)
  Widget _buildVisualProposalsTab(BuildContext context, ThemeProvider theme) {
    final proposals = [
      AppVisualIdentities.azulTecnologico,
      AppVisualIdentities.violetaPremium,
      AppVisualIdentities.minimalistaClaro,
      AppVisualIdentities.oscuroElegante,
    ];

    final labels = ['A', 'B', 'C', 'D'];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          "Encuentra tu identidad",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          "Mismos datos, diferentes sensaciones",
          style: TextStyle(color: context.tokens.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 20),
        ...List.generate(proposals.length, (index) {
          final p = proposals[index];
          final isSelected = theme.currentIdentity.id == p.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.withOpacity(0.4)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            labels[index],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            Text(p.subtitle, style: TextStyle(color: context.tokens.textSecondary, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: p.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check, size: 14, color: p.primary),
                            const SizedBox(width: 4),
                            Text("Seleccionada", style: TextStyle(color: p.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    else
                      OutlinedButton(
                        onPressed: () {
                          theme.setIdentity(p);
                          theme.resetBackgroundOnly();
                        },
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text("Elegir propuesta →"),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                LivePreviewCard(
                  identity: p,
                  scaffoldBg: p.defaultScaffoldBg,
                  isDark: p.isDefaultDark,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // PESTAÑA 2: EXPLORAR COLORES (Petróleo, Terracota, Acero, Oliva)
  Widget _buildColorExplorerTab(BuildContext context, ThemeProvider theme) {
    final explorerIdentities = [
      AppVisualIdentities.petroleoSereno,
      AppVisualIdentities.terracotaEditorial,
      AppVisualIdentities.aceroContemporaneo,
      AppVisualIdentities.olivaEsencial,
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ...explorerIdentities.map((item) {
          final isSelected = theme.currentIdentity.id == item.id;
          return Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: context.tokens.cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? item.primary : Colors.black.withOpacity(0.06),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                        Text(item.subtitle, style: TextStyle(color: context.tokens.textSecondary, fontSize: 12)),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        theme.setIdentity(item);
                        theme.resetBackgroundOnly();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: item.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.palette_outlined, size: 16),
                      label: Text(isSelected ? "Activo" : "Probar paleta"),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildColorSpecRow("Principal", item.primary),
                _buildColorSpecRow("Secundario", item.secondary),
                _buildColorSpecRow("Fondo", item.defaultScaffoldBg),
                _buildColorSpecRow("Tarjetas", item.defaultCardBg),
                const SizedBox(height: 14),
                LivePreviewCard(
                  identity: item,
                  scaffoldBg: item.defaultScaffoldBg,
                  isDark: item.isDefaultDark,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildColorSpecRow(String label, Color color) {
    final hex = '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
              ),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 13)),
            ],
          ),
          Text(hex, style: const TextStyle(fontSize: 13, fontFamily: 'monospace', fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // PESTAÑA 3: PERSONALIZACIÓN COMPLETA (Figma Make Screen)
  Widget _buildCustomizationTab(BuildContext context, ThemeProvider theme) {
    final tokens = context.tokens;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // 01 Identidad de la aplicación
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
              const Text("01 Identidad de la aplicación", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(
                "Tu color principal permanece, independientemente del fondo.",
                style: TextStyle(color: tokens.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ...AppVisualIdentities.all.map((id) {
                final isSelected = theme.currentIdentity.id == id.id;
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
                    onTap: () => theme.setIdentity(id),
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

        // 02 Modo de visualización
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
              const Text("02 Modo de visualización", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 14),
              Row(
                children: [
                  _buildModeButton(context, theme, DisplayMode.claro, "Claro", Icons.wb_sunny_outlined),
                  const SizedBox(width: 8),
                  _buildModeButton(context, theme, DisplayMode.oscuro, "Oscuro", Icons.nightlight_outlined),
                  const SizedBox(width: 8),
                  _buildModeButton(context, theme, DisplayMode.automatico, "Automático", Icons.settings_suggest_outlined),
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

        // 03 Elige tu fondo
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
              const Text("03 Elige tu fondo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                  final isSelected = theme.bgType == 'preset' && theme.selectedPresetId == preset.id;

                  return InkWell(
                    onTap: () => theme.setBackgroundPreset(preset.id),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: preset.color,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? theme.currentIdentity.primary : Colors.grey.withOpacity(0.3),
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
                      color: theme.effectiveBackgroundColor,
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
                      theme.setCustomHexBackground(_hexController.text);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.currentIdentity.primary.withOpacity(0.15),
                      foregroundColor: theme.currentIdentity.primary,
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
                  final isSelected = theme.bgType == 'gradient' && theme.selectedGradientId == grad.id;

                  return InkWell(
                    onTap: () => theme.setGradientBackground(grad.id),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: grad.gradient,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? theme.currentIdentity.primary : Colors.grey.withOpacity(0.3),
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
                  onPressed: () => theme.resetBackgroundOnly(),
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
          identity: theme.currentIdentity,
          scaffoldBg: theme.effectiveBackgroundColor,
          gradient: theme.effectiveGradient,
          isDark: theme.themeData.brightness == Brightness.dark,
        ),
        const SizedBox(height: 24),

        // Botón Guardar apariencia
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () async {
              await theme.savePreferences();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: theme.currentIdentity.primary,
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
              backgroundColor: theme.currentIdentity.primary,
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
                "nivo. Finanzas en equilibrio.",
                style: TextStyle(color: tokens.textSecondary.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Text(
                "Prototipo visual • Datos ilustrativos",
                style: TextStyle(color: tokens.textSecondary.withOpacity(0.5), fontSize: 10),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
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
