// Define the routes used in the app
// TODO: When authentication is added, will probably have to change routes in order to decide if user is logged in or not
import 'package:go_router/go_router.dart';
import 'routes.dart';

// View imports
import 'package:translify/views/Authentication_Views/login_view.dart';
import 'package:translify/views/Authentication_Views/sign_up_view.dart';
import 'package:translify/views/Authentication_Views/after_new_user_view.dart';
import 'package:translify/views/Home_View/home_view.dart';
import 'package:translify/views/Conversation_Translation_Views/conversation_translation_view.dart';
import 'package:translify/views/Camera_Translation_Views/camera_permissions_view.dart';
import 'package:translify/views/Camera_Translation_Views/initial_camera_view.dart';
import 'package:translify/views/Camera_Translation_Views/after_picture_taken_view.dart';

final GoRouter router = GoRouter(
  routes: [
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginView(),
    ),
    GoRoute(
      path: AppRoutes.signUp,
      builder: (context, state) => const SignUpView(),
    ),
    GoRoute(
      path: AppRoutes.afterNewUser,
      builder: (context, state) => const AfterNewUserView(),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomeView(),
    ),
    GoRoute(
      path: AppRoutes.conversation,
      builder: (context, state) => const ConversationTranslationView(),
    ),
    GoRoute(
      path: AppRoutes.cameraPermission,
      builder: (context, state) => const CameraPermissionsView(),
    ),
    GoRoute(
      path: AppRoutes.initialCamera,
      builder: (context, state) => const InitialCameraTranslationView(),
    ),
    GoRoute(
      path: AppRoutes.afterCamera,
      builder: (context, state) {
        final source = state.pathParameters["sourceLang"]!;
        final target = state.pathParameters["targetLang"]!;
        final String path = state.extra as String;

        return AfterPictureTakenView(
          imagePath: path,
          initialSourceLanguage: source,
          initialTargetLanguage: target,
        );
      },
    ),
  ],
  initialLocation: AppRoutes.login,
);
