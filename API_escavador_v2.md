

API V2
Pesquisar
Visão geral
API do Escavador
Saldo
Callbacks
Versões
Autenticação
Bibliotecas
Painel da API
Guias
Atualização de processos
Callback
Consulta de processos
Monitoramento de novos processos
Monitoramento de processos
Resumo de processos (IA)
Tribunais
Estrutura das respostas
Detalhes dos Callbacks
Documentação Desenvolvida por Escavador
Visão geral
API do Escavador
Bem vindo à API do Escavador!

O Escavador coleta e compila dados públicos disponíveis em fontes oficiais, desde Diários Oficiais a Tribunais do poder judiciário de todo o Brasil. Integre a API do Escavador ao seu sistema e tenha acesso a informações públicas de pessoas, empresas e processos, disponibilizadas de maneira estruturada.

Ao lado direito da página são exibidos exemplos da utilização de cada endpoint da API em bash e nas linguagens javascript, php e python.

O limite de requisições no uso da API é de 500 requisições por minuto.

Para mais informações, fale conosco.

Saldo
É possível encontrar o custo em centavos de uma requisição no header Creditos-Utilizados, presente na resposta. Visite a página de histórico para saber como consultar seu saldo. Consulte também a página de preços para saber mais sobre os custos de cada versão.

Callbacks
Na API V2, é possível receber callbacks para diversos eventos, como o callback associado a uma solicitação de atualização de um processo. Para fazer uso dessa funcionalidade, é necessário configurar uma URL de callback no painel da API. Acesse nosso guia sobre configuração da URL de callback para saber mais.

Versões
A API do Escavador possui duas versões: V1 e V2. Você pode encontrar mais informações sobre cada uma delas abaixo. Além disso, consulte a página de preços para saber mais sobre os custos de cada versão. É importante identificar quais recursos da API você irá utilizar para escolher a versão mais adequada. Agende uma reunião com nossa equipe de vendas para tirar dúvidas e conhecer melhor a API.

API V1
A API V1 conta com funcionalidades de busca e monitoramento de processos, pessoas e empresas, além de consulta e monitoramento em diários oficiais.

API Endpoint: https://api.escavador.com/api/v1

Para acessar a documentação da V1 da API clique aqui.

API V2
A API V2 conta com a funcionalidade de busca de processos, se diferenciando da V1 por ter uma maior quantidade de informações estruturadas de forma mais detalhada.

API Endpoint: https://api.escavador.com/api/v2

Para acessar a documentação da V2 da API clique aqui.

Postman
Caso utilize o Postman para realizar os testes, você pode baixar essa collection para o Postman.

Autenticação
Solicitar Token de Acesso pelo Painel
A API do Escavador utiliza Bearer Token para autenticação de usuários. O Bearer Token é um método de autenticação que envolve o uso de um token alfanumérico enviado junto com as solicitações para a API. Esse token é adicionado ao cabeçalho HTTP da solicitação, no campo "Authorization". Ele garante que apenas usuários autorizados tenham acesso aos recursos da API. Para isso, é necessário ter uma conta na plataforma. Você pode fazer isso acessando aqui.

Bibliotecas
Python
Possuimos um SDK em python com suporte para ambas as versões da API, Para entender como utilizar o SDK, consulte nosso repositório no github.

Painel da API
O painel da API do Escavador é uma ferramenta que facilita o gerenciamento do seu uso da API, lá você pode acessar:

Historico de requisições
Gerenciamento de tokens
Configuração e monitoramento de Callbacks
Recarga de créditos
Visualização de monitoramentos de tribunais e diarios oficiais
Faturas
Preços das rotas
Guias
Autenticando na API
Acesse o painel da API na página de gestão de tokens. Clique no botão + Criar Token, forneça um nome para seu token e logo depois certifique-se de copiar o token gerado, pois ele não será exibido novamente. Use o token gerado no cabeçalho das requisições para ser autenticado pela API.
O painel de tokens oferece uma gestão melhor de seus tokens de acesso, informando o nome, data de criação, vida útil e o recurso de revogar seus tokens.

Com o token gerado, basta enviar o header Authorization com o valor Bearer {seu-token-gerado}, desta forma, iremos autenticar sua requisição.

Configurando uma URL de callback
Como dito anteriormente, é possível configurar um URL de callback para receber callbacks da API do Escavador. Para isso acesse a página de callbacks, no painel da API, lá você pode informar a URL de callback, assim, para monitoramentos ou buscas assíncronas, quando novos eventos ou resultados forem gerados, eles serão enviados para a URL configurada.

Gerando um token para validar callbacks da API
Com a URL de callbacks configurada, é importante que você valide se o callback é de fato da API do Escavador. Para isso basta gerar um token de segurança no painel da API, com isso, ao receber novos callbacks do Escavador, você pode validar se o token enviado é o mesmo que você gerou. Nós enviamos o token pelo header Authorization.

Paginação
Algumas rotas da API utilizam paginação para retornar os resultados, pois, é possivel que muitas informações sejam retornadas. Além disso, para navegar pelos resultados, basta acessar os links gerados no campo da paginação.

Atualização de processos
Status de uma atualização de processo
Retorna o status de uma solicitação de atualização de um processo. Se nenhuma solicitação foi criada, retorna o status de atualização do processo.

Caso uma solicitação de processo tenha sido criada, esses são os possíveis status da solicitação:

Acesse a página de respostas para detalhes sobre os dados retornados.

Exemplo de requisição:

import requests
import json

url = 'https://api.escavador.com/api/v2/processos/numero_cnj/0018063-19.2013.8.26.0002/status-atualizacao'

headers = {
  'Authorization': 'Bearer {access_token}',
  'X-Requested-With': 'XMLHttpRequest'
}

response = requests.request('GET', url, headers=headers)

if response and response.text:
  parsed = json.loads(response.text)
  print(json.dumps(parsed, indent=4))
// Esse é um exemplo de resposta bem-sucedida de um processo sem solicitação de atualização.
Exemplo de resposta (200):

{
  "numero_cnj": "0000000-00.0000.0.00.0000",
  "data_ultima_verificacao": "2023-03-02T21:31:56+00:00",
  "tempo_desde_ultima_verificacao": "há 2 meses",
  "ultima_verificacao": null
}
// Esse é um exemplo de resposta bem-sucedida de um processo com solicitação de atualização.
Exemplo de resposta (200):

{
  "numero_cnj": "0000000-00.0000.0.00.0000",
  "data_ultima_verificacao": "2023-03-02T21:31:56+00:00",
  "tempo_desde_ultima_verificacao": "há 2 meses",
  "ultima_verificacao": {
    "id": 1,
    "status": "PENDENTE",
    "criado_em": "2023-05-10T18:54:24+00:00",
    "concluido_em": "2023-05-10T18:54:24+00:00"
  }
}
// Esse é um exemplo de resposta bem-sucedida de um processo com solicitação de atualização concluida.
Exemplo de resposta (200):

{
  "numero_cnj": "0000000-00.0000.0.00.0000",
  "data_ultima_verificacao": "2023-05-10T18:56:24+00:00",
  "tempo_desde_ultima_verificacao": "há 1 minuto",
  "ultima_verificacao": {
    "id": 1,
    "status": "SUCESSO",
    "criado_em": "2023-05-10T18:54:24+00:00",
    "concluido_em": "2023-05-10T18:56:33+00:00"
  }
}
// Esse é um exemplo de resposta bem-sucedida de um processo não encontrado.
Exemplo de resposta (200):

{
  "numero_cnj": "0000000-00.0000.0.00.0000",
  "data_ultima_verificacao": null,
  "tempo_desde_ultima_verificacao": null,
  "ultima_verificacao": null
}
Exemplo de resposta (401):

{
  "error": "Unauthenticated"
}
Exemplo de resposta (402):

{
  "error": "Você não possui saldo em crédito da API."
}
Exemplo de resposta (404):

{
  "error": "NotFound"
}
HTTP Request
GET api/v2/processos/numero_cnj/{numero}/status-atualizacao

Headers
Campo	Valor
Authorization	Bearer {access_token}
X-Requested-With	XMLHttpRequest
URI Parameters
Parâmetro	Tipo	Descrição
numero	string	Número único do processo. Obrigatório estar no formato de CNJ.
Exemplo: 0000000-00.0000.0.00.0000
Status de atualização do Processo
Campo	Descrição
PENDENTE	Aguardando o robô ir buscar as informações no Tribunal.
SUCESSO	Atualizou no Tribunal corretamente.
NAO_ENCONTRADO	O robô não encontrou o processo no sistema do Tribunal (Processo físico, segredo de justiça, arquivado, etc).
ERRO	Teve alguma falha ao tentar atualizar o processo.
Solicitar atualização de um processo
Solicita a inclusão ou atualização de um processo nos sistemas dos Tribunais, para obter as informações mais recentes.

Acesse a página de respostas para detalhes sobre os dados retornados.

Exemplo de requisição:

import requests
import json

url = 'https://api.escavador.com/api/v2/processos/numero_cnj/0018063-19.2013.8.26.0002/solicitar-atualizacao'

payload = {
  'enviar_callback': '1',
  'documentos_publicos': '1'
}

headers = {
  'Authorization': 'Bearer {access_token}',
  'X-Requested-With': 'XMLHttpRequest',
  'Content-Type': 'application/json'
}

response = requests.request('POST', url, headers=headers, json=payload)

if response and response.text:
  parsed = json.loads(response.text)
  print(json.dumps(parsed, indent=4))
// Esse é um exemplo de resposta bem-sucedida.
Exemplo de resposta (200):

{
  "id": 125,
  "status": "PENDENTE",
  "numero_cnj": "0000000-00.0000.0.00.0000",
  "criado_em": "2023-05-10T19:09:43+00:00",
  "concluido_em": null
}
Exemplo de resposta (401):

{
  "error": "Unauthenticated"
}
Exemplo de resposta (402):

{
  "error": "Você não possui saldo em crédito da API."
}
Exemplo de resposta (404):

{
  "error": "NotFound"
}
HTTP Request
POST api/v2/processos/numero_cnj/{numero}/solicitar-atualizacao

Headers
Campo	Valor
Authorization	Bearer {access_token}
X-Requested-With	XMLHttpRequest
Content-Type	application/json
URI Parameters
Parâmetro	Tipo	Descrição
numero	string	Número único do processo. Obrigatório estar no formato de CNJ.
Exemplo: 0000000-00.0000.0.00.0000
Body Parameters
Parâmetro	Tipo	Status	Descrição
enviar_callback	integer	opcional	Se enviar_callback=1 será enviado um callback quando o processo for atualizado. Obrigatório ter uma url de callback.
documentos_publicos	integer	opcional	Se documentos_publicos=1 será baixado os documentos públicos do processo
Callback
Retornar os callbacks
Grátis
Consultar todos os callbacks recebidos pela API.

Exemplo de requisição:

from escavador import *
import datetime
config("API_KEY")

response = Callback().callbacks(
  data_maxima=datetime.datetime(2019, 10, 23, 7, 1, 22),
  data_minima=datetime.datetime(2019, 9, 23, 7, 1, 22),
  evento="resultado_busca_assincrona",
  item_tipo="busca_assincrona",
  item_id=100,
  status=StatusCallback.SUCESSO
)
Exemplo de resposta (200):

{
  "paginator": {
    "total": 2,
    "total_pages": 1,
    "current_page": 1,
    "per_page": 20
  },
  "links": {
    "prev": null,
    "next": null
  },
  "items": [
    {
      "id": 1,
      "uuid": "027efc36e537d8f9b89c73869b69c941",
      "usuario_id": 1,
      "objeto_id": 1,
      "objeto_type": "ApiMonitoramento",
      "url": "http://api.teste.com/webhook",
      "attempts": 11,
      "next_run_at": "2018-01-18 19:57:44",
      "delivered_at": null,
      "created_at": "2018-01-16 22:38:19",
      "updated_at": "2018-01-18 19:57:44",
      "resultado": {
        "event": "update_time",
        "event_data": {
          "updated_at": "05/08/2023 05:18:24"
        },
        "app": {
          "id": 1,
          "vip": true,
          "monitor": {
            "origens": [
              "TRF5"
            ],
            "tipo": "UNICO",
            "valor": "0000000-00.0000.0.00.0000",
            "frequencia": "SEMANAL",
            "cron": "28 16 * * 4",
            "status": "FOUND",
            "incluir_docpub": false,
            "incluir_autos": false
          },
          "created_at": "21/03/2023 19:45:55",
          "frequencia": "SEMANAL"
        },
        "processo": {
          "origem": "TRF5",
          "instancia": "PRIMEIRO_GRAU",
          "extra_instancia": "",
          "sistema": "PJE",
          "numero_unico": "0000000-00.0000.0.00.0000"
        },
        "uuid": "027efc36e537d8f9b89c73869b69c941"
      },
      "status": "Em tentativa"
    },
    {
      "id": 2,
      "uuid": "d4e07ee0de82864c32c218e04f7e41ef",
      "usuario_id": 2,
      "objeto_id": 3,
      "objeto_type": "ApiAsync",
      "evento": "resultado_processo_async",
      "url": "https://api.teste.com/webhook",
      "attempts": 0,
      "next_run_at": null,
      "delivered_at": "2022-08-15 18:16:37",
      "created_at": "2022-08-15 18:16:37",
      "updated_at": "2022-08-15 18:16:37",
      "resultado": {
        "id": 1,
        "created_at": {
          "date": "2022-08-15 18:16:24",
          "timezone_type": 3,
          "timezone": "UTC"
        },
        "enviar_callback": "SIM",
        "link_api": "https://api.escavador.com/api/v1/async/resultados/1",
        "numero_processo": "0000000-00.0000.0.00.0000",
        "resposta": {
          "numero_unico": "0000000-00.0000.0.00.0000",
          "origem": "TRT-5",
          "instancias": [
            {
              "url": null,
              "sistema": "PJE",
              "instancia": "PRIMEIRO_GRAU",
              "extra_instancia": "",
              "segredo": false,
              "numero": null,
              "assunto": "Piso Salarial da Categoria / Salário Mínimo Profissional",
              "classe": "Ação Trabalhista - Rito Ordinário",
              "area": "Trabalhista",
              "data_distribuicao": "29/10/2018",
              "orgao_julgador": "27ª Vara do Trabalho de Salvador",
              "moeda_valor_causa": null,
              "valor_causa": null,
              "arquivado": false,
              "data_arquivamento": null,
              "fisico": null,
              "last_update_time": "15/08/2022 18:12",
              "situacoes": [],
              "dados": [
                {
                  "tipo": "Outros Assuntos",
                  "valor": "Acordo e Convenção Coletivos de Trabalho\nAjuda / Tíquete Alimentação\nAviso Prévio\nContrato Individual de Trabalho\nDIREITO DO TRABALHO\nDIREITO PROCESSUAL CIVIL E DO TRABALHO\nDepósito / Diferença de Recolhimento\nDescontos Salariais - Devolução\nDireito Coletivo\nDuração do Trabalho\nExpurgos Inflacionários\nFGTS\nHoras Extras\nIndenização\nLevantamento / Liberação\nMulta Convencional\nMulta Prevista em Norma Coletiva\nMulta de 40% do FGTS\nMulta do Art. 475-J do CPC\nMulta do Artigo 467 da CLT\nMulta do Artigo 477 da CLT\nPenalidades Processuais\nReflexos\nRemuneração, Verbas Indenizatórias e Benefícios\nRepouso Semanal Remunerado e Feriado\nRescisão do Contrato de Trabalho\nSalário / Diferença Salarial\nSeguro Desemprego\nVerbas Rescisórias"
                }
              ],
              "partes": [
                {
                  "id": 1,
                  "tipo": "AUTOR",
                  "nome": "ANTONIO",
                  "principal": true,
                  "polo": "ATIVO",
                  "documento": {
                    "tipo": "CPF",
                    "numero": "00000000000"
                  }
                },
                {
                  "id": 2,
                  "tipo": "ADVOGADO",
                  "nome": "Walter",
                  "principal": true,
                  "polo": "ATIVO",
                  "documento": {
                    "tipo": "CPF",
                    "numero": "00000000000"
                  },
                  "advogado_de": 1,
                  "oabs": [
                    {
                      "numero": "1234",
                      "uf": "BA"
                    }
                  ]
                },
                {
                  "id": 3,
                  "tipo": "RÉU",
                  "nome": "DISTRIBUIDORA S/A",
                  "principal": true,
                  "polo": "PASSIVO",
                  "documento": {
                    "tipo": "CNPJ",
                    "numero": "00000000000000"
                  }
                }
              ],
              "movimentacoes": [
                {
                  "id": 4,
                  "data": "10/08/2022",
                  "conteudo": "Decorrido o prazo de ANTONIO em 09/08/2022"
                },
                {
                  "id": 3,
                  "data": "09/08/2022",
                  "conteudo": "Disponibilizado\n(a) o(a) intimação no Diário da Justiça Eletrônico"
                },
                {
                  "id": 2,
                  "data": "09/08/2022",
                  "conteudo": "Publicado(a) o(a) intimação em 09/08/2022"
                },
                {
                  "id": 1,
                  "data": "08/08/2022",
                  "conteudo": "Expedido(a) intimação a(o) DISTRIBUIDORA S/A"
                }
              ],
              "audiencias": [
                {
                  "data": "12/02/2019 15:06",
                  "audiencia": "",
                  "situacao": "Realizada",
                  "numero_pessoas": 0
                }
              ]
            }
          ]
        },
        "status": "SUCESSO",
        "status_callback": null,
        "tipo": "BUSCA_PROCESSO",
        "tribunal": {
          "sigla": "TRT-5",
          "nome": "TRT da 5ª Região",
          "busca_processo": 1,
          "busca_nome": 0,
          "busca_oab": 0,
          "disponivel_autos": 1,
          "busca_documento": 1
        },
        "valor": "0000000-00.0000.0.00.0000",
        "event": "resultado_processo_async",
        "uuid": "d4e07ee0de82864c32c218e04f7e41ef"
      },
      "status": "Sucesso"
    },
    {
      "id": 3,
      "uuid": "0ab19863f3050147808331b3f16a15eb",
      "usuario_id": 2,
      "objeto_id": 3,
      "objeto_type": "Monitoramento",
      "evento": "diario_movimentacao_nova",
      "url": "https://api.teste.com/webhook",
      "attempts": 11,
      "next_run_at": null,
      "delivered_at": "2023-06-07 16:15:06",
      "created_at": "2023-06-04 16:46:08",
      "updated_at": "2023-06-07 16:15:06",
      "resultado": {
        "event": "diario_movimentacao_nova",
        "monitoramento": [
          {
            "id": 1,
            "processo_id": 1,
            "tribunal_processo_id": null,
            "pasta_id": null,
            "nome": null,
            "termo": "0000000-00.0000.0.00.0000",
            "categoria": "",
            "tipo": "PROCESSO",
            "alertar_apenas_novo_processo": 0,
            "limite_aparicoes": null,
            "enviar_email_principal": 1,
            "origem_criacao": null,
            "desativado": "NAO",
            "desativado_motivo": null,
            "bloqueado_ate": null,
            "nao_monitorar_ate": null,
            "api": "SIM",
            "dados_adicionais": null,
            "data_ultima_aparicao": {
              "date": "2023-06-01 00:00:00",
              "timezone_type": 3,
              "timezone": "UTC"
            },
            "descricao": "Processo nº 0000000-00.0000.0.00.0000",
            "aparicoes_nao_visualizadas": 1,
            "quantidade_aparicoes_mes": 1,
            "bloqueado_temporariamente": null,
            "oab_principal": null,
            "numero_diarios_monitorados": 171,
            "numero_diarios_disponiveis": 173,
            "tribunal_sigla": null,
            "tribunal_disponivel": true,
            "usuario_pode_visualizar": true,
            "quantidade_aparicoes_por_tipo": {
              "tribunal": [],
              "diario": 1
            },
            "quantidade_aparicoes_nao_visualizadas_por_tipo": {
              "tribunal": [],
              "diario": 1,
              "referencias": 0
            },
            "quantidade_sugestoes_nao_verificadas": 0,
            "termos_auxiliares": [],
            "processo": {
              "id": 1,
              "numero_antigo": null,
              "numero_novo": "0000000-00.0000.0.00.0000",
              "is_cnj": 1,
              "enviado_trimon_em": "2022-01-22 23:26:17",
              "created_at": null,
              "updated_at": "2023-06-04 16:31:01",
              "origem_tribunal_id": 26,
              "filtrado_em": null,
              "enviado_nursery_em": null,
              "link": "https://www.escavador.com/processos/852608/processo-0001260-9020135150042-do-trt-da-15-regiao",
              "link_api": "https://api.escavador.com/api/v1/processos/1",
              "data_movimentacoes": "16/07/2013 a 01/06/2023",
              "data_primeira_movimentacao": "16/07/2013",
              "url": {
                "id": 1,
                "slug": "processo-00000000000000000-do-trt-da-15-regiao",
                "objeto_type": "Processo",
                "objeto_id": 1,
                "redirect": 12,
                "created_at": null,
                "anuncio_ocultado_em": null
              }
            }
          }
        ],
        "movimentacao": {
          "id": 1,
          "secao": "Secretaria da Segunda Turma",
          "texto_categoria": "",
          "diario_oficial_id": 1,
          "processo_id": 1,
          "pagina": 4553,
          "complemento": null,
          "tipo": "Agravo de Instrumento em Recurso de Revista",
          "subtipo": null,
          "conteudo": "<p><font class=\"\"><b>complemento:</b> Complemento Processo Eletrônico</font></p><div>",
          "data": "2023-06-01T00:00:00.000000Z",
          "letras_processo": "",
          "subprocesso": null,
          "elasticsearch_status": "NOT_INDEXED",
          "created_at": "2023-06-04 16:31:01",
          "updated_at": "2023-06-04 16:31:01",
          "descricao_pequena": "Movimentação do processo 0000000-00.0000.0.00.0000",
          "diario_oficial": "01/06/2023 | TST - Judiciário",
          "estado": "Brasil",
          "envolvidos": [
            {
              "id": 1,
              "nome": "Maria",
              "objeto_type": "Pessoa",
              "pivot_tipo": "RELATOR",
              "pivot_outros": "NAO",
              "pivot_extra_nome": "Min.",
              "link": "https://www.escavador.com/sobre/1/maria",
              "link_api": "https://api.escavador.com/api/v1/pessoas/1",
              "nome_sem_filtro": "Maria",
              "envolvido_tipo": "Relator",
              "envolvido_extra_nome": "Min.",
              "oab": "",
              "advogado_de": null
            }
          ],
          "link": "https://www.escavador.com/diarios/0000000/TST/J/2023-06-01/1/movimentacao-do-processo-0000000-0000000000000",
          "link_api": "https://api.escavador.com/api/v1/movimentacoes/1",
          "data_formatada": "01/06/2023",
          "objeto_type": "Movimentacao",
          "link_pdf": "https://www.escavador.com/diarios/00000/TST/J/2023-06-01/pdf/baixar?page=4553",
          "link_pdf_api": "https://api.escavador.com/api/v1/diarios/000000/pdf/pagina/4553/baixar",
          "snippet": "conteudo do snippet",
          "processo": {
            "id": 1,
            "numero_antigo": null,
            "numero_novo": "0000000-00.0000.0.00.0000",
            "is_cnj": 1,
            "enviado_trimon_em": "2022-01-22 23:26:17",
            "created_at": null,
            "updated_at": "2023-06-04 16:31:01",
            "origem_tribunal_id": 26,
            "filtrado_em": null,
            "enviado_nursery_em": null,
            "link": "https://www.escavador.com/processos/852608/processo-0000000-0000000000000-do-trt-da-15-regiao",
            "link_api": "https://api.escavador.com/api/v1/processos/1",
            "data_movimentacoes": "16/07/2013 a 01/06/2023",
            "data_primeira_movimentacao": "16/07/2013",
            "url": {
              "id": 1,
              "slug": "processo-0000000-0000000000000-do-trt-da-15-regiao",
              "objeto_type": "Processo",
              "objeto_id": 1,
              "redirect": 12,
              "created_at": null,
              "anuncio_ocultado_em": null
            }
          },
          "diario": {
            "id": 1,
            "path": "",
            "origem_id": 1,
            "plugin": "TRT",
            "edicao": "3734/2023",
            "tipo": "Judiciário",
            "tipo_url": "J",
            "tipo_ocr": "OCR_1",
            "tipo_exibicao": "MOVIMENTACOES",
            "data": "2023-06-01",
            "data_disponibilizacao": null,
            "data_publicacao": "2023-06-01",
            "qtd_paginas": 9292,
            "pdf_key": null,
            "pdf_key_backblaze": "diarios",
            "pdf_pages": 9292,
            "external_storage_id": 1890431,
            "created_at": "2023-06-04 16:28:24",
            "elasticsearch_status": "NOT_INDEXED",
            "atena_status": "INDEXED",
            "vespa_ultima_indexacao": "2023-06-04 16:40:08",
            "descricao": "Tribunal Superior do Trabalho",
            "objeto_type": "Diario",
            "origem": {
              "id": 3,
              "nome": "Tribunal Superior do Trabalho",
              "sigla": "TST",
              "tipo": null,
              "db": "JURIDICO",
              "estado": "Brasil-TST",
              "competencia": "Brasil",
              "categoria": "Diários do Judiciário",
              "created_at": "2015-10-14T05:28:45.000000Z",
              "updated_at": "2015-10-14T05:28:45.000000Z"
            }
          },
          "url": {
            "id": 1,
            "slug": "movimentacao-do-processo-0000000-0000000000000",
            "objeto_type": "Movimentacao",
            "objeto_id": 1,
            "redirect": null,
            "created_at": "2023-06-04T16:31:01.000000Z",
            "anuncio_ocultado_em": null
          }
        },
        "uuid": "0ab19863f3050147808331b3f16a15eb"
      },
      "status": "Sucesso"
    }
  ]
}
Exemplo de resposta (401):

