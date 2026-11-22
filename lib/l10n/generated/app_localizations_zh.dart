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
  String get language => '语言';

  @override
  String get followSystemLanguage => '遵循系统语言';

  @override
  String get languageChanged => '语言变了。';

  @override
  String get languageSaveFailed => '无法保存您的语言首选项。';

  @override
  String get languageEnglish => '英语';

  @override
  String get languageFrench => '法国人';

  @override
  String get languageSpanish => '西班牙语';

  @override
  String get languageUkrainian => 'Українська';

  @override
  String get languageGerman => '德语';

  @override
  String get languageChinese => '中文（简体）';

  @override
  String get settings => '设置';

  @override
  String get dateDawnUser => '日期黎明用户';

  @override
  String get guestAccount => '访客帐户';

  @override
  String get notSignedIn => '您尚未登录';

  @override
  String get syncAndShareDescription => '登录以在每台设备上同步您的倒计时并与其他人分享。';

  @override
  String get signIn => '登入';

  @override
  String get appearance => '外貌';

  @override
  String get darkTheme => '黑暗的';

  @override
  String get lightTheme => '光';

  @override
  String get systemTheme => '系统';

  @override
  String get time => '时间';

  @override
  String get timeFormatDescription =>
      '时钟时间是如何书写的。不管怎样，你的倒计时都会被存储为精确的时刻——这只会改变它们的读取方式。';

  @override
  String get twelveHourTime => '12 小时（上午/下午）';

  @override
  String get twentyFourHourTime => '24小时';

  @override
  String get about => '关于';

  @override
  String get version => '版本';

  @override
  String get sync => '同步';

  @override
  String get safety => '安全';

  @override
  String get blockedPeople => '被屏蔽的人';

  @override
  String get legal => '合法的';

  @override
  String get privacyPolicy => '隐私政策';

  @override
  String get termsOfService => '服务条款';

  @override
  String get helpAndSupport => '帮助与支持';

  @override
  String get signOut => '登出';

  @override
  String get signedOut => '已退出。';

  @override
  String countdownsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count倒计时',
      one: '$count倒计时',
    );
    return '$_temp0';
  }

  @override
  String get welcomeToDateDawn => '欢迎来到约会黎明';

  @override
  String get createYourAccount => '创建您的帐户';

  @override
  String get countdownsSyncDescription => '您的倒计时会同步到您登录的每台设备。';

  @override
  String get welcomeDescription => '通过手机、平板电脑和网络倒计时重要时刻。';

  @override
  String get name => '姓名';

  @override
  String get nameHint => '亚历克斯·里维拉';

  @override
  String get nameRequired => '告诉我们该怎么称呼您。';

  @override
  String get email => '电子邮件';

  @override
  String get emailHint => '你@example.com';

  @override
  String get emailRequired => '输入您的电子邮件。';

  @override
  String get emailInvalid => '这看起来不像电子邮件。';

  @override
  String get password => '密码';

  @override
  String get passwordRequired => '输入您的密码。';

  @override
  String get passwordTooShort => '至少使用 6 个字符。';

  @override
  String get forgotPassword => '忘记密码？';

  @override
  String get forgotPasswordPrompt => '首先输入您的电子邮件，然后点击“忘记密码”。';

  @override
  String get signInConnectionError => '无法访问登录服务。检查您的连接。';

  @override
  String get createAccount => '创建账户';

  @override
  String get or => '或者';

  @override
  String get continueWithGoogle => '继续使用谷歌';

  @override
  String get alreadyHaveAccount => '已经有帐户？';

  @override
  String get newHere => '新来的？';

  @override
  String get createOne => '创建一个';

  @override
  String get troubleSigningIn => '登录时遇到问题？获得帮助';

  @override
  String get accountCreated => '帐户已创建。';

  @override
  String get welcomeBack => '欢迎回来。';

  @override
  String get signInFailed => '无法完成登录。请重试。';

  @override
  String get signedInWithGoogle => '已使用 Google 登录。';

  @override
  String get home => '家';

  @override
  String get invitations => '邀请函';

  @override
  String get circles => '界';

  @override
  String get notifications => '通知';

  @override
  String get support => '支持';

  @override
  String get homeEmptyTitle => '命名一天。';

  @override
  String get homeEmptyDescription =>
      '选择一个未来的时刻——婚礼、发布会、回家之旅。黎明日期计算着剩余的年、月、日和小时，然后在它到来时庆祝。';

  @override
  String get homeLoadError => '无法达到您的倒计时。拉下来再试一次。';

  @override
  String get getStarted => '开始使用';

  @override
  String get homeSyncTitle => '让它们无处不在';

  @override
  String get homeSyncDescription => '登录即可在手机、平板电脑和网络上同步您的倒计时，并与与您一起倒计时的人分享。';

  @override
  String get otherCountdowns => '其他倒计时';

  @override
  String get arrived => '到达的';

  @override
  String get countingDown => '倒计时';

  @override
  String get options => '选项';

  @override
  String get open => '打开';

  @override
  String get openCountdown => '开放倒计时';

  @override
  String get newCountdown => '新倒计时';

  @override
  String get editCountdown => '编辑倒计时';

  @override
  String get countdownTitleLabel => '标题';

  @override
  String get countdownDescriptionLabel => '描述';

  @override
  String get whenLabel => '什么时候';

  @override
  String get titleExampleHint => '婚礼、启动、团聚';

  @override
  String get descriptionExampleHint => '关于这一天的简短说明';

  @override
  String get dateLabel => '日期';

  @override
  String get timeLabel => '时间';

  @override
  String get presetWeek => '+1 周';

  @override
  String get presetMonth => '+1 个月';

  @override
  String get presetYear => '+1 年';

  @override
  String get presetFiveYears => '+5 年';

  @override
  String get createCountdown => '创建倒计时';

  @override
  String get saveChanges => '保存更改';

  @override
  String get deleteCountdown => '删除倒计时';

  @override
  String get countdownActions => '倒计时动作';

  @override
  String get deleteCountdownQuestion => '删除这个倒计时？';

  @override
  String get countdownCannotUndo => '倒计时无法撤消。';

  @override
  String get giveCountdownTitle => '给这个倒计时一个标题。';

  @override
  String get pickFutureMoment => '选一个还在你前面的时刻。';

  @override
  String get signInToSaveCountdown => '登录以保存倒计时。';

  @override
  String get countdownCreated => '已创建倒计时。';

  @override
  String get changesSaved => '更改已保存。';

  @override
  String get countdownDeleted => '倒计时已删除。';

  @override
  String get partnerLabel => '你的伙伴';

  @override
  String partnerNotAdded(String partnerName) {
    return '已创建倒计时，但未添加$partnerName。从倒计时手动邀请他们。';
  }

  @override
  String partnerAdded(String partnerName) {
    return '已创建倒计时。  添加了$partnerName。';
  }

  @override
  String get noPartnerAdded => '已创建倒计时，但未添加合作伙伴。手动邀请他们。';

  @override
  String get chooseFutureDateHint => '选择未来的日期以查看倒计时。';

  @override
  String countingDownRemaining(String remaining) {
    return '倒计时$remaining';
  }

  @override
  String get cannotEditCountdown => '您可以查看此倒计时，但不能更改它。';

  @override
  String get shareWith => '分享给';

  @override
  String get circleShareDescription => '几个圈子立即分享。其他圈子收到邀请。';

  @override
  String get collaborators => '合作者';

  @override
  String get collaboratorsCanFollow => '您邀请的任何人都可以在自己的设备上关注此倒计时。';

  @override
  String get peopleFollowing => '人们正在关注这个倒计时。';

  @override
  String get noCollaboratorsYet => '还没有其他人。';

  @override
  String get nameEmailHint => '姓名@example.com';

  @override
  String get recentContactsCouldNotLoad => '无法加载最近的联系人。检查您的连接或 Firestore 规则。';

  @override
  String invitationSentTo(String email) {
    return '邀请已发送至$email。';
  }

  @override
  String sharedWithCircle(String circleName) {
    return '与$circleName共享';
  }

  @override
  String get inviteAgain => '再次邀请';

  @override
  String get removePersonQuestion => '删除这个人？';

  @override
  String collaboratorLosesAccess(String email) {
    return '$email将失去对此倒计时的访问权限，并且将不再在其列表中看到它。';
  }

  @override
  String get changeRole => '改变角色';

  @override
  String changeRoleFor(String personName) {
    return '更改$personName的角色';
  }

  @override
  String roleChangeDescription(String role) {
    return '这改变了他们从现在开始的倒计时可以做的事情。他们目前拥有$role访问权限。';
  }

  @override
  String rolesNotAssignable(String roles, String topRole) {
    return '$roles不能由您分配 - 您是$topRole。';
  }

  @override
  String get circlesDescriptionTitle => '与您一起倒数的群组';

  @override
  String get circlesDescription =>
      '邀请某人加入某个圈子一次，然后只需轻按一下即可与整个群组分享任何倒计时。几个圈子会自动共享——你们中的一个人创造的任何东西，另一个人都会看到。';

  @override
  String get circlesLoadError => '无法加载您的圈子。拉下来重试。';

  @override
  String get noCircles => '还没有圈子';

  @override
  String get noCirclesDescription => '为与您一起倒计时的人（伴侣、家人或每年与您一起旅行的朋友）创建一个。';

  @override
  String get newCircle => '新圈子';

  @override
  String get sharesAutomatically => '自动分享';

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
  String get inviteSomeone => '邀请某人';

  @override
  String get you => '你';

  @override
  String get leaveCircle => '离开圈子';

  @override
  String get deleteCircle => '删除圈子';

  @override
  String get removeFromCircle => '从圈子中删除';

  @override
  String removeMemberQuestion(String personName) {
    return '删除$personName？';
  }

  @override
  String get removeMemberExplanation => '他们将不再看到与此圈子共享的倒计时。他们创建的任何内容都不会被删除。';

  @override
  String leaveCircleQuestion(String circleName) {
    return '留下“$circleName”？';
  }

  @override
  String get leaveCircleExplanation => '您将不再显示与此圈子共享的倒计时。您可以被邀请回来。';

  @override
  String deleteCircleQuestion(String circleName) {
    return '删除“$circleName”？';
  }

  @override
  String get deleteCircleExplanation =>
      '队伍消失了。与其共享的倒计时会被保留并保留在您的手中 - 只是不再与这些人共享。';

  @override
  String get circleNameHint => '家庭，东京 2027，美国';

  @override
  String get coupleCircleTitle => '这就是我们——一对情侣';

  @override
  String get coupleCircleDescription => '倒计时会自动与您的合作伙伴共享，无需接受邀请。';

  @override
  String get circleCreated => '圈子创建了。';

  @override
  String get coupleCircleCreated => '创建。接下来邀请你的伙伴。';

  @override
  String get inviteYourPartner => '邀请你的伙伴';

  @override
  String inviteToCircle(String circleName) {
    return '邀请加入“$circleName”';
  }

  @override
  String get coupleInviteExplanation =>
      '如果他们已经有帐户，则会自动添加。否则，他们将在登录时添加。与此圈子共享的未来倒计时将自动显示。';

  @override
  String get circleInviteExplanation => '他们将收到接受或拒绝的邀请。他们加入后，您可以一键与此圈子分享倒计时。';

  @override
  String get inviteEmailHint => '他们@example.com';

  @override
  String get sendInvitation => '发送邀请';

  @override
  String get partnerAddedAutomatically => '您的合作伙伴将自动添加。';

  @override
  String get signInToUseCircles => '登录才能使用圈子';

  @override
  String get circlesRequireAccounts => '圈子通过电子邮件邀请人们，因此他们需要一个被邀请的帐户。';

  @override
  String get waitingOnYou => '等着你';

  @override
  String get invitationsEmptyDescription =>
      '在您接受之前，不会与您分享任何内容。拒绝告诉邀请您的人，这样他们就不会猜测。';

  @override
  String get signInToSeeInvitations => '登录查看邀请';

  @override
  String get invitationsEmailAccount => '邀请会发送到您的电子邮件，因此请使用某人邀请的地址登录。';

  @override
  String get invitationsCouldNotLoad => '无法加载邀请。检查您的连接或 Firestore 规则。';

  @override
  String get nothingWaiting => '没什么等待';

  @override
  String get invitationInboxEmpty =>
      '人们发送给您的邀请将显示在此处。倒计时和标准圈子邀请需要您的回复；情侣圈子自动加入。';

  @override
  String get retryAddingYou => '重试添加您';

  @override
  String get decline => '衰退';

  @override
  String joinInviteQuestion(String eventTitle) {
    return '加入“$eventTitle”？';
  }

  @override
  String get joinInviteExplanation => '它将出现在您的列表中，并且您将在此设备上获得其倒计时。';

  @override
  String get join => '加入';

  @override
  String alreadyMemberOf(String name) {
    return '您已经是“$name”的会员。';
  }

  @override
  String youJoined(String name) {
    return '您加入了“$name”。';
  }

  @override
  String youWereAddedTo(String name) {
    return '您已被添加到“$name”。';
  }

  @override
  String get invitationDeclined => '邀请被拒绝。';

  @override
  String get countdownInvitation => '倒计时邀请';

  @override
  String get aCountdown => '倒计时';

  @override
  String invitedToFollowCountdown(String role) {
    return '您已被邀请关注此倒计时。接受会将其作为$role添加到您的列表中。';
  }

  @override
  String get accept => '接受';

  @override
  String get partnerInvitation => '合作伙伴邀请';

  @override
  String get circleInvitation => '圈子邀请';

  @override
  String partnerCircleAddTitle(String personName) {
    return '您将被添加到$personName的圈子中';
  }

  @override
  String get partnerCircleAddExplanation => '您将被自动添加。与此圈子共享的倒计时活动将显示在您的列表中。';

  @override
  String circleJoinExplanation(String circleName) {
    return '加入“$circleName”意味着他们与此圈子分享的倒计时将显示在您的列表中。';
  }

  @override
  String get becomePartners => '成为合作伙伴';

  @override
  String get joinCircle => '加入圈子';

  @override
  String get automaticJoinFailed => '自动加入无法完成。';

  @override
  String get notNow => '现在不要';

  @override
  String get notificationsTitle => '通知';

  @override
  String get markAllRead => '标记全部已读';

  @override
  String get markedAllRead => '标记为全部已读。';

  @override
  String get moreOptions => '更多选择';

  @override
  String get noReadMessagesToDelete => '没有已读消息可删除。';

  @override
  String get deleteReadMessages => '删除已读消息';

  @override
  String get deletedReadMessages => '删除已读消息。';

  @override
  String get notificationsSignInFirst => '首先登录';

  @override
  String get notificationsAccountOnly => '通知与您的帐户绑定。';

  @override
  String get couldNotLoad => '无法加载';

  @override
  String get checkConnectionRetry => '检查您的连接并重试。';

  @override
  String get nothingYet => '还没有什么';

  @override
  String get notificationsEmptyDescription => '当您的倒计时或邀请发生某些情况时，它会显示在此处。';

  @override
  String get liveNotificationsCouldNotLoad => '无法加载实时通知。';

  @override
  String get inbox => '收件箱';

  @override
  String get invitationResponses => '邀请回应';

  @override
  String get invitationResponsesCouldNotLoad => '无法加载邀请回复。';

  @override
  String get countdownUnavailable => '此倒计时不再可用。';

  @override
  String get viewDetails => '查看详情';

  @override
  String get sharedWith => '分享给';

  @override
  String get notes => '笔记';

  @override
  String get notesEmpty => '还什么都没有。给大家留下一个和你一起倒计时的想法。';

  @override
  String get addNote => '添加注释';

  @override
  String get years => '年';

  @override
  String get months => '几个月';

  @override
  String get days => '天';

  @override
  String get hours => '时间';

  @override
  String remainingMinutes(int count) {
    return '$count分钟';
  }

  @override
  String remainingSeconds(int count) {
    return '剩余$count秒';
  }

  @override
  String get cancel => '取消';

  @override
  String get keep => '保持';

  @override
  String get stay => '停留';

  @override
  String get leave => '离开';

  @override
  String get remove => '消除';

  @override
  String get delete => '删除';

  @override
  String get create => '创造';

  @override
  String get tryAgain => '再试一次';

  @override
  String get share => '分享';

  @override
  String get passed => '通过';

  @override
  String get upcoming => '即将推出';

  @override
  String get accepted => '公认';

  @override
  String get declined => '拒绝';

  @override
  String get removed => '已删除';

  @override
  String get reopened => '重新开放';

  @override
  String get waiting => '等待';

  @override
  String get itHasArrived => '它已经到了。';

  @override
  String remainingToGo(String remaining) {
    return '$remaining出发';
  }

  @override
  String get momentHasPassed => '这一刻已经过去了';

  @override
  String remainingAnd(String first, String last) {
    return '$first和$last';
  }

  @override
  String get dayHasCome => '这一天已经到来';

  @override
  String eventArrivedWithDescription(String title, String description) {
    return '$title在这里 —$description';
  }

  @override
  String eventArrivedTitleOnly(String title) {
    return '$title就在这里——享受每一分钟。';
  }

  @override
  String personRemovedFromCircle(String personName, String circleName) {
    return '$personName已从“$circleName”中删除。';
  }

  @override
  String youLeftCircle(String circleName) {
    return '您留下了“$circleName”。';
  }

  @override
  String circleDeleted(String circleName) {
    return '删除了“$circleName”。';
  }

  @override
  String get someone => '有人';

  @override
  String invitedYouToCircle(String personName, String circleName) {
    return '$personName邀请您参加“$circleName”';
  }

  @override
  String get roleAdmin => '行政';

  @override
  String get roleEditor => '编辑';

  @override
  String get roleViewer => '观众';

  @override
  String get roleAdminDescription => '可以管理倒计时及其参与者。';

  @override
  String get roleEditorDescription => '可以编辑倒计时并邀请其他人。';

  @override
  String get roleViewerDescription => '可以查看倒计时并留下笔记。';

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
      other: '$count 小时',
    );
    return '$_temp0';
  }

  @override
  String remainingMinuteUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 分钟',
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
  String get moreActions => '更多行动';

  @override
  String get block => '堵塞';

  @override
  String roleChanged(String personName, String role) {
    return '$personName现在是$role。';
  }

  @override
  String personRemoved(String personName) {
    return '$personName已被删除。';
  }

  @override
  String get signInToSaveIt => '登录以保存它';

  @override
  String get countdownsFollowYou => '倒计时存在于您的帐户中，因此它们会跟随您到每台设备，并可以与其他人共享。';

  @override
  String get savePermissionError =>
      'Firestore 拒绝保存。如果这种情况持续发生，则部署的安全规则比应用程序旧 - 运行“firebase deploy --only firestore:rules”。';

  @override
  String get saveNetworkError => '无法到达 Firestore。检查您的连接并重试。';

  @override
  String get saveFailed => '无法保存。请再试一次。';

  @override
  String get momentPassed => '这一刻已经过去了';

  @override
  String get and => '和';

  @override
  String get back => '后退';

  @override
  String get policyLastUpdated => '最后更新时间：2026 年 2 月 · 符合欧盟 GDPR 和加拿大 PIPEDA';

  @override
  String get privacyIntroTitle => '1. 简介及数据控制者';

  @override
  String privacyIntroBody(String supportEmail) {
    return 'Date Dawn（“我们”或“我们的”）尊重您的隐私并致力于保护您的个人数据。本隐私政策解释了当您使用我们的移动和网络应用程序时我们如何收集、使用和保护您的信息，完全符合欧盟《通用数据保护条例》(GDPR) 和加拿大《个人信息保护和电子文件法》(PIPEDA)。\n\n数据控制者联系人：$supportEmail';
  }

  @override
  String get privacyCollectTitle => '2. 我们收集的信息';

  @override
  String get privacyCollectBody =>
      '• 帐户数据：身份验证 (Firebase Auth) 期间提供的电子邮件地址和显示名称。\n• 用户内容：您明确创建或共享的倒计时、标题、日期、描述和圈子成员身份。\n• 设备和通知数据：推送通知令牌以提供倒计时提醒和邀请警报。\n\n我们不会收集浏览历史记录、广告标识符、位置数据，也不会将任何个人信息出售给第三方。';

  @override
  String get privacyBasisTitle => '3. 处理的法律依据 (EU GDPR)';

  @override
  String get privacyBasisBody =>
      '我们根据以下合法依据处理您的数据：\n• 合同必要性：提供倒计时同步、圈子共享和邀请功能。\n• 同意：当您授予推送通知权限或选择加入共享圈子时。\n• 合法利益：确保应用程序安全性、可靠性并防止滥用。';

  @override
  String get privacySharingTitle => '4. 分享与屏蔽';

  @override
  String get privacySharingBody =>
      'Date Dawn 允许人们进行一对一互动：您可以邀请某人进行倒计时，并且双方都可以在共享的人上留下笔记。该内容仅对倒计时的人可见——从不公开，也从未向其他任何人展示。\n\n您可以随时阻止其他人：打开与他们共享的倒计时，然后长按他们的名字（或在桌面上双击它）。屏蔽会将你们从彼此的倒计时中删除，取消你们之间的邀请，并阻止他们再次邀请您。这个人没有被告知。您已阻止的人员列表对您来说是私人的，您可以从“设置”→“已阻止的人员”中取消阻止任何人。';

  @override
  String get privacyStorageTitle => '5. 数据存储和安全';

  @override
  String get privacyStorageBody =>
      '您的数据将使用符合高行业安全标准的 Firebase（Google Cloud Platform）基础设施安全地存储和处理。您的设备和我们的服务器之间传输的数据在传输过程中使用 TLS 进行加密。';

  @override
  String get privacyRightsTitle => '6. 您的权利（访问、更正和删除）';

  @override
  String privacyRightsBody(String supportEmail) {
    return '根据 GDPR 和 PIPEDA，您有权：\n• 访问：索取我们持有的有关您的个人数据的副本。\n• 更正：更新或更正您在“设置”中的个人资料信息。\n• 删除（被遗忘的权利）：随时联系$supportEmail请求完全删除您的帐户以及所有相关倒计时和通知。';
  }

  @override
  String get termsAcceptanceTitle => '1. 接受条款';

  @override
  String get termsAcceptanceBody =>
      '通过访问或使用 Date Dawn，您同意受这些服务条款的约束。如果您不同意这些条款，请不要使用该应用程序。';

  @override
  String get termsUseTitle => '2. 服务的使用';

  @override
  String get termsUseBody =>
      'Date Dawn 提供个人、非商业倒计时和共享时刻跟踪。您同意不滥用服务、上传恶意内容、通过共享圈子或邀请骚扰其他用户，或尝试绕过安全控制。';

  @override
  String get termsOwnershipTitle => '3. 用户内容和所有权';

  @override
  String get termsOwnershipBody =>
      '您保留对您创建的倒计时活动、标题和内容的所有所有权。您授予 Date Dawn 有限许可，仅用于在经过身份验证的设备和共享圈子成员之间存储和同步您的内容。';

  @override
  String get termsTerminationTitle => '4. 终止和帐户删除';

  @override
  String get termsTerminationBody =>
      '您可以随时停止使用 Date Dawn，并通过向支持人员发送电子邮件请求删除帐户。我们保留暂停或终止违反这些条款或滥用平台基础设施的帐户的权利。';

  @override
  String get termsLiabilityTitle => '5. 责任限制';

  @override
  String get termsLiabilityBody =>
      'Date Dawn 按“原样”提供，不提供任何形式的保证。对于因您使用该应用程序而造成的任何间接、偶然或后果性损害，我们不承担任何责任。';

  @override
  String get privacyPolicyTitle => '隐私政策';

  @override
  String get termsOfServiceTitle => '服务条款';

  @override
  String get supportHeading => '我们阅读每条消息';

  @override
  String supportIntro(String responseTime) {
    return 'Date Dawn 是一个小型的独立应用程序。电子邮件是联系构建者的最快方式——中间没有支持台。我们通常回复$responseTime。';
  }

  @override
  String get supportResponseTime => '2个工作日内';

  @override
  String get supportCommonQuestions => '常见问题';

  @override
  String get supportFaqGoogleQuestion => '我用 Google 登录，但倒计时不见了。';

  @override
  String get supportFaqGoogleAnswer =>
      '使用与创建帐户时相同的方法。 Google 和电子邮件/密码不会自动链接。如果您需要切换方法或认为您在两个帐户中拥有数据，请在创建另一个帐户之前联系我们。';

  @override
  String get supportFaqSharingQuestion => '与我共享的人看不到倒计时。';

  @override
  String get supportFaqSharingAnswer =>
      '与圈子共享倒计时会发送邀请 - 它不会自动添加人员。他们需要在应用程序中打开邀请并接受它。情侣圈是一个例外：它们会立即分享。';

  @override
  String get supportFaqDeclinedQuestion => '我错误地拒绝了邀请。';

  @override
  String get supportFaqDeclinedAnswer =>
      '让邀请你的人再次邀请你——他们可以通过点击你名字旁边的刷新图标从倒计时开始邀请你。在此期间，什么也没有丢失。';

  @override
  String get supportFaqDeleteQuestion => '如何删除我的帐户和数据？';

  @override
  String get supportFaqDeleteAnswer =>
      '从您注册时使用的地址给我们发送电子邮件并要求删除。与该帐户相关的所有倒计时、邀请和通知都会被删除，我们会在完成后进行确认。';

  @override
  String get supportFaqBlockQuestion => '我如何阻止某人？';

  @override
  String get supportFaqBlockAnswer =>
      '打开与他们共享的倒计时，然后在人员列表中长按他们的名字（在计算机上双击）。他们已从您的共享倒计时中删除，并且无法再次邀请您。要撤消它，请转到“设置”→“阻止的人”。';

  @override
  String get supportFaqAdsQuestion => '你们会出售我的数据或展示广告吗？';

  @override
  String get supportFaqAdsAnswer =>
      '不会。没有广告，没有分析配置文件，也没有第三方跟踪。您倒计时的内容与您无关，因此它存储在您自己的帐户下，其他人无法阅读。';

  @override
  String get supportLegal => '合法的';

  @override
  String get supportNotice =>
      '退款、账单问题或崩溃报告都属于同一地址。如果应用程序出现问题，请告诉我们您的设备以及发生问题时您正在做什么，这是您可以包含的最有用的内容。';

  @override
  String get supportEmailLabel => '电子邮件支持';

  @override
  String supportEmailCopied(String email) {
    return '$email已复制';
  }

  @override
  String get openMail => '打开邮件';

  @override
  String get linkCopiedClipboard => '链接已复制到剪贴板。';

  @override
  String get verifyEmailTitle => '验证您的电子邮件';

  @override
  String verifyEmailInstructions(String email) {
    return '我们向$email发送了验证链接。请验证以继续。';
  }

  @override
  String get yourEmailAddress => '您的电子邮件地址';

  @override
  String resetLinkSent(String email) {
    return '重置发送到$email的链接。使用最新的电子邮件。';
  }

  @override
  String get verificationEmailSent => '验证电子邮件已发送。';

  @override
  String get verificationNotComplete => '尚未验证。检查您的收件箱。';

  @override
  String get verifiedSignInToContinue => '您的电子邮件已验证。如果需要，请登录以继续。';

  @override
  String get checkSpamFolder => '找不到电子邮件？请检查您的垃圾邮件或垃圾邮件文件夹。';

  @override
  String get confirmEmailVerified => '我已验证我的电子邮件';

  @override
  String get sendingEmail => '正在发送...';

  @override
  String get resendEmail => '重新发送电子邮件';

  @override
  String get waitBeforeResending => '请等待 60 秒，然后再请求另一封电子邮件。';

  @override
  String get resetCodeMissing => '此重置链接缺少安全代码。';

  @override
  String get passwordUpdatedSignIn => '密码已更新。再次登录。';

  @override
  String get resetLinkInvalidTitle => '无法使用此重置链接';

  @override
  String get resetLinkInvalidBody => '该链接可能已过期或已被使用。返回登录并请求新的密码重置电子邮件。';

  @override
  String get backToSignIn => '返回登录';

  @override
  String get chooseNewPassword => '选择新密码';

  @override
  String get newPassword => '新密码';

  @override
  String get confirmNewPassword => '确认新密码';

  @override
  String get passwordMinLength => '至少使用 6 个字符。';

  @override
  String get passwordsDoNotMatch => '密码不匹配。';

  @override
  String get updatePassword => '更新密码';

  @override
  String get editCountdownAction => '编辑';

  @override
  String get duplicateYearLater => '一年后重复';

  @override
  String get countdownDuplicated => '重复 — 打开它来调整日期。';

  @override
  String get onlyOwnerCanDelete => '只有所有者才能删除此倒计时。';

  @override
  String get countdownDeleteFailed => '无法删除。再试一次。';

  @override
  String get countdownDeleteWarning => '倒计时无法撤消。';

  @override
  String blockPersonQuestion(String personName) {
    return '块$personName？';
  }

  @override
  String get blockExplanation =>
      '你们将不再见面。他们将从您分享的每个倒计时中删除，你们之间的邀请被取消，并且他们无法再次邀请您。他们没有被告知。';

  @override
  String get undoBlockInSettings => '您可以随时在“设置”→“阻止的人”中撤消此操作。';

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
    return '$personName已解锁。';
  }

  @override
  String get blockAccessNotRestored => '倒计时访问未恢复。';

  @override
  String get undoBlockFailed => '无法撤消阻止。请再试一次。';

  @override
  String get blockSaveFailed => '无法保存您的区块。重新登录并重试。';

  @override
  String get noConnectionRetry => '没有连接。检查您的网络并重试。';

  @override
  String blockPersonFailed(String personName) {
    return '无法阻止$personName。请再试一次。';
  }

  @override
  String get blockedPeopleTitle => '被屏蔽的人';

  @override
  String get nobodyBlocked => '没有人被阻止';

  @override
  String get howToBlockPerson => '要阻止某人，请打开与他们共享的倒计时，打开其所在行的 ⋮ 菜单，然后点击“阻止”。';

  @override
  String get blockedPeopleDescription =>
      '这些人无法邀请您，您也不会与他们分享任何倒计时。他们没有被告知他们被封锁了。';

  @override
  String get unblock => '解锁';

  @override
  String get blockedListLoadFailed => '无法加载您的阻止列表';

  @override
  String get blockedListPermissionError => '您的帐户无权阅读此列表。如果这种情况持续发生，请更新应用程序。';

  @override
  String get deleteAccount => '关于如何删除帐户的说明';

  @override
  String get deleteAccountWarning => '此操作是永久性的。您的所有活动、圈子和数据都将被永久删除。';

  @override
  String get deleteAccountConfirmationPrompt => '输入您的确切帐户电子邮件以继续。';

  @override
  String get deleteAccountConfirmationLabel => '账户邮箱';

  @override
  String get permanentlyDeleteAccount => '永久删除帐户';

  @override
  String get deleteAccountProfileConsequence => '您的个人资料将被永久删除。';

  @override
  String get deleteAccountAccessConsequence => '您将无法访问所有活动和圈子。';

  @override
  String get deleteAccountIrreversibleConsequence => '此操作无法撤消。';

  @override
  String get deleteAccountPermanentlyAction => '永久删除帐户';

  @override
  String get accountDeleted => '帐号删除成功';

  @override
  String get serverTimedOutTryAgain => '服务器超时。请稍后重试。';

  @override
  String get accountDeletionFailed => '无法完成帐户删除。请再试一次。';

  @override
  String get accountDeletedCleanupWarning =>
      '帐户已删除，但无法清除某些本地设置。使用其他帐户之前重新启动应用程序。';
}
