import 'package:connectapp/view/userSelfProfile/widgets/comment_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import '../../../data/response/status.dart';
import '../../../res/fonts/app_fonts.dart';
import '../../../res/routes/routes_name.dart';
import '../../../view_models/controller/follow/user_follow_controller.dart';
import '../../../view_models/controller/getClipByid/clip_play_controller.dart';
import '../../../view_models/controller/getClipByid/get_clip_by_id_controller.dart';
import '../../../view_models/controller/repostClips/repost_clip_controller.dart';

class ClipPlayScreen extends StatelessWidget {
  const ClipPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final clipByIdController = Get.put(GetClipByIdController());
    final ClipPlayController controller = Get.put(ClipPlayController());
    final repostController = Get.find<RepostClipController>();
    final followController = Get.put(FollowUnfollowController());

    return WillPopScope(
      onWillPop: () async {
        controller.pauseVideo(); // Pause video when navigating back
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent, // make AppBar transparent
          elevation: 0, // remove shadow
          automaticallyImplyLeading: false,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(30),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2), // translucent circle
                ),
                padding: const EdgeInsets.all(6),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        body: Obx(() {
          switch (clipByIdController.rxRequestStatus.value) {
            case Status.LOADING:
              return const Center(
                  child: CircularProgressIndicator(color: Colors.white));
            case Status.ERROR:
              return Center(
                  child: Text(clipByIdController.error.value,
                      style: const TextStyle(color: Colors.red)));
            case Status.COMPLETED:
              final clip = clipByIdController.clipData.value!;
              if (controller.videoPlayerController.value == null &&
                  clip.processedUrl != null) {
                controller.initPlayer(clip.processedUrl!);
              }

              return Stack(
                children: [
                  Center(
                    child: controller.chewieController.value != null &&
                            controller.videoPlayerController.value!.value
                                .isInitialized
                        ? Chewie(controller: controller.chewieController.value!)
                        : const CircularProgressIndicator(color: Colors.white),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 10,
                    right: 70,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            InkWell(
                              onTap: () {
                                controller
                                    .pauseVideo(); // Pause video before navigating
                                Get.toNamed(
                                  RouteName.clipProfieScreen,
                                  arguments: clip.userId!.sId.toString(),
                                );
                              },
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.grey.shade200,
                                child: ClipOval(
                                  child: Image.network(
                                    clip.userId?.avatar?.imageUrl ?? "",
                                    fit: BoxFit.cover,
                                    width: 40,
                                    height: 40,
                                    errorBuilder: (context, error, stackTrace) {
                                      // 👇 show default image or icon when error occurs
                                      return Image.network(
                                        "https://i.pravatar.cc/150?img=3",
                                        fit: BoxFit.cover,
                                        width: 40,
                                        height: 40,
                                      );
                                      // OR, if you want to show a Flutter icon instead:
                                      // return Icon(Icons.person, size: 24, color: Colors.grey);
                                    },
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      "@${clip.userId?.username ?? "unknown"}",
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 6),
                                    // Container(
                                    //   padding: const EdgeInsets.symmetric(
                                    //       horizontal: 8, vertical: 2),
                                    //   decoration: BoxDecoration(
                                    //     color: Colors.pinkAccent,
                                    //     borderRadius: BorderRadius.circular(12),
                                    //   ),
                                    //   child: const Text(
                                    //     "Follow",
                                    //     style: TextStyle(
                                    //         color: Colors.white, fontSize: 12),
                                    //   ),
                                    // ),

                                    Obx(() {
                                      final userId =
                                          clip.userId!.sId.toString();
                                      final following =
                                          followController.isFollowing(userId);

                                      return GestureDetector(
                                        onTap: () {
                                          if (following) {
                                            followController
                                                .unfollowUser(userId);
                                          } else {
                                            followController.followUser(userId);
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: following
                                                ? Colors.grey
                                                : Colors.pinkAccent,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            following ? "Following" : "Follow",
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12),
                                          ),
                                        ),
                                      );
                                    })
                                  ],
                                ),
                                const SizedBox(height: 3),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          clip.tags?.join(" ") ?? "",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontFamily: AppFonts.opensansRegular,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 100,
                    right: 10,
                    child: Column(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.black.withOpacity(0.3),
                          radius: 20,
                          child: IconButton(
                            icon: Icon(
                              Icons.favorite,
                              color: clip.isLiked == true
                                  ? Colors.red
                                  : Colors.white,
                              size: 25,
                            ),
                            onPressed: () => controller.toggleLike(clip.sId!),
                          ),
                        ),
                        Text(
                          clip.likeCount?.toString() ?? "0",
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 15),
                        CircleAvatar(
                          backgroundColor: Colors.black.withOpacity(0.3),
                          radius: 25,
                          child: IconButton(
                            icon: const Icon(Icons.comment,
                                color: Colors.white, size: 25),
                            onPressed: () {
                              Get.bottomSheet(
                                CommentsBottomSheet(
                                    clipId: clip.sId.toString()),
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                              );
                            },
                          ),
                        ),
                        Text(
                          clip.commentCount?.toString() ?? "0",
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 15),
                        GestureDetector(
                          onTap: () => repostController
                              .toggleRepostClip(clip.sId.toString()),
                          child: AnimatedScale(
                            scale: 1.0,
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.fastLinearToSlowEaseIn,
                            child: CircleAvatar(
                              radius: 25,
                              backgroundColor: Colors.black.withOpacity(0.3),
                              child: Icon(
                                Icons.repeat,
                                color: clip.isReposted == true
                                    ? Colors.green
                                    : Colors.white,
                                size: 25,
                              ),
                            ),
                          ),
                        ),
                        // const SizedBox(height: 15),
                        // CircleAvatar(
                        //   backgroundColor: Colors.black.withOpacity(0.3),
                        //   radius: 25,
                        //   child: IconButton(
                        //     icon: const Icon(Icons.send,
                        //         color: Colors.white, size: 25),
                        //     onPressed: () {
                        //       // TODO: implement share
                        //       Utils.toastMessageCenter('It Will Work Later');
                        //     },
                        //   ),
                        // ),
                        // const SizedBox(height: 15),
                        // CircleAvatar(
                        //   backgroundColor: Colors.black.withOpacity(0.3),
                        //   radius: 25,
                        //   child: IconButton(
                        //     icon: const Icon(Icons.more_vert,
                        //         color: Colors.white, size: 25),
                        //     onPressed: () {
                        //       // TODO: show more options
                        //     },
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ],
              );
          }
        }),
      ),
    );
  }
}

// Instagram-like custom controls
class InstagramControls extends StatelessWidget {
  const InstagramControls({super.key});

  @override
  Widget build(BuildContext context) {
    final ClipPlayController controller = Get.put(ClipPlayController());
    final chewieController = ChewieController.of(context);
    final videoController = chewieController.videoPlayerController;
    Get.put(GetClipByIdController());

    return GestureDetector(
      onTap: controller.togglePlayPause,
      child: Stack(
        children: [
          Center(
            child: videoController.value.isPlaying
                ? const SizedBox.shrink()
                : const Icon(Icons.play_circle_fill,
                    color: Colors.white70, size: 70),
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              IconButton(
                icon: Obx(() => Icon(
                      controller.isMuted.value
                          ? Icons.volume_off
                          : Icons.volume_up,
                      color: Colors.white,
                    )),
                onPressed: controller.toggleMute,
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 1,
            right: 1,
            child: Column(
              children: [
                VideoProgressIndicator(
                  videoController,
                  allowScrubbing: true,
                  padding: EdgeInsets.zero,
                  colors: const VideoProgressColors(
                    playedColor: Colors.white,
                    backgroundColor: Colors.white24,
                    bufferedColor: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
