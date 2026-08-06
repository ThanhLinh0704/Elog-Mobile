import 'package:flutter/material.dart';
import '../../data/models/driver_trip_model.dart';
import '../../data/models/update_order_result_request.dart';

class OrderResultBottomSheet extends StatefulWidget {
  final int executionId;
  final int orderId;
  final String orderRef;
  final OrderDeliveryStatus currentStatus;
  final Future<void> Function(UpdateOrderResultRequest request) onSubmit;

  const OrderResultBottomSheet({
    super.key,
    required this.executionId,
    required this.orderId,
    required this.orderRef,
    required this.currentStatus,
    required this.onSubmit,
  });

  static Future<void> show({
    required BuildContext context,
    required int executionId,
    required int orderId,
    required String orderRef,
    required OrderDeliveryStatus currentStatus,
    required Future<void> Function(UpdateOrderResultRequest request) onSubmit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => OrderResultBottomSheet(
        executionId: executionId,
        orderId: orderId,
        orderRef: orderRef,
        currentStatus: currentStatus,
        onSubmit: onSubmit,
      ),
    );
  }

  @override
  State<OrderResultBottomSheet> createState() => _OrderResultBottomSheetState();
}

class _OrderResultBottomSheetState extends State<OrderResultBottomSheet> {
  OrderDeliveryStatus? _selectedStatus;
  ReasonCodeOption? _selectedReason;
  final _exceptionTextController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _exceptionTextController.dispose();
    super.dispose();
  }

  bool get _needsReason =>
      _selectedStatus == OrderDeliveryStatus.partiallyDelivered ||
      _selectedStatus == OrderDeliveryStatus.failed;

  Future<void> _handleSubmit() async {
    if (_selectedStatus == null) {
      setState(() => _error = 'Vui lòng chọn kết quả giao hàng.');
      return;
    }
    if (_needsReason && _selectedReason == null) {
      setState(() => _error = 'Vui lòng chọn lý do.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final req = UpdateOrderResultRequest(
        status: _selectedStatus!,
        reasonCode: _needsReason ? _selectedReason?.code : null,
        exceptionText: _exceptionTextController.text.trim().isEmpty
            ? null
            : _exceptionTextController.text.trim(),
      );
      await widget.onSubmit(req);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Row(
              children: [
                const Icon(Icons.fact_check, color: Color(0xFF1677FF)),
                const SizedBox(width: 8),
                Text(
                  'Cập nhật kết quả: ${widget.orderRef}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Status selection
            const Text(
              'Kết quả giao hàng *',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),

            _buildStatusTile(
              status: OrderDeliveryStatus.delivered,
              label: 'Đã giao thành công',
              color: Colors.green,
              icon: Icons.check_circle_outline,
            ),
            const SizedBox(height: 8),
            _buildStatusTile(
              status: OrderDeliveryStatus.partiallyDelivered,
              label: 'Giao một phần',
              color: Colors.orange,
              icon: Icons.warning_amber_outlined,
            ),
            const SizedBox(height: 8),
            _buildStatusTile(
              status: OrderDeliveryStatus.failed,
              label: 'Giao thất bại',
              color: Colors.red,
              icon: Icons.cancel_outlined,
            ),

            // Reason selector if required
            if (_needsReason) ...[
              const SizedBox(height: 16),
              const Text(
                'Lý do *',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<ReasonCodeOption>(
                initialValue: _selectedReason,
                hint: const Text('Chọn lý do...'),
                isExpanded: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: kReasonCodeOptions.map((opt) {
                  return DropdownMenuItem<ReasonCodeOption>(
                    value: opt,
                    child: Text(opt.label, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedReason = val),
              ),
            ],

            // Note text field
            if (_selectedStatus != null &&
                _selectedStatus != OrderDeliveryStatus.delivered) ...[
              const SizedBox(height: 16),
              const Text(
                'Ghi chú thêm (tùy chọn)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _exceptionTextController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Mô tả chi tiết tình huống...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],

            // Error message
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: Colors.red[700], fontSize: 13),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Submit button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1677FF),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Xác nhận kết quả',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTile({
    required OrderDeliveryStatus status,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    final isSelected = _selectedStatus == status;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedStatus = status;
          _selectedReason = null;
          _error = null;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? color : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
