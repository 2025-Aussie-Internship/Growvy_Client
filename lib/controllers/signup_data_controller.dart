import 'package:get/get.dart';

import '../services/signup_repository.dart';

/// 회원가입 단계마다 사용자가 입력한 값을 한 곳에 누적했다가
/// 마지막 SignupCompletePage 에서 한 번에 서버(DB)로 보낼 수 있게 해 주는 컨트롤러.
///
/// [toPayload] 가 반환하는 JSON 형식은 백엔드 API 스펙에 맞춰져 있다.
/// - seeker: name, email, birthDate, gender, phone, profileImageId, bannerImageId,
///           homeAddress, career, bio, interestIds[]
/// - employer: name, email, birthDate, gender, phone, profileImageId, bannerImageId,
///             companyName, businessAddress
///
/// [interestIds] 는 "Choose your interests" 에서 선택한 INDUSTRY id 와
/// "I don't know what I want to do" 설문에서 고른 답변 id 를 하나의 배열로 합쳐서 보낸다.
class SignupDataController extends GetxController {
  static SignupDataController get to => Get.find<SignupDataController>();

  // --------------- Google 로그인 단계 ---------------
  String? googleEmail;
  String? googleDisplayName;
  String? googleUid;
  String? googleIdToken;

  // --------------- 직군 선택 ---------------
  /// true: Employer, false: Job seeker, null: 아직 선택 전
  bool? isEmployer;

  // --------------- 공통 정보 (CommonSignUpPage) ---------------
  String? name;
  String? dateOfBirth; // 입력은 YYYY/MM/DD, 전송 시 YYYY-MM-DD 로 변환
  String? phoneNumber;
  String? gender; // 'Male' | 'Female' | null  → 전송 시 'MALE'/'FEMALE'

  // --------------- 프로필 / 배너 이미지 ---------------
  String? profileImageAsset; // 화면용 (현재 선택된 asset path)
  int? profileImageId; // 백엔드 전송용 image id
  int? bannerImageId; // 현재 선택 UI 가 없어 기본 0

  // --------------- Employer 전용 (EmployerSignupPage) ---------------
  String? companyName;
  bool? isSoleProprietorship; // 현재 백엔드 스펙엔 없음. 추후 필요시 사용.
  String? businessAddress;

  // --------------- Seeker 전용 ---------------
  String? homeAddress;
  final List<String> interests = <String>[]; // SeekerInterestPage 라벨
  final Map<int, int> surveyAnswers = <int, int>{}; // SeekerSurveyPage 원답
  final List<String> _surveyAnswerLabels = <String>[]; // 설문 답변 라벨 (id 매핑용)
  String? career; // SeekerCareerPage
  String? introduction; // SeekerCareerPage → 백엔드의 'bio'

  // ---------------- id 매핑 (백엔드 DB 시드 기준) ----------------

  /// 라벨 → id 매핑. INDUSTRY(1~11) + 설문 답변(12~30).
  /// EMPLOYMENT(31~35) 는 회원가입 단계에서 사용하지 않으므로 제외.
  static const Map<String, int> _interestIdByLabel = <String, int>{
    // INDUSTRY (1~11)
    'Hospitality & F&B': 1,
    'Retail & Sales': 2,
    'Farm & Seasonal': 3,
    'Manufacturing': 4,
    'Factory Work': 5,
    'Cleaning & Facilities': 6,
    'Construction': 7,
    'Logistics & Moving': 8,
    'Events & Festivals': 9,
    'Customer Service': 10,
    'Other Jobs': 11,
    
    // ENERGY_STYLE (12~14)
    'I prefer thinking and planning': 12,
    'I prefer hands-on, physical work': 13,
    'A mix of both sounds good': 14,

    // WORK_ENVIRONMENT (15~17)
    'Indoors (office, cafe, studio)': 15,
    'Outdoors (nature, farm, field)': 16,
    "I'm okay with either": 17,

    // SOCIAL_PREFERENCE (18~20)
    'I enjoy meeting and talking to people': 18,
    'I prefer working on my own': 19,
    'A balance of both': 20,

    // COMFORT_ZONE (21~23)
    'Something new and exciting': 21,
    'Something familiar and stable': 22,
    "I'm open to anything": 23,

    // MAIN_GOAL (24~27)
    'Earning money': 24,
    'Gaining new experiences': 25,
    'Building my career': 26,
    'Taking a break and recharging': 27,

    // WORK_PACE (28~30)
    'Fast-paced and active': 28,
    'Relaxed and steady': 29,
    'Depends on the day': 30,
  };

