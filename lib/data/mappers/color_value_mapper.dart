class ColorValueMapper {
  const ColorValueMapper._();

  static int toColorValue(String color) {
    final normalized = color.replaceFirst('#', '');
    final value = normalized.length == 6 ? 'FF$normalized' : normalized;
    return int.tryParse(value, radix: 16) ?? 0xFF2E7D32;
  }

  static String fromColorValue(int colorValue) {
    final value = colorValue & 0xFFFFFFFF;
    final alpha = (value >> 24) & 0xFF;
    final rgb = value & 0x00FFFFFF;
    final rgbHex = rgb.toRadixString(16).padLeft(6, '0').toUpperCase();

    if (alpha == 0xFF) return '#$rgbHex';

    final alphaHex = alpha.toRadixString(16).padLeft(2, '0').toUpperCase();
    return '#$alphaHex$rgbHex';
  }
}
