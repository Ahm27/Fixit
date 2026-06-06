import 'package:flutter/material.dart';

import '../models/account_role.dart';

enum AppLanguage { english, arabic }

extension AppLanguageX on AppLanguage {
  Locale get locale =>
      this == AppLanguage.arabic ? const Locale('ar') : const Locale('en');

  bool get isArabic => this == AppLanguage.arabic;

  String get nativeLabel => this == AppLanguage.arabic ? 'العربية' : 'English';
}

class AppStrings {
  const AppStrings(this.language);

  final AppLanguage language;

  bool get isArabic => language.isArabic;

  String get appName => isArabic ? 'فكس إت' : 'FixIt';
  String get welcomeTitle =>
      isArabic ? 'مرحبا بك في فكس إت' : 'Welcome to FixIt';
  String get welcomeSubtitle => isArabic
      ? 'اختر كيف تريد المتابعة وسننقلك إلى التجربة المناسبة.'
      : 'Choose how you want to continue and we will take you to the right experience.';
  String get homeServicesMarketplace =>
      isArabic ? 'منصة خدمات منزلية' : 'Home Services Marketplace';
  String helloFirstName(String? name) {
    final value = (name ?? '').trim();
    final first = value.isEmpty
        ? (isArabic ? 'هناك' : 'there')
        : value.split(' ').first;
    return isArabic ? 'مرحبًا، $first' : 'Hello, $first';
  }

  String get continueAsCustomer =>
      isArabic ? 'المتابعة كعميل' : 'Continue as Customer';
  String get continueAsWorker =>
      isArabic ? 'المتابعة كعامل' : 'Continue as Worker';
  String get continueWithGoogle =>
      isArabic ? 'المتابعة عبر جوجل' : 'Continue with Google';
  String get authTitle =>
      isArabic ? 'الدخول باستخدام جوجل' : 'Continue with Google';
  String authSubtitle(AccountRole role) {
    if (isArabic) {
      return role == AccountRole.worker
          ? 'سجّل الدخول بجوجل للمتابعة كعامل. إذا كانت هذه أول مرة، سنطلب بيانات العمل الأساسية بعد ذلك.'
          : 'سجّل الدخول بجوجل للمتابعة كعميل. إذا كانت هذه أول مرة، سنطلب بياناتك الأساسية بعد ذلك.';
    }
    return role == AccountRole.worker
        ? 'Sign in with Google to continue as a worker. If this is your first time, we will ask for your work details next.'
        : 'Sign in with Google to continue as a customer. If this is your first time, we will ask for your required details next.';
  }

  String get authHint => isArabic
      ? 'سيذهب المستخدمون الحاليون مباشرة إلى التطبيق. أما الحسابات الجديدة فستُكمل البيانات المطلوبة بعد تسجيل الدخول بجوجل.'
      : 'Returning users will go straight into the app. New users will complete the required profile fields after Google sign-in.';

  String get completeProfileTitle =>
      isArabic ? 'أكمل ملفك الشخصي' : 'Complete your profile';
  String get almostThere => isArabic ? 'باقي خطوة' : 'Almost there';
  String get finishSetup => isArabic ? 'إتمام الإعداد' : 'Finish setup';
  String get fullName => isArabic ? 'الاسم الكامل' : 'Full name';
  String get phoneNumber => isArabic ? 'رقم الهاتف' : 'Phone number';
  String get city => isArabic ? 'المدينة' : 'City';
  String get serviceCategory => isArabic ? 'نوع الخدمة' : 'Service category';
  String get yearsExperience =>
      isArabic ? 'سنوات الخبرة' : 'Years of experience';
  String get nationalId => isArabic ? 'الرقم القومي' : 'National ID';
  String get hourlyRate =>
      isArabic ? 'السعر بالساعة (ج.م)' : 'Hourly rate (EGP)';
  String get shortBio => isArabic ? 'نبذة قصيرة' : 'Short bio';
  String get validNumbersMessage => isArabic
      ? 'أدخل أرقامًا صحيحة للخبرة والسعر بالساعة.'
      : 'Enter valid numbers for experience and hourly rate.';
  String requiredField(String label) =>
      isArabic ? 'حقل $label مطلوب' : '$label is required';

