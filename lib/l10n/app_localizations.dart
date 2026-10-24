import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_mr.dart';

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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('mr')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Dateora'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Track Expiry Dates Before They Expire'**
  String get appTagline;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not Now'**
  String get notNow;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navItems.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get navItems;

  /// No description provided for @navCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get navCalendar;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get homeGreeting;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep tabs on your fresh groceries & essentials'**
  String get homeSubtitle;

  /// No description provided for @homeActiveItems.
  ///
  /// In en, this message translates to:
  /// **'Active Items'**
  String get homeActiveItems;

  /// No description provided for @homeExpiringSoon.
  ///
  /// In en, this message translates to:
  /// **'Expiring Soon'**
  String get homeExpiringSoon;

  /// No description provided for @homeExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get homeExpired;

  /// No description provided for @homeSafe.
  ///
  /// In en, this message translates to:
  /// **'Safe'**
  String get homeSafe;

  /// No description provided for @homeBachatTitle.
  ///
  /// In en, this message translates to:
  /// **'Bachat Tracker'**
  String get homeBachatTitle;

  /// No description provided for @homeBachatSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved this month'**
  String get homeBachatSaved;

  /// No description provided for @homeBachatWasted.
  ///
  /// In en, this message translates to:
  /// **'Wasted'**
  String get homeBachatWasted;

  /// No description provided for @homeBachatUsedItems.
  ///
  /// In en, this message translates to:
  /// **'items used'**
  String get homeBachatUsedItems;

  /// No description provided for @homeBachatEstimated.
  ///
  /// In en, this message translates to:
  /// **'Estimated based on entered prices'**
  String get homeBachatEstimated;

  /// No description provided for @homeExpiringSoonSection.
  ///
  /// In en, this message translates to:
  /// **'Expiring Soon'**
  String get homeExpiringSoonSection;

  /// No description provided for @homeViewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get homeViewAll;

  /// No description provided for @homeNoExpiringSoon.
  ///
  /// In en, this message translates to:
  /// **'No products expiring soon!'**
  String get homeNoExpiringSoon;

  /// No description provided for @homeNoExpiringSoonSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Everything is fresh and good to go.'**
  String get homeNoExpiringSoonSubtitle;

  /// No description provided for @homeAddNewItem.
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get homeAddNewItem;

  /// No description provided for @itemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get itemsTitle;

  /// No description provided for @itemsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or category...'**
  String get itemsSearchHint;

  /// No description provided for @itemsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get itemsFilterAll;

  /// No description provided for @itemsFilterExpiringSoon.
  ///
  /// In en, this message translates to:
  /// **'Expiring Soon'**
  String get itemsFilterExpiringSoon;

  /// No description provided for @itemsFilterExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get itemsFilterExpired;

  /// No description provided for @itemsFilterSafe.
  ///
  /// In en, this message translates to:
  /// **'Safe'**
  String get itemsFilterSafe;

  /// No description provided for @itemsSortSoonest.
  ///
  /// In en, this message translates to:
  /// **'Expiring Soonest'**
  String get itemsSortSoonest;

  /// No description provided for @itemsSortRecentlyAdded.
  ///
  /// In en, this message translates to:
  /// **'Recently Added'**
  String get itemsSortRecentlyAdded;

  /// No description provided for @itemsSortName.
  ///
  /// In en, this message translates to:
  /// **'Name (A-Z)'**
  String get itemsSortName;

  /// No description provided for @itemsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No items found'**
  String get itemsEmptyTitle;

  /// No description provided for @itemsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap the button below to add your first item.'**
  String get itemsEmptySubtitle;

  /// No description provided for @itemsDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Item?'**
  String get itemsDeleteConfirmTitle;

  /// No description provided for @itemsDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this item? This action cannot be undone.'**
  String get itemsDeleteConfirmMessage;

  /// No description provided for @itemsMarkUsed.
  ///
  /// In en, this message translates to:
  /// **'Mark as Used'**
  String get itemsMarkUsed;

  /// No description provided for @itemsMarkDisposed.
  ///
  /// In en, this message translates to:
  /// **'Mark as Disposed'**
  String get itemsMarkDisposed;

  /// No description provided for @addItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Add New Product'**
  String get addItemTitle;

  /// No description provided for @editItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Product'**
  String get editItemTitle;

  /// No description provided for @itemSectionBasic.
  ///
  /// In en, this message translates to:
  /// **'Basic Details'**
  String get itemSectionBasic;

  /// No description provided for @itemNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Product Name *'**
  String get itemNameLabel;

  /// No description provided for @itemNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Amul Milk, Crocin 650, Cetaphil'**
  String get itemNameHint;

  /// No description provided for @itemNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a product name'**
  String get itemNameRequired;

  /// No description provided for @itemCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category *'**
  String get itemCategoryLabel;

  /// No description provided for @itemExpiryDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Expiry Date *'**
  String get itemExpiryDateLabel;

  /// No description provided for @itemPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price (₹)'**
  String get itemPriceLabel;

  /// No description provided for @itemPriceHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 65 (optional)'**
  String get itemPriceHint;

  /// No description provided for @itemQuantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get itemQuantityLabel;

  /// No description provided for @itemQuantityHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 1, 500'**
  String get itemQuantityHint;

  /// No description provided for @itemUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get itemUnitLabel;

  /// No description provided for @itemUnitHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. pack, ml, kg'**
  String get itemUnitHint;

  /// No description provided for @itemLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Storage Location'**
  String get itemLocationLabel;

  /// No description provided for @itemLocationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Fridge, Pantry shelf, First aid kit'**
  String get itemLocationHint;

  /// No description provided for @itemNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get itemNotesLabel;

  /// No description provided for @itemNotesHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Opened on Monday, batch number'**
  String get itemNotesHint;

  /// No description provided for @itemRemindersLabel.
  ///
  /// In en, this message translates to:
  /// **'Remind me before'**
  String get itemRemindersLabel;

  /// No description provided for @itemReminderSameDay.
  ///
  /// In en, this message translates to:
  /// **'Same Day (0 days)'**
  String get itemReminderSameDay;

  /// No description provided for @itemReminder1Day.
  ///
  /// In en, this message translates to:
  /// **'1 day before'**
  String get itemReminder1Day;

  /// No description provided for @itemReminder3Days.
  ///
  /// In en, this message translates to:
  /// **'3 days before'**
  String get itemReminder3Days;

  /// No description provided for @itemReminder7Days.
  ///
  /// In en, this message translates to:
  /// **'7 days before'**
  String get itemReminder7Days;

  /// No description provided for @itemReminder14Days.
  ///
  /// In en, this message translates to:
  /// **'14 days before'**
  String get itemReminder14Days;

  /// No description provided for @itemReminder30Days.
  ///
  /// In en, this message translates to:
  /// **'30 days before'**
  String get itemReminder30Days;

  /// No description provided for @itemSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Product saved successfully!'**
  String get itemSavedSuccess;

  /// No description provided for @itemAddButton.
  ///
  /// In en, this message translates to:
  /// **'Save Product'**
  String get itemAddButton;

  /// No description provided for @itemUpdateButton.
  ///
  /// In en, this message translates to:
  /// **'Update Product'**
  String get itemUpdateButton;

  /// No description provided for @itemAiDetectedBadge.
  ///
  /// In en, this message translates to:
  /// **'AI Detected'**
  String get itemAiDetectedBadge;

  /// No description provided for @itemBarcodeLookup.
  ///
  /// In en, this message translates to:
  /// **'Barcode Scanner'**
  String get itemBarcodeLookup;

  /// No description provided for @itemAiScanner.
  ///
  /// In en, this message translates to:
  /// **'Scan with AI'**
  String get itemAiScanner;

  /// No description provided for @scannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan Barcode'**
  String get scannerTitle;

  /// No description provided for @scannerAlignFrame.
  ///
  /// In en, this message translates to:
  /// **'Align barcode inside the viewfinder'**
  String get scannerAlignFrame;

  /// No description provided for @scannerManualButton.
  ///
  /// In en, this message translates to:
  /// **'Enter barcode manually'**
  String get scannerManualButton;

  /// No description provided for @scannerManualDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter Barcode'**
  String get scannerManualDialogTitle;

  /// No description provided for @scannerManualDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter the 8 to 13-digit barcode number printed on packaging:'**
  String get scannerManualDialogMessage;

  /// No description provided for @scannerManualInputHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 8901030383848'**
  String get scannerManualInputHint;

  /// No description provided for @scannerCameraPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Camera Permission Needed'**
  String get scannerCameraPermissionTitle;

  /// No description provided for @scannerCameraPermissionMessage.
  ///
  /// In en, this message translates to:
  /// **'Camera permission is needed to scan barcodes directly.'**
  String get scannerCameraPermissionMessage;

  /// No description provided for @scannerNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'Product not found in Open Food Facts. Barcode noted in notes for you.'**
  String get scannerNotFoundMessage;

  /// No description provided for @scannerFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'Found product details from Open Food Facts!'**
  String get scannerFoundMessage;

  /// No description provided for @bachatScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Bachat & Savings'**
  String get bachatScreenTitle;

  /// No description provided for @bachatEstimatedNotice.
  ///
  /// In en, this message translates to:
  /// **'Estimated savings based on prices you entered. Used items count as saved money; disposed items count as wasted.'**
  String get bachatEstimatedNotice;

  /// No description provided for @bachatTotalSaved.
  ///
  /// In en, this message translates to:
  /// **'Total Saved'**
  String get bachatTotalSaved;

  /// No description provided for @bachatTotalWasted.
  ///
  /// In en, this message translates to:
  /// **'Total Wasted'**
  String get bachatTotalWasted;

  /// No description provided for @bachatItemsUsed.
  ///
  /// In en, this message translates to:
  /// **'Items Used'**
  String get bachatItemsUsed;

  /// No description provided for @bachatItemsDisposed.
  ///
  /// In en, this message translates to:
  /// **'Items Disposed'**
  String get bachatItemsDisposed;

  /// No description provided for @bachatMonthlyHistory.
  ///
  /// In en, this message translates to:
  /// **'Last 6 Months Breakdown'**
  String get bachatMonthlyHistory;

  /// No description provided for @bachatShareButton.
  ///
  /// In en, this message translates to:
  /// **'Share My Savings'**
  String get bachatShareButton;

  /// No description provided for @bachatNetSaved.
  ///
  /// In en, this message translates to:
  /// **'Net Saved'**
  String get bachatNetSaved;

  /// No description provided for @bachatNoData.
  ///
  /// In en, this message translates to:
  /// **'No used or disposed items recorded for this month yet.'**
  String get bachatNoData;

  /// No description provided for @bachatShareText.
  ///
  /// In en, this message translates to:
  /// **'I saved estimated ₹{amount} with Dateora this month by tracking expiry dates! Never waste groceries again.'**
  String bachatShareText(String amount);

  /// No description provided for @bachatCardTitle.
  ///
  /// In en, this message translates to:
  /// **'My Dateora Bachat'**
  String get bachatCardTitle;

  /// No description provided for @bachatCardTagline.
  ///
  /// In en, this message translates to:
  /// **'Smart Expiry Tracking • Zero Food Waste'**
  String get bachatCardTagline;

  /// No description provided for @calendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Expiry Calendar'**
  String get calendarTitle;

  /// No description provided for @calendarNoItemsOnDate.
  ///
  /// In en, this message translates to:
  /// **'No items expiring on this day.'**
  String get calendarNoItemsOnDate;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// No description provided for @historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No past items'**
  String get historyEmpty;

  /// No description provided for @historyEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Items you mark as Used or Disposed will appear here.'**
  String get historyEmptySubtitle;

  /// No description provided for @historyUsedBadge.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get historyUsedBadge;

  /// No description provided for @historyDisposedBadge.
  ///
  /// In en, this message translates to:
  /// **'Disposed'**
  String get historyDisposedBadge;

  /// No description provided for @historyRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore to Active'**
  String get historyRestore;

  /// No description provided for @historyDeletePermanent.
  ///
  /// In en, this message translates to:
  /// **'Delete Permanently'**
  String get historyDeletePermanent;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSectionGeneral.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settingsSectionGeneral;

  /// No description provided for @settingsSectionNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications & Reminders'**
  String get settingsSectionNotifications;

  /// No description provided for @settingsSectionPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Data'**
  String get settingsSectionPrivacy;

  /// No description provided for @settingsSectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About & Community'**
  String get settingsSectionAbout;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsLanguageHindi.
  ///
  /// In en, this message translates to:
  /// **'हिंदी'**
  String get settingsLanguageHindi;

  /// No description provided for @settingsLanguageMarathi.
  ///
  /// In en, this message translates to:
  /// **'मराठी'**
  String get settingsLanguageMarathi;

  /// No description provided for @settingsNotificationsEnable.
  ///
  /// In en, this message translates to:
  /// **'Expiry Reminders'**
  String get settingsNotificationsEnable;

  /// No description provided for @settingsNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get offline alerts before items expire'**
  String get settingsNotificationsSubtitle;

  /// No description provided for @settingsWeeklySummary.
  ///
  /// In en, this message translates to:
  /// **'Weekly Sunday Summary'**
  String get settingsWeeklySummary;

  /// No description provided for @settingsWeeklySummarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly overview of items expiring this week at 9:00 AM'**
  String get settingsWeeklySummarySubtitle;

  /// No description provided for @settingsReminderTime.
  ///
  /// In en, this message translates to:
  /// **'Daily Alert Time'**
  String get settingsReminderTime;

  /// No description provided for @settingsDefaultReminder.
  ///
  /// In en, this message translates to:
  /// **'Default Reminder Offset'**
  String get settingsDefaultReminder;

  /// No description provided for @settingsAnalyticsToggle.
  ///
  /// In en, this message translates to:
  /// **'Help improve Dateora'**
  String get settingsAnalyticsToggle;

  /// No description provided for @settingsAnalyticsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share anonymous usage data to help us fix issues (no names, photos, or private data)'**
  String get settingsAnalyticsSubtitle;

  /// No description provided for @settingsTellAFriend.
  ///
  /// In en, this message translates to:
  /// **'Tell a Friend'**
  String get settingsTellAFriend;

  /// No description provided for @settingsTellAFriendSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share Dateora with family and friends'**
  String get settingsTellAFriendSubtitle;

  /// No description provided for @settingsExportData.
  ///
  /// In en, this message translates to:
  /// **'Backup Data (JSON)'**
  String get settingsExportData;

  /// No description provided for @settingsExportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Export all your tracked items to a file'**
  String get settingsExportSubtitle;

  /// No description provided for @settingsImportData.
  ///
  /// In en, this message translates to:
  /// **'Restore Data (JSON)'**
  String get settingsImportData;

  /// No description provided for @settingsImportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Import items from a previous backup'**
  String get settingsImportSubtitle;

  /// No description provided for @settingsTellAFriendShareText.
  ///
  /// In en, this message translates to:
  /// **'Never let groceries or medicines expire again! Track expiry dates with Dateora: {url}'**
  String settingsTellAFriendShareText(String url);

  /// No description provided for @settingsPermissionsGrant.
  ///
  /// In en, this message translates to:
  /// **'Check App Permissions'**
  String get settingsPermissionsGrant;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Track Expiry Dates'**
  String get onboardingTitle1;

  /// No description provided for @onboardingDesc1.
  ///
  /// In en, this message translates to:
  /// **'Keep all your groceries, medicines, and household items organized in one place.'**
  String get onboardingDesc1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Never Waste Money'**
  String get onboardingTitle2;

  /// No description provided for @onboardingDesc2.
  ///
  /// In en, this message translates to:
  /// **'Get timely reminders 7 days, 3 days, and on the day your products expire.'**
  String get onboardingDesc2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Smart Bachat & AI'**
  String get onboardingTitle3;

  /// No description provided for @onboardingDesc3.
  ///
  /// In en, this message translates to:
  /// **'Scan packaging photos with AI or scan barcodes to auto-fill details in seconds.'**
  String get onboardingDesc3;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingGetStarted;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @categoryGroceries.
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get categoryGroceries;

  /// No description provided for @categoryMedicine.
  ///
  /// In en, this message translates to:
  /// **'Medicine'**
  String get categoryMedicine;

  /// No description provided for @categorySkincare.
  ///
  /// In en, this message translates to:
  /// **'Skincare'**
  String get categorySkincare;

  /// No description provided for @categoryDairy.
  ///
  /// In en, this message translates to:
  /// **'Dairy & Eggs'**
  String get categoryDairy;

  /// No description provided for @categoryHousehold.
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get categoryHousehold;

  /// No description provided for @categoryDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get categoryDocuments;

  /// No description provided for @categoryBeverages.
  ///
  /// In en, this message translates to:
  /// **'Beverages'**
  String get categoryBeverages;

  /// No description provided for @categoryPantry.
  ///
  /// In en, this message translates to:
  /// **'Pantry'**
  String get categoryPantry;

  /// No description provided for @categoryCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get categoryCustom;

  /// No description provided for @statusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get statusExpired;

  /// No description provided for @statusExpiresToday.
  ///
  /// In en, this message translates to:
  /// **'Expires Today'**
  String get statusExpiresToday;

  /// No description provided for @statusExpiresTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Expires Tomorrow'**
  String get statusExpiresTomorrow;

  /// No description provided for @statusExpiresInDays.
  ///
  /// In en, this message translates to:
  /// **'In {days} days'**
  String statusExpiresInDays(int days);

  /// No description provided for @statusSafe.
  ///
  /// In en, this message translates to:
  /// **'Safe'**
  String get statusSafe;

  /// No description provided for @statusExpiredDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'Expired {days} days ago'**
  String statusExpiredDaysAgo(int days);

  /// No description provided for @statusExpiredYesterday.
  ///
  /// In en, this message translates to:
  /// **'Expired yesterday'**
  String get statusExpiredYesterday;

  /// No description provided for @notifAlertTitle.
  ///
  /// In en, this message translates to:
  /// **'Dateora Expiry Alert'**
  String get notifAlertTitle;

  /// No description provided for @notifExpiresToday.
  ///
  /// In en, this message translates to:
  /// **'{name} expires today.'**
  String notifExpiresToday(String name);

  /// No description provided for @notifExpiresTomorrow.
  ///
  /// In en, this message translates to:
  /// **'{name} expires tomorrow.'**
  String notifExpiresTomorrow(String name);

  /// No description provided for @notifExpiresInDays.
  ///
  /// In en, this message translates to:
  /// **'{name} expires in {days} days.'**
  String notifExpiresInDays(String name, int days);

  /// No description provided for @notifWeeklySummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Dateora Weekly Summary'**
  String get notifWeeklySummaryTitle;

  /// No description provided for @notifWeeklySummaryBody.
  ///
  /// In en, this message translates to:
  /// **'{count} items expire this week. Check them before they go bad!'**
  String notifWeeklySummaryBody(int count);

  /// No description provided for @notifWeeklySummaryZeroBody.
  ///
  /// In en, this message translates to:
  /// **'All clear! No items expiring this week. Enjoy your fresh supplies.'**
  String get notifWeeklySummaryZeroBody;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'hi', 'mr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'hi': return AppLocalizationsHi();
    case 'mr': return AppLocalizationsMr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
