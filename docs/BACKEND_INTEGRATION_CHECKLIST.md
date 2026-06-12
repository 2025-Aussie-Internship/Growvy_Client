# 백엔드 ↔ 프론트엔드 연동 체크리스트

작성일: 2026-06-11
대상: Flutter 클라이언트(`growvy_client`) ↔ REST API + DB

> 이 문서는 백엔드 팀이 "API 만 만들어 주면 프론트는 바로 붙는" 상태가 되도록,
> 클라이언트 쪽에서 미리 깔아 둔 구조와 백엔드 쪽에서 채워 줘야 하는 항목을 정리한 체크리스트입니다.

---

## 1. 전체 데이터 흐름 (한눈에 보기)

```
[Splash]
  └─ AppTranslations.init()  (사전 로딩)
  └─ EasyLocalization.ensureInitialized()
  └─ Firebase.initializeApp()
  └─ UserService.init()       (SharedPreferences)
  └─ InitialBinding
       ├─ AuthController         (사용자 타입: employer/seeker)
       ├─ SignupDataController   (회원가입 단계별 입력 누적)
       └─ UserProfileController  (로그인 사용자 프로필 single SoT)
             └─ loadFromCache()  ← SharedPreferences 캐시 복원

[SignUp: Google 로그인]
  └─ GoogleSignIn → Firebase signInWithCredential
  └─ user.getIdToken()
       ├─ TokenStorage.saveFirebaseIdToken(...)  (Keychain/Keystore)
       └─ AuthRepository.exchangeFirebaseTokenForAccess(...)  ← (TODO) 백엔드 토큰 교환
  └─ SignupDataController.setGoogleAuth(...)

[가입 흐름: Are you / 정보입력 / 프로필 / 관심사 / 설문 / 완료]
  └─ 각 단계 입력을 SignupDataController 에 누적
  └─ ProfilePickerPage 에서 사진 선택 시
       SignupDataController.setProfileImage(asset, id)

[가입 완료 → SignupCompletePage]
  └─ signupData.submitToBackend()
       └─ SignupRepository.submit({isEmployer, payload})
             └─ ApiClient.post('/api/users/seeker' or '/api/users/employer')
                    Authorization: Bearer <Firebase or backend access token>
  └─ UserProfileController.hydrateFromSignup(signupData)
       └─ UserProfile 모델 생성 + UserProfileCache.save(...)
  └─ (서버 응답 있으면) profile.value = UserProfile.fromJson(serverUser)
  └─ signupData.reset()  ← 누적값 초기화
  └─ Get.offAll(MainPage)

[MainPage 사용 중]
  └─ MyPage / NotePage 등이 UserProfileController.profile (Obx) 를 구독
       → 프로필 사진/이름/직군 등이 reactive 갱신

[ProfileEdit 저장]
  └─ ProfileEditContent.onApply(result)
  └─ MyPage._applyProfileEdit:
       └─ UserProfileController.applyEdit(...)  ← 즉시 UI 갱신 + 캐시 저장
       └─ (TODO) UserRepository.updateMe(profile.toJson())  ← PATCH /api/users/me

[로그아웃]
  └─ AuthController.clearUserType()
  └─ UserProfileController.clear()
  └─ AuthRepository.signOut()
       ├─ FirebaseAuth.signOut()
       └─ TokenStorage.clearAll()
```

---

## 2. 백엔드가 만들어 줘야 하는 API 명세 (요청)

베이스: `.env` 의 `API_BASE_URL` (예: `https://api.growvy.example.com`).

### 2.1 인증

- [ ] **`POST /api/auth/firebase`**
  - Body: `{ "idToken": "<Firebase ID Token>" }`
  - Response 200:
    ```json
    {
      "accessToken": "...",
      "refreshToken": "...",
      "expiresInSec": 3600,
      "isNewUser": true,
      "user": { ...UserDto }
    }
    ```
  - 신규 사용자면 `isNewUser=true` + `user=null`, 기존 사용자면 user 포함.

