import 'package:flutter/material.dart';

/// Converte un colore hex (con o senza '#', con o senza canale alfa) in [Color].
/// Utility pura, sostituisce le implementazioni locali duplicate `_parseColor`
/// presenti in piu' schermate. Non ancora cablata: adozione progressiva sprint
/// per sprint per non modificare piu' schermate contemporaneamente.
Color parseHexColor(String hex) {
  var value = hex.replaceFirst('#', '');
  if (value.length == 6) value = 'FF$value';
  return Color(int.parse(value, radix: 16));
}
