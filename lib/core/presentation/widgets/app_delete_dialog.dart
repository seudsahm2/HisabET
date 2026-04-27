import 'package:flutter/material.dart';
import 'package:hisabet/core/theme/theme.dart';

class AppDeleteDialog extends StatefulWidget {
  final String title;
  final String content;

  const AppDeleteDialog({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  State<AppDeleteDialog> createState() => _AppDeleteDialogState();
}

class _AppDeleteDialogState extends State<AppDeleteDialog> {
  final _textController = TextEditingController();
  bool _canDelete = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      final value = _textController.text.trim().toLowerCase();
      setState(() {
        _canDelete = value == 'delete';
      });
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.content, style: const TextStyle(color: AppColors.negative)),
          const SizedBox(height: AppDimensions.md),
          const Text('Type "delete" below to confirm:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: AppDimensions.xs),
          TextField(
            controller: _textController,
            decoration: InputDecoration(
              hintText: 'delete',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLg)),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _canDelete ? () => Navigator.of(context).pop(true) : null,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.negative, foregroundColor: Colors.white),
          child: const Text('Delete Permanently'),
        ),
      ],
    );
  }
}
