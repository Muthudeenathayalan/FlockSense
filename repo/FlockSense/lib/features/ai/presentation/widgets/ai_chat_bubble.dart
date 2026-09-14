import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flock_sense/features/ai/data/models/ai_message_model.dart';
import 'package:flock_sense/features/ai/presentation/widgets/ai_chart_view.dart';

class AiChatBubble extends StatelessWidget {
  final AiMessageModel message;
  final VoidCallback? onRegenerate;

  const AiChatBubble({super.key, required this.message, this.onRegenerate});

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == AiMessageSender.user;
    final timeStr = DateFormat('HH:mm').format(message.timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF1B5E20),
              child: const Icon(
                Icons.psychology,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? const Color(0xFF1B5E20)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    border: isUser
                        ? null
                        : Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Display attachments if any
                      if (message.attachments.isNotEmpty) ...[
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: message.attachments.map((att) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isUser
                                    ? Colors.white.withAlpha(
                                        (0.2 * 255).toInt(),
                                      )
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    att.fileType.name == 'image'
                                        ? Icons.image
                                        : Icons.insert_drive_file,
                                    size: 14,
                                    color: isUser
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    att.fileName,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isUser
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Message Content Parser & Chart Detector
                      _buildMessageContent(message.content, isUser),

                      if (message.isStreaming) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Thinking...',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Timestamp & Action buttons
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timeStr,
                        style: const TextStyle(fontSize: 9, color: Colors.grey),
                      ),
                      if (!isUser && !message.isStreaming) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(
                              ClipboardData(text: message.content),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Response copied to clipboard'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          child: const Icon(
                            Icons.copy,
                            size: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            // ignore: deprecated_member_use
                            Share.shareXFiles([], text: message.content);
                          },
                          child: const Icon(
                            Icons.share,
                            size: 12,
                            color: Colors.grey,
                          ),
                        ),
                        if (onRegenerate != null) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: onRegenerate,
                            child: const Icon(
                              Icons.refresh,
                              size: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(String rawText, bool isUser) {
    final textColor = isUser ? Colors.white : Colors.black87;

    // Check for inline charts e.g. [CHART: weight], [CHART: mortality], etc.
    final chartRegex = RegExp(r'\[CHART:\s*([a-zA-Z0-9_]+)\]');
    final match = chartRegex.firstMatch(rawText);

    Widget? chartWidget;
    String textToFormat = rawText;

    if (match != null) {
      final chartType = match.group(1) ?? 'growth';
      textToFormat = rawText.replaceAll(chartRegex, '').trim();
      chartWidget = Padding(
        padding: const EdgeInsets.only(top: 8),
        child: AiChartView(chartType: chartType),
      );
    }

    if (isUser) {
      return Text(
        textToFormat,
        style: TextStyle(fontSize: 13, height: 1.4, color: textColor),
      );
    }

    // For AI model responses: parse headings, bullet lists, and bold text
    final lines = textToFormat.split('\n');
    final widgets = <Widget>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trimRight();
      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 6));
        continue;
      }

      // Check headings (###, ##, #)
      if (line.startsWith('### ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 2),
            child: Text(
              line.substring(4).trim(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF104422),
              ),
            ),
          ),
        );
      } else if (line.startsWith('## ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 2),
            child: Text(
              line.substring(3).trim(),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF104422),
              ),
            ),
          ),
        );
      } else if (line.startsWith('# ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              line.substring(2).trim(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF104422),
              ),
            ),
          ),
        );
      } else if (line.startsWith('* ') ||
          line.startsWith('- ') ||
          line.startsWith('• ')) {
        final bulletText = line.substring(2).trim();
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 5, right: 6),
                  child: Icon(Icons.circle, size: 5, color: Color(0xFF104422)),
                ),
                Expanded(
                  child: _buildRichInlineSpans(bulletText, textColor),
                ),
              ],
            ),
          ),
        );
      } else if (RegExp(r'^\d+\.\s+').hasMatch(line)) {
        final matchNum = RegExp(r'^(\d+)\.\s+(.*)$').firstMatch(line);
        final numStr = matchNum?.group(1) ?? '•';
        final itemText = matchNum?.group(2) ?? line;
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    '$numStr.',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF104422),
                    ),
                  ),
                ),
                Expanded(
                  child: _buildRichInlineSpans(itemText, textColor),
                ),
              ],
            ),
          ),
        );
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: _buildRichInlineSpans(line, textColor),
          ),
        );
      }
    }

    if (chartWidget != null) {
      widgets.add(chartWidget);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  /// Parses **bold** segments within a line
  Widget _buildRichInlineSpans(String text, Color baseColor) {
    final spans = <TextSpan>[];
    final boldRegex = RegExp(r'\*\*(.*?)\*\*');
    int lastEnd = 0;

    for (final match in boldRegex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: TextStyle(fontSize: 13, height: 1.4, color: baseColor),
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: TextStyle(
          fontSize: 13,
          height: 1.4,
          fontWeight: FontWeight.bold,
          color: baseColor == Colors.white ? Colors.white : Colors.black,
        ),
      ));
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: TextStyle(fontSize: 13, height: 1.4, color: baseColor),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}
