import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';

/// Validadores para o sistema de avaliações
class RatingValidators {
  static const int minRating = 1;
  static const int maxRating = 5;
  static const int maxCommentLength = 500;
  static const int maxTagsCount = 10;

  /// Valida se o valor do rating está dentro do range permitido
  static Either<Failure, double> validateRating(double rating, String fieldName) {
    if (rating < minRating || rating > maxRating) {
      return Left(ValidationFailure(
        message: '$fieldName deve estar entre $minRating e $maxRating',
      ));
    }
    return Right(rating);
  }

  /// Valida se todos os ratings obrigatórios foram preenchidos
  static Either<Failure, bool> validateRequiredRatings({
    required double overallRating,
    required double communicationRating,
    required double expertiseRating,
    required double responsivenessRating,
    required double valueRating,
  }) {
    final ratings = {
      'Avaliação geral': overallRating,
      'Comunicação': communicationRating,
      'Expertise': expertiseRating,
      'Responsividade': responsivenessRating,
      'Custo-benefício': valueRating,
    };

    for (final entry in ratings.entries) {
      final validation = validateRating(entry.value, entry.key);
      if (validation.isLeft()) {
        return Left(ValidationFailure(
          message: 'Por favor, avalie todos os critérios (${entry.key} não foi preenchido)',
        ));
      }
    }

    return const Right(true);
  }

  /// Valida o comentário
  static Either<Failure, String?> validateComment(String? comment) {
    if (comment == null || comment.trim().isEmpty) {
      return const Right(null);
    }

    final trimmedComment = comment.trim();
    
    if (trimmedComment.length > maxCommentLength) {
      return const Left(ValidationFailure(
        message: 'Comentário deve ter no máximo $maxCommentLength caracteres',
      ));
    }

    if (trimmedComment.length < 10) {
      return const Left(ValidationFailure(
        message: 'Comentário deve ter pelo menos 10 caracteres se fornecido',
      ));
    }

    // Verificar se não contém apenas espaços ou caracteres especiais
    if (!RegExp(r'[a-zA-ZÀ-ÿ0-9]').hasMatch(trimmedComment)) {
      return const Left(ValidationFailure(
        message: 'Comentário deve conter texto válido',
      ));
    }

    return Right(trimmedComment);
  }

  /// Valida as tags selecionadas
  static Either<Failure, List<String>> validateTags(List<String> tags) {
    if (tags.length > maxTagsCount) {
      return const Left(ValidationFailure(
        message: 'Você pode selecionar no máximo $maxTagsCount tags',
      ));
    }

    // Verificar se todas as tags são válidas (não vazias)
    final validTags = tags.where((tag) => tag.trim().isNotEmpty).toList();
    
    if (validTags.length != tags.length) {
      return const Left(ValidationFailure(
        message: 'Todas as tags devem ser válidas',
      ));
    }

    return Right(validTags);
  }

  /// Valida se o usuário pode avaliar o caso
  static Either<Failure, bool> validateRatingPermission({
    required String userId,
    required String caseId,
    required String raterType,
    required String clientId,
    required String lawyerId,
  }) {
    // Verificar se o usuário é parte do caso
    if (raterType == 'client' && userId != clientId) {
      return const Left(ValidationFailure(
        message: 'Apenas o cliente do caso pode fazer esta avaliação',
      ));
    }

    if (raterType == 'lawyer' && userId != lawyerId) {
      return const Left(ValidationFailure(
        message: 'Apenas o advogado do caso pode fazer esta avaliação',
      ));
    }

    // Verificar se o tipo de avaliador é válido
    if (!['client', 'lawyer'].contains(raterType)) {
      return const Left(ValidationFailure(
        message: 'Tipo de avaliador inválido',
      ));
    }

    return const Right(true);
  }

  /// Valida dados completos da avaliação
  static Either<Failure, bool> validateCompleteRating({
    required String caseId,
    required String lawyerId,
    required String clientId,
    required String raterType,
    required double overallRating,
    required double communicationRating,
    required double expertiseRating,
    required double responsivenessRating,
    required double valueRating,
    String? comment,
    List<String>? tags,
  }) {
    // Validar IDs não vazios
    if (caseId.trim().isEmpty) {
      return const Left(ValidationFailure(message: 'ID do caso é obrigatório'));
    }
    
    if (lawyerId.trim().isEmpty) {
      return const Left(ValidationFailure(message: 'ID do advogado é obrigatório'));
    }
    
    if (clientId.trim().isEmpty) {
      return const Left(ValidationFailure(message: 'ID do cliente é obrigatório'));
    }

    // Validar tipo do avaliador
    if (!['client', 'lawyer'].contains(raterType)) {
      return const Left(ValidationFailure(message: 'Tipo de avaliador inválido'));
    }

    // Validar ratings obrigatórios
    final ratingsValidation = validateRequiredRatings(
      overallRating: overallRating,
      communicationRating: communicationRating,
      expertiseRating: expertiseRating,
      responsivenessRating: responsivenessRating,
      valueRating: valueRating,
    );

    if (ratingsValidation.isLeft()) {
      return ratingsValidation;
    }

    // Validar comentário se fornecido
    if (comment != null) {
      final commentValidation = validateComment(comment);
      if (commentValidation.isLeft()) {
        return Left((commentValidation as Left).value);
      }
    }

    // Validar tags se fornecidas
    if (tags != null) {
      final tagsValidation = validateTags(tags);
      if (tagsValidation.isLeft()) {
        return Left((tagsValidation as Left).value);
      }
    }

    return const Right(true);
  }

  /// Valida se o rating médio está consistente
  static Either<Failure, bool> validateRatingConsistency({
    required double overallRating,
    required double communicationRating,
    required double expertiseRating,
    required double responsivenessRating,
    required double valueRating,
  }) {
    final averageRating = (communicationRating + expertiseRating + responsivenessRating + valueRating) / 4;
    final difference = (overallRating - averageRating).abs();

    // Permitir uma diferença de até 1.5 pontos
    if (difference > 1.5) {
      return const Left(ValidationFailure(
        message: 'A avaliação geral parece inconsistente com as avaliações detalhadas. '
        'Por favor, revise suas avaliações.',
      ));
    }

    return const Right(true);
  }

  /// Gera mensagem de feedback baseada na avaliação
  static String generateFeedbackMessage(double overallRating, String raterType) {
    final isClient = raterType == 'client';
    
    if (overallRating >= 4.5) {
      return isClient 
          ? 'Excelente! Sua avaliação ajudará outros clientes a encontrar este advogado.'
          : 'Excelente! Sua avaliação positiva ajuda a construir confiança na plataforma.';
    } else if (overallRating >= 3.5) {
      return isClient
          ? 'Muito bom! Sua avaliação é valiosa para a comunidade.'
          : 'Muito bom! Obrigado pelo feedback construtivo.';
    } else if (overallRating >= 2.5) {
      return isClient
          ? 'Obrigado pelo feedback. Compartilhamos com o advogado para melhorias.'
          : 'Obrigado pelo feedback. Trabalharemos para melhorar a experiência.';
    } else {
      return isClient
          ? 'Lamentamos pela experiência. Seu feedback nos ajuda a melhorar o serviço.'
          : 'Obrigado pelo feedback. Trabalharemos para resolver os problemas identificados.';
    }
  }
} 