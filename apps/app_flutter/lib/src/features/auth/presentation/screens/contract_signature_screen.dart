import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ContractSignatureScreen extends StatefulWidget {
  const ContractSignatureScreen({super.key});

  @override
  State<ContractSignatureScreen> createState() => _ContractSignatureScreenState();
}

class _ContractSignatureScreenState extends State<ContractSignatureScreen> {
  bool _isLoading = false;
  bool _agreedToTerms = false;
  String? _contractContent;

  @override
  void initState() {
    super.initState();
    _fetchContract();
  }

  Future<void> _fetchContract() async {
    setState(() => _isLoading = true);
    // Simulação de busca do contrato no backend
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _contractContent = _getPlaceholderContract();
      _isLoading = false;
    });
  }

  void _signContract() {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você precisa aceitar os termos para assinar o contrato.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    // Simulação de chamada ao backend para assinar
    Future.delayed(const Duration(seconds: 2), () {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contrato assinado com sucesso! Bem-vindo(a)!'),
          backgroundColor: Colors.green,
        ),
      );
      // Redireciona para a tela principal após assinatura
      context.go('/home'); 
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contrato de Associação'),
        automaticallyImplyLeading: false, // Remove a seta de voltar
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _isLoading && _contractContent == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Por favor, leia e aceite os termos abaixo para ativar sua conta como Super Associado.',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).dividerColor),
                          borderRadius: BorderRadius.circular(8),
                          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            _contractContent ?? 'Não foi possível carregar o contrato.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    CheckboxListTile(
                      title: const Text('Li e concordo com todos os termos do contrato'),
                      value: _agreedToTerms,
                      onChanged: (bool? value) {
                        setState(() {
                          _agreedToTerms = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      tileColor: Theme.of(context).inputDecorationTheme.fillColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: (_agreedToTerms && !_isLoading) ? _signContract : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading 
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Assinar Contrato e Ativar Conta'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  String _getPlaceholderContract() {
    return """
CONTRATO DE PRESTAÇÃO DE SERVIÇOS DE ADVOGADO ASSOCIADO - PLATAFORMA LITGO

Pelo presente instrumento particular, de um lado, [NOME DA PLATAFORMA], pessoa jurídica de direito privado, inscrita no CNPJ sob o nº XX.XXX.XXX/0001-XX, com sede na [Endereço da Plataforma], doravante denominada CONTRATANTE, e de outro lado, [NOME DO ADVOGADO], inscrito(a) na OAB/[UF] sob o nº XXXXX, CPF nº XXX.XXX.XXX-XX, residente e domiciliado(a) na [Endereço do Advogado], doravante denominado(a) CONTRATADO(A), celebram o presente Contrato de Associação, que se regerá pelas seguintes cláusulas e condições:

CLÁUSULA PRIMEIRA - DO OBJETO
1.1. O presente contrato tem como objeto a associação do(a) CONTRATADO(A) à CONTRATANTE, para a prestação de serviços advocatícios nos casos que lhe forem encaminhados através da plataforma tecnológica LITGO, sem qualquer vínculo empregatício, nos termos do artigo 39 do Regulamento Geral do Estatuto da Advocacia e da OAB.

CLÁUSULA SEGUNDA - DAS OBRIGAÇÕES DO CONTRATADO(A)
2.1. Atuar com zelo, dedicação e ética profissional em todos os casos aceitos através da plataforma.
2.2. Manter suas informações cadastrais e documentais sempre atualizadas na plataforma.
2.3. Respeitar os prazos e metas de qualidade de serviço (SLA) estabelecidos pela CONTRATANTE para cada tipo de caso.
2.4. Manter sigilo absoluto sobre todas as informações de clientes e casos aos quais tiver acesso.

CLÁUSULA TERCEIRA - DAS OBRIGAÇÕES DA CONTRATANTE
3.1. Disponibilizar ao(à) CONTRATADO(A) o acesso à sua plataforma tecnológica para recebimento de ofertas de casos.
3.2. Realizar o repasse dos honorários devidos ao(à) CONTRATADO(A) nos termos da Cláusula Quarta.
3.3. Fornecer o suporte técnico necessário para a utilização da plataforma.

CLÁUSULA QUARTA - DOS HONORÁRIOS
4.1. Pelos serviços prestados, o(a) CONTRATADO(A) fará jus a uma participação nos honorários de cada caso, cujo percentual será claramente especificado na "oferta do caso" antes de seu aceite.
4.2. Os honorários serão repassados ao(à) CONTRATADO(A) em até 10 (dez) dias úteis após o efetivo recebimento dos valores pagos pelo cliente final.

CLÁUSULA QUINTA - DA VIGÊNCIA E RESCISÃO
5.1. O presente contrato vigorará por prazo indeterminado, a partir da data de sua assinatura eletrônica.
5.2. O contrato poderá ser rescindido por qualquer das partes, a qualquer tempo, mediante notificação prévia de 30 (trinta) dias, sem qualquer ônus ou penalidade, ressalvando-se a conclusão dos casos já em andamento.

E, por estarem assim justas e contratadas, as partes assinam eletronicamente o presente instrumento.

[Local], [Data].

_________________________________________
[NOME DA PLATAFORMA]

_________________________________________
[NOME DO ADVOGADO]
    """;
  }
} 