  // ---------------- Setter helpers ----------------

  void setGoogleAuth({
    String? email,
    String? displayName,
    String? uid,
    String? idToken,
  }) {
    if (email != null) googleEmail = email;
    if (displayName != null) googleDisplayName = displayName;
    if (uid != null) googleUid = uid;
    if (idToken != null) googleIdToken = idToken;
  }

  void setUserType(bool employer) {
    isEmployer = employer;
  }

  void setBasicInfo({
    String? name,
    String? dateOfBirth,
    String? phoneNumber,
    String? gender,
  }) {
    if (name != null) this.name = name;
    if (dateOfBirth != null) this.dateOfBirth = dateOfBirth;
    if (phoneNumber != null) this.phoneNumber = phoneNumber;
    if (gender != null) this.gender = gender;
  }

  void setProfileImage(String assetPath, {int? id}) {
    profileImageAsset = assetPath;
    if (id != null) profileImageId = id;
  }

  void setBannerImageId(int id) {
    bannerImageId = id;
  }

  void setEmployerInfo({
    String? companyName,
    bool? isSoleProprietorship,
    String? businessAddress,
  }) {
    if (companyName != null) this.companyName = companyName;
    if (isSoleProprietorship != null) {
      this.isSoleProprietorship = isSoleProprietorship;
    }
    if (businessAddress != null) this.businessAddress = businessAddress;
  }

  void setHomeAddress(String value) {
    homeAddress = value;
  }

  /// "Choose your interests" 분기로 진입했을 때 호출.
  /// seeker 흐름에서는 interests 와 surveyAnswers 가 mutually exclusive 하므로
  /// 이 메서드는 설문 답변을 함께 비운다.
  void setInterests(Iterable<String> values) {
    interests
      ..clear()
      ..addAll(values);
    surveyAnswers.clear();
    _surveyAnswerLabels.clear();
  }

  /// "I don't know what I want to do..." 설문 분기로 진입했을 때 호출.
  /// 마찬가지로 interests 와는 동시에 가질 수 없으므로 그 쪽을 비운다.
  /// 라벨이 있어야 [_interestIdByLabel] 로 id 매핑이 가능하다.
  void setSurveyAnswers(
    Map<int, int> answers, {
    List<String> answerLabels = const [],
  }) {
    surveyAnswers
      ..clear()
      ..addAll(answers);
    _surveyAnswerLabels
      ..clear()
      ..addAll(answerLabels);
    interests.clear();
  }

  /// SeekerInterestPage 에서 설문 분기로 빠지는 순간 호출해서
  /// 그 전에 선택해 둔 industry 칩들을 폐기한다.
  void clearInterests() {
    interests.clear();
  }

  void setCareerInfo({String? career, String? introduction}) {
    if (career != null) this.career = career;
    if (introduction != null) this.introduction = introduction;
  }

  // ---------------- 단계별 validation ----------------
  //
  // 각 페이지의 NextButton 활성/비활성에 그대로 쓰일 수 있도록 컨트롤러 한 곳에서
  // 모아 둔다. 페이지가 setState 콜백을 돌리면 controller 의 값을 그대로 읽어
  // 호출하면 되고, 백엔드 스펙이 바뀌어도 이 메서드들만 수정하면 된다.
  //
  // - 모든 필드는 `trim().isNotEmpty` 기준으로 "입력됨" 판정.
  // - 입력 모드(employer/seeker) 가 정해진 뒤에만 일부 검증이 의미를 가진다.

