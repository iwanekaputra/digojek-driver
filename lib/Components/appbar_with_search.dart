import 'package:deliq_delivery/Components/search_bar.dart';
import 'package:flutter/material.dart';

class AppBarWithSearch extends StatelessWidget {
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final Function? onTap;
  final String? hint;
  final PreferredSizeWidget? bottom;

  const AppBarWithSearch({
    super.key,
    this.titleWidget,
    this.actions,
    this.leading,
    this.onTap,
    this.hint,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: true,
      titleSpacing: 0.0,
      leading: leading,
      title: titleWidget,
      actions: actions,
      bottom: bottom ??
          PreferredSize(
            preferredSize: const Size.fromHeight(0.0),
            child: CustomSearchBar(
              hint: hint,
              onTap: onTap,
            ),
          ),
    );
  }
}