- [ ] **`POST /api/auth/refresh`**
  - Body: `{ "refreshToken": "..." }`
  - Response: `{ "accessToken": "...", "expiresInSec": 3600 }`

### 2.2 회원가입

- [ ] **`POST /api/users/seeker`** (Auth: Bearer Firebase or backend token)
  - Body:
    ```json
    {
      "name": "string",
      "email": "string",
      "birthDate": "YYYY-MM-DD",
      "gender": "MALE | FEMALE",
      "phone": "string",
      "profileImageId": 1,
      "bannerImageId": 0,
      "homeAddress": "string",
      "career": "string",
      "bio": "string",
      "interestIds": [1, 2, 12, 17]
    }
    ```
  - Response 201: `UserDto`

- [ ] **`POST /api/users/employer`**
  - Body: 공통 필드 + `{ "companyName": "...", "businessAddress": "..." }`
  - Response 201: `UserDto`

### 2.3 내 정보

- [ ] **`GET /api/users/me`** → `UserDto`
- [ ] **`PATCH /api/users/me`** → `UserDto`
  - Body: 변경할 필드만 (예: `{ "profileImageId": 5, "name": "..." }`)
- [ ] **`POST /api/users/me/profile-image`** (선택: 사진 업로드 시)
  - multipart/form-data → `{ "imageId": int, "url": "..." }`
- [ ] **`DELETE /api/users/me`** (계정 삭제)

### 2.4 도메인 (참고용 — 추후)

- [ ] `GET /api/jobs?...`
- [ ] `POST /api/jobs/{id}/apply`
- [ ] `GET /api/notes?tab=hiring|ongoing|done`
- [ ] `POST /api/reviews`
- ...

### UserDto 표준 형태 (응답 공통)

```json
{
  "id": 123,
  "email": "user@example.com",
  "displayName": "최영희",
  "name": "최영희",
  "gender": "FEMALE",
  "pronouns": "She/Her",
  "phone": "+82 10 0000 0000",
  "birthDate": "1999-01-01",
  "userType": "SEEKER | EMPLOYER",
  "profileImageId": 1,
  "profileImageUrl": "https://...",
  "bannerImageId": 0,
  "companyName": null,
  "businessAddress": null,
  "homeAddress": "...",
  "career": "...",
  "bio": "...",
  "interestIds": [1, 2, 12, 17]
}
```

> 클라이언트는 `UserProfile.fromJson` 이 위 키들을 best-effort 로 매핑합니다.
> 키가 추가/변경되면 `lib/models/user_profile.dart` 의 `fromJson` 만 수정하면 됩니다.

---

## 3. 클라이언트 쪽에서 이미 만들어진 것

| 영역 | 파일 | 역할 |
| --- | --- | --- |
| 환경변수 | `lib/config/env.dart` | `.env` → `Env.apiBaseUrl` 등 |
| 보안 토큰 | `lib/services/token_storage.dart` | Keychain/Keystore 저장 (access/refresh/firebase) |
| HTTP | `lib/services/api_client.dart` | baseUrl + Authorization + 표준 에러 (`ApiException`) |
| 인증 | `lib/services/auth_repository.dart` | Firebase token 갱신 + signOut |
| 회원가입 | `lib/services/signup_repository.dart` | `POST /api/users/(seeker|employer)` |
| 사용자 | `lib/services/user_repository.dart` | `GET/PATCH /api/users/me` |
| 모델 | `lib/models/user_profile.dart` | `UserProfile` + `fromJson` / `toJson` |
| 디스크 캐시 | `lib/services/user_profile_cache.dart` | SharedPreferences |
| 컨트롤러 | `lib/controllers/user_profile_controller.dart` | Reactive 전역 single SoT |
| 가입 누적 | `lib/controllers/signup_data_controller.dart` | 단계별 입력 → `toPayload()` |
| 초기 바인딩 | `lib/bindings/initial_binding.dart` | 부팅 시 컨트롤러 등록 + 캐시 복원 |

---

## 4. 프론트엔드 쪽 남은 TODO (백엔드 endpoint 확정 후)

