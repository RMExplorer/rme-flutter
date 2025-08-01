import 'package:flutter/material.dart';
import 'dart:ui'; // Import dart:ui for the BackdropFilter widget.

class GlassCard extends StatelessWidget {
  /// The title text to be displayed on the card.
  final String title;

  /// The body content of the card, which can be a single widget or a column of widgets.
  final Widget content;

  const GlassCard({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    // Get the theme's brightness to adjust text color.
    final brightness = Theme.of(context).brightness;
    final textColor = brightness == Brightness.dark ? Colors.white : Colors.black87;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            // Increased blur values for a more pronounced glassy effect.
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                // Increased opacity for better visibility in light mode.
                color: textColor.withOpacity(0.1),
                border: Border.all(color: textColor.withOpacity(0.2), width: 1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.0,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  DefaultTextStyle(
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      height: 1.5,
                    ),
                    child: content,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
