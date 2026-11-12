# study_support_app（勉強サポートアプリ）

Flutter ＋ Firebase で作った勉強サポートアプリです。

## ファイルの地図

各ファイルの先頭に「何の画面か」「どこから開くか」の説明コメントがあります。

- 【画面】… 全体が切り替わる画面
- 【タブ】… 画面の中のタブ
- 【部品】… 画面の一部分（ほかの画面の中に表示される）
- 【ダイアログ】… 小さな確認ウィンドウ

```
lib/
├─ main.dart                  アプリの入口・下のタブ（MainNavigationScreen）
├─ firebase_options.dart      Firebase の接続設定（自動で作られる。手で編集しない）
├─ services/
│   └─ timer_service.dart     学習タイマーの通知（アプリを閉じても動く）
└─ screens/
    ├─ start/                 起動・初回登録
    │   ├─ splash_screen.dart         起動画面
    │   └─ onboarding_screen.dart     初回登録画面
    │
    ├─ home/                  下のタブ「ホーム」
    │   ├─ home_screen.dart           ホーム（タイマー・今日の目標）
    │   ├─ stopwatch_widget.dart      【部品】学習タイマー
    │   ├─ weekday_goal_button.dart   【部品】曜日ごとの目標ボタン
    │   └─ goal_time_setting_screen.dart  曜日ごとの目標時間の設定
    │
    ├─ ai_support/            下のタブ「AIサポート」
    │   ├─ ai_screen.dart             AIチャット（新しい会話）
    │   ├─ ai_history_screen.dart     履歴一覧
    │   ├─ ai_history_chat_screen.dart  過去の会話の続き
    │   ├─ ai_chat_input_bar.dart     【部品】入力欄
    │   └─ ai_chat_message.dart       【データの形】メッセージ1件分
    │
    ├─ link/                  下のタブ「Link」
    │   ├─ link_screen.dart           Link（ユーザー検索・Q&A・ルームの入口）
    │   ├─ user_search_screen.dart    ユーザー検索
    │   ├─ user_profile_screen.dart   相手のプロフィール
    │   ├─ qna_screen.dart            Q&A
    │   └─ room/
    │       ├─ room_screen.dart       ルーム（作成タブ・検索タブ）
    │       ├─ create_tab/
    │       │   ├─ create_room_tab.dart     【タブ】自分のルーム一覧
    │       │   ├─ room_card.dart           【部品】自分のルームのカード
    │       │   └─ room_making_screen.dart  新しいルームの作成
    │       ├─ search_tab/
    │       │   ├─ search_room_tab.dart     【タブ】公開ルームを探す
    │       │   └─ public_room_card.dart    【部品】公開ルームのカード
    │       └─ space/                 ルームの中
    │           ├─ room_space_screen.dart       ルームの中
    │           ├─ room_feature_screen.dart     メンバー／チャット／共有ノートの共通画面
    │           ├─ room_member_screen.dart      【部品】メンバー
    │           ├─ room_chat_screen.dart        【部品】チャット
    │           ├─ room_share_note_screen.dart  【部品】共有ノート
    │           └─ wallpaper_adjust_screen.dart 壁紙の調整
    │
    ├─ record/                下のタブ「学習記録」
    │   ├─ record_screen.dart         学習記録（2つのタブ）
    │   ├─ my_record/                 「自分の記録」タブ
    │   │   ├─ my_record_screen.dart          【タブ】今日の学習時間・目標達成日数
    │   │   ├─ study_time_chart_section.dart  【部品】学習時間グラフ
    │   │   ├─ recent_records_section.dart    【部品】最近の記録3件
    │   │   └─ all_study_records_screen.dart  記録の全件一覧
    │   └─ comparison/                「他の人と比較」タブ
    │       ├─ comparison_screen.dart         【タブ】比較する相手を選ぶ
    │       ├─ comparison_result_section.dart 【部品】比較結果
    │       └─ comparison_chart_section.dart  【部品】比較グラフ
    │
    ├─ mypage/                下のタブ「マイページ」
    │   ├─ mypage_screen.dart         マイページ（上半分）
    │   ├─ mypage_profile_section.dart  【部品】マイページの下半分
    │   ├─ profile_edit_screen.dart   プロフィール編集
    │   ├─ profile_edit_fields.dart   【部品】編集の入力欄
    │   ├─ profile_icon_adjust_screen.dart  アイコンの調整
    │   ├─ all_friends_screen.dart    友達の一覧
    │   └─ friend_request_dialog.dart 【ダイアログ】友達申請
    │
    ├─ chat/                  上部のチャットアイコンから
    │   ├─ chat_list_screen.dart      チャットの相手一覧
    │   └─ chat_room_screen.dart      1対1のチャット
    │
    ├─ notification/          上部の通知アイコンから
    │   ├─ notification_screen.dart   通知
    │   └─ friend_request_notification.dart  【部品】友達申請の通知1件
    │
    └─ settings/
        └─ settings_screen.dart       設定（マイページから）
```

