const adminEmails = ['chttwm@gmail.com'];

bool isAdminEmail(String? email) {
  final normalized = email?.toLowerCase().trim();
  return normalized != null && adminEmails.contains(normalized);
}
