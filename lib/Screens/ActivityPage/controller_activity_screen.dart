import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ActivityController extends GetxController {
  RxBool isOn = false.obs;

  toggle() {
    isOn.value = !isOn.value;
  }

  final List<String> recentActivity = [
    "You matched with 3 new people this week",
    "Your profile popularity increased by 27%",
    "Complete your profile to get more matches",
  ];

  final RxList<ActivityItem> activityList = <ActivityItem>[
    ActivityItem(
      message: "liked your profile",
      time: "5 min ago",
      icon: Icons.favorite_outlined,
    ),
    ActivityItem(
      message: "New message from Daniel",
      time: "20 min ago",
      icon: Icons.chat_bubble_rounded,
    ),
    ActivityItem(
      message: "You got a new match with Emma!",
      time: "1 hour ago",
      icon: Icons.star_rounded,
    ),
    ActivityItem(
      message: "12 people viewed your profile today",
      time: "3 hours ago",
      icon: Icons.remove_red_eye,
    ),
  ].obs;
}

class ActivityItem {
  final String message;
  final String time;
  final IconData icon;

  ActivityItem({required this.message, required this.time, required this.icon});
}
