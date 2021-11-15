import 'dart:convert';
import 'dart:typed_data';

import 'package:child_builder/child_builder.dart';
import 'package:flutter/material.dart';
import 'package:json_class/json_class.dart';
import 'package:json_dynamic_widget/json_dynamic_widget.dart';
import 'package:json_theme/json_theme.dart';
import 'package:rive/rive.dart';

/// Creates a [Rive] widget.
class RiveBuilder extends JsonWidgetBuilder {
  RiveBuilder({
    required this.alignment,
    required this.animations,
    required this.antialiasing,
    required this.artboard,
    required this.asset,
    required this.fit,
    required this.package,
    required this.placeholder,
    required this.rive,
    required this.stateMachines,
    required this.url,
  })  : assert((asset == null && url == null) ||
            (asset == null && rive == null) ||
            (rive == null && url == null)),
        assert(asset != null || rive != null || url != null),
        super(numSupportedChildren: kNumSupportedChildren);

  static const kNumSupportedChildren = 0;
  static const type = 'rive';

  final Alignment? alignment;
  final List<String>? animations;
  final bool? antialiasing;
  final String? artboard;
  final String? asset;
  final BoxFit? fit;
  final String? package;
  final JsonWidgetData? placeholder;
  final List<String>? stateMachines;
  final String? rive;
  final String? url;

  /// Builds the builder from a Map-like dynamic structure.  This expects the
  /// JSON format to be of the following structure:
  ///
  /// ```json
  /// {
  ///   "alignment": <AlignmentGeometry>,
  ///   "animations": <List<String>>,
  ///   "antialiasing": <bool>,
  ///   "artboard": <String>,
  ///   "asset": <String>,
  ///   "fit": <BoxFit>,
  ///   "package": <String>,
  ///   "placeholder": <JsonWidgetData>,
  ///   "stateMachines": <List<String>>,
  ///   "rive": <String>,
  ///   "url": <String>
  /// }
  /// ```
  ///
  /// See also:
  ///  * [ThemeDecoder.decodeAlignment]
  ///  * [ThemeDecoder.decodeBoxFit]
  static RiveBuilder fromDynamic(
    dynamic map, {
    JsonWidgetRegistry? registry,
  }) {
    if (map == null) {
      throw Exception('[RiveBuilder]: map is null');
    }

    return RiveBuilder(
      alignment: ThemeDecoder.decodeAlignment(
        map['alignment'],
        validate: false,
      ),
      animations: map['animations'] == null
          ? null
          : List<String>.from(map['animations']),
      artboard: map['artboard'],
      antialiasing: map['antialiasing'] == null
          ? null
          : JsonClass.parseBool(map['antialiasing']),
      asset: map['asset'],
      fit: ThemeDecoder.decodeBoxFit(
        map['fit'],
        validate: false,
      ),
      package: map['package'],
      placeholder: JsonWidgetData.fromDynamic(map['placeholder']),
      rive: map['rive'],
      stateMachines: map['stateMachines'] == null
          ? null
          : List<String>.from(map['stateMachines']),
      url: map['url'],
    );
  }

  /// Builds the widget from the give [data].
  @override
  Widget buildCustom({
    ChildWidgetBuilder? childBuilder,
    required BuildContext context,
    required JsonWidgetData data,
    Key? key,
  }) {
    assert(
      data.children?.isNotEmpty != true,
      '[RiveBuilder] does not support children.',
    );

    return asset != null
        ? RiveAnimation.asset(
            package == null ? asset! : 'packages/$package/$asset',
            alignment: alignment ?? Alignment.center,
            antialiasing: antialiasing ?? true,
            artboard: artboard,
            fit: fit,
            placeHolder: placeholder?.build(
              childBuilder: childBuilder,
              context: context,
            ),
          )
        : rive != null
            ? _RiveMemoryWidget(
                artboard: artboard,
                alignment: alignment ?? Alignment.center,
                animations: animations,
                antialiasing: antialiasing ?? true,
                fit: fit,
                rive: rive!,
              )
            : RiveAnimation.network(
                url!,
                alignment: alignment ?? Alignment.center,
                animations: animations ?? const <String>[],
                antialiasing: antialiasing ?? true,
                artboard: artboard,
                fit: fit,
                placeHolder: placeholder?.build(
                  childBuilder: childBuilder,
                  context: context,
                ),
                stateMachines: stateMachines ?? const <String>[],
              );
  }
}

class _RiveMemoryWidget extends StatefulWidget {
  _RiveMemoryWidget({
    required this.alignment,
    required this.artboard,
    required this.animations,
    required this.antialiasing,
    required this.fit,
    Key? key,
    required this.rive,
  }) : super(key: key);

  final Alignment? alignment;
  final String? artboard;
  final List<String>? animations;
  final bool? antialiasing;
  final BoxFit? fit;
  final String rive;

  @override
  _RiveMemoryWidgetState createState() => _RiveMemoryWidgetState();
}

class _RiveMemoryWidgetState extends State<_RiveMemoryWidget> {
  final List<RiveAnimationController> _animations = [];

  late Artboard _artboard;

  @override
  void initState() {
    super.initState();

    var file = RiveFile.import(
      ByteData.sublistView(base64.decode(widget.rive)),
    );

    if (widget.artboard == null) {
      _artboard = file.mainArtboard;
    } else {
      _artboard = file.artboardByName(widget.artboard!)!;
    }

    if (widget.animations?.isNotEmpty == true) {
      for (var name in widget.animations!) {
        var controller = SimpleAnimation(name);
        _artboard.addController(controller);
        _animations.add(controller);
      }
    } else {
      var controller = SimpleAnimation(_artboard.animations.first.name);
      _artboard.addController(controller);
      _animations.add(controller);
    }
  }

  @override
  void dispose() {
    super.dispose();

    for (var controller in _animations) {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) => Rive(
        artboard: _artboard,
        alignment: widget.alignment,
        antialiasing: widget.antialiasing ?? true,
        fit: widget.fit,
      );
}
