// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

void downloadFile(String url, String filename) {
  js.context.callMethod('eval', ['''
    (function() {
      var a = document.createElement('a');
      a.href = '$url';
      a.download = '$filename';
      a.target = '_blank';
      document.body.appendChild(a);
      a.click();
      setTimeout(function() { document.body.removeChild(a); }, 100);
    })();
  ''']);
}
