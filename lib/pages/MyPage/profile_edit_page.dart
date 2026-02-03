import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../styles/colors.dart';
import '../../widgets/profile_picker_modal.dart';
import '../../widgets/banner_color_picker_modal.dart';

/// 프로필 수정 콘텐츠. 페이지 또는 모달 시트에서 공용.
/// [onApply] 호출 시 현재 값으로 부모가 닫기 처리.
class ProfileEditContent extends StatefulWidget {
  const ProfileEditContent({
    super.key,
    required this.profileImages,
    required this.initialProfileIndex,
    required this.initialBannerColor,
    this.initialUserName = 'My Name',
    this.initialPronouns = 'She/Her',
    required this.onApply,
    this.leadingIcon = 'back',
  });

  final List<ImageProvider> profileImages;
  final int initialProfileIndex;
  final Color initialBannerColor;
  final String initialUserName;
  final String initialPronouns;
  final void Function(Map<String, dynamic> result) onApply;
  /// 'back' = 뒤로가기 아이콘, 'close' = X 닫기 아이콘
  final String leadingIcon;

  @override
  State<ProfileEditContent> createState() => _ProfileEditContentState();
}

class _ProfileEditContentState extends State<ProfileEditContent> {
  late int _profileIndex;
  late Color _bannerColor;
  late String _pronouns;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _profileIndex = widget.initialProfileIndex;
    _bannerColor = widget.initialBannerColor;
    _pronouns = widget.initialPronouns;
    _nameController = TextEditingController(text: widget.initialUserName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onProfileTap() {
    ProfilePickerModal.show(
      context,
      profileImages: widget.profileImages,
      onSelected: (index) => setState(() => _profileIndex = index),
    );
  }

  void _onBannerTap() async {
    final color = await BannerColorPickerModal.show(context, initialColor: _bannerColor);
    if (color != null && mounted) setState(() => _bannerColor = color);
  }

  void _applyAndClose() {
    widget.onApply({
      'profileIndex': _profileIndex,
      'bannerColor': _bannerColor,
      'userName': _nameController.text.isEmpty ? 'My Name' : _nameController.text,
      'pronouns': _pronouns,
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 56,
                width: double.infinity,
                color: _bannerColor,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: GestureDetector(
                        onTap: _applyAndClose,
                        child: widget.leadingIcon == 'close'
                            ? Icon(Icons.close, size: 28, color: Colors.grey[800])
                            : SvgPicture.asset(
                                'assets/icon/back_icon.svg',
                                width: 32,
                                height: 32,
                                fit: BoxFit.contain,
                              ),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _onProfileTap,
                      child: const Text(
                        'Profile',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Container(width: 1, height: 18, color: Colors.white),
                    TextButton(
                      onPressed: _onBannerTap,
                      child: const Text(
                        'Banner',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
              ),
              Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 80,
                    width: double.infinity,
                    color: _bannerColor,
                  ),
                  Positioned(
                    top: 20,
                    child: Container(
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
                  ),
                ],
              ),
              const SizedBox(height: 80),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 59,
                        child: TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: 'Enter My Name',
                            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                            filled: true,
                            fillColor: const Color(0xFFFAFAFA),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFBDBDBD), width: 1),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFBDBDBD), width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFBDBDBD), width: 1),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 59,
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            colorScheme: Theme.of(context).colorScheme.copyWith(
                              primary: Colors.grey,
                              surface: Colors.white,
                            ),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _pronouns,
                            isExpanded: true,
                            dropdownColor: Colors.white,
                            icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600], size: 24),
                            decoration: InputDecoration(
                              labelText: 'Gender Pronouns',
                              labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                              filled: true,
                              fillColor: const Color(0xFFFAFAFA),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFBDBDBD), width: 1),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFBDBDBD), width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFBDBDBD), width: 1),
                              ),
                            ),
                            selectedItemBuilder: (context) => ['She/Her', 'He/Him', 'They/Them']
                                .map((s) => Text(s, overflow: TextOverflow.ellipsis))
                                .toList(),
                            items: ['She/Her', 'He/Him', 'They/Them']
                                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _pronouns = v);
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Text(
                  'Account',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                _buildAccountRow('Your G-mail Address'),
                _buildAccountRow('*********'),
                _buildAccountRow('Phone Number'),
                _buildAccountRow('Home/Company Address'),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountRow(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFBDBDBD), width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: AppColors.mainColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: SvgPicture.asset(
                'assets/icon/profile_edit_icon.svg',
                width: 11,
                height: 11,
                fit: BoxFit.contain,
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 프로필 수정 페이지. 상단 Profile/Banner 버튼으로 프로필·배너 선택 모달.
class ProfileEditPage extends StatelessWidget {
  const ProfileEditPage({
    super.key,
    required this.profileImages,
    required this.initialProfileIndex,
    required this.initialBannerColor,
    this.initialUserName = 'My Name',
    this.initialPronouns = 'She/Her',
  });

  final List<ImageProvider> profileImages;
  final int initialProfileIndex;
  final Color initialBannerColor;
  final String initialUserName;
  final String initialPronouns;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0.5,
          centerTitle: true,
          title: SvgPicture.asset('assets/icon/logo_orange.svg', height: 36),
          leadingWidth: 0,
          leading: const SizedBox.shrink(),
        ),
      ),
      body: ProfileEditContent(
        profileImages: profileImages,
        initialProfileIndex: initialProfileIndex,
        initialBannerColor: initialBannerColor,
        initialUserName: initialUserName,
        initialPronouns: initialPronouns,
        leadingIcon: 'back',
        onApply: (result) => Navigator.pop(context, result),
      ),
    );
  }
}
