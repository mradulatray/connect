// import 'package:connectapp/res/custom_widgets/custome_appbar.dart';
// import 'package:connectapp/res/custom_widgets/responsive_padding.dart';
// import 'package:connectapp/res/fonts/app_fonts.dart';
// import 'package:connectapp/res/routes/routes_name.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// import '../../res/color/app_colors.dart';
// import '../../res/listitem/list_item.dart';
// class Chat {
//   final String id;
//   final String name;
//   final String? avatar;
//   final String lastMessage;
//   final DateTime timestamp;
//   final int unread;
//   final bool isGroup;
//   final bool? isOnline;
//   final String? senderName;
//   final List<Participant>? participants;

//   Chat({
//     required this.id,
//     required this.name,
//     this.avatar,
//     required this.lastMessage,
//     required this.timestamp,
//     required this.unread,
//     required this.isGroup,
//     this.isOnline,
//     this.senderName,
//     this.participants,
//   });

//   factory Chat.fromJson(Map<String, dynamic> json) {
//     return Chat(
//       id: json['_id'],
//       name: json['name'] ?? '',
//       avatar: json['avatar'] ?? json['groupAvatar'],
//       lastMessage: json['lastMessage'],
//       timestamp: DateTime.parse(json['updatedAt'] ?? json['createdAt']),
//       unread: json['unread'] ?? 0,
//       isGroup: json['isGroup'] ?? false,
//       participants: json['participants'] != null
//           ? (json['participants'] as List)
//               .map((p) => Participant.fromJson(p))
//               .toList()
//           : null,
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       '_id': id,
//       'name': name,
//       'avatar': avatar,
//       'lastMessage': lastMessage,
//       'updatedAt': timestamp.toIso8601String(),
//       'unread': unread,
//       'isGroup': isGroup,
//       'participants': participants?.map((p) => p.toJson()).toList(),
//     };
//   }
// }

// // New Reaction model
// class Reaction {
//   final Sender user;
//   final String emoji;

//   Reaction({
//     required this.user,
//     required this.emoji,
//   });

//   factory Reaction.fromJson(Map<String, dynamic> json) {
//     return Reaction(
//       user: Sender.fromJson(json['user']),
//       emoji: json['emoji'],
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'user': user.toJson(),
//       'emoji': emoji,
//     };
//   }
// }

// // New ReplyTo model
// class ReplyTo {
//   final String id;
//   final String content;
//   final Sender sender;

//   ReplyTo({
//     required this.id,
//     required this.content,
//     required this.sender,
//   });

//   factory ReplyTo.fromJson(Map<String, dynamic> json) {
//     return ReplyTo(
//       id: json['id'],
//       content: json['content'],
//       sender: Sender.fromJson(json['sender']),
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'content': content,
//       'sender': sender.toJson(),
//     };
//   }
// }

// // Updated Message model with reply and reaction support
// class Message {
//   final String id;
//   final String content;
//   final DateTime timestamp;
//   final Sender sender;
//   final bool isRead;
//   final ReplyTo? replyingTo;
//   final List<Reaction>? reactions;

//   Message({
//     required this.id,
//     required this.content,
//     required this.timestamp,
//     required this.sender,
//     required this.isRead,
//     this.replyingTo,
//     this.reactions,
//   });

//   factory Message.fromJson(Map<String, dynamic> json) {
//     return Message(
//       id: json['_id'] ?? json['id'],
//       content: json['content'],
//       timestamp: DateTime.parse(json['createdAt'] ?? json['timestamp']),
//       sender: Sender.fromJson(json['sender']),
//       isRead: json['status'] == 'read' || json['isRead'] == true,
//       replyingTo: json['replyingTo'] != null 
//           ? ReplyTo.fromJson(json['replyingTo']) 
//           : null,
//       reactions: json['reactions'] != null
//           ? (json['reactions'] as List)
//               .map((reaction) => Reaction.fromJson(reaction))
//               .toList()
//           : null,
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       '_id': id,
//       'content': content,
//       'createdAt': timestamp.toIso8601String(),
//       'sender': sender.toJson(),
//       'status': isRead ? 'read' : 'unread',
//       'replyingTo': replyingTo?.toJson(),
//       'reactions': reactions?.map((reaction) => reaction.toJson()).toList(),
//     };
//   }
// }

