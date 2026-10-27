// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'eBuCard';

  @override
  String get navMyCards => '我的名片';

  @override
  String get navExchange => '交换';

  @override
  String get navInbox => '收件箱';

  @override
  String get newCard => '新建名片';

  @override
  String get editCard => '编辑名片';

  @override
  String get myCardsEmpty => '你还没有名片，立即创建你的第一张电子名片。';

  @override
  String get inboxEmpty => '你收到的名片会显示在这里。';

  @override
  String get sendSection => '分享我的名片';

  @override
  String get receiveSection => '接收名片';

  @override
  String get sendByNfc => '手机触碰 (NFC)';

  @override
  String get sendByNfcHint => '将对方手机贴近你手机的背面';

  @override
  String get showQr => '显示二维码';

  @override
  String get receiveByNfc => '通过 NFC 读取';

  @override
  String get scanQr => '扫描二维码';

  @override
  String get signIn => '登录';

  @override
  String get signInWithEmail => '使用邮箱继续';

  @override
  String get signInWithApple => '通过 Apple 登录';

  @override
  String get signInWithGoogle => '通过 Google 登录';

  @override
  String get comingSoon => '即将推出';

  @override
  String get cardName => '名片名称';

  @override
  String get cardNameHint => '例如：工作、个人';

  @override
  String get defaultCardName => '我的名片';

  @override
  String get profileSection => '个人资料';

  @override
  String get contactSection => '联系方式';

  @override
  String get fullName => '姓名';

  @override
  String get jobTitle => '职位';

  @override
  String get company => '公司';

  @override
  String get phones => '电话号码';

  @override
  String get emails => '邮箱地址';

  @override
  String get websites => '网站';

  @override
  String get addresses => '地址';

  @override
  String get socialLinks => '社交账号';

  @override
  String get phone => '电话';

  @override
  String get email => '邮箱';

  @override
  String get website => '网站';

  @override
  String get addPhone => '添加电话';

  @override
  String get addEmail => '添加邮箱';

  @override
  String get addWebsite => '添加网站';

  @override
  String get addAddress => '添加地址';

  @override
  String get addSocialLink => '添加社交账号';

  @override
  String get street => '街道';

  @override
  String get city => '城市';

  @override
  String get region => '省／地区';

  @override
  String get postalCode => '邮政编码';

  @override
  String get country => '国家／地区';

  @override
  String get handleOrUrl => '用户名或链接';

  @override
  String get labelWork => '工作';

  @override
  String get labelMobile => '手机';

  @override
  String get labelHome => '住宅';

  @override
  String get labelFax => '传真';

  @override
  String get labelOther => '其他';

  @override
  String get photo => '照片';

  @override
  String get logo => '标志';

  @override
  String get cropImage => '裁剪图片';

  @override
  String get chooseFromGallery => '从相册选择';

  @override
  String get takePhoto => '拍照';

  @override
  String get removeImage => '移除';

  @override
  String get remove => '移除';

  @override
  String get save => '保存';

  @override
  String get delete => '删除';

  @override
  String get cancel => '取消';

  @override
  String get deleteCardTitle => '删除此名片？';

  @override
  String get deleteCardMessage => '此名片将从此设备中删除。';

  @override
  String get cardSaved => '名片已保存';

  @override
  String get cardNotFound => '此名片已不存在。';

  @override
  String get errorFullNameRequired => '请输入姓名';

  @override
  String get errorPhoneOrEmailRequired => '请至少填写一个电话号码或邮箱地址';

  @override
  String get errorInvalidEmail => '请输入有效的邮箱地址';

  @override
  String get errorImage => '无法加载图片，请重试。';

  @override
  String get socialOther => '其他';

  @override
  String get showQrTitle => '我的二维码';

  @override
  String get showQrHint => '请对方用 eBuCard 或手机相机扫描此二维码。';

  @override
  String get showQrNoCards => '请先创建名片，然后即可在此分享。';

  @override
  String get createCard => '创建名片';

  @override
  String get qrTooLarge => '此名片信息太多，无法放入一个二维码。请删减部分字段后重试。';

  @override
  String get showingCard => '要分享的名片';

  @override
  String get setAsDefault => '设为默认名片';

  @override
  String get isDefaultCard => '默认名片';

  @override
  String get defaultCardSet => '已更新默认名片';

  @override
  String get scanHint => '将相机对准 eBuCard 或联系人二维码。';

  @override
  String get notACard => '此二维码不是名片。';

  @override
  String get cameraError => '无法使用相机。请在“设置”中允许 eBuCard 使用相机。';

  @override
  String get duplicateTitle => '已在收件箱中';

  @override
  String duplicateMessage(String name) {
    return '$name 已在你的收件箱中。要更新已保存的名片，还是两张都保留？';
  }

  @override
  String get update => '更新';

  @override
  String get keepBoth => '两张都保留';

  @override
  String get cardReceived => '名片已加入收件箱';

  @override
  String get cardUpdated => '名片已更新';

  @override
  String get searchInbox => '搜索姓名、公司或邮箱';

  @override
  String get inboxNoMatches => '没有匹配的名片';

  @override
  String receivedOn(String date) {
    return '收于 $date';
  }

  @override
  String get note => '私人备注';

  @override
  String get noteHint => '只有你能看到，例如在哪里认识';

  @override
  String get saveNote => '保存备注';

  @override
  String get noteSaved => '备注已保存';

  @override
  String get saveToContacts => '保存到通讯录';

  @override
  String get contactsError => '无法打开通讯录。';

  @override
  String get cantOpenLink => '此手机上没有可打开此内容的应用。';

  @override
  String get deleteReceivedTitle => '要从收件箱删除此名片吗？';

  @override
  String get deleteReceivedMessage => '只会从 eBuCard 删除，不会从手机通讯录删除。';

  @override
  String get nfcShareTitle => '手机触碰 (NFC)';

  @override
  String get nfcShareReady => '准备分享';

  @override
  String get nfcShareHint =>
      '请保持此页面打开，并将手机背面贴近对方手机。对方需在 eBuCard 打开“交换”→“通过 NFC 读取”。';

  @override
  String get nfcCannotShare => '此手机无法通过 NFC 分享，请改用二维码。';

  @override
  String get nfcUnsupported => '此手机没有 NFC，请改用二维码。';

  @override
  String get nfcOff => 'NFC 已关闭';

  @override
  String get nfcOffMessage => '打开 NFC 后即可通过手机触碰交换名片。在此期间可先使用二维码。';

  @override
  String get openNfcSettings => '打开 NFC 设置';

  @override
  String get useQrInstead => '改用二维码';

  @override
  String get nfcReceiveTitle => '通过 NFC 读取';

  @override
  String get nfcReceiveListening => '将手机贴近对方手机背面';

  @override
  String get nfcReceiveHint =>
      '对方需在 eBuCard 打开“交换”→“手机触碰 (NFC)”。iPhone 无法通过 NFC 分享，请对方出示二维码。';

  @override
  String get nfcIosAlert => '将 iPhone 靠近对方手机。';

  @override
  String get nfcIosSuccess => '已收到名片';

  @override
  String get nfcStopped => '已停止读取。';

  @override
  String get tryAgain => '重试';

  @override
  String get nfcNotACard => '对方手机没有分享名片。';
}

