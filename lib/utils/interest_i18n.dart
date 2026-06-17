import 'package:easy_localization/easy_localization.dart' hide StringTranslateExtension;
import '../i18n/app_translations.dart';

/// 백엔드가 내려준 interestIds(=관심/설문 답변 id) 를 화면에 표시할 때 쓰는 헬퍼.
///
/// - 회원가입 단계에서 우리가 보내는 id 와 동일한 매핑을 거꾸로 갖고 있다.
///   (SignupDataController._interestIdByLabel 의 역매핑)
/// - 표시는 i18n 키를 [tr] 로 변환해서 사용. 영어/한국어 어떤 locale 이든 자동 대응.
///
/// 사용 예:
/// ```dart
/// final ids = response['interestIds'] as List<int>;
/// final labels = InterestI18n.labelsFromIds(ids);
/// // ['숙박 & 식음료', '실내 (사무실, 카페, 스튜디오)', ...]
/// ```
class InterestI18n {
  InterestI18n._();

  /// 백엔드 id → i18n 키.
  ///
  /// 1~11: INDUSTRY (Choose your interests 분기에서 선택)
  /// 12~30: 설문 답변
  static const Map<int, String> _i18nKeyById = <int, String>{
    // INDUSTRY (1~11)
    1: 'interests.hospitality_fb',
    2: 'interests.retail_sales',
    3: 'interests.farm_seasonal',
    4: 'interests.manufacturing',
    5: 'interests.factory_work',
    6: 'interests.cleaning_facilities',
    7: 'interests.construction',
    8: 'interests.logistics_moving',
    9: 'interests.events_festivals',
    10: 'interests.customer_service',
    11: 'interests.other_jobs',

    // ENERGY_STYLE (12~14)
    12: 'survey_options.thinking_planning',
    13: 'survey_options.hands_on',
    14: 'survey_options.mix_of_both',

    // WORK_ENVIRONMENT (15~17)
    15: 'survey_options.indoors',
    16: 'survey_options.outdoors',
    17: 'survey_options.either_env',

    // SOCIAL_PREFERENCE (18~20)
    18: 'survey_options.people_oriented',
    19: 'survey_options.solo',
    20: 'survey_options.balanced_social',

    // COMFORT_ZONE (21~23)
    21: 'survey_options.new_exciting',
    22: 'survey_options.familiar_stable',
    23: 'survey_options.open_anything',

    // MAIN_GOAL (24~27)
    24: 'survey_options.earn_money',
    25: 'survey_options.new_experience',
    26: 'survey_options.build_career',
    27: 'survey_options.recharge',

    // WORK_PACE (28~30)
    28: 'survey_options.fast_paced',
    29: 'survey_options.relaxed_steady',
    30: 'survey_options.depends_day',
  };

  /// 단일 id 를 현재 locale 의 라벨로 변환. 매핑이 없으면 null.
  static String? labelForId(int id) {
    final key = _i18nKeyById[id];
    return key == null ? null : key.tr();
  }

  /// 여러 id 를 현재 locale 의 라벨 목록으로 변환. 매핑이 없는 id 는 건너뛴다.
  static List<String> labelsFromIds(Iterable<int> ids) {
    return [
      for (final id in ids)
        if (_i18nKeyById[id] != null) _i18nKeyById[id]!.tr(),
    ];
  }

  /// 백엔드 interest id → i18n 키 목록 (UI prefill 용).
  static List<String> keysFromIds(Iterable<int> ids) {
    return [
      for (final id in ids)
        if (_i18nKeyById[id] != null) _i18nKeyById[id]!,
    ];
  }
}

/// 'MALE' / 'FEMALE' enum 을 현재 locale 의 라벨로 변환.
String genderLabel(String? raw) {
  switch (raw?.toUpperCase()) {
    case 'MALE':
      return 'signup.male'.tr();
    case 'FEMALE':
      return 'signup.female'.tr();
    default:
      return '';
  }
}