// // Updated Sender model with toJson method
// class Sender {
//   final String id;
//   final String name;
//   final String? avatar;

//   Sender({
//     required this.id,
//     required this.name,
//     this.avatar,
//   });

//   factory Sender.fromJson(Map<String, dynamic> json) {
//     return Sender(
//       id: json['_id'] ?? json['id'],
//       name: json['fullName'] ?? json['name'],
//       avatar: json['avatar']?['imageUrl'] ?? json['avatar'],
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       '_id': id,
//       'fullName': name,
//       'avatar': avatar,
//     };
//   }
// }

// // Updated Participant model with toJson method
// class Participant {
//   final String id;
//   final String name;
//   final String? avatar;

//   Participant({
//     required this.id,
//     required this.name,
//     this.avatar,
//   });

//   factory Participant.fromJson(Map<String, dynamic> json) {
//     return Participant(
//       id: json['_id'] ?? json['id'],
//       name: json['fullName'] ?? json['name'],
//       avatar: json['avatar']?['imageUrl'] ?? json['avatar'],
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       '_id': id,
//       'fullName': name,
//       'avatar': avatar,
//     };
//   }
// }

// class GroupMember {
//   final UserInfo userId;
//   final String joinedAt;
//   final String id;

//   GroupMember({
//     required this.userId,
//     required this.joinedAt,
//     required this.id,
//   });

//   factory GroupMember.fromJson(Map<String, dynamic> json) {
//     return GroupMember(
//       userId: UserInfo.fromJson(json['userId']),
//       joinedAt: json['joinedAt'],
//       id: json['_id'],
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'userId': userId.toJson(),
//       'joinedAt': joinedAt,
//       '_id': id,
//     };
//   }
// }

// class UserInfo {
//   final String id;
//   final String fullName;
//   final String email;
//   final Avatar? avatar;

//   UserInfo({
//     required this.id,
//     required this.fullName,
//     required this.email,
//     this.avatar,
//   });

//   factory UserInfo.fromJson(Map<String, dynamic> json) {
//     return UserInfo(
//       id: json['_id'],
//       fullName: json['fullName'],
//       email: json['email'],
//       avatar: json['avatar'] != null ? Avatar.fromJson(json['avatar']) : null,
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       '_id': id,
//       'fullName': fullName,
//       'email': email,
//       'avatar': avatar?.toJson(),
//     };
//   }
// }

// class Avatar {
//   final String imageUrl;

//   Avatar({required this.imageUrl});

//   factory Avatar.fromJson(Map<String, dynamic> json) {
//     return Avatar(imageUrl: json['imageUrl']);
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'imageUrl': imageUrl,
//     };
//   }
// }

// class GroupData {
//   final String id;
//   final String name;
//   final List<GroupMember> members;
//   final List<String> admins;
//   final String? groupAvatar;
//   final CreatedBy createdBy;
//   final String createdAt;

//   GroupData({
//     required this.id,
//     required this.name,
//     required this.members,
//     required this.admins,
//     this.groupAvatar,
//     required this.createdBy,
//     required this.createdAt,
//   });

//   factory GroupData.fromJson(Map<String, dynamic> json) {
//     return GroupData(
//       id: json['_id'],
//       name: json['name'],
//       members: (json['members'] as List)
//           .map((m) => GroupMember.fromJson(m))
//           .toList(),
//       admins: List<String>.from(json['admins']),
//       groupAvatar: json['groupAvatar'],
//       createdBy: CreatedBy.fromJson(json['createdBy']),
//       createdAt: json['createdAt'],
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       '_id': id,
//       'name': name,
//       'members': members.map((m) => m.toJson()).toList(),
//       'admins': admins,
//       'groupAvatar': groupAvatar,
//       'createdBy': createdBy.toJson(),
//       'createdAt': createdAt,
//     };
//   }
// }

// class CreatedBy {
//   final String id;
//   final String fullName;

//   CreatedBy({
//     required this.id,
//     required this.fullName,
//   });

