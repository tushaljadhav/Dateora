import 'app_localizations.dart';

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Dateora';

  @override
  String get appTagline => 'Track Expiry Dates Before They Expire';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get done => 'Done';

  @override
  String get close => 'Close';

  @override
  String get confirm => 'Confirm';

  @override
  String get retry => 'Retry';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get search => 'Search';

  @override
  String get clear => 'Clear';

  @override
  String get notNow => 'Not Now';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get submit => 'Submit';

  @override
  String get required => 'Required';

  @override
  String get navHome => 'Home';

  @override
  String get navItems => 'Items';

  @override
  String get navCalendar => 'Calendar';

  @override
  String get navHistory => 'History';

  @override
  String get navSettings => 'Settings';

  @override
  String get homeGreeting => 'Hello';

  @override
  String get homeSubtitle => 'Keep tabs on your fresh groceries & essentials';

  @override
  String get homeActiveItems => 'Active Items';

  @override
  String get homeExpiringSoon => 'Expiring Soon';

  @override
  String get homeExpired => 'Expired';

  @override
  String get homeSafe => 'Safe';

  @override
  String get homeBachatTitle => 'Bachat Tracker';

  @override
  String get homeBachatSaved => 'Saved this month';

  @override
  String get homeBachatWasted => 'Wasted';

  @override
  String get homeBachatUsedItems => 'items used';

  @override
  String get homeBachatEstimated => 'Estimated based on entered prices';

  @override
  String get homeExpiringSoonSection => 'Expiring Soon';

  @override
  String get homeViewAll => 'View All';

  @override
  String get homeNoExpiringSoon => 'No products expiring soon!';

  @override
  String get homeNoExpiringSoonSubtitle => 'Everything is fresh and good to go.';

  @override
  String get homeAddNewItem => 'Add Item';

  @override
  String get itemsTitle => 'Inventory';

  @override
  String get itemsSearchHint => 'Search by name or category...';

  @override
  String get itemsFilterAll => 'All';

  @override
  String get itemsFilterExpiringSoon => 'Expiring Soon';

  @override
  String get itemsFilterExpired => 'Expired';

  @override
  String get itemsFilterSafe => 'Safe';

  @override
  String get itemsSortSoonest => 'Expiring Soonest';

  @override
  String get itemsSortRecentlyAdded => 'Recently Added';

  @override
  String get itemsSortName => 'Name (A-Z)';

  @override
  String get itemsEmptyTitle => 'No items found';

  @override
  String get itemsEmptySubtitle => 'Tap the button below to add your first item.';

  @override
  String get itemsDeleteConfirmTitle => 'Delete Item?';

  @override
  String get itemsDeleteConfirmMessage => 'Are you sure you want to delete this item? This action cannot be undone.';

  @override
  String get itemsMarkUsed => 'Mark as Used';

  @override
  String get itemsMarkDisposed => 'Mark as Disposed';

  @override
  String get addItemTitle => 'Add New Product';

  @override
  String get editItemTitle => 'Edit Product';

  @override
  String get itemSectionBasic => 'Basic Details';

  @override
  String get itemNameLabel => 'Product Name *';

  @override
  String get itemNameHint => 'e.g. Amul Milk, Crocin 650, Cetaphil';

  @override
  String get itemNameRequired => 'Please enter a product name';

  @override
  String get itemCategoryLabel => 'Category *';

  @override
  String get itemExpiryDateLabel => 'Expiry Date *';

  @override
  String get itemPriceLabel => 'Price (₹)';

  @override
  String get itemPriceHint => 'e.g. 65 (optional)';

  @override
  String get itemQuantityLabel => 'Quantity';

  @override
  String get itemQuantityHint => 'e.g. 1, 500';

  @override
  String get itemUnitLabel => 'Unit';

  @override
  String get itemUnitHint => 'e.g. pack, ml, kg';

  @override
  String get itemLocationLabel => 'Storage Location';

  @override
  String get itemLocationHint => 'e.g. Fridge, Pantry shelf, First aid kit';

  @override
  String get itemNotesLabel => 'Notes';

  @override
  String get itemNotesHint => 'e.g. Opened on Monday, batch number';

  @override
  String get itemRemindersLabel => 'Remind me before';

  @override
  String get itemReminderSameDay => 'Same Day (0 days)';

  @override
  String get itemReminder1Day => '1 day before';

  @override
  String get itemReminder3Days => '3 days before';

  @override
  String get itemReminder7Days => '7 days before';

  @override
  String get itemReminder14Days => '14 days before';

  @override
  String get itemReminder30Days => '30 days before';

  @override
  String get itemSavedSuccess => 'Product saved successfully!';

  @override
  String get itemAddButton => 'Save Product';

  @override
  String get itemUpdateButton => 'Update Product';

  @override
  String get itemAiDetectedBadge => 'AI Detected';

  @override
  String get itemBarcodeLookup => 'Barcode Scanner';

  @override
  String get itemAiScanner => 'Scan with AI';

  @override
  String get scannerTitle => 'Scan Barcode';

  @override
  String get scannerAlignFrame => 'Align barcode inside the viewfinder';

  @override
  String get scannerManualButton => 'Enter barcode manually';

  @override
  String get scannerManualDialogTitle => 'Enter Barcode';

  @override
  String get scannerManualDialogMessage => 'Enter the 8 to 13-digit barcode number printed on packaging:';

  @override
  String get scannerManualInputHint => 'e.g. 8901030383848';

  @override
  String get scannerCameraPermissionTitle => 'Camera Permission Needed';

  @override
  String get scannerCameraPermissionMessage => 'Camera permission is needed to scan barcodes directly.';

  @override
  String get scannerNotFoundMessage => 'Product not found in Open Food Facts. Barcode noted in notes for you.';

  @override
  String get scannerFoundMessage => 'Found product details from Open Food Facts!';

  @override
  String get bachatScreenTitle => 'Bachat & Savings';

  @override
  String get bachatEstimatedNotice => 'Estimated savings based on prices you entered. Used items count as saved money; disposed items count as wasted.';

  @override
  String get bachatTotalSaved => 'Total Saved';

  @override
  String get bachatTotalWasted => 'Total Wasted';

  @override
  String get bachatItemsUsed => 'Items Used';

  @override
  String get bachatItemsDisposed => 'Items Disposed';

  @override
  String get bachatMonthlyHistory => 'Last 6 Months Breakdown';

  @override
  String get bachatShareButton => 'Share My Savings';

  @override
  String get bachatNetSaved => 'Net Saved';

  @override
  String get bachatNoData => 'No used or disposed items recorded for this month yet.';

  @override
  String bachatShareText(String amount) {
    return 'I saved estimated ₹$amount with Dateora this month by tracking expiry dates! Never waste groceries again.';
  }

  @override
  String get bachatCardTitle => 'My Dateora Bachat';

  @override
  String get bachatCardTagline => 'Smart Expiry Tracking • Zero Food Waste';

  @override
  String get calendarTitle => 'Expiry Calendar';

  @override
  String get calendarNoItemsOnDate => 'No items expiring on this day.';

  @override
  String get historyTitle => 'History';

  @override
  String get historyEmpty => 'No past items';

  @override
  String get historyEmptySubtitle => 'Items you mark as Used or Disposed will appear here.';

  @override
  String get historyUsedBadge => 'Used';

  @override
  String get historyDisposedBadge => 'Disposed';

  @override
  String get historyRestore => 'Restore to Active';

  @override
  String get historyDeletePermanent => 'Delete Permanently';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionGeneral => 'Preferences';

  @override
  String get settingsSectionNotifications => 'Notifications & Reminders';

  @override
  String get settingsSectionPrivacy => 'Privacy & Data';

  @override
  String get settingsSectionAbout => 'About & Community';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'System Default';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageHindi => 'हिंदी';

  @override
  String get settingsLanguageMarathi => 'मराठी';

  @override
  String get settingsNotificationsEnable => 'Expiry Reminders';

  @override
  String get settingsNotificationsSubtitle => 'Get offline alerts before items expire';

  @override
  String get settingsWeeklySummary => 'Weekly Sunday Summary';

  @override
  String get settingsWeeklySummarySubtitle => 'Weekly overview of items expiring this week at 9:00 AM';

  @override
  String get settingsReminderTime => 'Daily Alert Time';

  @override
  String get settingsDefaultReminder => 'Default Reminder Offset';

  @override
  String get settingsAnalyticsToggle => 'Help improve Dateora';

  @override
  String get settingsAnalyticsSubtitle => 'Share anonymous usage data to help us fix issues (no names, photos, or private data)';

  @override
  String get settingsTellAFriend => 'Tell a Friend';

  @override
  String get settingsTellAFriendSubtitle => 'Share Dateora with family and friends';

  @override
  String get settingsExportData => 'Backup Data (JSON)';

  @override
  String get settingsExportSubtitle => 'Export all your tracked items to a file';

  @override
  String get settingsImportData => 'Restore Data (JSON)';

  @override
  String get settingsImportSubtitle => 'Import items from a previous backup';

  @override
  String settingsTellAFriendShareText(String url) {
    return 'Never let groceries or medicines expire again! Track expiry dates with Dateora: $url';
  }

  @override
  String get settingsPermissionsGrant => 'Check App Permissions';

  @override
  String get onboardingTitle1 => 'Track Expiry Dates';

  @override
  String get onboardingDesc1 => 'Keep all your groceries, medicines, and household items organized in one place.';

  @override
  String get onboardingTitle2 => 'Never Waste Money';

  @override
  String get onboardingDesc2 => 'Get timely reminders 7 days, 3 days, and on the day your products expire.';

  @override
  String get onboardingTitle3 => 'Smart Bachat & AI';

  @override
  String get onboardingDesc3 => 'Scan packaging photos with AI or scan barcodes to auto-fill details in seconds.';

  @override
  String get onboardingGetStarted => 'Get Started';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get categoryGroceries => 'Groceries';

  @override
  String get categoryMedicine => 'Medicine';

  @override
  String get categorySkincare => 'Skincare';

  @override
  String get categoryDairy => 'Dairy & Eggs';

  @override
  String get categoryHousehold => 'Household';

  @override
  String get categoryDocuments => 'Documents';

  @override
  String get categoryBeverages => 'Beverages';

  @override
  String get categoryPantry => 'Pantry';

  @override
  String get categoryCustom => 'Custom';

  @override
  String get statusExpired => 'Expired';

  @override
  String get statusExpiresToday => 'Expires Today';

  @override
  String get statusExpiresTomorrow => 'Expires Tomorrow';

  @override
  String statusExpiresInDays(int days) {
    return 'In $days days';
  }

  @override
  String get statusSafe => 'Safe';

  @override
  String statusExpiredDaysAgo(int days) {
    return 'Expired $days days ago';
  }

  @override
  String get statusExpiredYesterday => 'Expired yesterday';

  @override
  String get notifAlertTitle => 'Dateora Expiry Alert';

  @override
  String notifExpiresToday(String name) {
    return '$name expires today.';
  }

  @override
  String notifExpiresTomorrow(String name) {
    return '$name expires tomorrow.';
  }

  @override
  String notifExpiresInDays(String name, int days) {
    return '$name expires in $days days.';
  }

  @override
  String get notifWeeklySummaryTitle => 'Dateora Weekly Summary';

  @override
  String notifWeeklySummaryBody(int count) {
    return '$count items expire this week. Check them before they go bad!';
  }

  @override
  String get notifWeeklySummaryZeroBody => 'All clear! No items expiring this week. Enjoy your fresh supplies.';
}
