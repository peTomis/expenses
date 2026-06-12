import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/color_provider.dart';

class AppTextInput extends ConsumerStatefulWidget {
  const AppTextInput({
    required this.controller,
    required this.label,
    super.key,
    this.description,
    this.placeholder,
    this.errorText,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.textInputAction = TextInputAction.done,
    this.textCapitalization = TextCapitalization.sentences,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String? description;
  final String? placeholder;
  final String? errorText;
  final TextInputType keyboardType;
  final bool obscureText;
  final TextInputAction textInputAction;
  final TextCapitalization textCapitalization;
  final bool autocorrect;
  final bool enableSuggestions;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  ConsumerState<AppTextInput> createState() => _AppTextInputState();
}

class _AppTextInputState extends ConsumerState<AppTextInput> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = ref.watch(appPrimaryTextColorProvider);
    final inputBackground = ref
        .watch(appPrimary500ColorProvider)
        .withValues(alpha: 0.5);

    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InputLabel(label: widget.label, color: textColor),
        const SizedBox(height: 8),
        SizedBox(
          height: _inputHeight,
          child: CupertinoTextField(
            controller: widget.controller,
            focusNode: _focusNode,
            keyboardType: widget.keyboardType,
            obscureText: widget.obscureText,
            textInputAction: widget.textInputAction,
            textCapitalization: widget.textCapitalization,
            autocorrect: widget.autocorrect,
            enableSuggestions: widget.enableSuggestions,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            cursorColor: textColor,
            style: TextStyle(color: textColor, fontSize: 14),
            placeholder: widget.placeholder,
            placeholderStyle: TextStyle(
              color: textColor.withValues(alpha: 0.55),
              fontSize: 14,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: inputBackground,
              borderRadius: _inputBorderRadius,
              border: Border.all(
                color: _borderColor(
                  hasError: hasError,
                  hasFocus: _focusNode.hasFocus,
                  textColor: textColor,
                ),
              ),
            ),
          ),
        ),
        if (hasError || _hasDescription) ...[
          const SizedBox(height: 6),
          _InputHelperText(
            text: hasError ? widget.errorText! : widget.description!,
            color: hasError
                ? Colors.redAccent
                : textColor.withValues(alpha: 0.75),
          ),
        ],
      ],
    );
  }

  bool get _hasDescription =>
      widget.description != null && widget.description!.isNotEmpty;

  Color _borderColor({
    required bool hasError,
    required bool hasFocus,
    required Color textColor,
  }) {
    if (hasError) {
      return Colors.redAccent;
    }

    return hasFocus ? textColor : textColor.withValues(alpha: 0.45);
  }
}

const _inputBorderRadius = BorderRadius.all(Radius.circular(8));
const _inputHeight = 44.0;

class _InputLabel extends StatelessWidget {
  const _InputLabel({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color),
    );
  }
}

class _InputHelperText extends StatelessWidget {
  const _InputHelperText({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: TextStyle(fontSize: 12, color: color));
  }
}
