import 'package:flutter/material.dart';

class ImjangAppBar extends AppBar {
  ImjangAppBar({
    super.key,
    required String title,
    bool showBackButton = false,
    List<Widget>? actions,
  }) : super(
          title: Text(title),
          leading: showBackButton
              ? Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                )
              : null,
          automaticallyImplyLeading: false,
          actions: actions,
        );
}
