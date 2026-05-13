import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../../core/theme/app_colors.dart';

class GuidedTour {
  static void show({
    required BuildContext context,
    required GlobalKey sosKey,
    required GlobalKey mapKey,
    required GlobalKey newsTabKey,
    required GlobalKey postButtonKey,
    required GlobalKey chatTabKey,
    required GlobalKey chatSearchKey,
    required GlobalKey profileTabKey,
    required GlobalKey bellIconKey,
    required VoidCallback onComplete,
  }) {
    final targets = [
      _buildTarget(
        sosKey,
        'SOS Button',
        'This is your panic button. Hold for 3 seconds to trigger emergency dispatch.',
        ContentAlign.top,
      ),
      _buildTarget(
        mapKey,
        'Home Map',
        'Your live location. Nearby alerts appear as pins.',
        ContentAlign.bottom,
      ),
      _buildTarget(
        newsTabKey,
        'News Tab',
        'Community updates and missing person reports from your area.',
        ContentAlign.top,
      ),
      _buildTarget(
        postButtonKey,
        'News Post Button',
        'Post an update or a missing person report here.',
        ContentAlign.top,
      ),
      _buildTarget(
        chatTabKey,
        'Chat Tab',
        'Your community group and direct messages.',
        ContentAlign.top,
      ),
      _buildTarget(
        chatSearchKey,
        'Chat Search',
        'Search for other Havenly users by name.',
        ContentAlign.bottom,
      ),
      _buildTarget(
        profileTabKey,
        'Profile Tab',
        'Manage your account, emergency contacts, and PIN here.',
        ContentAlign.top,
      ),
      _buildTarget(
        bellIconKey,
        'Bell Icon',
        'Alerts and notifications from your community.',
        ContentAlign.bottom,
      ),
    ];

    TutorialCoachMark(
      targets: targets,
      colorShadow: AppColors.brandDeep,
      textSkip: "Skip Tour",
      paddingFocus: 10,
      opacityShadow: 0.8,
      onFinish: onComplete,
      onSkip: () {
        onComplete();
        return true;
      },
    ).show(context: context);
  }

  static TargetFocus _buildTarget(
    GlobalKey key,
    String title,
    String body,
    ContentAlign align,
  ) {
    return TargetFocus(
      identify: title,
      keyTarget: key,
      contents: [
        TargetContent(
          align: align,
          builder: (context, controller) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Text(
                    body,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
