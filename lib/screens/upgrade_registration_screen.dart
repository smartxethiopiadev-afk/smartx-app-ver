import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/device_service.dart';
import 'login_activation_screen.dart';

class UpgradeRegistrationScreen extends StatefulWidget {
  final bool isDarkMode;
  final String languageCode;
  final int initialGrade;
  final String? initialSubject;

  const UpgradeRegistrationScreen({
    super.key,
    required this.isDarkMode,
    required this.languageCode,
    this.initialGrade = 12,
    this.initialSubject,
  });

  static Future<void> push(
    BuildContext context, {
    required bool isDarkMode,
    required String languageCode,
    int initialGrade = 12,
    String? initialSubject,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => UpgradeRegistrationScreen(
          isDarkMode: isDarkMode,
          languageCode: languageCode,
          initialGrade: initialGrade,
          initialSubject: initialSubject,
        ),
      ),
    );
  }

  @override
  State<UpgradeRegistrationScreen> createState() => _UpgradeRegistrationScreenState();
}

class _UpgradeRegistrationScreenState extends State<UpgradeRegistrationScreen> {
  late int _selectedGrade;
  late String _selectedSubject;
  String _deviceId = '...';
  String _studentName = '';
  String _studentPhone = '';
  int _selectedTierIndex = 1; // 0: Single Subject, 1: Full Grade, 2: Matric

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final List<String> _subjects = [
    'Mathematics',
    'Physics',
    'Chemistry',
    'Biology',
    'English',
    'Economics',
    'Geography',
    'History',
    'Information Technology',
  ];

  @override
  void initState() {
    super.initState();
    _selectedGrade = widget.initialGrade;
    _selectedSubject = widget.initialSubject ?? 'Physics';
    _loadDeviceAndProfile();
  }