## 旧ファイル名との対応

2026-11-05 にファイルの名前と置き場所を整理しました。あわせて、クラス名もファイル名に合わせました。

| 旧ファイル | 新ファイル |
|---|---|
| `data_screen.dart` | `screens/start/onboarding_screen.dart` |
| `splash_screen.dart` | `screens/start/splash_screen.dart` |
| `setting_screen.dart` | `screens/settings/settings_screen.dart` |
| `profile_screen.dart` | `screens/link/user_profile_screen.dart` |
| `timer_service.dart` | `services/timer_service.dart` |
| `home_screen_folder/home_screen.dart` | `screens/home/home_screen.dart` |
| `home_screen_folder/home_screen2.dart` | `screens/home/weekday_goal_button.dart` |
| `home_screen_folder/goaltime_setting_screen.dart` | `screens/home/goal_time_setting_screen.dart` |
| `ai_screen_folder/ai_screen.dart` | `screens/ai_support/ai_screen.dart` |
| `ai_screen_folder/ai_history_screen.dart` | `screens/ai_support/ai_history_screen.dart` |
| `ai_screen_folder/aihistory_chat_screen.dart` | `screens/ai_support/ai_history_chat_screen.dart` |
| `ai_screen_folder/aichat_inputbar.dart` | `screens/ai_support/ai_chat_input_bar.dart` |
| `link_screen_folder/link_screen.dart` | `screens/link/link_screen.dart` |
| `link_screen_folder/qanda_screen.dart` | `screens/link/qna_screen.dart` |
| `link_screen_folder/user_search_screen.dart` | `screens/link/user_search_screen.dart` |
| `link_screen_folder/room_screen_folder/room_screen.dart` | `screens/link/room/room_screen.dart` |
| `…/room_makeTab_folder/room_make.dart` | `screens/link/room/create_tab/create_room_tab.dart` |
| `…/room_makeTab_folder/room_making.dart` | `screens/link/room/create_tab/room_making_screen.dart` |
| `…/room_searchTab_folder/room_search.dart` | `screens/link/room/search_tab/search_room_tab.dart` |
| `…/room_space_folder/room_space.dart` | `screens/link/room/space/room_space_screen.dart` |
| `…/room_space_folder/room_chat_screen.dart` | `screens/link/room/space/room_chat_screen.dart` |
| `…/room_space_folder/room_member_screen.dart` | `screens/link/room/space/room_member_screen.dart` |
| `…/room_space_folder/room_sharenote_screen.dart` | `screens/link/room/space/room_share_note_screen.dart` |
| `…/room_space_folder/wallpaper_adjust_screen.dart` | `screens/link/room/space/wallpaper_adjust_screen.dart` |
| `record_screen_folder/record_screen.dart` | `screens/record/record_screen.dart` |
| `…/record_myrecord_screen_folder/record_myrecord_screen.dart` | `screens/record/my_record/my_record_screen.dart` |
| `…/record_myrecord_screen_folder/record_myrecord_screen2.dart` | `screens/record/my_record/study_time_chart_section.dart` |
| `…/record_myrecord_screen_folder/record_myrecord_screen3.dart` | `screens/record/my_record/recent_records_section.dart` |
| `…/record_myrecord_screen_folder/all_study_records_screen.dart` | `screens/record/my_record/all_study_records_screen.dart` |
| `…/comparision_screen_folder/comparison_screen.dart` | `screens/record/comparison/comparison_screen.dart` |
| `…/comparision_screen_folder/comparison_screen2.dart` | `screens/record/comparison/comparison_result_section.dart` |
| `…/comparision_screen_folder/comparison_screen3.dart` | `screens/record/comparison/comparison_chart_section.dart` |
| `mypage_screen_folder/mypage_screen.dart` | `screens/mypage/mypage_screen.dart` |
| `mypage_screen_folder/mypage_screen2.dart` | `screens/mypage/mypage_profile_section.dart` |
| `mypage_screen_folder/profile_edit_screen.dart` | `screens/mypage/profile_edit_screen.dart` |
| `mypage_screen_folder/profile_edit_screen2.dart` | `screens/mypage/profile_edit_fields.dart` |
| `mypage_screen_folder/profile_icon_adjust_screen.dart` | `screens/mypage/profile_icon_adjust_screen.dart` |
| `mypage_screen_folder/all_friends_screen.dart` | `screens/mypage/all_friends_screen.dart` |
| `mypage_screen_folder/friend_request_screen.dart` | `screens/mypage/friend_request_dialog.dart` |
| `chat_icon_screen_folder/chat_list_screen.dart` | `screens/chat/chat_list_screen.dart` |
| `chat_icon_screen_folder/chat_room_screen.dart` | `screens/chat/chat_room_screen.dart` |
| `notification_screen_folder/notification_screen.dart` | `screens/notification/notification_screen.dart` |
| `notification_screen_folder/friend_request_notification.dart` | `screens/notification/friend_request_notification.dart` |

