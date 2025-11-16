import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum DeviceClass { phone, smallTablet, bigTablet, desktop }

class Responsive {
  /// Breakpoints (you chose: phones, small tablets, big tablets)
  static const double phoneMax = 599;
  static const double smallTabletMax = 1023;
  // >= 1024 considered bigTablet/desktop boundary (we treat bigTablet for now)

  static DeviceClass deviceClass(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w <= phoneMax) return DeviceClass.phone;
    if (w <= smallTabletMax) return DeviceClass.smallTablet;
    return DeviceClass.bigTablet;
  }

  static bool isPhone(BuildContext context) =>
      deviceClass(context) == DeviceClass.phone;
  static bool isSmallTablet(BuildContext context) =>
      deviceClass(context) == DeviceClass.smallTablet;
  static bool isBigTablet(BuildContext context) =>
      deviceClass(context) == DeviceClass.bigTablet;

  /// Quick helpers for proportional sizes using ScreenUtil
  static double sp(double size) => size.sp; // text
  static double wp(BuildContext context, double percent) =>
      MediaQuery.of(context).size.width * percent;
  static double hp(BuildContext context, double percent) =>
      MediaQuery.of(context).size.height * percent;

  /// Example: adaptive padding
  static EdgeInsets pagePadding(
    BuildContext context, {
    double phone = 12,
    double smallTablet = 20,
    double bigTablet = 28,
  }) {
    final cls = deviceClass(context);
    final val = cls == DeviceClass.phone
        ? phone
        : cls == DeviceClass.smallTablet
        ? smallTablet
        : bigTablet;
    return EdgeInsets.all(val.w);
  }

  /// Use for headline sizes (you can adapt weights)
  static double headlineSize(BuildContext context) {
    final cls = deviceClass(context);
    switch (cls) {
      case DeviceClass.phone:
        return 18.sp;
      case DeviceClass.smallTablet:
        return 22.sp;
      case DeviceClass.bigTablet:
        return 26.sp;
      default:
        return 18.sp;
    }
  }

  static double bodySize(BuildContext context) {
    final cls = deviceClass(context);
    switch (cls) {
      case DeviceClass.phone:
        return 14.sp;
      case DeviceClass.smallTablet:
        return 16.sp;
      case DeviceClass.bigTablet:
        return 18.sp;
      default:
        return 14.sp;
    }
  }
}
