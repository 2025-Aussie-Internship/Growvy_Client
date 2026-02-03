import 'package:flutter/material.dart';

/// 모달 전용 테마. 페이퍼로지(Paperlogy) 폰트 적용.
ThemeData modalTheme(BuildContext context) {
  final base = Theme.of(context);
  return base.copyWith(
    textTheme: base.textTheme.apply(fontFamily: 'Paperlogy'),
    primaryTextTheme: base.primaryTextTheme.apply(fontFamily: 'Paperlogy'),
  );
}
