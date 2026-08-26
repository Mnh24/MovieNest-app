import 'package:flutter/material.dart';

/// Fades and slides a list item in on first build, with a small delay based
/// on [index] so items in the same list cascade in rather than popping in
/// all at once. Purely a first-appearance effect — rebuilds after the entry
/// animation completes render the child directly.
class StaggeredListItem extends StatefulWidget {
  const StaggeredListItem({
    super.key,
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  static const Duration _stepDelay = Duration(milliseconds: 40);
  static const Duration _duration = Duration(milliseconds: 320);
  static const int _maxStaggeredIndex = 12;

  @override
  State<StaggeredListItem> createState() => _StaggeredListItemState();
}

class _StaggeredListItemState extends State<StaggeredListItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: StaggeredListItem._duration,
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.06),
    end: Offset.zero,
  ).animate(_fade);

  @override
  void initState() {
    super.initState();
    // Cap the delay so a long list doesn't leave late items invisible for
    // a noticeable pause — only the first screenful staggers meaningfully.
    final cappedIndex = widget.index.clamp(
      0,
      StaggeredListItem._maxStaggeredIndex,
    );
    final delay = StaggeredListItem._stepDelay * cappedIndex;
    if (delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
