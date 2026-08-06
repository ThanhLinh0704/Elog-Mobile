import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../providers.dart';
import '../../../driver_trips/presentation/widgets/shared_widgets.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _isLoading = true;
  bool _isLoggingOut = false;
  String? _username;
  String? _fullName;
  String? _userId;
  List<String> _roles = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final storage = ref.read(secureStorageProvider);
    final username = await storage.getUsername();
    final fullName = await storage.getFullName();
    final userId = await storage.getUserId();
    final rolesRaw = await storage.getRoles();
    if (!mounted) return;
    setState(() {
      _username = username;
      _fullName = (fullName != null && fullName.isNotEmpty) ? fullName : username;
      _userId = userId;
      _roles = (rolesRaw ?? '')
          .split(',')
          .map((r) => r.trim())
          .where((r) => r.isNotEmpty)
          .toList();
      _isLoading = false;
    });
  }

  String _roleLabel(String role) {
    switch (role.toUpperCase()) {
      case 'DRIVER':
        return 'Tài xế';
      case 'DISPATCHER':
        return 'Điều phối viên';
      case 'WAREHOUSE_STAFF':
        return 'Nhân viên kho';
      case 'LOGISTICS_MANAGER':
        return 'Quản lý vận hành';
      case 'SYSTEM_ADMIN':
        return 'Quản trị hệ thống';
      default:
        return role;
    }
  }

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    final last = parts.last;
    return last.isNotEmpty ? last[0].toUpperCase() : '?';
  }

  Future<void> _handleLogout() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Đăng xuất',
      content: 'Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng không?',
      confirmLabel: 'Đăng xuất',
      confirmColor: AppTheme.statusException,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isLoggingOut = true);
    try {
      await ref.read(authNotifierProvider.notifier).logout();
      // Router redirect handles navigation back to Login once isLoggedIn = false.
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Thông tin cá nhân'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionCard(
                          title: 'Tài khoản',
                          icon: Icons.badge_outlined,
                          children: [
                            InfoRow(
                              icon: Icons.person_outline,
                              label: 'Tên đăng nhập',
                              value: _username,
                            ),
                            InfoRow(
                              icon: Icons.tag,
                              label: 'Mã tài khoản',
                              value: _userId != null ? '#$_userId' : null,
                            ),
                            InfoRow(
                              icon: Icons.verified_user_outlined,
                              label: 'Vai trò',
                              value: _roles.isNotEmpty
                                  ? _roles.map(_roleLabel).join(', ')
                                  : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSectionCard(
                          title: 'Ứng dụng',
                          icon: Icons.info_outline,
                          children: const [
                            InfoRow(
                              icon: Icons.local_shipping_outlined,
                              label: 'Ứng dụng',
                              value: 'ELog Driver',
                            ),
                            InfoRow(
                              icon: Icons.numbers,
                              label: 'Phiên bản',
                              value: '1.0.0',
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        _buildLogoutButton(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryDark, Color(0xFF1E293B)],
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.white.withOpacity(0.4), width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _initials(_fullName),
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryDark,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _fullName ?? 'Tài xế',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_shipping_outlined,
                    size: 14, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  _roles.isNotEmpty
                      ? _roles.map(_roleLabel).join(', ')
                      : 'Tài xế',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoggingOut ? null : _handleLogout,
        icon: _isLoggingOut
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.logout_rounded),
        label: Text(_isLoggingOut ? 'Đang đăng xuất...' : 'Đăng xuất'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.statusException,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