{
  "error": "Unauthenticated"
}
Exemplo de resposta (404):

{
  "error": "NotFound"
}
HTTP Request
GET api/v2/callbacks

Headers
Campo	Valor
Authorization	Bearer {access_token}
X-Requested-With	XMLHttpRequest
Query Parameters
Parâmetro	Status	Descrição
data_maxima	opcional	Data e hora (em UTC) máxima dos callbacks listados.
data_minima	opcional	Data e hora (em UTC) mínima dos callbacks listados.
evento	opcional	Evento que gerou o callback.
Obrigatório o uso do item_tipo e item_id
item_tipo	opcional	Tipo do item relacionado ao callback.
Valores permitidos: busca_assincrona, monitoramento_tribunal, monitoramento_diario
item_id	opcional	Id do item relacionado ao callback.
Obrigatório o uso do item_tipo
status	opcional	Status do callback.
Valores permitidos: sucesso, em_tentativa, erro
Marcar callbacks como recebidos
Grátis
Marca os callbacks enviados pela API como recebidos.

Exemplo de requisição:

from escavador import *
config("API_KEY")

response = Callback().marcarRecebido(
  ids=[1,2,3]
)
Exemplo de resposta (200):

[]
HTTP Request
POST api/v2/callbacks/marcar-recebidos

Headers
Campo	Valor
Authorization	Bearer {access_token}
X-Requested-With	XMLHttpRequest
Content-Type	application/json
Body Parameters
Parâmetro	Tipo	Status	Descrição
ids	int[]	obrigatório	Os ids dos callbacks que foram recebidos, máximo de 20 por vez. Os callbacks que estão em tentativa (next_run_at diferente de null) não podem ser marcados como recebidos.
Reenviar callback
Grátis
Reenvia o callback informado.

Exemplo de requisição:

from escavador import *
config("API_KEY")

response = Callback().reenviar(
  id=1
)
Exemplo de resposta (200):

{
  "message": "Callback reenviado com sucesso!"
}
Exemplo de resposta (422):

{
  "error": "Unauthenticated"
}
Exemplo de resposta (401):

{
  "error": "Unauthenticated"
}
Exemplo de resposta (404):

{
  "error": "NotFound"
}
HTTP Request
POST api/v2/callbacks/{id}/reenviar

Headers
Campo	Valor
Authorization	Bearer {access_token}
X-Requested-With	XMLHttpRequest
URI Parameters
Parâmetro	Tipo	Descrição
id	integer	O id do callback que será reenviado.
Atenção: Callbacks que estão sendo enviados (em tentativa), não podem ser reenviados.
Consulta de processos
Processo por numeração CNJ
Retorna dados da capa de um processo a partir da numeração CNJ.

Exemplo de requisição:

from escavador import *
from escavador.v2 import Processo
config("API_KEY")

response = Processo.por_numero(
  numero_cnj="0000000-00.0000.0.00.0000" # também aceita formato "00000000000000000000"
)
// Esse é um exemplo de resposta bem-sucedida.
Exemplo de resposta (200):

{
  "numero_cnj": "1024000-20.2015.2.23.0000",
  "titulo_polo_ativo": "Maria da Conceição de Oliveira",
  "titulo_polo_passivo": "João da Silva",
  "ano_inicio": 2015,
  "data_inicio": "2015-11-21",
  "estado_origem": {
    "nome": "São Paulo",
    "sigla": "SP"
  },
  "unidade_origem": {
    "nome": "FORO ESPECIALIZADO DA 1ª RAJ",
    "cidade": "São Paulo",
    "estado": {
      "nome": "São Paulo",
      "sigla": "SP"
    },
    "tribunal_sigla": "TJSP"
  },
  "data_ultima_movimentacao": "2018-07-25",
  "quantidade_movimentacoes": 103,
  "fontes_tribunais_estao_arquivadas": false,
  "data_ultima_verificacao": "2023-02-09T14:30:11+00:00",
  "tempo_desde_ultima_verificacao": "há 1 mês",
  "processos_relacionados": [
    {
      "numero": "8027909-02.2019.8.05.0000"
    },
    {
      "numero": "8028150-73.2019.8.05.0000"
    }
  ],
  "fontes": [
    {
      "id": 3,
      "processo_fonte_id": 14626,
      "descricao": "TJSP - 1º grau",
      "nome": "Tribunal de Justiça de São Paulo",
      "sigla": "TJSP",
      "tipo": "TRIBUNAL",
      "data_inicio": "2015-11-27",
      "data_ultima_movimentacao": "2018-07-25",
      "segredo_justica": null,
      "arquivado": null,
      "status_predito": "INATIVO",
      "grau": 1,
      "grau_formatado": "Primeiro Grau",
      "fisico": false,
      "sistema": "ESAJ",
      "capa": {
        "classe": "PROCEDIMENTO COMUM CIVEL",
        "assunto": "RESPONSABILIDADE CIVIL",
        "assuntos_normalizados": [
          {
            "id": 3642,
            "nome": "Responsabilidade Civil",
            "nome_com_pai": "DIREITO CIVIL > Responsabilidade Civil",
            "path_completo": "DIREITO CIVIL | Responsabilidade Civil",
            "bloqueado": false
          }
        ],
        "assunto_principal_normalizado": {
          "id": 3642,
          "nome": "Responsabilidade Civil",
          "nome_com_pai": "DIREITO CIVIL > Responsabilidade Civil",
          "path_completo": "DIREITO CIVIL | Responsabilidade Civil",
          "bloqueado": false
        },
        "area": "CIVEL",
        "orgao_julgador": "7ª VARA CIVEL",
        "situacao": "Baixado",
        "valor_causa": {
          "valor": "50000.0000",
          "moeda": "R$",
          "valor_formatado": "R$ 50.000,00"
        },
        "data_distribuicao": "2015-11-27",
        "data_arquivamento": null,
        "informacoes_complementares": null
      },
      "audiencias": [
        {
          "tipo": "Instrução",
          "data": "2024-10-17",
          "quantidade_pessoas": 2,
          "situacao": "Cancelada"
        }
      ],
      "url": "https://esaj.tjsp.jus.br/cpopg/search.do?conversationId=&dadosConsulta.localPesquisa.cdLocal=-1&cbPesquisa=NUMPROC&dadosConsulta.tipoNuProcesso=UNIFICADO&numeroDigitoAnoUnificado=1024000-20.2015&foroNumeroUnificado=0000&dadosConsulta.valorConsultaNuUnificado=1024000-20.2015.2.23.0000&dadosConsulta.valorConsulta=",
      "tribunal": {
        "id": 102,
        "nome": "Tribunal de Justiça de São Paulo",
        "sigla": "TJSP",
        "categoria": null
      },
      "quantidade_movimentacoes": 68,
      "quantidade_envolvidos": 7,
      "data_ultima_verificacao": "2023-02-09T14:30:11+00:00",
      "envolvidos": [
        {
          "nome": "Maria da Conceição de Oliveira",
          "quantidade_processos": 1,
          "tipo_pessoa": "FISICA",
          "advogados": [
            {
              "nome": "Marta Brandao de Oliveira",
              "quantidade_processos": 21,
              "tipo_pessoa": "FISICA",
              "prefixo": null,
              "sufixo": null,
              "tipo": "ADVOGADO",
              "tipo_normalizado": "Advogado",
              "polo": "ADVOGADO",
              "cpf": "00000000000",
              "nome_normalizado": "Marta Brandao de Oliveira",
              "oabs": [
                {
                  "uf": "SP",
                  "tipo": "ADVOGADO",
                  "numero": 123123
                }
              ]
            },
            {
              "nome": "Fernando Marçal",
              "quantidade_processos": 10,
              "tipo_pessoa": "FISICA",
              "prefixo": null,
              "sufixo": null,
              "tipo": "ADVOGADO",
              "tipo_normalizado": "Advogado",
              "polo": "ADVOGADO",
              "cpf": "00000000000",
              "nome_normalizado": "Fernando Marçal",
              "oabs": [
                {
                  "uf": "SP",
                  "tipo": "ADVOGADO",
                  "numero": 123123
                }
              ]
            }
          ],
          "prefixo": null,
          "sufixo": null,
          "tipo": "REQUERENTE",
          "tipo_normalizado": "Requerente",
          "polo": "ATIVO",
          "cpf": "00000000000",
          "nome_normalizado": "Maria da Conceição de Oliveira"
        },
        {
          "nome": "Joao da Silva",
          "quantidade_processos": 97,
          "tipo_pessoa": "FISICA",
          "advogados": [
            {
              "nome": "Antonio Carlos de Souza",
              "quantidade_processos": 37,
              "tipo_pessoa": "FISICA",
              "prefixo": null,
              "sufixo": null,
              "tipo": "ADVOGADO",
              "tipo_normalizado": "Advogado",
              "polo": "ADVOGADO",
              "cpf": "00000000000",
              "nome_normalizado": "Antonio Carlos de Souza",
              "oabs": [
                {
                  "uf": "SP",
                  "tipo": "ADVOGADO",
                  "numero": 123123
                }
              ]
            },
            {
              "nome": "Fabiane Santos Carvalho",
              "quantidade_processos": 33,
              "tipo_pessoa": "FISICA",
              "prefixo": null,
              "sufixo": null,
              "tipo": "ADVOGADO",
              "tipo_normalizado": "Advogado",
              "polo": "ADVOGADO",
              "cpf": "00000000000",
              "nome_normalizado": "Fabiane Santos Carvalho",
              "oabs": [
                {
                  "uf": "SP",
                  "tipo": "ADVOGADO",
                  "numero": 123123
                }
              ]
            }
          ],
          "prefixo": null,
          "sufixo": null,
          "tipo": "REQUERIDO",
          "tipo_normalizado": "Requerido",
          "polo": "PASSIVO",
          "cpf": "00000000000",
          "nome_normalizado": "Joao da Silva"
        },
        {
          "nome": "Marcos Tira Teima",
          "quantidade_processos": 126,
          "tipo_pessoa": "FISICA",
          "prefixo": null,
          "sufixo": null,
          "tipo": "JUIZ",
          "tipo_normalizado": "Juiz",
          "polo": "NENHUM"
        }
      ]
    },
    {
      "id": 6,
      "processo_fonte_id": 14566,
      "descricao": "TJSP - 2º grau",
      "nome": "Tribunal de Justiça de São Paulo",
      "sigla": "TJSP",
      "tipo": "TRIBUNAL",
      "data_inicio": "2017-06-01",
      "data_ultima_movimentacao": "2018-04-26",
      "segredo_justica": null,
      "arquivado": null,
      "status_predito": "INATIVO",
      "grau": 2,
      "grau_formatado": "Segundo Grau",
      "fisico": false,
      "sistema": "ESAJ",
      "capa": {
        "classe": "APELACAO CIVEL",
        "assunto": "DIREITO CIVIL-RESPONSABILIDADE CIVIL-INDENIZACAO POR DANO MORAL",
        "assuntos_normalizados": [
          {
            "id": 3644,
            "nome": "Indenização por Dano Moral",
            "nome_com_pai": "Responsabilidade Civil > Indenização por Dano Moral",
            "path_completo": "DIREITO CIVIL | Responsabilidade Civil | Indenização por Dano Moral",
            "bloqueado": false
          }
        ],
        "assunto_principal_normalizado": {
          "id": 3644,
          "nome": "Indenização por Dano Moral",
          "nome_com_pai": "Responsabilidade Civil > Indenização por Dano Moral",
          "path_completo": "DIREITO CIVIL | Responsabilidade Civil | Indenização por Dano Moral",
          "bloqueado": false
        },
        "area": "CIVEL",
        "orgao_julgador": "7ª CAMARA DE DIREITO PRIVADO",
        "situacao": "Baixado",
        "valor_causa": {
          "valor": "50000.0000",
          "moeda": "R$",
          "valor_formatado": "R$ 50.000,00"
        },
        "data_distribuicao": "2017-06-01",
        "data_arquivamento": null,
        "informacoes_complementares": null
      },
      "audiencias": [],
      "url": "https://esaj.tjsp.jus.br/cposg/search.do?conversationId=&paginaConsulta=0&cbPesquisa=NUMPROC&numeroDigitoAnoUnificado=1024000-20.2015&foroNumeroUnificado=0000&dePesquisaNuUnificado=1024000-20.2015.8.22.0000&dePesquisaNuUnificado=UNIFICADO&dePesquisa=&tipoNuProcesso=UNIFICADO&uuidCaptcha=sajcaptcha_e6c6a295c5404a6887d81483bdd96048&g-recaptcha-response=",
      "tribunal": {
        "id": 102,
        "nome": "Tribunal de Justiça de São Paulo",
        "sigla": "TJSP",
        "categoria": null
      },
      "quantidade_movimentacoes": 35,
      "quantidade_envolvidos": 7,
      "data_ultima_verificacao": "2023-02-09T14:30:00+00:00",
      "envolvidos": [
        {
          "nome": "Maria da Conceição de Oliveira",
          "quantidade_processos": 1,
          "tipo_pessoa": "FISICA",
          "advogados": [
            {
              "nome": "Fabiane Santos Carvalho",
              "quantidade_processos": 21,
              "tipo_pessoa": "FISICA",
              "prefixo": null,
              "sufixo": null,
              "tipo": "ADVOGADO",
              "tipo_normalizado": "Advogado",
              "polo": "ADVOGADO",
              "cpf": "00000000000",
              "nome_normalizado": "Fabiane Santos Carvalho",
              "oabs": [
                {
                  "uf": "SP",
                  "tipo": "ADVOGADO",
                  "numero": 123123
                }
              ]
            },
            {
              "nome": "Antonio Carlos de Souza",
              "quantidade_processos": 10,
              "tipo_pessoa": "FISICA",
              "prefixo": null,
              "sufixo": null,
              "tipo": "ADVOGADO",
              "tipo_normalizado": "Advogado",
              "polo": "ADVOGADO",
              "cpf": "00000000000",
              "nome_normalizado": "Antonio Carlos de Souza",
              "oabs": [
                {
                  "uf": "SP",
                  "tipo": "ADVOGADO",
                  "numero": 123123
                }
              ]
            }
          ],
          "prefixo": null,
          "sufixo": null,
          "tipo": "APELANTE",
          "tipo_normalizado": "Apelante",
          "polo": "ATIVO",
          "cpf": "00000000000",
          "nome_normalizado": "Maria da Conceicao de Oliveira"
        },
        {
          "nome": "Joao da Silva",
          "quantidade_processos": 97,
          "tipo_pessoa": "FISICA",
          "advogados": [
            {
              "nome": "",
              "quantidade_processos": 37,
              "tipo_pessoa": "FISICA",
              "prefixo": null,
              "sufixo": null,
              "tipo": "ADVOGADO",
              "tipo_normalizado": "Advogado",
              "polo": "ADVOGADO",
              "cpf": "00000000000",
              "nome_normalizado": "Marta Brandao de Oliveira",
              "oabs": [
                {
                  "uf": "SP",
                  "tipo": "ADVOGADO",
                  "numero": 123123
                }
              ]
            },
            {
              "nome": "Fernando Marçal",
              "quantidade_processos": 33,
              "tipo_pessoa": "FISICA",
              "prefixo": null,
              "sufixo": null,
              "tipo": "ADVOGADO",
              "tipo_normalizado": "Advogado",
              "polo": "ADVOGADO",
              "cpf": "00000000000",
              "nome_normalizado": "Fernando Marçal",
              "oabs": [
                {
                  "uf": "SP",
                  "tipo": "ADVOGADO",
                  "numero": 123123
                }
              ]
            }
          ],
          "prefixo": null,
          "sufixo": null,
          "tipo": "APELADO",
          "tipo_normalizado": "Apelado",
          "polo": "PASSIVO",
          "cpf": "00000000000",
          "nome_normalizado": "Joao da Silva"
        },
        {
          "nome": "Ronaldo de Assis",
          "quantidade_processos": 86,
          "tipo_pessoa": "FISICA",
          "prefixo": null,
          "sufixo": null,
          "tipo": "RELATOR",
          "tipo_normalizado": "Juiz",
          "polo": "NENHUM",
          "cpf": "00000000000",
          "nome_normalizado": "Ronaldo de Assis"
        }
      ]
    }
  ]
}
Exemplo de resposta (401):

