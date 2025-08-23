import 'package:flutter/material.dart';

class ARControls extends StatelessWidget {
  final VoidCallback onInfo;
  final VoidCallback onGrab;
  final VoidCallback onMenu;
  const ARControls({required this.onInfo, required this.onGrab, required this.onMenu, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _circleIcon(context, Icons.info_outlined, onInfo, tooltip: 'Información'),
        const SizedBox(width: 32),
        _circleIcon(context, Icons.camera_alt_outlined, onGrab, tooltip: 'Capturar'),
        const SizedBox(width: 32),
        _circleIcon(context, Icons.menu, onMenu, tooltip: 'Menú'),
      ],
    );
  }

  Widget _circleIcon(BuildContext context, IconData icon, VoidCallback onTap, {String? tooltip}) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: IconButton(
        icon: Icon(icon, size: 28),
        onPressed: onTap,
        tooltip: tooltip,
        splashRadius: 28,
      ),
    );
  }
}
