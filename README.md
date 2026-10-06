# Từ Vựng — Flutter cho Android / iOS

Bản mobile chuyển từ dự án `C:\Users\HYV\Desktop\quizlet`. Mã nguồn web được giữ nguyên. Dữ liệu app nằm riêng trên mỗi thiết bị, không gọi API thư viện web và không đồng bộ giữa người dùng.

## Chức năng

- Thư mục lồng nhau: tạo, đổi tên/chuyển cha; ngăn vòng lặp, chỉ xóa thư mục trống.
- Danh mục: tạo/sửa/xóa, mô tả, thư mục, thứ tự; tìm theo tên, từ và nghĩa.
- Nhập nhiều từ bằng TAB, từ hai dấu cách hoặc dấu phẩy. Giữ dấu phẩy trong nghĩa; bỏ qua từ trùng theo Unicode NFC và chữ thường, giữ nghĩa cũ.
- Nút **Thêm từ / Add word** ngay đầu mỗi danh mục mở form từ/nghĩa riêng, kiểm tra nội dung trống và từ trùng; lưu đúng danh mục đang mở và tự tra chi tiết từ điển. Nút **Nhập từ / Import words** bên cạnh dành cho nhập nhiều dòng. Phần danh sách có nút **+** để thêm từ ngay tại chỗ.
- Danh sách từ dùng hàng bo góc, từ và nghĩa phân cấp rõ, nút nghe riêng, chip **Đã thuộc / Cần học lại** để đổi trạng thái nhanh. Chạm hàng mở chi tiết; menu **⋯** chứa xem chi tiết, sửa và xóa. Tay kéo bên trái đổi thứ tự; tìm kiếm có nút xóa nhanh và hiển thị số từ phù hợp.
- Khi nhập từ, tự tra Wiktionary theo **Ngôn ngữ của từ**, lưu nghĩa/từ loại, ghi chú cách dùng, ví dụ và từ đồng nghĩa có sẵn cùng thẻ. Có tiến độ và nút bỏ qua; mất mạng hoặc không có mục từ vẫn lưu từ vựng. Chỉ các từ mới được tra, từ trùng không gọi lại từ điển.
- Mỗi thẻ có nút **ⓘ Chi tiết thẻ** trên thẻ học và dòng từ vựng. Popup xem dữ liệu đã lưu khi offline, có **Tra chi tiết / Tra lại và lưu** cho thẻ cũ hoặc để cập nhật. Đổi từ sẽ bỏ chi tiết cũ và tra lại; đổi nghĩa giữ chi tiết. Tìm từ gợi ý theo từ, nghĩa và các từ đồng nghĩa đã lưu; chạm gợi ý để mở popup.
- Từ vựng: sửa/xóa, kéo đổi thứ tự, đánh dấu đã thuộc/cần học lại, nghe phát âm.
- Thẻ: chạm lật, vuốt/nút chuyển, trộn, bỏ qua thẻ đã thuộc khi chuyển, nhớ vị trí học, lọc thẻ cần học lại, đảo mặt trước, theo dõi tiến độ.
- Giọng đọc hệ thống: chọn ngôn ngữ riêng cho từ và nghĩa (Hàn, Việt, Anh, Nhật, Trung, Pháp, Đức, Tây Ban Nha), chọn giọng/tốc độ, tự đọc khi chuyển; tự phát với thời gian lật/chuyển chính xác đến mili giây (nhập giây thập phân, ví dụ `0.5` = `500 ms`), số lần đọc từng mặt, lặp danh sách. Dừng khi ra nền. Cài đặt cũ giữ mặc định Hàn–Việt và tự chuyển giây sang mili giây.
- Kiểm tra: số câu tùy chọn, trộn câu/đáp án, quay lại sửa đáp án, chấm và lưu lịch sử.
- Phản xạ: 3 hoặc 5 giây/câu, hiện đáp án rồi tự chuyển; tạm dừng khi ra nền.
- Luyện viết: nhìn nghĩa viết từ, chuẩn hóa đáp án, hiện đáp án, tổng kết.
- Luyện đọc: lưu nháp, ghi âm/nghe lại/xóa; giữ 5 bản ghi gần nhất trên toàn app, tối đa 5 phút/bản.
- Chấm phát âm: WAV mono PCM 16 kHz, tối đa 29 giây; gửi endpoint dự án web, hiện điểm tổng, chính xác, trôi chảy, đầy đủ và từng từ; nghe/chấm lại trong phiên.
- Cá nhân → Ngôn ngữ giao diện: **Theo thiết bị**, **Tiếng Việt**, **English**; áp dụng ngay và lưu trên thiết bị. Thiết bị dùng ngôn ngữ chưa hỗ trợ sẽ dùng tiếng Việt. Từ vựng, tên danh mục và nội dung do người dùng nhập được giữ nguyên khi đổi giao diện.
- Cá nhân → Cài đặt · Giao diện: **Sáng** / **Tối**, áp dụng cho toàn app và lưu lựa chọn trên thiết bị; sao chép/khôi phục JSON cho từ vựng, thư mục, tiến độ, lịch sử và cài đặt.

## Bản dịch và biểu tượng

Chuỗi giao diện nằm trong `lib/l10n/app_vi.arb` và `app_en.arb`, với các tham số cho số lượng, tiến độ và thông báo. Để thêm ngôn ngữ, tạo `app_<mã>.arb` với cùng khóa, chạy `flutter gen-l10n`, rồi bổ sung lựa chọn ngôn ngữ giao diện trong `lib/main.dart` và danh sách hợp lệ trong `lib/models.dart`. `MaterialApp` dùng các delegate của Flutter cho nút hệ thống và định dạng theo locale. Không chỉnh trực tiếp các file Dart được sinh trong `lib/l10n`.

