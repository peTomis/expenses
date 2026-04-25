import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

class DevLogo extends StatelessWidget {
  const DevLogo({super.key});

  static final _petomisUri = Uri.https('www.petomis.com');

  Future<void> _openPetomis() async {
    await launchUrl(_petomisUri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: SizedBox.shrink()),
        Tooltip(
          message: 'Petomis',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _openPetomis,
            child: SvgPicture.asset(
              'assets/icons/pe_logo.svg',
              width: 32,
              colorFilter: const ColorFilter.mode(
                Colors.black,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Container(height: 11),
              Container(height: 3.5, color: Colors.black),
              Container(height: 10.5),
            ],
          ),
        ),
      ],
    );
  }
}
