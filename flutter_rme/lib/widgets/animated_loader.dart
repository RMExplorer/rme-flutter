import 'package:flutter/material.dart';

/// A widget that displays an animated loading card with a spinning word effect,
/// inspired by a design from Uiverse.io.
class AnimatedLoader extends StatefulWidget {
  const AnimatedLoader({super.key});

  @override
  State<AnimatedLoader> createState() => _AnimatedLoaderState();
}

class _AnimatedLoaderState extends State<AnimatedLoader> with SingleTickerProviderStateMixin {
  // A list of words to display in the animation
  final List<String> words = ['analytes', 'properties', 'materials', 'tables'];
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // Initialize the AnimationController with a duration of 4 seconds
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(); // Repeat the animation indefinitely.


    // The `_animation.value` will represent the negative multiple of `singleWordHeight`.
    _animation = TweenSequence<double>([
      // Transition from 0% (current word at 0.0) to 10% (overshoot -102%)
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -0.02),
        weight: 10, // 10% of total duration
      ),
      // Transition from 10% (overshoot -102%) to 25% (settle -100%) - first word (forms) becomes active
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.02, end: -1.0),
        weight: 15, // (25 - 10)% = 15% of total duration
      ),
      // Transition from 25% (current word at -1.0) to 35% (overshoot -202%)
      TweenSequenceItem(
        tween: Tween<double>(begin: -1.0, end: -1.02),
        weight: 10, // (35 - 25)% = 10% of total duration
      ),
      // Transition from 35% (overshoot -202%) to 50% (settle -200%) - second word (switches) becomes active
      TweenSequenceItem(
        tween: Tween<double>(begin: -1.02, end: -2.0),
        weight: 15, // (50 - 35)% = 15% of total duration
      ),
      // Transition from 50% (current word at -2.0) to 60% (overshoot -302%)
      TweenSequenceItem(
        tween: Tween<double>(begin: -2.0, end: -2.02),
        weight: 10, // (60 - 50)% = 10% of total duration
      ),
      // Transition from 60% (overshoot -302%) to 75% (settle -300%) - third word (cards) becomes active
      TweenSequenceItem(
        tween: Tween<double>(begin: -2.02, end: -3.0),
        weight: 15, // (75 - 60)% = 15% of total duration
      ),
      // Transition from 75% (current word at -3.0) to 85% (overshoot -402%)
      TweenSequenceItem(
        tween: Tween<double>(begin: -3.0, end: -3.02),
        weight: 10, // (85 - 75)% = 10% of total duration
      ),
      // Transition from 85% (overshoot -402%) to 100% (settle -400%) - duplicated first word (buttons) becomes active
      TweenSequenceItem(
        tween: Tween<double>(begin: -3.02, end: -4.0),
        weight: 15, // (100 - 85)% = 15% of total duration
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine the theme to adjust colors.
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? const Color(0xFF111111) : Colors.grey[200];
    final textColor = isDarkMode ? const Color(0xFF7C7C7C) : Colors.grey[700];
    const wordColor = Color(0xFF956AFA);

    // Define the height of a single word, consistent with the SizedBox height.
    const double singleWordHeight = 40.0;

    // Helper function to create a word widget with consistent styling and height.
    Widget _buildWord(String text) {
      return SizedBox(
        height: singleWordHeight,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
              fontSize: 25.0,
              color: wordColor,
            ),
          ),
        ),
      );
    }

    return Container(
      // The card container with padding and rounded corners.
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The "loading" text.
          Text(
            'loading',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
              fontSize: 25.0,
              color: textColor,
            ),
          ),
          const SizedBox(width: 8.0),
          // The words container, which is where the animation happens.
          SizedBox(
            height: singleWordHeight, // Only show one word at a time
            child: ClipRect( // Clip content that overflows visually
              child: Stack(
                children: [
                  SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(), // Disable user scrolling
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Transform.translate(
                          // Use the animation value (which is a multiple of `singleWordHeight`)
                          offset: Offset(0, _animation.value * singleWordHeight),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildWord(words[0]), // buttons (initial)
                              _buildWord(words[1]), // forms
                              _buildWord(words[2]), // switches
                              _buildWord(words[3]), // cards
                              _buildWord(words[0]), // buttons (duplicated for seamless loop)
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  // This is the gradient overlay that clips the top and bottom of the words,
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.1, 0.3, 0.7, 0.9],
                          colors: [
                            bgColor!,
                            bgColor.withOpacity(0.0),
                            bgColor.withOpacity(0.0),
                            bgColor,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}