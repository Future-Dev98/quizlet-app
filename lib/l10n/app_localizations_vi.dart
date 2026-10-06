// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get addWord => 'Thêm từ';

  @override
  String get saveWord => 'Lưu từ';

  @override
  String get autoDetailsHint =>
      'Cách dùng, ví dụ và từ đồng nghĩa sẽ được tra tự động khi lưu.';

  @override
  String get wordActions => 'Thao tác với từ';

  @override
  String get wordListHint =>
      'Chạm vào từ để xem chi tiết · Kéo biểu tượng bên trái để sắp xếp';

  @override
  String get reorderWord => 'Kéo để sắp xếp từ';

  @override
  String get clearSearch => 'Xóa tìm kiếm';

  @override
  String get cardDetails => 'Chi tiết thẻ';

  @override
  String get wordUsage => 'Cách sử dụng';

  @override
  String get usageExamples => 'Ví dụ sử dụng';

  @override
  String get wordSynonyms => 'Từ đồng nghĩa';

  @override
  String get dictionaryMeanings => 'Nghĩa và từ loại từ từ điển';

  @override
  String get noDictionaryMeanings => 'Từ điển chưa có thông tin nghĩa.';

  @override
  String get noUsageNotes =>
      'Từ điển chưa có ghi chú cách dùng. Tham khảo nghĩa, từ loại và ví dụ bên dưới.';

  @override
  String get noUsageExamples => 'Từ điển chưa có ví dụ cho từ này.';

  @override
  String get noSynonyms => 'Từ điển chưa liệt kê từ đồng nghĩa cho từ này.';

  @override
  String get noSavedDetails =>
      'Thẻ này chưa có dữ liệu chi tiết. Chọn Tra chi tiết để tìm và lưu.';

  @override
  String get lookupDetails => 'Tra chi tiết';

  @override
  String get refreshDetails => 'Tra lại và lưu';

  @override
  String get closeDetails => 'Đóng';

  @override
  String get noDictionaryEntry =>
      'Chưa tìm thấy mục từ cho ngôn ngữ đã chọn. Kiểm tra chính tả và Ngôn ngữ của từ trong Tùy chọn thẻ.';

  @override
  String get dictionaryLookupError =>
      'Chưa tra được từ điển. Kiểm tra kết nối mạng rồi thử lại. Dữ liệu đã lưu được giữ nguyên.';

  @override
  String get dictionarySourceNotice =>
      'Nguồn: Wiktionary · CC BY-SA. Giữ nguyên ngôn ngữ nguồn; một từ có thể có nhiều nghĩa và cách dùng.';

  @override
  String get copySource => 'Sao chép nguồn';

  @override
  String get sourceCopied => 'Đã sao chép liên kết nguồn.';

  @override
  String get wordSuggestions => 'Gợi ý từ · Chạm để xem chi tiết';

  @override
  String get lookingUpWords => 'Đang tra cách dùng và từ đồng nghĩa';

  @override
  String get dictionaryNetworkNotice =>
      'Tra từ trên Wiktionary theo Ngôn ngữ của từ. Chỉ gửi từ cần tra; kết quả được lưu cùng thẻ để xem offline.';

  @override
  String get skipLookup => 'Bỏ qua tra cứu và lưu từ';

  @override
  String detailsMissing(int count) {
    return 'Đã lưu từ. $count thẻ chưa có chi tiết từ điển; có thể tra lại từ popup.';
  }

  @override
  String get appTitle => 'Từ Vựng';

  @override
  String get brand => 'từ vựng';

  @override
  String get saveError =>
      'Chưa lưu được dữ liệu. Kiểm tra dung lượng máy và thử lại.';

  @override
  String get loadError =>
      'Không đọc được dữ liệu. Dữ liệu hiện có được giữ lại.';

  @override
  String get retry => 'Thử lại';

  @override
  String get home => 'Trang chủ';

  @override
  String get library => 'Thư viện';

  @override
  String get profile => 'Cá nhân';

  @override
  String get createSet => 'Tạo danh mục';

  @override
  String get homeHeading => 'Mỗi từ mới là một\nbước tiến nhỏ.';

  @override
  String get yourLibrary => 'Thư viện của bạn';

  @override
  String get tagline => 'Học theo nhịp của bạn. Ghi nhớ mỗi ngày.';

  @override
  String get journey => 'HÀNH TRÌNH CỦA BẠN';

  @override
  String get continueLearning => 'Tiếp tục học   →';

  @override
  String get searchSets => 'Tìm danh mục, từ vựng…';

  @override
  String get parentFolder => 'Thư mục cha';

  @override
  String get createFolder => 'Tạo thư mục';

  @override
  String get openFolder => 'Mở thư mục';

  @override
  String get editFolder => 'Sửa thư mục';

  @override
  String get emptyLibrary =>
      'Chưa có danh mục phù hợp. Tạo danh mục để bắt đầu.';

  @override
  String get folderName => 'Tên thư mục';

  @override
  String get rootLibrary => 'Thư viện gốc';

  @override
  String get deleteEmptyFolder => 'Xóa thư mục trống';

  @override
  String get cancel => 'Hủy';

  @override
  String get save => 'Lưu';

  @override
  String get folderNotEmpty =>
      'Chỉ xóa được thư mục trống. Hãy chuyển nội dung ra trước.';

  @override
  String get studyCorner => 'Góc học tập';

  @override
  String get yourJourney => 'Kiến thức của bạn, hành trình của bạn.';

  @override
  String get themeSettings => 'Cài đặt · Giao diện';

  @override
  String get themeHint => 'Chọn màu nền và chữ cho ứng dụng.';

  @override
  String get lightTheme => 'Sáng';

  @override
  String get darkTheme => 'Tối';

  @override
  String get smallStep => 'Mỗi từ mới là một bước tiến nhỏ.';

  @override
  String get darkPreview => 'Nền tối · Chữ sáng';

  @override
  String get lightPreview => 'Nền sáng · Chữ tối';

  @override
  String get copyBackup => 'Sao chép bản sao lưu';

  @override
  String get backupHint => 'Bộ từ, thư mục, cài đặt và tiến độ (JSON)';

  @override
  String get backupCopied =>
      'Đã sao chép bản sao lưu. Bản ghi âm được lưu riêng trên máy.';

  @override
  String get restoreJson => 'Khôi phục từ JSON';

  @override
  String get privacyNotice =>
      'Dữ liệu lưu riêng trên thiết bị, không cần tài khoản. Gỡ app có thể xóa dữ liệu; hãy sao lưu trước khi đổi máy. Chấm phát âm cần máy chủ Azure và kết nối mạng.';

  @override
  String get restoreData => 'Khôi phục dữ liệu';

  @override
  String get pasteBackup => 'Dán JSON đã sao lưu…';

  @override
  String get check => 'Kiểm tra';

  @override
  String get replaceData => 'Thay thế dữ liệu hiện tại?';

  @override
  String get invalidJson =>
      'JSON không hợp lệ. Dữ liệu hiện tại được giữ nguyên.';

  @override
  String get agree => 'Đồng ý';

  @override
  String get editSet => 'Sửa danh mục';

  @override
  String get setName => 'Tên danh mục';

  @override
  String get enterSetName => 'Nhập tên danh mục';

  @override
  String get description => 'Mô tả';

  @override
  String get folder => 'Thư mục';

  @override
  String get displayOrder => 'Thứ tự hiển thị';

  @override
  String get orderValidation => 'Nhập số từ 0 đến 1000000';

  @override
  String get saveSet => 'Lưu danh mục';

  @override
  String get noImportWords => 'Chưa có từ để nhập.';

  @override
  String get quiz => 'Kiểm tra';

  @override
  String get reflex => 'Phản xạ';

  @override
  String get writing => 'Luyện viết';

  @override
  String get positiveCount => 'Nhập số câu lớn hơn 0.';

  @override
  String get addBeforePractice => 'Thêm từ vựng trước khi luyện tập.';

  @override
  String get distinctMeanings => 'Cần ít nhất 2 nghĩa khác nhau để tạo đáp án.';

  @override
  String get writingHeading => 'Nhìn nghĩa, viết lại từ.';

  @override
  String get reflexHeading => 'Nhanh tay chọn đáp án.';

  @override
  String get quizHeading => 'Sẵn sàng thử sức?';

  @override
  String get writingHint =>
      'Viết từ tương ứng. Bạn có thể hiện đáp án để tự ôn tập.';

  @override
  String get quizHint =>
      'Câu hỏi được trộn ngẫu nhiên. Đáp án sai lấy từ các từ trong danh mục.';

  @override
  String get questionCount => 'Số câu hỏi';

  @override
  String get threeSeconds => '3 giây';

  @override
  String get fiveSeconds => '5 giây';

  @override
  String get start => 'Bắt đầu';

  @override
  String get practiceProgress => 'Mỗi lượt học là một bước tiến.';

  @override
  String get savingResult => 'Đang lưu kết quả…';

  @override
  String get resultSaved => 'Đã lưu kết quả trên thiết bị.';

  @override
  String get resultSaveError => 'Chưa lưu được kết quả. Hãy thử lại.';

  @override
  String get backToSet => 'Quay lại danh mục';

  @override
  String get retrySave => 'Thử lưu lại';

  @override
  String get skipped => 'Bỏ qua / hết giờ';

  @override
  String get writeMatchingWord => 'Viết từ tương ứng với nghĩa';

  @override
  String get chooseMeaning => 'Chọn nghĩa đúng';

  @override
  String get practicePaused => 'Bài luyện đã tạm dừng khi rời ứng dụng.';

  @override
  String get resume => 'Tiếp tục';

  @override
  String get typeWord => 'Gõ từ…';

  @override
  String get showAnswer => 'Hiện đáp án';

  @override
  String get previousQuestion => 'Câu trước';

  @override
  String get nextQuestion => 'Câu tiếp';

  @override
  String get correctAnswer => 'Chính xác!';

  @override
  String get viewResult => 'Xem kết quả';

  @override
  String get next => 'Tiếp theo';

  @override
  String get speechError => 'Không phát được giọng đọc trên thiết bị này.';

  @override
  String get defaultVoice => 'Giọng mặc định';

  @override
  String get secondsUnit => 'giây';

  @override
  String get delayHint => '0.5 giây = 500 ms · Từ 0.001 đến 60 giây';

  @override
  String get delayValidation => 'Nhập thời gian từ 0.001 đến 60 giây';

  @override
  String get cardOptions => 'Tùy chọn thẻ';

  @override
  String get starredOnly => 'Chỉ thẻ cần học lại';

  @override
  String get trackProgress => 'Theo dõi tiến độ xem thẻ';

  @override
  String get reverseCards => 'Hiển thị nghĩa ở mặt trước';

  @override
  String get speechEnabled => 'Bật giọng đọc';

  @override
  String get autoSpeak => 'Tự đọc khi chuyển thẻ';

  @override
  String get loopCards => 'Lặp lại khi hết thẻ';

  @override
  String get speakFront => 'Đọc mặt trước khi tự phát';

  @override
  String get speakBack => 'Đọc mặt sau khi tự phát';

  @override
  String get speechRate => 'Tốc độ đọc';

  @override
  String get flipDelay => 'Chờ lật thẻ';

  @override
  String get nextDelay => 'Chờ chuyển thẻ';

  @override
  String get frontRepeats => 'Số lần đọc mặt trước';

  @override
  String get backRepeats => 'Số lần đọc mặt sau';

  @override
  String get wordVoice => 'Giọng đọc từ';

  @override
  String get meaningVoice => 'Giọng đọc nghĩa';

  @override
  String get font => 'Kiểu chữ';

  @override
  String get defaultFont => 'Mặc định';

  @override
  String get saveOptions => 'Lưu tùy chọn';

  @override
  String get addDefinitions => 'Thêm định nghĩa';

  @override
  String get importHint =>
      'Mỗi dòng: từ + TAB / nhiều dấu cách / dấu phẩy + nghĩa. Từ trùng sẽ được bỏ qua.';

  @override
  String get importExample => '사랑하다, yêu\n공부하다, học';

  @override
  String get importWords => 'Nhập từ';

  @override
  String get savingWords => 'Đang lưu từ…';

  @override
  String get editWord => 'Sửa từ vựng';

  @override
  String get word => 'Từ';

  @override
  String get meaning => 'Nghĩa';

  @override
  String get enterWordMeaning => 'Nhập đầy đủ từ và nghĩa';

  @override
  String get duplicateWord => 'Từ này đã có trong danh mục';

  @override
  String get deleteSetConfirm => 'Xóa danh mục?';

  @override
  String get deleteSet => 'Xóa danh mục';

  @override
  String get noCards => 'Chưa có thẻ phù hợp.';

  @override
  String get markUnlearned => 'Đánh dấu chưa thuộc';

  @override
  String get markLearned => 'Đã thuộc từ này';

  @override
  String get practice => 'Luyện tập';

  @override
  String get reading => 'Luyện đọc';

  @override
  String get pronunciation => 'Chấm phát âm';

  @override
  String get vocabulary => 'Từ vựng';

  @override
  String get searchInSet => 'Tìm trong danh mục';

  @override
  String get learned => 'Đã thuộc';

  @override
  String get needsReview => 'Cần học lại';

  @override
  String get listenWord => 'Nghe từ';

  @override
  String get editWordAction => 'Sửa từ';

  @override
  String get deleteWord => 'Xóa từ';

  @override
  String get deleteWordConfirm => 'Xóa từ?';

  @override
  String get recentResults => 'Kết quả gần đây';

  @override
  String get meaningFace => 'NGHĨA';

  @override
  String get wordFace => 'TỪ';

  @override
  String get listenSample => 'Nghe mẫu';

  @override
  String get cardGestureHint => 'Chạm để lật · Vuốt để chuyển';

  @override
  String get recordingsLoadError =>
      'Không đọc được bản ghi trên máy. Dữ liệu hiện có được giữ lại.';

  @override
  String get draftSaveError => 'Không lưu được bài đọc nháp.';

  @override
  String get microphonePermission =>
      'Chưa có quyền micro. Bật quyền micro cho Từ Vựng trong cài đặt thiết bị.';

  @override
  String get microphoneError =>
      'Không khởi động được micro. Hãy kiểm tra quyền và thử lại.';

  @override
  String get emptyRecording => 'Bản ghi trống. Hãy thử lại.';

  @override
  String get untitledReading => 'Bài đọc không tên';

  @override
  String get recordingSaveError =>
      'Chưa lưu hoặc chấm được bản ghi. Hãy thử lại.';

  @override
  String get endpointValidation =>
      'Nhập URL HTTPS máy chủ dự án, ví dụ https://your-domain/api/pronunciation. Khóa Azure chỉ đặt trên máy chủ.';

  @override
  String get koreanAssessmentOnly => 'Chấm phát âm cần từ tiếng Hàn.';

  @override
  String get recordOneSecond => 'Hãy đọc ít nhất một giây.';

  @override
  String get assessmentError => 'Máy chủ chưa chấm được phát âm.';

  @override
  String get connectionError => 'Không kết nối được máy chủ.';

  @override
  String get recordingPlayError => 'Không phát được bản ghi trên thiết bị.';

  @override
  String get assessmentNotice =>
      'Chấm điểm qua Azure như dự án gốc. Âm thanh sẽ gửi đến máy chủ bạn cấu hình; dữ liệu từ vựng vẫn nằm trên thiết bị.';

  @override
  String get recordingNotice =>
      'Bài đọc và bản ghi âm lưu trên thiết bị này. Giữ 5 bản ghi gần nhất, mỗi bản ghi tối đa 5 phút.';

  @override
  String get assessmentUrl => 'URL HTTPS chấm phát âm';

  @override
  String get readingTitle => 'Tên bài đọc';

  @override
  String get readingText => 'Nội dung bài đọc';

  @override
  String get processing => 'Đang xử lý…';

  @override
  String get stopAssess => 'Dừng và chấm';

  @override
  String get stopSave => 'Dừng và lưu';

  @override
  String get startRecording => 'Bắt đầu ghi âm';

  @override
  String get replayRecording => 'Nghe lại bản ghi';

  @override
  String get reassessRecording => 'Chấm lại bản ghi';

  @override
  String get yourRecordings => 'Bản ghi của bạn';

  @override
  String get noRecordings => 'Chưa có bản ghi. Thử đọc đoạn đầu tiên nhé.';

  @override
  String get listenRecording => 'Nghe bản ghi';

  @override
  String get deleteRecordingConfirm => 'Xóa bản ghi?';

  @override
  String get recordingDeleteError => 'Không xóa được bản ghi.';

  @override
  String get deleteRecording => 'Xóa bản ghi';

  @override
  String get interfaceLanguage => 'Ngôn ngữ giao diện';

  @override
  String get systemLanguage => 'Theo thiết bị';

  @override
  String get wordLanguage => 'Ngôn ngữ của từ';

  @override
  String get meaningLanguage => 'Ngôn ngữ của nghĩa';

  @override
  String get languageHint =>
      'Giọng đọc tùy thuộc các ngôn ngữ đã cài trên thiết bị.';

  @override
  String get options => 'Tùy chọn';

  @override
  String get noReviewCards =>
      'Không có thẻ cần học lại. Tắt bộ lọc để xem tất cả.';

  @override
  String get emptySet => 'Danh mục chưa có từ. Nhập từ để bắt đầu.';

  @override
  String get previousCard => 'Thẻ trước';

  @override
  String get stopAutoplay => 'Dừng tự phát';

  @override
  String get autoplay => 'Tự động phát';

  @override
  String get shuffleCards => 'Trộn thẻ';

  @override
  String get nextCard => 'Thẻ tiếp';

  @override
  String get listenYourself => 'Đọc và nghe chính mình.';

  @override
  String get dailyReading => 'Luyện đọc mỗi ngày.';

  @override
  String wordProgress(int count, int learned) {
    return '$count từ · $learned đã thuộc';
  }

  @override
  String get vietnamese => 'Tiếng Việt';

  @override
  String get english => 'Tiếng Anh';

  @override
  String get korean => 'Tiếng Hàn';

  @override
  String get japanese => 'Tiếng Nhật';

  @override
  String get chinese => 'Tiếng Trung';

  @override
  String get french => 'Tiếng Pháp';

  @override
  String get german => 'Tiếng Đức';

  @override
  String get spanish => 'Tiếng Tây Ban Nha';

  @override
  String learnedCards(int count) {
    return '$count thẻ đã thuộc';
  }

  @override
  String sessionSets(int sessions, int sets) {
    return '$sessions lượt học · $sets danh mục';
  }

  @override
  String setProgress(int cards, int learned) {
    return '$cards thẻ · $learned đã thuộc';
  }

  @override
  String completedSessions(int count) {
    return '$count lượt học hoàn thành';
  }

  @override
  String accuracyPercent(int percent) {
    return 'Độ chính xác: $percent%';
  }

  @override
  String backupReplaceNotice(int count) {
    return 'Bản sao lưu có $count danh mục. Toàn bộ từ vựng và tiến độ hiện tại sẽ được thay thế.';
  }

  @override
  String importLineError(int line) {
    return 'Dòng $line: dùng TAB, nhiều dấu cách hoặc dấu phẩy để ngăn từ và nghĩa.';
  }

  @override
  String maxQuestions(int count) {
    return 'Tối đa $count câu; nhập nhiều hơn sẽ dùng tất cả.';
  }

  @override
  String answerReview(String meaning, String answer) {
    return '$meaning\nBạn trả lời: $answer';
  }

  @override
  String questionPosition(int current, int total) {
    return 'CÂU $current / $total';
  }

  @override
  String secondsRemaining(int count) {
    return '$count giây';
  }

  @override
  String wrongAnswer(String answer) {
    return 'Chưa đúng. Đáp án: $answer';
  }

  @override
  String voiceUnavailable(String language) {
    return 'Thiết bị chưa có giọng $language. Hãy tải giọng trong cài đặt hệ thống.';
  }

  @override
  String importSummary(int added, int duplicates) {
    return 'Đã thêm $added từ · bỏ qua $duplicates từ trùng.';
  }

  @override
  String deleteSetNotice(String title) {
    return 'Xóa $title và toàn bộ thẻ trong danh mục này?';
  }

  @override
  String deleteWordNotice(String word) {
    return 'Xóa “$word” khỏi danh mục?';
  }

  @override
  String cardPosition(int current, int total) {
    return 'THẺ $current / $total';
  }

  @override
  String recordingElapsed(int seconds) {
    return '● Đang ghi âm · $seconds giây';
  }

  @override
  String assessmentMetrics(String accuracy, String fluency) {
    return 'Chính xác: $accuracy · Trôi chảy: $fluency';
  }

  @override
  String assessmentCompleteness(String value) {
    return 'Đầy đủ: $value';
  }

  @override
  String recognizedText(String text) {
    return 'Nhận diện: $text';
  }

  @override
  String recordingDetails(String seconds, String date) {
    return '$seconds giây · $date';
  }

  @override
  String deleteRecordingNotice(String title) {
    return 'Xóa bản ghi “$title” trên thiết bị này?';
  }
}