{
  "error": "Unauthenticated"
}
Exemplo de resposta (402):

{
  "error": "Você não possui saldo em crédito da API."
}
Exemplo de resposta (404):

{
  "error": "NotFound"
}
HTTP Request
GET api/v2/processos/numero_cnj/{numero}

Headers
Campo	Valor
Authorization	Bearer {access_token}
X-Requested-With	XMLHttpRequest
URI Parameters
Parâmetro	Tipo	Descrição
numero	string	Número único do processo. Obrigatório estar no formato de CNJ.
Exemplo: 0000000-00.0000.0.00.0000
Movimentações de um processo
Retorna as movimentações de um processo a partir do número CNJ, que estão na base do Escavador. Caso precise atualizar as movimentações, utilize a rota de solicitar atualização de um processo.

Acesse a página de respostas para detalhes sobre os dados retornados.

Exemplo de requisição:

from escavador import *
from escavador.v2 import Processo
config("API_KEY")

response = Processo.movimentacoes(
  numero_cnj="0000000-00.0000.0.00.0000" # também aceita formato "00000000000000000000"
)
// Esse é um exemplo de resposta bem-sucedida.
Exemplo de resposta (200):

{
  "items": [
    {
      "id": 853879,
      "data": "2018-07-25",
      "tipo": "ANDAMENTO",
      "conteudo": "CERTIDAO DE CARTORIO EXPEDIDA",
      "fonte": {
        "fonte_id": 3,
        "nome": "Tribunal de Justiça de São Paulo",
        "tipo": "TRIBUNAL",
        "sigla": "TJSP",
        "grau": 1,
        "grau_formatado": "Primeiro Grau"
      }
    },
    {
      "id": 853877,
      "data": "2018-07-25",
      "tipo": "ANDAMENTO",
      "conteudo": "CERTIDAO DE CARTORIO EXPEDIDA",
      "fonte": {
        "fonte_id": 3,
        "nome": "Tribunal de Justiça de São Paulo",
        "tipo": "TRIBUNAL",
        "sigla": "TJSP",
        "grau": 1,
        "grau_formatado": "Primeiro Grau"
      }
    },
    {
      "id": 853875,
      "data": "2018-07-25",
      "tipo": "ANDAMENTO",
      "conteudo": "ARQUIVADO DEFINITIVAMENTE",
      "fonte": {
        "fonte_id": 3,
        "nome": "Tribunal de Justiça de São Paulo",
        "tipo": "TRIBUNAL",
        "sigla": "TJSP",
        "grau": 1,
        "grau_formatado": "Primeiro Grau"
      }
    },
    {
      "id": 853881,
      "data": "2018-06-05",
      "tipo": "ANDAMENTO",
      "conteudo": "SUSPENSAO DO PRAZO",
      "fonte": {
        "fonte_id": 3,
        "nome": "Tribunal de Justiça de São Paulo",
        "tipo": "TRIBUNAL",
        "sigla": "TJSP",
        "grau": 1,
        "grau_formatado": "Primeiro Grau"
      }
    },
    {
      "id": 853883,
      "data": "2018-06-02",
      "tipo": "ANDAMENTO",
      "conteudo": "SUSPENSAO DO PRAZO",
      "fonte": {
        "fonte_id": 3,
        "nome": "Tribunal de Justiça de São Paulo",
        "tipo": "TRIBUNAL",
        "sigla": "TJSP",
        "grau": 1,
        "grau_formatado": "Primeiro Grau"
      }
    },
    {
      "id": 853885,
      "data": "2018-05-24",
      "tipo": "ANDAMENTO",
      "conteudo": "CERTIDAO DE PUBLICACAO EXPEDIDA",
      "fonte": {
        "fonte_id": 3,
        "nome": "Tribunal de Justiça de São Paulo",
        "tipo": "TRIBUNAL",
        "sigla": "TJSP",
        "grau": 1,
        "grau_formatado": "Primeiro Grau"
      }
    },
    {
      "id": 853887,
      "data": "2018-05-23",
      "tipo": "ANDAMENTO",
      "conteudo": "REMETIDO AO DJE",
      "fonte": {
        "fonte_id": 3,
        "nome": "Tribunal de Justiça de São Paulo",
        "tipo": "TRIBUNAL",
        "sigla": "TJSP",
        "grau": 1,
        "grau_formatado": "Primeiro Grau"
      }
    },
    {
      "id": 853889,
      "data": "2018-05-10",
      "tipo": "ANDAMENTO",
      "conteudo": "PROFERIDO DESPACHO",
      "fonte": {
        "fonte_id": 3,
        "nome": "Tribunal de Justiça de São Paulo",
        "tipo": "TRIBUNAL",
        "sigla": "TJSP",
        "grau": 1,
        "grau_formatado": "Primeiro Grau"
      }
    },
    {
      "id": 853896,
      "data": "2018-05-04",
      "tipo": "ANDAMENTO",
      "conteudo": "DECISAO DE 2ª INSTANCIA - RECURSO NAO PROVIDO - JUNTADA",
      "fonte": {
        "fonte_id": 3,
        "nome": "Tribunal de Justiça de São Paulo",
        "tipo": "TRIBUNAL",
        "sigla": "TJSP",
        "grau": 1,
        "grau_formatado": "Primeiro Grau"
      }
    },
    {
      "id": 853895,
      "data": "2018-05-04",
      "tipo": "ANDAMENTO",
      "conteudo": "EMBARGOS DE DECLARACAO ACOLHIDOS",
      "fonte": {
        "fonte_id": 3,
        "nome": "Tribunal de Justiça de São Paulo",
        "tipo": "TRIBUNAL",
        "sigla": "TJSP",
        "grau": 1,
        "grau_formatado": "Primeiro Grau"
      }
    },
    {
      "id": 853893,
      "data": "2018-05-04",
      "tipo": "ANDAMENTO",
      "conteudo": "TRANSITO EM JULGADO AS PARTES - PROC. EM ANDAMENTO",
      "fonte": {
        "fonte_id": 3,
        "nome": "Tribunal de Justiça de São Paulo",
        "tipo": "TRIBUNAL",
        "sigla": "TJSP",
        "grau": 1,
        "grau_formatado": "Primeiro Grau"
      }
    },
    {
      "id": 853891,
      "data": "2018-05-04",
      "tipo": "ANDAMENTO",
      "conteudo": "CONCLUSOS PARA DESPACHO",
      "fonte": {
        "fonte_id": 3,
        "nome": "Tribunal de Justiça de São Paulo",
        "tipo": "TRIBUNAL",
        "sigla": "TJSP",
        "grau": 1,
        "grau_formatado": "Primeiro Grau"
      }
    },
    {
      "id": 853897,
      "data": "2018-04-26",
      "tipo": "ANDAMENTO",
      "conteudo": "RECEBIDOS OS AUTOS DO TRIBUNAL DE JUSTICA",
      "fonte": {
        "fonte_id": 3,
        "nome": "Tribunal de Justiça de São Paulo",
        "tipo": "TRIBUNAL",
        "sigla": "TJSP",
        "grau": 1,
        "grau_formatado": "Primeiro Grau"
      }
    },
    {
      "id": 849990,
      "data": "2018-04-26",
      "tipo": "ANDAMENTO",
      "conteudo": "EXPEDIDO CERTIDAO",
      "fonte": {
        "fonte_id": 6,
        "nome": "Tribunal de Justiça de São Paulo",
        "tipo": "TRIBUNAL",
        "sigla": "TJSP",
        "grau": 2,
        "grau_formatado": "Segundo Grau"
      }
    },
    {
      "id": 849988,
      "data": "2018-04-26",
      "tipo": "ANDAMENTO",
      "conteudo": "BAIXA DEFINITIVA",
      "fonte": {
        "fonte_id": 6,
        "nome": "Tribunal de Justiça de São Paulo",
        "tipo": "TRIBUNAL",
        "sigla": "TJSP",
        "grau": 2,
        "grau_formatado": "Segundo Grau"
      }
    },
    {
      "id": 849986,
      "data": "2018-04-26",
      "tipo": "ANDAMENTO",
      "conteudo": "EXPEDIDO CERTIDAO DE BAIXA DE RECURSO",
      "fonte": {
        "fonte_id": 6,
        "nome": "Tribunal de Justiça de São Paulo",
        "tipo": "TRIBUNAL",
        "sigla": "TJSP",
        "grau": 2,
        "grau_formatado": "Segundo Grau"
      }
    },
    {
      "id": 849992,
      "data": "2018-03-28",
      "tipo": "ANDAMENTO",
      "conteudo": "EXPEDIDO CERTIDAO",
      "fonte": {
        "fonte_id": 6,
        "nome": "Tribunal de Justiça de São Paulo",
        "tipo": "TRIBUNAL",
        "sigla": "TJSP",
        "grau": 2,
        "grau_formatado": "Segundo Grau"
      }
    },
    {
      "id": 849994,
      "data": "2018-03-26",
      "tipo": "ANDAMENTO",
      "conteudo": "JULGADO VIRTUALMENTE",
      "fonte": {
        "fonte_id": 6,
        "nome": "Tribunal de Justiça de São Paulo",
        "tipo": "TRIBUNAL",
        "sigla": "TJSP",
        "grau": 2,
        "grau_formatado": "Segundo Grau"
      }
    },
    {
      "id": 849998,
      "data": "2018-03-06",
      "tipo": "ANDAMENTO",
      "conteudo": "EXPEDIDO CERTIDAO",
      "fonte": {
        "fonte_id": 6,
        "nome": "Tribunal de Justiça de São Paulo",
        "tipo": "TRIBUNAL",
        "sigla": "TJSP",
        "grau": 2,
        "grau_formatado": "Segundo Grau"
      }
    },
    {
      "id": 849996,
      "data": "2018-03-06",
      "tipo": "ANDAMENTO",
      "conteudo": "CONCLUSOS PARA O RELATOR (EXPEDIDO TERMO COM CONCLUSAO)",
      "fonte": {
        "fonte_id": 6,
        "nome": "Tribunal de Justiça de São Paulo",
        "tipo": "TRIBUNAL",
        "sigla": "TJSP",
        "grau": 2,
        "grau_formatado": "Segundo Grau"
      }
    }
  ],
  "links": {
    "next": "https://api.escavador.com/api/v2/processos/numero_cnj/1024000-20.2015.8.22.0000/movimentacoes?cursor=eyJkYXRhIjoiMjAxOC0wMy0wNiAwMDowMDowMCIsIm1vdmltZW50YWNhb19pZCI6ODQ5OTk2LCJfcG9pbnRzVG9OZXh0SXRlbXMiOnRydWV9&li=216029777"
  },
  "paginator": {
    "per_page": 20
  }
}
Exemplo de resposta (401):

{
  "error": "Unauthenticated"
}
Exemplo de resposta (402):

{
  "error": "Você não possui saldo em crédito da API."
}
Exemplo de resposta (404):

{
  "error": "NotFound"
}
HTTP Request
GET api/v2/processos/numero_cnj/{numero}/movimentacoes

Headers
Campo	Valor
Authorization	Bearer {access_token}
X-Requested-With	XMLHttpRequest
URI Parameters
Parâmetro	Tipo	Descrição
numero	string	Número único do processo. Obrigatório estar no formato de CNJ.
Exemplo: 0000000-00.0000.0.00.0000
Query Parameters
Parâmetro	Status	Descrição
limit	opcional	Quantidade de movimentações por página. Pode ser 50 ou 100.
Processos do envolvido por Nome ou CPF/CNPJ
Retorna os processos de um envolvido a partir do nome ou CPF/CNPJ.

Ao buscar processos pelo CPF, pode ocorrer da pessoa em questão possuir homônimos, o que torna o nome do CPF informado não único no Brasil. Além disso, se os processos em que essa pessoa esteja envolvida não possuírem o CPF informado nos sistemas dos Tribunais, os resultados podem não ser retornados. Nesse caso, é recomendável realizar a busca pelo nome da parte e filtrar pelo estado da pessoa, o que cobre a grande maioria dos casos. Para saber mais sobre o algoritmo de matching, acesse a página da Central de Ajuda.
Acesse a página de respostas para detalhes sobre os dados retornados.

Exemplo de requisição:

from escavador import *
from escavador.v2 import Processo
config("API_KEY")

response = Processo.por_envolvido(
  nome="Companhia de Aguas do Estado do Parana",
  tribunais=[SiglaTribunal.TJAL, SiglaTribunal.TREBA, SiglaTribunal.TRT15] # opcional
)
// Esse é um exemplo de resposta bem-sucedida.
Exemplo de resposta (200):

