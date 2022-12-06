import 'package:json_dynamic_widget/json_dynamic_widget.dart';
import 'package:json_dynamic_widget_plugin_rive/json_dynamic_widget_plugin_rive.dart';
import 'package:json_theme/json_theme_schemas.dart';

class JsonRivePlugin {
  static void bind(JsonWidgetRegistry registry) {
    final schemaCache = SchemaCache();
    schemaCache.addSchema(RiveSchema.id, RiveSchema.schema);

    registry.registerCustomBuilder(
      RiveBuilder.type,
      const JsonWidgetBuilderContainer(
        builder: RiveBuilder.fromDynamic,
        schemaId: RiveSchema.id,
      ),
    );
  }
}
