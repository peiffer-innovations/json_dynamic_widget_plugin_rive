import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:json_dynamic_widget/json_dynamic_widget.dart';
import 'package:json_dynamic_widget_plugin_rive/json_dynamic_widget_plugin_rive.dart';
import 'package:logging/logging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
    if (record.error != null) {
      debugPrint('${record.error}');
    }
    if (record.stackTrace != null) {
      debugPrint('${record.stackTrace}');
    }
  });

  var navigatorKey = GlobalKey<NavigatorState>();

  var registry = JsonWidgetRegistry.instance;
  JsonRivePlugin.bind(registry);

  registry.navigatorKey = navigatorKey;

  var data = JsonWidgetData.fromDynamic(
    json.decode(await rootBundle.loadString('assets/pages/rives.json')),
  )!;

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DynamicWidgetPage(
        data: data,
      ),
      theme: ThemeData.light(),
    ),
  );
}

class DynamicWidgetPage extends StatelessWidget {
  DynamicWidgetPage({
    Key? key,
    required this.data,
  }) : super(key: key);

  final JsonWidgetData data;

  @override
  Widget build(BuildContext context) => data.build(context: context);
}
