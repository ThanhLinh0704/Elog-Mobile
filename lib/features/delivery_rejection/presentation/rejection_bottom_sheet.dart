import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../driver_trips/presentation/widgets/shared_widgets.dart';

/// Rejection type enum values matching backend
class RejectionTypeOption {
  final String value; // Backend enum code
  final String label; // Vietnamese display label

  const RejectionTypeOption(this.value, this.label);
}

const kRejectionTypes = [
  RejectionTypeOption('STORE_CLOSED', 'Cửa hàng đóng cửa'),
  RejectionTypeOption('STORE_REFUSED', 'Cửa hàng từ chối nhận'),
  RejectionTypeOption('WRONG_ITEMS', 'Hàng không đúng đơn'),
  RejectionTypeOption('DAMAGED_GOODS', 'Hàng bị hư hỏng'),
  RejectionTypeOption('NO_SPACE', 'Không có chỗ chứa hàng'),
  RejectionTypeOption('OTHER', 'Lý do khác (vui lòng ghi rõ bên dưới)'),
];

/// Result returned from the bottom sheet
class RejectionFormResult {
  final String rejectionType;
  final String? description;

  const RejectionFormResult({
    required this.rejectionType,
    this.description,
  });
}

/// Show the delivery rejection bottom sheet.
/// Returns [RejectionFormResult] if user confirmed, null if cancelled.
Future<RejectionFormResult?> showRejectionBottomSheet(
  BuildContext context, {
  required String storeCode,
  required String? storeName,
}) {
  return showModalBottomSheet<RejectionFormResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _RejectionBottomSheet(
      storeCode: storeCode,
      storeName: storeName,
    ),
  );
}

class _RejectionBottomSheet extends StatefulWidget {
  final String storeCode;
  final String? storeName;

  const _RejectionBottomSheet({
    required this.storeCode,
    required this.storeName,
  });

  @override
  State<_RejectionBottomSheet> createState() => _RejectionBottomSheetState();
}

class _RejectionBottomSheetState extends State<_RejectionBottomSheet> {
  String? _selectedType;
  final _descCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  bool get _isOther => _selectedType == 'OTHER';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn lý do từ chối')),
      );
      return;
    }

    // Final confirmation
    final confirmed = await showConfirmDialog(
      context,
      title: 'Xác nhận báo lỗi giao hàng',
      content:
          'Sau khi xác nhận, hàng sẽ được giữ lại trên xe và xử lý trả về kho sau khi kết thúc chuyến.',
      confirmLabel: 'Xác nhận',
      confirmColor: Colors.red.shade700,
    );
    if (!confirmed) return;

    setState(() => _isSubmitting = true);
    // Don't close bottom sheet before result — return result to caller
    if (mounted) {
      Navigator.of(context).pop(RejectionFormResult(
        rejectionType: _selectedType!,
        description:
            _descCtrl.text.trim().isNotEmpty ? _descCtrl.text.trim() : null,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle indicator
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                'Báo Lỗi Giao Hàng',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.storeCode}${widget.storeName != null ? " — ${widget.storeName}" : ""}',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 20),

              // Rejection types
              const Text(
                'Lý do từ chối:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              ...kRejectionTypes.map((option) => _RejectionOption(
                    option: option,
                    isSelected: _selectedType == option.value,
                    onTap: () => setState(() => _selectedType = option.value),
                  )),
              const SizedBox(height: 16),

              // Description field
              TextFormField(
                controller: _descCtrl,
                decoration: InputDecoration(
                  labelText: _isOther ? 'Ghi chú *' : 'Ghi chú thêm (tùy chọn)',
                  hintText: _isOther
                      ? 'Vui lòng mô tả lý do từ chối'
                      : 'Thông tin bổ sung nếu có',
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                textInputAction: TextInputAction.done,
                validator: (v) {
                  if (_isOther && (v == null || v.trim().isEmpty)) {
                    return 'Vui lòng nhập mô tả khi chọn "Lý do khác"';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Warning
              const GoodsRetainedBanner(),
              const SizedBox(height: 20),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(null),
                      child: const Text('Huỷ'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('Xác nhận Báo Lỗi'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _RejectionOption extends StatelessWidget {
  final RejectionTypeOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _RejectionOption({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withOpacity(0.08)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.primary : const Color(0xFFCBD5E1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? AppTheme.primary : AppTheme.textMuted,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                option.label,
                style: TextStyle(
                  color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
