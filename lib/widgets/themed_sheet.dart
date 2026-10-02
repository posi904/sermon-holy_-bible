import 'package:flutter/material.dart';

import '../core/theme/reader_theme.dart';

/// A modal bottom sheet whose surface colour is looked up while building, so
/// it follows the reading theme even if the theme is switched while it is open.
Future<T?> showThemedSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: isScrollControlled,
    builder: (BuildContext sheetContext) => Material(
      color: Palette.c(0xFFEDE3D0),
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: builder(sheetContext),
    ),
  );
}
