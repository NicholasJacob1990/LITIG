
class Validators {
  // Private constructor to prevent instantiation
  Validators._();

  /// Validates CPF (Brazilian individual taxpayer registry)
  static String? validateCPF(String? cpf) {
    if (cpf == null || cpf.isEmpty) {
      return 'CPF é obrigatório';
    }

    // Remove formatting
    final cleanCPF = cpf.replaceAll(RegExp(r'[^0-9]'), '');

    // Check length
    if (cleanCPF.length != 11) {
      return 'CPF deve ter 11 dígitos';
    }

    // Check for invalid sequences (like 111.111.111-11)
    if (RegExp(r'^(\d)\1{10}$').hasMatch(cleanCPF)) {
      return 'CPF inválido';
    }

    // Validate check digits
    if (!_isValidCPF(cleanCPF)) {
      return 'CPF inválido';
    }

    return null;
  }

  /// Validates CNPJ (Brazilian corporate taxpayer registry)
  static String? validateCNPJ(String? cnpj) {
    if (cnpj == null || cnpj.isEmpty) {
      return 'CNPJ é obrigatório';
    }

    // Remove formatting
    final cleanCNPJ = cnpj.replaceAll(RegExp(r'[^0-9]'), '');

    // Check length
    if (cleanCNPJ.length != 14) {
      return 'CNPJ deve ter 14 dígitos';
    }

    // Check for invalid sequences
    if (RegExp(r'^(\d)\1{13}$').hasMatch(cleanCNPJ)) {
      return 'CNPJ inválido';
    }

    // Validate check digits
    if (!_isValidCNPJ(cleanCNPJ)) {
      return 'CNPJ inválido';
    }

    return null;
  }