  Future<void> _loadDeviceAndProfile() async {
    final devId = await DeviceService.getDeviceId();
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_fullName') ?? prefs.getString('user_name') ?? '';
    final phone = prefs.getString('user_phoneNumber') ?? prefs.getString('phone_number') ?? '';

    if (mounted) {
      setState(() {
        _deviceId = devId;
        _studentName = name;
        _studentPhone = phone;
        _nameController.text = name;
        _phoneController.text = phone;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _registerViaTelegram() async {
    final name = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : (_studentName.isNotEmpty ? _studentName : 'Student');
    final phone = _phoneController.text.trim().isNotEmpty
        ? _phoneController.text.trim()
        : (_studentPhone.isNotEmpty ? _studentPhone : 'N/A');

    String tierName = 'Full Grade $_selectedGrade (All Subjects)';
    if (_selectedTierIndex == 0) {
      tierName = 'Grade $_selectedGrade $_selectedSubject Only';
    } else if (_selectedTierIndex == 2) {
      tierName = 'University Entrance Matric Preparation Pack';
    }

    final String message =
        'ሰላም Ethio Concept Center Admin, በመተግበሪያው ላይ መመዝገብ እና መለያ መክፈት እፈልጋለሁ:\n'
        '• የተመረጠው ፓኬጅ: $tierName\n'
        '• የተማሪ ስም: $name\n'
        '• ስልክ ቁጥር: $phone\n'
        '• Device ID: $_deviceId\n'
        'እባክዎ የይለፍ ቃል (Password) ይስጡኝ።';

    final Uri telegramUri = Uri.parse('https://t.me/EthioconceptcenterAcademy?text=${Uri.encodeComponent(message)}');

    try {
      if (await canLaunchUrl(telegramUri)) {
        await launchUrl(telegramUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(telegramUri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      if (mounted) {
        Clipboard.setData(ClipboardData(text: message));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('የምዝገባ መረጃው ተቀድቷል! ቴሌግራም ላይ @EthioconceptcenterAcademy ይላኩ።'),
            backgroundColor: Color(0xFF0088CC),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLight = !widget.isDarkMode;
    final bool isAm = widget.languageCode == 'am';

    return Scaffold(
      backgroundColor: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(
          isAm ? 'የተማሪ ምዝገባ እና ማግበሪያ' : 'Student Registration & Upgrade',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        backgroundColor: isLight ? Colors.white : const Color(0xFF1E293B),
        foregroundColor: isLight ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isAm ? 'አንድ ስልክ ብቻ (Single Device)' : '1 Phone Hardware Binding',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const Icon(Icons.security_rounded, color: Colors.white, size: 22),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isAm
                        ? 'የተማሪ መለያዎን በአድሚን ያስከፍቱ'
                        : 'Register & Activate Account',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isAm
                        ? 'በቴሌግራም አድሚኑን በማነጋገር ስም፣ ስልክ እና ይለፍ ቃል በመቀበል የተፈቀደሎትን ትምህርት በቋሚነት በዚህ ስልክዎ ይጠቀሙ።'
                        : 'Contact admin on Telegram to receive credentials and unlock authorized subjects permanently on this phone.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Grade Selector
            Text(
              isAm ? 'የትምህርት ክፍል ይምረጡ (Select Grade)' : 'Select Grade',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                color: isLight ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [9, 10, 11, 12].map((g) {
                final bool isSelected = _selectedGrade == g;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedGrade = g;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFEF4444)
                              : (isLight ? Colors.white : const Color(0xFF1E293B)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFEF4444)
                                : (isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
                          ),
                        ),
                        child: Text(
                          'Grade $g',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : (isLight ? const Color(0xFF0F172A) : Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 18),

            // Access Tier Options (No Price, strictly feature scope)
            Text(
              isAm ? 'የመዳረሻ ዓይነት (Access Tiers)' : 'Choose Access Tier',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                color: isLight ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              ),
            ),
            const SizedBox(height: 8),

            _buildTierCard(
              index: 0,
              title: isAm
                  ? 'የአንድ ትምህርት ብቻ መዳረሻ (Single Subject)'
                  : 'Single Subject Access',
              subtitle: isAm
                  ? 'ለተመረጠው ትምህርት ብቻ (ለምሳሌ Grade $_selectedGrade $_selectedSubject)'
                  : 'Unlocks selected subject only (e.g. $_selectedSubject)',
              icon: Icons.menu_book_rounded,
              color: const Color(0xFF10B981),
              isLight: isLight,
            ),
            const SizedBox(height: 8),
            _buildTierCard(
              index: 1,
              title: isAm
                  ? 'የሙሉ ክፍል ትምህርቶች (Grade $_selectedGrade All Subjects)'
                  : 'Full Grade $_selectedGrade (All Subjects)',
              subtitle: isAm
                  ? 'የክፍል $_selectedGrade ሁሉንም ትምህርቶች (Math, Physics, Chem, Bio...) ያካትታል'
                  : 'Unlocks all subjects for Grade $_selectedGrade',
              icon: Icons.auto_stories_rounded,
              color: const Color(0xFF2563EB),
              isLight: isLight,
            ),
            const SizedBox(height: 8),
            _buildTierCard(
              index: 2,
              title: isAm
                  ? 'የማትሪክ ዝግጅት ፓኬጅ (Matric Exam Prep)'
                  : 'University Entrance Matric Bundle',
              subtitle: isAm
                  ? 'የፈተና ወረቀቶች፣ ጥያቄዎችና ማብራሪያዎች ሙሉ መዳረሻ'
                  : 'National exam prep questions, worksheets, and model tests',
              icon: Icons.military_tech_rounded,
              color: const Color(0xFFF59E0B),
              isLight: isLight,
            ),

            if (_selectedTierIndex == 0) ...[
              const SizedBox(height: 14),
              Text(
                isAm ? 'ትምህርት ይምረጡ (Choose Subject)' : 'Select Subject',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isLight ? Colors.white : const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isLight ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedSubject,
                    isExpanded: true,
                    dropdownColor: isLight ? Colors.white : const Color(0xFF1E293B),
                    items: _subjects.map((sub) {
                      return DropdownMenuItem<String>(
                        value: sub,
                        child: Text(
                          sub,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isLight ? const Color(0xFF0F172A) : Colors.white,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedSubject = val;
                        });
                      }
                    },
                  ),
                ),
              ),
            ],

            const SizedBox(height: 18),

            // Student Registration Inputs
            Text(
              isAm ? 'የተማሪ መረጃ (Student Info)' : 'Student Details',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                color: isLight ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: isAm ? 'ሙሉ ስም (Full Name)' : 'Full Name',
                prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                filled: true,
                fillColor: isLight ? Colors.white : const Color(0xFF1E293B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: isAm ? 'ስልክ ቁጥር (Phone Number)' : 'Phone Number',
                prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                filled: true,
                fillColor: isLight ? Colors.white : const Color(0xFF1E293B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Device Hardware ID Badge
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.fingerprint_rounded, size: 20, color: Color(0xFF64748B)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAm ? 'የስልክ መለያ ቁጥር (Device ID)' : 'Phone Hardware ID',
                          style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                        ),
                        Text(
                          _deviceId,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isLight ? const Color(0xFF0F172A) : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _deviceId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Device ID copied!')),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Primary Action: Register on Telegram
            ElevatedButton(
              onPressed: _registerViaTelegram,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0088CC),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      Positioned(
                        right: -3,
                        top: -3,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add, size: 8, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isAm
                        ? 'በቴሌግራም ተመዝገብና አግኝ (Register via Telegram)'
                        : 'Register via Telegram Admin',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Secondary Action: I Have Credentials (Login)
            OutlinedButton.icon(
              onPressed: () async {
                await LoginActivationScreen.push(
                  context,
                  isDarkMode: widget.isDarkMode,
                  languageCode: widget.languageCode,
                  preferredGrade: _selectedGrade,
                  preferredSubject: _selectedSubject,
                );
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
                side: BorderSide(
                  color: isLight ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: Icon(
                Icons.key_rounded,
                size: 18,
                color: isLight ? const Color(0xFF0F172A) : Colors.white,
              ),
              label: Text(
                isAm
                    ? 'የይለፍ ቃል አለኝ (Login)'
                    : 'I already have credentials (Login)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isLight ? const Color(0xFF0F172A) : Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTierCard({
    required int index,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isLight,
  }) {
    final bool isSelected = _selectedTierIndex == index;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedTierIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isLight ? Colors.white : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? color
                : (isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: isLight ? const Color(0xFF0F172A) : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: isSelected ? color : const Color(0xFF94A3B8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
