import 'dart:ffi';

import 'package:deliq_delivery/Themes/colors.dart';
import 'package:deliq_delivery/Themes/style.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BottomBar extends StatelessWidget {
  final Function onTap;
  final String? text;
  final Color? color;
  final Color? textColor;
  final double height;
  final double? width;

  const BottomBar(
      {super.key,
      required this.onTap,
      required this.text,
      this.color,
      this.textColor,
      this.height = 60.0,
      this.width});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap as void Function()?,
      child: Container(
        color: color ?? kMainColor,
        height: height,
        width: width ?? double.maxFinite,
        child: Center(
          child: Text(
            text!,
            style: textColor != null
                ? bottomBarTextStyle.copyWith(color: textColor)
                : bottomBarTextStyle,
          ),
        ),
      ),
    );
  }
}
