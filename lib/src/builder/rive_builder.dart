import 'dart:convert';

import 'package:json_dynamic_widget/json_dynamic_widget.dart';
import 'package:rive/rive.dart';

part 'rive_builder.g.dart';

/// Creates a [Rive] widget.
@jsonWidget
abstract class _RiveBuilder extends JsonWidgetBuilder {
  const _RiveBuilder({
    super.args,
  });

  @override
  _Rive buildCustom({
    ChildWidgetBuilder? childBuilder,
    required BuildContext context,
    required JsonWidgetData data,
    Key? key,
  });
}

class _Rive extends StatelessWidget {
  const _Rive({
    required this.alignment,
    required this.animations,
    required this.antialiasing,
    required this.artboard,
    required this.asset,
    @JsonBuildArg() this.childBuilder,
    required this.fit,
    required this.package,
    required this.placeholder,
    required this.rive,
    required this.stateMachines,
    required this.url,
  })  : assert((asset == null && url == null) ||
            (asset == null && rive == null) ||
            (rive == null && url == null)),
        assert(asset != null || rive != null || url != null);

  final Alignment? alignment;
  final List<String>? animations;
  final bool? antialiasing;
  final String? artboard;
  final String? asset;
  final ChildWidgetBuilder? childBuilder;
  final BoxFit? fit;
  final String? package;
  final JsonWidgetData? placeholder;
  final List<String>? stateMachines;
  final String? rive;
  final String? url;

  /// Builds the widget from the give [data].
  @override
  Widget build(BuildContext context) {
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
  const _RiveMemoryWidget({
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

    final file = RiveFile.import(
      ByteData.sublistView(base64.decode(widget.rive)),
    );

    if (widget.artboard == null) {
      _artboard = file.mainArtboard;
    } else {
      _artboard = file.artboardByName(widget.artboard!)!;
    }

    if (widget.animations?.isNotEmpty == true) {
      for (var name in widget.animations!) {
        final controller = SimpleAnimation(name);
        _artboard.addController(controller);
        _animations.add(controller);
      }
    } else {
      final controller = SimpleAnimation(_artboard.animations.first.name);
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
