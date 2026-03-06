import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../features/moderation/data/moderation_service.dart';

class ReportDialog extends ConsumerStatefulWidget {
  final String? productId;
  final String? commentId;
  final String? userId;

  const ReportDialog({super.key, this.productId, this.commentId, this.userId});

  @override
  ConsumerState<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends ConsumerState<ReportDialog> {
  ReportReason _selectedReason = ReportReason.INAPPROPRIATE_CONTENT;
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final service = ref.read(moderationServiceProvider);
      await service.reportContent(
        reason: _selectedReason,
        description: _descriptionController.text.trim(),
        reportedProductId: widget.productId,
        reportedCommentId: widget.commentId,
        reportedUserId: widget.userId,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Signalement envoyé. Merci de nous aider à garder Clovi sûr !'),
          backgroundColor: AppColors.cloviGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Signaler un contenu', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pourquoi signalez-vous ce contenu ?', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 12),
            ...ReportReason.values.map((reason) => RadioListTile<ReportReason>(
                  title: Text(_reasonLabel(reason), style: const TextStyle(fontSize: 14)),
                  value: reason,
                  groupValue: _selectedReason,
                  onChanged: (v) => setState(() => _selectedReason = v!),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  activeColor: AppColors.cloviGreen,
                )),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                hintText: 'Plus de détails (facultatif)...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.all(12),
              ),
              maxLines: 3,
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          style: FilledButton.styleFrom(backgroundColor: AppColors.cloviGreen),
          child: _isSubmitting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Signaler'),
        ),
      ],
    );
  }

  String _reasonLabel(ReportReason r) {
    return switch (r) {
      ReportReason.SPAM => 'Spam / Arnaque',
      ReportReason.INAPPROPRIATE_CONTENT => 'Contenu inapproprié',
      ReportReason.FRAUD => 'Fraude / Contrefaçon',
      ReportReason.HARASSMENT => 'Harcèlement',
      ReportReason.OTHER => 'Autre',
    };
  }
}
