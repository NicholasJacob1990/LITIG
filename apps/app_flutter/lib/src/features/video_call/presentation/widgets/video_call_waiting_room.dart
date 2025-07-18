import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class VideoCallWaitingRoom extends StatelessWidget {
  const VideoCallWaitingRoom({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ícone de videochamada
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(60),
              border: Border.all(color: Colors.blue, width: 2),
            ),
            child: const Icon(
              LucideIcons.video,
              color: Colors.blue,
              size: 48,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Texto de carregamento
          const Text(
            'Conectando à videochamada...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          // Indicador de carregamento
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            strokeWidth: 3,
          ),
          
          const SizedBox(height: 32),
          
          // Dicas
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                const Text(
                  'Dicas para uma boa videochamada:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _buildTip(
                  icon: LucideIcons.lightbulb,
                  text: 'Certifique-se de estar em um ambiente bem iluminado',
                ),
                _buildTip(
                  icon: LucideIcons.volume2,
                  text: 'Use fones de ouvido para melhor qualidade de áudio',
                ),
                _buildTip(
                  icon: LucideIcons.wifi,
                  text: 'Verifique sua conexão com a internet',
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Botão de cancelar
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(LucideIcons.x, color: Colors.white),
            label: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white),
            ),
            style: TextButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.7),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTip({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.blue,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}