Trong màn hình bộ thẻ, mở **Tùy chọn → Ngôn ngữ của từ / Ngôn ngữ của nghĩa** để đổi cặp giọng đọc. Giọng đọc phụ thuộc gói ngôn ngữ đã cài trên thiết bị. Chấm phát âm qua endpoint hiện vẫn hỗ trợ tiếng Hàn theo hợp đồng máy chủ gốc.

Ảnh gốc được lưu ở `assets/app_icon.jpg`, dùng để tạo icon Android, iOS, macOS, Windows và favicon/icon web. Có thể tái tạo bằng `python tool/generate_icons.py` (cần Pillow); script chỉ thay đổi kích thước ảnh, giữ nguyên nội dung. Tên launcher Android được dịch theo ngôn ngữ thiết bị.

## Dữ liệu

`assets/seed.json` chứa 405 từ trong 8 danh mục từ database gốc. Chỉ nạp lần đầu; cập nhật app không ghi đè dữ liệu người dùng. Tiến độ mỗi máy bắt đầu từ 0.

App lưu `study_data.json` trong Application Documents, ghi file tạm và giữ `.bak` để phục hồi file hỏng. Giao diện không đổi trạng thái nếu lưu thất bại. Bài đọc, bản ghi và URL chấm phát âm lưu riêng trong Documents của app. JSON sao lưu không bao gồm âm thanh và nháp bài đọc. Gỡ app có thể xóa dữ liệu.

Chi tiết từ điển nằm trong trường tùy chọn `details` của mỗi thẻ và được đưa vào bản sao lưu JSON. Dữ liệu cũ chưa có trường này vẫn đọc được. Tra cứu chỉ gửi từ cần tra tới `en.wiktionary.org`, không gửi nghĩa tự nhập hay toàn bộ thư viện. Kết quả giữ nguyên ngôn ngữ nguồn (phần giải thích thường bằng tiếng Anh), kèm liên kết nguồn và thời điểm tra. Wiktionary là dữ liệu cộng đồng theo CC BY-SA; không phải mọi mục từ đều có ví dụ/cách dùng/đồng nghĩa, và một từ có thể có nhiều nghĩa. Những mục thiếu thông tin được ghi rõ trong popup.

## Chạy và kiểm tra

```sh
flutter pub get
flutter analyze
flutter test
flutter run
flutter build apk --debug
```

Windows có thể yêu cầu Developer Mode để tạo symlink plugin khi chạy `flutter pub get` hoặc build desktop. App nhắm đến Android/iOS; bản web chưa hỗ trợ vì dữ liệu lưu bằng file thiết bị. APK debug nằm ở `build/app/outputs/flutter-apk/app-debug.apk`; chưa phải bản ký để phát hành trên cửa hàng.

## iPhone 13

Bố cục tự điều chỉnh khoảng cách và cỡ chữ theo chiều rộng, có SafeArea cho tai thỏ/thanh Home và cuộn khi nội dung dài. Đã kiểm thử ở 320 × 568, 360 × 640, 390 × 844, 430 × 932, 600 × 960 và 844 × 390 logical pixels, cùng cỡ chữ hệ thống lớn. Nút đã thuộc có kích thước gọn và vùng chạm riêng; nghĩa và từ vựng dùng cùng cỡ chữ. Nút tạo danh mục nằm trong nội dung để tránh che thao tác trên màn hình nhỏ. Ảnh kiểm thử ở `build/previews` dùng font Windows; iPhone sẽ dùng font hệ thống.

Build iOS cần macOS, Xcode và Flutter: chép dự án sang Mac, chạy `flutter pub get`, mở `ios/Runner.xcworkspace`, chọn Team ký app và iPhone 13, chạy bằng Xcode hoặc `flutter run`. Phân phối bằng `flutter build ipa` và quy trình ký/phân phối Apple. Quyền micro đã khai báo trong `Info.plist`.

Chưa xác minh trên iPhone thật: quyền micro, giọng Hàn/Việt, ghi/phát âm thanh, kết nối Azure. Tải giọng Hàn/Việt trong cài đặt thiết bị nếu chưa có; một số giọng có thể cần mạng.

## Chấm phát âm

Chấm điểm vẫn cần máy chủ và Azure như bản gốc. Trong **Chấm phát âm**, nhập URL HTTPS đầy đủ, ví dụ `https://your-domain/api/pronunciation`. Máy chủ Next.js gốc phải cấu hình `AZURE_SPEECH_KEY` và `AZURE_SPEECH_REGION`. Không đưa khóa Azure vào app. Âm thanh được gửi khi dừng/chấm hoặc chấm lại. Nếu chưa có endpoint/cấu hình Azure, học offline và ghi âm vẫn dùng được, còn chấm điểm chưa dùng được.

## Kiểm thử

Kiểm tra seed, bố cục iPhone 13/cỡ chữ lớn, tạo danh mục/nhập từ, thư mục con, tiến độ qua khởi động lại, lưu thất bại, đáp án trùng, sửa đáp án kiểm tra, luyện viết, timeout/tạm dừng phản xạ, Unicode tiếng Hàn và phục hồi file hỏng. Âm thanh/Azure cần kiểm tra trên thiết bị thật với máy chủ đã cấu hình.
