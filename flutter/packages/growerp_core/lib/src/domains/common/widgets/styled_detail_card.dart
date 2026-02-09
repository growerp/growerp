/*
 * This software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 * 
 * To the extent possible under law, the author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 * 
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */

import 'dart:typed_data';
import 'package:flutter/material.dart';

/// A styled detail card widget following the Stitch design system.
/// Used for displaying grouped information in user/company detail views.
class StyledDetailCard extends StatelessWidget {
  final String title;
  final IconData? titleIcon;
  final Widget child;
  final List<Widget>? actions;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  const StyledDetailCard({
    super.key,
    required this.title,
    required this.child,
    this.titleIcon,
    this.actions,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.6)
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with title and actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                if (titleIcon != null) ...[
                  Icon(titleIcon, size: 20, color: colorScheme.primary),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                if (actions != null)
                  Row(mainAxisSize: MainAxisSize.min, children: actions!),
              ],
            ),
          ),
          // Content
          Padding(padding: padding ?? const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }
}

/// A styled info row for displaying label-value pairs in detail views.
class StyledInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool isLink;

  const StyledInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.onTap,
    this.trailing,
    this.isLink = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 18,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isLink ? colorScheme.primary : colorScheme.onSurface,
                    decoration: isLink ? TextDecoration.underline : null,
                    decorationColor: isLink ? colorScheme.primary : null,
                  ),
                ),
              ],
            ),
          ),
          trailing ?? const SizedBox.shrink(),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: content,
      );
    }
    return content;
  }
}

/// A styled header section for detail views with avatar, name, and status.
class StyledDetailHeader extends StatelessWidget {
  final Widget avatar;
  final String title;
  final String? subtitle;
  final String? id;
  final Widget? statusBadge;
  final Widget? roleBadge;
  final List<Widget>? actions;

  const StyledDetailHeader({
    super.key,
    required this.avatar,
    required this.title,
    this.subtitle,
    this.id,
    this.statusBadge,
    this.roleBadge,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withValues(alpha: isDark ? 0.15 : 0.08),
            colorScheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.5),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.2),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: SizedBox(width: 80, height: 80, child: avatar),
            ),
          ),
          const SizedBox(width: 20),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (id != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'ID: $id',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                // Badges row
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    statusBadge ?? const SizedBox.shrink(),
                    roleBadge ?? const SizedBox.shrink(),
                  ],
                ),
              ],
            ),
          ),
          // Actions
          if (actions != null)
            Column(mainAxisSize: MainAxisSize.min, children: actions!),
        ],
      ),
    );
  }
}

/// A styled action button for use in detail cards.
class StyledActionButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback? onPressed;
  final bool isDanger;
  final bool isSmall;

  const StyledActionButton({
    super.key,
    required this.icon,
    this.label,
    this.onPressed,
    this.isDanger = false,
    this.isSmall = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isDanger
        ? colorScheme.error
        : colorScheme.onSurfaceVariant.withValues(alpha: 0.7);

    if (label != null) {
      return TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: isSmall ? 16 : 20, color: color),
        label: Text(
          label!,
          style: TextStyle(fontSize: isSmall ? 12 : 14, color: color),
        ),
      );
    }

    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: isSmall ? 18 : 22),
      color: color,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      splashRadius: 20,
    );
  }
}

/// A styled toggle row for boolean settings in detail views.
class StyledToggleRow extends StatelessWidget {
  final String label;
  final String? description;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final IconData? icon;

  const StyledToggleRow({
    super.key,
    required this.label,
    required this.value,
    this.description,
    this.onChanged,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 18,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    description!,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: colorScheme.primary.withValues(alpha: 0.5),
            thumbColor: WidgetStatePropertyAll(
              value ? colorScheme.primary : colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

/// A styled contact link row with appropriate icons and tap actions.
class StyledContactRow extends StatelessWidget {
  final ContactType type;
  final String value;
  final VoidCallback? onTap;

  const StyledContactRow({
    super.key,
    required this.type,
    required this.value,
    this.onTap,
  });

  IconData get _icon {
    switch (type) {
      case ContactType.email:
        return Icons.mail_outline;
      case ContactType.phone:
        return Icons.call_outlined;
      case ContactType.website:
        return Icons.language;
    }
  }

  String get _label {
    switch (type) {
      case ContactType.email:
        return 'Email';
      case ContactType.phone:
        return 'Phone';
      case ContactType.website:
        return 'Website';
    }
  }

  @override
  Widget build(BuildContext context) {
    return StyledInfoRow(
      label: _label,
      value: value,
      icon: _icon,
      onTap: onTap,
      isLink: true,
    );
  }
}

enum ContactType { email, phone, website }

/// A styled avatar widget following the Stitch design system.
/// Used for displaying user/company profile images with premium styling.
class StyledAvatar extends StatelessWidget {
  /// The image to display. Can be from memory (Uint8List), network, or file.
  final ImageProvider? image;

  /// Fallback text to display when no image is available (e.g., initials)
  final String? fallbackText;

  /// The radius of the avatar. Default is 60.
  final double radius;

  /// Whether to show the edit overlay button
  final bool showEditButton;

  /// Callback when edit button is pressed
  final VoidCallback? onEditPressed;

  /// Optional hero tag for animations
  final String? heroTag;

  const StyledAvatar({
    super.key,
    this.image,
    this.fallbackText,
    this.radius = 60,
    this.showEditButton = false,
    this.onEditPressed,
    this.heroTag,
  });

  /// Creates a StyledAvatar from memory bytes (Uint8List)
  factory StyledAvatar.memory(
    Uint8List? bytes, {
    Key? key,
    String? fallbackText,
    double radius = 60,
    bool showEditButton = false,
    VoidCallback? onEditPressed,
    String? heroTag,
  }) {
    return StyledAvatar(
      key: key,
      image: bytes != null ? MemoryImage(bytes) : null,
      fallbackText: fallbackText,
      radius: radius,
      showEditButton: showEditButton,
      onEditPressed: onEditPressed,
      heroTag: heroTag,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget avatarContent = Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: image == null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary.withValues(alpha: 0.8),
                  colorScheme.primary,
                ],
              )
            : null,
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.5),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: isDark ? 0.3 : 0.2),
            blurRadius: 16,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: image != null
            ? Image(
                image: image!,
                fit: BoxFit.cover,
                width: radius * 2,
                height: radius * 2,
                errorBuilder: (context, error, stackTrace) =>
                    _buildFallback(colorScheme),
              )
            : _buildFallback(colorScheme),
      ),
    );