  String get profile => isArabic ? 'الملف الشخصي' : 'Profile';
  String get editProfile => isArabic ? 'تعديل الملف الشخصي' : 'Edit profile';
  String get reportBug => isArabic ? 'الإبلاغ عن مشكلة' : 'Report a bug';
  String get openSupportTicket =>
      isArabic ? 'فتح تذكرة دعم' : 'Open support ticket';
  String get supportSubtitle => isArabic
      ? 'أرسل شكوى أو استفسارًا أو بلاغًا وسيقوم فريقنا بالمتابعة.'
      : 'Send a complaint, question, or issue and our team will follow up.';
  String get languageLabel => isArabic ? 'اللغة' : 'Language';
  String get english => isArabic ? 'الإنجليزية' : 'English';
  String get arabic => isArabic ? 'العربية' : 'Arabic';
  String get saveChanges => isArabic ? 'حفظ التغييرات' : 'Save changes';
  String get cancel => isArabic ? 'إلغاء' : 'Cancel';
  String get subject => isArabic ? 'العنوان' : 'Subject';
  String get message => isArabic ? 'الرسالة' : 'Message';
  String get bugSubjectHint => isArabic
      ? 'مثال: الرسائل لا تتحدث'
      : 'Example: Messages are not updating';
  String get supportSubjectHint =>
      isArabic ? 'كيف يمكننا مساعدتك؟' : 'How can we help you?';
  String get describeIssue => isArabic
      ? 'اشرح المشكلة أو الاستفسار بالتفصيل'
      : 'Describe the issue or inquiry in detail';
  String get submit => isArabic ? 'إرسال' : 'Submit';
  String get supportSent => isArabic
      ? 'تم إرسال طلبك إلى الدعم.'
      : 'Your request was sent to support.';
  String get supportSendFailed => isArabic
      ? 'تعذر إرسال الطلب. حاول مرة أخرى.'
      : 'Could not send the request. Please try again.';
  String get signOut => isArabic ? 'تسجيل الخروج' : 'Sign out';
  String get customerRole => isArabic ? 'عميل' : 'Customer';
  String get workerRole => isArabic ? 'عامل' : 'Worker';
  String get availability => isArabic ? 'التوفر' : 'Availability';
  String get available => isArabic ? 'متاح' : 'Available';
  String get offline => isArabic ? 'غير متاح' : 'Offline';
  String get uploadPhoto => isArabic ? 'رفع صورة' : 'Upload photo';
  String get manageAccount => isArabic ? 'إدارة الحساب' : 'Manage account';
  String get support => isArabic ? 'الدعم' : 'Support';
  String get home => isArabic ? 'الرئيسية' : 'Home';
  String get bookings => isArabic ? 'الحجوزات' : 'Bookings';
  String get messages => isArabic ? 'الرسائل' : 'Messages';
  String get requests => isArabic ? 'الطلبات' : 'Requests';
  String get earnings => isArabic ? 'الأرباح' : 'Earnings';
  String get refresh => isArabic ? 'تحديث' : 'Refresh';
  String get bookService => isArabic ? 'احجز خدمة' : 'Book service';
  String get back => isArabic ? 'رجوع' : 'Back';
  String get continueLabel => isArabic ? 'متابعة' : 'Continue';
  String get submitRequest => isArabic ? 'إرسال الطلب' : 'Submit request';
  String get chooseService => isArabic ? 'اختر الخدمة' : 'Choose service';
  String get chooseServiceSubtitle => isArabic
      ? 'ابدأ بنوع الخدمة وأخبرنا بما يحتاج إلى إصلاح.'
      : 'Start with the service type and tell us what needs attention.';
  String get serviceTitle => isArabic ? 'عنوان الخدمة' : 'Service title';
  String get describeProblem =>
      isArabic ? 'اشرح المشكلة' : 'Describe the problem';
  String get addDetails => isArabic ? 'أضف التفاصيل' : 'Add details';
  String get addDetailsSubtitle => isArabic
      ? 'حدد الوقت والموقع والميزانية، ويمكنك إضافة صورة مرجعية.'
      : 'Set the time, location, budget, and optionally attach a reference photo.';
  String get address => isArabic ? 'العنوان' : 'Address';
  String get estimatedBudget =>
      isArabic ? 'الميزانية التقديرية (ج.م)' : 'Estimated budget (EGP)';
  String get uploadImage => isArabic ? 'ارفع صورة' : 'Upload an image';
  String get chooseWorker => isArabic ? 'اختر العامل' : 'Choose a worker';
  String get chooseWorkerSubtitle => isArabic
      ? 'اختر فنيًا مباشرة أو اتركه للمطابقة التلقائية.'
      : 'Pick a technician directly or leave it open for automatic matching.';
  String get autoMatchLater =>
      isArabic ? 'دع التطبيق يطابقني لاحقًا' : 'Auto match me later';
  String get noWorkersAvailableAutoMatch => isArabic
      ? 'لا يوجد عمّال متاحون حاليًا في هذه الفئة. ما زال بإمكانك المتابعة مع المطابقة التلقائية.'
      : 'No workers are currently available in this category. You can still continue with auto matching.';
  String get verified => isArabic ? 'موثّق' : 'Verified';
  String yearsExperienceValue(int years) =>
      isArabic ? '$years سنوات خبرة' : '$years years experience';
  String jobsCountValue(int jobs) => isArabic ? '$jobs مهمة' : '$jobs jobs';
  String pricePerHour(double rate) => isArabic
      ? '${rate.toStringAsFixed(0)} ج.م/ساعة'
      : 'EGP ${rate.toStringAsFixed(0)}/hr';
  String get reviewBooking => isArabic ? 'راجع الحجز' : 'Review booking';
  String get reviewBookingSubtitle => isArabic
      ? 'أكد تفاصيل الخدمة قبل إرسال الطلب.'
      : 'Confirm the service details before sending the request.';
  String get category => isArabic ? 'الفئة' : 'Category';
  String get service => isArabic ? 'الخدمة' : 'Service';
  String get description => isArabic ? 'الوصف' : 'Description';
  String get preferredTime => isArabic ? 'الوقت المفضل' : 'Preferred time';
  String get budget => isArabic ? 'الميزانية' : 'Budget';
  String get worker => isArabic ? 'العامل' : 'Worker';
  String get noAvailableWorkersAtMoment => isArabic
      ? 'لا يوجد عمّال متاحون حاليًا'
      : 'No Available Workers at this moment';
  String get customerAttachmentAdded =>
      isArabic ? 'تمت إضافة مرفق العميل' : 'Customer attachment added';
  String get serviceChat => isArabic ? 'محادثة الخدمة' : 'Service chat';
  String get typeMessage => isArabic ? 'اكتب رسالة...' : 'Type a message...';
  String get notifications => isArabic ? 'الإشعارات' : 'Notifications';
  String get noNotificationsYet =>
      isArabic ? 'لا توجد إشعارات بعد' : 'No notifications yet';
  String get requestNotFound =>
      isArabic ? 'الطلب غير موجود' : 'Request not found';
  String get requestDetails => isArabic ? 'تفاصيل الطلب' : 'Request details';
  String workerName(String name) =>
      isArabic ? 'العامل: $name' : 'Worker: $name';
  String get attachmentUnavailable =>
      isArabic ? 'المرفق غير متاح' : 'Attachment unavailable';
  String get serviceStatus => isArabic ? 'حالة الخدمة' : 'Service status';
  String get requestSubmitted =>
      isArabic ? 'تم إرسال الطلب' : 'Request Submitted';
  String get technicianAssigned =>
      isArabic ? 'تم تعيين الفني' : 'Technician Assigned';
  String get inProgress => isArabic ? 'جارٍ التنفيذ' : 'In Progress';
  String get completed => isArabic ? 'مكتمل' : 'Completed';
  String get openChat => isArabic ? 'فتح المحادثة' : 'Open chat';
  String get demoModeBanner => isArabic
      ? 'تعذر الوصول إلى Supabase، لذا يعمل التطبيق في الوضع التجريبي.'
      : 'Supabase could not be reached, so the app is running in demo mode.';
  String helloName(String name) => isArabic ? 'مرحبًا، $name' : 'Hello, $name';
  String get whatServiceNeed =>
      isArabic ? 'ما الخدمة\nالتي تحتاجها؟' : 'What service\ndo you need?';
  String get homeHeroSubtitle => isArabic
      ? 'اختر خدمة، وقارن بين العمّال، وارفع الصور، وتابع حالة الطلب مباشرة.'
      : 'Choose a service, compare workers, upload photos, and track the job live.';
  String get startBooking => isArabic ? 'ابدأ حجزًا' : 'Start a booking';
  String get serviceCategoriesTitle =>
      isArabic ? 'فئات الخدمات' : 'Service categories';
  String get recentBookings => isArabic ? 'أحدث الحجوزات' : 'Recent bookings';
  String get firstBookingHint => isArabic
      ? 'ستظهر حجوزاتك هنا بعد إنشاء أول طلب.'
      : 'Your bookings will appear here after you create your first request.';
  String get active => isArabic ? 'نشطة' : 'Active';
  String get history => isArabic ? 'السجل' : 'History';
  String get noBookingsSection => isArabic
      ? 'لا توجد حجوزات في هذا القسم بعد.'
      : 'No bookings in this section yet.';
  String get noConversationsYet =>
      isArabic ? 'لا توجد محادثات بعد.' : 'No conversations yet.';
  String assignedTo(String name) =>
      isArabic ? 'تم إسناده إلى $name' : 'Assigned to $name';
  String get attachmentAdded =>
      isArabic ? 'تمت إضافة مرفق' : 'Attachment added';
  String get invalidBookingFields => isArabic
      ? 'أكمل الحقول المطلوبة وأدخل ميزانية صحيحة.'
      : 'Complete the required fields and enter a valid budget.';
  String currency(double amount) => isArabic
      ? '${amount.toStringAsFixed(0)} ج.م'
      : 'EGP ${amount.toStringAsFixed(0)}';
  String get general => isArabic ? 'عام' : 'General';
  String get workerControlRoom =>
      isArabic ? 'لوحة تحكم العامل' : 'Worker control room';
  String get workerControlRoomSubtitle => isArabic
      ? 'اقبل الطلبات القريبة، وحرّك المهام عبر المراحل، وأبقِ العملاء على اطلاع.'
      : 'Accept nearby requests, move jobs through progress, and keep customers updated.';
  String get noRequestsSection => isArabic
      ? 'لا توجد طلبات في هذا القسم الآن.'
      : 'No requests in this section right now.';
  String get chat => isArabic ? 'محادثة' : 'Chat';
  String get acceptJob => isArabic ? 'قبول الطلب' : 'Accept job';
  String get startWork => isArabic ? 'بدء العمل' : 'Start work';
  String get markComplete => isArabic ? 'تحديد كمكتمل' : 'Mark complete';
  String get cancelled => isArabic ? 'ملغي' : 'Cancelled';
  String get today => isArabic ? 'اليوم' : 'Today';
  String get thisWeek => isArabic ? 'هذا الأسبوع' : 'This week';
  String get thisMonth => isArabic ? 'هذا الشهر' : 'This month';
  String get availableBalance => isArabic ? 'المتاح' : 'Available';
  String get performance => isArabic ? 'الأداء' : 'Performance';
  String performanceSummary(int jobs, double avg) => isArabic
      ? '$jobs مهام مكتملة - متوسط التذكرة ${avg.toStringAsFixed(0)} ج.م'
      : '$jobs jobs completed - average ticket EGP ${avg.toStringAsFixed(0)}';
  String get completedJobsTitle =>
      isArabic ? 'المهام المكتملة' : 'Completed jobs';
  String get completedJobsHint => isArabic
      ? 'ستظهر المهام المكتملة هنا عند إنهاء الطلبات.'
      : 'Completed jobs will show here as you finish requests.';
  String get workerFallback => isArabic ? 'عامل' : 'Worker';
  String requestBucketLabel(String key) {
    switch (key) {
      case 'new':
        return isArabic ? 'جديد' : 'New';
      case 'active':
        return active;
      case 'done':
        return isArabic ? 'منتهية' : 'Done';
      default:
        return key;
    }
  }