  /// CommonSignUpPage (이름/생일/전화/성별) 모두 입력됐는지.
  bool isBasicInfoValid() {
    final n = (name ?? '').trim();
    final dob = (dateOfBirth ?? '').trim();
    final phone = (phoneNumber ?? '').trim();
    final g = (gender ?? '').trim();
    // 생일은 YYYY/MM/DD 10글자 모두 채워졌을 때만 유효한 것으로 본다.
    return n.isNotEmpty &&
        phone.isNotEmpty &&
        g.isNotEmpty &&
        dob.length == 10;
  }

  /// EmployerSignupPage 의 필수: 회사명 + 사업장 주소.
  bool isEmployerInfoValid() {
    return (companyName ?? '').trim().isNotEmpty &&
        (businessAddress ?? '').trim().isNotEmpty;
  }

  /// SeekerAddressPage 의 필수: 자택 주소.
  bool isAddressValid() {
    return (homeAddress ?? '').trim().isNotEmpty;
  }

  /// SeekerCareerPage 의 필수: 경력 + 자기소개.
  bool isCareerValid() {
    return (career ?? '').trim().isNotEmpty &&
        (introduction ?? '').trim().isNotEmpty;
  }

  /// SeekerInterestPage 또는 SeekerSurveyPage 중 하나에서 결과가 있어야 한다.
  /// (interests 분기 → 최소 1개, survey 분기 → 6개 모든 질문 답변)
  bool isInterestOrSurveyValid() {
    if (interests.isNotEmpty) return true;
    return _surveyAnswerLabels.length >= 6;
  }

  bool isProfileImagePicked() => profileImageId != null && profileImageId! > 0;

  /// 최종 submit 직전의 종합 검증.
  /// 누락된 필드가 있으면 false 를 반환하고, 누락 필드 라벨은 [missingFields] 로 조회.
  bool isReadyForSubmit() {
    if (isEmployer == null) return false;
    if (!isBasicInfoValid()) return false;
    if (!isProfileImagePicked()) return false;
    if (isEmployer == true) {
      return isEmployerInfoValid();
    }
    return isAddressValid() && isCareerValid() && isInterestOrSurveyValid();
  }

  /// 디버그/안내용: 비어 있는 필수 필드의 사람-읽기용 라벨 리스트.
  /// (예: SignupCompletePage 에서 어떤 필드가 빠졌는지 SnackBar 로 안내할 때 사용)
  List<String> missingFields() {
    final missing = <String>[];
    if (isEmployer == null) missing.add('User type');
    if ((name ?? '').trim().isEmpty) missing.add('Name');
    if ((dateOfBirth ?? '').trim().length != 10) {
      missing.add('Date of birth');
    }
    if ((phoneNumber ?? '').trim().isEmpty) missing.add('Phone number');
    if ((gender ?? '').trim().isEmpty) missing.add('Gender');
    if (!isProfileImagePicked()) missing.add('Profile image');
    if (isEmployer == true) {
      if ((companyName ?? '').trim().isEmpty) missing.add('Company name');
      if ((businessAddress ?? '').trim().isEmpty) {
        missing.add('Business address');
      }
    } else if (isEmployer == false) {
      if ((homeAddress ?? '').trim().isEmpty) missing.add('Home address');
      if ((career ?? '').trim().isEmpty) missing.add('Career');
      if ((introduction ?? '').trim().isEmpty) missing.add('Introduction');
      if (!isInterestOrSurveyValid()) missing.add('Interests or survey');
    }
    return missing;
  }

  // ---------------- 직렬화 ----------------

  /// 백엔드 스펙에 맞춘 최종 payload (평탄한 구조).
  Map<String, dynamic> toPayload() {
    final base = <String, dynamic>{
      'name': name ?? '',
      'email': googleEmail ?? '',
      'birthDate': _formatBirthDate(dateOfBirth),
      'gender': _formatGender(gender),
      'phone': phoneNumber ?? '',
      'profileImageId': profileImageId ?? 0,
      'bannerImageId': bannerImageId ?? 0,
    };
    if (isEmployer == true) {
      base.addAll(<String, dynamic>{
        'companyName': companyName ?? '',
        'businessAddress': businessAddress ?? '',
      });
    } else {
      base.addAll(<String, dynamic>{
        'homeAddress': homeAddress ?? '',
        'career': career ?? '',
        'bio': introduction ?? '',
        'interestIds': _buildInterestIds(),
      });
    }
    return base;
  }

