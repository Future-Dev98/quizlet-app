import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// No description provided for @listenAgain.
  ///
  /// In vi, this message translates to:
  /// **'Nghe lại'**
  String get listenAgain;

  /// No description provided for @continueListening.
  ///
  /// In vi, this message translates to:
  /// **'Nghe tiếp'**
  String get continueListening;

  /// No description provided for @femaleVoice.
  ///
  /// In vi, this message translates to:
  /// **'Nữ'**
  String get femaleVoice;

  /// No description provided for @maleVoice.
  ///
  /// In vi, this message translates to:
  /// **'Nam'**
  String get maleVoice;

  /// No description provided for @enhancedVoice.
  ///
  /// In vi, this message translates to:
  /// **'Chất lượng cao'**
  String get enhancedVoice;

  /// No description provided for @premiumVoice.
  ///
  /// In vi, this message translates to:
  /// **'Cao cấp'**
  String get premiumVoice;

  /// No description provided for @downloadVoicesHint.
  ///
  /// In vi, this message translates to:
  /// **'Để có thêm giọng nữ tiếng Hàn và tiếng Việt, tải giọng trong Cài đặt iPhone → Trợ năng → Nội dung được đọc hoặc Đọc & nói → Giọng nói. Sau đó mở lại Tùy chọn để cập nhật danh sách.'**
  String get downloadVoicesHint;

  /// No description provided for @addWord.
  ///
  /// In vi, this message translates to:
  /// **'Thêm từ'**
  String get addWord;

  /// No description provided for @saveWord.
  ///
  /// In vi, this message translates to:
  /// **'Lưu từ'**
  String get saveWord;

  /// No description provided for @autoDetailsHint.
  ///
  /// In vi, this message translates to:
  /// **'Cách dùng, ví dụ và từ đồng nghĩa sẽ được tra tự động khi lưu.'**
  String get autoDetailsHint;

  /// No description provided for @wordActions.
  ///
  /// In vi, this message translates to:
  /// **'Thao tác với từ'**
  String get wordActions;

  /// No description provided for @wordListHint.
  ///
  /// In vi, this message translates to:
  /// **'Chạm vào từ để xem chi tiết · Kéo biểu tượng bên trái để sắp xếp'**
  String get wordListHint;

  /// No description provided for @reorderWord.
  ///
  /// In vi, this message translates to:
  /// **'Kéo để sắp xếp từ'**
  String get reorderWord;

  /// No description provided for @clearSearch.
  ///
  /// In vi, this message translates to:
  /// **'Xóa tìm kiếm'**
  String get clearSearch;

  /// No description provided for @cardDetails.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết thẻ'**
  String get cardDetails;

  /// No description provided for @wordUsage.
  ///
  /// In vi, this message translates to:
  /// **'Cách sử dụng'**
  String get wordUsage;

  /// No description provided for @usageExamples.
  ///
  /// In vi, this message translates to:
  /// **'Ví dụ sử dụng'**
  String get usageExamples;

  /// No description provided for @wordSynonyms.
  ///
  /// In vi, this message translates to:
  /// **'Từ đồng nghĩa'**
  String get wordSynonyms;

  /// No description provided for @dictionaryMeanings.
  ///
  /// In vi, this message translates to:
  /// **'Nghĩa và từ loại từ từ điển'**
  String get dictionaryMeanings;

  /// No description provided for @noDictionaryMeanings.
  ///
  /// In vi, this message translates to:
  /// **'Từ điển chưa có thông tin nghĩa.'**
  String get noDictionaryMeanings;

  /// No description provided for @noUsageNotes.
  ///
  /// In vi, this message translates to:
  /// **'Từ điển chưa có ghi chú cách dùng. Tham khảo nghĩa, từ loại và ví dụ bên dưới.'**
  String get noUsageNotes;

  /// No description provided for @noUsageExamples.
  ///
  /// In vi, this message translates to:
  /// **'Từ điển chưa có ví dụ cho từ này.'**
  String get noUsageExamples;

  /// No description provided for @noSynonyms.
  ///
  /// In vi, this message translates to:
  /// **'Từ điển chưa liệt kê từ đồng nghĩa cho từ này.'**
  String get noSynonyms;

  /// No description provided for @noSavedDetails.
  ///
  /// In vi, this message translates to:
  /// **'Thẻ này chưa có dữ liệu chi tiết. Chọn Tra chi tiết để tìm và lưu.'**
  String get noSavedDetails;

  /// No description provided for @lookupDetails.
  ///
  /// In vi, this message translates to:
  /// **'Tra chi tiết'**
  String get lookupDetails;

  /// No description provided for @refreshDetails.
  ///
  /// In vi, this message translates to:
  /// **'Tra lại và lưu'**
  String get refreshDetails;

  /// No description provided for @closeDetails.
  ///
  /// In vi, this message translates to:
  /// **'Đóng'**
  String get closeDetails;

  /// No description provided for @noDictionaryEntry.
  ///
  /// In vi, this message translates to:
  /// **'Chưa tìm thấy mục từ cho ngôn ngữ đã chọn. Kiểm tra chính tả và Ngôn ngữ của từ trong Tùy chọn thẻ.'**
  String get noDictionaryEntry;

  /// No description provided for @dictionaryLookupError.
  ///
  /// In vi, this message translates to:
  /// **'Chưa tra được từ điển. Kiểm tra kết nối mạng rồi thử lại. Dữ liệu đã lưu được giữ nguyên.'**
  String get dictionaryLookupError;

  /// No description provided for @dictionarySourceNotice.
  ///
  /// In vi, this message translates to:
  /// **'Nguồn: Wiktionary · CC BY-SA. Giữ nguyên ngôn ngữ nguồn; một từ có thể có nhiều nghĩa và cách dùng.'**
  String get dictionarySourceNotice;

  /// No description provided for @copySource.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép nguồn'**
  String get copySource;

  /// No description provided for @sourceCopied.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép liên kết nguồn.'**
  String get sourceCopied;

  /// No description provided for @wordSuggestions.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý từ · Chạm để xem chi tiết'**
  String get wordSuggestions;

  /// No description provided for @lookingUpWords.
  ///
  /// In vi, this message translates to:
  /// **'Đang tra cách dùng và từ đồng nghĩa'**
  String get lookingUpWords;

  /// No description provided for @dictionaryNetworkNotice.
  ///
  /// In vi, this message translates to:
  /// **'Tra từ trên Wiktionary theo Ngôn ngữ của từ. Chỉ gửi từ cần tra; kết quả được lưu cùng thẻ để xem offline.'**
  String get dictionaryNetworkNotice;

  /// No description provided for @skipLookup.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ qua tra cứu và lưu từ'**
  String get skipLookup;

  /// No description provided for @detailsMissing.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu từ. {count} thẻ chưa có chi tiết từ điển; có thể tra lại từ popup.'**
  String detailsMissing(int count);

  /// No description provided for @appTitle.
  ///
  /// In vi, this message translates to:
  /// **'Từ Vựng'**
  String get appTitle;

  /// No description provided for @brand.
  ///
  /// In vi, this message translates to:
  /// **'từ vựng'**
  String get brand;

  /// No description provided for @saveError.
  ///
  /// In vi, this message translates to:
  /// **'Chưa lưu được dữ liệu. Kiểm tra dung lượng máy và thử lại.'**
  String get saveError;

  /// No description provided for @loadError.
  ///
  /// In vi, this message translates to:
  /// **'Không đọc được dữ liệu. Dữ liệu hiện có được giữ lại.'**
  String get loadError;

  /// No description provided for @retry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get retry;

  /// No description provided for @home.
  ///
  /// In vi, this message translates to:
  /// **'Trang chủ'**
  String get home;

  /// No description provided for @library.
  ///
  /// In vi, this message translates to:
  /// **'Thư viện'**
  String get library;

  /// No description provided for @profile.
  ///
  /// In vi, this message translates to:
  /// **'Cá nhân'**
  String get profile;

  /// No description provided for @createSet.
  ///
  /// In vi, this message translates to:
  /// **'Tạo danh mục'**
  String get createSet;

  /// No description provided for @homeHeading.
  ///
  /// In vi, this message translates to:
  /// **'Mỗi từ mới là một\nbước tiến nhỏ.'**
  String get homeHeading;

  /// No description provided for @yourLibrary.
  ///
  /// In vi, this message translates to:
  /// **'Thư viện của bạn'**
  String get yourLibrary;

  /// No description provided for @tagline.
  ///
  /// In vi, this message translates to:
  /// **'Học theo nhịp của bạn. Ghi nhớ mỗi ngày.'**
  String get tagline;

  /// No description provided for @journey.
  ///
  /// In vi, this message translates to:
  /// **'HÀNH TRÌNH CỦA BẠN'**
  String get journey;

  /// No description provided for @continueLearning.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục học   →'**
  String get continueLearning;

  /// No description provided for @searchSets.
  ///
  /// In vi, this message translates to:
  /// **'Tìm danh mục, từ vựng…'**
  String get searchSets;

  /// No description provided for @parentFolder.
  ///
  /// In vi, this message translates to:
  /// **'Thư mục cha'**
  String get parentFolder;

  /// No description provided for @createFolder.
  ///
  /// In vi, this message translates to:
  /// **'Tạo thư mục'**
  String get createFolder;

  /// No description provided for @openFolder.
  ///
  /// In vi, this message translates to:
  /// **'Mở thư mục'**
  String get openFolder;

  /// No description provided for @editFolder.
  ///
  /// In vi, this message translates to:
  /// **'Sửa thư mục'**
  String get editFolder;

  /// No description provided for @emptyLibrary.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có danh mục phù hợp. Tạo danh mục để bắt đầu.'**
  String get emptyLibrary;

  /// No description provided for @folderName.
  ///
  /// In vi, this message translates to:
  /// **'Tên thư mục'**
  String get folderName;

  /// No description provided for @rootLibrary.
  ///
  /// In vi, this message translates to:
  /// **'Thư viện gốc'**
  String get rootLibrary;

  /// No description provided for @deleteEmptyFolder.
  ///
  /// In vi, this message translates to:
  /// **'Xóa thư mục trống'**
  String get deleteEmptyFolder;

  /// No description provided for @cancel.
  ///
  /// In vi, this message translates to:
  /// **'Hủy'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In vi, this message translates to:
  /// **'Lưu'**
  String get save;

  /// No description provided for @folderNotEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ xóa được thư mục trống. Hãy chuyển nội dung ra trước.'**
  String get folderNotEmpty;

  /// No description provided for @studyCorner.
  ///
  /// In vi, this message translates to:
  /// **'Góc học tập'**
  String get studyCorner;

  /// No description provided for @yourJourney.
  ///
  /// In vi, this message translates to:
  /// **'Kiến thức của bạn, hành trình của bạn.'**
  String get yourJourney;

  /// No description provided for @themeSettings.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt · Giao diện'**
  String get themeSettings;

  /// No description provided for @themeHint.
  ///
  /// In vi, this message translates to:
  /// **'Chọn màu nền và chữ cho ứng dụng.'**
  String get themeHint;

  /// No description provided for @lightTheme.
  ///
  /// In vi, this message translates to:
  /// **'Sáng'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In vi, this message translates to:
  /// **'Tối'**
  String get darkTheme;

  /// No description provided for @smallStep.
  ///
  /// In vi, this message translates to:
  /// **'Mỗi từ mới là một bước tiến nhỏ.'**
  String get smallStep;

  /// No description provided for @darkPreview.
  ///
  /// In vi, this message translates to:
  /// **'Nền tối · Chữ sáng'**
  String get darkPreview;

  /// No description provided for @lightPreview.
  ///
  /// In vi, this message translates to:
  /// **'Nền sáng · Chữ tối'**
  String get lightPreview;

  /// No description provided for @copyBackup.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép bản sao lưu'**
  String get copyBackup;

  /// No description provided for @backupHint.
  ///
  /// In vi, this message translates to:
  /// **'Bộ từ, thư mục, cài đặt và tiến độ (JSON)'**
  String get backupHint;

  /// No description provided for @backupCopied.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép bản sao lưu. Bản ghi âm được lưu riêng trên máy.'**
  String get backupCopied;

  /// No description provided for @restoreJson.
  ///
  /// In vi, this message translates to:
  /// **'Khôi phục từ JSON'**
  String get restoreJson;

  /// No description provided for @privacyNotice.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu lưu riêng trên thiết bị, không cần tài khoản. Gỡ app có thể xóa dữ liệu; hãy sao lưu trước khi đổi máy. Chấm phát âm cần máy chủ Azure và kết nối mạng.'**
  String get privacyNotice;

  /// No description provided for @restoreData.
  ///
  /// In vi, this message translates to:
  /// **'Khôi phục dữ liệu'**
  String get restoreData;

  /// No description provided for @pasteBackup.
  ///
  /// In vi, this message translates to:
  /// **'Dán JSON đã sao lưu…'**
  String get pasteBackup;

  /// No description provided for @check.
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra'**
  String get check;

  /// No description provided for @replaceData.
  ///
  /// In vi, this message translates to:
  /// **'Thay thế dữ liệu hiện tại?'**
  String get replaceData;

  /// No description provided for @invalidJson.
  ///
  /// In vi, this message translates to:
  /// **'JSON không hợp lệ. Dữ liệu hiện tại được giữ nguyên.'**
  String get invalidJson;

  /// No description provided for @agree.
  ///
  /// In vi, this message translates to:
  /// **'Đồng ý'**
  String get agree;

  /// No description provided for @editSet.
  ///
  /// In vi, this message translates to:
  /// **'Sửa danh mục'**
  String get editSet;

  /// No description provided for @setName.
  ///
  /// In vi, this message translates to:
  /// **'Tên danh mục'**
  String get setName;

  /// No description provided for @enterSetName.
  ///
  /// In vi, this message translates to:
  /// **'Nhập tên danh mục'**
  String get enterSetName;

  /// No description provided for @description.
  ///
  /// In vi, this message translates to:
  /// **'Mô tả'**
  String get description;

  /// No description provided for @folder.
  ///
  /// In vi, this message translates to:
  /// **'Thư mục'**
  String get folder;

  /// No description provided for @displayOrder.
  ///
  /// In vi, this message translates to:
  /// **'Thứ tự hiển thị'**
  String get displayOrder;

  /// No description provided for @orderValidation.
  ///
  /// In vi, this message translates to:
  /// **'Nhập số từ 0 đến 1000000'**
  String get orderValidation;

  /// No description provided for @saveSet.
  ///
  /// In vi, this message translates to:
  /// **'Lưu danh mục'**
  String get saveSet;

  /// No description provided for @noImportWords.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có từ để nhập.'**
  String get noImportWords;

  /// No description provided for @quiz.
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra'**
  String get quiz;

  /// No description provided for @reflex.
  ///
  /// In vi, this message translates to:
  /// **'Phản xạ'**
  String get reflex;

  /// No description provided for @writing.
  ///
  /// In vi, this message translates to:
  /// **'Luyện viết'**
  String get writing;

  /// No description provided for @positiveCount.
  ///
  /// In vi, this message translates to:
  /// **'Nhập số câu lớn hơn 0.'**
  String get positiveCount;

  /// No description provided for @addBeforePractice.
  ///
  /// In vi, this message translates to:
  /// **'Thêm từ vựng trước khi luyện tập.'**
  String get addBeforePractice;

  /// No description provided for @distinctMeanings.
  ///
  /// In vi, this message translates to:
  /// **'Cần ít nhất 2 nghĩa khác nhau để tạo đáp án.'**
  String get distinctMeanings;

  /// No description provided for @writingHeading.
  ///
  /// In vi, this message translates to:
  /// **'Nhìn nghĩa, viết lại từ.'**
  String get writingHeading;

  /// No description provided for @reflexHeading.
  ///
  /// In vi, this message translates to:
  /// **'Nhanh tay chọn đáp án.'**
  String get reflexHeading;

  /// No description provided for @quizHeading.
  ///
  /// In vi, this message translates to:
  /// **'Sẵn sàng thử sức?'**
  String get quizHeading;

  /// No description provided for @writingHint.
  ///
  /// In vi, this message translates to:
  /// **'Viết từ tương ứng. Bạn có thể hiện đáp án để tự ôn tập.'**
  String get writingHint;

  /// No description provided for @quizHint.
  ///
  /// In vi, this message translates to:
  /// **'Câu hỏi được trộn ngẫu nhiên. Đáp án sai lấy từ các từ trong danh mục.'**
  String get quizHint;

  /// No description provided for @questionCount.
  ///
  /// In vi, this message translates to:
  /// **'Số câu hỏi'**
  String get questionCount;

  /// No description provided for @threeSeconds.
  ///
  /// In vi, this message translates to:
  /// **'3 giây'**
  String get threeSeconds;

  /// No description provided for @fiveSeconds.
  ///
  /// In vi, this message translates to:
  /// **'5 giây'**
  String get fiveSeconds;

  /// No description provided for @start.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu'**
  String get start;

  /// No description provided for @practiceProgress.
  ///
  /// In vi, this message translates to:
  /// **'Mỗi lượt học là một bước tiến.'**
  String get practiceProgress;

  /// No description provided for @savingResult.
  ///
  /// In vi, this message translates to:
  /// **'Đang lưu kết quả…'**
  String get savingResult;

  /// No description provided for @resultSaved.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu kết quả trên thiết bị.'**
  String get resultSaved;

  /// No description provided for @resultSaveError.
  ///
  /// In vi, this message translates to:
  /// **'Chưa lưu được kết quả. Hãy thử lại.'**
  String get resultSaveError;

  /// No description provided for @backToSet.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại danh mục'**
  String get backToSet;

  /// No description provided for @retrySave.
  ///
  /// In vi, this message translates to:
  /// **'Thử lưu lại'**
  String get retrySave;

  /// No description provided for @skipped.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ qua / hết giờ'**
  String get skipped;

  /// No description provided for @writeMatchingWord.
  ///
  /// In vi, this message translates to:
  /// **'Viết từ tương ứng với nghĩa'**
  String get writeMatchingWord;

  /// No description provided for @chooseMeaning.
  ///
  /// In vi, this message translates to:
  /// **'Chọn nghĩa đúng'**
  String get chooseMeaning;

  /// No description provided for @practicePaused.
  ///
  /// In vi, this message translates to:
  /// **'Bài luyện đã tạm dừng khi rời ứng dụng.'**
  String get practicePaused;

  /// No description provided for @resume.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục'**
  String get resume;

  /// No description provided for @typeWord.
  ///
  /// In vi, this message translates to:
  /// **'Gõ từ…'**
  String get typeWord;

  /// No description provided for @showAnswer.
  ///
  /// In vi, this message translates to:
  /// **'Hiện đáp án'**
  String get showAnswer;

  /// No description provided for @previousQuestion.
  ///
  /// In vi, this message translates to:
  /// **'Câu trước'**
  String get previousQuestion;

  /// No description provided for @nextQuestion.
  ///
  /// In vi, this message translates to:
  /// **'Câu tiếp'**
  String get nextQuestion;

  /// No description provided for @correctAnswer.
  ///
  /// In vi, this message translates to:
  /// **'Chính xác!'**
  String get correctAnswer;

  /// No description provided for @viewResult.
  ///
  /// In vi, this message translates to:
  /// **'Xem kết quả'**
  String get viewResult;

  /// No description provided for @next.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp theo'**
  String get next;

  /// No description provided for @speechError.
  ///
  /// In vi, this message translates to:
  /// **'Không phát được giọng đọc trên thiết bị này.'**
  String get speechError;

  /// No description provided for @defaultVoice.
  ///
  /// In vi, this message translates to:
  /// **'Giọng mặc định'**
  String get defaultVoice;

  /// No description provided for @secondsUnit.
  ///
  /// In vi, this message translates to:
  /// **'giây'**
  String get secondsUnit;

  /// No description provided for @delayHint.
  ///
  /// In vi, this message translates to:
  /// **'0.5 giây = 500 ms · Từ 0.001 đến 60 giây'**
  String get delayHint;

  /// No description provided for @delayValidation.
  ///
  /// In vi, this message translates to:
  /// **'Nhập thời gian từ 0.001 đến 60 giây'**
  String get delayValidation;

  /// No description provided for @cardOptions.
  ///
  /// In vi, this message translates to:
  /// **'Tùy chọn thẻ'**
  String get cardOptions;

  /// No description provided for @starredOnly.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ thẻ cần học lại'**
  String get starredOnly;

  /// No description provided for @trackProgress.
  ///
  /// In vi, this message translates to:
  /// **'Theo dõi tiến độ xem thẻ'**
  String get trackProgress;

  /// No description provided for @reverseCards.
  ///
  /// In vi, this message translates to:
  /// **'Hiển thị nghĩa ở mặt trước'**
  String get reverseCards;

  /// No description provided for @speechEnabled.
  ///
  /// In vi, this message translates to:
  /// **'Bật giọng đọc'**
  String get speechEnabled;

  /// No description provided for @autoSpeak.
  ///
  /// In vi, this message translates to:
  /// **'Tự đọc khi chuyển thẻ'**
  String get autoSpeak;

  /// No description provided for @loopCards.
  ///
  /// In vi, this message translates to:
  /// **'Lặp lại khi hết thẻ'**
  String get loopCards;

  /// No description provided for @speakFront.
  ///
  /// In vi, this message translates to:
  /// **'Đọc mặt trước khi tự phát'**
  String get speakFront;

  /// No description provided for @speakBack.
  ///
  /// In vi, this message translates to:
  /// **'Đọc mặt sau khi tự phát'**
  String get speakBack;

  /// No description provided for @speechRate.
  ///
  /// In vi, this message translates to:
  /// **'Tốc độ đọc'**
  String get speechRate;

  /// No description provided for @flipDelay.
  ///
  /// In vi, this message translates to:
  /// **'Chờ lật thẻ'**
  String get flipDelay;

  /// No description provided for @nextDelay.
  ///
  /// In vi, this message translates to:
  /// **'Chờ chuyển thẻ'**
  String get nextDelay;

  /// No description provided for @frontRepeats.
  ///
  /// In vi, this message translates to:
  /// **'Số lần đọc mặt trước'**
  String get frontRepeats;

  /// No description provided for @backRepeats.
  ///
  /// In vi, this message translates to:
  /// **'Số lần đọc mặt sau'**
  String get backRepeats;

  /// No description provided for @wordVoice.
  ///
  /// In vi, this message translates to:
  /// **'Giọng đọc từ'**
  String get wordVoice;

  /// No description provided for @meaningVoice.
  ///
  /// In vi, this message translates to:
  /// **'Giọng đọc nghĩa'**
  String get meaningVoice;

  /// No description provided for @font.
  ///
  /// In vi, this message translates to:
  /// **'Kiểu chữ'**
  String get font;

  /// No description provided for @defaultFont.
  ///
  /// In vi, this message translates to:
  /// **'Mặc định'**
  String get defaultFont;

  /// No description provided for @saveOptions.
  ///
  /// In vi, this message translates to:
  /// **'Lưu tùy chọn'**
  String get saveOptions;

  /// No description provided for @addDefinitions.
  ///
  /// In vi, this message translates to:
  /// **'Thêm định nghĩa'**
  String get addDefinitions;

  /// No description provided for @importHint.
  ///
  /// In vi, this message translates to:
  /// **'Mỗi dòng: từ + TAB / nhiều dấu cách / dấu phẩy + nghĩa. Từ trùng sẽ được bỏ qua.'**
  String get importHint;

  /// No description provided for @importExample.
  ///
  /// In vi, this message translates to:
  /// **'사랑하다, yêu\n공부하다, học'**
  String get importExample;

  /// No description provided for @importWords.
  ///
  /// In vi, this message translates to:
  /// **'Nhập từ'**
  String get importWords;

  /// No description provided for @savingWords.
  ///
  /// In vi, this message translates to:
  /// **'Đang lưu từ…'**
  String get savingWords;

  /// No description provided for @wordsSavedLookupNotice.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu từ và nghĩa bạn nhập. Đang tải thêm cách dùng, ví dụ và từ đồng nghĩa. Bạn có thể bỏ qua bước này.'**
  String get wordsSavedLookupNotice;

  /// No description provided for @skipLookupOnly.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ qua tra cứu'**
  String get skipLookupOnly;

  /// No description provided for @editWord.
  ///
  /// In vi, this message translates to:
  /// **'Sửa từ vựng'**
  String get editWord;

  /// No description provided for @word.
  ///
  /// In vi, this message translates to:
  /// **'Từ'**
  String get word;

  /// No description provided for @meaning.
  ///
  /// In vi, this message translates to:
  /// **'Nghĩa'**
  String get meaning;

  /// No description provided for @enterWordMeaning.
  ///
  /// In vi, this message translates to:
  /// **'Nhập đầy đủ từ và nghĩa'**
  String get enterWordMeaning;

  /// No description provided for @duplicateWord.
  ///
  /// In vi, this message translates to:
  /// **'Từ này đã có trong danh mục'**
  String get duplicateWord;

  /// No description provided for @deleteSetConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xóa danh mục?'**
  String get deleteSetConfirm;

  /// No description provided for @deleteSet.
  ///
  /// In vi, this message translates to:
  /// **'Xóa danh mục'**
  String get deleteSet;

  /// No description provided for @noCards.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có thẻ phù hợp.'**
  String get noCards;

  /// No description provided for @markUnlearned.
  ///
  /// In vi, this message translates to:
  /// **'Đánh dấu chưa thuộc'**
  String get markUnlearned;

  /// No description provided for @markLearned.
  ///
  /// In vi, this message translates to:
  /// **'Đã thuộc từ này'**
  String get markLearned;

  /// No description provided for @practice.
  ///
  /// In vi, this message translates to:
  /// **'Luyện tập'**
  String get practice;

  /// No description provided for @reading.
  ///
  /// In vi, this message translates to:
  /// **'Luyện đọc'**
  String get reading;

  /// No description provided for @pronunciation.
  ///
  /// In vi, this message translates to:
  /// **'Chấm phát âm'**
  String get pronunciation;

  /// No description provided for @vocabulary.
  ///
  /// In vi, this message translates to:
  /// **'Từ vựng'**
  String get vocabulary;

  /// No description provided for @searchInSet.
  ///
  /// In vi, this message translates to:
  /// **'Tìm trong danh mục'**
  String get searchInSet;

  /// No description provided for @learned.
  ///
  /// In vi, this message translates to:
  /// **'Đã thuộc'**
  String get learned;

  /// No description provided for @needsReview.
  ///
  /// In vi, this message translates to:
  /// **'Cần học lại'**
  String get needsReview;

  /// No description provided for @listenWord.
  ///
  /// In vi, this message translates to:
  /// **'Nghe từ'**
  String get listenWord;

  /// No description provided for @editWordAction.
  ///
  /// In vi, this message translates to:
  /// **'Sửa từ'**
  String get editWordAction;

  /// No description provided for @deleteWord.
  ///
  /// In vi, this message translates to:
  /// **'Xóa từ'**
  String get deleteWord;

  /// No description provided for @deleteWordConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xóa từ?'**
  String get deleteWordConfirm;

  /// No description provided for @recentResults.
  ///
  /// In vi, this message translates to:
  /// **'Kết quả gần đây'**
  String get recentResults;

  /// No description provided for @meaningFace.
  ///
  /// In vi, this message translates to:
  /// **'NGHĨA'**
  String get meaningFace;

  /// No description provided for @wordFace.
  ///
  /// In vi, this message translates to:
  /// **'TỪ'**
  String get wordFace;

  /// No description provided for @listenSample.
  ///
  /// In vi, this message translates to:
  /// **'Nghe mẫu'**
  String get listenSample;

  /// No description provided for @cardGestureHint.
  ///
  /// In vi, this message translates to:
  /// **'Chạm để lật · Vuốt để chuyển'**
  String get cardGestureHint;

  /// No description provided for @recordingsLoadError.
  ///
  /// In vi, this message translates to:
  /// **'Không đọc được bản ghi trên máy. Dữ liệu hiện có được giữ lại.'**
  String get recordingsLoadError;

  /// No description provided for @draftSaveError.
  ///
  /// In vi, this message translates to:
  /// **'Không lưu được bài đọc nháp.'**
  String get draftSaveError;

  /// No description provided for @microphonePermission.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có quyền micro. Bật quyền micro cho Từ Vựng trong cài đặt thiết bị.'**
  String get microphonePermission;

  /// No description provided for @microphoneError.
  ///
  /// In vi, this message translates to:
  /// **'Không khởi động được micro. Hãy kiểm tra quyền và thử lại.'**
  String get microphoneError;

  /// No description provided for @emptyRecording.
  ///
  /// In vi, this message translates to:
  /// **'Bản ghi trống. Hãy thử lại.'**
  String get emptyRecording;

  /// No description provided for @untitledReading.
  ///
  /// In vi, this message translates to:
  /// **'Bài đọc không tên'**
  String get untitledReading;

  /// No description provided for @recordingSaveError.
  ///
  /// In vi, this message translates to:
  /// **'Chưa lưu hoặc chấm được bản ghi. Hãy thử lại.'**
  String get recordingSaveError;

  /// No description provided for @endpointValidation.
  ///
  /// In vi, this message translates to:
  /// **'Nhập URL HTTPS máy chủ dự án, ví dụ https://your-domain/api/pronunciation. Khóa Azure chỉ đặt trên máy chủ.'**
  String get endpointValidation;

  /// No description provided for @koreanAssessmentOnly.
  ///
  /// In vi, this message translates to:
  /// **'Chấm phát âm cần từ tiếng Hàn.'**
  String get koreanAssessmentOnly;

  /// No description provided for @recordOneSecond.
  ///
  /// In vi, this message translates to:
  /// **'Hãy đọc ít nhất một giây.'**
  String get recordOneSecond;

  /// No description provided for @assessmentError.
  ///
  /// In vi, this message translates to:
  /// **'Máy chủ chưa chấm được phát âm.'**
  String get assessmentError;

  /// No description provided for @connectionError.
  ///
  /// In vi, this message translates to:
  /// **'Không kết nối được máy chủ.'**
  String get connectionError;

  /// No description provided for @recordingPlayError.
  ///
  /// In vi, this message translates to:
  /// **'Không phát được bản ghi trên thiết bị.'**
  String get recordingPlayError;

  /// No description provided for @assessmentNotice.
  ///
  /// In vi, this message translates to:
  /// **'Chấm điểm qua Azure như dự án gốc. Âm thanh sẽ gửi đến máy chủ bạn cấu hình; dữ liệu từ vựng vẫn nằm trên thiết bị.'**
  String get assessmentNotice;

  /// No description provided for @recordingNotice.
  ///
  /// In vi, this message translates to:
  /// **'Bài đọc và bản ghi âm lưu trên thiết bị này. Giữ 5 bản ghi gần nhất, mỗi bản ghi tối đa 5 phút.'**
  String get recordingNotice;

  /// No description provided for @assessmentUrl.
  ///
  /// In vi, this message translates to:
  /// **'URL HTTPS chấm phát âm'**
  String get assessmentUrl;

  /// No description provided for @readingTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tên bài đọc'**
  String get readingTitle;

  /// No description provided for @readingText.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung bài đọc'**
  String get readingText;

  /// No description provided for @processing.
  ///
  /// In vi, this message translates to:
  /// **'Đang xử lý…'**
  String get processing;

  /// No description provided for @stopAssess.
  ///
  /// In vi, this message translates to:
  /// **'Dừng và chấm'**
  String get stopAssess;

  /// No description provided for @stopSave.
  ///
  /// In vi, this message translates to:
  /// **'Dừng và lưu'**
  String get stopSave;

  /// No description provided for @startRecording.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu ghi âm'**
  String get startRecording;

  /// No description provided for @replayRecording.
  ///
  /// In vi, this message translates to:
  /// **'Nghe lại bản ghi'**
  String get replayRecording;

  /// No description provided for @reassessRecording.
  ///
  /// In vi, this message translates to:
  /// **'Chấm lại bản ghi'**
  String get reassessRecording;

  /// No description provided for @yourRecordings.
  ///
  /// In vi, this message translates to:
  /// **'Bản ghi của bạn'**
  String get yourRecordings;

  /// No description provided for @noRecordings.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có bản ghi. Thử đọc đoạn đầu tiên nhé.'**
  String get noRecordings;

  /// No description provided for @listenRecording.
  ///
  /// In vi, this message translates to:
  /// **'Nghe bản ghi'**
  String get listenRecording;

  /// No description provided for @deleteRecordingConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xóa bản ghi?'**
  String get deleteRecordingConfirm;

  /// No description provided for @recordingDeleteError.
  ///
  /// In vi, this message translates to:
  /// **'Không xóa được bản ghi.'**
  String get recordingDeleteError;

  /// No description provided for @deleteRecording.
  ///
  /// In vi, this message translates to:
  /// **'Xóa bản ghi'**
  String get deleteRecording;

  /// No description provided for @interfaceLanguage.
  ///
  /// In vi, this message translates to:
  /// **'Ngôn ngữ giao diện'**
  String get interfaceLanguage;

  /// No description provided for @systemLanguage.
  ///
  /// In vi, this message translates to:
  /// **'Theo thiết bị'**
  String get systemLanguage;

  /// No description provided for @wordLanguage.
  ///
  /// In vi, this message translates to:
  /// **'Ngôn ngữ của từ'**
  String get wordLanguage;

  /// No description provided for @meaningLanguage.
  ///
  /// In vi, this message translates to:
  /// **'Ngôn ngữ của nghĩa'**
  String get meaningLanguage;

  /// No description provided for @languageHint.
  ///
  /// In vi, this message translates to:
  /// **'Giọng đọc tùy thuộc các ngôn ngữ đã cài trên thiết bị.'**
  String get languageHint;

  /// No description provided for @options.
  ///
  /// In vi, this message translates to:
  /// **'Tùy chọn'**
  String get options;

  /// No description provided for @noReviewCards.
  ///
  /// In vi, this message translates to:
  /// **'Không có thẻ cần học lại. Tắt bộ lọc để xem tất cả.'**
  String get noReviewCards;

  /// No description provided for @emptySet.
  ///
  /// In vi, this message translates to:
  /// **'Danh mục chưa có từ. Nhập từ để bắt đầu.'**
  String get emptySet;

  /// No description provided for @previousCard.
  ///
  /// In vi, this message translates to:
  /// **'Thẻ trước'**
  String get previousCard;

  /// No description provided for @stopAutoplay.
  ///
  /// In vi, this message translates to:
  /// **'Dừng tự phát'**
  String get stopAutoplay;

  /// No description provided for @autoplay.
  ///
  /// In vi, this message translates to:
  /// **'Tự động phát'**
  String get autoplay;

  /// No description provided for @shuffleCards.
  ///
  /// In vi, this message translates to:
  /// **'Trộn thẻ'**
  String get shuffleCards;

  /// No description provided for @nextCard.
  ///
  /// In vi, this message translates to:
  /// **'Thẻ tiếp'**
  String get nextCard;

  /// No description provided for @listenYourself.
  ///
  /// In vi, this message translates to:
  /// **'Đọc và nghe chính mình.'**
  String get listenYourself;

  /// No description provided for @dailyReading.
  ///
  /// In vi, this message translates to:
  /// **'Luyện đọc mỗi ngày.'**
  String get dailyReading;

  /// No description provided for @wordProgress.
  ///
  /// In vi, this message translates to:
  /// **'{count} từ · {learned} đã thuộc'**
  String wordProgress(int count, int learned);

  /// No description provided for @vietnamese.
  ///
  /// In vi, this message translates to:
  /// **'Tiếng Việt'**
  String get vietnamese;

  /// No description provided for @english.
  ///
  /// In vi, this message translates to:
  /// **'Tiếng Anh'**
  String get english;

  /// No description provided for @korean.
  ///
  /// In vi, this message translates to:
  /// **'Tiếng Hàn'**
  String get korean;

  /// No description provided for @japanese.
  ///
  /// In vi, this message translates to:
  /// **'Tiếng Nhật'**
  String get japanese;

  /// No description provided for @chinese.
  ///
  /// In vi, this message translates to:
  /// **'Tiếng Trung'**
  String get chinese;

  /// No description provided for @french.
  ///
  /// In vi, this message translates to:
  /// **'Tiếng Pháp'**
  String get french;

  /// No description provided for @german.
  ///
  /// In vi, this message translates to:
  /// **'Tiếng Đức'**
  String get german;

  /// No description provided for @spanish.
  ///
  /// In vi, this message translates to:
  /// **'Tiếng Tây Ban Nha'**
  String get spanish;

  /// No description provided for @learnedCards.
  ///
  /// In vi, this message translates to:
  /// **'{count} thẻ đã thuộc'**
  String learnedCards(int count);

  /// No description provided for @sessionSets.
  ///
  /// In vi, this message translates to:
  /// **'{sessions} lượt học · {sets} danh mục'**
  String sessionSets(int sessions, int sets);

  /// No description provided for @setProgress.
  ///
  /// In vi, this message translates to:
  /// **'{cards} thẻ · {learned} đã thuộc'**
  String setProgress(int cards, int learned);

  /// No description provided for @completedSessions.
  ///
  /// In vi, this message translates to:
  /// **'{count} lượt học hoàn thành'**
  String completedSessions(int count);

  /// No description provided for @accuracyPercent.
  ///
  /// In vi, this message translates to:
  /// **'Độ chính xác: {percent}%'**
  String accuracyPercent(int percent);

  /// No description provided for @backupReplaceNotice.
  ///
  /// In vi, this message translates to:
  /// **'Bản sao lưu có {count} danh mục. Toàn bộ từ vựng và tiến độ hiện tại sẽ được thay thế.'**
  String backupReplaceNotice(int count);

  /// No description provided for @importLineError.
  ///
  /// In vi, this message translates to:
  /// **'Dòng {line}: dùng TAB, nhiều dấu cách hoặc dấu phẩy để ngăn từ và nghĩa.'**
  String importLineError(int line);

  /// No description provided for @maxQuestions.
  ///
  /// In vi, this message translates to:
  /// **'Tối đa {count} câu; nhập nhiều hơn sẽ dùng tất cả.'**
  String maxQuestions(int count);

  /// No description provided for @answerReview.
  ///
  /// In vi, this message translates to:
  /// **'{meaning}\nBạn trả lời: {answer}'**
  String answerReview(String meaning, String answer);

  /// No description provided for @questionPosition.
  ///
  /// In vi, this message translates to:
  /// **'CÂU {current} / {total}'**
  String questionPosition(int current, int total);

  /// No description provided for @secondsRemaining.
  ///
  /// In vi, this message translates to:
  /// **'{count} giây'**
  String secondsRemaining(int count);

  /// No description provided for @wrongAnswer.
  ///
  /// In vi, this message translates to:
  /// **'Chưa đúng. Đáp án: {answer}'**
  String wrongAnswer(String answer);

  /// No description provided for @voiceUnavailable.
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị chưa có giọng {language}. Hãy tải giọng trong cài đặt hệ thống.'**
  String voiceUnavailable(String language);

  /// No description provided for @importSummary.
  ///
  /// In vi, this message translates to:
  /// **'Đã thêm {added} từ · bỏ qua {duplicates} từ trùng.'**
  String importSummary(int added, int duplicates);

  /// No description provided for @deleteSetNotice.
  ///
  /// In vi, this message translates to:
  /// **'Xóa {title} và toàn bộ thẻ trong danh mục này?'**
  String deleteSetNotice(String title);

  /// No description provided for @deleteWordNotice.
  ///
  /// In vi, this message translates to:
  /// **'Xóa “{word}” khỏi danh mục?'**
  String deleteWordNotice(String word);

  /// No description provided for @cardPosition.
  ///
  /// In vi, this message translates to:
  /// **'THẺ {current} / {total}'**
  String cardPosition(int current, int total);

  /// No description provided for @recordingElapsed.
  ///
  /// In vi, this message translates to:
  /// **'● Đang ghi âm · {seconds} giây'**
  String recordingElapsed(int seconds);

  /// No description provided for @assessmentMetrics.
  ///
  /// In vi, this message translates to:
  /// **'Chính xác: {accuracy} · Trôi chảy: {fluency}'**
  String assessmentMetrics(String accuracy, String fluency);

  /// No description provided for @assessmentCompleteness.
  ///
  /// In vi, this message translates to:
  /// **'Đầy đủ: {value}'**
  String assessmentCompleteness(String value);

  /// No description provided for @recognizedText.
  ///
  /// In vi, this message translates to:
  /// **'Nhận diện: {text}'**
  String recognizedText(String text);

  /// No description provided for @recordingDetails.
  ///
  /// In vi, this message translates to:
  /// **'{seconds} giây · {date}'**
  String recordingDetails(String seconds, String date);

  /// No description provided for @deleteRecordingNotice.
  ///
  /// In vi, this message translates to:
  /// **'Xóa bản ghi “{title}” trên thiết bị này?'**
  String deleteRecordingNotice(String title);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