{
  "envolvido_encontrado": {
    "nome": "Engenharia e Construcoes Ltda",
    "tipo_pessoa": "JURIDICA",
    "quantidade_processos": 2
  },
  "items": [
    {
      "numero_cnj": "1060225-21.2023.5.56.0002",
      "titulo_polo_ativo": "Joao da Silva",
      "titulo_polo_passivo": "Empresa de Engenharia e outros",
      "ano_inicio": 2023,
      "data_inicio": "2023-03-11",
      "estado_origem": {
        "nome": "São Paulo",
        "sigla": "SP"
      },
      "unidade_origem": {
        "nome": "FORO ESPECIALIZADO DA 1ª RAJ",
        "cidade": "São Paulo",
        "estado": {
          "nome": "São Paulo",
          "sigla": "SP"
        },
        "tribunal_sigla": "TJSP"
      },
      "data_ultima_movimentacao": "2023-03-11",
      "quantidade_movimentacoes": 2,
      "fontes_tribunais_estao_arquivadas": false,
      "data_ultima_verificacao": "2023-03-14T19:00:14+00:00",
      "tempo_desde_ultima_verificacao": "há 15 minutos",
      "processos_relacionados": [
        {
          "numero": "8027909-02.2019.8.05.0000"
        },
        {
          "numero": "8028150-73.2019.8.05.0000"
        }
      ],
      "fontes": [
        {
          "id": 47,
          "processo_fonte_id": 1048903,
          "descricao": "TRT-2 - 1º grau",
          "nome": "Tribunal Regional do Trabalho da 2ª Região",
          "sigla": "TRT-2",
          "tipo": "TRIBUNAL",
          "data_inicio": "2023-03-11",
          "data_ultima_movimentacao": "2023-03-11",
          "segredo_justica": false,
          "arquivado": null,
          "status_predito": "ATIVO",
          "grau": 1,
          "grau_formatado": "Primeiro Grau",
          "fisico": false,
          "sistema": "PJE",
          "capa": {
            "classe": "ACAO TRABALHISTA - RITO ORDINARIO",
            "assunto": "SALARIO POR FORA - INTEGRACAO",
            "assuntos_normalizados": [
              {
                "id": 6870,
                "nome": "Horas Extras",
                "nome_com_pai": "Duração do Trabalho > Horas Extras",
                "path_completo": "DIREITO DO TRABALHO | Direito Individual do Trabalho  | Duração do Trabalho | Horas Extras",
                "bloqueado": false
              },
              {
                "id": 7041,
                "nome": "Salário por Fora - Integração",
                "nome_com_pai": "Salário/Diferença Salarial > Salário por Fora - Integração",
                "path_completo": "DIREITO DO TRABALHO | Direito Individual do Trabalho  | Verbas Remuneratórias, Indenizatórias e Benefícios | Salário/Diferença Salarial | Salário por Fora - Integração",
                "bloqueado": false
              }
            ],
            "assunto_principal_normalizado": {
              "id": 7041,
              "nome": "Salário por Fora - Integração",
              "nome_com_pai": "Salário/Diferença Salarial > Salário por Fora - Integração",
              "path_completo": "DIREITO DO TRABALHO | Direito Individual do Trabalho  | Verbas Remuneratórias, Indenizatórias e Benefícios | Salário/Diferença Salarial | Salário por Fora - Integração",
              "bloqueado": false
            },
            "area": "TRABALHISTA",
            "orgao_julgador": "7ª VARA DO TRABALHO DE SAO PAULO",
            "situacao": "Baixado",
            "valor_causa": {
              "valor": "310455.6100",
              "moeda": "R$",
              "valor_formatado": "R$ 310.455,61"
            },
            "data_distribuicao": "2023-03-11",
            "data_arquivamento": null,
            "informacoes_complementares": null
          },
          "url": "https://pje.trt2.jus.br/consultaprocessual/detalhe-processo/10003246720235020007",
          "tribunal": {
            "id": 13,
            "nome": "Tribunal Regional do Trabalho da 2ª Região",
            "sigla": "TRT-2",
            "categoria": null
          },
          "quantidade_movimentacoes": 2,
          "data_ultima_verificacao": "2023-03-14T19:00:14+00:00",
          "envolvidos": [
            {
              "nome": "Joao da Silva",
              "quantidade_processos": 1,
              "tipo_pessoa": "FISICA",
              "advogados": [
                {
                  "nome": "Paulo Roberto de Oliveira",
                  "quantidade_processos": 3,
                  "tipo_pessoa": "FISICA",
                  "prefixo": null,
                  "sufixo": null,
                  "tipo": "ADVOGADO",
                  "tipo_normalizado": "Advogado",
                  "polo": "ADVOGADO",
                  "cpf": "00000000000",
                  "oabs": [
                    {
                      "uf": "SP",
                      "tipo": "ADVOGADO",
                      "numero": 123123
                    }
                  ]
                },
                {
                  "nome": "Daniel Felipe Assis",
                  "quantidade_processos": 8,
                  "tipo_pessoa": "FISICA",
                  "prefixo": null,
                  "sufixo": null,
                  "tipo": "ADVOGADO",
                  "tipo_normalizado": "Advogado",
                  "polo": "ADVOGADO",
                  "oabs": [
                    {
                      "uf": "SP",
                      "tipo": "ADVOGADO",
                      "numero": 123123
                    }
                  ]
                }
              ],
              "prefixo": null,
              "sufixo": null,
              "tipo": "RECLAMANTE",
              "tipo_normalizado": "Reclamante",
              "polo": "ATIVO",
              "cpf": "00000000000"
            },
            {
              "nome": "Empresa de Engenharia e outros",
              "quantidade_processos": 2,
              "tipo_pessoa": "JURIDICA",
              "prefixo": null,
              "sufixo": null,
              "tipo": "RECLAMADO",
              "tipo_normalizado": "Reclamado",
              "polo": "PASSIVO",
              "cnpj": "00000000000000"
            },
            {
              "nome": "Empresa de Construcoes",
              "quantidade_processos": 2,
              "tipo_pessoa": "JURIDICA",
              "prefixo": null,
              "sufixo": null,
              "tipo": "RECLAMADO",
              "tipo_normalizado": "Reclamado",
              "polo": "PASSIVO",
              "cnpj": "00000000000000"
            },
            {
              "nome": "Engenharia e Construcoes Ltda",
              "quantidade_processos": 66,
              "tipo_pessoa": "JURIDICA",
              "prefixo": null,
              "sufixo": null,
              "tipo": "RECLAMADO",
              "tipo_normalizado": "Reclamado",
              "polo": "PASSIVO",
              "cnpj": "00000000000000"
            },
            {
              "nome": "Construtora e Incorporadora Ltda",
              "quantidade_processos": 1,
              "tipo_pessoa": "JURIDICA",
              "prefixo": null,
              "sufixo": null,
              "tipo": "RECLAMADO",
              "tipo_normalizado": "Reclamado",
              "polo": "PASSIVO",
              "cnpj": "00000000000000"
            }
          ]
        }
      ]
    },
    {
      "numero_cnj": "0205615-29.2023.3.12.0026",
      "titulo_polo_ativo": "Maria Almeida Sampaio",
      "titulo_polo_passivo": "Engenharia e Construcoes Ltda",
      "ano_inicio": 2023,
      "data_inicio": "2023-03-10",
      "data_ultima_movimentacao": "2023-03-10",
      "quantidade_movimentacoes": 2,
      "fontes_tribunais_estao_arquivadas": false,
      "data_ultima_verificacao": "2023-03-14T19:00:14+00:00",
      "tempo_desde_ultima_verificacao": "há 15 minutos",
      "fontes": [
        {
          "id": 355,
          "processo_fonte_id": 1048904,
          "descricao": "TRT-20 - 1º grau",
          "nome": "Tribunal Regional do Trabalho da 20ª Região",
          "sigla": "TRT-20",
          "tipo": "TRIBUNAL",
          "data_inicio": "2023-03-10",
          "data_ultima_movimentacao": "2023-03-10",
          "segredo_justica": false,
          "arquivado": null,
          "grau": 1,
          "grau_formatado": "Primeiro Grau",
          "fisico": false,
          "sistema": "PJE",
          "capa": {
            "classe": "ACAO TRABALHISTA - RITO ORDINARIO",
            "assunto": "ISONOMIA/DIFERENCA SALARIAL",
            "assuntos_normalizados": [
              {
                "id": 6793,
                "nome": "isonomia/Diferença Salarial",
                "nome_com_pai": "Enquadramento > isonomia/Diferença Salarial",
                "path_completo": "DIREITO DO TRABALHO | Direito Individual do Trabalho  | Categoria Profissional Especial | Bancários | Enquadramento | isonomia/Diferença Salarial",
                "bloqueado": false
              },
              {
                "id": 6978,
                "nome": "Adicional de Periculosidade",
                "nome_com_pai": "Adicional > Adicional de Periculosidade",
                "path_completo": "DIREITO DO TRABALHO | Direito Individual do Trabalho  | Verbas Remuneratórias, Indenizatórias e Benefícios | Adicional | Adicional de Periculosidade",
                "bloqueado": false
              }
            ],
            "assunto_principal_normalizado": {
              "id": 6793,
              "nome": "isonomia/Diferença Salarial",
              "nome_com_pai": "Enquadramento > isonomia/Diferença Salarial",
              "path_completo": "DIREITO DO TRABALHO | Direito Individual do Trabalho  | Categoria Profissional Especial | Bancários | Enquadramento | isonomia/Diferença Salarial",
              "bloqueado": false
            },
            "area": "TRABALHISTA",
            "orgao_julgador": "2ª VARA DO TRABALHO DE ARACAJU",
            "valor_causa": {
              "valor": "292319.7200",
              "moeda": "R$",
              "valor_formatado": "R$ 292.319,72"
            },
            "data_distribuicao": "2023-03-10",
            "data_arquivamento": null,
            "informacoes_complementares": null
          },
          "url": "https://pje.trt20.jus.br/consultaprocessual/detalhe-processo/00002054020235200002",
          "tribunal": {
            "id": 31,
            "nome": "Tribunal Regional do Trabalho da 20ª Região",
            "sigla": "TRT-20",
            "categoria": null
          },
          "quantidade_movimentacoes": 2,
          "data_ultima_verificacao": "2023-03-14T19:00:14+00:00",
          "envolvidos": [
            {
              "nome": "Maria Almeida Sampaio",
              "quantidade_processos": 1,
              "tipo_pessoa": "FISICA",
              "advogados": [
                {
                  "nome": "Petrucio Silveira",
                  "quantidade_processos": 16,
                  "tipo_pessoa": "FISICA",
                  "prefixo": null,
                  "sufixo": null,
                  "tipo": "ADVOGADO",
                  "tipo_normalizado": "Advogado",
                  "polo": "ADVOGADO",
                  "cpf": "00000000000",
                  "oabs": [
                    {
                      "uf": "SE",
                      "tipo": "ADVOGADO",
                      "numero": 123123
                    }
                  ]
                },
                {
                  "nome": "Kevin Correia Borges",
                  "quantidade_processos": 8,
                  "tipo_pessoa": "FISICA",
                  "prefixo": null,
                  "sufixo": null,
                  "tipo": "ADVOGADO",
                  "tipo_normalizado": "Advogado",
                  "polo": "ADVOGADO",
                  "cpf": "00000000000",
                  "oabs": [
                    {
                      "uf": "SE",
                      "tipo": "ADVOGADO",
                      "numero": 123123
                    }
                  ]
                }
              ],
              "prefixo": null,
              "sufixo": null,
              "tipo": "RECLAMANTE",
              "tipo_normalizado": "Reclamante",
              "polo": "ATIVO",
              "cpf": "00000000000"
            },
            {
              "nome": "Engenharia e Construcoes Ltda",
              "quantidade_processos": 66,
              "tipo_pessoa": "JURIDICA",
              "prefixo": null,
              "sufixo": null,
              "tipo": "RECLAMADO",
              "tipo_normalizado": "Reclamado",
              "polo": "PASSIVO",
              "cnpj": "00000000000000"
            }
          ]
        }
      ]
    }
  ],
  "links": {
    "next": "https://api.escavador.com/api/v2/envolvido/processos?nome=Joao%20da%20Silva&cursor=eyJwcm9jZXNzby5kYXRhX2luaWNpbyI6IjIwMjItMDctMDUgMDA6MDA6MDAiLCJwcm9jZXNzby5pZCI6MTEwNjg3NSwiX3BvaW50c1RvTmV4dEl0ZW1zIjp0cnVlfQ&li=216025845"
  },
  "paginator": {
    "per_page": 20
  }
}
Exemplo de resposta (401):

{
  "error": "Unauthenticated"
}
Exemplo de resposta (402):

{
  "error": "Você não possui saldo em crédito da API."
}
Exemplo de resposta (404):

{
  "error": "NotFound"
}
HTTP Request
GET api/v2/envolvido/processos

Headers
Campo	Valor
Authorization	Bearer {access_token}
X-Requested-With	XMLHttpRequest
Query Parameters
Parâmetro	Status	Descrição
nome	opcional	Nome do envolvido. Obrigatório se cpf_cnpj não for enviado.
cpf_cnpj	opcional	CPF/CNPJ do envolvido. Obrigatório se nome não for enviado.
ordem	opcional	Ordem dos items na resposta com base na data de início do processo. Pode ser asc ou desc
Default: desc.
limit	opcional	Quantidade de processos por página. Pode ser 50 ou 100.
tribunais[]	opcional	Filtra processos a partir das siglas de tribunais enviadas.
incluir_homonimos	opcional	Inclui processos de envolvidos do mesmo nome que não identificamos o CPF. Disponível apenas para busca por CPF
Default: false.
status	opcional	Filtra processos a partir do status do processo, pode ser ATIVO ou INATIVO. Obs. A classificação do status é feito por IA e vai considerar a última atualização que possuímos do processo na nossa base.
data_minima	opcional	Filtra processos que iniciaram após a data informada. A data deve ser estar no formato AAAA-MM-DD.
data_maxima	opcional	Filtra processos que iniciaram antes da data informada. A data deve ser estar no formato AAAA-MM-DD e, caso a data minima seja enviada, deve ser maior que a data minima.
Resumo de Processos do envolvido por Nome ou CPF/CNPJ
Retorna a quantidade de processos de um envolvido a partir do nome ou CPF/CNPJ.

Exemplo de requisição:

import requests
import json

url = 'https://api.escavador.com/api/v2/envolvido/resumo'

params = {
  'nome': 'Empresa Fantasia SA'
}

headers = {
  'Authorization': 'Bearer {access_token}',
  'X-Requested-With': 'XMLHttpRequest'
}

response = requests.request('GET', url, headers=headers, params=params)

if response and response.text:
  parsed = json.loads(response.text)
  print(json.dumps(parsed, indent=4))
// Esse é um exemplo de resposta bem-sucedida.
Exemplo de resposta (200):

{
  "nome": "Empresa Fantasia S.A",
  "tipo_pessoa": "JURIDICA",
  "quantidade_processos": 3516803
}
Exemplo de resposta (401):

{
  "error": "Unauthenticated"
}
Exemplo de resposta (404):

{
  "error": "NotFound"
}
HTTP Request
GET api/v2/envolvido/resumo

Headers
Campo	Valor
Authorization	Bearer {access_token}
X-Requested-With	XMLHttpRequest
Query Parameters
Parâmetro	Status	Descrição
nome	opcional	Nome do envolvido. Obrigatório se cpf_cnpj não for enviado.
cpf_cnpj	opcional	CPF/CNPJ do envolvido. Obrigatório se nome não for enviado.
Processos de um advogado por OAB
Retorna os processos de um advogado a partir da OAB

Acesse a página de respostas para detalhes sobre os dados retornados.

Exemplo de requisição:

from escavador import *
from escavador.v2 import Processo
config("API_KEY")

response = Processo.por_oab(
  numero="123456", # também pode ser int
  estado="AC"
)
// Esse é um exemplo de resposta bem-sucedida.
Exemplo de resposta (200):

{
  "advogado_encontrado": {
    "nome": "JOÃO DA SILVA",
    "tipo": "ADVOGADO",
    "quantidade_processos": 521
  },
  "items": [
    {
      "numero_cnj": "0000000-00.2022.2.03.0000",
      "titulo_polo_ativo": "Marcio Castro Chagas",
      "titulo_polo_passivo": "Mauro Emerson Gomes",
      "ano_inicio": 2022,
      "data_inicio": "2023-02-10",
      "estado_origem": {
        "nome": "São Paulo",
        "sigla": "SP"
      },
      "unidade_origem": {
        "nome": "FORO ESPECIALIZADO DA 1ª RAJ",
        "cidade": "São Paulo",
        "estado": {
          "nome": "São Paulo",
          "sigla": "SP"
        },
        "tribunal_sigla": "TJSP"
      },
      "data_ultima_movimentacao": "2023-02-10",
      "quantidade_movimentacoes": 1,
      "fontes_tribunais_estao_arquivadas": false,
      "data_ultima_verificacao": "2023-03-14T18:06:59+00:00",
      "tempo_desde_ultima_verificacao": "há 2 horas",
      "processos_relacionados": [
        {
          "numero": "8027909-02.2019.8.05.0000"
        },
        {
          "numero": "8028150-73.2019.8.05.0000"
        }
      ],
      "fontes": [
        {
          "id": 1104,
          "processo_fonte_id": 1125512,
          "descricao": "TSE - 3º grau",
          "nome": "Tribunal Superior Eleitoral",
          "sigla": "TSE",
          "tipo": "TRIBUNAL",
          "data_inicio": "2023-02-10",
          "data_ultima_movimentacao": "2023-02-10",
          "segredo_justica": false,
          "arquivado": null,
          "status_predito": "ATIVO",
          "grau": 3,
          "grau_formatado": "Superior",
          "fisico": false,
          "sistema": "UNIFICADO",
          "capa": {
            "classe": "RECURSO ESPECIAL ELEITORAL",
            "assunto": "DIREITO ELEITORAL",
            "assuntos_normalizados": [
              {
                "id": 3388,
                "nome": "Eleições",
                "nome_com_pai": "Conselhos Regionais de Fiscalização Profissional e Afins > Eleições",
                "path_completo": "DIREITO ADMINISTRATIVO E OUTRAS MATÉRIAS DE DIREITO PÚBLICO | Organização Político-administrativa / Administração Pública | Conselhos Regionais de Fiscalização Profissional e Afins | Eleições",
                "bloqueado": false
              },
              {
                "id": 3935,
                "nome": "Propaganda eleitoral",
                "nome_com_pai": "Campanha Eleitoral > Propaganda eleitoral",
                "path_completo": "DIREITO ELEITORAL E PROCESSO ELEITORAL DO STF | Eleição | Campanha Eleitoral | Propaganda eleitoral",
                "bloqueado": false
              },
              {
                "id": 4564,
                "nome": "DIREITO ELEITORAL",
                "nome_com_pai": "DIREITO ELEITORAL",
                "path_completo": "DIREITO ELEITORAL",
                "bloqueado": false
              },
              {
                "id": 4717,
                "nome": "Eleições",
                "nome_com_pai": "DIREITO ELEITORAL > Eleições",
                "path_completo": "DIREITO ELEITORAL | Eleições",
                "bloqueado": false
              },
              {
                "id": 4904,
                "nome": "Propaganda Política",
                "nome_com_pai": "Partidos Políticos > Propaganda Política",
                "path_completo": "DIREITO ELEITORAL | Partidos Políticos | Propaganda Política",
                "bloqueado": false
              },
              {
                "id": 5770,
                "nome": "Propaganda Política - Propaganda Eleitoral - Impulsionamento",
                "nome_com_pai": "Propaganda Política - Propaganda Eleitoral > Propaganda Política - Propaganda Eleitoral - Impulsionamento",
                "path_completo": "DIREITO ELEITORAL | Eleições | Propaganda Política - Propaganda Eleitoral | Propaganda Política - Propaganda Eleitoral - Impulsionamento",
                "bloqueado": false
              }
            ],
            "assunto_principal_normalizado": {
              "id": 4564,
              "nome": "DIREITO ELEITORAL",
              "nome_com_pai": "DIREITO ELEITORAL",
              "path_completo": "DIREITO ELEITORAL",
              "bloqueado": false
            },
            "area": null,
            "orgao_julgador": "MINISTRO JOÃO",
            "situacao": "Baixado",
            "valor_causa": {
              "valor": null,
              "moeda": null,
              "valor_formatado": null
            },
            "data_distribuicao": "2023-02-10",
            "data_arquivamento": null,
            "informacoes_complementares": null
          },
          "url": "https://consultaunificadapje.tse.jus.br/#/public/resultado/0000000-00.2022.2.03.0000",
          "tribunal": {
            "id": 36,
            "nome": "Tribunal Superior Eleitoral",
            "sigla": "TSE",
            "categoria": null
          },
          "quantidade_movimentacoes": 1,
          "data_ultima_verificacao": "2023-03-14T18:06:59+00:00",
          "envolvidos": [
            {
              "nome": "Marcio Castro Chagas",
              "quantidade_processos": 1,
              "tipo_pessoa": null,
              "advogados": [
                {
                  "nome": "João Paulo de Silva",
                  "quantidade_processos": 5,
                  "tipo_pessoa": "FISICA",
                  "prefixo": null,
                  "sufixo": null,
                  "tipo": "ADVOGADO",
                  "tipo_normalizado": "Advogado",
                  "polo": "ADVOGADO",
                  "cpf": "00000000000",
                  "oabs": [
                    {
                      "uf": "CE",
                      "tipo": "ADVOGADO",
                      "numero": 123023
                    }
                  ]
                }
              ],
              "prefixo": null,
              "sufixo": null,
              "tipo": "AUTOR",
              "tipo_normalizado": "Autor",
              "polo": "ATIVO"
            },
            {
              "nome": "Mauro Emerson Gomes",
              "quantidade_processos": 1,
              "tipo_pessoa": "JURIDICA",
              "advogados": [
                {
                  "nome": "Roberta dos Santos Conceição",
                  "quantidade_processos": 49,
                  "tipo_pessoa": "FISICA",
                  "prefixo": null,
                  "sufixo": null,
                  "tipo": "ADVOGADO",
                  "tipo_normalizado": "Advogado",
                  "polo": "ADVOGADO",
                  "cpf": "00000000000",
                  "oabs": [
                    {
                      "uf": "CE",
                      "tipo": "ADVOGADO",
                      "numero": 123123
                    }
                  ]
                },
                {
                  "nome": "Luiz Carlos Silveira",
                  "quantidade_processos": 31,
                  "tipo_pessoa": "JURIDICA",
                  "prefixo": null,
                  "sufixo": null,
                  "tipo": "ADVOGADO",
                  "tipo_normalizado": "Advogado",
                  "polo": "ADVOGADO",
                  "oabs": [
                    {
                      "uf": "CE",
                      "tipo": "ADVOGADO",
                      "numero": 123123
                    }
                  ]
                }
              ],
              "prefixo": null,
              "sufixo": null,
              "tipo": "REU",
              "tipo_normalizado": "Réu",
              "polo": "PASSIVO"
            },
            {
              "nome": "Rede Servicos Online do Brasil Ltda",
              "quantidade_processos": 10996,
              "tipo_pessoa": "JURIDICA",
              "advogados": [
                {
                  "nome": "Joana D'Arc de Souza",
                  "quantidade_processos": 101,
                  "tipo_pessoa": "FISICA",
                  "prefixo": null,
                  "sufixo": null,
                  "tipo": "ADVOGADO",
                  "tipo_normalizado": "Advogado",
                  "polo": "ADVOGADO",
                  "cpf": "00000000000",
                  "oabs": [
                    {
                      "uf": "SP",
                      "tipo": "ADVOGADO",
                      "numero": 123123
                    }
                  ]
                }
              ],
              "prefixo": null,
              "sufixo": null,
              "tipo": "REU",
              "tipo_normalizado": "Réu",
              "polo": "PASSIVO",
              "cnpj": "00000000000000"
            }
          ]
        }
      ]
    }
  ],
  "links": {
    "next": "https://api.escavador.com/api/v2/advogado/processos?oab_estado=SP&oab_numero=123123&cursor=eyJwcm9jZXNzby5kYXRhX2luaWNpbyI6IjIwMjEtMDEtMTkgMDA6MDA6MDAiLCJwcm9jZXNzby5pZCI6MTEwNzI0NCwiX3BvaW50c1RvTmV4dEl0ZW1zIjp0cnVlfQ&li=216038277"
  },
  "paginator": {
    "per_page": 20
  }
}
Exemplo de resposta (401):