- [ ] **API 활성화 스위치**
  - `lib/services/signup_repository.dart` 와 `user_repository.dart` 의 상수
    `enabled` 는 `bool.fromEnvironment('API_ENABLED', defaultValue: false)`.
  - 실제 호출 시작: `flutter run --dart-define=API_ENABLED=true`

- [ ] **`.env`** 에 `API_BASE_URL=https://...` 추가 (이미 키만 정의됨).

- [ ] **토큰 교환** (`AuthRepository.exchangeFirebaseTokenForAccess`)
  - 백엔드 `POST /api/auth/firebase` 스펙 확정되면 구현 활성화.
  - 성공 시 `TokenStorage.saveAccessToken / saveRefreshToken` 으로 저장.

- [ ] **401/403 자동 재시도**
  - `ApiClient` 에 `_send` 가 401 받으면
    1) `AuthRepository.refreshIdTokenFromFirebase(force: true)` 또는
       `POST /api/auth/refresh` 로 새 access token 발급,
    2) 원 요청을 한 번만 재시도하는 인터셉터 추가.

- [ ] **프로필 사진 업로드**
  - 현재는 자체 9종 asset (id 1~9). 사용자가 사진을 직접 업로드하려면
    `POST /api/users/me/profile-image` (multipart) 연동 후
    `UserProfile.profileImageUrl` 갱신.

- [ ] **앱 시작 시 서버 sync**
  - `InitialBinding` 의 `profileCtrl.loadFromCache()` 다음에
    `profileCtrl.refreshFromServer(() => UserRepository.fetchMe())` 추가 예정.
  - 네트워크 실패 시에도 캐시로 UI 가 유지되어 UX 영향 없음.

- [ ] **ProfileEdit 저장 → 서버 PATCH**
  - `MyPage._applyProfileEdit` 의 TODO 주석 위치에
    `UserRepository.updateMe(profile.toJson())` 추가.

- [ ] **회원가입 실패 처리**
  - `SignupCompletePage._goToMain` 의 `submitToBackend` 가 throw 하면
    스낵바 + 재시도. 현재는 정상 경로만 처리.

- [ ] **에러 로깅**
  - `ApiException` 의 message/status 를 Sentry/Crashlytics 로 전송 (추가 검토).

---

## 5. 데이터 저장 위치 정리

| 저장소 | 용도 | 키 |
| --- | --- | --- |
| **FlutterSecureStorage** (Keychain/Keystore) | 토큰 | `access_token`, `refresh_token`, `firebase_id_token` |
| **SharedPreferences** | 사용자 프로필 캐시 | `cached_user_profile_v1` |
| **SharedPreferences** | 사용자 타입 | `user_type` (`employer` / `seeker`) |
| **In-memory (GetX)** | 활성 화면 데이터 | `UserProfileController.profile (Rxn)` |
| **In-memory (GetX)** | 가입 단계 누적 | `SignupDataController` |

> 토큰은 절대 SharedPreferences/메모리에만 남기지 않습니다.
> 일반 프로필 데이터는 SecureStorage 에 두지 않습니다 (필요 이상 권한).

---

## 6. 점검 체크리스트 (배포 전)

- [ ] `.env` 의 `API_BASE_URL` 환경별로 분리 (`dev` / `prod` build flavor)
- [ ] `--dart-define=API_ENABLED=true` 가 release build 설정에 포함됐는지
- [ ] iOS `Info.plist` `NSAppTransportSecurity` HTTPS only 유지
- [ ] Android `network_security_config.xml` HTTPS only
- [ ] 401 → refresh → retry 가 무한 루프 안 도는지 (1회 retry 가드)
- [ ] 로그아웃 후 SignUp 화면으로 되돌아갔을 때 Keychain/SharedPreferences 둘 다
      비워지는지 (`MyPage._onLogOutTap` 흐름 확인)
- [ ] `UserProfileCache` 키 (`_v1`) 마이그레이션 정책: 스키마 바뀌면 `_v2` 로 올리기
