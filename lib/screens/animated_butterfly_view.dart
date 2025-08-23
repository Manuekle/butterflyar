import 'package:flutter/material.dart';
import 'ar_experience_screen.dart';
import 'butterfly_static_screen.dart';
import 'package:butterfliesar/models/butterfly.dart';
import 'package:butterfliesar/utils/ar_helpers.dart' show SimpleARSupport, ARPlatformSupport;
import 'package:vibration/vibration.dart';
import 'package:butterfliesar/widgets/animated_toast.dart';
import 'package:butterfliesar/widgets/safe_model_viewer.dart';

/// Widget que alterna suavemente entre AR y modo estático con fade+slide.
class AnimatedButterflyView extends StatefulWidget {
  final Butterfly butterfly;
  final bool initialAR;

  const AnimatedButterflyView({
    required this.butterfly,
    super.key,
    this.initialAR = true,
  });

  @override
  State<AnimatedButterflyView> createState() => _AnimatedButterflyViewState();
}

class _AnimatedButterflyViewState extends State<AnimatedButterflyView> {
  bool _showAR = true;
  bool _arSupported = true;
  bool _checkedAR = false;
  String? _toast;

  @override
  void initState() {
    super.initState();
    _showAR = widget.initialAR;
    _checkARSupport();
  }

  Future<void> _checkARSupport() async {
    try {
      final support = await SimpleARSupport.detectARSupport();
      setState(() {
        _arSupported = support != ARPlatformSupport.none;
        _checkedAR = true;
        if (!_arSupported) _showAR = false;
      });
    } catch (e) {
      debugPrint('Error checking AR support: $e');
      setState(() {
        _arSupported = false;
        _checkedAR = true;
        _showAR = false;
      });
    }
  }

  Future<void> _toggleMode() async {
    setState(() => _showAR = !_showAR);
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(duration: 30, amplitude: 60);
    }
    setState(() {
      _toast = _showAR ? '¡Modo AR activado!' : 'Vista fondo activada';
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  void _open3DViewer() {
    // Verificar si la mariposa tiene modelo 3D
    final modelPath = widget.butterfly.modelAsset ?? 'assets/models/test.glb';
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SafeModelViewer(
          modelAssetPath: modelPath,
          title: '3D ${widget.butterfly.name}',
          autoRotate: true,
          cameraControls: true,
          backgroundColor: const Color(0xFF1a1a2e),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_checkedAR) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            transitionBuilder: (child, animation) {
              final offset = Tween<Offset>(
                begin: _showAR ? const Offset(0.08, 0) : const Offset(-0.08, 0),
                end: Offset.zero,
              ).animate(animation);
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: offset, child: child),
              );
            },
            child: _showAR
                ? ARExperienceScreen(
                    key: ValueKey(
                      'ar-view',
                    ), // Añadimos una clave para ayudar a Flutter a diferenciar los widgets
                    butterfly: widget.butterfly,
                  )
                : ButterflyStaticScreen(
                    key: ValueKey('static-view'),
                    butterfly: widget.butterfly,
                    canSwitchToAR: _arSupported,
                    onSwitchToAR: _arSupported ? _toggleMode : null,
                  ),
          ),
          if (_toast != null) AnimatedToast(message: _toast!),
        ],
      ),
      // Botón flotante para visualizador 3D
      floatingActionButton: FloatingActionButton(
        onPressed: _open3DViewer,
        backgroundColor: Colors.deepPurple,
        child: const Icon(
          Icons.view_in_ar,
          color: Colors.white,
        ),
        heroTag: "3d_viewer_fab",
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
    );
  }
}
