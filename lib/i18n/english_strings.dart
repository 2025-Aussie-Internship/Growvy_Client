/// 앱 전체에서 사용자에게 노출되는 **하드코딩 영어 문자열** 모음.
///
/// 이 목록은 앱 시작 시(언어 선택 → Ready to Start 직전) `TranslationService.prewarm` 으로
/// 한 번에 번역해 캐시에 채워두기 위해 존재한다.
///
/// 새 영어 텍스트를 `AutoTranslateText` 로 화면에 넣을 때, 정적 문자열이라면 이 곳에도 추가해
/// "처음 진입했을 때 영어가 잠깐 보이는 깜빡임"을 예방한다. (동적/DB 데이터는 자연히 lazy 번역됨.)
library;

const List<String> kStaticEnglishStrings = <String>[
  // ──────────────────────────────────────────────────────────────────────────
  // 공통 모달
  // ──────────────────────────────────────────────────────────────────────────
  'Cancel',
  'Accept',
  "No, I don't",
  'Yes, I do',
  'OK',
  'Save',
  'Save Changes',
  'Save Draft',
  'Discard',
  'Add',
  'Sure',
  'Select',
  'apply',
  'See More',
  'Sign In',

  // ──────────────────────────────────────────────────────────────────────────
  // 알림(모달) / 캘린더
  // ──────────────────────────────────────────────────────────────────────────
  'Notifications',
  'Today',
  'This Week',
  'AD',
  "Today's To Do List",
  'No tasks for this day',
  'Select Year',
  'Select Month',

  // 알림 더미 메시지 (메인 알림 모달)
  'Start today! Part-time café job in Sydney',
  'Resort housekeeping jobs near the beach',
  'High-paying seasonal farm work',
  'Morning farm shift reminder',
  'Restaurant serving shift reminder',
  'Warehouse packing job opportunity',
  'Café shift opening available',
  'Delivery driver needed urgently',
  'Kitchen helper position open',
  'Barista training session',
  'Weekend retail position available',
  'Part-time jobs for students',
  'Night shift warehouse work',

  // 캘린더 todo 더미
  'Café or Restaurant Staff',
  'Retail Assistant',
  'Delivery Driver',
  'Warehouse Work',
  'Kitchen Helper',
  'Team Meeting',
  'Barista Training',

  // 영문 월 / 요일
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
  'Sunday', 'Monday', 'Tuesday', 'Wednesday',
  'Thursday', 'Friday', 'Saturday',

  // ──────────────────────────────────────────────────────────────────────────
  // Home (Main) 더미
  // ──────────────────────────────────────────────────────────────────────────
  'Part-time café job in Sydney',
  'Nearest', 'Newest',

  // nearbyJobs
  'Restaurant Staff', 'Aussie Bite',
  'Farm work', 'COMPANY',
  'Café Job', "Bunny's",
  'Kitchen Hand', 'Sydney Kitchen',
  'Delivery Driver', 'Uber Eats',
  'Warehouse', 'Amazon',
  'HOT', 'NEW', 'Urgent', 'Exp', 'Flexible', 'Bike', 'Night', 'High Pay',

  // popularJobs
  'Babysitter', "Jake's mom",
  'Hostel Staff', 'Ustaing',
  'Record Shop', 'The Gomori',
  'Packing', 'Ropine',
  'Dog Walker', 'Pet Lovers',
  'Barista', 'Starbucks',

  // ──────────────────────────────────────────────────────────────────────────
  // JobDetail 더미
  // ──────────────────────────────────────────────────────────────────────────
  "Sadie's HotPot",
  'My Awesome Company',
  'Looking for someone to try my Malatang.',
  'Feb 15, 2026 - Feb 16, 2026',
  '10:00 AM - 11:00 AM (1-hour)',
  '123 Swanston St, Melbourne, VIC, Australia',
  '\$1000 per day',
  '1 openings.',
  'D-10', 'Veteran',

  // ──────────────────────────────────────────────────────────────────────────
  // Map 더미
  // ──────────────────────────────────────────────────────────────────────────
  'Payment', 'Time', 'Qualifications',
  'Warehouse Job', 'Company', '\$24.95 per hour', '4~8 hours per day', 'Age 18+ 2025',
  'Event Staff', 'Event Co', '\$22.00 per hour',
  'Retail Inc',
  'Cafe Staff', 'Cafe Co',
  'Delivery Helper', 'Logistics',
  'Store Associate', 'Retail',
  'Food Co',

  // ──────────────────────────────────────────────────────────────────────────
  // MyPage / ProfileEdit
  // ──────────────────────────────────────────────────────────────────────────
  'My Name',
  'She/Her', 'He/Him', 'They/Them',
  'Customer Service Center',
  'Notice',
  'Settings',
  'Account Deletion',
  'Log Out',
  'Edit Profile',
  'Check reviews',
  'Profile', 'Banner',
  'Enter My Name',
  'Gender Pronouns',
  'Account',
  'Your G-mail Address',
  'Phone Number',
  'Home/Company Address',
  'Home Address',
  'Business Address',
  // MyPage 메뉴(구인자)
  'My Job Posts',
  'Applicants',
  'Interviews',
  'Billing',
  'Support',
  // MyPage subtitle (employer 임시 업종)
  'Hospitality',
  // 확인 모달
  'Do you really want\nto Log out?',
  'Do you want to\nsave the changes?',
  // ProfileEdit 신규 필드
  'Phone-Number',
  'G-mail Address',
  'Career',
  'One Line Introduction',
  'Preference',
  "Sadie's Hot Pot",
  'Unit 5, 123 George Street',
  '00 0000 0000',
  'abcdefg@gmail.com',
  'blahblah',
  "I like to help people! And I'm trying to improve my social skills :)",
  // Note 탭 (seeker Done) 신규 버튼
  'Write Note',

  // ReviewDetail
  'Change Saved!',
  'Changes you made may not be saved',

  // ──────────────────────────────────────────────────────────────────────────
  // Chat
  // ──────────────────────────────────────────────────────────────────────────
  'User Name',
  'Last Message text...',
  'Month, Date, Year(Time)',
  'Name',
  'Type a Message',
  'Text',

  // ──────────────────────────────────────────────────────────────────────────
  // Search
  // ──────────────────────────────────────────────────────────────────────────
  'Recent searches',
  'auto save',
  'delete all',
  'Popular searches',
  'Farm work', 'Farm', 'Cafe', 'Cafe staff', 'Hotel staff', 'Hotel',
  'Farm Work', 'Hotel Staff', 'Deckhand', 'Au Pair', 'Warehouse Assistant',
  'Café job', 'Record Shop Employee', "Will's fram", 'This is for you Jane',
  'People needs Rabbit!', 'Hopkins Night', 'Dustin Byers', 'Rookie',

  // ──────────────────────────────────────────────────────────────────────────
  // Region (filter / modal)
  // ──────────────────────────────────────────────────────────────────────────
  'search for region',
  'Sydney', 'Newcastle', 'Wollongong', 'Central Coast',
  'Melbourne', 'Geelong', 'Ballarat', 'Bendigo',
  'Brisbane', 'Gold Coast', 'Sunshine Coast', 'Cairns', 'Townsville',
  'Perth', 'Mandurah',
  'Adelaide',
  'Hobart', 'Launceston',
  'Canberra',
  'Darwin', 'Alice Springs',
  'CBD', 'Inner City', 'North', 'South', 'East', 'West', 'Inner', 'South-East',

  // ──────────────────────────────────────────────────────────────────────────
  // Note (Write / Detail) - seeker
  // ──────────────────────────────────────────────────────────────────────────
  'Note', 'Title', 'Enter the Job Title',
  'What did you learn?',
  'Overall Experience',
  'Tell us about your experience',
  'Paste your photos',
  'Add Skill', 'Enter a skill',
  'How was the job?',
  'Limit reached',
  'Do you really want\nto stop recruiting?',
  'Do you want\nto save draft it?',
  'Save Complete!',
  'Untitled Note',
  'Saved', 'Completed', 'Volunteer',
  'My experience',
  'Do you want\nShare your note?',
  'Share Complete!',
  'Do you want\nDelete your note?',
  'Delete Complete!',
  // skills
  'Communication', 'Teamwork', 'Time Management', 'Problem Solving',
  'Independence', 'Adaptability', 'Initiative', 'Customer Interaction',
  // experience labels
  'Great', 'Good', 'Okay', 'Challenging', 'Tough',

  // ──────────────────────────────────────────────────────────────────────────
  // Note (Write) - employer
  // ──────────────────────────────────────────────────────────────────────────
  'Post a Job', 'title',
  'Write about your experience',
  'Schedule', 'DD/MM/YYYY - DD/MM/YYYY', 'Shift: 00:00 - 00:00',
  'Location', 'Enter the Location',
  'Pay', 'Enter the daily rate',
  'Number of Hires',
  'Tags', 'Photos',
  'Do you really want to stop recruiting?',
  'Do you want to save draft it?',
  // tags
  'Seasonal',

  // ──────────────────────────────────────────────────────────────────────────
  // StartHiring 폼
  // ──────────────────────────────────────────────────────────────────────────
  'Start Hiring', 'Publish', 'Ready To Start Hiring?',
  'Job Title', 'Company Name', 'Enter your business name',
  'Work Location', 'Enter suburb, state (e.g. Fitzroy, VIC)',
  'Employment Type',
  'Casual', 'Part-time', 'Full-time', 'Contract', 'Temporary',
  'Industry',
  'Hospitality & F&B', 'Retail & Sales', 'Farm & Seasonal',
  'Manufacturing', 'Factory Work', 'Cleaning & Facilities',
  'Construction', 'Logistics & Moving', 'Events & Festivals',
  'Customer Service', 'Other Jobs',
  'Responsibilities', 'Write the Job Title',
  'Shift Details', 'Date', 'Number of people', 'At least one person',
  'Day of the Week', 'SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT',
  'Hourly Rate', 'Penalty Rates', 'Superannuation',
  'Paid separately', 'Included in rate',
  'Application Deadline', 'When is the Application Deadline?',
  'From', 'To',
  'AM', 'PM',
  // step labels
  'Basic Info', 'Job Details', 'Pay &\nBenefits', 'Application\nSettings',

  // ──────────────────────────────────────────────────────────────────────────
  // 공통 모달들 (banner/profile/job-openings/job-application)
  // ──────────────────────────────────────────────────────────────────────────
  'Pick Banner Color',
  'Pick Your Profile',
  'My Job Openings',
  'Job Application List',
  'Event Staff',
  'Café Crew',

  // controllers/note_page_controller 더미
  'Food Delivery Rider', 'Hungry Panda',
  'Temporary Sales Assistant', 'Happy Gumpy',
  'Pop-Up Store Crew', 'Red Bull Australia',
  'Festival Support Staff', 'Boost Juice',
  'Event Helper',
  'Cashier', 'Blue Wattle Coffee',
  'Brand Ambassador', 'UGG (AU)',
  'Office Assistant', "Browing'",
  'D-Day', 'Expired',
  'Promotional Staff', 'Conference Helper', 'Inventory Assistant',
  'Festival Staff',

  // ──────────────────────────────────────────────────────────────────────────
  // Note 탭 (employer) - 구인자용 새 UI
  // ──────────────────────────────────────────────────────────────────────────
  'Write Review',
  'Reviewing',

  // ──────────────────────────────────────────────────────────────────────────
  // Note 탭 (seeker Done 더미) - 시안 보강
  // ──────────────────────────────────────────────────────────────────────────
  'Sephora Australia',
  'UNIQLO Australia',
  "Grill'd",
  'Casual Bar Support Staff',
  'Pepper & Vine',
  'Oak & Ivy',
];
