import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/emulator/input/action_handler.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/emulator/input/touch/touch_controls.dart';
import 'package:nesd/ui/emulator/input/touch/touch_input_config.dart';

class JoyStick extends HookConsumerWidget {
  const JoyStick({required this.config, super.key});

  final JoyStickConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionStream = ref.watch(actionStreamProvider);
    final innerOffset = useState(Offset.zero);
    final active = useState(false);
    final touchCenter = useState<Offset?>(null);

    final touchArea = TouchArea.of(context);
    final viewportSize = touchArea.size;

    // 计算默认摇杆中心位置（用config的x,y）
    final halfW = viewportSize.width / 2;
    final halfH = viewportSize.height / 2;
    final centerX = viewportSize.width / 2;
    final centerY = viewportSize.height / 2;
    final defaultCenter = Offset(
      centerX + config.x * halfW,
      centerY + config.y * halfH,
    );

    // 当前摇杆中心：激活时跟随触摸点，否则在默认位置
    final joystickCenter =
        active.value ? (touchCenter.value ?? defaultCenter) : defaultCenter;

    final radius = config.size / 2;

    void handleEdge(
      double previous,
      double current,
      InputAction? action,
    ) {
      if (action == null) {
        return;
      }

      final inside = current > config.deadZone;

      if (previous <= config.deadZone != inside) {
        actionStream.add(
          InputActionEvent(
            action: action,
            value: inside ? 1.0 : 0.0,
            bindingType: config.bindingType,
          ),
        );
      }
    }

    void updateFromGlobal(Offset globalTouchPos) {
      final center = touchCenter.value ?? defaultCenter;
      final dx = globalTouchPos.dx - center.dx;
      final dy = globalTouchPos.dy - center.dy;

      final distance = Offset(dx, dy).distance;

      final prevNormX = innerOffset.value.dx / radius;
      final prevNormY = innerOffset.value.dy / radius;

      final Offset newOffset;
      if (distance < radius) {
        newOffset = Offset(dx, dy);
      } else {
        // 限制在圆形范围内
        newOffset = Offset(
          dx / distance * radius,
          dy / distance * radius,
        );
      }
      innerOffset.value = newOffset;

      final normX = newOffset.dx / radius;
      final normY = newOffset.dy / radius;

      handleEdge(-prevNormX, -normX, config.leftAction);
      handleEdge(prevNormX, normX, config.rightAction);
      handleEdge(-prevNormY, -normY, config.upAction);
      handleEdge(prevNormY, normY, config.downAction);
    }

    void releaseAll() {
      for (final action in [
        config.upAction,
        config.downAction,
        config.leftAction,
        config.rightAction,
      ]) {
        if (action != null) {
          actionStream.add(
            InputActionEvent(
              action: action,
              value: 0.0,
              bindingType: config.bindingType,
            ),
          );
        }
      }
    }

    // 触摸区域：覆盖屏幕左侧 45%，高度为下半部分
    final touchAreaWidth = viewportSize.width * 0.45;
    final touchAreaHeight = viewportSize.height * 0.75;
    final touchAreaTop = viewportSize.height * 0.25;

    return Stack(
      children: [
        // 大面积透明触摸区域（左侧）
        Positioned(
          left: 0,
          top: touchAreaTop,
          width: touchAreaWidth,
          height: touchAreaHeight,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanStart: (details) {
              final box =
                  context.findRenderObject() as RenderBox?;
              if (box == null) {
                return;
              }

              // 将本地坐标转换为整个Stack的坐标
              final globalPos = Offset(
                details.localPosition.dx,
                details.localPosition.dy + touchAreaTop,
              );

              active.value = true;
              touchCenter.value = globalPos;
              innerOffset.value = Offset.zero;
            },
            onPanUpdate: (details) {
              final globalPos = Offset(
                details.localPosition.dx,
                details.localPosition.dy + touchAreaTop,
              );
              updateFromGlobal(globalPos);
            },
            onPanEnd: (_) {
              active.value = false;
              touchCenter.value = null;
              innerOffset.value = Offset.zero;
              releaseAll();
            },
            onPanCancel: () {
              active.value = false;
              touchCenter.value = null;
              innerOffset.value = Offset.zero;
              releaseAll();
            },
            child: const SizedBox.expand(),
          ),
        ),
        // 摇杆视觉部分：外圈
        Positioned(
          left: joystickCenter.dx - radius,
          top: joystickCenter.dy - radius,
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: active.value ? 0.9 : 0.5,
              duration: const Duration(milliseconds: 150),
              child: Container(
                width: config.size,
                height: config.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: touchInputColorSecondary,
                  border: Border.all(
                    color: const Color(0x44ffffff),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ),
        // 摇杆视觉部分：内圈（可动）
        Positioned(
          left: joystickCenter.dx +
              innerOffset.value.dx -
              config.innerSize / 2,
          top: joystickCenter.dy +
              innerOffset.value.dy -
              config.innerSize / 2,
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: active.value ? 1.0 : 0.6,
              duration: const Duration(milliseconds: 150),
              child: Container(
                width: config.innerSize,
                height: config.innerSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active.value
                      ? touchInputColor
                      : touchInputColorActive,
                  border: Border.all(
                    color: const Color(0x66ffffff),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
