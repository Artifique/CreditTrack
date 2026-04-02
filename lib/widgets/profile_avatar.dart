import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/profile_model.dart';

/// Avatar avec initiales (plus de photo réseau). [lightStyle] : fond blanc sur bandeau dégradé.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.profile,
    required this.radius,
    this.lightStyle = false,
  });

  final ProfileModel? profile;
  final double radius;
  final bool lightStyle;

  static String initialsFor(ProfileModel? profile) {
    String name = '';
    if (profile != null) {
      final o = profile.ownerName?.trim();
      if (o != null && o.isNotEmpty) {
        name = o;
      } else {
        name = profile.businessName.trim();
      }
    }
    if (name.isEmpty) name = 'CT';
    final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    final single = parts.isNotEmpty ? parts[0] : name;
    if (single.length >= 2) return single.substring(0, 2).toUpperCase();
    return single.isNotEmpty ? single[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final text = initialsFor(profile);
    final fontSize = radius * 0.85;
    if (lightStyle) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white,
        child: Text(
          text,
          style: TextStyle(
            color: AppColors.primary,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            letterSpacing: text.length == 2 ? -0.5 : 0,
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          letterSpacing: text.length == 2 ? -0.5 : 0,
        ),
      ),
    );
  }
}
