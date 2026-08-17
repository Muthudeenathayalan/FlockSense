import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flock_sense/features/ai/data/models/ai_attachment_model.dart';
import 'package:flock_sense/features/ai/data/services/ai_storage_service.dart';

class AiInputBar extends StatefulWidget {
  final Function(String text, List<AiAttachmentModel> attachments) onSend;
  final bool isSending;
  final VoidCallback onStop;

  const AiInputBar({
    super.key,
    required onSend,
    required this.isSending,
    required this.onStop,
  }) : onSend = onSend;

  @override
  State<AiInputBar> createState() => _AiInputBarState();
}

class _AiInputBarState extends State<AiInputBar> {
  final TextEditingController _controller = TextEditingController();
  final List<AiAttachmentModel> _attachments = [];
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingAttachment = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final xFile = await _picker.pickImage(source: source, imageQuality: 80);
      if (xFile == null) return;

      setState(() => _isUploadingAttachment = true);

      final file = File(xFile.path);
      final attachment = await AiStorageService.uploadFile(
        file: file,
        conversationId: 'temp',
        type: AiAttachmentType.image,
      );

      setState(() {
        _attachments.add(attachment);
        _isUploadingAttachment = false;
      });
    } catch (e) {
      setState(() => _isUploadingAttachment = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add image: $e')),
        );
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'csv', 'xlsx', 'xls', 'txt', 'doc', 'docx'],
      );

      if (result == null || result.files.single.path == null) return;

      setState(() => _isUploadingAttachment = true);

      final file = File(result.files.single.path!);
      final ext = result.files.single.extension ?? '';
      final type = AiAttachmentModel.detectTypeFromExtension(ext);

      final attachment = await AiStorageService.uploadFile(
        file: file,
        conversationId: 'temp',
        type: type,
      );

      setState(() {
        _attachments.add(attachment);
        _isUploadingAttachment = false;
      });
    } catch (e) {
      setState(() => _isUploadingAttachment = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick document: $e')),
        );
      }
    }
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty && _attachments.isEmpty) return;

    widget.onSend(text, List.from(_attachments));

    _controller.clear();
    setState(() => _attachments.clear());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300, width: 0.8)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Attachment Preview Row
            if (_attachments.isNotEmpty || _isUploadingAttachment) ...[
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    if (_isUploadingAttachment)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                        child: const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                    ..._attachments.map((att) => Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                att.fileType == AiAttachmentType.image ? Icons.image : Icons.insert_drive_file,
                                size: 16,
                                color: const Color(0xFF1B5E20),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                att.fileName,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => setState(() => _attachments.remove(att)),
                                child: const Icon(Icons.close, size: 14, color: Colors.grey),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 6),
            ],

            // Input Bar Row
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file, color: Colors.black54),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (ctx) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.camera_alt, color: Color(0xFF1B5E20)),
                            title: const Text('Capture Photo (Bird / Droppings / Label)'),
                            onTap: () {
                              Navigator.pop(ctx);
                              _pickImage(ImageSource.camera);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.photo_library, color: Color(0xFF00838F)),
                            title: const Text('Choose from Gallery'),
                            onTap: () {
                              Navigator.pop(ctx);
                              _pickImage(ImageSource.gallery);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.upload_file, color: Color(0xFFE65100)),
                            title: const Text('Attach Document (PDF, CSV, Excel, TXT)'),
                            onTap: () {
                              Navigator.pop(ctx);
                              _pickFile();
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLines: 4,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Ask FlockSense AI or analyze files...',
                      hintStyle: const TextStyle(fontSize: 13, color: Colors.black45),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Color(0xFF1B5E20), width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.mic_none, color: Colors.black45),
                  tooltip: 'Voice Search (Tap to speak)',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Voice Assistant ready. Speak your question now...')),
                    );
                  },
                ),
                IconButton(
                  icon: widget.isSending
                      ? const Icon(Icons.stop_circle, color: Colors.red)
                      : const Icon(Icons.send, color: Color(0xFF1B5E20)),
                  onPressed: widget.isSending ? widget.onStop : _handleSend,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
