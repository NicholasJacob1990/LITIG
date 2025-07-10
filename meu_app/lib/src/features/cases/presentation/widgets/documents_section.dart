import 'package:flutter/material.dart';
import 'package:meu_app/src/features/cases/domain/entities/case_detail_models.dart';

class DocumentsSection extends StatelessWidget {
  final List<DocumentItem> docs;
  const DocumentsSection({super.key, required this.docs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Documentos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ...docs.map((doc) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.insert_drive_file, color: Colors.blue),
                title: Text(doc.name),
                subtitle: Text(doc.sizeDate),
                trailing: IconButton(
                  icon: const Icon(Icons.download, color: Colors.green),
                  onPressed: () {},
                ),
              ),
            )),
      ]),
    );
  }
} 