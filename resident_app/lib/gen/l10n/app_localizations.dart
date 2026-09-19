import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ta.dart';

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
    Locale('ar'),
    Locale('en'),
    Locale('es'),
    Locale('hi'),
    Locale('ta'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Hominode'**
  String get appTitle;

  /// No description provided for @appSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your Community, Connected'**
  String get appSubtitle;

  /// No description provided for @common_home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get common_home;

  /// No description provided for @common_profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get common_profile;

  /// No description provided for @common_settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get common_settings;

  /// No description provided for @common_logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get common_logout;

  /// No description provided for @common_login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get common_login;

  /// No description provided for @common_register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get common_register;

  /// No description provided for @common_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get common_save;

  /// No description provided for @common_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get common_cancel;

  /// No description provided for @common_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get common_delete;

  /// No description provided for @common_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get common_edit;

  /// No description provided for @common_close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get common_close;

  /// No description provided for @common_loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get common_loading;

  /// No description provided for @common_error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get common_error;

  /// No description provided for @common_success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get common_success;

  /// No description provided for @common_warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get common_warning;

  /// No description provided for @common_confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get common_confirm;

  /// No description provided for @common_back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get common_back;

  /// No description provided for @common_next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get common_next;

  /// No description provided for @common_skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get common_skip;

  /// No description provided for @common_done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get common_done;

  /// No description provided for @common_search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get common_search;

  /// No description provided for @common_filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get common_filter;

  /// No description provided for @common_sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get common_sort;

  /// No description provided for @common_view_all.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get common_view_all;

  /// No description provided for @common_no_data.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get common_no_data;

  /// No description provided for @common_try_again.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get common_try_again;

  /// No description provided for @common_language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get common_language;

  /// No description provided for @login_email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get login_email;

  /// No description provided for @login_phone.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get login_phone;

  /// No description provided for @login_password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get login_password;

  /// No description provided for @login_confirm_password.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get login_confirm_password;

  /// No description provided for @login_forgot_password.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get login_forgot_password;

  /// No description provided for @login_sign_in.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get login_sign_in;

  /// No description provided for @login_sign_up.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get login_sign_up;

  /// No description provided for @login_no_account.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get login_no_account;

  /// No description provided for @login_have_account.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get login_have_account;

  /// No description provided for @login_invalid_email.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get login_invalid_email;

  /// No description provided for @login_invalid_phone.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get login_invalid_phone;

  /// No description provided for @login_password_mismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get login_password_mismatch;

  /// No description provided for @login_required_field.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get login_required_field;

  /// No description provided for @home_welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get home_welcome;

  /// No description provided for @home_recent_activity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get home_recent_activity;

  /// No description provided for @home_notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get home_notifications;

  /// No description provided for @home_bookings.
  ///
  /// In en, this message translates to:
  /// **'My Bookings'**
  String get home_bookings;

  /// No description provided for @home_complaints.
  ///
  /// In en, this message translates to:
  /// **'Complaints'**
  String get home_complaints;

  /// No description provided for @home_documents.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get home_documents;

  /// No description provided for @home_billing.
  ///
  /// In en, this message translates to:
  /// **'Billing'**
  String get home_billing;

  /// No description provided for @home_amenities.
  ///
  /// In en, this message translates to:
  /// **'Amenities'**
  String get home_amenities;

  /// No description provided for @home_visitors.
  ///
  /// In en, this message translates to:
  /// **'Visitors'**
  String get home_visitors;

  /// No description provided for @home_messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get home_messages;

  /// No description provided for @home_marketplace.
  ///
  /// In en, this message translates to:
  /// **'Marketplace'**
  String get home_marketplace;

  /// No description provided for @home_community.
  ///
  /// In en, this message translates to:
  /// **'Community Wall'**
  String get home_community;

  /// No description provided for @profile_my_profile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get profile_my_profile;

  /// No description provided for @profile_edit_profile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get profile_edit_profile;

  /// No description provided for @profile_domestic_staff.
  ///
  /// In en, this message translates to:
  /// **'Domestic Staff'**
  String get profile_domestic_staff;

  /// No description provided for @profile_my_bookings.
  ///
  /// In en, this message translates to:
  /// **'My Bookings'**
  String get profile_my_bookings;

  /// No description provided for @profile_documents.
  ///
  /// In en, this message translates to:
  /// **'Documents & Circulars'**
  String get profile_documents;

  /// No description provided for @profile_family_members.
  ///
  /// In en, this message translates to:
  /// **'Family Members'**
  String get profile_family_members;

  /// No description provided for @profile_vehicles.
  ///
  /// In en, this message translates to:
  /// **'Vehicles'**
  String get profile_vehicles;

  /// No description provided for @profile_settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get profile_settings;

  /// No description provided for @profile_about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get profile_about;

  /// No description provided for @profile_help.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get profile_help;

  /// No description provided for @profile_privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get profile_privacy;

  /// No description provided for @profile_terms.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get profile_terms;

  /// No description provided for @notifications_title.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications_title;

  /// No description provided for @notifications_no_notifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get notifications_no_notifications;

  /// No description provided for @notifications_mark_read.
  ///
  /// In en, this message translates to:
  /// **'Mark as Read'**
  String get notifications_mark_read;

  /// No description provided for @notifications_mark_unread.
  ///
  /// In en, this message translates to:
  /// **'Mark as Unread'**
  String get notifications_mark_unread;

  /// No description provided for @notifications_clear_all.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get notifications_clear_all;

  /// No description provided for @bookings_title.
  ///
  /// In en, this message translates to:
  /// **'My Bookings'**
  String get bookings_title;

  /// No description provided for @bookings_upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get bookings_upcoming;

  /// No description provided for @bookings_completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get bookings_completed;

  /// No description provided for @bookings_cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get bookings_cancelled;

  /// No description provided for @bookings_no_bookings.
  ///
  /// In en, this message translates to:
  /// **'No bookings'**
  String get bookings_no_bookings;

  /// No description provided for @bookings_book_now.
  ///
  /// In en, this message translates to:
  /// **'Book Now'**
  String get bookings_book_now;

  /// No description provided for @bookings_cancel_booking.
  ///
  /// In en, this message translates to:
  /// **'Cancel Booking'**
  String get bookings_cancel_booking;

  /// No description provided for @bookings_booking_confirmed.
  ///
  /// In en, this message translates to:
  /// **'Booking Confirmed'**
  String get bookings_booking_confirmed;

  /// No description provided for @bookings_booking_pending.
  ///
  /// In en, this message translates to:
  /// **'Booking Pending'**
  String get bookings_booking_pending;

  /// No description provided for @bookings_booking_cancelled.
  ///
  /// In en, this message translates to:
  /// **'Booking Cancelled'**
  String get bookings_booking_cancelled;

  /// No description provided for @amenities_title.
  ///
  /// In en, this message translates to:
  /// **'Amenities'**
  String get amenities_title;

  /// No description provided for @amenities_available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get amenities_available;

  /// No description provided for @amenities_booked.
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get amenities_booked;

  /// No description provided for @amenities_capacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get amenities_capacity;

  /// No description provided for @amenities_available_slots.
  ///
  /// In en, this message translates to:
  /// **'Available Slots'**
  String get amenities_available_slots;

  /// No description provided for @amenities_book_amenity.
  ///
  /// In en, this message translates to:
  /// **'Book Amenity'**
  String get amenities_book_amenity;

  /// No description provided for @amenities_select_date.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get amenities_select_date;

  /// No description provided for @amenities_select_time.
  ///
  /// In en, this message translates to:
  /// **'Select Time'**
  String get amenities_select_time;

  /// No description provided for @amenities_select_people.
  ///
  /// In en, this message translates to:
  /// **'Number of People'**
  String get amenities_select_people;

  /// No description provided for @amenities_price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get amenities_price;

  /// No description provided for @amenities_total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get amenities_total;

  /// No description provided for @complaints_title.
  ///
  /// In en, this message translates to:
  /// **'Complaints'**
  String get complaints_title;

  /// No description provided for @complaints_new_complaint.
  ///
  /// In en, this message translates to:
  /// **'New Complaint'**
  String get complaints_new_complaint;

  /// No description provided for @complaints_my_complaints.
  ///
  /// In en, this message translates to:
  /// **'My Complaints'**
  String get complaints_my_complaints;

  /// No description provided for @complaints_status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get complaints_status;

  /// No description provided for @complaints_open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get complaints_open;

  /// No description provided for @complaints_in_progress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get complaints_in_progress;

  /// No description provided for @complaints_resolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get complaints_resolved;

  /// No description provided for @complaints_closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get complaints_closed;

  /// No description provided for @complaints_description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get complaints_description;

  /// No description provided for @complaints_category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get complaints_category;

  /// No description provided for @complaints_priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get complaints_priority;

  /// No description provided for @complaints_high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get complaints_high;

  /// No description provided for @complaints_medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get complaints_medium;

  /// No description provided for @complaints_low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get complaints_low;

  /// No description provided for @complaints_submit.
  ///
  /// In en, this message translates to:
  /// **'Submit Complaint'**
  String get complaints_submit;

  /// No description provided for @complaints_submitted.
  ///
  /// In en, this message translates to:
  /// **'Complaint Submitted'**
  String get complaints_submitted;

  /// No description provided for @documents_title.
  ///
  /// In en, this message translates to:
  /// **'Documents & Circulars'**
  String get documents_title;

  /// No description provided for @documents_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get documents_all;

  /// No description provided for @documents_documents.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documents_documents;

  /// No description provided for @documents_circulars.
  ///
  /// In en, this message translates to:
  /// **'Circulars'**
  String get documents_circulars;

  /// No description provided for @documents_published.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get documents_published;

  /// No description provided for @documents_author.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get documents_author;

  /// No description provided for @documents_download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get documents_download;

  /// No description provided for @documents_view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get documents_view;

  /// No description provided for @documents_no_documents.
  ///
  /// In en, this message translates to:
  /// **'No documents'**
  String get documents_no_documents;

  /// No description provided for @billing_title.
  ///
  /// In en, this message translates to:
  /// **'Billing'**
  String get billing_title;

  /// No description provided for @billing_outstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get billing_outstanding;

  /// No description provided for @billing_paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get billing_paid;

  /// No description provided for @billing_pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get billing_pending;

  /// No description provided for @billing_amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get billing_amount;

  /// No description provided for @billing_due_date.
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get billing_due_date;

  /// No description provided for @billing_pay_now.
  ///
  /// In en, this message translates to:
  /// **'Pay Now'**
  String get billing_pay_now;

  /// No description provided for @billing_payment_history.
  ///
  /// In en, this message translates to:
  /// **'Payment History'**
  String get billing_payment_history;

  /// No description provided for @billing_invoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get billing_invoice;

  /// No description provided for @billing_download_invoice.
  ///
  /// In en, this message translates to:
  /// **'Download Invoice'**
  String get billing_download_invoice;

  /// No description provided for @messages_title.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages_title;

  /// No description provided for @messages_new_message.
  ///
  /// In en, this message translates to:
  /// **'New Message'**
  String get messages_new_message;

  /// No description provided for @messages_no_messages.
  ///
  /// In en, this message translates to:
  /// **'No messages'**
  String get messages_no_messages;

  /// No description provided for @messages_type_message.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get messages_type_message;

  /// No description provided for @messages_send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get messages_send;

  /// No description provided for @messages_chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get messages_chat;

  /// No description provided for @messages_admin_chat.
  ///
  /// In en, this message translates to:
  /// **'Admin Chat'**
  String get messages_admin_chat;

  /// No description provided for @messages_flat_members.
  ///
  /// In en, this message translates to:
  /// **'Flat Members'**
  String get messages_flat_members;

  /// No description provided for @messages_building_members.
  ///
  /// In en, this message translates to:
  /// **'Building Members'**
  String get messages_building_members;

  /// No description provided for @marketplace_title.
  ///
  /// In en, this message translates to:
  /// **'Marketplace'**
  String get marketplace_title;

  /// No description provided for @marketplace_buy.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get marketplace_buy;

  /// No description provided for @marketplace_sell.
  ///
  /// In en, this message translates to:
  /// **'Sell'**
  String get marketplace_sell;

  /// No description provided for @marketplace_my_listings.
  ///
  /// In en, this message translates to:
  /// **'My Listings'**
  String get marketplace_my_listings;

  /// No description provided for @marketplace_create_listing.
  ///
  /// In en, this message translates to:
  /// **'Create Listing'**
  String get marketplace_create_listing;

  /// No description provided for @marketplace_price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get marketplace_price;

  /// No description provided for @marketplace_condition.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get marketplace_condition;

  /// No description provided for @marketplace_new.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get marketplace_new;

  /// No description provided for @marketplace_used.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get marketplace_used;

  /// No description provided for @marketplace_contact_seller.
  ///
  /// In en, this message translates to:
  /// **'Contact Seller'**
  String get marketplace_contact_seller;

  /// No description provided for @marketplace_request_phone.
  ///
  /// In en, this message translates to:
  /// **'Request Phone'**
  String get marketplace_request_phone;

  /// No description provided for @community_title.
  ///
  /// In en, this message translates to:
  /// **'Community Wall'**
  String get community_title;

  /// No description provided for @community_create_post.
  ///
  /// In en, this message translates to:
  /// **'Create Post'**
  String get community_create_post;

  /// No description provided for @community_no_posts.
  ///
  /// In en, this message translates to:
  /// **'No posts'**
  String get community_no_posts;

  /// No description provided for @community_like.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get community_like;

  /// No description provided for @community_comment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get community_comment;

  /// No description provided for @community_share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get community_share;

  /// No description provided for @community_delete_post.
  ///
  /// In en, this message translates to:
  /// **'Delete Post'**
  String get community_delete_post;

  /// No description provided for @community_edit_post.
  ///
  /// In en, this message translates to:
  /// **'Edit Post'**
  String get community_edit_post;

  /// No description provided for @visitors_title.
  ///
  /// In en, this message translates to:
  /// **'Visitors'**
  String get visitors_title;

  /// No description provided for @visitors_add_visitor.
  ///
  /// In en, this message translates to:
  /// **'Add Visitor'**
  String get visitors_add_visitor;

  /// No description provided for @visitors_expected.
  ///
  /// In en, this message translates to:
  /// **'Expected'**
  String get visitors_expected;

  /// No description provided for @visitors_departed.
  ///
  /// In en, this message translates to:
  /// **'Departed'**
  String get visitors_departed;

  /// No description provided for @visitors_name.
  ///
  /// In en, this message translates to:
  /// **'Visitor Name'**
  String get visitors_name;

  /// No description provided for @visitors_phone.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get visitors_phone;

  /// No description provided for @visitors_purpose.
  ///
  /// In en, this message translates to:
  /// **'Purpose'**
  String get visitors_purpose;

  /// No description provided for @visitors_date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get visitors_date;

  /// No description provided for @visitors_time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get visitors_time;

  /// No description provided for @visitors_check_in.
  ///
  /// In en, this message translates to:
  /// **'Check In'**
  String get visitors_check_in;

  /// No description provided for @visitors_check_out.
  ///
  /// In en, this message translates to:
  /// **'Check Out'**
  String get visitors_check_out;

  /// No description provided for @settings_title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings_title;

  /// No description provided for @settings_language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settings_language;

  /// No description provided for @settings_notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settings_notifications;

  /// No description provided for @settings_privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settings_privacy;

  /// No description provided for @settings_security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get settings_security;

  /// No description provided for @settings_about.
  ///
  /// In en, this message translates to:
  /// **'About App'**
  String get settings_about;

  /// No description provided for @settings_version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settings_version;

  /// No description provided for @settings_change_password.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get settings_change_password;

  /// No description provided for @settings_two_factor.
  ///
  /// In en, this message translates to:
  /// **'Two-Factor Authentication'**
  String get settings_two_factor;

  /// No description provided for @settings_enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get settings_enable;

  /// No description provided for @settings_disable.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get settings_disable;

  /// No description provided for @errors_network_error.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection.'**
  String get errors_network_error;

  /// No description provided for @errors_server_error.
  ///
  /// In en, this message translates to:
  /// **'Server error. Please try again later.'**
  String get errors_server_error;

  /// No description provided for @errors_unauthorized.
  ///
  /// In en, this message translates to:
  /// **'Unauthorized. Please login again.'**
  String get errors_unauthorized;

  /// No description provided for @errors_not_found.
  ///
  /// In en, this message translates to:
  /// **'Not found.'**
  String get errors_not_found;

  /// No description provided for @errors_something_went_wrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errors_something_went_wrong;

  /// No description provided for @validation_required.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get validation_required;

  /// No description provided for @validation_invalid_email.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get validation_invalid_email;

  /// No description provided for @validation_invalid_phone.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get validation_invalid_phone;

  /// No description provided for @validation_password_short.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get validation_password_short;

  /// No description provided for @validation_password_mismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get validation_password_mismatch;

  /// No description provided for @date_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get date_today;

  /// No description provided for @date_yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get date_yesterday;

  /// No description provided for @date_tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get date_tomorrow;

  /// No description provided for @date_this_week.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get date_this_week;

  /// No description provided for @date_this_month.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get date_this_month;

  /// No description provided for @date_january.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get date_january;

  /// No description provided for @date_february.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get date_february;

  /// No description provided for @date_march.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get date_march;

  /// No description provided for @date_april.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get date_april;

  /// No description provided for @date_may.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get date_may;

  /// No description provided for @date_june.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get date_june;

  /// No description provided for @date_july.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get date_july;

  /// No description provided for @date_august.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get date_august;

  /// No description provided for @date_september.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get date_september;

  /// No description provided for @date_october.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get date_october;

  /// No description provided for @date_november.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get date_november;

  /// No description provided for @date_december.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get date_december;

  /// No description provided for @time_am.
  ///
  /// In en, this message translates to:
  /// **'AM'**
  String get time_am;

  /// No description provided for @time_pm.
  ///
  /// In en, this message translates to:
  /// **'PM'**
  String get time_pm;

  /// No description provided for @time_morning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get time_morning;

  /// No description provided for @time_afternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get time_afternoon;

  /// No description provided for @time_evening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get time_evening;

  /// No description provided for @time_night.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get time_night;
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
      <String>['ar', 'en', 'es', 'hi', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'hi':
      return AppLocalizationsHi();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
