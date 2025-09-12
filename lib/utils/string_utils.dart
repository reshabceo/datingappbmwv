class StringUtils {
  /// Capitalizes only the first letter of a string and makes the rest lowercase
  static String capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    if (text.length == 1) return text.toUpperCase();
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Capitalizes the first letter of each word in a string
  static String capitalizeWords(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) => capitalizeFirst(word)).join(' ');
  }

  /// Formats a name for display (first letter capitalized, rest lowercase)
  static String formatName(String name) {
    if (name.isEmpty) return name;
    return capitalizeFirst(name.trim());
  }
}

