import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/user_profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  late TextEditingController _nameCtrl;
  late TextEditingController _headlineCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _collegeCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _customSkillCtrl;
  late TextEditingController _salaryCtrl;

  String? _selectedGradYear = '2026';
  String _selectedJobType = 'Full-Time';
  double _expectedSalary = 12.0;

  // Profile picture customization state
  String _avatarInitials = 'AV';
  Color _avatarBgColor = AppColors.primary;
  IconData _avatarIcon = Icons.person_rounded;
  int _selectedAvatarIndex = 0;
  String? _avatarImagePath;
  final ImagePicker _picker = ImagePicker();

  final List<Map<String, dynamic>> _presetAvatars = [
    {'label': 'Arjun V', 'initials': 'AV', 'color': const Color(0xFF4648D4), 'icon': Icons.code_rounded},
    {'label': 'Flutter Dev', 'initials': 'FD', 'color': const Color(0xFF0EA5E9), 'icon': Icons.flutter_dash_rounded},
    {'label': 'Java Lead', 'initials': 'JL', 'color': const Color(0xFF10B981), 'icon': Icons.terminal_rounded},
    {'label': 'AI Expert', 'initials': 'AI', 'color': const Color(0xFFEC4899), 'icon': Icons.psychology_rounded},
    {'label': 'Cloud Arch', 'initials': 'CA', 'color': const Color(0xFFF59E0B), 'icon': Icons.cloud_rounded},
  ];

  final List<String> _userSkills = [];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _checkLostImage();
    final profile = ref.read(userProfileProvider);
    _userSkills.addAll(profile.skills);
    _avatarImagePath = profile.avatarImagePath;
    _avatarInitials = profile.avatarInitials;

    _nameCtrl = TextEditingController(text: profile.name);
    _headlineCtrl = TextEditingController(text: profile.targetRole);
    _phoneCtrl = TextEditingController(text: '+91 98765 43210');
    _emailCtrl = TextEditingController(text: 'arjun.verma@cda.edu');
    _collegeCtrl = TextEditingController(text: profile.college);
    _bioCtrl = TextEditingController(
        text: 'Passionate software developer specializing in scalable Java backends & cross-platform Flutter mobile applications. Building real-world AI tools.');
    _customSkillCtrl = TextEditingController();
    _salaryCtrl = TextEditingController(text: '12');
  }

  Future<void> _checkLostImage() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final LostDataResponse response = await _picker.retrieveLostData();
        if (response.isEmpty) return;
        if (response.file != null) {
          setState(() {
            _avatarImagePath = response.file!.path;
          });
          await ref.read(userProfileProvider.notifier).setAvatarImagePath(response.file!.path);
        }
      } catch (e) {
        debugPrint("Retrieve lost data error: $e");
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nameCtrl.dispose();
    _headlineCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _collegeCtrl.dispose();
    _bioCtrl.dispose();
    _customSkillCtrl.dispose();
    _salaryCtrl.dispose();
    super.dispose();
  }

  void _addSkill(String skill) {
    final trimmed = skill.trim();
    if (trimmed.isNotEmpty && !_userSkills.contains(trimmed)) {
      setState(() {
        _userSkills.add(trimmed);
        _customSkillCtrl.clear();
      });
    }
  }

  void _removeSkill(String skill) {
    setState(() {
      _userSkills.remove(skill);
    });
  }

  void _updateSalaryFromText(String val) {
    final parsed = double.tryParse(val);
    if (parsed != null) {
      setState(() {
        _expectedSalary = parsed.clamp(4.0, 50.0);
      });
    }
  }

  void _updateSalaryFromSlider(double val) {
    setState(() {
      _expectedSalary = val;
      _salaryCtrl.text = val.round().toString();
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
        requestFullMetadata: false,
      );
      if (image != null) {
        setState(() {
          _avatarImagePath = image.path;
        });
        await ref.read(userProfileProvider.notifier).setAvatarImagePath(image.path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Profile photo updated!'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e, stack) {
      debugPrint("IMAGE PICKER ERROR: $e\n$stack");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not pick photo: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _pickResume() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = result.files.single;
        await ref.read(userProfileProvider.notifier).setResume(
          fileName: file.name,
          filePath: file.path!,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Resume "${file.name}" uploaded successfully!'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking resume: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _showAvatarPickerSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.credDarkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.credDarkBorder : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Change Profile Photo / Avatar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose a photo source or pick from tech avatar badges.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),

              // Source Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: isDark ? AppColors.credDarkBorder : const Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 20),
                      label: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _pickImage(ImageSource.camera);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: isDark ? AppColors.credDarkBorder : const Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.photo_library_rounded, color: Color(0xFF0EA5E9), size: 20),
                      label: const Text('Choose Gallery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _pickImage(ImageSource.gallery);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Text(
                'Or Select Preset Badge Avatar:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 14),

              // Avatar Badge Presets
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _presetAvatars.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  final isSelected = _selectedAvatarIndex == idx;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedAvatarIndex = idx;
                        _avatarInitials = item['initials'] as String;
                        _avatarBgColor = item['color'] as Color;
                        _avatarIcon = item['icon'] as IconData;
                        _avatarImagePath = null;
                      });
                      setSheetState(() {});
                      Navigator.pop(ctx);
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: item['color'] as Color,
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 3)
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: (item['color'] as Color).withValues(alpha: 0.4),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(item['icon'] as IconData, color: Colors.white, size: 24),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item['initials'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      
      // Update Riverpod Provider state
      ref.read(userProfileProvider.notifier).updateProfile(
        name: _nameCtrl.text.trim(),
        college: _collegeCtrl.text.trim(),
        targetRole: _headlineCtrl.text.trim(),
        avatarInitials: _avatarInitials,
        avatarImagePath: _avatarImagePath,
      );
      ref.read(userProfileProvider.notifier).updateSkills(_userSkills);

      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Profile updated successfully!', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.credDarkBackground : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.credDarkCard : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : AppColors.onSurface, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Edit Profile & Skills',
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.onSurface,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
          ),
        ],
      ),
      body: RawScrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        thickness: 6,
        radius: const Radius.circular(10),
        thumbColor: AppColors.primary.withValues(alpha: 0.7),
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar Picker
                Center(
                  child: GestureDetector(
                    onTap: _showAvatarPickerSheet,
                    child: Stack(
                      children: [
                        Container(
                          width: 104,
                          height: 104,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _avatarBgColor,
                            gradient: _selectedAvatarIndex == 0
                                ? AppColors.primaryGradient
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: _avatarBgColor.withValues(alpha: 0.35),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: _avatarImagePath != null
                                ? ClipOval(
                                    child: kIsWeb
                                        ? Image.network(
                                            _avatarImagePath!,
                                            width: 104,
                                            height: 104,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Text(_avatarInitials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 34)),
                                          )
                                        : Image.file(
                                            File(_avatarImagePath!),
                                            width: 104,
                                            height: 104,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Text(_avatarInitials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 34)),
                                          ),
                                  )
                                : _selectedAvatarIndex == 0
                                    ? Text(
                                        _avatarInitials,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 34,
                                        ),
                                      )
                                    : Icon(_avatarIcon, color: Colors.white, size: 46),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? AppColors.credDarkBackground : Colors.white,
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Resume Upload Section
                _buildResumeSection(isDark),

                // Section 1: Personal Details
                _buildSectionTitle('Personal Information', isDark),
                const SizedBox(height: 12),

                _buildTextField(
                  controller: _nameCtrl,
                  label: 'Full Name',
                  icon: Icons.person_outline_rounded,
                  isDark: isDark,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Full name is required';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                _buildTextField(
                  controller: _headlineCtrl,
                  label: 'Professional Headline',
                  icon: Icons.badge_outlined,
                  isDark: isDark,
                ),
                const SizedBox(height: 14),

                _buildTextField(
                  controller: _emailCtrl,
                  label: 'Email Address',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  isDark: isDark,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Email address is required';
                    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(val.trim())) return 'Enter a valid email address';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                _buildTextField(
                  controller: _phoneCtrl,
                  label: 'Phone Number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  isDark: isDark,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Phone number is required';
                    final cleanPhone = val.replaceAll(RegExp(r'[\s\-\+]'), '');
                    if (cleanPhone.length < 10 || !RegExp(r'^[0-9]+$').hasMatch(cleanPhone)) {
                      return 'Enter a valid 10-digit phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Section 2: Education
                _buildSectionTitle('Education & Institute', isDark),
                const SizedBox(height: 12),

                _buildTextField(
                  controller: _collegeCtrl,
                  label: 'College / Institute',
                  icon: Icons.account_balance_outlined,
                  isDark: isDark,
                ),
                const SizedBox(height: 14),

                // Graduation Year Dropdown with Validation
                DropdownButtonFormField<String>(
                  value: _selectedGradYear,
                  dropdownColor: isDark ? AppColors.credDarkCard : Colors.white,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.onSurface,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Graduation Year',
                    labelStyle: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : AppColors.outline,
                    ),
                    prefixIcon: Icon(Icons.calendar_today_rounded,
                        size: 18, color: isDark ? const Color(0xFF94A3B8) : AppColors.outline),
                    filled: true,
                    fillColor: isDark ? AppColors.credDarkCard : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                          color: isDark ? AppColors.credDarkBorder : const Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                          color: isDark ? AppColors.credDarkBorder : const Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                  items: ['2024', '2025', '2026', '2027', '2028']
                      .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedGradYear = val),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Please select graduation year';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Section 3: Bio
                _buildSectionTitle('About / Summary', isDark),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _bioCtrl,
                  maxLines: 3,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white : AppColors.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Tell recruiters about your passions, achievements, and goals...',
                    hintStyle: TextStyle(
                        fontSize: 13,
                        color: isDark ? const Color(0xFF64748B) : AppColors.outline),
                    filled: true,
                    fillColor: isDark ? AppColors.credDarkCard : Colors.white,
                    contentPadding: const EdgeInsets.all(16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                          color: isDark ? AppColors.credDarkBorder : const Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                          color: isDark ? AppColors.credDarkBorder : const Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Section 4: Technical Skills Editor
                _buildSectionTitle('Technical Skills & Tools', isDark),
                const SizedBox(height: 8),
                Text(
                  'Add or remove skills to customize job matches & AI interview questions.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),

                // Skills Chips Box
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _userSkills.map((s) {
                    return Chip(
                      label: Text(s,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                      backgroundColor: AppColors.primary,
                      deleteIcon: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                      onDeleted: () => _removeSkill(s),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                // Add Custom Skill Input
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customSkillCtrl,
                        style: TextStyle(
                            fontSize: 13, color: isDark ? Colors.white : AppColors.onSurface),
                        decoration: InputDecoration(
                          hintText: 'Add new skill (e.g. Docker, Redis)',
                          hintStyle: TextStyle(
                              fontSize: 12,
                              color: isDark ? const Color(0xFF64748B) : AppColors.outline),
                          filled: true,
                          fillColor: isDark ? AppColors.credDarkCard : Colors.white,
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(100),
                            borderSide: BorderSide(
                                color: isDark ? AppColors.credDarkBorder : const Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(100),
                            borderSide: BorderSide(
                                color: isDark ? AppColors.credDarkBorder : const Color(0xFFE2E8F0)),
                          ),
                        ),
                        onSubmitted: _addSkill,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: const CircleBorder(),
                      ),
                      icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                      onPressed: () => _addSkill(_customSkillCtrl.text),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Section 5: Career Preferences
                _buildSectionTitle('Career & Salary Preferences', isDark),
                const SizedBox(height: 14),

                // Job Type Tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: ['Full-Time', 'Internship', 'Remote', 'Contract'].map((type) {
                      final isSelected = _selectedJobType == type;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedJobType = type),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark ? AppColors.credDarkCard : Colors.white),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark ? AppColors.credDarkBorder : const Color(0xFFE2E8F0)),
                            ),
                          ),
                          child: Text(
                            type,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark
                                      ? const Color(0xFF94A3B8)
                                      : AppColors.onSurfaceVariant),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),

                // Dual Salary Input Box & Interactive Slider
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.credDarkCard : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: isDark ? AppColors.credDarkBorder : const Color(0xFFEEF0F2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Target Annual Package',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : AppColors.onSurface,
                                    )),
                                const SizedBox(height: 2),
                                Text('Drag slider or type exact amount below',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
                                    )),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Direct Editable Salary Text Field
                          SizedBox(
                            width: 100,
                            child: TextFormField(
                              controller: _salaryCtrl,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                              ),
                              decoration: InputDecoration(
                                suffixText: 'LPA',
                                suffixStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                filled: true,
                                fillColor: AppColors.primary.withValues(alpha: 0.1),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onChanged: _updateSalaryFromText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Slider(
                        value: _expectedSalary.clamp(4.0, 50.0),
                        min: 4.0,
                        max: 50.0,
                        divisions: 46,
                        activeColor: AppColors.primary,
                        label: '₹${_expectedSalary.round()} LPA',
                        onChanged: _updateSalaryFromSlider,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _isSaving ? null : _saveProfile,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Save Profile Changes',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResumeSection(bool isDark) {
    final profile = ref.watch(userProfileProvider);
    final hasResume = profile.resumeFileName != null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.credDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.credDarkBorder : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.description_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resume / Curriculum Vitae',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.onSurface,
                      ),
                    ),
                    Text(
                      hasResume ? 'Uploaded & Active' : 'No resume uploaded yet',
                      style: TextStyle(
                        fontSize: 11,
                        color: hasResume ? const Color(0xFF10B981) : (isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (hasResume) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E273A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? const Color(0xFF2A364F) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFEF4444), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.resumeFileName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.onSurface,
                          ),
                        ),
                        if (profile.resumeUploadedAt != null)
                          Text(
                            'Uploaded on ${profile.resumeUploadedAt}',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? const Color(0xFF94A3B8) : AppColors.outline,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                    onPressed: () async {
                      await ref.read(userProfileProvider.notifier).removeResume();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Resume removed'),
                            backgroundColor: Colors.redAccent,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.upload_file_rounded, color: AppColors.primary, size: 18),
                label: const Text('Change Resume (PDF/DOC)', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                onPressed: _pickResume,
              ),
            ),
          ] else ...[
            InkWell(
              onTap: _pickResume,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.cloud_upload_rounded, color: AppColors.primary, size: 28),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Tap to Upload Resume',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Supports PDF, DOC, DOCX files',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: isDark ? Colors.white : AppColors.onSurface,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
        fontSize: 13,
        color: isDark ? Colors.white : AppColors.onSurface,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: 12,
          color: isDark ? const Color(0xFF94A3B8) : AppColors.outline,
        ),
        prefixIcon: Icon(icon,
            size: 18, color: isDark ? const Color(0xFF94A3B8) : AppColors.outline),
        filled: true,
        fillColor: isDark ? AppColors.credDarkCard : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
              color: isDark ? AppColors.credDarkBorder : const Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
              color: isDark ? AppColors.credDarkBorder : const Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}
