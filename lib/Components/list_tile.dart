import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:flutter/material.dart';

class BuildListTile extends StatelessWidget {
  final String? image;
  final String? text;
  final Function? onTap;

  const BuildListTile({super.key, this.image, this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(vertical: 4.0, horizontal: 20.0),
      leading: FadedScaleAnimation(
        fadeDuration: const Duration(milliseconds: 400),
        scaleDuration: const Duration(milliseconds: 400),
        child: Image.asset(
          image!,
          height: 25.3,
          width: 25.3,
        ),
      ),
      title: Text(
        text!,
        style: Theme.of(context)
            .textTheme
            .headlineMedium!
            .copyWith(fontWeight: FontWeight.w500),
      ),
      onTap: onTap as void Function()?,
    );
  }
}