    // Wrap with edit button if needed
    if (showEditButton) {
      avatarContent = Stack(
        children: [
          avatarContent,
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: onEditPressed,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.surface, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.camera_alt,
                  color: colorScheme.onPrimary,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Wrap with hero animation if tag provided
    if (heroTag != null) {
      return Hero(tag: heroTag!, child: avatarContent);
    }

    return avatarContent;
  }

  Widget _buildFallback(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.primary.withValues(alpha: 0.2),
      child: Center(
        child: Text(
          fallbackText ?? '',
          style: TextStyle(
            fontSize: radius * 0.5,
            fontWeight: FontWeight.w600,
            color: colorScheme.onPrimary,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

/// A small styled avatar for use in lists and compact views.
class StyledAvatarSmall extends StatelessWidget {
  final ImageProvider? image;
  final String? fallbackText;
  final double size;
  final VoidCallback? onTap;

  const StyledAvatarSmall({
    super.key,
    this.image,
    this.fallbackText,
    this.size = 40,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: image == null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary.withValues(alpha: 0.7),
                  colorScheme.primary,
                ],
              )
            : null,
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: isDark ? 0.2 : 0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipOval(
        child: image != null
            ? Image(
                image: image!,
                fit: BoxFit.cover,
                width: size,
                height: size,
                errorBuilder: (context, error, stackTrace) =>
                    _buildFallback(colorScheme),
              )
            : _buildFallback(colorScheme),
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: avatar);
    }

    return avatar;
  }

  Widget _buildFallback(ColorScheme colorScheme) {
    return Center(
      child: Text(
        fallbackText ?? '',
        style: TextStyle(
          fontSize: size * 0.35,
          fontWeight: FontWeight.w600,
          color: colorScheme.onPrimary,
        ),
      ),
    );
  }
}

/// A styled image upload widget following the Stitch design system.
/// Displays a compact horizontal layout with avatar preview, upload instructions, and remove button.
class StyledImageUpload extends StatelessWidget {
  /// The current image to display (from memory)
  final Uint8List? imageBytes;

  /// The current image provider (for file/network images)
  final ImageProvider? image;

  /// Label for the upload area (e.g., "Customer Logo", "Profile Photo")
  final String label;

  /// Optional subtitle text (e.g., "JPG, PNG up to 2MB")
  final String? subtitle;

  /// Callback when the upload area is tapped
  final VoidCallback? onUploadTap;

  /// Callback when remove button is tapped
  final VoidCallback? onRemove;

  /// Fallback text to show in avatar when no image (e.g., initials)
  final String? fallbackText;

  /// Size of the avatar circle
  final double avatarSize;

  const StyledImageUpload({
    super.key,
    this.imageBytes,
    this.image,
    required this.label,
    this.subtitle,
    this.onUploadTap,
    this.onRemove,
    this.fallbackText,
    this.avatarSize = 56,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hasImage = imageBytes != null || image != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.4)
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Avatar/Image preview
          GestureDetector(
            onTap: onUploadTap,
            child: Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.surfaceContainerHighest,
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipOval(
                child: hasImage
                    ? Image(
                        image: image ?? MemoryImage(imageBytes!),
                        fit: BoxFit.cover,
                        width: avatarSize,
                        height: avatarSize,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildFallback(colorScheme),
                      )
                    : _buildFallback(colorScheme),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Upload instructions
          Expanded(
            child: GestureDetector(
              onTap: onUploadTap,
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle ?? 'Click to upload. JPG, PNG up to 2MB',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Remove button
          if (hasImage && onRemove != null)
            TextButton(
              onPressed: onRemove,
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              child: const Text(
                'Remove',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFallback(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: fallbackText != null && fallbackText!.isNotEmpty
            ? Text(
                fallbackText!,
                style: TextStyle(
                  fontSize: avatarSize * 0.35,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            : Icon(
                Icons.person_outline,
                size: avatarSize * 0.5,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
      ),
    );
  }
}
