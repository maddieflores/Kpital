import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../features/auth/providers/auth_provider.dart';

class UserAvatar extends StatelessWidget {
  final UserModel user;
  final double radius;
  final bool showEditBadge;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  const UserAvatar({
    super.key,
    required this.user,
    this.radius = 32,
    this.showEditBadge = false,
    this.onTap,
    this.backgroundColor,
  });

  Widget _buildContent(BuildContext context) {
    final avatar = user.avatarUrl?.trim();

    if (avatar != null && avatar.isNotEmpty) {
      // 1. Emoji / Preset avatar
      if (avatar.startsWith('emoji:')) {
        final emoji = avatar.replaceFirst('emoji:', '');
        return Center(
          child: Text(
            emoji,
            style: TextStyle(fontSize: radius * 1.1),
          ),
        );
      }

      // 2. Base64 Image (data:image/...)
      if (avatar.startsWith('data:image/') || avatar.length > 200) {
        try {
          final pureBase64 = avatar.contains(',') ? avatar.split(',')[1] : avatar;
          final Uint8List bytes = base64Decode(pureBase64);
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            width: radius * 2,
            height: radius * 2,
            errorBuilder: (_, __, ___) => _buildFallback(context),
          );
        } catch (_) {
          return _buildFallback(context);
        }
      }

      // 3. Network URL (http/https)
      if (avatar.startsWith('http://') || avatar.startsWith('https://')) {
        return Image.network(
          avatar,
          fit: BoxFit.cover,
          width: radius * 2,
          height: radius * 2,
          errorBuilder: (_, __, ___) => _buildFallback(context),
        );
      }
    }

    return _buildFallback(context);
  }

  Widget _buildFallback(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    return Center(
      child: Text(
        user.initials,
        style: TextStyle(
          fontSize: radius * 0.75,
          fontWeight: FontWeight.bold,
          color: primaryColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final bg = backgroundColor ?? primaryColor.withValues(alpha: 0.15);

    Widget avatarCircle = Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.25),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: _buildContent(context),
      ),
    );

    if (showEditBadge) {
      avatarCircle = Stack(
        clipBehavior: Clip.none,
        children: [
          avatarCircle,
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                size: 15,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: avatarCircle,
      );
    }

    return avatarCircle;
  }
}