{
  "error": "Unauthenticated"
}
Exemplo de resposta (402):

{
  "error": "Você não possui saldo em crédito da API."
}
Exemplo de resposta (404):

{
  "error": "NotFound"
}
HTTP Request
GET api/v2/advogado/processos

Headers
Campo	Valor
Authorization	Bearer {access_token}
X-Requested-With	XMLHttpRequest
Query Parameters
Parâmetro	Status	Descrição
oab_estado	obrigatório	Estado da OAB.
oab_numero	obrigatório	Número da OAB.
oab_tipo	opcional	Tipo da OAB, pode ser informado caso o mesmo número exista para diferentes tipos. Pode ser ADVOGADO, SUPLEMENTAR, ESTAGIARIO ou CONSULTOR_ESTRANGEIRO.
ordem	opcional	Ordem dos items na resposta com base na data de início do processo. Pode ser asc ou desc
Default: desc.
limit	opcional	Quantidade de processos por página. Pode ser 50 ou 100.
tribunais[]	opcional	Filtra processos a partir das siglas de tribunais enviadas.
status	opcional	Filtra processos a partir do status do processo, pode ser ATIVO ou INATIVO. Obs. A classificação do status é feito por IA e vai considerar a última atualização que possuímos do processo na nossa base.
data_minima	opcional	Filtra processos que iniciaram após a data informada. A data deve ser estar no formato AAAA-MM-DD.
data_maxima	opcional	Filtra processos que iniciaram antes da data informada. A data deve ser estar no formato AAAA-MM-DD e, caso a data minima seja enviada, deve ser maior que a data minima.
Resumo de processos do advogado por OAB
Retorna um resumo do advogado a partir do oab, mostrando a quantidade de processos e o tipo da oab informada

Exemplo de requisição:

import requests
import json

url = 'https://api.escavador.com/api/v2/advogado/resumo'

params = {
  'oab_estado': 'SP',
  'oab_numero': '123456'
}

headers = {
  'Authorization': 'Bearer {access_token}',
  'X-Requested-With': 'XMLHttpRequest'
}

response = requests.request('GET', url, headers=headers, params=params)

if response and response.text:
  parsed = json.loads(response.text)
  print(json.dumps(parsed, indent=4))
// Esse é um exemplo de resposta bem-sucedida.
Exemplo de resposta (200):

{
  "nome": "Fulano da Silva",
  "tipo": "ADVOGADO",
  "quantidade_processos": 153
}
Exemplo de resposta (401):

{
  "error": "Unauthenticated"
}
Exemplo de resposta (404):

{
  "error": "NotFound"
}
HTTP Request
GET api/v2/advogado/resumo

Headers
Campo	Valor
Authorization	Bearer {access_token}
X-Requested-With	XMLHttpRequest
Query Parameters
Parâmetro	Status	Descrição
oab_estado	obrigatório	Estado da OAB.
oab_numero	obrigatório	Número da OAB.
oab_tipo	opcional	Tipo da OAB, pode ser informado caso o mesmo número exista para diferentes tipos. Pode ser ADVOGADO, SUPLEMENTAR, ESTAGIARIO ou CONSULTOR_ESTRANGEIRO.
Documentos públicos de um processo
Retorna uma lista dos documentos públicos de um processo a partir da numeração CNJ, que estão na base do Escavador. Caso precise atualizar os documentos, utilize a rota de solicitar atualização de um processo com o parâmetro documentos_publicos=1.

Exemplo de requisição:

import requests
import json

url = 'https://api.escavador.com/api/v2/processos/numero_cnj/0018063-19.2013.8.26.0002/documentos-publicos'

headers = {
  'Authorization': 'Bearer {access_token}',
  'X-Requested-With': 'XMLHttpRequest'
}

response = requests.request('GET', url, headers=headers)

if response and response.text:
  parsed = json.loads(response.text)
  print(json.dumps(parsed, indent=4))
// Esse é um exemplo de resposta bem-sucedida.
Exemplo de resposta (200):

{
  "items": [
    {
      "id": 11404,
      "titulo": "Despacho",
      "descricao": "Despacho | Despacho",
      "data": "2024-06-17 18:02:36",
      "tipo": "PUBLICO",
      "extensao_arquivo": "pdf",
      "quantidade_paginas": 2,
      "key": "M3VLQSs0M1ZoaVgwaVlEc3pqSldJWDViUkdkckdtYk9BQ2hnSDFOODQ0N2dUNlpCbVM5S1ZPakpvN2JGcGJMMWhuMlJFbDBCZXNjVHY5eHV5UE1BQnc9PQ==",
      "links": {
        "api": "https://api.escavador.com/api/v2/processos/numero_cnj/9213798-66.2024.2.00.6793/documentos/M3VLQSs0M1ZoaVgwaVlEc3pqSldJWDViUkdkckdtYk9BQ2hnSDFOODQ0N2dUNlpCbVM5S1ZPakpvN2JGcGJMMWhuMlJFbDBCZXNjVHY5eHV5UE1BQnc9PQ=="
      }
    },
    {
      "id": 11333,
      "titulo": "Despacho",
      "descricao": "Despacho | Despacho",
      "data": "2024-06-05 16:06:51",
      "tipo": "PUBLICO",
      "extensao_arquivo": "pdf",
      "quantidade_paginas": null,
      "key": "N2dGS0VWMFJoaUZyZFdsVzFja3pObDFiWFVwWE5sVndHRWpjSU9KWEg0MlpGeVpDYTFGSW5RbDBCeVlvM3NTSldJa0NCQ2hLZHpNOE4zR3dndG1BQ1E9PQ==",
      "links": {
        "api": "https://api.escavador.com/api/v2/processos/numero_cnj/9213798-66.2024.2.00.6793/documentos/N2dGS0VWMFJoaUZyZFdsVzFja3pObDFiWFVwWE5sVndHRWpjSU9KWEg0MlpGeVpDYTFGSW5RbDBCeVlvM3NTSldJa0NCQ2hLZHpNOE4zR3dndG1BQ1E9PQ=="
      }
    },
    {
      "id": 10840,
      "titulo": "Despacho",
      "descricao": "Despacho | Despacho",
      "data": "2024-04-09 19:39:16",
      "tipo": "PUBLICO",
      "extensao_arquivo": "pdf",
      "quantidade_paginas": 1,
      "key": "R3lDRlNWa1pIV1hWcDVZVEJrR1ZWUm5oZDFWSVZKcGpHTm1lV1FJZ1FRWFQwNFZCZkZ2ZlNkTlJKWlpSaGZMZGJXZ1h6eGFHWWdCQmNoR29QVE5ETGdndG1BQ0E9PQ==",
      "links": {
        "api": "https://api.escavador.com/api/v2/processos/numero_cnj/9213798-66.2024.2.00.6793/documentos/R3lDRlNWa1pIV1hWcDVZVEJrR1ZWUm5oZDFWSVZKcGpHTm1lV1FJZ1FRWFQwNFZCZkZ2ZlNkTlJKWlpSaGZMZGJXZ1h6eGFHWWdCQmNoR29QVE5ETGdndG1BQ0E9PQ=="
      }
    },
    {
      "id": 14826,
      "titulo": "Despacho",
      "descricao": "Despacho | Despacho",
      "data": "2024-03-19 18:25:33",
      "tipo": "PUBLICO",
      "extensao_arquivo": "pdf",
      "quantidade_paginas": 1,
      "key": "O2VSU1lGQm5rR0Zra1dIVU5ka3lRMjFhYkpKaFpYQ0pjS09LbXZWWFozVEdaRmZhU0lkSWRRcFFBeVdoTEpVQllSRWxaS1hBZGRkZk5RTXZnZ0FDZ1E9PQ==",
      "links": {
        "api": "https://api.escavador.com/api/v2/processos/numero_cnj/9213798-66.2024.2.00.6793/documentos/O2VSU1lGQm5rR0Zra1dIVU5ka3lRMjFhYkpKaFpYQ0pjS09LbXZWWFozVEdaRmZhU0lkSWRRcFFBeVdoTEpVQllSRWxaS1hBZGRkZk5RTXZnZ0FDZ1E9PQ==O2VSU1lGQm5rR0Zra1dIVU5ka3lRMjFhYkpKaFpYQ0pjS09LbXZWWFozVEdaRmZhU0lkSWRRcFFBeVdoTEpVQllSRWxaS1hBZGRkZk5RTXZnZ0FDZ1E9PQ=="
      }
    },
    {
      "id": 10808,
      "titulo": "Despacho",
      "descricao": "Despacho | Despacho",
      "data": "2024-03-08 10:37:25",
      "tipo": "PUBLICO",
      "extensao_arquivo": "pdf",
      "quantidade_paginas": null,
      "key": "T3REUllLa3dIRkpoZFhkbFpjRmZKa1ZFVlZNa1pUdmhlTmxJc1ZWQklRbElkVmdZVW5wWlRBQlhlVWdGSWRkblZsRFlGZ0FUQUJDWmdFQT09",
      "links": {
        "api": "https://api.escavador.com/api/v2/processos/numero_cnj/9213798-66.2024.2.00.6793/documentos/T3REUllLa3dIRkpoZFhkbFpjRmZKa1ZFVlZNa1pUdmhlTmxJc1ZWQklRbElkVmdZVW5wWlRBQlhlVWdGSWRkblZsRFlGZ0FUQUJDWmdFQT09"
      }
    },
    {
      "id": 10041,
      "titulo": "Acórdão",
      "descricao": "Acórdão | Acórdão",
      "data": "2024-02-22 22:38:37",
      "tipo": "PUBLICO",
      "extensao_arquivo": "pdf",
      "quantidade_paginas": 2,
      "key": "P0ZLVk5QVWdoRmpGZkRaWFlHVmxaM2RIVkhWeVZGRGpOT3JkRWRVU2ZGWGRHSmtNbEdpVFZRQWRBdURJaUVjRExBZ0VJQ0FCU0FSWk1BQ3c9PQ==",
      "links": {
        "api": "https://api.escavador.com/api/v2/processos/numero_cnj/9213798-66.2024.2.00.6793/documentos/P0ZLVk5QVWdoRmpGZkRaWFlHVmxaM2RIVkhWeVZGRGpOT3JkRWRVU2ZGWGRHSmtNbEdpVFZRQWRBdURJaUVjRExBZ0VJQ0FCU0FSWk1BQ3c9PQ=="
      }
    },
    {
      "id": 18561,
      "titulo": "Despacho",
      "descricao": "Despacho | Despacho",
      "data": "2024-02-07 14:54:00",
      "tipo": "PUBLICO",
      "extensao_arquivo": "pdf",
      "quantidade_paginas": 2,
      "key": "MzZWVkpWWkZWY1RqVkdWZFpFWkFaM1pUYzJGbWRWWnhYWFpjU1lGSWVrR0ZIWVZaVWxHSk9qTmxIa1dYVkZRQ0FJQ1lWQ0tETkFJQT09",
      "links": {
        "api": "https://api.escavador.com/api/v2/processos/numero_cnj/9213798-66.2024.2.00.6793/documentos/MzZWVkpWWkZWY1RqVkdWZFpFWkFaM1pUYzJGbWRWWnhYWFpjU1lGSWVrR0ZIWVZaVWxHSk9qTmxIa1dYVkZRQ0FJQ1lWQ0tETkFJQT09"
      }
    },
    {
      "id": 95986,
      "titulo": "Despacho",
      "descricao": "Despacho | Despacho",
      "data": "2024-01-09 13:52:05",
      "tipo": "PUBLICO",
      "extensao_arquivo": "pdf",
      "quantidade_paginas": 1,
      "key": "W1ZWS0pIVk5sRldIVm1Sa1VIV0ZZbVZpUVhJcElVVGpHZFNFWm9YWlpXZGZhT1pFa05ETkpZdFZDQlpDWWdFR3dNd0FDRU1NQkFDZz09",
      "links": {
        "api": "https://api.escavador.com/api/v2/processos/numero_cnj/9213798-66.2024.2.00.6793/documentos/W1ZWS0pIVk5sRldIVm1Sa1VIV0ZZbVZpUVhJcElVVGpHZFNFWm9YWlpXZGZhT1pFa05ETkpZdFZDQlpDWWdFR3dNd0FDRU1NQkFDZz09"
      }
    },
    {
      "id": 94232,
      "titulo": "Acórdão",
      "descricao": "Acórdão | Acórdão",
      "data": "2023-12-02 06:37:41",
      "tipo": "PUBLICO",
      "extensao_arquivo": "pdf",
      "quantidade_paginas": 1,
      "key": "D0ZGSk5Ka1dIZ0ZJb2RrVmZGWkZaUkpFQ0tkQ1FKbVZIUkRkVkdOT3BEUmQxQmhrVmZkU1pOTEl3WlZaQmdBdEFGQ0lFQ1dCT0NBZz09",
      "links": {
        "api": "https://api.escavador.com/api/v2/processos/numero_cnj/9213798-66.2024.2.00.6793/documentos/D0ZGSk5Ka1dIZ0ZJb2RrVmZGWkZaUkpFQ0tkQ1FKbVZIUkRkVkdOT3BEUmQxQmhrVmZkU1pOTEl3WlZaQmdBdEFGQ0lFQ1dCT0NBZz09"
      }
    },
    {
      "id": 92398,
      "titulo": "Decisão",
      "descricao": "Decisão | Decisão",
      "data": "2023-10-30 23:57:39",
      "tipo": "PUBLICO",
      "extensao_arquivo": "pdf",
      "quantidade_paginas": 1,
      "key": "T2hWVk5LQWZWWVJoa1lFQmxVZFluUlZGWnBjVk5XV3pGZFpJU05sRlFzQ0FXWkxFaUJKVVRTcFNlZ3BJQ0ZGZ1VIV0VBZ3dNR0NJTUFJQT09",
      "links": {
        "api": "https://api.escavador.com/api/v2/processos/numero_cnj/9213798-66.2024.2.00.6793/documentos/T2hWVk5LQWZWWVJoa1lFQmxVZFluUlZGWnBjVk5XV3pGZFpJU05sRlFzQ0FXWkxFaUJKVVRTcFNlZ3BJQ0ZGZ1VIV0VBZ3dNR0NJTUFJQT09"
      }
    },
    {
      "id": 98409,
      "titulo": "Sentença",
      "descricao": "Sentença | Sentença",
      "data": "2023-09-26 23:01:43",
      "tipo": "PUBLICO",
      "extensao_arquivo": "pdf",
      "quantidade_paginas": 1,
      "key": "O0ZLVlVGS0hZVlpaWW1sVVRlZE5qSUxWZkVIVnpWS2dFU0FGeFRZVmJZWkZIYkVVU2dGa0FFU1FZUVFNV2FSbUZJZ1pDQUFJQ0VDQmNBZz09",
      "links": {
        "api": "https://api.escavador.com/api/v2/processos/numero_cnj/9213798-66.2024.2.00.6793/documentos/O0ZLVlVGS0hZVlpaWW1sVVRlZE5qSUxWZkVIVnpWS2dFU0FGeFRZVmJZWkZIYkVVU2dGa0FFU1FZUVFNV2FSbUZJZ1pDQUFJQ0VDQmNBZz09"
      }
    },
    {
      "id": 94210,
      "titulo": "Ata da Audiência",
      "descricao": "Ata da Audiência | Ata da Audiência",
      "data": "2023-09-26 11:21:40",
      "tipo": "PUBLICO",
      "extensao_arquivo": "pdf",
      "quantidade_paginas": 1,
      "key": "P1ZaVk5MWldUVlZaRmZJVkpaTlFIZGRQYldwRmVUVUtkWEpGSU1WVEpXZW1GU1lGWk5LQ0pCQ2tXUlJIZW1HS1lWQ1NWZ1RHZ0NBSUVNR0lBZz09",
      "links": {
        "api": "https://api.escavador.com/api/v2/processos/numero_cnj/9213798-66.2024.2.00.6793/documentos/P1ZaVk5MWldUVlZaRmZJVkpaTlFIZGRQYldwRmVUVUtkWEpGSU1WVEpXZW1GU1lGWk5LQ0pCQ2tXUlJIZW1HS1lWQ1NWZ1RHZ0NBSUVNR0lBZz09"
      }
    }
  ],
  "links": {
    "next": null,
    "prev": null,
    "first": "https://api.escavador.com/api/v2/processos/numero_cnj/9213798-66.2024.2.00.6793/documentos?page=1",
    "last": "https://api.escavador.com/api/v2/processos/numero_cnj/9213798-66.2024.2.00.6793/documentos?page=1"
  },
  "paginator": {
    "current_page": 1,
    "per_page": 20,
    "total": 12,
    "total_pages": 1
  }
}
Exemplo de resposta (401):

