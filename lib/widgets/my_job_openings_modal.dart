import 'package:flutter/material.dart';
import '../styles/modal_theme.dart';

/// 구인자: 내 공고 선택 모달. 공고 선택 후 Select 시 해당 공고 지원자 목록(JobApplicationListModal)으로 이어짐.
class MyJobOpeningsModal {
  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required List<Map<String, dynamic>> jobs,
  }) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Theme(
        data: modalTheme(context),
        child: _MyJobOpeningsContent(jobs: jobs),
      ),
    );
  }
}

class _MyJobOpeningsContent extends StatefulWidget {
  const _MyJobOpeningsContent({required this.jobs});

  final List<Map<String, dynamic>> jobs;

  @override
  State<_MyJobOpeningsContent> createState() => _MyJobOpeningsContentState();
}

class _MyJobOpeningsContentState extends State<_MyJobOpeningsContent> {
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
              'My Job Openings',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Divider(height: 1, thickness: 1, color: const Color(0xFFD9D9D9)),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: widget.jobs.length,
                itemBuilder: (context, index) {
                  final job = widget.jobs[index];
                  final isSelected = _selectedIndex == index;
                  return _buildJobCard(index, job, isSelected);
                },
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: SizedBox(
                width: double.infinity,
                height: 51,
                child: ElevatedButton(
                  onPressed: () {
                    if (_selectedIndex != null) {
                      Navigator.of(context).pop(widget.jobs[_selectedIndex!]);
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
                    'Select',
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

  Widget _buildJobCard(int index, Map<String, dynamic> job, bool isSelected) {
    const cardWidth = 358.0;
    const cardHeight = 137.0;
    final title = job['title'] as String? ?? 'Event Staff';
    final body = job['body'] as String? ??
        'Lorem ipsum dolor sit amet consectetur. At id varius facilisis morbi tortor elementum lectus. Nisi adipiscing in hac leo. Ut phasellus tristique lorem porttitor vitae ac. Id pellentesque fermentum in egestas a tortor diam.';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: cardWidth,
          height: cardHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: cardWidth,
                height: cardHeight,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFFC6340) : const Color(0xFFF5F5F5),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        body,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: Color(0xFFB4B4B4),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFC6340),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 16,
                      color: Color(0xFFFC6340),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
