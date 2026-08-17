enum AiAttachmentType { image, pdf, csv, excel, word, text, unknown }

class AiAttachmentModel {
  final String id;
  final String fileName;
  final double fileSizeKb;
  final AiAttachmentType fileType;
  final String downloadUrl;
  final String? localPath;
  final String? mimeType;

  const AiAttachmentModel({
    required this.id,
    required this.fileName,
    required this.fileSizeKb,
    required this.fileType,
    required this.downloadUrl,
    this.localPath,
    this.mimeType,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'fileSizeKb': fileSizeKb,
      'fileType': fileType.name,
      'downloadUrl': downloadUrl,
      'localPath': localPath,
      'mimeType': mimeType,
    };
  }

  factory AiAttachmentModel.fromJson(Map<String, dynamic> json) {
    return AiAttachmentModel(
      id: json['id'] as String? ?? '',
      fileName: json['fileName'] as String? ?? 'attachment',
      fileSizeKb: (json['fileSizeKb'] as num?)?.toDouble() ?? 0.0,
      fileType: AiAttachmentType.values.firstWhere(
        (e) => e.name == json['fileType'],
        orElse: () => AiAttachmentType.unknown,
      ),
      downloadUrl: json['downloadUrl'] as String? ?? '',
      localPath: json['localPath'] as String?,
      mimeType: json['mimeType'] as String?,
    );
  }

  static AiAttachmentType detectTypeFromExtension(String ext) {
    final clean = ext.replaceAll('.', '').toLowerCase();
    switch (clean) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'webp':
      case 'gif':
        return AiAttachmentType.image;
      case 'pdf':
        return AiAttachmentType.pdf;
      case 'csv':
        return AiAttachmentType.csv;
      case 'xls':
      case 'xlsx':
        return AiAttachmentType.excel;
      case 'doc':
      case 'docx':
        return AiAttachmentType.word;
      case 'txt':
        return AiAttachmentType.text;
      default:
        return AiAttachmentType.unknown;
    }
  }
}
