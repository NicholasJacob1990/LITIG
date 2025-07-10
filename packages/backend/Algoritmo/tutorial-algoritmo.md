### 🔧 Como “plugar” o Algoritmo Único no **projeto LITGO6** (React-Native + Expo + Supabase)

> Você já tem um app Expo com pastas como
> `app/triagem.tsx`, `app/NewCase.tsx`, `app/(tabs)/advogados.tsx` e autenticação Supabase.
> O back-end Python que criamos na resposta anterior ficará **escondido** em `https://api.seudominio.com`.

---

## 1.  Backend Python já pronto

Certifique-se de ter publicado os três endpoints:

| End-point          | O que faz                                                |
| ------------------ | -------------------------------------------------------- |
| `POST /api/triage` | Chama Claude → devolve `{id, summary, area, urgency_h}`  |
| `POST /api/embed`  | Devolve vetor `[384]` do resumo                          |
| `POST /api/match`  | Devolve lista ordenada `[{ … lawyer … fair … explain }]` |

> **Todos** os segredos (Service Key Supabase, chaves API) estão só no servidor.

---

## 2.  Adicione a URL da API no app

```
# .env
API_URL=https://api.seudominio.com
```

> Se você já usa `expo-constants`, instale `react-native-dotenv` ou coloque essa URL no `app.config.js`.

---

## 3.  Crie um **serviço de API** no front-end

`src/services/api.ts`

```ts
const API = process.env.EXPO_PUBLIC_API_URL || process.env.API_URL;

export async function triage(texto: string) {
  const r = await fetch(`${API}/api/triage`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ texto_cliente: texto })
  });
  return r.json();           // { id, summary, area, urgency_h }
}

export async function embed(summary: string) {
  const r = await fetch(`${API}/api/embed`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ text: summary })
  });
  return r.json();           // [vector]
}

export async function match(caseId: string, k = 5) {
  const r = await fetch(`${API}/api/match`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ case_id: caseId, k })
  });
  return r.json();           // [{ lawyer_id, nome, fair, ... }]
}
```

---

## 4.  Conecte ao formulário **`app/triagem.tsx`**

```tsx
import { triage, embed, match } from '@/services/api';
import { useRouter } from 'expo-router';

export default function TriagemScreen() {
  const [texto, setTexto] = useState('');
  const [loading, setLoading] = useState(false);
  const router = useRouter();

  const handleEnviar = async () => {
    if (!texto) return;
    setLoading(true);

    // 1) Triagem LLM
    const caso = await triage(texto);

    // 2) Embedding (envia ao back que já salva no Supabase)
    await embed(caso.summary);

    // 3) Ranking
    const advs = await match(caso.id);

    // 4) Navega p/ tela de matches
    router.push({
      pathname: '/(tabs)/advogados',
      params: { data: JSON.stringify(advs) }
    });
    setLoading(false);
  };

  /* … UI: textarea + botão … */
}
```

---

## 5.  Renderize a lista em **`app/(tabs)/advogados.tsx`**

```tsx
import { useLocalSearchParams } from 'expo-router';

export default function AdvogadosScreen() {
  const { data } = useLocalSearchParams<{ data: string }>();
  const lista = JSON.parse(data ?? '[]');

  return (
    <ScrollView className="p-4">
      {lista.map((l: any) => (
        <View key={l.lawyer_id} className="border rounded p-4 mb-3">
          <Text className="font-bold">{l.nome}</Text>
          <Text>Score {Math.round(l.fair * 100)} %</Text>
          <Text>Êxito {Math.round(l.taxa_sucesso * 100)} %</Text>
          <Text className="italic mt-1">{l.explain}</Text>
          <Button title="Conversar" onPress={() =>
            router.push({ pathname: '/chat', params: { lawyerId: l.lawyer_id } })
          } />
        </View>
      ))}
    </ScrollView>
  );
}
```

*(Se já existir uma tela de “LawyerDetails”, apenas passe o `lawyer_id`.)*

---

## 6.  Ajuste as Rotas se usar `expo-router`

*Certifique-se de ter*:

```
app/
 ├─ triagem.tsx           // coleta relato
 ├─ (tabs)/
 │   ├─ advogados.tsx     // lista matches
 │   └─ lawyer-details.tsx
```

> `router.push('/triagem')` ➜ coleta ➜ push para `/advogados`.

---

## 7.  Tratamento de áudio (opcional)

Use `expo-speech` + `expo-av` para gravar voz, transcrevê-la com Whisper API **no back-end** e reaproveitar o fluxo acima (envie texto transcrito para `/api/triage`).

---

## 8.  Segurança visível

* Front-end **nunca** expõe Service Key Supabase ou chave Claude.
* Apenas `API_URL` fica no bundle; sem ela o atacante não tem acesso ao banco.
* Back-end exige cabeçalho `Authorization: Bearer <jwt>` caso queira validar usuário; basta enviar `session.access_token` do Supabase.

---

## 9.  Checklist de publicação

1. `EXPO_PUBLIC_API_URL` setado no **Dashboard Expo** → *Environment variables*.
2. Back-end Python hospedado (Render/Railway/Cloud Run) com SSL.
3. CORS do FastAPI:

   ```py
   app.add_middleware(
       CORSMiddleware,
       allow_origins=["https://app.seudominio.com"],
       allow_methods=["POST"],
       allow_headers=["*"],
   )
   ```
4. Teste no Expo Go → web → build (EAS) → loja.

---

### Pronto!

O seu aplicativo já conversa com o back-end “escondido” em Python, recebe o ranking inteligente e mostra aos usuários – sem que nenhuma lógica sensível apareça no código do app. Se precisar de ajuda com algum arquivo específico do projeto LITGO6, é só dizer qual!