//   factory CreatedBy.fromJson(Map<String, dynamic> json) {
//     return CreatedBy(
//       id: json['_id'],
//       fullName: json['fullName'],
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       '_id': id,
//       'fullName': fullName,
//     };
//   }
// }
// // services/socket_service.dart


// class MessageScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: CustomAppBar(
//         automaticallyImplyLeading: true,
//         title: 'All Messages',
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           color: Theme.of(context).scaffoldBackgroundColor,
//         ),
//         child: Column(
//           children: [
//             // Search bar
//             Padding(
//               padding: ResponsivePadding.customPadding(context,
//                   left: 3, right: 3, top: 4, bottom: 3),
//               child: TextField(
//                 decoration: InputDecoration(
//                   hintText: "Search Here",
//                   hintStyle: TextStyle(
//                     color: Theme.of(context).textTheme.bodyLarge?.color,
//                   ),
//                   prefixIcon: Icon(
//                     Icons.search,
//                     color: Theme.of(context).textTheme.bodyLarge?.color,
//                   ),
//                   border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                       borderSide: BorderSide(color: AppColors.whiteColor)),
//                   contentPadding:
//                       EdgeInsets.symmetric(vertical: 0, horizontal: 16),
//                 ),
//               ),
//             ),

//             // Filter Chips
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 12.0),
//               child: Row(
//                 children: [
//                   FilterChipWidget(label: "All", selected: true),
//                   SizedBox(width: 8),
//                   FilterChipWidget(label: "Group chat"),
//                   SizedBox(width: 8),
//                   FilterChipWidget(label: "Public Threads"),
//                 ],
//               ),
//             ),

//             SizedBox(height: 8),

//             // Chat List
//             Expanded(
//               child: ListView.builder(
//                 itemCount: chatData.length,
//                 itemBuilder: (context, index) {
//                   final chat = chatData[index];
//                   return InkWell(
//                     onTap: () {
//                       Get.toNamed(RouteName.chatscreen);
//                     },
//                     child: ChatTile(
//                       name: chat["name"]!,
//                       message: chat["message"]!,
//                       time: chat["time"]!,
//                       imageUrl: chat["image"]!,
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class FilterChipWidget extends StatelessWidget {
//   final String label;
//   final bool selected;

//   const FilterChipWidget(
//       {super.key, required this.label, this.selected = false});

//   @override
//   Widget build(BuildContext context) {
//     return ChoiceChip(
//       label: Text(label),
//       selected: selected,
//       selectedColor: AppColors.loginContainerColor,
//       backgroundColor: Colors.grey.shade200,
//       labelStyle: TextStyle(
//         color: selected ? Colors.white : Colors.black,
//         fontWeight: FontWeight.w500,
//       ),
//       onSelected: (_) {},
//     );
//   }
// }

// class ChatTile extends StatelessWidget {
//   final String name;
//   final String message;
//   final String time;
//   final String imageUrl;

//   const ChatTile({
//     required this.name,
//     required this.message,
//     required this.time,
//     required this.imageUrl,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return ListTile(
//       contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
//       leading: CircleAvatar(
//         radius: 26,
//         backgroundImage: CachedNetworkImageProvider(imageUrl),
//       ),
//       title: Text(name,
//           style: TextStyle(
//               fontWeight: FontWeight.bold,
//               color: Theme.of(context).textTheme.bodyLarge?.color,
//               fontFamily: AppFonts.opensansRegular)),
//       subtitle: Text(
//         message,
//         maxLines: 1,
//         overflow: TextOverflow.ellipsis,
//         style: TextStyle(
//             color: Theme.of(context).textTheme.bodyLarge?.color,
//             fontFamily: AppFonts.opensansRegular),
//       ),
//       trailing: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             padding: EdgeInsets.all(6),
//             decoration: BoxDecoration(
//               color: Colors.black,
//               shape: BoxShape.circle,
//             ),
//             child: Text(
//               '02',
//               style: TextStyle(color: Colors.white, fontSize: 12),
//             ),
//           ),
//           SizedBox(height: 4),
//           Text(
//             time,
//             style: TextStyle(fontSize: 12, color: AppColors.whiteColor),
//           ),
//         ],
//       ),
//     );
//   }
// }