  String serviceCategoryName(String category) {
    switch (category) {
      case 'Plumbing':
        return isArabic ? 'سباكة' : category;
      case 'Electrical':
        return isArabic ? 'كهرباء' : category;
      case 'AC Repair':
        return isArabic ? 'تكييف' : category;
      case 'Painting':
        return isArabic ? 'دهانات' : category;
      case 'Carpentry':
        return isArabic ? 'نجارة' : category;
      case 'Appliance Repair':
        return isArabic ? 'إصلاح الأجهزة' : category;
      default:
        return category;
    }
  }

  String serviceDescription(String category) {
    switch (category) {
      case 'Plumbing':
        return isArabic
            ? 'إصلاح التسريبات، وتركيب الحنفيات، والسخانات، والطوارئ'
            : 'Leak repair, faucet installs, heaters, and emergencies';
      case 'Electrical':
        return isArabic
            ? 'التمديدات، والمخارج، والمفاتيح، ومشكلات الإضاءة'
            : 'Wiring, outlets, switches, and lighting issues';
      case 'Painting':
        return isArabic
            ? 'تجديد الغرف، واللمسات النهائية، وأعمال الطلاء'
            : 'Room refreshes, touch-ups, and repaint work';
      case 'Carpentry':
        return isArabic
            ? 'الأبواب، والخزائن، والأثاث، وإصلاحات الخشب'
            : 'Doors, cabinets, furniture, and wood repairs';
      case 'AC Repair':
        return isArabic
            ? 'مشكلات التبريد، والصيانة، والخدمة'
            : 'Cooling issues, maintenance, and servicing';
      default:
        return isArabic
            ? 'فحص وإصلاح الأجهزة المنزلية'
            : 'Household appliance diagnostics and repairs';
    }
  }

  String requestStatusLabel(String key) {
    switch (key) {
      case 'pending':
        return isArabic ? 'قيد الانتظار' : 'Pending';
      case 'accepted':
        return isArabic ? 'تم القبول' : 'Accepted';
      case 'in_progress':
        return inProgress;
      case 'completed':
        return completed;
      case 'cancelled':
        return cancelled;
      default:
        return key;
    }
  }
}
