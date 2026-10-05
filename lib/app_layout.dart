import 'package:flutter/widgets.dart';

double mobileInset(BuildContext context) =>
    (MediaQuery.sizeOf(context).width * .06).clamp(16.0, 28.0);
