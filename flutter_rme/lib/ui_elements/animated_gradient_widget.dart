import 'package:flutter/material.dart';

class AnimatedUiverseText extends StatefulWidget {
  final AnimationController controller;

  const AnimatedUiverseText({super.key, required this.controller});

  @override
  State<AnimatedUiverseText> createState() => _AnimatedUiverseTextState();
}

class _AnimatedUiverseTextState extends State<AnimatedUiverseText> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    const String text = 'Reference Material Explorer';
    const TextStyle baseStyle = TextStyle(
      fontSize: 38,
      fontFamily: "Arial",
      letterSpacing: 3,
      fontWeight: FontWeight.normal,
    );

    final strokeColor = _isHovering ? Colors.transparent : const Color(0x7CFFFFFF);
    final borderColor = _isHovering ? const Color(0xFF03A9F4) : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: () {
          // Handle tap if needed
        },
        child: Stack(
          children: [
            // The stroked text
            Text(
              text,
              style: baseStyle.copyWith(
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 1
                  ..color = strokeColor,
              ),
            ),
            // The animated gradient text (front text)
            AnimatedBuilder(
              animation: widget.controller,
              builder: (context, child) {
                return ShaderMask(
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      colors: const [
                        Color(0xFF03A9F4),
                        Color(0xFFF441A5),
                        Color(0xFFFFEB3B),
                        Color(0xFF03A9F4),
                      ],
                      tileMode: TileMode.repeated,
                      transform: GradientRotation(
                          widget.controller.value * 2 * -(2 * 3.141592653589793)), // 400% animation = 2 full rotations
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.srcIn,
                  child: Text(
                    text,
                    style: baseStyle.copyWith(
                      color: Colors.white, // Color doesn't matter much as it's masked
                    ),
                  ),
                );
              },
            ),
            // The animated border
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: AnimatedContainer(
                  duration: const Duration(seconds: 1),
                  height: 2,
                  width: _isHovering ? MediaQuery.of(context).size.width : 0, // This needs refinement based on actual text width
                  decoration: BoxDecoration(
                    color: borderColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}