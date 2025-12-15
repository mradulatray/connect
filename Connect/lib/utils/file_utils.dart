
import 'package:connectapp/utils/local_file_manager.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../view/message/audioplayerstate.dart';
import '../view/message/videoplayer.dart';

class FileUtils {

  static String getFileType(String path) {
    final extension = path.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
      return 'image/$extension';
    } else if (['mp4', 'avi', 'mov', 'wmv', 'flv', '3gp', 'webm']
        .contains(extension)) {
      return 'video/$extension';
    } else if (['mp3', 'aac', 'wav', 'ogg', 'm4a', 'flac']
        .contains(extension)) {
      return 'audio/$extension';
    } else if (['pdf'].contains(extension)) {
      return 'application/pdf';
    } else if (['doc', 'docx'].contains(extension)) {
      return 'application/msword';
    } else if (['xls', 'xlsx'].contains(extension)) {
      return 'application/vnd.ms-excel';
    } else if (['txt'].contains(extension)) {
      return 'text/plain';
    } else {
      return 'application/octet-stream';
    }
  }

  static void openFile(BuildContext context,String fileUrl, String fileName, LocalFileManager localFileManager) {
    final fileType = getFileType(fileName);

    if (fileType.startsWith('image/')) {
      showImageFullScreen(context,fileUrl, fileName,localFileManager);
    } else if (fileType.startsWith('video/')) {
      showVideoFullScreen(context,fileUrl, fileName,localFileManager);
    } else if (fileType.startsWith('audio/')) {
      showAudioPlayer(context,fileUrl, fileName,localFileManager);
    } else {
      openFileWithSystemApp(context,fileUrl, fileName, localFileManager);
    }
  }

  static void showImageFullScreen(BuildContext context,String imageUrl, String fileName, LocalFileManager localFileManager) {
    localFileManager.addFilePath(FileTypeFormat.media, imageUrl);
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, color: Colors.white, size: 48),
                            SizedBox(height: 16),
                            Text(
                              'Failed to load image',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    fileName,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  static void showVideoFullScreen(BuildContext context,String videoUrl, String fileName,LocalFileManager localFileManager) {
    localFileManager.addFilePath(FileTypeFormat.media, videoUrl);
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black,
          child: VideoPlayerDialog(
            videoUrl: videoUrl,
            fileName: fileName,
          ),
        );
      },
    );
  }

  static void showAudioPlayer(BuildContext context, String audioUrl, String fileName,LocalFileManager localFileManager) {
    localFileManager.addFilePath(FileTypeFormat.media, audioUrl);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AudioPlayerDialog(
          audioUrl: audioUrl,
          fileName: fileName,
        );
      },
    );
  }

  // Fixed PDF opening with proper file handling and multiple fallbacks
  static Future<void> openFileWithSystemApp(BuildContext context,String fileUrl, String fileName,LocalFileManager localFileManager) async {
    try {
      debugPrint('Attempting to open file: $fileUrl');

      // For PDFs, use multiple fallback approaches
      if (fileName.toLowerCase().endsWith('.pdf')) {
        localFileManager.addFilePath(FileTypeFormat.document, fileUrl);
        await openPDFFile(context, fileUrl, fileName,localFileManager);
        return;
      }

      // For other files, try multiple launch modes
      final Uri url = Uri.parse(fileUrl);

      // First try external application
      bool launched = false;
      try {
        localFileManager.addFilePath(FileTypeFormat.link, fileUrl);
        if (await canLaunchUrl(url)) {
          launched = await launchUrl(
            url,
            mode: LaunchMode.externalApplication,
          );
        }
      } catch (e) {
        debugPrint('External app launch failed: $e');
      }

      // If external app fails, try platform default
      if (!launched) {
        try {
          launched = await launchUrl(
            url,
            mode: LaunchMode.platformDefault,
          );
        } catch (e) {
          debugPrint('Platform default launch failed: $e');
        }
      }

      // Final fallback to in-app browser
      if (!launched) {
        try {
          await launchUrl(
            url,
            mode: LaunchMode.inAppWebView,
          );
          launched = true;
        } catch (e) {
          debugPrint('In-app browser launch failed: $e');
        }
      }

      if (!launched) {
        showSnackBar(context,'Cannot open file. Please install a suitable app.');
      }
    } catch (e) {
      debugPrint('Error opening file: $e');
      showSnackBar(context,'Error opening file: ${e.toString()}');
    }
  }

  static void showSnackBar(BuildContext context,String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

// Download and open PDF locally
  // Improved PDF opening method
  // Improved PDF opening method with multiple fallback strategies
  static Future<void> openPDFFile(BuildContext context,String fileUrl, String fileName,LocalFileManager localFileManager) async {
    try {
      debugPrint('Opening PDF: $fileUrl');
      final Uri url = Uri.parse(fileUrl);

      bool launched = false;
      localFileManager.addFilePath(FileTypeFormat.document, fileUrl);

      // Strategy 1: Try external application with PDF intent
      try {
        if (await canLaunchUrl(url)) {
          launched = await launchUrl(
            url,
            mode: LaunchMode.externalApplication,
          );
        }
      } catch (e) {
        debugPrint('External PDF app failed: $e');
      }

      // Strategy 2: Try platform default
      if (!launched) {
        try {
          launched = await launchUrl(
            url,
            mode: LaunchMode.platformDefault,
          );
        } catch (e) {
          debugPrint('Platform default PDF failed: $e');
        }
      }

      // Strategy 3: Try in-app web view
      if (!launched) {
        try {
          launched = await launchUrl(
            url,
            mode: LaunchMode.inAppWebView,
            webViewConfiguration: const WebViewConfiguration(
              enableJavaScript: true,
              enableDomStorage: true,
            ),
          );
        } catch (e) {
          debugPrint('In-app web view PDF failed: $e');
        }
      }

      // Strategy 4: Open in system browser as last resort
      if (!launched) {
        try {
          launched = await launchUrl(
            url,
            mode: LaunchMode.externalNonBrowserApplication,
          );
        } catch (e) {
          debugPrint('External non-browser PDF failed: $e');
        }
      }

      if (!launched) {
        // Show dialog with options
        showPDFOptionsDialog(context,fileUrl, fileName);
      }
    } catch (e) {
      debugPrint('PDF opening error: $e');
      showSnackBar(context,'Cannot open PDF. Please install a PDF reader app.');
    }
  }

// Show dialog with PDF opening options
  static void showPDFOptionsDialog(BuildContext context,String fileUrl, String fileName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Open PDF'),
          content: Text('No PDF reader app found. Would you like to:'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // copyUrlToClipboard(fileUrl);
              },
              child: Text('Copy URL'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                // Try to open in browser
                try {
                  final Uri url = Uri.parse(fileUrl);
                  await launchUrl(url, mode: LaunchMode.inAppWebView);
                } catch (e) {
                  showSnackBar(context, 'Failed to open in browser');
                }
              },
              child: Text('Open in Browser'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  static IconData getFileIcon(String pathOrExtension) {
    String extension = pathOrExtension.toLowerCase();

    // If the input contains a dot and is a path, extract the extension
    if (extension.contains('.') && !extension.startsWith('.')) {
      extension = extension.split('.').last.toLowerCase();
    }
    // Add dot prefix to extension for consistent matching as in second function
    if (!extension.startsWith('.')) {
      extension = '.' + extension;
    }

    switch (extension) {
      case '.pdf':
        return Icons.picture_as_pdf;
      case '.doc':
      case '.docx':
        return Icons.description;
      case '.xls':
      case '.xlsx':
      // Use Icons.grid_on as in the first function for Excel files
        return Icons.grid_on;
      case '.ppt':
      case '.pptx':
        return Icons.slideshow;
      case '.txt':
        return Icons.notes;
      case '.zip':
      case '.rar':
        return Icons.archive;
      case '.mp4':
      case '.mov':
      case '.avi':
      case '.mkv':
        return Icons.videocam;
      case '.mp3':
      case '.wav':
        return Icons.audiotrack;
      default:
      // Use Icons.insert_drive_file_outlined from the first function as default
        return Icons.insert_drive_file_outlined;
    }
  }


  static Future<void> openUrl(BuildContext context,String url, LocalFileManager localFileManager) async {
    try {
      debugPrint('Opening URL: $url');
      final Uri uri = Uri.parse(url);
      bool launched = false;

      // Strategy 1: Try external application
      try {

        localFileManager.addFilePath(FileTypeFormat.link, url);

        if (await canLaunchUrl(uri)) {
          launched = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
        }
      } catch (e) {
        debugPrint('External app URL launch failed: $e');
      }

      // Strategy 2: Try platform default
      if (!launched) {
        try {
          launched = await launchUrl(
            uri,
            mode: LaunchMode.platformDefault,
          );
        } catch (e) {
          debugPrint('Platform default URL launch failed: $e');
        }
      }

      // Strategy 3: Try in-app web view
      if (!launched) {
        try {
          launched = await launchUrl(
            uri,
            mode: LaunchMode.inAppWebView,
            webViewConfiguration: const WebViewConfiguration(
              enableJavaScript: true,
              enableDomStorage: true,
            ),
          );
        } catch (e) {
          debugPrint('In-app web view URL launch failed: $e');
        }
      }

      if (!launched) {
        showSnackBar(context,
            'Cannot open URL. Please check your internet connection.');
      }
    } catch (e) {
      debugPrint('Error opening URL: $e');
      showSnackBar(context,'Invalid URL format');
    }
  }
}