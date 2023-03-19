import 'package:json_dynamic_widget/json_dynamic_widget_schemas.dart';
import 'package:json_theme/json_theme_schemas.dart';

class RiveSchema {
  static const id =
      'https://peiffer-innovations.github.io/flutter_json_schemas/schemas/json_dynamic_widget_plugin_rive/rive.json';

  static final schema = {
    r'$schema': 'http://json-schema.org/draft-06/schema#',
    r'$children': 0,
    r'$id': '$id',
    'title': 'Rive',
    'type': 'object',
    'additionalProperties': false,
    'properties': {
      'alignment': SchemaHelper.objectSchema(AlignmentSchema.id),
      'animations': {
        'type': 'string',
      },
      'antialiasing': SchemaHelper.boolSchema,
      'artboard': SchemaHelper.stringSchema,
      'asset': SchemaHelper.stringSchema,
      'fit': SchemaHelper.objectSchema(BoxFitSchema.id),
      'package': SchemaHelper.stringSchema,
      'placeholder': SchemaHelper.objectSchema(JsonWidgetDataSchema.id),
      'stateMachines': {
        'type': 'string',
      },
      'rive': SchemaHelper.stringSchema,
      'url': SchemaHelper.stringSchema,
    },
  };
}
