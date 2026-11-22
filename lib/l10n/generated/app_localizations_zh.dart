// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Date Dawn';

  @override
  String get language => '語言';

  @override
  String get followSystemLanguage => '遵循系統語言';

  @override
  String get languageChanged => '語言變了。';

  @override
  String get languageSaveFailed => '無法儲存您的語言首選項。';

  @override
  String get languageEnglish => '英語';

  @override
  String get languageFrench => '法語';

  @override
  String get languageSpanish => '西班牙語';

  @override
  String get languageUkrainian => '烏克蘭語';

  @override
  String get languageGerman => '德語';

  @override
  String get languageChinese => '繁體中文（台灣）';

  @override
  String get settings => '設定';

  @override
  String get dateDawnUser => '日期黎明使用者';

  @override
  String get guestAccount => '訪客帳戶';

  @override
  String get notSignedIn => '您尚未登入';

  @override
  String get syncAndShareDescription => '登入以在每臺裝置上同步您的倒計時並與其他人分享。';

  @override
  String get signIn => '登入';

  @override
  String get appearance => '外貌';

  @override
  String get darkTheme => '黑暗的';

  @override
  String get lightTheme => '光';

  @override
  String get systemTheme => '系統';

  @override
  String get time => '時間';

  @override
  String get timeFormatDescription =>
      '時鐘時間是如何書寫的。不管怎樣，你的倒計時都會被儲存為精確的時刻——這隻會改變它們的讀取方式。';

  @override
  String get twelveHourTime => '12 小時（上午/下午）';

  @override
  String get twentyFourHourTime => '24小時';

  @override
  String get about => '關於';

  @override
  String get version => '版本';

  @override
  String get sync => '同步';

  @override
  String get safety => '安全';

  @override
  String get blockedPeople => '被遮蔽的人';

  @override
  String get legal => '合法的';

  @override
  String get privacyPolicy => '隱私政策';

  @override
  String get termsOfService => '服務條款';

  @override
  String get helpAndSupport => '幫助與支援';

  @override
  String get signOut => '登出';

  @override
  String get signedOut => '已退出。';

  @override
  String countdownsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count倒計時',
      one: '$count倒計時',
    );
    return '$_temp0';
  }

  @override
  String get welcomeToDateDawn => '歡迎來到約會黎明';

  @override
  String get createYourAccount => '建立您的帳戶';

  @override
  String get countdownsSyncDescription => '您的倒計時會同步到您登入的每臺裝置。';

  @override
  String get welcomeDescription => '透過手機、平板電腦和網路倒計時重要時刻。';

  @override
  String get name => '姓名';

  @override
  String get nameHint => '亞歷克斯·里維拉';

  @override
  String get nameRequired => '告訴我們該怎麼稱呼您。';

  @override
  String get email => '電子郵件';

  @override
  String get emailHint => '你@example.com';

  @override
  String get emailRequired => '輸入您的電子郵件。';

  @override
  String get emailInvalid => '這看起來不像電子郵件。';

  @override
  String get password => '密碼';

  @override
  String get passwordRequired => '輸入您的密碼。';

  @override
  String get passwordTooShort => '至少使用 6 個字元。';

  @override
  String get forgotPassword => '忘記密碼？';

  @override
  String get forgotPasswordPrompt => '首先輸入您的電子郵件，然後點選“忘記密碼”。';

  @override
  String get signInConnectionError => '無法訪問登入服務。檢查您的連線。';

  @override
  String get createAccount => '建立賬戶';

  @override
  String get or => '或者';

  @override
  String get continueWithGoogle => '繼續使用谷歌';

  @override
  String get alreadyHaveAccount => '已經有帳戶？';

  @override
  String get newHere => '新來的？';

  @override
  String get createOne => '建立一個';

  @override
  String get troubleSigningIn => '登入時遇到問題？獲得幫助';

  @override
  String get accountCreated => '帳戶已建立。';

  @override
  String get welcomeBack => '歡迎回來。';

  @override
  String get signInFailed => '無法完成登入。請重試。';

  @override
  String get signedInWithGoogle => '已使用 Google 登入。';

  @override
  String get home => '家';

  @override
  String get invitations => '邀請函';

  @override
  String get circles => '界';

  @override
  String get notifications => '通知';

  @override
  String get support => '支援';

  @override
  String get homeEmptyTitle => '命名一天。';

  @override
  String get homeEmptyDescription =>
      '選擇一個未來的時刻——婚禮、釋出會、回家之旅。黎明日期計算著剩餘的年、月、日和小時，然後在它到來時慶祝。';

  @override
  String get homeLoadError => '無法達到您的倒計時。拉下來再試一次。';

  @override
  String get getStarted => '開始使用';

  @override
  String get homeSyncTitle => '讓它們無處不在';

  @override
  String get homeSyncDescription => '登入即可在手機、平板電腦和網路上同步您的倒計時，並與與您一起倒計時的人分享。';

  @override
  String get otherCountdowns => '其他倒計時';

  @override
  String get arrived => '到達的';

  @override
  String get countingDown => '倒計時';

  @override
  String get options => '選項';

  @override
  String get open => '開啟';

  @override
  String get openCountdown => '開放倒計時';

  @override
  String get newCountdown => '新倒計時';

  @override
  String get editCountdown => '編輯倒計時';

  @override
  String get countdownTitleLabel => '標題';

  @override
  String get countdownDescriptionLabel => '描述';

  @override
  String get whenLabel => '什麼時候';

  @override
  String get titleExampleHint => '婚禮、啟動、團聚';

  @override
  String get descriptionExampleHint => '關於這一天的簡短說明';

  @override
  String get dateLabel => '日期';

  @override
  String get timeLabel => '時間';

  @override
  String get presetWeek => '+1 周';

  @override
  String get presetMonth => '+1 個月';

  @override
  String get presetYear => '+1 年';

  @override
  String get presetFiveYears => '+5 年';

  @override
  String get createCountdown => '建立倒計時';

  @override
  String get saveChanges => '儲存更改';

  @override
  String get deleteCountdown => '刪除倒計時';

  @override
  String get countdownActions => '倒計時動作';

  @override
  String get deleteCountdownQuestion => '刪除這個倒計時？';

  @override
  String get countdownCannotUndo => '倒計時無法撤消。';

  @override
  String get giveCountdownTitle => '給這個倒計時一個標題。';

  @override
  String get pickFutureMoment => '選一個還在你前面的時刻。';

  @override
  String get signInToSaveCountdown => '登入以儲存倒計時。';

  @override
  String get countdownCreated => '已建立倒計時。';

  @override
  String get changesSaved => '更改已儲存。';

  @override
  String get countdownDeleted => '倒計時已刪除。';

  @override
  String get partnerLabel => '你的夥伴';

  @override
  String partnerNotAdded(String partnerName) {
    return '已建立倒計時，但未新增$partnerName。從倒計時手動邀請他們。';
  }

  @override
  String partnerAdded(String partnerName) {
    return '已建立倒計時。  新增了$partnerName。';
  }

  @override
  String get noPartnerAdded => '已建立倒計時，但未新增合作伙伴。手動邀請他們。';

  @override
  String get chooseFutureDateHint => '選擇未來的日期以檢視倒計時。';

  @override
  String countingDownRemaining(String remaining) {
    return '倒計時$remaining';
  }

  @override
  String get cannotEditCountdown => '您可以檢視此倒計時，但不能更改它。';

  @override
  String get shareWith => '分享給';

  @override
  String get circleShareDescription => '幾個圈子立即分享。其他圈子收到邀請。';

  @override
  String get collaborators => '合作者';

  @override
  String get collaboratorsCanFollow => '您邀請的任何人都可以在自己的裝置上關注此倒計時。';

  @override
  String get peopleFollowing => '人們正在關注這個倒計時。';

  @override
  String get noCollaboratorsYet => '還沒有其他人。';

  @override
  String get nameEmailHint => '姓名@example.com';

  @override
  String get recentContactsCouldNotLoad => '無法載入最近的聯絡人。檢查您的連線或 Firestore 規則。';

  @override
  String invitationSentTo(String email) {
    return '邀請已傳送至$email。';
  }

  @override
  String sharedWithCircle(String circleName) {
    return '與$circleName共享';
  }

  @override
  String get inviteAgain => '再次邀請';

  @override
  String get removePersonQuestion => '刪除這個人？';

  @override
  String collaboratorLosesAccess(String email) {
    return '$email將失去對此倒計時的訪問許可權，並且將不再在其列表中看到它。';
  }

  @override
  String get changeRole => '改變角色';

  @override
  String changeRoleFor(String personName) {
    return '更改$personName的角色';
  }

  @override
  String roleChangeDescription(String role) {
    return '這改變了他們從現在開始的倒計時可以做的事情。他們目前擁有$role訪問許可權。';
  }

  @override
  String rolesNotAssignable(String roles, String topRole) {
    return '$roles不能由您分配 - 您是$topRole。';
  }

  @override
  String get circlesDescriptionTitle => '與您一起倒數的群組';

  @override
  String get circlesDescription =>
      '邀請某人加入某個圈子一次，然後只需輕按一下即可與整個群組分享任何倒計時。幾個圈子會自動共享——你們中的一個人創造的任何東西，另一個人都會看到。';

  @override
  String get circlesLoadError => '無法載入您的圈子。拉下來重試。';

  @override
  String get noCircles => '還沒有圈子';

  @override
  String get noCirclesDescription => '為與您一起倒計時的人（伴侶、家人或每年與您一起旅行的朋友）建立一個。';

  @override
  String get newCircle => '新圈子';

  @override
  String get sharesAutomatically => '自動分享';

  @override
  String peopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 人',
    );
    return '$_temp0';
  }

  @override
  String get inviteSomeone => '邀請某人';

  @override
  String get you => '你';

  @override
  String get leaveCircle => '離開圈子';

  @override
  String get deleteCircle => '刪除圈子';

  @override
  String get removeFromCircle => '從圈子中刪除';

  @override
  String removeMemberQuestion(String personName) {
    return '刪除$personName？';
  }

  @override
  String get removeMemberExplanation => '他們將不再看到與此圈子共享的倒計時。他們建立的任何內容都不會被刪除。';

  @override
  String leaveCircleQuestion(String circleName) {
    return '留下“$circleName”？';
  }

  @override
  String get leaveCircleExplanation => '您將不再顯示與此圈子共享的倒計時。您可以被邀請回來。';

  @override
  String deleteCircleQuestion(String circleName) {
    return '刪除“$circleName”？';
  }

  @override
  String get deleteCircleExplanation =>
      '隊伍消失了。與其共享的倒計時會被保留並保留在您的手中 - 只是不再與這些人共享。';

  @override
  String get circleNameHint => '家庭，東京 2027，美國';

  @override
  String get coupleCircleTitle => '這就是我們——一對情侶';

  @override
  String get coupleCircleDescription => '倒計時會自動與您的合作伙伴共享，無需接受邀請。';

  @override
  String get circleCreated => '圈子建立了。';

  @override
  String get coupleCircleCreated => '建立。接下來邀請你的夥伴。';

  @override
  String get inviteYourPartner => '邀請你的夥伴';

  @override
  String inviteToCircle(String circleName) {
    return '邀請加入“$circleName”';
  }

  @override
  String get coupleInviteExplanation =>
      '如果他們已經有帳戶，則會自動新增。否則，他們將在登入時新增。與此圈子共享的未來倒計時將自動顯示。';

  @override
  String get circleInviteExplanation => '他們將收到接受或拒絕的邀請。他們加入後，您可以一鍵與此圈子分享倒計時。';

  @override
  String get inviteEmailHint => '他們@example.com';

  @override
  String get sendInvitation => '傳送邀請';

  @override
  String get partnerAddedAutomatically => '您的合作伙伴將自動新增。';

  @override
  String get signInToUseCircles => '登入才能使用圈子';

  @override
  String get circlesRequireAccounts => '圈子透過電子郵件邀請人們，因此他們需要一個被邀請的帳戶。';

  @override
  String get waitingOnYou => '等著你';

  @override
  String get invitationsEmptyDescription =>
      '在您接受之前，不會與您分享任何內容。拒絕告訴邀請您的人，這樣他們就不會猜測。';

  @override
  String get signInToSeeInvitations => '登入檢視邀請';

  @override
  String get invitationsEmailAccount => '邀請會傳送到您的電子郵件，因此請使用某人邀請的地址登入。';

  @override
  String get invitationsCouldNotLoad => '無法載入邀請。檢查您的連線或 Firestore 規則。';

  @override
  String get nothingWaiting => '沒什麼等待';

  @override
  String get invitationInboxEmpty =>
      '人們傳送給您的邀請將顯示在此處。倒計時和標準圈子邀請需要您的回覆；情侶圈子自動加入。';

  @override
  String get retryAddingYou => '重試新增您';

  @override
  String get decline => '衰退';

  @override
  String joinInviteQuestion(String eventTitle) {
    return '加入“$eventTitle”？';
  }

  @override
  String get joinInviteExplanation => '它將出現在您的列表中，並且您將在此裝置上獲得其倒計時。';

  @override
  String get join => '加入';

  @override
  String alreadyMemberOf(String name) {
    return '您已經是“$name”的會員。';
  }

  @override
  String youJoined(String name) {
    return '您加入了“$name”。';
  }

  @override
  String youWereAddedTo(String name) {
    return '您已被新增到“$name”。';
  }

  @override
  String get invitationDeclined => '邀請被拒絕。';

  @override
  String get countdownInvitation => '倒計時邀請';

  @override
  String get aCountdown => '倒計時';

  @override
  String invitedToFollowCountdown(String role) {
    return '您已被邀請關注此倒計時。接受會將其作為$role新增到您的列表中。';
  }

  @override
  String get accept => '接受';

  @override
  String get partnerInvitation => '合作伙伴邀請';

  @override
  String get circleInvitation => '圈子邀請';

  @override
  String partnerCircleAddTitle(String personName) {
    return '您將被新增到$personName的圈子中';
  }

  @override
  String get partnerCircleAddExplanation => '您將被自動新增。與此圈子共享的倒計時活動將顯示在您的列表中。';

  @override
  String circleJoinExplanation(String circleName) {
    return '加入“$circleName”意味著他們與此圈子分享的倒計時將顯示在您的列表中。';
  }

  @override
  String get becomePartners => '成為合作伙伴';

  @override
  String get joinCircle => '加入圈子';

  @override
  String get automaticJoinFailed => '自動加入無法完成。';

  @override
  String get notNow => '現在不要';

  @override
  String get notificationsTitle => '通知';

  @override
  String get markAllRead => '標記全部已讀';

  @override
  String get markedAllRead => '標記為全部已讀。';

  @override
  String get moreOptions => '更多選擇';

  @override
  String get noReadMessagesToDelete => '沒有已讀訊息可刪除。';

  @override
  String get deleteReadMessages => '刪除已讀訊息';

  @override
  String get deletedReadMessages => '刪除已讀訊息。';

  @override
  String get notificationsSignInFirst => '首先登入';

  @override
  String get notificationsAccountOnly => '通知與您的帳戶繫結。';

  @override
  String get couldNotLoad => '無法載入';

  @override
  String get checkConnectionRetry => '檢查您的連線並重試。';

  @override
  String get nothingYet => '還沒有什麼';

  @override
  String get notificationsEmptyDescription => '當您的倒計時或邀請發生某些情況時，它會顯示在此處。';

  @override
  String get liveNotificationsCouldNotLoad => '無法載入實時通知。';

  @override
  String get inbox => '收件箱';

  @override
  String get invitationResponses => '邀請回應';

  @override
  String get invitationResponsesCouldNotLoad => '無法載入邀請回復。';

  @override
  String get countdownUnavailable => '此倒計時不再可用。';

  @override
  String get viewDetails => '檢視詳情';

  @override
  String get sharedWith => '分享給';

  @override
  String get notes => '筆記';

  @override
  String get notesEmpty => '還什麼都沒有。給大家留下一個和你一起倒計時的想法。';

  @override
  String get addNote => '新增註釋';

  @override
  String get years => '年';

  @override
  String get months => '幾個月';

  @override
  String get days => '天';

  @override
  String get hours => '時間';

  @override
  String remainingMinutes(int count) {
    return '$count分鐘';
  }

  @override
  String remainingSeconds(int count) {
    return '剩餘$count秒';
  }

  @override
  String get cancel => '取消';

  @override
  String get keep => '保持';

  @override
  String get stay => '停留';

  @override
  String get leave => '離開';

  @override
  String get remove => '消除';

  @override
  String get delete => '刪除';

  @override
  String get create => '創造';

  @override
  String get tryAgain => '再試一次';

  @override
  String get share => '分享';

  @override
  String get passed => '透過';

  @override
  String get upcoming => '即將推出';

  @override
  String get accepted => '公認';

  @override
  String get declined => '拒絕';

  @override
  String get removed => '已刪除';

  @override
  String get reopened => '重新開放';

  @override
  String get waiting => '等待';

  @override
  String get itHasArrived => '它已經到了。';

  @override
  String remainingToGo(String remaining) {
    return '$remaining出發';
  }

  @override
  String get momentHasPassed => '這一刻已經過去了';

  @override
  String remainingAnd(String first, String last) {
    return '$first和$last';
  }

  @override
  String get dayHasCome => '這一天已經到來';

  @override
  String eventArrivedWithDescription(String title, String description) {
    return '$title在這裡 —$description';
  }

  @override
  String eventArrivedTitleOnly(String title) {
    return '$title就在這裡——享受每一分鐘。';
  }

  @override
  String personRemovedFromCircle(String personName, String circleName) {
    return '$personName已從“$circleName”中刪除。';
  }

  @override
  String youLeftCircle(String circleName) {
    return '您留下了“$circleName”。';
  }

  @override
  String circleDeleted(String circleName) {
    return '刪除了“$circleName”。';
  }

  @override
  String get someone => '有人';

  @override
  String invitedYouToCircle(String personName, String circleName) {
    return '$personName邀請您參加“$circleName”';
  }

  @override
  String get roleAdmin => '行政';

  @override
  String get roleEditor => '編輯';

  @override
  String get roleViewer => '觀眾';

  @override
  String get roleAdminDescription => '可以管理倒計時及其參與者。';

  @override
  String get roleEditorDescription => '可以編輯倒計時並邀請其他人。';

  @override
  String get roleViewerDescription => '可以檢視倒計時並留下筆記。';

  @override
  String remainingYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 年',
    );
    return '$_temp0';
  }

  @override
  String remainingMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 月',
    );
    return '$_temp0';
  }

  @override
  String remainingDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 天',
    );
    return '$_temp0';
  }

  @override
  String remainingHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 小時',
    );
    return '$_temp0';
  }

  @override
  String remainingMinuteUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 分鐘',
    );
    return '$_temp0';
  }

  @override
  String remainingSecondUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 秒',
    );
    return '$_temp0';
  }

  @override
  String get moreActions => '更多行動';

  @override
  String get block => '堵塞';

  @override
  String roleChanged(String personName, String role) {
    return '$personName現在是$role。';
  }

  @override
  String personRemoved(String personName) {
    return '$personName已被刪除。';
  }

  @override
  String get signInToSaveIt => '登入以儲存它';

  @override
  String get countdownsFollowYou => '倒計時存在於您的帳戶中，因此它們會跟隨您到每臺裝置，並可以與其他人共享。';

  @override
  String get savePermissionError =>
      'Firestore 拒絕儲存。如果這種情況持續發生，則部署的安全規則比應用程式舊 - 執行“firebase deploy --only firestore:rules”。';

  @override
  String get saveNetworkError => '無法到達 Firestore。檢查您的連線並重試。';

  @override
  String get saveFailed => '無法儲存。請再試一次。';

  @override
  String get momentPassed => '這一刻已經過去了';

  @override
  String get and => '和';

  @override
  String get back => '後退';

  @override
  String get policyLastUpdated => '最後更新時間：2026 年 2 月 · 符合歐盟 GDPR 和加拿大 PIPEDA';

  @override
  String get privacyIntroTitle => '1. 簡介及資料控制者';

  @override
  String privacyIntroBody(String supportEmail) {
    return 'Date Dawn（“我們”或“我們的”）尊重您的隱私並致力於保護您的個人資料。本隱私政策解釋了當您使用我們的移動和網路應用程式時我們如何收集、使用和保護您的資訊，完全符合歐盟《通用資料保護條例》(GDPR) 和加拿大《個人資訊保護和電子檔案法》(PIPEDA)。\n\n資料控制者聯絡人：$supportEmail';
  }

  @override
  String get privacyCollectTitle => '2. 我們收集的資訊';

  @override
  String get privacyCollectBody =>
      '• 帳戶資料：身份驗證 (Firebase Auth) 期間提供的電子郵件地址和顯示名稱。\n• 使用者內容：您明確建立或共享的倒計時、標題、日期、描述和圈子成員身份。\n• 裝置和通知資料：推送通知令牌以提供倒計時提醒和邀請警報。\n\n我們不會收集瀏覽歷史記錄、廣告識別符號、位置資料，也不會將任何個人資訊出售給第三方。';

  @override
  String get privacyBasisTitle => '3. 處理的法律依據 (EU GDPR)';

  @override
  String get privacyBasisBody =>
      '我們根據以下合法依據處理您的資料：\n• 合同必要性：提供倒計時同步、圈子共享和邀請功能。\n• 同意：當您授予推送通知許可權或選擇加入共享圈子時。\n• 合法利益：確保應用程式安全性、可靠性並防止濫用。';

  @override
  String get privacySharingTitle => '4. 分享與遮蔽';

  @override
  String get privacySharingBody =>
      'Date Dawn 允許人們進行一對一互動：您可以邀請某人進行倒計時，並且雙方都可以在共享的人上留下筆記。該內容僅對倒計時的人可見——從不公開，也從未向其他任何人展示。\n\n您可以隨時阻止其他人：開啟與他們共享的倒計時，然後長按他們的名字（或在桌面上雙擊它）。遮蔽會將你們從彼此的倒計時中刪除，取消你們之間的邀請，並阻止他們再次邀請您。這個人沒有被告知。您已阻止的人員列表對您來說是私人的，您可以從“設定”→“已阻止的人員”中取消阻止任何人。';

  @override
  String get privacyStorageTitle => '5. 資料儲存和安全';

  @override
  String get privacyStorageBody =>
      '您的資料將使用符合高行業安全標準的 Firebase（Google Cloud Platform）基礎設施安全地儲存和處理。您的裝置和我們的伺服器之間傳輸的資料在傳輸過程中使用 TLS 進行加密。';

  @override
  String get privacyRightsTitle => '6. 您的權利（訪問、更正和刪除）';

  @override
  String privacyRightsBody(String supportEmail) {
    return '根據 GDPR 和 PIPEDA，您有權：\n• 訪問：索取我們持有的有關您的個人資料的副本。\n• 更正：更新或更正您在“設定”中的個人資料資訊。\n• 刪除（被遺忘的權利）：隨時聯絡$supportEmail請求完全刪除您的帳戶以及所有相關倒計時和通知。';
  }

  @override
  String get termsAcceptanceTitle => '1. 接受條款';

  @override
  String get termsAcceptanceBody =>
      '透過訪問或使用 Date Dawn，您同意受這些服務條款的約束。如果您不同意這些條款，請不要使用該應用程式。';

  @override
  String get termsUseTitle => '2. 服務的使用';

  @override
  String get termsUseBody =>
      'Date Dawn 提供個人、非商業倒計時和共享時刻跟蹤。您同意不濫用服務、上傳惡意內容、透過共享圈子或邀請騷擾其他使用者，或嘗試繞過安全控制。';

  @override
  String get termsOwnershipTitle => '3. 使用者內容和所有權';

  @override
  String get termsOwnershipBody =>
      '您保留對您建立的倒計時活動、標題和內容的所有所有權。您授予 Date Dawn 有限許可，僅用於在經過身份驗證的裝置和共享圈子成員之間儲存和同步您的內容。';

  @override
  String get termsTerminationTitle => '4. 終止和帳戶刪除';

  @override
  String get termsTerminationBody =>
      '您可以隨時停止使用 Date Dawn，並透過向支援人員傳送電子郵件請求刪除帳戶。我們保留暫停或終止違反這些條款或濫用平臺基礎設施的帳戶的權利。';

  @override
  String get termsLiabilityTitle => '5. 責任限制';

  @override
  String get termsLiabilityBody =>
      'Date Dawn 按“原樣”提供，不提供任何形式的保證。對於因您使用該應用程式而造成的任何間接、偶然或後果性損害，我們不承擔任何責任。';

  @override
  String get privacyPolicyTitle => '隱私政策';

  @override
  String get termsOfServiceTitle => '服務條款';

  @override
  String get supportHeading => '我們閱讀每條訊息';

  @override
  String supportIntro(String responseTime) {
    return 'Date Dawn 是一個小型的獨立應用程式。電子郵件是聯絡構建者的最快方式——中間沒有支援臺。我們通常回復$responseTime。';
  }

  @override
  String get supportResponseTime => '2個工作日內';

  @override
  String get supportCommonQuestions => '常見問題';

  @override
  String get supportFaqGoogleQuestion => '我用 Google 登入，但倒計時不見了。';

  @override
  String get supportFaqGoogleAnswer =>
      '使用與建立帳戶時相同的方法。 Google 和電子郵件/密碼不會自動連結。如果您需要切換方法或認為您在兩個帳戶中擁有資料，請在建立另一個帳戶之前聯絡我們。';

  @override
  String get supportFaqSharingQuestion => '與我共享的人看不到倒計時。';

  @override
  String get supportFaqSharingAnswer =>
      '與圈子共享倒計時會傳送邀請 - 它不會自動新增人員。他們需要在應用程式中開啟邀請並接受它。情侶圈是一個例外：它們會立即分享。';

  @override
  String get supportFaqDeclinedQuestion => '我錯誤地拒絕了邀請。';

  @override
  String get supportFaqDeclinedAnswer =>
      '讓邀請你的人再次邀請你——他們可以透過點選你名字旁邊的重新整理圖示從倒計時開始邀請你。在此期間，什麼也沒有丟失。';

  @override
  String get supportFaqDeleteQuestion => '如何刪除我的帳戶和資料？';

  @override
  String get supportFaqDeleteAnswer =>
      '從您註冊時使用的地址給我們傳送電子郵件並要求刪除。與該帳戶相關的所有倒計時、邀請和通知都會被刪除，我們會在完成後進行確認。';

  @override
  String get supportFaqBlockQuestion => '我如何阻止某人？';

  @override
  String get supportFaqBlockAnswer =>
      '開啟與他們共享的倒計時，然後在人員列表中長按他們的名字（在計算機上雙擊）。他們已從您的共享倒計時中刪除，並且無法再次邀請您。要撤消它，請轉到“設定”→“阻止的人”。';

  @override
  String get supportFaqAdsQuestion => '你們會出售我的資料或展示廣告嗎？';

  @override
  String get supportFaqAdsAnswer =>
      '不會。沒有廣告，沒有分析配置檔案，也沒有第三方跟蹤。您倒計時的內容與您無關，因此它儲存在您自己的帳戶下，其他人無法閱讀。';

  @override
  String get supportLegal => '合法的';

  @override
  String get supportNotice =>
      '退款、賬單問題或崩潰報告都屬於同一地址。如果應用程式出現問題，請告訴我們您的裝置以及發生問題時您正在做什麼，這是您可以包含的最有用的內容。';

  @override
  String get supportEmailLabel => '電子郵件支援';

  @override
  String supportEmailCopied(String email) {
    return '$email已複製';
  }

  @override
  String get openMail => '開啟郵件';

  @override
  String get linkCopiedClipboard => '連結已複製到剪貼簿。';

  @override
  String get verifyEmailTitle => '驗證您的電子郵件';

  @override
  String verifyEmailInstructions(String email) {
    return '我們向$email傳送了驗證連結。請驗證以繼續。';
  }

  @override
  String get yourEmailAddress => '您的電子郵件地址';

  @override
  String resetLinkSent(String email) {
    return '重置傳送到$email的連結。使用最新的電子郵件。';
  }

  @override
  String get verificationEmailSent => '驗證電子郵件已傳送。';

  @override
  String get verificationNotComplete => '尚未驗證。檢查您的收件箱。';

  @override
  String get verifiedSignInToContinue => '您的電子郵件已驗證。如果需要，請登入以繼續。';

  @override
  String get checkSpamFolder => '找不到電子郵件？請檢查您的垃圾郵件或垃圾郵件資料夾。';

  @override
  String get confirmEmailVerified => '我已驗證我的電子郵件';

  @override
  String get sendingEmail => '正在傳送...';

  @override
  String get resendEmail => '重新傳送電子郵件';

  @override
  String get waitBeforeResending => '請等待 60 秒，然後再請求另一封電子郵件。';

  @override
  String get resetCodeMissing => '此重置連結缺少安全程式碼。';

  @override
  String get passwordUpdatedSignIn => '密碼已更新。再次登入。';

  @override
  String get resetLinkInvalidTitle => '無法使用此重置連結';

  @override
  String get resetLinkInvalidBody => '該連結可能已過期或已被使用。返回登入並請求新的密碼重置電子郵件。';

  @override
  String get backToSignIn => '返回登入';

  @override
  String get chooseNewPassword => '選擇新密碼';

  @override
  String get newPassword => '新密碼';

  @override
  String get confirmNewPassword => '確認新密碼';

  @override
  String get passwordMinLength => '至少使用 6 個字元。';

  @override
  String get passwordsDoNotMatch => '密碼不匹配。';

  @override
  String get updatePassword => '更新密碼';

  @override
  String get editCountdownAction => '編輯';

  @override
  String get duplicateYearLater => '一年後重複';

  @override
  String get countdownDuplicated => '重複 — 開啟它來調整日期。';

  @override
  String get onlyOwnerCanDelete => '只有所有者才能刪除此倒計時。';

  @override
  String get countdownDeleteFailed => '無法刪除。再試一次。';

  @override
  String get countdownDeleteWarning => '倒計時無法撤消。';

  @override
  String blockPersonQuestion(String personName) {
    return '塊$personName？';
  }

  @override
  String get blockExplanation =>
      '你們將不再見面。他們將從您分享的每個倒計時中刪除，你們之間的邀請被取消，並且他們無法再次邀請您。他們沒有被告知。';

  @override
  String get undoBlockInSettings => '您可以隨時在“設定”→“阻止的人”中撤消此操作。';

  @override
  String get blocking => '阻塞…';

  @override
  String get blockAction => '堵塞';

  @override
  String personBlocked(String personName) {
    return '$personName被阻止。';
  }

  @override
  String get undo => '撤消';

  @override
  String personUnblocked(String personName) {
    return '$personName已解鎖。';
  }

  @override
  String get blockAccessNotRestored => '倒計時訪問未恢復。';

  @override
  String get undoBlockFailed => '無法撤消阻止。請再試一次。';

  @override
  String get blockSaveFailed => '無法儲存您的區塊。重新登入並重試。';

  @override
  String get noConnectionRetry => '沒有連線。檢查您的網路並重試。';

  @override
  String blockPersonFailed(String personName) {
    return '無法阻止$personName。請再試一次。';
  }

  @override
  String get blockedPeopleTitle => '被遮蔽的人';

  @override
  String get nobodyBlocked => '沒有人被阻止';

  @override
  String get howToBlockPerson => '要阻止某人，請開啟與他們共享的倒計時，開啟其所在行的 ⋮ 選單，然後點選“阻止”。';

  @override
  String get blockedPeopleDescription =>
      '這些人無法邀請您，您也不會與他們分享任何倒計時。他們沒有被告知他們被封鎖了。';

  @override
  String get unblock => '解鎖';

  @override
  String get blockedListLoadFailed => '無法載入您的阻止列表';

  @override
  String get blockedListPermissionError => '您的帳戶無權閱讀此列表。如果這種情況持續發生，請更新應用程式。';

  @override
  String get deleteAccount => '關於如何刪除帳戶的說明';

  @override
  String get deleteAccountWarning => '此操作是永久性的。您的所有活動、圈子和資料都將被永久刪除。';

  @override
  String get deleteAccountConfirmationPrompt => '輸入您的確切帳戶電子郵件以繼續。';

  @override
  String get deleteAccountConfirmationLabel => '賬戶郵箱';

  @override
  String get permanentlyDeleteAccount => '永久刪除帳戶';

  @override
  String get deleteAccountProfileConsequence => '您的個人資料將被永久刪除。';

  @override
  String get deleteAccountAccessConsequence => '您將無法訪問所有活動和圈子。';

  @override
  String get deleteAccountIrreversibleConsequence => '此操作無法撤消。';

  @override
  String get deleteAccountPermanentlyAction => '永久刪除帳戶';

  @override
  String get accountDeleted => '帳號刪除成功';

  @override
  String get serverTimedOutTryAgain => '伺服器超時。請稍後重試。';

  @override
  String get accountDeletionFailed => '無法完成帳戶刪除。請再試一次。';

  @override
  String get accountDeletedCleanupWarning =>
      '帳戶已刪除，但無法清除某些本地設定。使用其他帳戶之前重新啟動應用程式。';
}
