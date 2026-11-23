import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/rewarded_ad_dialog.dart';

class AdsProvider extends ChangeNotifier {
  static const String _kCreatorModeKey = 'kpital_ads_creator_mode';

  // ID oficiales de prueba de Google AdMob
  final String adMobAppId = 'ca-app-pub-3940256099942544~3347511713';
  final String bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  final String rewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';

  bool _isCreatorMode = true; // Por defecto modo Creador (Owner) activo para el dueño
  bool _isInitialized = false;

  bool get isCreatorMode => _isCreatorMode;
  bool get shouldShowBannerAds => !_isCreatorMode;
  bool get isInitialized => _isInitialized;

  AdsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isCreatorMode = prefs.getBool(_kCreatorModeKey) ?? true;
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setCreatorMode(bool value) async {
    _isCreatorMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kCreatorModeKey, value);
  }

  /// CU-7.2: Rewarded Ad para IA (15 segundos para desbloquear análisis en cuenta gratis, bypass para Owner)
  Future<bool> requestRewardedAd(
    BuildContext context, {
    required VoidCallback onRewardGranted,
  }) async {
    if (_isCreatorMode) {
      // CU-7.3: Modo Creador desactiva anuncios automáticamente
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 2),
          backgroundColor: Color(0xFF10B981),
          content: Row(
            children: [
              Icon(Icons.workspace_premium, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text('Modo Creador (Owner) activo: Análisis IA ilimitado sin anuncios.'),
              ),
            ],
          ),
        ),
      );
      onRewardGranted();
      return true;
    }

    // Usuario común: Mostrar video publicitario de 15 segundos
    final granted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const RewardedAdDialog(),
    );

    if (granted == true) {
      onRewardGranted();
      return true;
    }

    return false;
  }
}