/// The translations for Chinese, using the Han script (`zh_Hans`).
class AppLocalizationsZhHans extends AppLocalizationsZh {
  AppLocalizationsZhHans() : super('zh_Hans');

  @override
  String get appTitle => 'eBuCard';

  @override
  String get navMyCards => '我的名片';

  @override
  String get navExchange => '交换';

  @override
  String get navInbox => '收件箱';

  @override
  String get newCard => '新建名片';

  @override
  String get editCard => '编辑名片';

  @override
  String get myCardsEmpty => '你还没有名片，立即创建你的第一张电子名片。';

  @override
  String get inboxEmpty => '你收到的名片会显示在这里。';

  @override
  String get sendSection => '分享我的名片';

  @override
  String get receiveSection => '接收名片';

  @override
  String get sendByNfc => '手机触碰 (NFC)';

  @override
  String get sendByNfcHint => '将对方手机贴近你手机的背面';

  @override
  String get showQr => '显示二维码';

  @override
  String get receiveByNfc => '通过 NFC 读取';

  @override
  String get scanQr => '扫描二维码';

  @override
  String get signIn => '登录';

  @override
  String get signInWithEmail => '使用邮箱继续';

  @override
  String get signInWithApple => '通过 Apple 登录';

  @override
  String get signInWithGoogle => '通过 Google 登录';

  @override
  String get comingSoon => '即将推出';

  @override
  String get cardName => '名片名称';

  @override
  String get cardNameHint => '例如：工作、个人';

  @override
  String get defaultCardName => '我的名片';

  @override
  String get profileSection => '个人资料';

  @override
  String get contactSection => '联系方式';

