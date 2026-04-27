/// Tour images: paste **https://** (or http://) links only — e.g. ImgBB, Imgur, your own host.
/// This project does not upload files to Firebase Storage from the admin UI.
class AdminTourStorage {
  AdminTourStorage._();

  static bool isHttpUrl(String raw) {
    final t = raw.trim();
    final lower = t.toLowerCase();
    return lower.startsWith('https://') || lower.startsWith('http://');
  }

  static bool isDataImageUrl(String raw) =>
      raw.trim().startsWith('data:image/');
}
