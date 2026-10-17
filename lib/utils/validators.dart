class Validators {
  static String? required(String? v, {String field = 'Ce champ'}) {
    if (v == null || v.trim().isEmpty) return '$field est requis';
    return null;
  }

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'E-mail requis';
    final re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!re.hasMatch(v.trim())) return 'E-mail invalide';
    return null;
  }

  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Téléphone requis';
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 8) return 'Numéro invalide (min 8 chiffres)';
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Mot de passe requis';
    if (v.length < 6) return 'Min 6 caractères';
    return null;
  }

  static String? prix(String? v) {
    if (v == null || v.trim().isEmpty) return 'Prix requis';
    final p = double.tryParse(v.replaceAll(',', '.'));
    if (p == null || p <= 0) return 'Prix invalide';
    return null;
  }

  static String? url(String? v) {
    if (v == null || v.trim().isEmpty) return 'URL requise';
    final uri = Uri.tryParse(v.trim());
    if (uri == null || !uri.hasScheme) return 'URL invalide (https://...)';
    return null;
  }
}
