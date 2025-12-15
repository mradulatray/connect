import 'package:connectapp/models/UserLogin/user_login_model.dart';
import 'package:connectapp/view_models/controller/userPreferences/user_preferences_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

import '../../res/api_urls/api_urls.dart';
import 'package:cached_network_image/cached_network_image.dart';

class GroupManagementScreen extends StatefulWidget {
  final VoidCallback? onJoinGroup;

  const GroupManagementScreen({super.key, this.onJoinGroup});
  @override
  _GroupManagementScreenState createState() => _GroupManagementScreenState();
}

class _GroupManagementScreenState extends State<GroupManagementScreen> {
  String currentStep = 'initial'; // 'initial', 'createGroup', 'addMembers'

  // Group creation variables
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _groupDescriptionController =
      TextEditingController();
  File? _groupAvatar;
  final ImagePicker _picker = ImagePicker();

  // Group data from API response
  Map<String, dynamic>? createdGroup;
  List<dynamic> availableMembers =
      []; // Changed from chooseMembers to availableMembers
  List<String> selectedMemberIds = [];
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            }),
      ),
      backgroundColor: Color(0xFF1a1a2e),
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button and title
            Container(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  if (currentStep != 'initial')
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        if (currentStep == 'addMembers') {
                          setState(() {
                            currentStep = 'initial';
                          });
                        } else {
                          setState(() {
                            currentStep = 'initial';
                          });
                        }
                      },
                    ),
                  Expanded(
                    child: Text(
                      _getScreenTitle(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (currentStep != 'initial')
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          currentStep = 'initial';
                          _resetForm();
                        });
                      },
                    ),
                ],
              ),
            ),

            // Content based on current step
            Expanded(
              child: _buildCurrentStepContent(),
            ),
          ],
        ),
      ),
    );
  }

  String _getScreenTitle() {
    switch (currentStep) {
      case 'createGroup':
        return 'Create Group';
      case 'addMembers':
        return 'Add Members';
      default:
        return 'Chat';
    }
  }

  Widget _buildCurrentStepContent() {
    switch (currentStep) {
      case 'createGroup':
        return _buildCreateGroupForm();
      case 'addMembers':
        return _buildAddMembersScreen();
      default:
        return _buildInitialScreen();
    }
  }

  Widget _buildInitialScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Welcome to Chat',
            style: TextStyle(color: Colors.white, fontSize: 24),
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                currentStep = 'createGroup';
              });
            },
            icon: Icon(Icons.group_add),
            label: Text('Create Group'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4f46e5),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
          ),
          SizedBox(
            height: 10,
          ),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                widget.onJoinGroup?.call();
                // currentStep = 'createGroup';
              });
            },
            icon: Icon(Icons.group_add),
            label: Text('Join Group'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4f46e5),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateGroupForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group Avatar
          Center(
            child: GestureDetector(
              onTap: _pickGroupImage,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Color(0xFF374151),
                  shape: BoxShape.circle,
                  border: Border.all(color: Color(0xFF4f46e5), width: 2),
                ),
                child: _groupAvatar != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(60),
                        child: Image.file(
                          _groupAvatar!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt,
                            color: Colors.white54,
                            size: 32,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Group Avatar',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),

          SizedBox(height: 32),

          // Group Name
          Text(
            'Group Name *',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          TextFormField(
            controller: _groupNameController,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter group name',
              hintStyle: TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Color(0xFF374151),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),

          SizedBox(height: 20),

          // Description
          Text(
            'Description *',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          TextFormField(
            controller: _groupDescriptionController,
            style: TextStyle(color: Colors.white),
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Enter group description',
              hintStyle: TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Color(0xFF374151),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),

          SizedBox(height: 40),

          // Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      currentStep = 'initial';
                      _resetForm();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF374151),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('Cancel'),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: isLoading ? null : _createGroup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4f46e5),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text('Next'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddMembersScreen() {
    return Column(
      children: [
        // Group info header
        if (createdGroup != null)
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(0xFF374151),
                  backgroundImage: createdGroup!['groupAvatar'] != null
                      ? CachedNetworkImageProvider(createdGroup!['groupAvatar'])
                      : null,
                  child: createdGroup!['groupAvatar'] == null
                      ? Icon(Icons.group, color: Colors.white54, size: 30)
                      : null,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        createdGroup!['name'] ?? '',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Select members to add',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Members list
        Expanded(
          child: availableMembers.isEmpty
              ? Center(
                  child: Text(
                    'No members available',
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: availableMembers.length,
                  itemBuilder: (context, index) {
                    final member = availableMembers[index];
                    final isSelected =
                        selectedMemberIds.contains(member['_id']);

                    return Container(
                      margin: EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Color(0xFF374151),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Color(0xFF4f46e5),
                          backgroundImage: member['avatar']?['imageUrl'] != null
                              ? CachedNetworkImageProvider(member['avatar']['imageUrl'])
                              : null,
                          child: member['avatar']?['imageUrl'] == null
                              ? Text(
                                  member['fullName']?[0]?.toUpperCase() ?? '?',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                )
                              : null,
                        ),
                        title: Text(
                          member['fullName'] ?? 'Unknown',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          member['email'] ?? 'No email',
                          style: TextStyle(color: Colors.white54),
                        ),
                        trailing: GestureDetector(
                          onTap: () => _toggleMemberSelection(member['_id']),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? Color(0xFF4f46e5)
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? Color(0xFF4f46e5)
                                    : Colors.white54,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? Icon(Icons.check,
                                    color: Colors.white, size: 20)
                                : Icon(Icons.add,
                                    color: Colors.white54, size: 20),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Selected members count
        if (selectedMemberIds.isNotEmpty)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '${selectedMemberIds.length} member(s) selected',
              style: TextStyle(
                color: Color(0xFF4f46e5),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

        // Bottom buttons
        Container(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      currentStep = 'initial';
                      _resetForm();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF374151),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('Cancel'),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: isLoading || selectedMemberIds.isEmpty
                      ? null
                      : _addMembersToGroup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4f46e5),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Create Group${selectedMemberIds.isNotEmpty ? ' (${selectedMemberIds.length})' : ''}'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickGroupImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _groupAvatar = File(image.path);
      });
    }
  }

  Future<void> _createGroup() async {
    final UserPreferencesViewmodel _userPreferences =
        UserPreferencesViewmodel();
    LoginResponseModel? userData = await _userPreferences.getUser();
    final token = userData?.token;

    if (_groupNameController.text.isEmpty ||
        _groupDescriptionController.text.isEmpty) {
      _showErrorSnackBar('Please fill in all required fields');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      print(
          '🚀 Using endpoint: ${ApiUrls.baseUrl}/connect/v1/api/user/create-seperate-group');

      var request = http.MultipartRequest(
          'POST',
          Uri.parse(
              '${ApiUrls.baseUrl}/connect/v1/api/user/create-seperate-group'));

      // Add text fields
      request.fields['name'] = _groupNameController.text;
      request.fields['description'] = _groupDescriptionController.text;

      // Add image if selected with proper MIME handling
      if (_groupAvatar != null) {
        // Get file info
        final String fileName = _groupAvatar!.path.split('/').last;
        final fileSize = await _groupAvatar!.length();

        print("🔍 Uploading file: $fileName");
        print("📏 File size: $fileSize bytes");
        print("📁 File path: ${_groupAvatar!.path}");

        // Verify file exists and is readable
        if (!await _groupAvatar!.exists()) {
          throw Exception('File does not exist');
        }

        // Read file as bytes to ensure it's valid
        final bytes = await _groupAvatar!.readAsBytes();
        print("✅ File readable, ${bytes.length} bytes loaded");

        // Determine MIME type
        final mimeType = lookupMimeType(_groupAvatar!.path);
        if (mimeType == null) {
          throw Exception('Could not determine MIME type');
        }
        print("🎭 MIME type: $mimeType");

        final mediaType = MediaType.parse(mimeType);

        // Use fromBytes instead of fromPath for more control
        final multipartFile = http.MultipartFile.fromBytes(
          'groupAvatar',
          bytes,
          filename: fileName,
          contentType: mediaType,
        );

        request.files.add(multipartFile);
      }

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';

      print('📤 Sending request with fields: ${request.fields}');
      print('📎 Sending request with files: ${request.files.length}');

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('📨 Response status: ${response.statusCode}');
      print('📄 Response body of create-seperate-group: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        var jsonResponse = json.decode(response.body);

        // Extract members from the nested structure
        List<dynamic> extractedMembers = [];
        if (jsonResponse['chooseMembers'] != null) {
          for (var chat in jsonResponse['chooseMembers']) {
            if (chat['participants'] != null) {
              for (var participant in chat['participants']) {
                extractedMembers.add(participant);
              }
            }
          }
        }

        print('📋 Extracted ${extractedMembers.length} members');
        print('👥 Members data: $extractedMembers');

        setState(() {
          createdGroup = jsonResponse['group'];
          availableMembers = extractedMembers;
          currentStep = 'addMembers';
        });
        _showSuccessSnackBar('Group created successfully!');
      } else {
        try {
          var errorResponse = json.decode(response.body);
          _showErrorSnackBar(
              errorResponse['message'] ?? 'Failed to create group');
        } catch (e) {
          _showErrorSnackBar(
              'Server error: ${response.statusCode} - ${response.body}');
        }
      }
    } catch (e) {
      print('💥 Error creating group: $e');
      _showErrorSnackBar('Network error: ${e.toString()}');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _addMembersToGroup() async {
    final UserPreferencesViewmodel _userPreferences =
        UserPreferencesViewmodel();
    LoginResponseModel? userData = await _userPreferences.getUser();
    final token = userData?.token;

    if (createdGroup == null || selectedMemberIds.isEmpty) {
      _showErrorSnackBar('No members selected');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.patch(
        Uri.parse(
            '${ApiUrls.baseUrl}/connect/v1/api/user/add-group-members/${createdGroup!['_id']}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'members': selectedMemberIds,
        }),
      );

      var jsonResponse = json.decode(response.body);
      print("Response of add groupMembers: $jsonResponse");

      if (response.statusCode == 200) {
        _showSuccessSnackBar('Members added successfully!');
        // Navigate back or to group chat
        setState(() {
          currentStep = 'initial';
          _resetForm();
        });
      } else {
        _showErrorSnackBar(jsonResponse['message'] ?? 'Failed to add members');
      }
    } catch (e) {
      _showErrorSnackBar('Network error: ${e.toString()}');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _toggleMemberSelection(String memberId) {
    setState(() {
      if (selectedMemberIds.contains(memberId)) {
        selectedMemberIds.remove(memberId);
      } else {
        selectedMemberIds.add(memberId);
      }
    });
  }

  void _resetForm() {
    _groupNameController.clear();
    _groupDescriptionController.clear();
    setState(() {
      _groupAvatar = null;
      createdGroup = null;
      availableMembers.clear();
      selectedMemberIds.clear();
    });
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _groupDescriptionController.dispose();
    super.dispose();
  }
}
