// Smart Vending logo that follows the theme: light-ground files in the light
// theme, the reversed `_dark` files in the dark theme. Inks are never tinted.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/sv_tokens.dart';

class SvLogoImage extends StatelessWidget {
  const SvLogoImage({
    super.key,
    this.kind = SvLogoKind.icon,
    this.height = 32,
    this.semanticLabel = 'Smart Vending',
  });

  final SvLogoKind kind;
  final double height;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      SvLogo.path(kind, Theme.of(context).brightness),
      height: height,
      semanticsLabel: semanticLabel,
      // The files use <mask> for the shelf cut-outs. If a flutter_svg version
      // ever renders them solid, precompile with vector_graphics_compiler
      // (supports masks) or flatten the masks in the source artwork.
    );
  }
}