  @override
  String get fullName => '姓名';

  @override
  String get jobTitle => '职位';

  @override
  String get company => '公司';

  @override
  String get phones => '电话号码';

  @override
  String get emails => '邮箱地址';

  @override
  String get websites => '网站';

  @override
  String get addresses => '地址';

  @override
  String get socialLinks => '社交账号';

  @override
  String get phone => '电话';

  @override
  String get email => '邮箱';

  @override
  String get website => '网站';

  @override
  String get addPhone => '添加电话';

  @override
  String get addEmail => '添加邮箱';

  @override
  String get addWebsite => '添加网站';

  @override
  String get addAddress => '添加地址';

  @override
  String get addSocialLink => '添加社交账号';

  @override
  String get street => '街道';

  @override
  String get city => '城市';

  @override
  String get region => '省／地区';

  @override
  String get postalCode => '邮政编码';

  @override
  String get country => '国家／地区';

  @override
  String get handleOrUrl => '用户名或链接';

  @override
  String get labelWork => '工作';

  @override
  String get labelMobile => '手机';

  @override
  String get labelHome => '住宅';

  @override
  String get labelFax => '传真';

  @override
  String get labelOther => '其他';

  @override
  String get photo => '照片';

  @override
  String get logo => '标志';

  @override
  String get cropImage => '裁剪图片';

  @override
  String get chooseFromGallery => '从相册选择';

  @override
  String get takePhoto => '拍照';

  @override
  String get removeImage => '移除';

  @override
  String get remove => '移除';

  @override
  String get save => '保存';

  @override
  String get delete => '删除';

  @override
  String get cancel => '取消';

  @override
  String get deleteCardTitle => '删除此名片？';

  @override
  String get deleteCardMessage => '此名片将从此设备中删除。';

  @override
  String get cardSaved => '名片已保存';

  @override
  String get cardNotFound => '此名片已不存在。';

  @override
  String get errorFullNameRequired => '请输入姓名';

  @override
  String get errorPhoneOrEmailRequired => '请至少填写一个电话号码或邮箱地址';

  @override
  String get errorInvalidEmail => '请输入有效的邮箱地址';

  @override
  String get errorImage => '无法加载图片，请重试。';

  @override
  String get socialOther => '其他';

  @override
  String get showQrTitle => '我的二维码';

  @override
  String get showQrHint => '请对方用 eBuCard 或手机相机扫描此二维码。';

  @override
  String get showQrNoCards => '请先创建名片，然后即可在此分享。';

  @override
  String get createCard => '创建名片';

  @override
  String get qrTooLarge => '此名片信息太多，无法放入一个二维码。请删减部分字段后重试。';

  @override
  String get showingCard => '要分享的名片';

  @override
  String get setAsDefault => '设为默认名片';

  @override
  String get isDefaultCard => '默认名片';

  @override
  String get defaultCardSet => '已更新默认名片';

  @override
  String get scanHint => '将相机对准 eBuCard 或联系人二维码。';

  @override
  String get notACard => '此二维码不是名片。';

  @override
  String get cameraError => '无法使用相机。请在“设置”中允许 eBuCard 使用相机。';

  @override
  String get duplicateTitle => '已在收件箱中';

  @override
  String duplicateMessage(String name) {
    return '$name 已在你的收件箱中。要更新已保存的名片，还是两张都保留？';
  }

  @override
  String get update => '更新';

  @override
  String get keepBoth => '两张都保留';

  @override
  String get cardReceived => '名片已加入收件箱';

  @override
  String get cardUpdated => '名片已更新';

  @override
  String get searchInbox => '搜索姓名、公司或邮箱';

  @override
  String get inboxNoMatches => '没有匹配的名片';

  @override
  String receivedOn(String date) {
    return '收于 $date';
  }

  @override
  String get note => '私人备注';

  @override
  String get noteHint => '只有你能看到，例如在哪里认识';

  @override
  String get saveNote => '保存备注';

  @override
  String get noteSaved => '备注已保存';

  @override
  String get saveToContacts => '保存到通讯录';

  @override
  String get contactsError => '无法打开通讯录。';

  @override
  String get cantOpenLink => '此手机上没有可打开此内容的应用。';

  @override
  String get deleteReceivedTitle => '要从收件箱删除此名片吗？';

  @override
  String get deleteReceivedMessage => '只会从 eBuCard 删除，不会从手机通讯录删除。';

  @override
  String get nfcShareTitle => '手机触碰 (NFC)';