  /// seeker 분기 결과를 단일 [interestIds] 배열로 변환한다.
  /// - "Choose your interests" 를 거쳤다면 1~11 의 INDUSTRY id 만,
  /// - 설문을 거쳤다면 12~ 의 답변 id 만 들어간다.
  /// 두 분기는 mutually exclusive 라서 둘 중 채워진 쪽을 우선 사용한다.
  List<int> _buildInterestIds() {
    final source = _surveyAnswerLabels.isNotEmpty
        ? _surveyAnswerLabels
        : interests;
    final ids = <int>{};
    for (final label in source) {
      final id = _interestIdByLabel[label];
      if (id != null) ids.add(id);
    }
    return ids.toList(growable: false);
  }

  /// 'YYYY/MM/DD' → 'YYYY-MM-DD'. 잘못된 입력이면 빈 문자열.
  String _formatBirthDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    return raw.replaceAll('/', '-');
  }

  /// 'Male' → 'MALE', 'Female' → 'FEMALE'.
  String _formatGender(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    return raw.toUpperCase();
  }

  /// [toPayload] 의 alias. 백엔드가 받자마자 DB users 테이블 한 행으로
  /// insert 할 수 있는 평탄한 Map 임을 호출 측에 분명히 하기 위해 별도 이름을 둠.
  ///
  /// SQL 비유:
  /// ```sql
  /// INSERT INTO users (name, email, birth_date, gender, phone,
  ///                    profile_image_id, banner_image_id,
  ///                    home_address, career, bio, interest_ids,        -- seeker
  ///                    company_name, business_address)                 -- employer
  /// VALUES (:name, :email, :birthDate, :gender, :phone, ...);
  /// ```
  Map<String, dynamic> toDbRow() => toPayload();

  /// 수집된 모든 값을 디버그/로깅용 한 줄짜리 문자열로 직렬화.
  /// (실제로는 개인정보가 섞이므로 release 빌드에서 호출 금지)
  String describeForDebug() {
    final p = toPayload();
    final keys = p.keys.toList()..sort();
    return keys.map((k) => '$k=${p[k]}').join(' | ');
  }

  /// 수집한 페이로드를 백엔드로 한 번에 전송한다.
  ///
  /// 실제 API 호출은 [SignupRepository] 가 담당하며, `API_ENABLED` 가
  /// false 인 동안은 안전한 stub 으로 동작 (UI 흐름이 멈추지 않게).
  ///
  /// [isReadyForSubmit] 가 false 일 때는 호출하지 말 것을 권장한다 —
  /// 호출 자체는 막지 않지만, 누락된 필드는 빈 문자열/0 등으로 전송된다.
  ///
  /// 백엔드 응답으로 생성된 user JSON 을 반환 (없으면 빈 map).
  Future<Map<String, dynamic>> submitToBackend() async {
    return SignupRepository.submit(
      isEmployer: isEmployer == true,
      payload: toPayload(),
    );
  }

  /// 다음 회원가입 시도를 위해 누적된 값을 초기화한다.
  void reset() {
    googleEmail = null;
    googleDisplayName = null;
    googleUid = null;
    googleIdToken = null;
    isEmployer = null;
    name = null;
    dateOfBirth = null;
    phoneNumber = null;
    gender = null;
    profileImageAsset = null;
    profileImageId = null;
    bannerImageId = null;
    companyName = null;
    isSoleProprietorship = null;
    businessAddress = null;
    homeAddress = null;
    interests.clear();
    surveyAnswers.clear();
    _surveyAnswerLabels.clear();
    career = null;
    introduction = null;
  }
}
