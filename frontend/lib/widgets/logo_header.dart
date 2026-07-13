import 'package:flutter/material.dart';

class LogoHeader extends StatelessWidget {
  final double height;
  const LogoHeader({super.key, this.height = 32.0});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/images/logo_infra.png', height: height * 1.5, fit: BoxFit.contain),
        const SizedBox(width: 16),
        Container(width: 1, height: height * 0.8, color: Colors.grey.shade300),
        const SizedBox(width: 16),
        Image.asset('assets/images/logo_metals.png', height: height * 1.2, fit: BoxFit.contain),
      ],
    );
  }
}
