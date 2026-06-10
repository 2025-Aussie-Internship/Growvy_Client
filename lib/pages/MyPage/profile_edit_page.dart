import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../styles/colors.dart';
import '../../utils/auto_localize.dart';
import '../../widgets/auto_translate_text.dart';
import '../../widgets/confirm_modal.dart';
import '../../widgets/profile_picker_modal.dart';

/// 프로필 수정 콘텐츠. MyPage 안에 인라인으로 노출되거나 [ProfileEditPage] 안에서 사용.
///
/// 시안과 동일한 디자인:
///   - 상단: 뒤로(< ) + 우측 주황 ✓ 체크
///   - 큰 원형 프로필 사진 + 우하단 회색 ✏️ 편집 동그라미
///   - "Name" / "Gender Pronouns" / "G-mail Address" / "Phone-Number" 까지는 공통
///   - 구직자만: "Home Address" / "Preference" (chip grid) / "Career" / "One Line Introduction"
///   - 구인자만: "Company Name" / "Business Address"
///
/// ✓ 체크 탭 → "Do you want to save the changes?" 확인 모달 → Yes 시 [onApply] 호출.
/// 뒤로(< ) 탭 → 변경사항 무시하고 [onClose] 호출.
class ProfileEditContent extends StatefulWidget {
  const ProfileEditContent({
    super.key,
    required this.profileImages,
    required this.initialProfileIndex,
    this.initialUserName = 'User Name',
    this.initialPronouns = 'She/Her',
    required this.onApply,
    required this.onClose,
  });

  final List<ImageProvider> profileImages;
  final int initialProfileIndex;
  final String initialUserName;
  final String initialPronouns;
  final void Function(Map<String, dynamic> result) onApply;
  final VoidCallback onClose;

  @override
  State<ProfileEditContent> createState() => _ProfileEditContentState();
}

class _ProfileEditContentState extends State<ProfileEditContent> {
  late int _profileIndex;
  late String _pronouns;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _homeAddressController;
  late TextEditingController _careerController;
  late TextEditingController _introController;
  late TextEditingController _companyNameController;
  late TextEditingController _businessAddressController;

  /// 구직자 Preference (관심사) — 다중 선택 가능. 시안의 11개 카테고리.
  final Set<String> _selectedInterestKeys = <String>{'interests.events_festivals'};

  /// 시안의 11개 관심사 (interest_i18n.dart 와 매핑 동일)
  static const List<String> _interestKeys = <String>[
    'interests.hospitality_fb',
    'interests.retail_sales',
    'interests.farm_seasonal',
    'interests.manufacturing',
    'interests.factory_work',
    'interests.cleaning_facilities',
    'interests.construction',
    'interests.logistics_moving',
    'interests.events_festivals',
    'interests.customer_service',
    'interests.other_jobs',
  ];

  static const String _gmail = 'abcdefg@gmail.com';

  @override
  void initState() {
    super.initState();
    _profileIndex = widget.initialProfileIndex;
    _pronouns = widget.initialPronouns;
    _nameController = TextEditingController(text: widget.initialUserName);
    _phoneController = TextEditingController();
    _homeAddressController = TextEditingController();
    _careerController = TextEditingController();
    _introController = TextEditingController();
    _companyNameController = TextEditingController();
    _businessAddressController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _homeAddressController.dispose();
    _careerController.dispose();
    _introController.dispose();
    _companyNameController.dispose();
    _businessAddressController.dispose();
    super.dispose();
  }

  void _openProfilePicker() {
    ProfilePickerModal.show(
      context,
      profileImages: widget.profileImages,
      onSelected: (index) => setState(() => _profileIndex = index),
    );
  }

