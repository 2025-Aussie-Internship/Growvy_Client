import 'package:flutter/material.dart';
import '../../services/user_service.dart';
import 'note_page.dart';

/// Note 탭: Employer/Seeker 동일한 Note 페이지 표시. write만 타입에 따라 다름.
class NoteTabPage extends StatefulWidget {
  const NoteTabPage({super.key});

  @override
  State<NoteTabPage> createState() => _NoteTabPageState();
}

class _NoteTabPageState extends State<NoteTabPage> {
  bool _isLoading = true;
  bool _isEmployer = false;

  @override
  void initState() {
    super.initState();
    _loadUserType();
  }

  Future<void> _loadUserType() async {
    final isEmployer = await UserService.isEmployer();
    if (mounted) {
      setState(() {
        _isEmployer = isEmployer;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return NotePage(isEmployer: _isEmployer);
  }
}
