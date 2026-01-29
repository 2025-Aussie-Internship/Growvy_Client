/// Note 목록 아이템 모델
class NoteItem {
  final String title;
  final String employer;
  final String dDay;
  final String tag;
  final bool hasContent;
  final List<String> photos;
  final bool? isDraft;

  const NoteItem({
    required this.title,
    required this.employer,
    required this.dDay,
    required this.tag,
    required this.hasContent,
    this.photos = const [],
    this.isDraft,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'employer': employer,
        'dDay': dDay,
        'tag': tag,
        'hasContent': hasContent,
        'photos': photos,
        if (isDraft != null) 'isDraft': isDraft,
      };

  factory NoteItem.fromJson(Map<String, dynamic> json) {
    return NoteItem(
      title: json['title'] as String,
      employer: json['employer'] as String,
      dDay: json['dDay'] as String,
      tag: json['tag'] as String,
      hasContent: json['hasContent'] as bool? ?? false,
      photos: json['photos'] != null
          ? List<String>.from(json['photos'] as List)
          : [],
      isDraft: json['isDraft'] as bool?,
    );
  }
}
