import 'package:meu_app/src/features/partnerships/data/datasources/partnership_remote_data_source.dart';
import 'package:meu_app/src/features/partnerships/data/models/partnership_model.dart';

class PartnershipRemoteDataSourceImpl implements PartnershipRemoteDataSource {
  @override
  Future<List<PartnershipModel>> fetchPartnerships() async {
    await Future.delayed(const Duration(milliseconds: 500));

    final mockData = [
      {
        "id": "1",
        "title": "Parceria para Caso Corporativo XPTO",
        "type": "caseSharing",
        "status": "active",
        "createdAt": DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
        "partnerType": "firm",
        "partner": {
          "id": "firm-123",
          "name": "Escritório Modelo & Associados",
          "teamSize": 50,
          "createdAt": "2020-01-01T12:00:00Z",
          "updatedAt": "2023-10-10T12:00:00Z"
        }
      },
      {
        "id": "2",
        "title": "Diligência em São Paulo",
        "type": "correspondent",
        "status": "negotiation",
        "createdAt": DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
        "partnerType": "lawyer",
        "partner": {
          "id": "lawyer-456",
          "name": "Dr. João da Silva",
          "avatarUrl": "https://i.pravatar.cc/150?img=2",
          "oab": "SP123456"
        }
      },
      {
        "id": "3",
        "title": "Parecer sobre Direito Tributário",
        "type": "expertOpinion",
        "status": "closed",
        "createdAt": DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
        "partnerType": "lawyer",
        "partner": {
          "id": "lawyer-789",
          "name": "Dra. Maria Oliveira",
          "avatarUrl": "https://i.pravatar.cc/150?img=3",
          "oab": "RJ654321"
        }
      }
    ];

    return mockData.map((json) => PartnershipModel.fromJson(json)).toList();
  }
} 