import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// A custom iOS-style page route that applies a frosted glass blur effect to the
/// previous page during push, pop, and interactive edge-swipe back gestures.
class GlassPageRoute<T> extends PageRoute<T> with CupertinoRouteTransitionMixin<T> {
  GlassPageRoute({
    required this.builder,
    super.settings,
  });

  final WidgetBuilder builder;

  @override
  Widget buildContent(BuildContext context) => builder(context);

  @override
  String? get title => null;

  @override
  bool get maintainState => true;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final transition = super.buildTransitions(
      context,
      animation,
      secondaryAnimation,
      child,
    );

    // Smooth, progressive glass blur on the underlying route
    final blurVal = (animation.value * 16.0).clamp(0.0, 16.0);
    final overlayAlpha = (animation.value * 0.2).clamp(0.0, 0.2);

    if (animation.value <= 0.001) {
      return transition;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurVal, sigmaY: blurVal),
            child: Container(
              color: Colors.black.withValues(alpha: overlayAlpha),
            ),
          ),
        ),
        transition,
      ],
    );
  }
}