  @override
  String get nfcShareReady => '准备分享';

  @override
  String get nfcShareHint =>
      '请保持此页面打开，并将手机背面贴近对方手机。对方需在 eBuCard 打开“交换”→“通过 NFC 读取”。';

  @override
  String get nfcCannotShare => '此手机无法通过 NFC 分享，请改用二维码。';

  @override
  String get nfcUnsupported => '此手机没有 NFC，请改用二维码。';

  @override
  String get nfcOff => 'NFC 已关闭';

  @override
  String get nfcOffMessage => '打开 NFC 后即可通过手机触碰交换名片。在此期间可先使用二维码。';

  @override
  String get openNfcSettings => '打开 NFC 设置';

  @override
  String get useQrInstead => '改用二维码';

  @override
  String get nfcReceiveTitle => '通过 NFC 读取';

  @override
  String get nfcReceiveListening => '将手机贴近对方手机背面';

  @override
  String get nfcReceiveHint =>
      '对方需在 eBuCard 打开“交换”→“手机触碰 (NFC)”。iPhone 无法通过 NFC 分享，请对方出示二维码。';

  @override
  String get nfcIosAlert => '将 iPhone 靠近对方手机。';

  @override
  String get nfcIosSuccess => '已收到名片';

  @override
  String get nfcStopped => '已停止读取。';

  @override
  String get tryAgain => '重试';

  @override
  String get nfcNotACard => '对方手机没有分享名片。';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get appTitle => 'eBuCard';

  @override
  String get navMyCards => '我的名片';

  @override
  String get navExchange => '交換';

  @override
  String get navInbox => '收件匣';

  @override
  String get newCard => '新增名片';

  @override
  String get editCard => '編輯名片';

  @override
  String get myCardsEmpty => '你還沒有名片，立即建立你的第一張電子名片。';

  @override
  String get inboxEmpty => '你收到的名片會顯示在這裡。';

  @override
  String get sendSection => '分享我的名片';

  @override
  String get receiveSection => '接收名片';

  @override
  String get sendByNfc => '手機觸碰 (NFC)';

  @override
  String get sendByNfcHint => '將對方手機貼近你手機的背面';

  @override
  String get showQr => '顯示 QR 碼';

  @override
  String get receiveByNfc => '以 NFC 讀取';

  @override
  String get scanQr => '掃描 QR 碼';

  @override
  String get signIn => '登入';

  @override
  String get signInWithEmail => '使用電郵繼續';

  @override
  String get signInWithApple => '使用 Apple 登入';

  @override
  String get signInWithGoogle => '使用 Google 登入';

  @override
  String get comingSoon => '即將推出';

  @override
  String get cardName => '名片名稱';

  @override
  String get cardNameHint => '例如：工作、私人';

  @override
  String get defaultCardName => '我的名片';

  @override
  String get profileSection => '個人資料';

  @override
  String get contactSection => '聯絡方式';

  @override
  String get fullName => '姓名';

  @override
  String get jobTitle => '職位';

  @override
  String get company => '公司';

  @override
  String get phones => '電話號碼';

  @override
  String get emails => '電郵地址';

  @override
  String get websites => '網站';

  @override
  String get addresses => '地址';

  @override
  String get socialLinks => '社交網絡';

  @override
  String get phone => '電話';

  @override
  String get email => '電郵';

  @override
  String get website => '網站';

  @override
  String get addPhone => '新增電話';

  @override
  String get addEmail => '新增電郵';

  @override
  String get addWebsite => '新增網站';

  @override
  String get addAddress => '新增地址';

  @override
  String get addSocialLink => '新增社交網絡';

  @override
  String get street => '街道';

  @override
  String get city => '城市';

  @override
  String get region => '州／地區';

  @override
  String get postalCode => '郵政編碼';

  @override
  String get country => '國家／地區';

  @override
  String get handleOrUrl => '用戶名稱或連結';

  @override
  String get labelWork => '工作';

  @override
  String get labelMobile => '手機';

  @override
  String get labelHome => '住宅';

  @override
  String get labelFax => '傳真';

  @override
  String get labelOther => '其他';

  @override
  String get photo => '相片';

  @override
  String get logo => '標誌';

  @override
  String get cropImage => '裁剪圖片';

  @override
  String get chooseFromGallery => '從相簿選擇';

  @override
  String get takePhoto => '拍照';

  @override
  String get removeImage => '移除';

  @override
  String get remove => '移除';

  @override
  String get save => '儲存';

  @override
  String get delete => '刪除';

