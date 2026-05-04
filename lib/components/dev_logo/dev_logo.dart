import 'package:expenses/providers/color_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

class DevLogo extends ConsumerWidget {
  const DevLogo({super.key});

  static final _petomisUri = Uri.https('www.petomis.com');

  Future<void> _openPetomis() async {
    await launchUrl(_petomisUri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brandColor = ref.watch(appPrimary300ColorProvider);

    return Row(
      children: [
        const Expanded(child: SizedBox.shrink()),
        _PetomisLogoButton(color: brandColor, onTap: _openPetomis),
        Expanded(child: _DevLogoLine(color: brandColor)),
      ],
    );
  }
}

class _PetomisLogoButton extends StatelessWidget {
  const _PetomisLogoButton({required this.color, required this.onTap});

  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Petomis',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 32,
            height: 32,
            child: SvgPicture.asset(
              'assets/icons/pe_logo.svg',
              width: 32,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
          ),
        ),
      ),
    );
  }
}

class _DevLogoLine extends StatelessWidget {
  const _DevLogoLine({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 11),
        Container(height: 3.5, color: color),
        const SizedBox(height: 10.5),
      ],
    );
  }
}
