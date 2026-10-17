// Inline note (brand book "Banner"): warm = gentle heads-up (amber),
// soft = neutral news (mint tint). Never red for customer-facing problems.

import 'package:flutter/material.dart';

import '../theme/sv_tokens.dart';

enum SvNoteTone { warm, soft }

class SvNote extends StatelessWidget {
  const SvNote({super.key, required this.title, this.message, this.tone = SvNoteTone.warm, this.icon});

  final String title;
  final String? message;
  final SvNoteTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final SvColors c = SvColors.of(context);
    final TextTheme t = Theme.of(context).textTheme;
    final (Color bg, Color fg) = switch (tone) {
      SvNoteTone.warm => (c.warm, c.onWarm),
      SvNoteTone.soft => (c.brandSoft, c.ink),
    };
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(SvSpace.s3),
        decoration: BoxDecoration(color: bg, borderRadius: SvRadius.mdAll),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon ?? (tone == SvNoteTone.warm ? Icons.error_outline_rounded : Icons.check_rounded), color: fg, size: 22),
            const SizedBox(width: SvSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: t.titleSmall?.copyWith(color: fg)),
                  if (message != null) Text(message!, style: t.bodySmall?.copyWith(color: fg)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
