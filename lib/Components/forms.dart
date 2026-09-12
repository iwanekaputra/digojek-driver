import "package:flutter/material.dart";

class CustomFormField extends StatelessWidget {
  final String title;
  final bool obscureText;
  final TextEditingController? controller;

  const CustomFormField(
      {super.key,
      required this.title,
      this.obscureText = false,
      this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(
            height: 8,
          ),
          TextFormField(
            obscureText: obscureText,
            controller: controller,
            decoration: InputDecoration(
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 5)),
          )
        ],
      ),
    );
  }
}

class CustomFormDate extends StatelessWidget {
  final String title;
  final bool obscureText;
  final TextEditingController? controller;
  final VoidCallback? onTap;

  const CustomFormDate(
      {super.key,
      required this.title,
      this.onTap,
      this.obscureText = false,
      this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(
            height: 8,
          ),
          TextFormField(
            readOnly: true,
            onTap: onTap,
            obscureText: obscureText,
            controller: controller,
            decoration: InputDecoration(
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.all(5)),
          )
        ],
      ),
    );
  }
}