  /// Validates email address
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'E-mail é obrigatório';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(email)) {
      return 'E-mail inválido';
    }

    return null;
  }

  /// Validates Brazilian phone number
  static String? validatePhone(String? phone) {
    if (phone == null || phone.isEmpty) {
      return null; // Phone is optional
    }

    // Remove formatting
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');

    // Brazilian phone: 10 or 11 digits (with area code)
    if (cleanPhone.length < 10 || cleanPhone.length > 11) {
      return 'Telefone deve ter 10 ou 11 dígitos';
    }

    // Check area code (11-99)
    final areaCode = int.tryParse(cleanPhone.substring(0, 2));
    if (areaCode == null || areaCode < 11 || areaCode > 99) {
      return 'Código de área inválido';
    }

    return null;
  }

  /// Validates required phone number
  static String? validateRequiredPhone(String? phone) {
    if (phone == null || phone.isEmpty) {
      return 'Telefone é obrigatório';
    }

    return validatePhone(phone);
  }

  /// Validates Brazilian CEP (postal code)
  static String? validateCEP(String? cep) {
    if (cep == null || cep.isEmpty) {
      return 'CEP é obrigatório';
    }

    // Remove formatting
    final cleanCEP = cep.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleanCEP.length != 8) {
      return 'CEP deve ter 8 dígitos';
    }

    // Check for invalid sequences (like 00000-000)
    if (RegExp(r'^0{8}$').hasMatch(cleanCEP)) {
      return 'CEP inválido';
    }

    return null;
  }

  /// Validates name (required, minimum 2 characters)
  static String? validateName(String? name) {
    if (name == null || name.isEmpty) {
      return 'Nome é obrigatório';
    }

    if (name.trim().length < 2) {
      return 'Nome deve ter pelo menos 2 caracteres';
    }

    // Check for valid characters (letters, spaces, hyphens, apostrophes)
    if (!RegExp(r"^[a-zA-ZÀ-ÿ\s'-]+$").hasMatch(name)) {
      return 'Nome contém caracteres inválidos';
    }

    return null;
  }

  /// Validates full name (requires at least first and last name)
  static String? validateFullName(String? name) {
    final basicValidation = validateName(name);
    if (basicValidation != null) {
      return basicValidation;
    }

    final nameParts = name!.trim().split(' ');
    if (nameParts.length < 2) {
      return 'Digite nome e sobrenome';
    }

    // Check if each part has at least 2 characters
    for (final part in nameParts) {
      if (part.trim().length < 2) {
        return 'Nome e sobrenome devem ter pelo menos 2 caracteres cada';
      }
    }

    return null;
  }

  /// Validates password strength
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Senha é obrigatória';
    }

    if (password.length < 8) {
      return 'Senha deve ter pelo menos 8 caracteres';
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Senha deve conter pelo menos uma letra maiúscula';
    }

    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Senha deve conter pelo menos uma letra minúscula';
    }

    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Senha deve conter pelo menos um número';
    }

    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      return 'Senha deve conter pelo menos um caractere especial';
    }

    return null;
  }

  /// Validates confirm password
  static String? validateConfirmPassword(String? confirmPassword, String? originalPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Confirmação de senha é obrigatória';
    }

    if (confirmPassword != originalPassword) {
      return 'Senhas não coincidem';
    }

    return null;
  }

  /// Validates birth date
  static String? validateBirthDate(DateTime? birthDate) {
    if (birthDate == null) {
      return 'Data de nascimento é obrigatória';
    }

    final now = DateTime.now();
    final age = now.year - birthDate.year;
    
    // Check if birthday has occurred this year
    final hasHadBirthdayThisYear = now.month > birthDate.month ||
        (now.month == birthDate.month && now.day >= birthDate.day);

    final actualAge = hasHadBirthdayThisYear ? age : age - 1;

    if (actualAge < 0) {
      return 'Data de nascimento não pode ser no futuro';
    }

    if (actualAge > 120) {
      return 'Data de nascimento inválida';
    }

    if (actualAge < 16) {
      return 'Idade mínima: 16 anos';
    }

    return null;
  }

  /// Validates company founding date
  static String? validateFoundingDate(DateTime? foundingDate) {
    if (foundingDate == null) {
      return null; // Optional
    }

    final now = DateTime.now();
    
    if (foundingDate.isAfter(now)) {
      return 'Data de fundação não pode ser no futuro';
    }

    // Companies can't be older than 200 years
    if (now.year - foundingDate.year > 200) {
      return 'Data de fundação muito antiga';
    }

    return null;
  }

  /// Validates RG (Brazilian identity document)
  static String? validateRG(String? rg) {
    if (rg == null || rg.isEmpty) {
      return null; // RG can be optional depending on context
    }

    // Remove formatting
    final cleanRG = rg.replaceAll(RegExp(r'[^0-9Xx]'), '');

    // RG can have 7-9 characters (including check digit which can be X)
    if (cleanRG.length < 7 || cleanRG.length > 9) {
      return 'RG inválido';
    }

    return null;
  }

  /// Validates required RG
  static String? validateRequiredRG(String? rg) {
    if (rg == null || rg.isEmpty) {
      return 'RG é obrigatório';
    }

    return validateRG(rg);
  }

  /// Validates URL
  static String? validateURL(String? url) {
    if (url == null || url.isEmpty) {
      return null; // URL is optional
    }

    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );

    if (!urlRegex.hasMatch(url)) {
      return 'URL inválida';
    }

    return null;
  }

  /// Validates file size
  static String? validateFileSize(int? sizeInBytes, {int maxSizeInMB = 10}) {
    if (sizeInBytes == null || sizeInBytes <= 0) {
      return 'Arquivo inválido';
    }

    final maxSizeInBytes = maxSizeInMB * 1024 * 1024;
    
    if (sizeInBytes > maxSizeInBytes) {
      return 'Arquivo muito grande. Máximo: ${maxSizeInMB}MB';
    }

    return null;
  }

  /// Validates file extension
  static String? validateFileExtension(String? fileName, List<String> allowedExtensions) {
    if (fileName == null || fileName.isEmpty) {
      return 'Nome do arquivo inválido';
    }

    final extension = fileName.split('.').last.toLowerCase();
    
    if (!allowedExtensions.contains(extension)) {
      return 'Tipo de arquivo não permitido. Permitidos: ${allowedExtensions.join(', ')}';
    }

    return null;
  }

  // Private helper methods

  static bool _isValidCPF(String cpf) {
    // Calculate first check digit
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += int.parse(cpf[i]) * (10 - i);
    }
    int remainder = sum % 11;
    int digit1 = remainder < 2 ? 0 : 11 - remainder;

    if (int.parse(cpf[9]) != digit1) {
      return false;
    }

    // Calculate second check digit
    sum = 0;
    for (int i = 0; i < 10; i++) {
      sum += int.parse(cpf[i]) * (11 - i);
    }
    remainder = sum % 11;
    int digit2 = remainder < 2 ? 0 : 11 - remainder;

    return int.parse(cpf[10]) == digit2;
  }

  static bool _isValidCNPJ(String cnpj) {
    // CNPJ validation weights
    final weights1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    final weights2 = [6, 7, 8, 9, 2, 3, 4, 5, 6, 7, 8, 9];

    // Calculate first check digit
    int sum = 0;
    for (int i = 0; i < 12; i++) {
      sum += int.parse(cnpj[i]) * weights1[i];
    }
    int remainder = sum % 11;
    int digit1 = remainder < 2 ? 0 : 11 - remainder;

    if (int.parse(cnpj[12]) != digit1) {
      return false;
    }

    // Calculate second check digit
    sum = 0;
    for (int i = 0; i < 13; i++) {
      sum += int.parse(cnpj[i]) * weights2[i];
    }
    remainder = sum % 11;
    int digit2 = remainder < 2 ? 0 : 11 - remainder;

    return int.parse(cnpj[13]) == digit2;
  }
}

/// Utility class for common validation patterns
class ValidationPatterns {
  static final RegExp cpf = RegExp(r'^\d{3}\.\d{3}\.\d{3}-\d{2}$');
  static final RegExp cnpj = RegExp(r'^\d{2}\.\d{3}\.\d{3}\/\d{4}-\d{2}$');
  static final RegExp phone = RegExp(r'^\(\d{2}\)\s\d{4,5}-\d{4}$');
  static final RegExp cep = RegExp(r'^\d{5}-\d{3}$');
  static final RegExp email = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
}

/// Extension methods for common validations
extension StringValidation on String? {
  bool get isValidCPF => Validators.validateCPF(this) == null;
  bool get isValidCNPJ => Validators.validateCNPJ(this) == null;
  bool get isValidEmail => Validators.validateEmail(this) == null;
  bool get isValidPhone => Validators.validatePhone(this) == null;
  bool get isValidCEP => Validators.validateCEP(this) == null;
  
  String? get cpfValidation => Validators.validateCPF(this);
  String? get cnpjValidation => Validators.validateCNPJ(this);
  String? get emailValidation => Validators.validateEmail(this);
  String? get phoneValidation => Validators.validatePhone(this);
  String? get cepValidation => Validators.validateCEP(this);
}