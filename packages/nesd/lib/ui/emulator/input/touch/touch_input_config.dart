import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nesd/ui/emulator/input/input_action.dart';
import 'package:nesd/ui/settings/controls/binding.dart';

part 'touch_input_config.freezed.dart';
part 'touch_input_config.g.dart';

enum TouchInputType {
  rectangleButton(),
  circleButton(),
  joyStick(),
  dPad();

  static TouchInputType forTouchInputConfig(TouchInputConfig config) {
    return switch (config) {
      RectangleButtonConfig() => rectangleButton,
      CircleButtonConfig() => circleButton,
      JoyStickConfig() => joyStick,
      DPadConfig() => dPad,
    };
  }
}

@Freezed(unionKey: 'type')
sealed class TouchInputConfig with _$TouchInputConfig {
  const TouchInputConfig._();

  const factory TouchInputConfig.rectangleButton({
    required double x,
    required double y,
    @Default(BindingType.hold) BindingType bindingType,
    @JsonKey(fromJson: InputAction.fromCode, toJson: InputAction.toJson)
    InputAction? action,
    @Default(60) double width,
    @Default(60) double height,
    @Default('') String label,
  }) = RectangleButtonConfig;

  const factory TouchInputConfig.circleButton({
    required double x,
    required double y,
    @Default(BindingType.hold) BindingType bindingType,
    @JsonKey(fromJson: InputAction.fromCode, toJson: InputAction.toJson)
    InputAction? action,
    @Default(75) double size,
    @Default('') String label,
  }) = CircleButtonConfig;

  const factory TouchInputConfig.joyStick({
    required double x,
    required double y,
    @Default(BindingType.hold) BindingType bindingType,
    @JsonKey(fromJson: InputAction.fromCode, toJson: InputAction.toJson)
    InputAction? upAction,
    @JsonKey(fromJson: InputAction.fromCode, toJson: InputAction.toJson)
    InputAction? downAction,
    @JsonKey(fromJson: InputAction.fromCode, toJson: InputAction.toJson)
    InputAction? leftAction,
    @JsonKey(fromJson: InputAction.fromCode, toJson: InputAction.toJson)
    InputAction? rightAction,
    @Default(150) double size,
    @Default(60) double innerSize,
    @Default(0.25) double deadZone,
  }) = JoyStickConfig;

  const factory TouchInputConfig.dPad({
    required double x,
    required double y,
    @Default(BindingType.hold) BindingType bindingType,
    @JsonKey(fromJson: InputAction.fromCode, toJson: InputAction.toJson)
    InputAction? upAction,
    @JsonKey(fromJson: InputAction.fromCode, toJson: InputAction.toJson)
    InputAction? downAction,
    @JsonKey(fromJson: InputAction.fromCode, toJson: InputAction.toJson)
    InputAction? leftAction,
    @JsonKey(fromJson: InputAction.fromCode, toJson: InputAction.toJson)
    InputAction? rightAction,
    @Default(150) double size,
    @Default(0.25) double deadZone,
  }) = DPadConfig;

  Offset center(Size viewport) {
    final center = viewport.center(Offset.zero);
    final relative = Offset(x * center.dx, y * center.dy);

    return center + relative;
  }

  Rect boundingBox(Size viewport) =>
      Rect.fromCenter(center: center(viewport), width: width, height: height);

  double get height => switch (this) {
    RectangleButtonConfig(height: final height) => height,
    CircleButtonConfig(size: final size) => size,
    JoyStickConfig(size: final size) => size,
    DPadConfig(size: final size) => size,
  };

  double get width => switch (this) {
    RectangleButtonConfig(width: final width) => width,
    CircleButtonConfig(size: final size) => size,
    JoyStickConfig(size: final size) => size,
    DPadConfig(size: final size) => size,
  };

  factory TouchInputConfig.fromJson(Map<String, dynamic> json) =>
      _$TouchInputConfigFromJson(json);
}

const defaultPortraitConfig = [
  DPadConfig(
    x: -0.6,
    y: 0.55,
    upAction: controller1Up,
    downAction: controller1Down,
    leftAction: controller1Left,
    rightAction: controller1Right,
  ),
  // 右下方扇形功能键：A 主键，B 左侧，X=A+B 组合（跳跃/旋风腿）在上，Y 连发在右。
  CircleButtonConfig(x: 0.72, y: 0.55, action: controller1A, label: 'A'),
  CircleButtonConfig(x: 0.32, y: 0.55, action: controller1B, label: 'B'),
  CircleButtonConfig(
    x: 0.52,
    y: 0.32,
    action: controller1X,
    label: 'X',
    size: 65,
  ),
  CircleButtonConfig(
    x: 0.92,
    y: 0.32,
    action: controller1Y,
    label: 'Y',
    size: 65,
  ),
  RectangleButtonConfig(
    height: 36,
    x: -0.2,
    y: -0.7,
    action: controller1Select,
    label: 'Select',
  ),
  RectangleButtonConfig(
    height: 36,
    x: 0.2,
    y: -0.7,
    action: controller1Start,
    label: 'Start',
  ),
];

const defaultLandscapeConfig = [
  // 摇杆默认左下方（王者荣耀式布局）。
  JoyStickConfig(
    x: -0.7,
    y: 0.5,
    size: 160,
    innerSize: 65,
    upAction: controller1Up,
    downAction: controller1Down,
    leftAction: controller1Left,
    rightAction: controller1Right,
  ),
  // 右下方扇形功能键钻石布局：
  //   Y(连发) 左 — X(A+B 组合，跳跃/旋风腿) 上 — A 右 — B 下
  CircleButtonConfig(
    x: 0.86,
    y: 0.45,
    action: controller1A,
    label: 'A',
    size: 85,
  ),
  CircleButtonConfig(
    x: 0.68,
    y: 0.68,
    action: controller1B,
    label: 'B',
    size: 80,
  ),
  CircleButtonConfig(x: 0.68, y: 0.22, action: controller1X, label: 'X'),
  CircleButtonConfig(x: 0.5, y: 0.45, action: controller1Y, label: 'Y'),
  RectangleButtonConfig(
    height: 35,
    width: 70,
    x: -0.15,
    y: -0.7,
    action: controller1Select,
    label: 'Select',
  ),
  RectangleButtonConfig(
    height: 35,
    width: 70,
    x: 0.15,
    y: -0.7,
    action: controller1Start,
    label: 'Start',
  ),
];