  @override
  String get cancel => '取消';

  @override
  String get deleteCardTitle => '刪除此名片？';

  @override
  String get deleteCardMessage => '此名片將從此裝置中移除。';

  @override
  String get cardSaved => '名片已儲存';

  @override
  String get cardNotFound => '此名片已不存在。';

  @override
  String get errorFullNameRequired => '請輸入姓名';

  @override
  String get errorPhoneOrEmailRequired => '請至少輸入一個電話號碼或電郵地址';

  @override
  String get errorInvalidEmail => '請輸入有效的電郵地址';

  @override
  String get errorImage => '無法載入圖片，請再試一次。';

  @override
  String get socialOther => '其他';

  @override
  String get showQrTitle => '我的 QR 碼';

  @override
  String get showQrHint => '請對方用 eBuCard 或手機相機掃描此 QR 碼。';

  @override
  String get showQrNoCards => '請先建立名片，然後便可在此分享。';

  @override
  String get createCard => '建立名片';

  @override
  String get qrTooLarge => '此名片資料太多，無法放入一個 QR 碼。請刪減部分欄位後再試。';

  @override
  String get showingCard => '要分享的名片';

  @override
  String get setAsDefault => '設為預設名片';

  @override
  String get isDefaultCard => '預設名片';

  @override
  String get defaultCardSet => '已更新預設名片';

  @override
  String get scanHint => '將相機對準 eBuCard 或聯絡人 QR 碼。';

  @override
  String get notACard => '此 QR 碼不是名片。';

  @override
  String get cameraError => '無法使用相機。請在「設定」中允許 eBuCard 使用相機。';

  @override
  String get duplicateTitle => '已在收件匣中';

  @override
  String duplicateMessage(String name) {
    return '$name 已在你的收件匣中。要更新已儲存的名片，還是兩張都保留？';
  }

  @override
  String get update => '更新';

  @override
  String get keepBoth => '兩張都保留';

  @override
  String get cardReceived => '名片已加入收件匣';

  @override
  String get cardUpdated => '名片已更新';

  @override
  String get searchInbox => '搜尋姓名、公司或電郵';

  @override
  String get inboxNoMatches => '沒有相符的名片';

  @override
  String receivedOn(String date) {
    return '收於 $date';
  }

  @override
  String get note => '私人備註';

  @override
  String get noteHint => '只有你看得到，例如在哪裡認識';

  @override
  String get saveNote => '儲存備註';

  @override
  String get noteSaved => '備註已儲存';

  @override
  String get saveToContacts => '儲存至通訊錄';

  @override
  String get contactsError => '無法開啟通訊錄。';

  @override
  String get cantOpenLink => '此手機上沒有可開啟此內容的應用程式。';

  @override
  String get deleteReceivedTitle => '要從收件匣移除此名片嗎？';

  @override
  String get deleteReceivedMessage => '只會從 eBuCard 移除，不會從手機通訊錄刪除。';

  @override
  String get nfcShareTitle => '手機觸碰 (NFC)';

  @override
  String get nfcShareReady => '準備分享';

  @override
  String get nfcShareHint =>
      '請保持此畫面開啟，並將手機背面貼近對方手機。對方須在 eBuCard 開啟「交換」→「以 NFC 讀取」。';

  @override
  String get nfcCannotShare => '此手機無法以 NFC 分享，請改用 QR 碼。';

  @override
  String get nfcUnsupported => '此手機沒有 NFC，請改用 QR 碼。';

  @override
  String get nfcOff => 'NFC 已關閉';

  @override
  String get nfcOffMessage => '開啟 NFC 後即可以手機觸碰交換名片。期間可先使用 QR 碼。';

  @override
  String get openNfcSettings => '開啟 NFC 設定';

  @override
  String get useQrInstead => '改用 QR 碼';

  @override
  String get nfcReceiveTitle => '以 NFC 讀取';

  @override
  String get nfcReceiveListening => '將手機貼近對方手機背面';

  @override
  String get nfcReceiveHint =>
      '對方須在 eBuCard 開啟「交換」→「手機觸碰 (NFC)」。iPhone 無法以 NFC 分享，請對方出示 QR 碼。';

  @override
  String get nfcIosAlert => '將 iPhone 靠近對方手機。';

  @override
  String get nfcIosSuccess => '已收到名片';

  @override
  String get nfcStopped => '已停止讀取。';

  @override
  String get tryAgain => '再試一次';

  @override
  String get nfcNotACard => '對方手機沒有分享名片。';
}
