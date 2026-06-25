import 'package:flutter/material.dart';
import 'package:nesd/ui/common/focus_on_hover.dart';
import 'package:nesd/ui/theme/base.dart';

class NesdButton extends StatelessWidget {
  const NesdButton({
    required this.child,
    this.autofocus = false,
    this.icon,
    this.onPressed,
    this.width = 200,
    super.key,
  });

  final Widget child;
  final bool autofocus;
  final Icon? icon;
  final VoidCallback? onPressed;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return FocusOnHover(
      child: DefaultTextStyle(
        style: baseTextStyle.copyWith(
          fontVariations: const [FontVariation.weight(700)],
        ),
        child: SizedBox(
          width: width,
          child: icon != null
              ? FilledButton.icon(
                  autofocus: autofocus,
                  onPressed: onPressed,
                  icon: icon,
                  label: child,
                )
              : FilledButton(
                  autofocus: autofocus,
                  onPressed: onPressed,
                  child: child,
                ),
        ),
      ),
    );
  }
}
