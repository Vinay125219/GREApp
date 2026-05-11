import 'package:flutter/material.dart';

import '../presentation/admin_dashboard_screen/admin_dashboard_screen.dart';
import '../presentation/admin_students_screen/admin_students_screen.dart';
import '../presentation/admin_content_screen/admin_content_screen.dart';
import '../presentation/admin_analytics_screen/admin_analytics_screen.dart';
import '../presentation/admin_settings_screen/admin_settings_screen.dart';
import '../presentation/admin_bulk_upload_screen/admin_bulk_upload_screen.dart';
import '../presentation/admin_integrity_screen/admin_integrity_screen.dart';
import '../presentation/admin_schedule_screen/admin_schedule_screen.dart';
import '../presentation/course_lesson_screen/course_lesson_screen.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/notifications_screen/notifications_screen.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/student_dashboard_screen/student_dashboard_screen.dart';
import '../presentation/student_doubts_screen/student_doubts_screen.dart';
import '../presentation/student_profile_screen/student_profile_screen.dart';
import '../presentation/student_analytics_screen/student_analytics_screen.dart';
import '../presentation/student_drip_content_screen/student_drip_content_screen.dart';
import '../presentation/test_engine_screen/test_engine_screen.dart';
import '../presentation/test_result_screen/test_result_screen.dart';
import '../presentation/admin_reporting_screen/admin_reporting_screen.dart';
import '../presentation/pdf_viewer_screen/pdf_viewer_screen.dart';
import '../presentation/admin_doubt_reply_screen/admin_doubt_reply_screen.dart';
import '../presentation/admin_doubts_screen/admin_doubts_screen.dart';
import '../presentation/student_doubt_thread_screen/student_doubt_thread_screen.dart';
import '../presentation/test_review_screen/test_review_screen.dart';
import '../presentation/admin_add_student_screen/admin_add_student_screen.dart';
import '../presentation/student_courses_screen/student_courses_screen.dart';
import '../presentation/student_tests_screen/student_tests_screen.dart';

class AppRoutes {
  static const String initial = '/';
  static const String splashScreen = '/splash-screen';
  static const String loginScreen = '/login-screen';
  static const String studentDashboardScreen = '/student-dashboard-screen';
  static const String adminDashboardScreen = '/admin-dashboard-screen';
  static const String courseLessonScreen = '/course-lesson-screen';
  static const String testEngineScreen = '/test-engine-screen';
  static const String testResultScreen = '/test-result-screen';
  static const String studentProfileScreen = '/student-profile-screen';
  static const String studentDoubtsScreen = '/student-doubts-screen';
  static const String notificationsScreen = '/notifications-screen';
  static const String adminStudentsScreen = '/admin-students-screen';
  static const String adminContentScreen = '/admin-content-screen';
  static const String adminAnalyticsScreen = '/admin-analytics-screen';
  static const String adminSettingsScreen = '/admin-settings-screen';
  static const String adminBulkUploadScreen = '/admin-bulk-upload-screen';
  static const String studentAnalyticsScreen = '/student-analytics-screen';
  static const String adminIntegrityScreen = '/admin-integrity-screen';
  static const String adminScheduleScreen = '/admin-schedule-screen';
  static const String studentDripContentScreen = '/student-drip-content-screen';
  static const String adminReportingScreen = '/admin-reporting-screen';
  static const String pdfViewerScreen = '/pdf-viewer-screen';
  static const String adminDoubtReplyScreen = '/admin-doubt-reply-screen';
  static const String adminDoubtsScreen = '/admin-doubts-screen';
  static const String studentDoubtThreadScreen = '/student-doubt-thread-screen';
  static const String testReviewScreen = '/test-review-screen';
  static const String adminAddStudentScreen = '/admin-add-student-screen';
  static const String studentCoursesScreen = '/student-courses-screen';
  static const String studentTestsScreen = '/student-tests-screen';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    splashScreen: (context) => const SplashScreen(),
    loginScreen: (context) => const LoginScreen(),
    studentDashboardScreen: (context) => const StudentDashboardScreen(),
    adminDashboardScreen: (context) => const AdminDashboardScreen(),
    courseLessonScreen: (context) => const CourseLessonScreen(),
    testEngineScreen: (context) => const TestEngineScreen(),
    testResultScreen: (context) => const TestResultScreen(),
    studentProfileScreen: (context) => const StudentProfileScreen(),
    studentDoubtsScreen: (context) => const StudentDoubtsScreen(),
    notificationsScreen: (context) => const NotificationsScreen(),
    adminStudentsScreen: (context) => const AdminStudentsScreen(),
    adminContentScreen: (context) => const AdminContentScreen(),
    adminAnalyticsScreen: (context) => const AdminAnalyticsScreen(),
    adminSettingsScreen: (context) => const AdminSettingsScreen(),
    adminBulkUploadScreen: (context) => const AdminBulkUploadScreen(),
    studentAnalyticsScreen: (context) => const StudentAnalyticsScreen(),
    adminIntegrityScreen: (context) => const AdminIntegrityScreen(),
    adminScheduleScreen: (context) => const AdminScheduleScreen(),
    studentDripContentScreen: (context) => const StudentDripContentScreen(),
    adminReportingScreen: (context) => const AdminReportingScreen(),
    pdfViewerScreen: (context) => const PdfViewerScreen(),
    adminDoubtReplyScreen: (context) => const AdminDoubtReplyScreen(),
    adminDoubtsScreen: (context) => const AdminDoubtsScreen(),
    studentDoubtThreadScreen: (context) => const StudentDoubtThreadScreen(),
    testReviewScreen: (context) => const TestReviewScreen(),
    adminAddStudentScreen: (context) => const AdminAddStudentScreen(),
    studentCoursesScreen: (context) => const StudentCoursesScreen(),
    studentTestsScreen: (context) => const StudentTestsScreen(),
  };
}