### クラス名の変更

| 旧クラス名 | 新クラス名 | ファイル |
|---|---|---|
| `GoaltimeSettingScreen` | `GoalTimeSettingScreen` | `screens/home/goal_time_setting_screen.dart` |
| `ProfileScreen` | `UserProfileScreen` | `screens/link/user_profile_screen.dart` |
| `QnAListPage` | `QnaListScreen` | `screens/link/qna_screen.dart` |
| `PostPage` | `QnaPostScreen` | `screens/link/qna_screen.dart` |
| `DetailPage` | `QnaDetailScreen` | `screens/link/qna_screen.dart` |
| `RecordMyRecordScreen` | `MyRecordScreen` | `screens/record/my_record/my_record_screen.dart` |
| `RecordMyRecordScreen2` | `StudyTimeChartSection` | `screens/record/my_record/study_time_chart_section.dart` |
| `RecordMyRecordScreen3` | `RecentRecordsSection` | `screens/record/my_record/recent_records_section.dart` |
| `ComparisonScreen2` | `ComparisonResultSection` | `screens/record/comparison/comparison_result_section.dart` |
| `ComparisonScreen3` | `ComparisonChartSection` | `screens/record/comparison/comparison_chart_section.dart` |
| `MypageScreen2` | `MypageProfileSection` | `screens/mypage/mypage_profile_section.dart` |
| `ProfileEditSection2` | `ProfileEditFields` | `screens/mypage/profile_edit_fields.dart` |
| `FriendRequestScreen` | `FriendRequestDialog` | `screens/mypage/friend_request_dialog.dart` |
| `SettingsPage` | `SettingsScreen` | `screens/settings/settings_screen.dart` |
| `_AiTestScreenState` | `_AiScreenState` | `screens/ai_support/ai_screen.dart` |
| `ChatMessage`（2か所に同じもの） | `AiChatMessage`（1つにまとめた） | `screens/ai_support/ai_chat_message.dart` |
| `_RoomFeatureScreen` | `RoomFeatureScreen` | `screens/link/room/space/room_feature_screen.dart` |

### 大きなファイルから分けたもの

| 元のファイル | 分けた先 |
|---|---|
| `screens/home/home_screen.dart` | `screens/home/stopwatch_widget.dart`（`StopwatchWidget`） |
| `screens/link/room/space/room_space_screen.dart` | `screens/link/room/space/room_feature_screen.dart`（`RoomFeatureScreen`） |
| `screens/link/room/create_tab/create_room_tab.dart` | `screens/link/room/create_tab/room_card.dart`（`RoomCard`） |
| `screens/link/room/search_tab/search_room_tab.dart` | `screens/link/room/search_tab/public_room_card.dart`（`PublicRoomCard`） |

### 削除したもの

- `record_screen_folder/record_model.dart`（どこからも使われていなかった）
- `temp_app/`（Flutter のひな形のままの別プロジェクト）
- `qna_screen.dart` の中の `main()` と `MyApp`（Q&A画面だけを単体で動かす用。アプリ本体からは使われていなかった）
- 使われていない import・変数・関数（自動チェック `flutter analyze` の指摘のうち、動きに関係しないもの）

## 書き方のルール

- アプリ内のファイルを読み込むときは `import 'package:study_support_app/…';` の形で書く
- コードの整形は `dart format lib` でそろえる
