import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/activation_service.dart';
import '../services/device_service.dart';

class ActivationCodeDialog extends StatefulWidget {
  final bool isDarkMode;
  final String languageCode;
  final int? preferredGrade;
  final String? preferredSubject;
  final VoidCallback? onActivated;

  const ActivationCodeDialog({
    super.key,
    required this.isDarkMode,
    required this.languageCode,
    this.preferredGrade,
    this.preferredSubject,
    this.onActivated,
  });

  static Future<bool?> show(
    BuildContext context, {
    required bool isDarkMode,
    required String languageCode,
    int? preferredGrade,
    String? preferredSubject,
    VoidCallback? onActivated,
  }) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ActivationCodeDialog(
        isDarkMode: isDarkMode,
        languageCode: languageCode,
        preferredGrade: preferredGrade,
        preferredSubject: preferredSubject,
        onActivated: onActivated,
      ),
    );
  }

  @override
  State<ActivationCodeDialog> createState() => _ActivationCodeDialogState();
}

class _ActivationCodeDialogState extends State<ActivationCodeDialog> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();

  String _deviceId = '';
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    final hardwareId = await DeviceService.getDeviceId();

    final name = prefs.getString('user_fullName') ??
        prefs.getString('user_name') ??
        '';
    final phone = prefs.getString('user_phoneNumber') ??
        prefs.getString('phone_number') ??
        '';

    _nameController.text = name;
    _phoneController.text = phone;

    if (mounted) {
      setState(() {
        _deviceId = hardwareId;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleActivate() async {
    final isAm = widget.languageCode == 'am';
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final code = _codeController.text.trim().toUpperCase().replaceAll(' ', '');

    setState(() {
      _errorMessage = null;
    });

    if (code.isEmpty) {
      setState(() {
        _errorMessage = isAm
            ? 'እባክዎ የማግበሪያ ኮዱን ያስገቡ።'
            : 'Please enter your activation code.';
      });
      return;
    }

    if (name.isEmpty) {
      setState(() {
        _errorMessage = isAm
            ? 'እባክዎ የተማሪውን ሙሉ ስም ያስገቡ።'
            : 'Please enter student full name.';
      });
      return;
    }

    if (phone.isEmpty || phone.length < 9) {
      setState(() {
        _errorMessage = isAm
            ? 'እባክዎ ትክክለኛ ስልክ ቁጥር ያስገቡ።'
            : 'Please enter a valid phone number.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final result = await ActivationService.activateCode(
      code: code,
      name: name,
      phone: phone,
      languageCode: widget.languageCode,
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (result.isSuccess) {
      Navigator.of(context).pop(true);
      widget.onActivated?.call();

      _showSuccessSheet(result);
    } else {
      setState(() {
        _errorMessage = result.message;
      });
    }
  }

  void _showSuccessSheet(ActivationResult result) {
    final isAm = widget.languageCode == 'am';
    final isLight = !widget.isDarkMode;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isLight ? Colors.white : const Color(0xFF0F172A),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_rounded, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              isAm ? 'ፓኬጁ በተሳካ ሁኔታ ነቅቷል!' : 'Package Activated Successfully!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: isLight ? const Color(0xFF0F172A) : Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              result.packageName ?? (isAm ? 'የትምህርት ፓኬጅ' : 'Learning Package'),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0084FF),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phonelink_lock_rounded, color: Color(0xFF10B981), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isAm
                          ? 'ይህ ፓኬጅ ከዚህ ስልክ ጋር በደህንነት ተያይዟል (Hardware Bound)። ከመስመር ውጭ ማውረድ እና ሙሉ ትምህርቶች ተፈቅደዋል።'
                          : 'Package is securely bound to this device. Full unit downloads and worksheets are unlocked.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  isAm ? 'መማር ጀምር' : 'Start Learning',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLight = !widget.isDarkMode;
    final bool isAm = widget.languageCode == 'am';

    final Color bgColor = isLight ? Colors.white : const Color(0xFF1E293B);
    final Color borderColor = isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155);
    final Color textPrimary = isLight ? const Color(0xFF0F172A) : Colors.white;
    final Color textSecondary = isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    return Dialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: _isLoading
          ? const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator(color: Color(0xFF0084FF))),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Close Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0084FF).withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.vpn_key_rounded,
                              color: Color(0xFF0084FF),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isAm ? 'የማግበሪያ ኮድ አስገባ' : 'Enter Activation Code',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: textSecondary, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isAm
                        ? 'ከቴሌግራም ወይም ከአስተዳዳሪ የተሰጠዎትን የማግበሪያ ኮድ ያስገቡ።'
                        : 'Enter the package-specific activation code received from Smart X Admin.',
                    style: TextStyle(fontSize: 12, color: textSecondary, height: 1.35),
                  ),
                  const SizedBox(height: 18),

                  // 1. Activation Code Input (Big & Prominent)
                  Text(
                    isAm ? 'የማግበሪያ ኮድ (Activation Code)' : 'Activation Code',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: 1.5,
                      color: Color(0xFF0084FF),
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. SMARTX-G12-MATH-2026',
                      hintStyle: TextStyle(
                        fontFamily: 'sans-serif',
                        fontSize: 13,
                        letterSpacing: 0,
                        color: textSecondary.withValues(alpha: 0.7),
                      ),
                      isDense: true,
                      filled: true,
                      fillColor: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                      prefixIcon: const Icon(Icons.key_rounded, size: 18, color: Color(0xFF0084FF)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF0084FF), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. Student Full Name Input
                  Text(
                    isAm ? 'የተማሪው ሙሉ ስም' : 'Student Full Name',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: isAm ? 'ስም እና የአባት ስም' : 'Full Name',
                      isDense: true,
                      filled: true,
                      fillColor: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                      prefixIcon: const Icon(Icons.person_rounded, size: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3. Student Phone Input
                  Text(
                    isAm ? 'ስልክ ቁጥር' : 'Phone Number',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: '09xxxxxxxx / +251...',
                      isDense: true,
                      filled: true,
                      fillColor: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                      prefixIcon: const Icon(Icons.phone_rounded, size: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Single Device Protection Status
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.security_rounded, size: 16, color: Color(0xFF10B981)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isAm ? 'ደህንነቱ የተጠበቀ የመሣሪያ ማረጋገጫ' : 'Automated Secure Single-Device Authentication',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Error Message Banner
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textSecondary,
                            side: BorderSide(color: borderColor),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(isAm ? 'ይቅር' : 'Cancel'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _handleActivate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0084FF),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  isAm ? 'ኮዱን አግብር' : 'Activate Code',
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
