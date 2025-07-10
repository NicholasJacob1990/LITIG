### Atualização do fluxo – **exibição e escolha de advogados por distância + filtros de preferência**

| Nº    | Fase                                      | Ações do usuário / sistema                                                                                                                                                                    | Entregas específicas                                                                                                                                                                     |                                                                           |
| ----- | ----------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------- |
| **0** | **On-boarding**                           | PF ou PJ cria conta, aceita Termo LGPD/OAB, decide se compartilha GPS.                                                                                                                        | —                                                                                                                                                                                        |                                                                           |
| **1** | **Entrada da dúvida & Triagem IA**        | Cliente descreve o caso → IA devolve **Síntese Jurídica**.                                                                                                                                    | Síntese enviada a cliente e advogados (passo já revisado).                                                                                                                               |                                                                           |
| **2** | **Busca de advogados próximos**           | App solicita posição via GPS **ou** CEP digitado.<br>Automático: raio inicial = 20 km.                                                                                                        | Chamada Supabase RPC `lawyers_nearby(lat, lng, radius, area)` ordena por distância ↑ e rating ↓ (PostGIS + `earth_distance`).                                                            |                                                                           |
| **3** | **Tela “Escolha seu advogado”**           | Mapa (Mapbox/Google) + lista em “sheet” deslizante. Cada card mostra:<br>• Nome + foto<br>• Área principal<br>• ★ rating<br>• Distância (“a 2,3 km”)<br>• Nº OAB + formação resumida          | Endereço exato só após contratação (boa prática LGPD/OAB).                                                                                                                               |                                                                           |
| **4** | **Filtros de preferência** (topo do mapa) | *Raio* (slider 5-100 km)                                                                                                                                                                      | atualiza consulta RPC <br>*Áreas* (multi-select) <br>*Idiomas* (pt, en, es…) <br>*Disponível agora* (toggle) <br>*Avaliação mínima* (★ 3 a 5) <br>*Modalidade* (chat, vídeo, presencial) | Todos os filtros trafegam como query-params → RPC refina e devolve lista. |
| **5** | **Opções de seleção**                     | **A)** Cliente toca num card → tela de “Pré-visualização” com botão **Agendar**.<br>**B)** Botão “Deixar o sistema escolher” = atribuição automática do primeiro da lista (distância+rating). | Log \`audit.choice\_type = 'manual'                                                                                                                                                      | 'auto'\` para compliance.                                                 |
| **6** | **Boas-vindas e pagamento**               | Caso já atribuído → advogado envia 1.ª mensagem; cliente escolhe plano e paga.                                                                                                                | Resto do fluxo permanece igual (chat/vídeo, relatório, NPS).                                                                                                                             |                                                                           |

---

### Implementação técnica (mobile–first)

1. **Permissão & fallback**

   ```ts
   const pos = await Location.getCurrentPositionAsync({ accuracy: Location.Accuracy.High })
      .catch(() => undefined); // usuário negou
   ```

   Se `pos` indefinido → campo CEP; geocodifica via OpenStreetMap.

2. **Endpoint SQL (Supabase)**

   ```sql
   CREATE OR REPLACE FUNCTION lawyers_nearby(
     _lat double precision,
     _lng double precision,
     _radius_km double precision,
     _area text,
     _rating_min double precision,
     _available bool)
   RETURNS TABLE(...) AS $$
     SELECT *, earth_distance(...)/1000 AS distance_km
     FROM   lawyers
     WHERE  _area IS NULL OR primary_area ILIKE _area
     AND    rating >= _rating_min
     AND    (_available = false OR is_available = true)
     AND    earth_box(ll_to_earth(_lat,_lng), _radius_km*1000) @> ll_to_earth(lat,lng)
     ORDER  BY distance_km ASC, rating DESC
   $$ LANGUAGE sql STABLE;
   ```

3. **Interface React Native**

   ```tsx
   <MapView ...>
     {lawyers.map(l => (
       <Marker key={l.id} coordinate={{ latitude: l.lat, longitude: l.lng }}>
         <Avatar source={{ uri: l.avatar }} />
       </Marker>
     ))}
   </MapView>

   <BottomSheet>
     <Filters onChange={setQuery}/>
     <FlatList data={lawyers} renderItem={LawyerCard}/>
   </BottomSheet>
   ```

4. **Privacidade & OAB**

   * Mostrar **somente distância aproximada** até a contratação.
   * Sem valores exatos de honorários na listagem (evita infração de mercantilização).
   * Logs `audit.geosearch` guardam lat/lng truncados (2 casas) + timestamp.

5. **Experiência**

   * Animação “Draw route” opcional se consulta presencial.
   * Placeholder “Nenhum profissional no raio X km” com CTA “Aumentar raio ou filtre por remoto”.

---

#### Resultado

* O usuário sempre vê profissionais **ordenados por proximidade** com filtros de preferência.
* A designação automática continua disponível para quem quiser agilidade.
* Todo processo mantém rastreabilidade e conformidade com a OAB e a LGPD.
