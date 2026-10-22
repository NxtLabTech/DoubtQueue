String? requiredField(String? value, String message) {
  return value == null || value.trim().isEmpty ? message : null;
}
