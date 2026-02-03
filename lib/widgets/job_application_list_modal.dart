import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../styles/modal_theme.dart';

/// 구인자용 Job Application List 모달. 아래에서 위로 슬라이드, 신청한 구직자 중 선택 후 Accept로 새 채팅방 생성.
class JobApplicationListModal {
  static void show(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Theme(
        data: modalTheme(context),
        child: const _JobApplicationListContent(),
      ),
    );
  }
}

class _ApplicantItem {
  final String name;
  final String profileImagePath;

  _ApplicantItem({
    required this.name,
    required this.profileImagePath,
  });
}

class _JobApplicationListContent extends StatefulWidget {
  const _JobApplicationListContent();

  @override
  State<_JobApplicationListContent> createState() =>
      _JobApplicationListContentState();
}

class _JobApplicationListContentState extends State<_JobApplicationListContent> {
  static final List<_ApplicantItem> _dummyApplicants = [
    _ApplicantItem(name: 'User Name', profileImagePath: 'assets/image/test_profile1.png'),
    _ApplicantItem(name: 'User Name', profileImagePath: 'assets/image/test_profile2.png'),
    _ApplicantItem(name: 'User Name', profileImagePath: 'assets/image/test_profile3.png'),
    _ApplicantItem(name: 'User Name', profileImagePath: 'assets/image/test_profile4.png'),
    _ApplicantItem(name: 'User Name', profileImagePath: 'assets/image/test_profile5.png'),
    _ApplicantItem(name: 'User Name', profileImagePath: 'assets/image/test_profile6.png'),
  ];

  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.75;
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            // 드래그 핸들
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Job Application List',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Divider(height: 1, thickness: 1, color: Colors.grey[300]),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                itemCount: _dummyApplicants.length,
                itemBuilder: (context, index) {
                  final applicant = _dummyApplicants[index];
                  final isSelected = _selectedIndex == index;
                  return _buildApplicantTile(index, applicant, isSelected);
                },
              ),
            ),
            Divider(height: 1, thickness: 1, color: const Color(0xFFD9D9D9)),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 358,
                height: 51,
                child: ElevatedButton(
                  onPressed: () {
                    if (_selectedIndex != null) {
                      // TODO: 새 채팅방 생성 후 이동
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFC6340),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(90),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Accept',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicantTile(int index, _ApplicantItem applicant, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey[200],
              backgroundImage: AssetImage(applicant.profileImagePath),
              onBackgroundImageError: (_, __) {},
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    applicant.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: List.generate(5, (i) {
                      final filled = i < 3; // 별 3개 채움
                      return Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: SvgPicture.asset(
                          filled
                              ? 'assets/icon/score_filled_icon.svg'
                              : 'assets/icon/score_not_icon.svg',
                          width: 16,
                          height: 16,
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
                border: Border.all(
                  color: isSelected ? const Color(0xFFFC6340) : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Color(0xFFFC6340))
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
