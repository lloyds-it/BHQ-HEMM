import 'file_downloader_stub.dart'
    if (dart.library.html) 'file_downloader_web.dart';

class FileDownloader {
  /// Triggers a file download. On Web it creates a download link, on Mobile it can log/share/save.
  static void download(String url, String filename) {
    downloadFile(url, filename);
  }
}
