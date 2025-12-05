import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_kn.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('hi'),
    Locale('kn'),
    Locale('ta'),
    Locale('te')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'My Goat Manager'**
  String get appTitle;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @syncData.
  ///
  /// In en, this message translates to:
  /// **'Sync Data'**
  String get syncData;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @languageChangedTo.
  ///
  /// In en, this message translates to:
  /// **'Language changed to'**
  String get languageChangedTo;

  /// No description provided for @goats.
  ///
  /// In en, this message translates to:
  /// **'Goats'**
  String get goats;

  /// No description provided for @milkRecords.
  ///
  /// In en, this message translates to:
  /// **'Milk Records'**
  String get milkRecords;

  /// No description provided for @events.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get events;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @farmSetup.
  ///
  /// In en, this message translates to:
  /// **'Farm Setup'**
  String get farmSetup;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @createYourFarmAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Your Farm Account'**
  String get createYourFarmAccount;

  /// No description provided for @loginOrCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Login or Create Account'**
  String get loginOrCreateAccount;

  /// No description provided for @upgradeAndAccount.
  ///
  /// In en, this message translates to:
  /// **'Upgrade and Account'**
  String get upgradeAndAccount;

  /// No description provided for @appAndFarmTools.
  ///
  /// In en, this message translates to:
  /// **'App and Farm Tools'**
  String get appAndFarmTools;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @farmNotes.
  ///
  /// In en, this message translates to:
  /// **'Farm Notes'**
  String get farmNotes;

  /// No description provided for @seeAllOurApps.
  ///
  /// In en, this message translates to:
  /// **'See All Our Apps'**
  String get seeAllOurApps;

  /// No description provided for @farmingKnowledge.
  ///
  /// In en, this message translates to:
  /// **'Farming Knowledge'**
  String get farmingKnowledge;

  /// No description provided for @helpAndSupport.
  ///
  /// In en, this message translates to:
  /// **'Help and Support'**
  String get helpAndSupport;

  /// No description provided for @howToUseThisApp.
  ///
  /// In en, this message translates to:
  /// **'How to Use This App'**
  String get howToUseThisApp;

  /// No description provided for @contactOurTeam.
  ///
  /// In en, this message translates to:
  /// **'Contact Our Team'**
  String get contactOurTeam;

  /// No description provided for @shareAndRecommend.
  ///
  /// In en, this message translates to:
  /// **'Share and Recommend'**
  String get shareAndRecommend;

  /// No description provided for @shareAppWithFriends.
  ///
  /// In en, this message translates to:
  /// **'Share App with Friends'**
  String get shareAppWithFriends;

  /// No description provided for @rateAppInPlayStore.
  ///
  /// In en, this message translates to:
  /// **'Rate App in Play Store'**
  String get rateAppInPlayStore;

  /// No description provided for @legal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get legal;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @noNewNotifications.
  ///
  /// In en, this message translates to:
  /// **'No New Notifications'**
  String get noNewNotifications;

  /// No description provided for @syncingData.
  ///
  /// In en, this message translates to:
  /// **'Syncing Data'**
  String get syncingData;

  /// No description provided for @dataSyncedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Data Synced Successfully'**
  String get dataSyncedSuccessfully;

  /// No description provided for @selectBreed.
  ///
  /// In en, this message translates to:
  /// **'Select breed ..'**
  String get selectBreed;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get searchHint;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @allBreeds.
  ///
  /// In en, this message translates to:
  /// **'All Breeds'**
  String get allBreeds;

  /// No description provided for @breedOptional.
  ///
  /// In en, this message translates to:
  /// **'Breed (optional)'**
  String get breedOptional;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @photoCaptured.
  ///
  /// In en, this message translates to:
  /// **'Photo captured successfully!'**
  String get photoCaptured;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @imageSelected.
  ///
  /// In en, this message translates to:
  /// **'Image selected successfully!'**
  String get imageSelected;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove Photo'**
  String get removePhoto;

  /// No description provided for @photoRemoved.
  ///
  /// In en, this message translates to:
  /// **'Photo removed'**
  String get photoRemoved;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @generalDetails.
  ///
  /// In en, this message translates to:
  /// **'General Details'**
  String get generalDetails;

  /// No description provided for @tagNo.
  ///
  /// In en, this message translates to:
  /// **'Tag No:'**
  String get tagNo;

  /// No description provided for @tagNoLabel.
  ///
  /// In en, this message translates to:
  /// **'Tag No:'**
  String get tagNoLabel;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name:'**
  String get nameLabel;

  /// No description provided for @dobLabel.
  ///
  /// In en, this message translates to:
  /// **'D.O.B:'**
  String get dobLabel;

  /// No description provided for @ageLabel.
  ///
  /// In en, this message translates to:
  /// **'Age:'**
  String get ageLabel;

  /// No description provided for @genderLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender:'**
  String get genderLabel;

  /// No description provided for @weightLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight:'**
  String get weightLabel;

  /// No description provided for @stageLabel.
  ///
  /// In en, this message translates to:
  /// **'Stage:'**
  String get stageLabel;

  /// No description provided for @breedLabel.
  ///
  /// In en, this message translates to:
  /// **'Breed:'**
  String get breedLabel;

  /// No description provided for @groupLabel.
  ///
  /// In en, this message translates to:
  /// **'Group:'**
  String get groupLabel;

  /// No description provided for @joinedOn.
  ///
  /// In en, this message translates to:
  /// **'Joined On:'**
  String get joinedOn;

  /// No description provided for @joinedOnLabel.
  ///
  /// In en, this message translates to:
  /// **'Joined On:'**
  String get joinedOnLabel;

  /// No description provided for @sourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Source:'**
  String get sourceLabel;

  /// No description provided for @motherLabel.
  ///
  /// In en, this message translates to:
  /// **'Mother:'**
  String get motherLabel;

  /// No description provided for @fatherLabel.
  ///
  /// In en, this message translates to:
  /// **'Father:'**
  String get fatherLabel;

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes:'**
  String get notesLabel;

  /// No description provided for @tapToUpload.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload a picture...'**
  String get tapToUpload;

  /// No description provided for @changePicture.
  ///
  /// In en, this message translates to:
  /// **'Change picture...'**
  String get changePicture;

  /// No description provided for @goatsOffspring.
  ///
  /// In en, this message translates to:
  /// **'Goat\'s Offspring'**
  String get goatsOffspring;

  /// No description provided for @goatOffspring.
  ///
  /// In en, this message translates to:
  /// **'Goat\'s Offspring'**
  String get goatOffspring;

  /// No description provided for @noEventsYet.
  ///
  /// In en, this message translates to:
  /// **'No Events Yet'**
  String get noEventsYet;

  /// No description provided for @eventsForThisGoat.
  ///
  /// In en, this message translates to:
  /// **'Events for this goat will appear here'**
  String get eventsForThisGoat;

  /// No description provided for @eventsPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Events for this goat will appear here'**
  String get eventsPlaceholder;

  /// No description provided for @searchTagOrName.
  ///
  /// In en, this message translates to:
  /// **'Search tag or name...'**
  String get searchTagOrName;

  /// No description provided for @goatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Goats'**
  String get goatsTitle;

  /// No description provided for @noGoatsAvailableToPreview.
  ///
  /// In en, this message translates to:
  /// **'No goats available to preview'**
  String get noGoatsAvailableToPreview;

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get exportPdf;

  /// No description provided for @filterBy.
  ///
  /// In en, this message translates to:
  /// **'Filter By'**
  String get filterBy;

  /// No description provided for @sortByAge.
  ///
  /// In en, this message translates to:
  /// **'Sort by Age'**
  String get sortByAge;

  /// No description provided for @noGoatsRegistered.
  ///
  /// In en, this message translates to:
  /// **'No goats have been registered for the selected filters as of yet!'**
  String get noGoatsRegistered;

  /// No description provided for @selectGroup.
  ///
  /// In en, this message translates to:
  /// **'Select group ..'**
  String get selectGroup;

  /// No description provided for @addGoat.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addGoat;

  /// No description provided for @viewRecord.
  ///
  /// In en, this message translates to:
  /// **'View Record'**
  String get viewRecord;

  /// No description provided for @editRecord.
  ///
  /// In en, this message translates to:
  /// **'Edit Record'**
  String get editRecord;

  /// No description provided for @addEvent.
  ///
  /// In en, this message translates to:
  /// **'Add Event'**
  String get addEvent;

  /// No description provided for @deleteGoatTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Goat'**
  String get deleteGoatTitle;

  /// No description provided for @deleteGoatConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete goat'**
  String get deleteGoatConfirm;

  /// No description provided for @deleteGoatDeleted.
  ///
  /// In en, this message translates to:
  /// **'Goat deleted'**
  String get deleteGoatDeleted;

  /// No description provided for @goatsListPdf.
  ///
  /// In en, this message translates to:
  /// **'Goats List'**
  String get goatsListPdf;

  /// No description provided for @breedLabel2.
  ///
  /// In en, this message translates to:
  /// **'Breed:'**
  String get breedLabel2;

  /// No description provided for @groupLabel2.
  ///
  /// In en, this message translates to:
  /// **'Group:'**
  String get groupLabel2;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date:'**
  String get dateLabel;

  /// No description provided for @totalGoats.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalGoats;

  /// No description provided for @newGoat.
  ///
  /// In en, this message translates to:
  /// **'New Goat'**
  String get newGoat;

  /// No description provided for @pleaseSelectAllRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select all required fields'**
  String get pleaseSelectAllRequired;

  /// No description provided for @tagNoLabel2.
  ///
  /// In en, this message translates to:
  /// **'Tag no. *'**
  String get tagNoLabel2;

  /// No description provided for @nameLabel2.
  ///
  /// In en, this message translates to:
  /// **'Name.'**
  String get nameLabel2;

  /// No description provided for @selectGender.
  ///
  /// In en, this message translates to:
  /// **'Select Gender. *'**
  String get selectGender;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of birth.'**
  String get dateOfBirth;

  /// No description provided for @dateOfEntry.
  ///
  /// In en, this message translates to:
  /// **'Date of entry on the farm.'**
  String get dateOfEntry;

  /// No description provided for @weightLabel2.
  ///
  /// In en, this message translates to:
  /// **'Weight.'**
  String get weightLabel2;

  /// No description provided for @groupOptional.
  ///
  /// In en, this message translates to:
  /// **'Group (optional)'**
  String get groupOptional;

  /// No description provided for @breedOptional2.
  ///
  /// In en, this message translates to:
  /// **'Breed (optional)'**
  String get breedOptional2;

  /// No description provided for @selectObtained.
  ///
  /// In en, this message translates to:
  /// **'Select how the goat was obtained. *'**
  String get selectObtained;

  /// No description provided for @motherTagLabel.
  ///
  /// In en, this message translates to:
  /// **'Mother\'s tag no.'**
  String get motherTagLabel;

  /// No description provided for @fatherTagLabel.
  ///
  /// In en, this message translates to:
  /// **'Father\'s tag no.'**
  String get fatherTagLabel;

  /// No description provided for @notesPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Write some notes ...'**
  String get notesPlaceholder;

  /// No description provided for @createNewBreed.
  ///
  /// In en, this message translates to:
  /// **'Create new breed...'**
  String get createNewBreed;

  /// No description provided for @createNewGroup.
  ///
  /// In en, this message translates to:
  /// **'Create new group...'**
  String get createNewGroup;

  /// No description provided for @goatCreated.
  ///
  /// In en, this message translates to:
  /// **'Goat created successfully!'**
  String get goatCreated;

  /// No description provided for @goatUpdated.
  ///
  /// In en, this message translates to:
  /// **'Goat updated successfully!'**
  String get goatUpdated;

  /// No description provided for @filterByPeriod.
  ///
  /// In en, this message translates to:
  /// **'Filter by Period'**
  String get filterByPeriod;

  /// No description provided for @filterByMilkType.
  ///
  /// In en, this message translates to:
  /// **'Filter by Milk Type'**
  String get filterByMilkType;

  /// No description provided for @noMilkRecordsDisplay.
  ///
  /// In en, this message translates to:
  /// **'There is no milk records to display for the selected date range.'**
  String get noMilkRecordsDisplay;

  /// No description provided for @farm.
  ///
  /// In en, this message translates to:
  /// **'Farm'**
  String get farm;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @used.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get used;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @filterByDateRange.
  ///
  /// In en, this message translates to:
  /// **'Filter by Date Range'**
  String get filterByDateRange;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @milkType.
  ///
  /// In en, this message translates to:
  /// **'Milk type'**
  String get milkType;

  /// No description provided for @allTypes.
  ///
  /// In en, this message translates to:
  /// **'All Types'**
  String get allTypes;

  /// No description provided for @wholeFarm.
  ///
  /// In en, this message translates to:
  /// **'Whole Farm'**
  String get wholeFarm;

  /// No description provided for @individualGoat.
  ///
  /// In en, this message translates to:
  /// **'Individual Goat'**
  String get individualGoat;

  /// No description provided for @generated.
  ///
  /// In en, this message translates to:
  /// **'Generated'**
  String get generated;

  /// No description provided for @noRecordsToExport.
  ///
  /// In en, this message translates to:
  /// **'No records to export.'**
  String get noRecordsToExport;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @selectMilkType.
  ///
  /// In en, this message translates to:
  /// **'- Select milk type -'**
  String get selectMilkType;

  /// No description provided for @editViewRecord.
  ///
  /// In en, this message translates to:
  /// **'Edit/View Record'**
  String get editViewRecord;

  /// No description provided for @deleteRecord.
  ///
  /// In en, this message translates to:
  /// **'Delete Record'**
  String get deleteRecord;

  /// No description provided for @deleteRecordConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this record?'**
  String get deleteRecordConfirmation;

  /// No description provided for @recordDeleted.
  ///
  /// In en, this message translates to:
  /// **'Record deleted successfully'**
  String get recordDeleted;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'to'**
  String get to;

  /// No description provided for @searchEventsHint.
  ///
  /// In en, this message translates to:
  /// **'Search events...'**
  String get searchEventsHint;

  /// No description provided for @individual.
  ///
  /// In en, this message translates to:
  /// **'Individual'**
  String get individual;

  /// No description provided for @mass.
  ///
  /// In en, this message translates to:
  /// **'Mass'**
  String get mass;

  /// No description provided for @filterByDate.
  ///
  /// In en, this message translates to:
  /// **'Filter by Date'**
  String get filterByDate;

  /// No description provided for @customDateRange.
  ///
  /// In en, this message translates to:
  /// **'Custom Date Range'**
  String get customDateRange;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From:'**
  String get from;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @lastWeek.
  ///
  /// In en, this message translates to:
  /// **'Last Week'**
  String get lastWeek;

  /// No description provided for @currentMonth.
  ///
  /// In en, this message translates to:
  /// **'Current Month'**
  String get currentMonth;

  /// No description provided for @lastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last Month'**
  String get lastMonth;

  /// No description provided for @filterByEventType.
  ///
  /// In en, this message translates to:
  /// **'Filter by Event Type'**
  String get filterByEventType;

  /// No description provided for @treated.
  ///
  /// In en, this message translates to:
  /// **'Treated'**
  String get treated;

  /// No description provided for @weighed.
  ///
  /// In en, this message translates to:
  /// **'Weighed'**
  String get weighed;

  /// No description provided for @weaned.
  ///
  /// In en, this message translates to:
  /// **'Weaned'**
  String get weaned;

  /// No description provided for @castrated.
  ///
  /// In en, this message translates to:
  /// **'Castrated'**
  String get castrated;

  /// No description provided for @vaccinated.
  ///
  /// In en, this message translates to:
  /// **'Vaccinated'**
  String get vaccinated;

  /// No description provided for @deworming.
  ///
  /// In en, this message translates to:
  /// **'Deworming'**
  String get deworming;

  /// No description provided for @hoofTrimming.
  ///
  /// In en, this message translates to:
  /// **'Hoof Trimming'**
  String get hoofTrimming;

  /// No description provided for @eventType.
  ///
  /// In en, this message translates to:
  /// **'Event Type'**
  String get eventType;

  /// No description provided for @noIndividualEvents.
  ///
  /// In en, this message translates to:
  /// **'There are no individual events to display for the selected date range.'**
  String get noIndividualEvents;

  /// No description provided for @noMassEvents.
  ///
  /// In en, this message translates to:
  /// **'There are no mass events to display for the selected date range.'**
  String get noMassEvents;

  /// No description provided for @selectGoatToContinue.
  ///
  /// In en, this message translates to:
  /// **'Select Goat to Continue...'**
  String get selectGoatToContinue;

  /// No description provided for @searchGoatHint.
  ///
  /// In en, this message translates to:
  /// **'Search goat...'**
  String get searchGoatHint;

  /// No description provided for @noGoatsFound.
  ///
  /// In en, this message translates to:
  /// **'No goats found'**
  String get noGoatsFound;

  /// No description provided for @medicineLabel.
  ///
  /// In en, this message translates to:
  /// **'Medicine:'**
  String get medicineLabel;

  /// No description provided for @diagnosisLabel.
  ///
  /// In en, this message translates to:
  /// **'Diagnosis:'**
  String get diagnosisLabel;

  /// No description provided for @symptomsLabel.
  ///
  /// In en, this message translates to:
  /// **'Symptoms:'**
  String get symptomsLabel;

  /// No description provided for @treatedByLabel.
  ///
  /// In en, this message translates to:
  /// **'Treated By:'**
  String get treatedByLabel;

  /// No description provided for @weighedLabel.
  ///
  /// In en, this message translates to:
  /// **'Weighed:'**
  String get weighedLabel;

  /// No description provided for @eventNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Event Name:'**
  String get eventNameLabel;

  /// No description provided for @editEvent.
  ///
  /// In en, this message translates to:
  /// **'Edit Event'**
  String get editEvent;

  /// No description provided for @viewGoat.
  ///
  /// In en, this message translates to:
  /// **'View Goat'**
  String get viewGoat;

  /// No description provided for @newMassEvent.
  ///
  /// In en, this message translates to:
  /// **'New Mass Event'**
  String get newMassEvent;

  /// No description provided for @newEvent.
  ///
  /// In en, this message translates to:
  /// **'New Event'**
  String get newEvent;

  /// No description provided for @eventDateRequired.
  ///
  /// In en, this message translates to:
  /// **'Event date. *'**
  String get eventDateRequired;

  /// No description provided for @selectEventTypeRequired.
  ///
  /// In en, this message translates to:
  /// **'Select event type. *'**
  String get selectEventTypeRequired;

  /// No description provided for @symptomsRequired.
  ///
  /// In en, this message translates to:
  /// **'Symptoms for sickness. *'**
  String get symptomsRequired;

  /// No description provided for @diagnosisRequired.
  ///
  /// In en, this message translates to:
  /// **'Diagnosis. *'**
  String get diagnosisRequired;

  /// No description provided for @technicianRequired.
  ///
  /// In en, this message translates to:
  /// **'Name of technician. *'**
  String get technicianRequired;

  /// No description provided for @medicineGivenRequired.
  ///
  /// In en, this message translates to:
  /// **'What medicine was given? *'**
  String get medicineGivenRequired;

  /// No description provided for @weighedResultRequired.
  ///
  /// In en, this message translates to:
  /// **'Weighed result. *'**
  String get weighedResultRequired;

  /// No description provided for @eventNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name of event. *'**
  String get eventNameRequired;

  /// No description provided for @writeNotes.
  ///
  /// In en, this message translates to:
  /// **'Write some notes ...'**
  String get writeNotes;

  /// No description provided for @pleaseSelectEventDate.
  ///
  /// In en, this message translates to:
  /// **'Please select event date'**
  String get pleaseSelectEventDate;

  /// No description provided for @pleaseSelectEventType.
  ///
  /// In en, this message translates to:
  /// **'Please select event type'**
  String get pleaseSelectEventType;

  /// No description provided for @pleaseEnterEventName.
  ///
  /// In en, this message translates to:
  /// **'Please enter event name'**
  String get pleaseEnterEventName;

  /// No description provided for @eventsRecords.
  ///
  /// In en, this message translates to:
  /// **'Events Records'**
  String get eventsRecords;

  /// No description provided for @noEventsToDisplay.
  ///
  /// In en, this message translates to:
  /// **'No events to display.'**
  String get noEventsToDisplay;

  /// No description provided for @massEvent.
  ///
  /// In en, this message translates to:
  /// **'Mass Event'**
  String get massEvent;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;
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
      <String>['en', 'hi', 'kn', 'ta', 'te'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'kn':
      return AppLocalizationsKn();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
