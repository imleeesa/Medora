import 'package:flutter/material.dart';

/// Render controllato degli asset 3D Medora (assets/images/medora/).
/// Gli asset sono elementi di brand decorativi: di default sono ESCLUSI
/// dalla semantica (screen reader). Passare `semanticLabel` solo quando
/// l'immagine comunica davvero un'informazione non presente nel testo.
/// Mai usarli come unico veicolo di uno stato (regola UI bible).
class Medora3DAsset extends StatelessWidget {
  static const String capsuleMint = 'assets/images/medora/capsule_3d_mint.png';
  static const String pillLavender =
      'assets/images/medora/pill_3d_lavender.png';
  static const String pillAmber = 'assets/images/medora/pill_3d_amber.png';
  static const String blisterSoft = 'assets/images/medora/blister_3d_soft.png';
  static const String bellSoft = 'assets/images/medora/bell_3d_soft.png';
  static const String heartPulse = 'assets/images/medora/heart_3d_pulse.png';
  static const String emptyPillsIllustration =
      'assets/images/medora/empty_pills_illustration.png';

  final String assetPath;
  final double size;
  final String? semanticLabel;

  const Medora3DAsset(
    this.assetPath, {
    super.key,
    required this.size,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      // Un asset mancante non deve mai rompere il layout: fallback invisibile
      // della stessa dimensione.
      errorBuilder: (_, __, ___) => SizedBox(width: size, height: size),
    );

    if (semanticLabel == null) {
      return ExcludeSemantics(child: image);
    }
    return Semantics(label: semanticLabel, image: true, child: image);
  }
}
