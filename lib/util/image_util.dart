
class ImageUtils {
    static String getImageUrl(String? serverUrl, String itemId) {
      if (serverUrl == null) return '';
      try {
        return '$serverUrl/Items/$itemId/Images/Primary/';
      } catch (e) {
        return '';
      }
    }
  }