import 'package:flutter/material.dart';
import '../widgets/rewarded_ad_dialog.dart';

class AdsProvider extends ChangeNotifier {
  // ID oficiales de prueba de Google AdMob
  final String adMobAppId = 'ca-app-pub-3940256099942544~3347511713';
  final String bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  final String rewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';

  bool _isOwner = false;
  bool _isCreatorMode = false;

  bool get isCreatorMode => _isOwner && _isCreatorMode;
  bool get shouldShowBannerAds => !isCreatorMode;
  bool get isInitialized => true;

  void assignOwner(bool isOwner) {
    if (_isOwner == isOwner) return;
    _isOwner = isOwner;
    _isCreatorMode = isOwner;
    notifyListeners();
  }

  void setCreatorMode(bool value) {
    if (!_isOwner) return;
    _isCreatorMode = value;
    notifyListeners();
  }

  /// CU-7.2: Rewarded Ad para IA (15 segundos para desbloquear análisis en cuenta gratis, bypass para Owner)
  Future<bool> requestRewardedAd(
    BuildContext context, {
    required VoidCallback onRewardGranted,
  }) async {
    if (isCreatorMode) {
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