  Future<void> _onSavePressed() async {
    final confirmed = await ConfirmModal.show<bool>(
      context: context,
      message: 'Do you want to\nsave the changes?',
      onCancel: () => Navigator.pop(context, false),
      onAccept: () => Navigator.pop(context, true),
    );
    if (confirmed != true || !mounted) return;
    widget.onApply({
      'profileIndex': _profileIndex,
      'userName': _nameController.text.isEmpty ? 'User Name' : _nameController.text,
      'pronouns': _pronouns,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ──────────────────────── 상단 헤더 ────────────────────────
        SizedBox(
          height: 48,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                IconButton(
                  onPressed: widget.onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  icon: SvgPicture.asset(
                    'assets/icon/back_icon.svg',
                    width: 28,
                    height: 28,
                    fit: BoxFit.contain,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _onSavePressed,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  icon: const Icon(
                    Icons.check_rounded,
                    color: AppColors.mainColor,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ──────────────────────── 프로필 사진 ────────────────────────
        Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: widget.profileImages[_profileIndex],
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: _openProfilePicker,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD1D1D1),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(7),
                    child: SvgPicture.asset(
                      'assets/icon/profile_edit_icon.svg',
                      fit: BoxFit.contain,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // ──────────────────────── 폼 ────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Name'),
              _textField(_nameController, hint: 'Name'),
              const SizedBox(height: 18),
              _label('Gender Pronouns'),
              _pronounsDropdown(),
              const SizedBox(height: 18),
              _label('G-mail Address'),
              _disabledField(_gmail),
              const SizedBox(height: 18),
              _label('Phone-Number'),
              _textField(
                _phoneController,
                hint: '00 0000 0000',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 18),
              // 구직자/구인자 분기
              Obx(() {
                final isEmployer = AuthController.to.isEmployer.value;
                if (isEmployer) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Company Name'),
                      _textField(_companyNameController, hint: "Sadie's Hot Pot"),
                      const SizedBox(height: 18),
                      _label('Business Address'),
                      _textField(
                        _businessAddressController,
                        hint: 'Unit 5, 123 George Street',
                      ),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Home Address'),
                    _textField(
                      _homeAddressController,
                      hint: 'Unit 5, 123 George Street',
                    ),
                    const SizedBox(height: 18),
                    _label('Preference'),
                    _buildInterestGrid(),
                    const SizedBox(height: 18),
                    _label('Career'),
                    _textField(_careerController, hint: 'blahblah'),
                    const SizedBox(height: 18),
                    _label('One Line Introduction'),
                    _textField(
                      _introController,
                      hint:
                          "I like to help people! And I'm trying to improve my social skills :)",
                      maxLines: 3,
                    ),
                  ],
                );
              }),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ],
    );
  }

  // ─── 공통 빌더들 ──────────────────────────────────────────────

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: AutoTranslateText(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      );

  Widget _textField(
    TextEditingController controller, {
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: Colors.black),
      decoration: InputDecoration(
        hintText: autoLocalize(context, hint),
        hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFEFEFEF),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFBDBDBD)),
        ),
      ),
    );
  }

  Widget _disabledField(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFEF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
      ),
    );
  }

  Widget _pronounsDropdown() {
    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        canvasColor: Colors.white,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFEFEFEF),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _pronouns,
            isExpanded: true,
            dropdownColor: Colors.white,
            icon: Icon(Icons.expand_more,
                color: Colors.grey[700], size: 22),
            style: const TextStyle(fontSize: 14, color: Colors.black),
            hint: Text(
              autoLocalize(context, 'Gender Pronouns'),
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
            items: const ['She/Her', 'He/Him', 'They/Them']
                .map(
                  (s) => DropdownMenuItem<String>(
                    value: s,
                    child: AutoTranslateText(
                      s,
                      style: const TextStyle(fontSize: 14, color: Colors.black),
                    ),
                  ),
                )
                .toList(),
            selectedItemBuilder: (ctx) => ['She/Her', 'He/Him', 'They/Them']
                .map(
                  (s) => Align(
                    alignment: Alignment.centerLeft,
                    child: AutoTranslateText(
                      s,
                      style: const TextStyle(fontSize: 14, color: Colors.black),
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _pronouns = v);
            },
          ),
        ),
      ),
    );
  }

  /// 시안의 2열 chip grid. 선택된 항목은 주황 outline + 옅은 주황 background.
  Widget _buildInterestGrid() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final key in _interestKeys)
          _InterestChip(
            label: autoLocalize(context, _labelFromKey(key)),
            selected: _selectedInterestKeys.contains(key),
            onTap: () {
              setState(() {
                if (_selectedInterestKeys.contains(key)) {
                  _selectedInterestKeys.remove(key);
                } else {
                  _selectedInterestKeys.add(key);
                }
              });
            },
            // 2열 grid 처럼 보이도록 화면 가로의 절반 -10/2 폭으로 고정.
            width: (MediaQuery.of(context).size.width - 20 * 2 - 10) / 2,
          ),
      ],
    );
  }

  static String _labelFromKey(String key) {
    // interests.events_festivals → 'Events & Festivals' 같은 영어 라벨로 fallback.
    // autoLocalize 가 한국어/영어 자동 처리하므로 여기에선 영어 원본만 잘 넘기면 됨.
    switch (key) {
      case 'interests.hospitality_fb':
        return 'Hospitality & F&B';
      case 'interests.retail_sales':
        return 'Retail & Sales';
      case 'interests.farm_seasonal':
        return 'Farm & Seasonal';
      case 'interests.manufacturing':
        return 'Manufacturing';
      case 'interests.factory_work':
        return 'Factory Work';
      case 'interests.cleaning_facilities':
        return 'Cleaning & Facilities';
      case 'interests.construction':
        return 'Construction';
      case 'interests.logistics_moving':
        return 'Logistics & Moving';
      case 'interests.events_festivals':
        return 'Events & Festivals';
      case 'interests.customer_service':
        return 'Customer Service';
      case 'interests.other_jobs':
        return 'Other Jobs';
    }
    return key;
  }
}

/// 시안의 주황/회색 outline chip.
class _InterestChip extends StatelessWidget {
  const _InterestChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.width,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFFFE5DA) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AppColors.mainColor
                  : const Color(0xFFD9D9D9),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: selected ? AppColors.mainColor : Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

/// 프로필 수정 페이지 (Navigator.push 진입용). MyPage 의 인라인 편집과 별개.
class ProfileEditPage extends StatelessWidget {
  const ProfileEditPage({
    super.key,
    required this.profileImages,
    required this.initialProfileIndex,
    this.initialUserName = 'User Name',
    this.initialPronouns = 'She/Her',
  });

  final List<ImageProvider> profileImages;
  final int initialProfileIndex;
  final String initialUserName;
  final String initialPronouns;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: true,
        bottom: false,
        child: SingleChildScrollView(
          child: ProfileEditContent(
            profileImages: profileImages,
            initialProfileIndex: initialProfileIndex,
            initialUserName: initialUserName,
            initialPronouns: initialPronouns,
            onApply: (result) => Navigator.pop(context, result),
            onClose: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }
}
