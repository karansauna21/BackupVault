import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SettingsCategoryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const SettingsCategoryCard({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.brightness == Brightness.light
              ? const Color(0xFFE2E8F0)
              : const Color(0xFF1E293B),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }
}

class SettingsSwitchTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsSwitchTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: icon != null
          ? Icon(
              icon,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            )
          : null,
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            )
          : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: theme.colorScheme.primary,
      ),
    );
  }
}

class SettingsDropdownTile<T> extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const SettingsDropdownTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: icon != null
          ? Icon(
              icon,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            )
          : null,
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            )
          : null,
      trailing: SizedBox(
        width: 140,
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            items: items,
            onChanged: onChanged,
            alignment: Alignment.centerRight,
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down_rounded),
            dropdownColor: theme.colorScheme.surface,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsSliderTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String Function(double)? formatLabel;
  final ValueChanged<double> onChanged;

  const SettingsSliderTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    this.formatLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: icon != null
              ? Icon(
                  icon,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                )
              : null,
          title: Text(
            title,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: subtitle != null ? Text(subtitle!) : null,
          trailing: Text(
            formatLabel != null ? formatLabel!(value) : value.toStringAsFixed(0),
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: theme.colorScheme.primary,
              inactiveTrackColor: theme.colorScheme.primary.withValues(alpha: 0.15),
              thumbColor: theme.colorScheme.primary,
              overlayColor: theme.colorScheme.primary.withValues(alpha: 0.12),
              valueIndicatorColor: theme.colorScheme.primary,
              valueIndicatorTextStyle: const TextStyle(color: Colors.white),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions ?? (max - min).toInt(),
              label: formatLabel != null ? formatLabel!(value) : value.toStringAsFixed(0),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class SettingsTextFieldTile extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final String value;
  final bool isNumeric;
  final String? prefixText;
  final String? suffixText;
  final ValueChanged<String> onSubmitted;

  const SettingsTextFieldTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.value,
    this.isNumeric = false,
    this.prefixText,
    this.suffixText,
    required this.onSubmitted,
  });

  @override
  State<SettingsTextFieldTile> createState() => _SettingsTextFieldTileState();
}

class _SettingsTextFieldTileState extends State<SettingsTextFieldTile> {
  late TextEditingController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(SettingsTextFieldTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_isEditing) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: widget.icon != null
          ? Icon(
              widget.icon,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            )
          : null,
      title: Text(
        widget.title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: widget.subtitle != null
          ? Text(
              widget.subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.prefixText != null) ...[
            Text(widget.prefixText!, style: theme.textTheme.bodyMedium),
            const SizedBox(width: 4),
          ],
          SizedBox(
            width: 120,
            height: 38,
            child: TextField(
              controller: _controller,
              keyboardType: widget.isNumeric ? TextInputType.number : TextInputType.text,
              inputFormatters: widget.isNumeric
                  ? [FilteringTextInputFormatter.digitsOnly]
                  : null,
              textAlign: TextAlign.end,
              onTap: () => setState(() => _isEditing = true),
              onSubmitted: (val) {
                setState(() => _isEditing = false);
                widget.onSubmitted(val.trim());
              },
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: theme.brightness == Brightness.light
                    ? const Color(0xFFF1F5F9)
                    : const Color(0xFF1E293B),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                hintText: 'Enter...',
              ),
            ),
          ),
          if (widget.suffixText != null) ...[
            const SizedBox(width: 4),
            Text(widget.suffixText!, style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class SettingsPathPickerTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final String path;
  final String dialogTitle;
  final ValueChanged<String> onSelected;

  const SettingsPathPickerTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.path,
    required this.dialogTitle,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: icon != null
          ? Icon(
              icon,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            )
          : null,
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        path.isEmpty ? 'No path selected' : path,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: path.isEmpty
              ? theme.colorScheme.error.withValues(alpha: 0.8)
              : theme.textTheme.bodySmall?.color,
        ),
      ),
      trailing: IconButton.filledTonal(
        icon: const Icon(Icons.folder_open_rounded),
        color: theme.colorScheme.primary,
        onPressed: () => _showEditDialog(context),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final controller = TextEditingController(text: path);
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(dialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter the directory path manually:',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Directory Path',
                  hintText: Platform.isWindows ? 'C:\\Backups' : '/home/user/backups',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                onSelected(controller.text.trim());
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

class SettingsSearchField extends StatelessWidget {
  final String query;
  final ValueChanged<String> onChanged;

  const SettingsSearchField({
    super.key,
    required this.query,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        onChanged: onChanged,
        style: theme.textTheme.bodyLarge,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () => onChanged(''),
                )
              : null,
          hintText: 'Search settings...',
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          filled: true,
          fillColor: theme.brightness == Brightness.light
              ? const Color(0xFFF1F5F9)
              : const Color(0xFF1E293B),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
