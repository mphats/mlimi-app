import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_colors.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final void Function()? onTap;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final EdgeInsetsGeometry? contentPadding;
  final Color? fillColor;
  final Color? borderColor;
  final double? borderRadius;

  const CustomTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.focusNode,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.contentPadding,
    this.fillColor,
    this.borderColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          maxLines: obscureText ? 1 : maxLines,
          minLines: minLines,
          maxLength: maxLength,
          enabled: enabled,
          readOnly: readOnly,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          onTap: onTap,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: enabled ? AppColors.textPrimary : AppColors.textDisabled,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: hint,
            helperText: helperText,
            errorText: errorText,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: AppColors.textSecondary, size: 22)
                : null,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor:
                fillColor ??
                (enabled
                    ? AppColors.inputBackground
                    : AppColors.backgroundDark),
            contentPadding:
                contentPadding ??
                const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 12),
              borderSide: BorderSide(
                color: borderColor ?? AppColors.inputBorder,
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 12),
              borderSide: BorderSide(
                color: borderColor ?? AppColors.inputBorder,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 12),
              borderSide: BorderSide(
                color: AppColors.inputBorderFocused,
                width: 2.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 12),
              borderSide: BorderSide(
                color: AppColors.inputBorderError,
                width: 2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 12),
              borderSide: BorderSide(
                color: AppColors.inputBorderError,
                width: 2.5,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 12),
              borderSide: BorderSide(
                color: AppColors.border.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            hintStyle: TextStyle(
              color: AppColors.textHint, 
              fontSize: 16,
            ),
            helperStyle: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
            errorStyle: TextStyle(
              color: AppColors.error, 
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            counterStyle: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class CustomSearchField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hint;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final void Function()? onClear;
  final bool enabled;
  final FocusNode? focusNode;

  const CustomSearchField({
    super.key,
    this.controller,
    this.hint,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.enabled = true,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontSize: 16,
      ),
      decoration: InputDecoration(
        hintText: hint ?? 'Search...',
        prefixIcon: const Icon(
          Icons.search,
          color: AppColors.textSecondary,
          size: 22,
        ),
        suffixIcon: controller?.text.isNotEmpty == true
            ? IconButton(
                icon: const Icon(
                  Icons.clear,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
                onPressed: () {
                  controller?.clear();
                  onClear?.call();
                },
              )
            : null,
        filled: true,
        fillColor: AppColors.inputBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(
            color: AppColors.inputBorder, 
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(
            color: AppColors.inputBorder, 
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(
            color: AppColors.inputBorderFocused,
            width: 2.5,
          ),
        ),
        hintStyle: const TextStyle(
          color: AppColors.textHint, 
          fontSize: 16,
        ),
      ),
    );
  }
}

class CustomDropdownField<T> extends StatelessWidget {
  final T? value;
  final List<T> items;
  final String? label;
  final String? hint;
  final String Function(T) itemBuilder;
  final void Function(T?) onChanged;
  final String? Function(T?)? validator;
  final IconData? prefixIcon;
  final bool enabled;

  const CustomDropdownField({
    super.key,
    required this.value,
    required this.items,
    required this.itemBuilder,
    required this.onChanged,
    this.label,
    this.hint,
    this.validator,
    this.prefixIcon,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        DropdownButtonFormField<T>(
          initialValue: value,
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    itemBuilder(item),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 16,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: enabled ? onChanged : null,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: AppColors.textSecondary, size: 22)
                : null,
            filled: true,
            fillColor: enabled
                ? AppColors.inputBackground
                : AppColors.backgroundDark,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.inputBorder,
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.inputBorder,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.inputBorderFocused,
                width: 2.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.inputBorderError,
                width: 2,
              ),
            ),
            hintStyle: const TextStyle(
              color: AppColors.textHint, 
              fontSize: 16,
            ),
          ),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: enabled ? AppColors.textPrimary : AppColors.textDisabled,
            fontSize: 16,
          ),
          dropdownColor: AppColors.surface,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.textSecondary,
            size: 24,
          ),
        ),
      ],
    );
  }
}