{
  "error": "Unauthenticated"
}
Exemplo de resposta (402):

{
  "error": "Você não possui saldo em crédito da API."
}
Exemplo de resposta (404):

{
  "code": "NOT_FOUND",
  "message": "Recurso não encontrado",
  "errors": null,
  "appends": null
}
Exemplo de resposta (422):

{
  "code": "NUMERO_CNJ_INVALIDO",
  "message": "O número do processo não está no formato CNJ.",
  "errors": null,
  "appends": null
}
HTTP Request
GET api/v2/processos/numero_cnj/{numero}/documentos-publicos

Headers
Campo	Valor
Authorization	Bearer {access_token}
X-Requested-With	XMLHttpRequest
URI Parameters
Parâmetro	Tipo	Descrição
numero	string	Número único do processo. Obrigatório estar no formato de CNJ.
Exemplo: 0000000-00.0000.0.00.0000
Query Parameters
Parâmetro	Status	Descrição
limit	opcional	Quantidade de documentos por página. Pode ser 50 ou 100.
Download do PDF de um Documento
Permite baixar um documento de um processo em formato PDF, utilizando a numeração CNJ e uma chave de acesso exclusiva para cada documento.

Acesse a lista de documentos públicos para mais detalhes sobre os documentos e a chave, fornecida por nós.

Exemplo de requisição:

import requests
import json

url = 'https://api.escavador.com/api/v2/processos/numero_cnj/0018063-19.2013.8.26.0002/documentos/1'

headers = {
  'Authorization': 'Bearer {access_token}',
  'X-Requested-With': 'XMLHttpRequest'
}

response = requests.request('GET', url, headers=headers)

if response and response.text:
  parsed = json.loads(response.text)
  print(json.dumps(parsed, indent=4))
Exemplo de resposta (401):

{
  "error": "Unauthenticated"
}
Exemplo de resposta (402):

{
  "error": "Você não possui saldo em crédito da API."
}
Exemplo de resposta (404):

{
  "code": "NOT_FOUND",
  "message": "Recurso não encontrado",
  "errors": null,
  "appends": null
}
HTTP Request
GET api/v2/processos/numero_cnj/{numero}/documentos/{key}

Headers
Campo	Valor
Authorization	Bearer {access_token}
X-Requested-With	XMLHttpRequest
URI Parameters
Parâmetro	Tipo	Descrição
numero	string	Número único do processo. Obrigatório estar no formato de CNJ.
Exemplo: 0000000-00.0000.0.00.0000
key	string	Chave disponibilizada pela nossa API
Envolvidos de um processo
Retorna uma lista dos envolvidos de um processo a partir da numeração CNJ.

Exemplo de requisição:

import requests
import json

url = 'https://api.escavador.com/api/v2/processos/numero_cnj/0018063-19.2013.8.26.0002/envolvidos'

headers = {
  'Authorization': 'Bearer {access_token}',
  'X-Requested-With': 'XMLHttpRequest'
}

response = requests.request('GET', url, headers=headers)

if response and response.text:
  parsed = json.loads(response.text)
  print(json.dumps(parsed, indent=4))
// Esse é um exemplo de resposta bem-sucedida.
Exemplo de resposta (200):

{
  "items": [
    {
      "nome": "Município de Gravataí / RS",
      "quantidade_processos": 4177,
      "tipo_pessoa": "JURIDICA",
      "cpf": null,
      "cnpj": "87.890.992/0001-58",
      "participacoes_processo": [
        {
          "tipo": "REQUERIDO",
          "tipo_normalizado": "Requerido",
          "polo": "PASSIVO",
          "prefixo": null,
          "sufixo": null,
          "advogados": [],
          "fonte": {
            "processo_fonte_id": 715246906,
            "id": 2827,
            "tipo": "TRIBUNAL",
            "nome": "Tribunal de Justiça do Rio Grande do Sul",
            "sigla": "TJRS",
            "grau": 1,
            "grau_formatado": "Primeiro Grau"
          }
        }
      ]
    },
    {
      "nome": "João da Silva",
      "quantidade_processos": 567,
      "tipo_pessoa": "FISICA",
      "cpf": "123.456.789-00",
      "cnpj": null,
      "participacoes_processo": [
        {
          "tipo": "Apelado",
          "tipo_normalizado": "Apelado",
          "polo": "PASSIVO",
          "prefixo": null,
          "sufixo": null,
          "advogados": [],
          "fonte": {
            "processo_fonte_id": 987654321,
            "id": 5678,
            "tipo": "TRIBUNAL",
            "nome": "Supremo Tribunal Federal",
            "sigla": "STF",
            "grau": 3,
            "grau_formatado": "Superior"
          }
        }
      ]
    },
    {
      "nome": "Município de Porto Alegre / RS",
      "quantidade_processos": 2345,
      "tipo_pessoa": "JURIDICA",
      "cpf": null,
      "cnpj": "98.765.432/0001-12",
      "participacoes_processo": [
        {
          "tipo": "REQUERIDO",
          "tipo_normalizado": "Requerido",
          "polo": "ATIVO",
          "prefixo": null,
          "sufixo": null,
          "advogados": [],
          "fonte": {
            "processo_fonte_id": 112233445,
            "id": 9101,
            "tipo": "TRIBUNAL",
            "nome": "Tribunal Regional Federal",
            "sigla": "TRF",
            "grau": 1,
            "grau_formatado": "Primeiro Grau"
          }
        }
      ]
    },
    {
      "nome": "Maria Oliveira",
      "quantidade_processos": 890,
      "tipo_pessoa": "FISICA",
      "cpf": "987.654.321-00",
      "cnpj": null,
      "participacoes_processo": [
        {
          "tipo": "AGRAVADO",
          "tipo_normalizado": "Agravado",
          "polo": "PASSIVO",
          "prefixo": null,
          "sufixo": null,
          "advogados": [
            {
              "nome": "Danielle Almeida",
              "quantidade_processos": 1,
              "tipo_pessoa": "FISICA",
              "prefixo": null,
              "sufixo": null,
              "tipo": "Advogado",
              "tipo_normalizado": "Advogado",
              "polo": "ADVOGADO",
              "cpf": null,
              "cnpj": null
            }
          ],
          "fonte": {
            "processo_fonte_id": 223344556,
            "id": 3344,
            "tipo": "TRIBUNAL",
            "nome": "Tribunal de Justiça do Rio de Janeiro",
            "sigla": "TJRJ",
            "grau": 2,
            "grau_formatado": "Segundo Grau"
          }
        }
      ]
    },
    {
      "nome": "Associação ABC",
      "quantidade_processos": 456,
      "tipo_pessoa": "JURIDICA",
      "cpf": null,
      "cnpj": "11.222.333/0001-44",
      "participacoes_processo": [
        {
          "tipo": "Apelado",
          "tipo_normalizado": "Apelado",
          "polo": null,
          "prefixo": null,
          "sufixo": null,
          "advogados": [
            {
              "nome": "Ana Souza",
              "quantidade_processos": 1,
              "tipo_pessoa": "FISICA",
              "prefixo": null,
              "sufixo": null,
              "tipo": "Advogado",
              "tipo_normalizado": "Advogado",
              "polo": "ADVOGADO",
              "cpf": null,
              "cnpj": null,
              "oabs": [
                {
                  "uf": "SP",
                  "tipo": "ADVOGADO",
                  "numero": 123456
                }
              ]
            }
          ],
          "fonte": {
            "processo_fonte_id": 445566778,
            "id": 5566,
            "tipo": "TRIBUNAL",
            "nome": "Tribunal de Justiça de Minas Gerais",
            "sigla": "TJMG",
            "grau": 1,
            "grau_formatado": "Primeiro Grau"
          }
        }
      ]
    }
  ],
  "links": {
    "next": "https://api.escavador.com/api/v2/processos/numero_cnj/87.890.992/0001-58/envolvidos?cursor=eyJlbnZvbHZpZG9fcHJvY2Vzc28uaWQiOjE5OSwiX3BvaW50c1RvTmV4dEl0ZW1zIjp0cnVlfQ&li=1262"
  },
  "paginator": {
    "per_page": 20
  }
}
Exemplo de resposta (401):

{
  "error": "Unauthenticated"
}
Exemplo de resposta (402):

{
  "error": "Você não possui saldo em crédito da API."
}
Exemplo de resposta (404):

{
  "code": "NOT_FOUND",
  "message": "Recurso não encontrado",
  "errors": null,
  "appends": null
}
Exemplo de resposta (422):

{
  "code": "NUMERO_CNJ_INVALIDO",
  "message": "O número do processo não está no formato CNJ.",
  "errors": null,
  "appends": null
}
HTTP Request
GET api/v2/processos/numero_cnj/{numero}/envolvidos

Headers
Campo	Valor
Authorization	Bearer {access_token}
X-Requested-With	XMLHttpRequest
URI Parameters
Parâmetro	Tipo	Descrição
numero	string	Número único do processo. Obrigatório estar no formato de CNJ.
Exemplo: 0000000-00.0000.0.00.0000
Query Parameters
Parâmetro	Status	Descrição
limit	opcional	Quantidade de envolvidos por página. Pode ser 50 ou 100.
Monitoramento de novos processos
Criar novo monitoramento
O termo enviado será monitorado nas capas e nos envolvidos dos processos. Todos os processos que contiverem o termo serão enviados.

Exemplo de requisição:

import requests
import json

url = 'https://api.escavador.com/api/v2/monitoramentos/novos-processos'

payload = {
  'termo': 'João',
  'variacoes': ["Jo\u00e3o","Jo\u00e3ozinho"],
  'termos_auxiliares': [{"condicao":"CONTEM","termo":"Maria"},{"condicao":"NAO_CONTEM","termo":"Jo\u00e3o"},{"condicao":"CONTEM_ALGUMA","termo":"Jos\u00e9"}],
  'tribunais': ["TJSP","TJMG"]
}

headers = {
  'Authorization': 'Bearer {access_token}',
  'X-Requested-With': 'XMLHttpRequest',
  'Content-Type': 'application/json'
}

response = requests.request('POST', url, headers=headers, json=payload)

if response and response.text:
  parsed = json.loads(response.text)
  print(json.dumps(parsed, indent=4))
// Esse é um exemplo de resposta bem-sucedida.
Exemplo de resposta (200):

{
  "id": 111,
  "termo": "Fulano",
  "criado_em": "2023-11-23T18:12:12+00:00",
  "variacoes": [],
  "termos_auxiliares": [],
  "tribunais_especificos": []
}
// Esse é um exemplo de monitoramento com variacoes.
Exemplo de resposta (200):

{
  "id": 112,
  "termo": "Fulano de tal",
  "tipo": "TERMO",
  "criado_em": "2023-11-23 18:15:13",
  "variacoes": [
    " de tal",
    " de tal e tal"
  ]
}
// Esse é um exemplo de monitoramento com termos auxiliares.
Exemplo de resposta (200):

{
  "id": 112,
  "termo": "Fulano de tal",
  "tipo": "TERMO",
  "criado_em": "2023-11-23 18:15:13",
  "termos_auxiliares": {
    "CONTEM": [
      "Fulano"
    ],
    "NAO_CONTEM": [
      "Fulano de tal"
    ],
    "CONTEM_ALGUMA": [
      "Fulano",
      "Fulano de tal"
    ]
  }
}
// Esse é um exemplo de monitoramento com termos auxiliares e variacoes.
Exemplo de resposta (200):

{
  "id": 112,
  "termo": "Fulano de tal",
  "tipo": "TERMO",
  "criado_em": "2023-11-23 18:15:13",
  "variacoes": [
    " de tal",
    " de tal e tal"
  ],
  "termos_auxiliares": {
    "CONTEM": [
      "Fulano"
    ],
    "NAO_CONTEM": [
      "Fulano de tal"
    ],
    "CONTEM_ALGUMA": [
      "Fulano",
      "Fulano de tal"
    ]
  }
}
Exemplo de resposta (401):

{
  "error": "Unauthenticated"
}
Exemplo de resposta (402):

{
  "error": "Você não possui saldo em crédito da API."
}
HTTP Request
POST api/v2/monitoramentos/novos-processos

Headers
Campo	Valor
Authorization	Bearer {access_token}
X-Requested-With	XMLHttpRequest
Content-Type	application/json
Body Parameters
Parâmetro	Tipo	Status	Descrição
termo	string	obrigatório	Termo a ser monitorado. Pode ser o nome de um envolvido, um CPF/CNPJ ou algum termo genérico que apareça na capa do processo.
variacoes	string[]	opcional	Lista de variações do termo a ser monitorado. Caso o processo dê match com alguma variação, será alertado. É permitido o registro de até duas variações.
termos_auxiliares	string[][]	opcional	Lista de termos termos e condições para o alerta do monitoramento. As condições que podem ser utilizadas são as seguintes:
CONTEM: apenas irá alertar se o processo conter todos os nomes informados.
NAO_CONTEM: apenas irá alertar se não tiver nenhum dos termos informados.
CONTEM_ALGUMA: apenas irá alertar, se tiver pelo menos 1 dos termos informados.
tribunais	string[]	opcional	Lista de siglas dos tribunais específicos que o monitoramento deve ser feito, caso não seja informado, o monitoramento será feito em todos os tribunais.
Callbacks relacionados
Evento	Descrição
novo_processo	Ocorre quando um monitoramento de novos processos encontra algum processo novo.
Listar todos os monitoramentos
Retorna todos os monitoramentos de novos processos do usuário

Exemplo de requisição:

import requests
import json

url = 'https://api.escavador.com/api/v2/monitoramentos/novos-processos'

headers = {
  'Authorization': 'Bearer {access_token}',
  'X-Requested-With': 'XMLHttpRequest'
}

response = requests.request('GET', url, headers=headers)

if response and response.text:
  parsed = json.loads(response.text)
  print(json.dumps(parsed, indent=4))
// Esse é um exemplo de resposta bem-sucedida.
Exemplo de resposta (200):

{
  "items": [
    {
      "id": 103,
      "termo": "EMPRESA SA",
      "criado_em": "2023-11-22T22:13:43+00:00",
      "variacoes": [],
      "termos_auxiliares": [],
      "tribunais_especificos": []
    },
    {
      "id": 111,
      "termo": "Fulano",
      "criado_em": "2023-11-23T18:12:12+00:00",
      "variacoes": [],
      "termos_auxiliares": [],
      "tribunais_especificos": []
    },
    {
      "id": 112,
      "termo": "Fulano de tal",
      "criado_em": "2023-11-23T18:15:13+00:00",
      "variacoes": [
        "Fulano d. tal",
        "Fulano de t."
      ],
      "termos_auxiliares": {
        "CONTEM": [
          "Fulana"
        ],
        "NAO_CONTEM": [
          "Outra pessoa"
        ]
      },
      "tribunais_especificos": []
    }
  ],
  "links": {
    "next": null,
    "prev": null,
    "first": "http://api.escavador.com/api/v2/monitoramentos/novos-processos?page=1",
    "last": "http://api.escavador.com/api/v2/monitoramentos/novos-processos?page=1"
  },
  "paginator": {
    "current_page": 1,
    "per_page": 20,
    "total": 3,
    "total_pages": 1
  }
}
Exemplo de resposta (401):

{
  "error": "Unauthenticated"
}
Exemplo de resposta (402):

{
  "error": "Você não possui saldo em crédito da API."
}
HTTP Request
GET api/v2/monitoramentos/novos-processos

Headers
Campo	Valor
Authorization	Bearer {access_token}
X-Requested-With	XMLHttpRequest
Retornar um monitoramento específico
Retorna um monitoramento de novos processos a partir do id

Exemplo de requisição:

import requests
import json

url = 'https://api.escavador.com/api/v2/monitoramentos/novos-processos/1'

headers = {
  'Authorization': 'Bearer {access_token}',
  'X-Requested-With': 'XMLHttpRequest'
}

response = requests.request('GET', url, headers=headers)

if response and response.text:
  parsed = json.loads(response.text)
  print(json.dumps(parsed, indent=4))
// Esse é um exemplo de resposta bem-sucedida.
Exemplo de resposta (200):

{
  "id": 111,
  "termo": "Fulano",
  "criado_em": "2023-11-23T18:12:12+00:00",
  "variacoes": [],
  "termos_auxiliares": [],
  "tribunais_especificos": []
}
// Esse é um exemplo de monitoramento com variacoes.
Exemplo de resposta (200):

{
  "id": 112,
  "termo": "Fulano de tal",
  "tipo": "TERMO",
  "criado_em": "2023-11-23 18:15:13",
  "variacoes": [
    " de tal",
    " de tal e tal"
  ]
}
// Esse é um exemplo de monitoramento com termos auxiliares.
Exemplo de resposta (200):

{
  "id": 112,
  "termo": "Fulano de tal",
  "tipo": "TERMO",
  "criado_em": "2023-11-23 18:15:13",
  "termos_auxiliares": {
    "CONTEM": [
      "Fulano"
    ],
    "NAO_CONTEM": [
      "Fulano de tal"
    ],
    "CONTEM_ALGUMA": [
      "Fulano",
      "Fulano de tal"
    ]
  }
}
// Esse é um exemplo de monitoramento com termos auxiliares e variacoes.
Exemplo de resposta (200):

{
  "id": 112,
  "termo": "Fulano de tal",
  "tipo": "TERMO",
  "criado_em": "2023-11-23 18:15:13",
  "variacoes": [
    " de tal",
    " de tal e tal"
  ],
  "termos_auxiliares": {
    "CONTEM": [
      "Fulano"
    ],
    "NAO_CONTEM": [
      "Fulano de tal"
    ],
    "CONTEM_ALGUMA": [
      "Fulano",
      "Fulano de tal"
    ]
  }
}
Exemplo de resposta (401):

{
  "error": "Unauthenticated"
}
Exemplo de resposta (402):

{
  "error": "Você não possui saldo em crédito da API."
}
Exemplo de resposta (404):

{
  "error": "NotFound"
}
HTTP Request
GET api/v2/monitoramentos/novos-processos/{id}

Headers
Campo	Valor
Authorization	Bearer {access_token}
X-Requested-With	XMLHttpRequest
URI Parameters
Parâmetro	Tipo	Descrição
id	integer	Id do monitoramento.
Remover um monitoramento
Remove um monitoramento de novos processos a partir do id

Exemplo de requisição:

import requests
import json

url = 'https://api.escavador.com/api/v2/monitoramentos/novos-processos/1'

headers = {
  'Authorization': 'Bearer {access_token}',
  'X-Requested-With': 'XMLHttpRequest'
}

response = requests.request('DELETE', url, headers=headers)

if response and response.text:
  parsed = json.loads(response.text)
  print(json.dumps(parsed, indent=4))
Exemplo de resposta (204):

[]
HTTP Request
DELETE api/v2/monitoramentos/novos-processos/{id}

Headers
Campo	Valor
Authorization	Bearer {access_token}
X-Requested-With	XMLHttpRequest
URI Parameters
Parâmetro	Tipo	Descrição
id	integer	Id do monitoramento.
Listar processos encontrados
Retorna os resultados do monitoramento de novos procesos, a partir do seu ID.

Exemplo de requisição:

import requests
import json

url = 'https://api.escavador.com/api/v2/monitoramentos/novos-processos/1/resultados'

headers = {
  'Authorization': 'Bearer {access_token}',
  'X-Requested-With': 'XMLHttpRequest'
}

response = requests.request('GET', url, headers=headers)

if response and response.text:
  parsed = json.loads(response.text)
  print(json.dumps(parsed, indent=4))
// Esse é um exemplo de resposta bem-sucedida.
Exemplo de resposta (200):

{
  "items": [
    {
      "numero_cnj": "3833283-72.2025.4.02.8208",
      "data_inicio": "2025-03-05",
      "tribunal": "TRT-11",
      "match": "<b>João da Silva</b> requerente 92969887215 sind dos emp em estab bancarios no...",
      "estado_origem": {
        "nome": "Amazonas",
        "sigla": "AM"
      }
    },
    {
      "numero_cnj": "6903212-72.2025.2.00.3259",
      "data_inicio": "2024-12-09",
      "tribunal": "TRT-10",
      "match": "expedido(a) intimacao a(o) <b>João da Silva</b>",
      "estado_origem": {
        "nome": "Amazonas",
        "sigla": "AM"
      }
    }
  ],
  "links": {
    "next": null
  },
  "paginator": {
    "per_page": 20
  }
}
Exemplo de resposta (401):

{
  "error": "Unauthenticated"
}
Exemplo de resposta (402):

{
  "error": "Você não possui saldo em crédito da API."
}
Exemplo de resposta (404):

{
  "error": "NotFound"
}
HTTP Request
GET api/v2/monitoramentos/novos-processos/{id}/resultados

Headers
Campo	Valor
Authorization	Bearer {access_token}
X-Requested-With	XMLHttpRequest
URI Parameters
Parâmetro	Tipo	Descrição
id	integer	Id do monitoramento.
Monitoramento de processos
Criar novo monitoramento
O número do processo informado será monitorado nos tribunais e diários oficiais. Todas as movimentações e publicações encontradas serão enviadas. Ao criar um monitoramento, ele começará com o status PENDENTE e será alterado para ENCONTRADO assim que nosso robô localizar o processo no sistema do tribunal. Se o processo não for encontrado, o status será atualizado para NAO_ENCONTRADO e não haverá cobrança.

Exemplo de requisição:

import requests
import json

url = 'https://api.escavador.com/api/v2/monitoramentos/processos'

payload = {
  'numero': '0000001-00.0000.0.00.0000'
}

headers = {
  'Authorization': 'Bearer {access_token}',
  'X-Requested-With': 'XMLHttpRequest',
  'Content-Type': 'application/json'
}

response = requests.request('POST', url, headers=headers, json=payload)

if response and response.text:
  parsed = json.loads(response.text)
  print(json.dumps(parsed, indent=4))
// Esse é um exemplo de resposta bem-sucedida.
Exemplo de resposta (200):

{
  "id": 17,
  "numero": "0000001-00.2024.6.14.0000",
  "criado_em": "2024-11-19T20:35:09+00:00",
  "data_ultima_verificacao": null,
  "tribunais": [
    {
      "id": 50,
      "nome": "Tribunal Regional Eleitoral do Pará",
      "sigla": "TRE-PA",
      "categoria": null
    }
  ],
  "frequencia": "DIARIA",
  "status": "PENDENTE"
}
Exemplo de resposta (401):

{
  "error": "Unauthenticated"
}
Exemplo de resposta (402):

{
  "error": "Você não possui saldo em crédito da API."
}
HTTP Request
POST api/v2/monitoramentos/processos

Headers
Campo	Valor
Authorization	Bearer {access_token}
X-Requested-With	XMLHttpRequest
Content-Type	application/json
Body Parameters
Parâmetro	Tipo	Status	Descrição
numero	string	obrigatório	Númeração CNJ do processo.
tribunal	string	opcional	Sigla do tribunal a ser monitorado. Caso não deseje acompanhar o processo no tribunal de origem, como em situações em que o processo está no STF com a mesma numeração.
frequencia	string	opcional	Quantidade de dias em que o robô buscará atualizações nos sistemas dos tribunais.
Valores permitidos:
DIARIA: De segunda a sexta.
SEMANAL: 1 vez na semana (O dia é escolhido pelo Escavador).
Default: DIARIA.
Callbacks relacionados
Evento	Descrição
nova_movimentacao	Ocorre quando um monitoramento de processo encontra uma nova movimentação no tribunal ou diário oficial.
processo_encontrado	É enviado assim que nosso robô localiza o processo no sistema do tribunal e o status do monitoramento é alterado para ENCONTRADO.
processo_nao_encontrado	Ocorre quando o processo não é encontrado no sistema do tribunal e o status do monitoramento é alterado para NAO_ENCONTRADO.
Listar todos os monitoramentos
Retorna todos os monitoramentos de processos do usuário

Exemplo de requisição:

import requests
import json

url = 'https://api.escavador.com/api/v2/monitoramentos/processos'

headers = {
  'Authorization': 'Bearer {access_token}',
  'X-Requested-With': 'XMLHttpRequest'
}

response = requests.request('GET', url, headers=headers)

if response and response.text:
  parsed = json.loads(response.text)
  print(json.dumps(parsed, indent=4))
// Esse é um exemplo de resposta bem-sucedida.
Exemplo de resposta (200):

{
  "items": [
    {
      "id": 1566931,
      "numero": "0800493-92.2024.8.14.0112",
      "criado_em": "2024-10-02T16:15:45+00:00",
      "data_ultima_verificacao": null,
      "tribunais": [
        {
          "id": 90,
          "nome": "Tribunal de Justiça do Pará",
          "sigla": "TJPA",
          "categoria": null
        }
      ],
      "frequencia": "DIARIA",
      "status": "ENCONTRADO"
    },
    {
      "id": 1567024,
      "numero": "1002089-72.2023.8.26.0260",
      "criado_em": "2024-10-02T18:01:34+00:00",
      "data_ultima_verificacao": null,
      "tribunais": [
        {
          "id": 102,
          "nome": "Tribunal de Justiça de São Paulo",
          "sigla": "TJSP",
          "categoria": null
        }
      ],
      "frequencia": "DIARIA",
      "status": "ENCONTRADO"
    },
    {
      "id": 1567034,
      "numero": "1157146-44.2024.8.26.0100",
      "criado_em": "2024-10-02T18:15:48+00:00",
      "data_ultima_verificacao": null,
      "tribunais": [
        {
          "id": 102,
          "nome": "Tribunal de Justiça de São Paulo",
          "sigla": "TJSP",
          "categoria": null
        }
      ],
      "frequencia": "DIARIA",
      "status": "ENCONTRADO"
    }
  ]
}
Exemplo de resposta (401):

{
  "error": "Unauthenticated"
}
Exemplo de resposta (402):

{
  "error": "Você não possui saldo em crédito da API."
}
HTTP Request
GET api/v2/monitoramentos/processos

Headers
Campo	Valor
Authorization	Bearer {access_token}
X-Requested-With	XMLHttpRequest
Retornar um monitoramento específico
Retorna um monitoramento de processos a partir do id

Exemplo de requisição:

import requests
import json

url = 'https://api.escavador.com/api/v2/monitoramentos/processos/1'

headers = {
  'Authorization': 'Bearer {access_token}',
  'X-Requested-With': 'XMLHttpRequest'
}

response = requests.request('GET', url, headers=headers)

if response and response.text:
  parsed = json.loads(response.text)
  print(json.dumps(parsed, indent=4))
// Esse é um exemplo de resposta bem-sucedida.
Exemplo de resposta (200):

{
  "id": 17,
  "numero": "0000001-00.2024.6.14.0000",
  "criado_em": "2024-11-19T20:35:09+00:00",
  "data_ultima_verificacao": null,
  "tribunais": [
    {
      "id": 50,
      "nome": "Tribunal Regional Eleitoral do Pará",
      "sigla": "TRE-PA",
      "categoria": null
    }
  ],
  "frequencia": "DIARIA",
  "status": "PENDENTE"
}
Exemplo de resposta (401):

{
  "error": "Unauthenticated"
}
Exemplo de resposta (402):

{
  "error": "Você não possui saldo em crédito da API."
}
Exemplo de resposta (404):

{
  "error": "NotFound"
}
HTTP Request
GET api/v2/monitoramentos/processos/{id}

Headers
Campo	Valor
Authorization	Bearer {access_token}
X-Requested-With	XMLHttpRequest
URI Parameters
Parâmetro	Tipo	Descrição
id	integer	Id do monitoramento.
Remover um monitoramento
Remove um monitoramento de processos a partir do id

Exemplo de requisição:

import requests
import json

url = 'https://api.escavador.com/api/v2/monitoramentos/processos/1'

headers = {
  'Authorization': 'Bearer {access_token}',
  'X-Requested-With': 'XMLHttpRequest'
}

response = requests.request('DELETE', url, headers=headers)

if response and response.text:
  parsed = json.loads(response.text)
  print(json.dumps(parsed, indent=4))
Exemplo de resposta (204):

[]
HTTP Request
DELETE api/v2/monitoramentos/processos/{id}

Headers
Campo	Valor
Authorization	Bearer {access_token}
X-Requested-With	XMLHttpRequest
URI Parameters
Parâmetro	Tipo	Descrição
id	integer	Id do monitoramento.
Resumo de processos (IA)
Solicita a geração/atualização do resumo inteligente de um processo.
Esta rota registra uma solicitação para gerar ou atualizar o resumo inteligente do processo. O resumo é baseado nos dados mais recentes disponíveis em nossa base. Para garantir que o resumo reflita as últimas alterações no tribunal, recomenda-se primeiro atualizar o processo através da rota Atualizar Processo.

Exemplo de requisição:

import requests
import json

url = 'https://api.escavador.com/api/v2/processos/numero_cnj/0018063-19.2013.8.26.0002/ia/resumo/solicitar-atualizacao'

headers = {
  'Authorization': 'Bearer {access_token}',
  'X-Requested-With': 'XMLHttpRequest'
}

response = requests.request('POST', url, headers=headers)

if response and response.text:
  parsed = json.loads(response.text)
  print(json.dumps(parsed, indent=4))
Exemplo de resposta (200):

{
  "id": 2001596,
  "status": "PENDENTE",
  "criado_em": "2025-01-13T21:01:26+00:00",
  "numero_cnj": "8118778-37.2021.8.05.0001",
  "concluido_em": null
}
Exemplo de resposta (401):

{
  "error": "Unauthenticated"
}
Exemplo de resposta (402):

{
  "error": "Você não possui saldo em crédito da API."
}
Exemplo de resposta (404):

{
  "code": "NOT_FOUND",
  "message": "Recurso não encontrado",
  "errors": null,
  "appends": null
}
Exemplo de resposta (422):

{
  "code": "NUMERO_CNJ_INVALIDO",
  "message": "O número do processo não está no formato CNJ.",
  "errors": null,
  "appends": null
}
HTTP Request
POST api/v2/processos/numero_cnj/{numero}/ia/resumo/solicitar-atualizacao

Headers
Campo	Valor
Authorization	Bearer {access_token}
X-Requested-With	XMLHttpRequest
URI Parameters
Parâmetro	Tipo	Descrição
numero	string	Número único do processo. Obrigatório estar no formato de CNJ.
Exemplo: 0000000-00.0000.0.00.0000
Resumo inteligente de um processo
Retorna o resumo inteligente do processo, caso o resumo já exista. No retorno, são exibidos o número CNJ do processo, o conteúdo do resumo (normalmente um texto resumido com os elementos essenciais do processo) e a data de atualização do resumo.

Exemplo de requisição:

import requests
import json

url = 'https://api.escavador.com/api/v2/processos/numero_cnj/0018063-19.2013.8.26.0002/ia/resumo'

headers = {
  'Authorization': 'Bearer {access_token}',
  'X-Requested-With': 'XMLHttpRequest'
}

response = requests.request('GET', url, headers=headers)

if response and response.text:
  parsed = json.loads(response.text)
  print(json.dumps(parsed, indent=4))
Exemplo de resposta (200):

{
  "numero_cnj": "8118778-37.2021.8.05.0001",
  "conteudo": "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Duis a nibh sit amet tellus elementum rhoncus. Mauris ullamcorper posuere odio sodales dictum. Etiam pellentesque euismod quam, a accumsan metus. Fusce lobortis, ipsum eget feugiat efficitur, urna nisi rhoncus tortor, vel interdum libero odio ac ligula. Phasellus sapien massa, malesuada eget augue eget, consectetur gravida elit. In at ipsum tempor, blandit metus quis, semper mauris. Nunc in sem ullamcorper, vestibulum ex et, volutpat velit.",
  "atualizado_em": "2025-01-13T21:01:33+00:00"
}
Exemplo de resposta (401):

{
  "error": "Unauthenticated"
}
Exemplo de resposta (402):

{
  "error": "Você não possui saldo em crédito da API."
}
Exemplo de resposta (404):

{
  "code": "NOT_FOUND",
  "message": "Recurso não encontrado",
  "errors": null,
  "appends": null
}
Exemplo de resposta (422):

{
  "code": "NUMERO_CNJ_INVALIDO",
  "message": "O número do processo não está no formato CNJ.",
  "errors": null,
  "appends": null
}
HTTP Request
GET api/v2/processos/numero_cnj/{numero}/ia/resumo

Headers
Campo	Valor
Authorization	Bearer {access_token}
X-Requested-With	XMLHttpRequest
URI Parameters
Parâmetro	Tipo	Descrição
numero	string	Número único do processo. Obrigatório estar no formato de CNJ.
Exemplo: 0000000-00.0000.0.00.0000
Status da solicitação de resumo inteligente
Permite consultar o status atual do resumo inteligente para um determinado processo. O status pode indicar, por exemplo, que a solicitação foi concluída (FINALIZADO) ou permanece em aberto.

Exemplo de requisição:

import requests
import json

url = 'https://api.escavador.com/api/v2/processos/numero_cnj/0018063-19.2013.8.26.0002/ia/resumo/status'

headers = {
  'Authorization': 'Bearer {access_token}',
  'X-Requested-With': 'XMLHttpRequest'
}

response = requests.request('GET', url, headers=headers)

if response and response.text:
  parsed = json.loads(response.text)
  print(json.dumps(parsed, indent=4))
Exemplo de resposta (200):

{
  "id": 2001596,
  "status": "FINALIZADO",
  "criado_em": "2025-01-13T21:01:27+00:00",
  "numero_cnj": "8118778-37.2021.8.05.0001",
  "concluido_em": "2025-01-13T21:01:33+00:00"
}
Exemplo de resposta (401):

{
  "error": "Unauthenticated"
}
Exemplo de resposta (402):

{
  "error": "Você não possui saldo em crédito da API."
}
Exemplo de resposta (404):

{
  "code": "NOT_FOUND",
  "message": "Recurso não encontrado",
  "errors": null,
  "appends": null
}
Exemplo de resposta (422):

{
  "code": "NUMERO_CNJ_INVALIDO",
  "message": "O número do processo não está no formato CNJ.",
  "errors": null,
  "appends": null
}
HTTP Request
GET api/v2/processos/numero_cnj/{numero}/ia/resumo/status

Headers
Campo	Valor
Authorization	Bearer {access_token}
X-Requested-With	XMLHttpRequest
URI Parameters
Parâmetro	Tipo	Descrição
numero	string	Número único do processo. Obrigatório estar no formato de CNJ.
Exemplo: 0000000-00.0000.0.00.0000
Status da solicitação de resumo inteligente
Campo	Descrição
PENDENTE	Aguardando o robô gerar o resumo inteligente.
FINALIZADO	Resumo inteligente gerado com sucesso.
Tribunais
Retornar os Tribunais disponíveis
Retorna a lista de tribunais que são utilizados na V2, utilize essa rota caso queira filtrar os processos por tribunal nas rotas que possuem essa opção.

Exemplo de requisição:

from escavador import *
from escavador.v2 import Tribunal
config("API_KEY")

response = Tribunal.listar(
  estados=['BA','SP']
)
// Esse é um exemplo de resposta bem-sucedida.
Exemplo de resposta (200):

{
  "items": [
    {
      "nome": "Supremo Tribunal Federal",
      "sigla": "STF",
      "categoria": null,
      "estados": []
    },
    {
      "nome": "Tribunal Regional do Trabalho da 1ª Região",
      "sigla": "TRT-1",
      "categoria": null,
      "estados": [
        {
          "nome": "Rio de Janeiro",
          "sigla": "RJ"
        }
      ]
    },
    {
      "nome": "Tribunal Regional do Trabalho da 2ª Região",
      "sigla": "TRT-2",
      "categoria": null,
      "estados": [
        {
          "nome": "São Paulo",
          "sigla": "SP"
        }
      ]
    },
    {
      "nome": "Tribunal Regional do Trabalho da 3ª Região",
      "sigla": "TRT-3",
      "categoria": null,
      "estados": [
        {
          "nome": "Minas Gerais",
          "sigla": "MG"
        }
      ]
    }
  ]
}
Exemplo de resposta (401):

{
  "error": "Unauthenticated"
}
Exemplo de resposta (402):

{
  "error": "Você não possui saldo em crédito da API."
}
Exemplo de resposta (404):

{
  "error": "NotFound"
}
HTTP Request
GET api/v2/tribunais

Headers
Campo	Valor
Authorization	Bearer {access_token}
X-Requested-With	XMLHttpRequest
Query Parameters
Parâmetro	Status	Descrição
estados[]	opcional	Filtra os tribunais de acordo com os estados enviados.
Estrutura das respostas
Introdução
Nesta seção você irá conhecer as estruturas de dados que os retornos de várias chamadas da API V2 do Escavador têm em comum. Entender essas estruturas possibilita saber quando um método projetado para um retorno específico da API pode também ser aplicado ao retorno de outra chamada diferente.

Abaixo, apresentamos cada uma das estruturas de dados e seus campos. Cada campo é descrito pela sua chave, seu significado, seus tipos possíveis, bem como uma indicação se sempre está presente ou pode ser omitido.

Estrutura Error
Resposta da API com sinalização de erro ocorrido.

