import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_colors.dart';
import 'app_design_tokens.dart';

enum DisplayMode { claro, oscuro, automatico }

class ThemeProvider extends ChangeNotifier {
  static const String _prefIdentityKey = 'nivo_visual_identity';
  static const String _prefDisplayModeKey = 'nivo_display_mode';
  static const String _prefBgTypeKey = 'nivo_bg_type'; // 'default', 'preset', 'custom', 'gradient'
  static const String _prefBgValueKey = 'nivo_bg_value';

  // 1. Identidad por defecto: Violeta Premium #8261B8 (Identidad Kpital)
  VisualIdentity _currentIdentity = AppVisualIdentities.violetaPremium;
  DisplayMode _displayMode = DisplayMode.automatico;

  // Estado de fondo independiente
  String _bgType = 'default';
  String? _selectedPresetId;
  String? _customHexBg;
  String? _selectedGradientId;

  bool _isInitialized = false;

  ThemeProvider() {
    _loadPreferences();
  }

  // Getters
  VisualIdentity get currentIdentity => _currentIdentity;
  DisplayMode get displayMode => _displayMode;
  String get bgType => _bgType;
  String? get selectedPresetId => _selectedPresetId;
  String? get customHexBg => _customHexBg;
  String? get selectedGradientId => _selectedGradientId;
  bool get isInitialized => _isInitialized;

  // Carga persistente desde SharedPreferences
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final identityId = prefs.getString(_prefIdentityKey);
      if (identityId != null) {
        _currentIdentity = AppVisualIdentities.fromId(identityId);
      }

      final modeStr = prefs.getString(_prefDisplayModeKey);
      if (modeStr != null) {
        if (modeStr == 'claro') _displayMode = DisplayMode.claro;
        if (modeStr == 'oscuro') _displayMode = DisplayMode.oscuro;
        if (modeStr == 'automatico') _displayMode = DisplayMode.automatico;
      }

      _bgType = prefs.getString(_prefBgTypeKey) ?? 'default';
      final bgVal = prefs.getString(_prefBgValueKey);

      if (_bgType == 'preset' && bgVal != null) {
        _selectedPresetId = bgVal;
      } else if (_bgType == 'custom' && bgVal != null) {
        _customHexBg = bgVal;
      } else if (_bgType == 'gradient' && bgVal != null) {
        _selectedGradientId = bgVal;
      }
    } catch (_) {
      // Si falla almacenamiento, mantenemos los valores estándar
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Guardar configuración en disco
  Future<void> savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefIdentityKey, _currentIdentity.id);
      await prefs.setString(_prefDisplayModeKey, _displayMode.name);
      await prefs.setString(_prefBgTypeKey, _bgType);

      if (_bgType == 'preset' && _selectedPresetId != null) {
        await prefs.setString(_prefBgValueKey, _selectedPresetId!);
      } else if (_bgType == 'custom' && _customHexBg != null) {
        await prefs.setString(_prefBgValueKey, _customHexBg!);
      } else if (_bgType == 'gradient' && _selectedGradientId != null) {
        await prefs.setString(_prefBgValueKey, _selectedGradientId!);
      } else {
        await prefs.remove(_prefBgValueKey);
      }
    } catch (_) {}
  }

  // Métodos de cambio
  void setIdentity(VisualIdentity identity) {
    _currentIdentity = identity;
    notifyListeners();
  }

  void setDisplayMode(DisplayMode mode) {
    _displayMode = mode;
    notifyListeners();
  }

  void setBackgroundPreset(String presetId) {
    _bgType = 'preset';
    _selectedPresetId = presetId;
    _customHexBg = null;
    _selectedGradientId = null;
    notifyListeners();
  }

  void setCustomHexBackground(String hex) {
    var cleanHex = hex.trim().replaceAll('#', '');
    if (cleanHex.length == 6) {
      _bgType = 'custom';
      _customHexBg = '#${cleanHex.toUpperCase()}';
      _selectedPresetId = null;
      _selectedGradientId = null;
      notifyListeners();
    }
  }

  void setGradientBackground(String gradientId) {
    _bgType = 'gradient';
    _selectedGradientId = gradientId;
    _selectedPresetId = null;
    _customHexBg = null;
    notifyListeners();
  }

  void resetBackgroundOnly() {
    _bgType = 'default';
    _selectedPresetId = null;
    _customHexBg = null;
    _selectedGradientId = null;
    notifyListeners();
  }

  void resetToOriginal() {
    _currentIdentity = AppVisualIdentities.azulTecnologico;
    _displayMode = DisplayMode.automatico;
    resetBackgroundOnly();
  }

  // Color de fondo resuelto dinámicamente
  Color get effectiveBackgroundColor {
    if (_bgType == 'preset' && _selectedPresetId != null) {
      final preset = AppBackgroundPresets.fromId(_selectedPresetId);
      if (preset != null) return preset.color;
    } else if (_bgType == 'custom' && _customHexBg != null) {
      try {
        final val = int.parse(_customHexBg!.replaceAll('#', 'FF'), radix: 16);
        return Color(val);
      } catch (_) {}
    } else if (_bgType == 'gradient' && _selectedGradientId != null) {
      final grad = AppGradientPresets.fromId(_selectedGradientId);
      if (grad != null) return grad.colors.first;
    }

    // Default por identidad o modo
    if (_displayMode == DisplayMode.oscuro) {
      return const Color(0xFF171A1E);
    }
    return _currentIdentity.defaultScaffoldBg;
  }

  Gradient? get effectiveGradient {
    if (_bgType == 'gradient' && _selectedGradientId != null) {
      final grad = AppGradientPresets.fromId(_selectedGradientId);
      return grad?.gradient;
    }
    return null;
  }

  // ThemeData completo con tokens inyectados
  ThemeData get themeData {
    final scaffoldBg = effectiveBackgroundColor;
    final gradient = effectiveGradient;
    
    // Contraste calculado según la luminancia del fondo (WCAG)
    final bool isDark = scaffoldBg.computeLuminance() < 0.45;

    final Color cardBg = isDark
        ? (_currentIdentity.isDefaultDark ? _currentIdentity.defaultCardBg : const Color(0xFF23272F))
        : _currentIdentity.defaultCardBg;

    final Color textPrimary = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
    final Color textSecondary = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    final tokens = AppDesignTokens(
      identity: _currentIdentity,
      scaffoldBg: scaffoldBg,
      cardBg: cardBg,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      balanceCardBg: _currentIdentity.balanceCardColor,
      balanceCardText: _currentIdentity.balanceCardTextColor,
      backgroundGradient: gradient,
      isDark: isDark,
    );

    final baseTheme = isDark ? ThemeData.dark() : ThemeData.light();

    return baseTheme.copyWith(
      scaffoldBackgroundColor: scaffoldBg,
      primaryColor: _currentIdentity.primary,
      cardColor: cardBg,
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: _currentIdentity.primary,
        secondary: _currentIdentity.secondary,
        surface: cardBg,
        brightness: isDark ? Brightness.dark : Brightness.light,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: isDark
              ? BorderSide(color: Colors.white.withOpacity(0.08), width: 1)
              : BorderSide(color: Colors.black.withOpacity(0.04), width: 1),
        ),
      ),
      extensions: [tokens],
    );
  }
}
