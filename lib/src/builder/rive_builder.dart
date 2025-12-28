import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:json_dynamic_widget/json_dynamic_widget.dart';
import 'package:rive/rive.dart' as rive;

part 'rive_builder.g.dart';

/// Creates a Rive animation widget.
///
/// Updated for Rive 0.14.0 which uses the new C++ runtime (rive_native).
///
/// ## Breaking changes from 0.13.x:
/// - `fit` now uses `rive.Fit` instead of `BoxFit`
/// - Uses `RiveWidgetBuilder` / `RiveWidget` instead of removed `RiveAnimation`
/// - File loading via `File.asset()` / `File.decode()` instead of `RiveFile.import()`
/// - Artboard/StateMachine selection uses selector classes
/// - Must call `RiveNative.init()` before using Rive
///
/// ## Supported sources:
/// - `asset` - Load from Flutter assets
/// - `url` - Load from network URL
/// - `rive` - Load from base64-encoded rive data
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

class _Rive extends StatefulWidget {
  const _Rive({
    this.alignment = Alignment.center,
    this.animations,
    this.artboard,
    this.asset,
    @JsonBuildArg() this.childBuilder,
    this.fit = rive.Fit.contain,
    super.key,
    this.layoutScaleFactor = 1.0,
    this.package,
    this.placeholder,
    this.rive,
    this.stateMachines,
    this.url,
    this.useRiveRenderer = true,
  })  : assert((asset == null && url == null) ||
            (asset == null && rive == null) ||
            (rive == null && url == null)),
        assert(asset != null || rive != null || url != null);

  final Alignment alignment;
  final List<String>? animations;
  final String? artboard;
  final String? asset;
  final ChildWidgetBuilder? childBuilder;
  final rive.Fit fit;
  final double layoutScaleFactor;
  final String? package;
  final JsonWidgetData? placeholder;
  final List<String>? stateMachines;

  /// Base64-encoded rive file data
  final String? rive;
  final String? url;

  /// Whether to use Rive's native renderer (true) or Flutter's Skia/Impeller (false)
  final bool useRiveRenderer;

  @override
  State<_Rive> createState() => _RiveState();
}

class _RiveState extends State<_Rive> {
  // For asset/url sources - use FileLoader with RiveWidgetBuilder
  rive.FileLoader? _fileLoader;

  // For base64 rive data - manual loading
  rive.File? _riveFile;
  rive.RiveWidgetController? _controller;
  bool _isLoading = true;
  String? _error;

  bool get _isBase64Source => widget.rive != null;

  rive.Factory get _factory =>
      widget.useRiveRenderer ? rive.Factory.rive : rive.Factory.flutter;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(covariant _Rive oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset != widget.asset ||
        oldWidget.url != widget.url ||
        oldWidget.rive != widget.rive ||
        oldWidget.artboard != widget.artboard) {
      _dispose();
      _init();
    }
  }

  void _init() {
    if (_isBase64Source) {
      _loadBase64Rive();
    } else {
      _initFileLoader();
    }
  }

  void _initFileLoader() {
    if (widget.asset != null) {
      final assetPath = widget.package == null
          ? widget.asset!
          : 'packages/${widget.package}/${widget.asset}';
      _fileLoader = rive.FileLoader.fromAsset(
        assetPath,
        riveFactory: () => _factory,
      );
    } else if (widget.url != null) {
      _fileLoader = rive.FileLoader.fromUrl(
        widget.url!,
        riveFactory: () => _factory,
      );
    }
    setState(() {});
  }

  Future<void> _loadBase64Rive() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final bytes = base64.decode(widget.rive!);

      // Decode the rive file from bytes
      _riveFile = await rive.File.decode(
        Uint8List.fromList(bytes),
        factory: _factory,
      );

      // Create controller with artboard and state machine selectors
      _controller = rive.RiveWidgetController(
        _riveFile!,
        artboardSelector: _artboardSelector,
        stateMachineSelector: _stateMachineSelector,
      );

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  rive.ArtboardSelector get _artboardSelector {
    if (widget.artboard != null) {
      return rive.ArtboardSelector.byName(widget.artboard!);
    }
    return const rive.ArtboardSelector.byDefault();
  }

  rive.StateMachineSelector get _stateMachineSelector {
    if (widget.stateMachines != null && widget.stateMachines!.isNotEmpty) {
      return rive.StateMachineSelector.byName(widget.stateMachines!.first);
    }
    if (widget.animations != null && widget.animations!.isNotEmpty) {
      return const rive.StateMachineSelector.none();
    }
    return const rive.StateMachineSelector.byDefault();
  }

  void _dispose() {
    _fileLoader?.dispose();
    _fileLoader = null;
    _controller?.dispose();
    _controller = null;
    _riveFile?.dispose();
    _riveFile = null;
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Handle base64 source separately (no FileLoader)
    if (_isBase64Source) {
      return _buildBase64Widget(context);
    }

    // Handle asset/url sources with RiveWidgetBuilder
    return _buildFileLoaderWidget(context);
  }

  Widget _buildBase64Widget(BuildContext context) {
    if (_isLoading) {
      return _buildPlaceholder(context);
    }

    if (_error != null || _controller == null) {
      return _buildError(_error ?? 'Failed to load Rive animation');
    }

    return rive.RiveWidget(
      controller: _controller!,
      fit: widget.fit,
      alignment: widget.alignment,
      layoutScaleFactor: widget.layoutScaleFactor,
    );
  }

  Widget _buildFileLoaderWidget(BuildContext context) {
    if (_fileLoader == null) {
      return _buildPlaceholder(context);
    }

    return rive.RiveWidgetBuilder(
      fileLoader: _fileLoader!,
      artboardSelector: _artboardSelector,
      stateMachineSelector: _stateMachineSelector,
      builder: (context, state) {
        return switch (state) {
          rive.RiveLoading() => _buildPlaceholder(context),
          rive.RiveLoaded(:final controller) => rive.RiveWidget(
              controller: controller,
              fit: widget.fit,
              alignment: widget.alignment,
              layoutScaleFactor: widget.layoutScaleFactor,
            ),
          rive.RiveFailed(:final error) => _buildError(error.toString()),
        };
      },
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return widget.placeholder?.build(
          childBuilder: widget.childBuilder,
          context: context,
        ) ??
        const Center(child: CircularProgressIndicator());
  }

  Widget _buildError(String error) {
    return Center(
      child: Text(
        'Rive Error: $error',
        style: const TextStyle(color: Colors.red, fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }
}