Campo	Tipo Retorno	Sempre presente	Descrição	Exemplo
code	string	Sim	Código único do tipo de erro ocorrido	"UNPROCESSABLE_ENTITY"
message	string	Sim	Mensagem de erro	"Não foi possível processar a solicitação"
errors	object	Sim	Objeto contendo um detalhamento de cada erro ocorrido	{"nome": ["O campo nome é obrigatório quando cpf cnpj não está presente."], "cpf_cnpj": ["O campo cpf cnpj é obrigatório quando nome não está presente."]}
appends	null	Sim	Campo reservado para uso futuro	null
Estrutura Processo
Representação de um processo no seu estado atual.

Campo	Tipo Retorno	Sempre presente	Descrição	Exemplo
numero_cnj	string	Sim	Número único do processo no padrão CNJ	"0000000-00.0000.0.00.0000"
titulo_polo_ativo	string / null	Sim	Nome do polo ativo do processo	"Carlos Müller Lacerda da Paixão e outros"
titulo_polo_passivo	string / null	Sim	Nome do polo passivo do processo	"Banco do Brasil Investimentos S/A"
ano_inicio	integer	Sim	Ano de início do processo	2019
data_inicio	string / null	Sim	Data de início do processo no formato YYYY-MM-DD	"2019-01-01"
data_ultima_movimentacao	string	Sim	Data da última movimentação registrada, no formato YYYY-MM-DD	"2019-01-01"
quantidade_movimentacoes	integer	Sim	Quantidade de movimentações registradas	1
fontes_tribunais_estao_arquivadas	boolean	Sim	Indica se todas fontes do tipo "TRIBUNAL" estão arquivadas	false
data_ultima_verificacao	string	Sim	Momento da última verificação do processo nas fontes oficiais no formato ISO 8601	"2019-01-01T00:01:23+00:00"
tempo_desde_ultima_verificacao	string	Sim	Tempo decorrido desde a última verificação do processo	"há 1 mês"
fontes	array[FonteProcesso]	Sim	Fontes de onde o processo foi extraído	[{...}, {...}, ...]
Estrutura ProcessoFonte
Informações de um processo em relação a uma das fontes que foi extraído, tal como os dados desta fonte. Cada processo pode ter várias fontes.

Campo	Tipo Retorno	Sempre presente	Descrição	Exemplo
id	integer	Sim	Identificador único dessa fonte no sistema do Escavador	1
processo_fonte_id	integer	Sim	Identificador único do processo naquela fonte dentro do sistema do Escavador	1
descricao	string	Sim	Descrição da fonte	"Tribunal de Justiça de Minas Gerais"
nome	string	Sim	Nome da fonte	"Tribunal de Justiça de Minas Gerais"
sigla	string	Sim	Sigla da fonte	"TJMG"
tipo	string	Sim	Tipo da fonte	"TRIBUNAL"
data_inicio	string / null	Sim	Data de início da tramitação do processo naquela fonte, no formato YYYY-MM-DD	"2019-01-01"
data_ultima_movimentacao	string	Sim	Data da última movimentação registrada naquela fonte, no formato YYYY-MM-DD	"2019-01-01"
segredo_justica	boolean / null	Sim	Indica se o processo está sob segredo de justiça	false
arquivado	boolean / null	Sim	Indica se o processo está arquivado	false
status_predito	string / null	Sim	Indica se o processo está ATIVO ou INATIVO. null se a fonte for do tipo "DIARIO_OFICIAL"	ATIVO
grau	string	Sim	Grau da instância do processo nessa fonte	1
grau_formatado	string	Sim	Grau do processo por extenso	"Primeiro Grau"
fisico	boolean	Sim	Indica se o processo é físico ou eletrônico	false
sistema	string	Sim	Sistema de onde o processo foi extraído	"PROJUDI"
url	string	Sim	URL para acessar o processo na fonte, caso existir	"https://..."
quantidade_movimentacoes	integer	Sim	Quantidade de movimentações registradas naquela fonte	1
data_ultima_verificacao	string	Sim	Momento da última verificação do processo naquela fonte no formato ISO 8601	"2019-01-01T00:01:23+00:00"
envolvidos	**array[Envolvido]	Sim	Pessoas e instituições envolvidas no processo	[{...}, {...}, ...]
capa	CapaProcessoTribunal	Não	Informações da capa do processo, se a fonte for do tipo "TRIBUNAL"	{...}
tribunal	Tribunal	Não	Informações do tribunal, se a fonte for do tipo "TRIBUNAL"	{...}
caderno	string	Não	Título do caderno do diário oficial onde o processo foi publicado, se a fonte for do tipo "DIARIO_OFICIAL"	"Jurisdicional das Comarcas"
Estrutura ProcessoFonteCapa
Contém informações da capa de um processo em uma fonte, quando foi extraído de um tribunal.

Campo	Tipo Retorno	Sempre presente	Descrição	Exemplo
classe	string	Sim	Classe do processo	"Procedimento Comum"
assunto	string / null	Sim	Assunto do processo	"Responsabilidade Civil"
assuntos_normalizados	array[Assunto]	Sim	Assuntos do processo	[{...}, {...}, ...]
assunto_principal_normalizado	Assunto / null	Sim	Principal assunto do processo	{...}
area	string / null	Sim	Área do processo	"Cível"
orgao_julgador	string / null	Sim	Órgão responsável por julgar o processo	"1ª Vara Cível"
valor_causa	ValorCausa / null	Sim	Valor monetário da causa do processo	{...}
data_distribuicao	string / null	Sim	Data de distribuição do processo, no formato YYYY-MM-DD	"2019-01-01"
data_arquivamento	string / null	Sim	Data de arquivamento do processo, no formato YYYY-MM-DD	"2019-01-01"
informacoes_complementares	array[InformacaoComplementar] / null	Sim	Informações complementares	[{...}, {...}, ...]
Estrutura ValorCausa
Representa o valor monetário da causa de um processo.

Campo	Tipo Retorno	Sempre presente	Descrição	Exemplo
valor	string	Sim	Valor monetário da causa do processo, como string que contém um float	12345.6789
moeda	string	Sim	Moeda da causa do processo	"R$"
valor_formatado	string	Sim	Valor monetário da causa do processo, formatado	"R$ 12.345,68"
Estrutura InformacaoComplementar
Representação chave-valor para informações não-fundamentais de um processo.

Campo	Tipo Retorno	Sempre presente	Descrição	Exemplo
tipo	string	Sim	Tipo ou significado da informação	"Juiz"
valor	string	Sim	Valor da informação	"José da Silva"
Estrutura Assunto
Representa um assunto de que se trata um processo.

Campo	Tipo Retorno	Sempre presente	Descrição	Exemplo
id	integer	Sim	Identificador único do assunto no sistema do Escavador	1
nome	string	Sim	Descrição do assunto em específico	"Obrigação de Fazer / Não Fazer"
nome_com_pai	string	Sim	Descrição do assunto e seu pai (mais genérico)	"Liquidação / Cumprimento / Execução > Obrigação de Fazer / Não Fazer"
path_completo	string	Sim	Path completo do assunto, desde a raiz menos específica até o assunto em específico	"DIREITO PROCESSUAL CIVIL E DO TRABALHO > Liquidação / Cumprimento / Execução > Obrigação de Fazer / Não Fazer"
Estrutura Movimentação
Representação de uma movimentação de um processo.

Campo	Tipo Retorno	Sempre presente	Descrição	Exemplo
id	integer	Sim	Identificador único da movimentação no sistema do Escavador	12345678
data	string	Sim	Dia em que ocorreu, no formato YYYY-MM-DD	"2019-01-01"
tipo	string	Sim	Indica se a movimentação representa uma publicação ou andamento do processo	"PUBLICAÇÃO"
conteudo	string	Sim	Conteúdo da movimentação	"Distribuído em 01/01/2019 para: Tribunal Pleno"
fonte	MovimentacaoFonte	Sim	Fonte da movimentação	{...}
Estrutura MovimentacaoFonte
Representação da fonte da qual uma movimentação foi extraída, e informações da movimentação em relação a esta fonte.

Campo	Tipo Retorno	Sempre presente	Descrição	Exemplo
fonte_id	integer	Sim	Identificador único da fonte no sistema do Escavador	123
nome	string	Sim	Nome completo da fonte	"Tribunal de Justiça do Estado de São Paulo"
tipo	string	Sim	Tipo da fonte (TRIBUNAL ou DIARIO_OFICIAL)	"TRIBUNAL"
sigla	string	Sim	Sigla da fonte	"TJSP"
grau	integer	Sim	Grau do processo no momento da movimentação naquela fonte	1
grau_formatado	string	Sim	Grau do processo no momento da movimentação naquela fonte, formatado	"Primeiro Grau"
caderno	string / null	Não	Título do caderno do diário oficial onde a movimentação foi publicada, se a fonte for do tipo "DIARIO_OFICIAL"	"Jurisdicional das Comarcas"
Estrutura Envolvido
Representa as informações de um envolvido no contexto de um processo.

Campo	Tipo Retorno	Sempre presente	Descrição	Exemplo
nome	string / null	Sim	Nome do envolvido	"José da Silva"
quantidade_processos	integer	Sim	Quantidade de processos em que o envolvido é parte	1
tipo_pessoa	string	Sim	Indica se é pessoa física ou jurídica	"FISICA"
prefixo	string / null	Sim	Prefixo do envolvido, se tiver	"Dr."
sufixo	string / null	Sim	Sufixo do envolvido, se tiver	"- Foragido"
tipo	string / null	Sim	Tipo do envolvido naquele processo	"Relator"
tipo_normalizado	string / null	Sim		"Juiz"
polo	string / null	Sim	O polo do envolvido naquele processo (ATIVO, PASSIVO, ADVOGADO, etc).	"NENHUM"
cpf	string / null	Não	CPF do envolvido, se for pessoa física e este dado existir	"12345678900"
cnpj	string / null	Não	CNPJ do envolvido, se for pessoa jurídica e este dado existir	"12345678000190"
oabs	array[Oab]	Não	Lista de carteiras da OAB do envolvido, se for advogado	[{...}, {...}, ...]
advogados	array[Envolvido]	Não	Lista de advogados do envolvido, se tiver	[{...}, {...}, ...]
Estrutura EnvolvidoEncontrado
Informações essenciais de um envolvido encontrado em buscas de processos por envolvido.

Campo	Tipo Retorno	Sempre presente	Descrição	Exemplo
nome	string	Sim	Nome do envolvido	"Banco do Brasil Exportações S.A"
tipo_pessoa	string	Sim	Indica se é pessoa física ou jurídica	"JURIDICA"
quantidade_processos	integer	Sim	Quantidade de processos em que o envolvido é parte	1234
Estrutura Oab
Dados que caracterizam uma carteira da OAB.

Campo	Tipo Retorno	Sempre presente	Descrição	Exemplo
numero	string	Sim	Número da carteira	"123456"
uf	string	Sim	UF da carteira	"SP"
tipo	string	Sim	Tipo da carteira	"ADVOGADO"
Estrutura Tribunal
Dados que caracterizam um tribunal.

Campo	Tipo Retorno	Sempre presente	Descrição	Exemplo
id	integer	Sim	Id do tribunal	1
nome	string	Sim	Nome do tribunal	"Tribunal Superior do Trabalho"
sigla	string	Sim	Sigla do tribunal	"TST"
categoria	string	Sim	Categoria do tribunal	"Tribunais Superiores e Conselhos"
estados	array[Estado]	Sim	Estados que o tribunal pertence	[{...}, {...}, ...]
Estrutura Estado
Dados que caracterizam um Estado.

Campo	Tipo Retorno	Sempre presente	Descrição	Exemplo
nome	string	Sim	Nome do estado	"Bahia"
sigla	string	Sim	Sigla do estado	"BA"
Estrutura StatusAtualizacaoProcesso
Campo	Tipo Retorno	Sempre presente	Descrição	Exemplo
numero_cnj	string	Sim	Número do Processo	"0000000-00.0000.0.00.0000"
data_ultima_verificacao	data	Sim	Data que o processo foi verificado no Tribunal	"2023-03-02T21:31:56+00:00"
tempo_desde_ultima_verificacao	data	Sim	Tempo desde a ultima atualização	"há 2 meses"
ultima_verificacao	array[BuscaAtualizacaoProcesso]	Não	Objeto contendo informações da ultima verificação do Processo	[{...}, {...}, ...]
Estrutura BuscaAtualizacaoProcesso
Campo	Tipo Retorno	Sempre presente	Descrição	Exemplo
numero_cnj	string	Não	Número do Processo	"0000000-00.0000.0.00.0000"
id	integer	Sim	id da Busca de atualização	1
status	string	Sim	Status da atualização do processo	"PENDENTE"
criado_em	data	Sim	Data que a busca do robô foi inicializada	"2023-03-02T21:31:56+00:00"
concluido_em	data	Sim	Data que a busca do robô foi concluída	"2023-03-02T21:31:56+00:00"
Detalhes dos Callbacks
Introdução
Callbacks são avisos que o Escavador dispara (Via método POST) para certos eventos que ocorrem em sua conta.

As chamadas são enviadas com content-type application/json.

A URL de callback pode ser cadastrado pelo painel da API.

Para garantir que os callbacks recebidos tem como origem a API do Escavador, você pode gerar um token no painel da API. Esse token será enviado em todos os callbacks pelo header Authorization.

Em caso de ocorrer falha na entrega do webhook na url de callback cadastrada, o Escavador irá tentar enviar novamente mais 10 vezes. Sendo assim, um total de 11 tentativas serão feitas. Cada tentativa tem um intervalo de 2n minutos, sendo n o número da tentativa.

Estes são os eventos e seus respectivos dados enviados:

Monitoramento de novos processos: novo processo encontrado
Ocorre quando um Monitoramento de novos processos encontra algum processo novo.

Campos enviados no callback
Parâmetro	Descrição
event	novo_processo
monitoramento	Informações do Monitoramento.
processo	Informações do processo encontrado
POST JSON

{
   "event":"novo_processo",
   "monitoramento":{
      "id":11,
      "termo":"Bruno Souza Cabral",
      "criado_em":"2024-01-18T15:15:08+00:00",
      "variacoes":[],
      "termos_auxiliares":[]
   },
   "processo":{
      "numero_cnj":"0008649-70.2021.8.12.0110",
      "data_inicio":"2021-10-06",
      "tribunal":"TJMS",
      "estado_origem":{
         "nome":"Mato Grosso do Sul",
         "sigla":"MS"
      }
   },
   "uuid":"e774c93cbef5bbaab6bc6707f2609167"
}
Atualização de processos: atualização concluída
Ocorre quando uma atualização de processo é concluída e foi setado para enviar callback.

Campos enviados no callback
Parâmetro	Descrição
event	atualizacao_processo_concluida
atualizacao.id	ID da atualização
atualizacao.status.numero_cnj	Status da atualização, pode ser SUCESSO, NAO_ENCONTRADO ou ERRO
atualizacao.numero_cnj	Número do CNJ do processo
POST JSON

{
    "event": "atualizacao_processo_concluida",
    "atualizacao": {
        "id": 22,
        "status": "SUCESSO",
        "criado_em": "2024-02-07T17:07:44+00:00",
        "numero_cnj": "0011699-83.2017.5.15.0087",
        "concluido_em": "2024-02-07T17:08:46+00:00",
        "enviar_callback": "SIM"
    },
    "uuid": "65b45990e91de83f8f40483102ce97ca"
}
Monitoramento de processos: Nova movimentação encontrada
Ocorre quando uma nova movimentação é encontrada no sistema do tribunal ou diário oficial.

Campos enviados no callback
Parâmetro	Descrição
event	atualizacao_processo_concluida
monitoramento	Informações do Monitoramento.
movimentacao	Informações da movimentacao encontrada
movimentacao.tipo	Para identificar se a origem é do tribunal ou diário oficial: ANDAMENTO ou PUBLICACAO
POST JSON

{
   "event":"nova_movimentacao",
   "monitoramento":{
      "id":1567024,
      "numero":"1002089-72.2023.8.26.0260",
      "criado_em":"2024-10-02T18:01:34+00:00",
      "data_ultima_verificacao":null,
      "tribunais":[
         {
            "id":102,
            "nome":"Tribunal de Justiça de São Paulo",
            "sigla":"TJSP",
            "categoria":null
         }
      ],
      "frequencia":"DIARIA",
      "status":"ENCONTRADO"
   },
   "movimentacao":{
      "id":23895909833,
      "data":"2024-10-01",
      "tipo":"ANDAMENTO",
      "tipo_publicacao":null,
      "classificacao_predita":{
         "nome":"Antecipação de tutela",
         "descricao":"É a decisão que concede o pedido de tutela antecipada formulado pela parte. Pode ocorrer em momento liminar (antes da oitiva do Réu) ou durante o curso do processo.",
         "hierarquia":"Movimentações do Magistrado > Decisão > Concessão > Antecipação de tutela"
      },
      "conteudo":"Pedido de Liminar/Antecipação de Tutela",
      "texto_categoria":null,
      "fonte":{
         "processo_fonte_id":538793371,
         "fonte_id":1,
         "nome":"Tribunal de Justiça de São Paulo",
         "tipo":"TRIBUNAL",
         "sigla":"TJSP",
         "grau":1,
         "grau_formatado":"Primeiro Grau"
      }
   },
   "uuid":"65b45990e91de83f8f40483102ce97ca"
}
Monitoramento de processos: Processo encontrado
Ocorre quando um Monitoramento de processos encontra o processo no sistema do tribunal e inicia o monitoramento.

Campos enviados no callback
Parâmetro	Descrição
event	processo_encontrado
monitoramento	Informações do Monitoramento.
POST JSON

{
   "event":"processo_encontrado",
   "monitoramento":{
      "id":1567024,
      "numero":"1002089-72.2023.8.26.0260",
      "criado_em":"2024-10-02T18:01:34+00:00",
      "data_ultima_verificacao":null,
      "tribunais":[
         {
            "id":102,
            "nome":"Tribunal de Justiça de São Paulo",
            "sigla":"TJSP",
            "categoria":null
         }
      ],
      "frequencia":"DIARIA",
      "status":"ENCONTRADO"
   },
   "uuid":"65b45990e91de83f8f40483102ce97ca"
}
Monitoramento de processos: Processo não encontrado
Ocorre quando um Monitoramento de processos não encontra o processo no sistema do tribunal e assim ele não é monitorado.

Campos enviados no callback
Parâmetro	Descrição
event	processo_nao_encontrado
monitoramento	Informações do Monitoramento.
POST JSON

{
   "event":"processo_nao_encontrado",
   "monitoramento":{
      "id":1567024,
      "numero":"1002089-72.2023.8.26.0260",
      "criado_em":"2024-10-02T18:01:34+00:00",
      "data_ultima_verificacao":null,
      "tribunais":[
         {
            "id":102,
            "nome":"Tribunal de Justiça de São Paulo",
            "sigla":"TJSP",
            "categoria":null
         }
      ],
      "frequencia":"DIARIA",
      "status":"NAO_ENCONTRADO"
   },
   "uuid":"65b45990e91de83f8f40483102ce97ca"
}
bashjavascriptphppython
