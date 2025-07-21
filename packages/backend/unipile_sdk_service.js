#!/usr/bin/env node

/**
 * Unipile SDK Service - Serviço Node.js usando o SDK oficial da Unipile
 * ====================================================================
 * 
 * Este serviço utiliza o SDK oficial da Unipile para simplificar a integração
 * e garantir compatibilidade com as melhores práticas da API.
 * 
 * VERSÃO 3.0 - Adicionado suporte para Instagram, Facebook e Calendários
 * 
 * Baseado na documentação:
 * - https://developer.unipile.com/reference/accountscontroller_listaccounts
 * - https://developer.unipile.com/reference/calendarscontroller_listcalendars
 * - https://developer.unipile.com/reference/calendarscontroller_createcalendarevent
 * - https://www.unipile.com/instagram-profile-api-a-complete-developers-guide-to-smarter-integration-with-unipile/
 * - https://www.unipile.com/communication-api/messaging-api/linkedin-api/
 * - SDK: npm install unipile-node-sdk
 */

const { UnipileClient } = require('unipile-node-sdk');

class UnipileSDKService {
    constructor() {
        this.dsn = process.env.UNIPILE_DSN || 'api.unipile.com';
        this.accessToken = process.env.UNIPILE_API_TOKEN;
        
        if (!this.accessToken) {
            throw new Error('UNIPILE_API_TOKEN environment variable is required');
        }
        
        // Inicializa o cliente Unipile
        this.client = new UnipileClient(`https://${this.dsn}`, this.accessToken);
    }

    /**
     * Lista todas as contas conectadas usando o SDK
     */
    async listAccounts() {
        try {
            const accounts = await this.client.account.list();
            return {
                success: true,
                data: accounts,
                timestamp: new Date().toISOString()
            };
        } catch (error) {
            return {
                success: false,
                error: error.message,
                timestamp: new Date().toISOString()
            };
        }
    }

    /**
     * Conecta uma conta do LinkedIn
     */
    async connectLinkedIn(credentials) {
        try {
            const linkedinAccount = await this.client.account.connectLinkedin({
                username: credentials.username,
                password: credentials.password,
            });
            
            return {
                success: true,
                data: linkedinAccount,
                timestamp: new Date().toISOString()
            };
        } catch (error) {
            return {
                success: false,
                error: error.message,
                timestamp: new Date().toISOString()
            };
        }
    }

    /**
     * 🆕 Conecta uma conta do Instagram
     */
    async connectInstagram(credentials) {
        try {
            const instagramAccount = await this.client.account.connectInstagram({
                username: credentials.username,
                password: credentials.password,
            });
            
            return {
                success: true,
                data: instagramAccount,
                provider: 'instagram',
                timestamp: new Date().toISOString()
            };
        } catch (error) {
            return {
                success: false,
                error: error.message,
                provider: 'instagram',
                timestamp: new Date().toISOString()
            };
        }
    }

    /**
     * 🆕 Conecta uma conta do Facebook/Messenger
     */
    async connectFacebook(credentials) {
        try {
            const facebookAccount = await this.client.account.connectFacebook({
                username: credentials.username,
                password: credentials.password,
            });
            
            return {
                success: true,
                data: facebookAccount,
                provider: 'facebook',
                timestamp: new Date().toISOString()
            };
        } catch (error) {
            return {
                success: false,
                error: error.message,
                provider: 'facebook',
                timestamp: new Date().toISOString()
            };
        }
    }

    /**
     * Recupera o perfil de uma empresa no LinkedIn
     */
    async getCompanyProfile(accountId, identifier) {
        try {
            const companyProfile = await this.client.users.getCompanyProfile({
                account_id: accountId,
                identifier: identifier,
            });
            
            return {
                success: true,
                data: companyProfile,
                timestamp: new Date().toISOString()
            };
        } catch (error) {
            return {
                success: false,
                error: error.message,
                timestamp: new Date().toISOString()
            };
        }
    }

    /**
     * 🆕 Recupera perfil completo do Instagram
     */
    async getInstagramProfile(accountId) {
        try {
            const profile = await this.client.users.getProfile({
                account_id: accountId,
                provider: 'instagram'
            });
            
            return {
                success: true,
                data: {
                    ...profile,
                    provider: 'instagram',
                    engagement_metrics: await this._calculateInstagramEngagement(accountId)
                },
                timestamp: new Date().toISOString()
            };
        } catch (error) {
            return {
                success: false,
                error: error.message,
                provider: 'instagram',
                timestamp: new Date().toISOString()
            };
        }
    }

    /**
     * 🆕 Recupera perfil completo do Facebook
     */
    async getFacebookProfile(accountId) {
        try {
            const profile = await this.client.users.getProfile({
                account_id: accountId,
                provider: 'facebook'
            });
            
            return {
                success: true,
                data: {
                    ...profile,
                    provider: 'facebook',
                    engagement_metrics: await this._calculateFacebookEngagement(accountId)
                },
                timestamp: new Date().toISOString()
            };
        } catch (error) {
            return {
                success: false,
                error: error.message,
                provider: 'facebook',
                timestamp: new Date().toISOString()
            };
        }
    }

    /**
     * 🆕 Lista posts do Instagram com métricas
     */
    async getInstagramPosts(accountId, options = {}) {
        try {
            const posts = await this.client.posts.list({
                account_id: accountId,
                provider: 'instagram',
                limit: options.limit || 50,
                ...options
            });
            
            return {
                success: true,
                data: {
                    posts: posts,
                    analytics: await this._analyzeInstagramPosts(posts)
                },
                provider: 'instagram',
                timestamp: new Date().toISOString()
            };
        } catch (error) {
            return {
                success: false,
                error: error.message,
                provider: 'instagram',
                timestamp: new Date().toISOString()
            };
        }
    }

    /**
     * 🆕 Lista posts do Facebook com métricas
     */
    async getFacebookPosts(accountId, options = {}) {
        try {
            const posts = await this.client.posts.list({
                account_id: accountId,
                provider: 'facebook',
                limit: options.limit || 50,
                ...options
            });
            
            return {
                success: true,
                data: {
                    posts: posts,
                    analytics: await this._analyzeFacebookPosts(posts)
                },
                provider: 'facebook',
                timestamp: new Date().toISOString()
            };
        } catch (error) {
            return {
                success: false,
                error: error.message,
                provider: 'facebook',
                timestamp: new Date().toISOString()
            };
        }
    }

    /**
     * 🆕 Obtém dados consolidados de todas as redes sociais
     */
    async getSocialProfiles(accountIds) {
        try {
            const results = {};
            
            for (const [provider, accountId] of Object.entries(accountIds)) {
                switch (provider) {
                    case 'linkedin':
                        results.linkedin = await this.getCompanyProfile(accountId, 'profile');
                        break;
                    case 'instagram':
                        results.instagram = await this.getInstagramProfile(accountId);
                        break;
                    case 'facebook':
                        results.facebook = await this.getFacebookProfile(accountId);
                        break;
                }
            }
            
            return {
                success: true,
                data: {
                    profiles: results,
                    social_score: await this._calculateSocialScore(results)
                },
                timestamp: new Date().toISOString()
            };
        } catch (error) {
            return {
                success: false,
                error: error.message,
                timestamp: new Date().toISOString()
            };
        }
    }

    /**
     * Conecta uma conta de email (Gmail/Outlook)
     */
    async connectEmail(provider, credentials) {
        try {
            let emailAccount;
            
            switch (provider.toLowerCase()) {
                case 'gmail':
                    emailAccount = await this.client.account.connectGmail(credentials);
                    break;
                case 'outlook':
                    emailAccount = await this.client.account.connectOutlook(credentials);
                    break;
                default:
                    throw new Error(`Unsupported email provider: ${provider}`);
            }
            
            return {
                success: true,
                data: emailAccount,
                timestamp: new Date().toISOString()
            };
        } catch (error) {
            return {
                success: false,
                error: error.message,
                timestamp: new Date().toISOString()
            };
        }
    }

    /**
     * Lista emails de uma conta específica
     */
    async listEmails(accountId, options = {}) {
        try {
            const emails = await this.client.messaging.list({
                account_id: accountId,
                ...options
            });
            
            return {
                success: true,
                data: emails,
                timestamp: new Date().toISOString()
            };
        } catch (error) {
            return {
                success: false,
                error: error.message,
                timestamp: new Date().toISOString()
            };
        }
    }

    /**
     * Envia um email
     */
    async sendEmail(accountId, emailData) {
        try {
            const result = await this.client.messaging.send({
                account_id: accountId,
                ...emailData
            });
            
            return {
                success: true,
                data: result,
                timestamp: new Date().toISOString()
            };
        } catch (error) {
            return {
                success: false,
                error: error.message,
                timestamp: new Date().toISOString()
            };
        }
    }

    /**
     * 🆕 Calcula métricas de engajamento do Instagram
     */
    async _calculateInstagramEngagement(accountId) {
        try {
            const recentPosts = await this.getInstagramPosts(accountId, { limit: 20 });
            if (!recentPosts.success) return { engagement_rate: 0 };
            
            const posts = recentPosts.data.posts;
            const totalEngagement = posts.reduce((sum, post) => {
                const likes = post.likes_count || 0;
                const comments = post.comments_count || 0;
                return sum + likes + comments;
            }, 0);
            
            const avgEngagement = totalEngagement / posts.length;
            
            return {
                engagement_rate: avgEngagement,
                posts_analyzed: posts.length,
                avg_likes: posts.reduce((sum, p) => sum + (p.likes_count || 0), 0) / posts.length,
                avg_comments: posts.reduce((sum, p) => sum + (p.comments_count || 0), 0) / posts.length
            };
        } catch (error) {
            return { engagement_rate: 0, error: error.message };
        }
    }

    /**
     * 🆕 Calcula métricas de engajamento do Facebook
     */
    async _calculateFacebookEngagement(accountId) {
        try {
            const recentPosts = await this.getFacebookPosts(accountId, { limit: 20 });
            if (!recentPosts.success) return { engagement_rate: 0 };
            
            const posts = recentPosts.data.posts;
            const totalEngagement = posts.reduce((sum, post) => {
                const likes = post.likes_count || 0;
                const comments = post.comments_count || 0;
                const shares = post.shares_count || 0;
                return sum + likes + comments + shares;
            }, 0);
            
            const avgEngagement = totalEngagement / posts.length;
            
            return {
                engagement_rate: avgEngagement,
                posts_analyzed: posts.length,
                avg_likes: posts.reduce((sum, p) => sum + (p.likes_count || 0), 0) / posts.length,
                avg_comments: posts.reduce((sum, p) => sum + (p.comments_count || 0), 0) / posts.length,
                avg_shares: posts.reduce((sum, p) => sum + (p.shares_count || 0), 0) / posts.length
            };
        } catch (error) {
            return { engagement_rate: 0, error: error.message };
        }
    }

    /**
     * 🆕 Calcula score social consolidado
     */
    async _calculateSocialScore(profiles) {
        try {
            let score = 0;
            let totalWeight = 0;
            
            // LinkedIn (35% do peso)
            if (profiles.linkedin?.success) {
                const linkedinData = profiles.linkedin.data;
                const connections = linkedinData.connections_count || 0;
                const linkedinScore = Math.min(connections / 500, 1) * 0.35;
                score += linkedinScore;
                totalWeight += 0.35;
            }
            
            // Instagram (30% do peso)
            if (profiles.instagram?.success) {
                const instagramData = profiles.instagram.data;
                const followers = instagramData.followers_count || 0;
                const engagement = instagramData.engagement_metrics?.engagement_rate || 0;
                const instagramScore = (Math.min(followers / 10000, 1) * 0.2 + Math.min(engagement / 100, 1) * 0.1) * 0.30;
                score += instagramScore;
                totalWeight += 0.30;
            }
            
            // Facebook (25% do peso)
            if (profiles.facebook?.success) {
                const facebookData = profiles.facebook.data;
                const friends = facebookData.friends_count || 0;
                const engagement = facebookData.engagement_metrics?.engagement_rate || 0;
                const facebookScore = (Math.min(friends / 5000, 1) * 0.15 + Math.min(engagement / 50, 1) * 0.1) * 0.25;
                score += facebookScore;
                totalWeight += 0.25;
            }
            
            return {
                overall_score: totalWeight > 0 ? (score / totalWeight) : 0,
                breakdown: {
                    linkedin: profiles.linkedin?.success ? 'connected' : 'not_connected',
                    instagram: profiles.instagram?.success ? 'connected' : 'not_connected',
                    facebook: profiles.facebook?.success ? 'connected' : 'not_connected'
                },
                recommendation: this._getSocialRecommendation(score, totalWeight)
            };
        } catch (error) {
            return { overall_score: 0, error: error.message };
        }
    }

    /**
     * 🆕 Gera recomendações para melhorar presença social
     */
    _getSocialRecommendation(score, totalWeight) {
        if (totalWeight === 0) {
            return "Conecte pelo menos uma rede social para começar a construir sua presença digital.";
        }
        
        const normalizedScore = score / totalWeight;
        
        if (normalizedScore >= 0.8) {
            return "Excelente presença social! Continue engajando com sua audiência.";
        } else if (normalizedScore >= 0.6) {
            return "Boa presença social. Considere aumentar a frequência de posts e interações.";
        } else if (normalizedScore >= 0.4) {
            return "Presença social moderada. Foque em aumentar conexões e engajamento.";
        } else {
            return "Presença social baixa. Recomendamos conectar mais redes e aumentar atividade.";
        }
    }

    /**
     * 🆕 Analisa qualidade e temas dos posts do Instagram
     */
    async _analyzeInstagramPosts(posts) {
        return {
            total_posts: posts.length,
            avg_engagement: posts.reduce((sum, p) => sum + ((p.likes_count || 0) + (p.comments_count || 0)), 0) / posts.length,
            content_types: this._analyzeContentTypes(posts),
            posting_frequency: this._calculatePostingFrequency(posts),
            professional_content_ratio: this._calculateProfessionalContentRatio(posts)
        };
    }

    /**
     * 🆕 Analisa qualidade e temas dos posts do Facebook
     */
    async _analyzeFacebookPosts(posts) {
        return {
            total_posts: posts.length,
            avg_engagement: posts.reduce((sum, p) => sum + ((p.likes_count || 0) + (p.comments_count || 0) + (p.shares_count || 0)), 0) / posts.length,
            content_types: this._analyzeContentTypes(posts),
            posting_frequency: this._calculatePostingFrequency(posts),
            professional_content_ratio: this._calculateProfessionalContentRatio(posts)
        };
    }

    /**
     * 🆕 Analisa tipos de conteúdo (foto, vídeo, texto)
     */
    _analyzeContentTypes(posts) {
        const types = { photo: 0, video: 0, text: 0, carousel: 0 };
        
        posts.forEach(post => {
            if (post.media_type) {
                types[post.media_type] = (types[post.media_type] || 0) + 1;
            } else if (post.attachments?.length > 0) {
                types.photo += 1;
            } else {
                types.text += 1;
            }
        });
        
        return types;
    }

    /**
     * 🆕 Calcula frequência de postagem
     */
    _calculatePostingFrequency(posts) {
        if (posts.length < 2) return { frequency: 'insufficient_data' };
        
        const dates = posts.map(p => new Date(p.created_at)).sort((a, b) => b - a);
        const daysDiff = (dates[0] - dates[dates.length - 1]) / (1000 * 60 * 60 * 24);
        const postsPerWeek = (posts.length / daysDiff) * 7;
        
        return {
            posts_per_week: postsPerWeek,
            frequency_rating: postsPerWeek >= 3 ? 'high' : postsPerWeek >= 1 ? 'medium' : 'low'
        };
    }

    /**
     * 🆕 Calcula ratio de conteúdo profissional vs pessoal
     */
    _calculateProfessionalContentRatio(posts) {
        const professionalKeywords = [
            'direito', 'advogado', 'jurídico', 'lei', 'justiça', 'tribunal', 
            'processo', 'cliente', 'escritório', 'oab', 'advocacia'
        ];
        
        let professionalCount = 0;
        
        posts.forEach(post => {
            const text = (post.text || '').toLowerCase();
            const hasProfessionalContent = professionalKeywords.some(keyword => 
                text.includes(keyword)
            );
            
            if (hasProfessionalContent) {
                professionalCount++;
            }
        });
        
        return {
            professional_posts: professionalCount,
            total_posts: posts.length,
            professional_ratio: posts.length > 0 ? professionalCount / posts.length : 0,
            rating: professionalCount / posts.length >= 0.3 ? 'high' : 'low'
        };
    }

    // ========================================
    // 📅 MÉTODOS DE CALENDÁRIO (NOVO v3.0)
    // ========================================

    /**
     * 📅 Lista todos os calendários de uma conta
     */
    async listCalendars(accountId) {
        try {
            const calendars = await this.client.calendars.list({
                account_id: accountId
            });
            
            return {
                success: true,
                data: calendars,
                provider: 'calendar',
                timestamp: new Date().toISOString()
            };
        } catch (error) {
            return {
                success: false,
                error: error.message,
                provider: 'calendar',
                timestamp: new Date().toISOString()
            };
        }
    }

    /**
     * 📅 Obtém um calendário específico
     */
    async getCalendar(calendarId, accountId) {
        try {
            const calendar = await this.client.calendars.get({
                calendar_id: calendarId,
                account_id: accountId
            });
            
            return {
                success: true,
                data: calendar,
                provider: 'calendar',
                timestamp: new Date().toISOString()
            };
        } catch (error) {
            return {
                success: false,
                error: error.message,
                provider: 'calendar',
                timestamp: new Date().toISOString()
            };
        }
    }

    /**
     * 📅 Lista eventos de um calendário específico
     */
    async listCalendarEvents(calendarId, options = {}) {
        try {
            const events = await this.client.calendars.listEvents({
                calendar_id: calendarId,
                ...options
            });
            
            return {
                success: true,
                data: events,
                provider: 'calendar',
                calendar_id: calendarId,
                timestamp: new Date().toISOString()
            };
        } catch (error) {
            return {
                success: false,
                error: error.message,
                provider: 'calendar',
                calendar_id: calendarId,
                timestamp: new Date().toISOString()
            };
        }
    }

    /**
     * 📅 Cria um novo evento no calendário
     */
    async createCalendarEvent(calendarId, eventData) {
        try {
            const event = await this.client.calendars.createEvent({
                calendar_id: calendarId,
                ...eventData
            });
            
            return {
                success: true,
                data: event,
                provider: 'calendar',
                calendar_id: calendarId,
                timestamp: new Date().toISOString()
            };
        } catch (error) {
            return {
                success: false,
                error: error.message,
                provider: 'calendar',
                calendar_id: calendarId,
                timestamp: new Date().toISOString()
            };
        }
    }

    /**
     * 📅 Obtém um evento específico
     */
    async getCalendarEvent(calendarId, eventId) {
        try {
            const event = await this.client.calendars.getEvent({
                calendar_id: calendarId,
                event_id: eventId
            });
            
            return {
                success: true,
                data: event,
                provider: 'calendar',
                calendar_id: calendarId,
                event_id: eventId,
                timestamp: new Date().toISOString()
            };
        } catch (error) {
            return {
                success: false,
                error: error.message,
                provider: 'calendar',
                calendar_id: calendarId,
                event_id: eventId,
                timestamp: new Date().toISOString()
            };
        }
    }

    /**
     * 📅 Edita um evento existente
     */
    async editCalendarEvent(calendarId, eventId, eventData) {
        try {
            const event = await this.client.calendars.editEvent({
                calendar_id: calendarId,
                event_id: eventId,
                ...eventData
            });
            
            return {
                success: true,
                data: event,
                provider: 'calendar',
                calendar_id: calendarId,
                event_id: eventId,
                timestamp: new Date().toISOString()
            };
        } catch (error) {
            return {
                success: false,
                error: error.message,
                provider: 'calendar',
                calendar_id: calendarId,
                event_id: eventId,
                timestamp: new Date().toISOString()
            };
        }
    }

    /**
     * 📅 Deleta um evento
     */
    async deleteCalendarEvent(calendarId, eventId) {
        try {
            const result = await this.client.calendars.deleteEvent({
                calendar_id: calendarId,
                event_id: eventId
            });
            
            return {
                success: true,
                data: result,
                provider: 'calendar',
                calendar_id: calendarId,
                event_id: eventId,
                operation: 'delete',
                timestamp: new Date().toISOString()
            };
        } catch (error) {
            return {
                success: false,
                error: error.message,
                provider: 'calendar',
                calendar_id: calendarId,
                event_id: eventId,
                timestamp: new Date().toISOString()
            };
        }
    }

    /**
     * 📅 Cria evento jurídico LITIG-1 com padrões específicos
     */
    async createLegalEvent(calendarId, legalEventData) {
        try {
            const eventData = {
                title: legalEventData.title,
                description: this._formatLegalEventDescription(legalEventData),
                start_time: legalEventData.startTime,
                end_time: legalEventData.endTime,
                location: legalEventData.location,
                attendees: legalEventData.attendees || [],
                reminders: legalEventData.reminders || this._getDefaultLegalReminders(),
                metadata: {
                    ...legalEventData.metadata,
                    source: 'LITIG-1',
                    case_id: legalEventData.caseId,
                    case_type: legalEventData.caseType,
                    lawyer_id: legalEventData.lawyerId,
                    client_id: legalEventData.clientId,
                    event_category: legalEventData.eventCategory || 'legal_appointment'
                }
            };
            
            return await this.createCalendarEvent(calendarId, eventData);
        } catch (error) {
            return {
                success: false,
                error: error.message,
                provider: 'calendar',
                operation: 'create_legal_event',
                timestamp: new Date().toISOString()
            };
        }
    }

    /**
     * 📅 Sincroniza eventos LITIG-1 com calendário externo
     */
    async syncLegalEventsWithCalendar(accountId, litigEvents) {
        try {
            const calendars = await this.listCalendars(accountId);
            if (!calendars.success) {
                throw new Error('Failed to list calendars');
            }
            
            // Encontra calendário primário ou primeiro disponível
            const primaryCalendar = calendars.data.find(cal => cal.primary) || calendars.data[0];
            if (!primaryCalendar) {
                throw new Error('No calendar available');
            }
            
            const results = [];
            
            for (const litigEvent of litigEvents) {
                const result = await this.createLegalEvent(primaryCalendar.id, litigEvent);
                results.push({
                    case_id: litigEvent.caseId,
                    title: litigEvent.title,
                    success: result.success,
                    calendar_event_id: result.success ? result.data.id : null,
                    error: result.success ? null : result.error
                });
            }
            
            return {
                success: true,
                data: {
                    calendar_id: primaryCalendar.id,
                    calendar_name: primaryCalendar.name,
                    synced_events: results,
                    success_count: results.filter(r => r.success).length,
                    error_count: results.filter(r => !r.success).length
                },
                operation: 'sync_legal_events',
                timestamp: new Date().toISOString()
            };
        } catch (error) {
            return {
                success: false,
                error: error.message,
                operation: 'sync_legal_events',
                timestamp: new Date().toISOString()
            };
        }
    }

    /**
     * 📅 Formata descrição para eventos jurídicos
     */
    _formatLegalEventDescription(legalEventData) {
        const parts = [
            legalEventData.description || '',
            '',
            '🏛️ Evento LITIG-1',
            `📋 Caso: ${legalEventData.caseNumber || legalEventData.caseId}`,
            `⚖️ Tipo: ${legalEventData.caseType || 'Jurídico'}`,
            `👤 Cliente: ${legalEventData.clientName || 'N/A'}`,
            `👨‍💼 Advogado: ${legalEventData.lawyerName || 'N/A'}`
        ];
        
        if (legalEventData.urgency) {
            parts.push(`🚨 Urgência: ${legalEventData.urgency}`);
        }
        
        if (legalEventData.notes) {
            parts.push('', '📝 Observações:', legalEventData.notes);
        }
        
        return parts.filter(Boolean).join('\n');
    }

    /**
     * 📅 Define lembretes padrão para eventos jurídicos
     */
    _getDefaultLegalReminders() {
        return [
            { method: 'email', minutes: 24 * 60 }, // 1 dia antes
            { method: 'popup', minutes: 2 * 60 },  // 2 horas antes
            { method: 'popup', minutes: 30 }       // 30 minutos antes
        ];
    }

    /**
     * Verifica a saúde da conexão
     */
    async healthCheck() {
        try {
            const accounts = await this.listAccounts();
            
            return {
                success: true,
                status: 'healthy',
                connected_accounts: accounts.success ? accounts.data.length : 0,
                api_endpoint: `https://${this.dsn}`,
                has_token: !!this.accessToken,
                using_sdk: true,
                timestamp: new Date().toISOString()
            };
        } catch (error) {
            return {
                success: false,
                status: 'unhealthy',
                error: error.message,
                timestamp: new Date().toISOString()
            };
        }
    }
}

// CLI Interface para comunicação com Python
if (require.main === module) {
    const service = new UnipileSDKService();
    const command = process.argv[2];
    const args = process.argv.slice(3);

    async function executeCommand() {
        let result;
        
        switch (command) {
            case 'list-accounts':
                result = await service.listAccounts();
                break;
                
            case 'connect-linkedin':
                const [username, password] = args;
                result = await service.connectLinkedIn({ username, password });
                break;
                
            case 'connect-instagram':
                const [igUsername, igPassword] = args;
                result = await service.connectInstagram({ username: igUsername, password: igPassword });
                break;
                
            case 'connect-facebook':
                const [fbUsername, fbPassword] = args;
                result = await service.connectFacebook({ username: fbUsername, password: fbPassword });
                break;
                
            case 'get-company-profile':
                const [accountId, identifier] = args;
                result = await service.getCompanyProfile(accountId, identifier);
                break;
                
            case 'get-instagram-profile':
                const [igAccountId] = args;
                result = await service.getInstagramProfile(igAccountId);
                break;
                
            case 'get-facebook-profile':
                const [fbAccountId] = args;
                result = await service.getFacebookProfile(fbAccountId);
                break;
                
            case 'get-instagram-posts':
                const [igPostsAccountId, igOptions] = args;
                result = await service.getInstagramPosts(igPostsAccountId, JSON.parse(igOptions || '{}'));
                break;
                
            case 'get-facebook-posts':
                const [fbPostsAccountId, fbOptions] = args;
                result = await service.getFacebookPosts(fbPostsAccountId, JSON.parse(fbOptions || '{}'));
                break;
                
            case 'get-social-profiles':
                const [accountIds] = args;
                result = await service.getSocialProfiles(JSON.parse(accountIds));
                break;
                
            case 'connect-email':
                const [provider, email, credentials] = args;
                result = await service.connectEmail(provider, { email, ...JSON.parse(credentials || '{}') });
                break;
                
            case 'list-emails':
                const [emailAccountId, options] = args;
                result = await service.listEmails(emailAccountId, JSON.parse(options || '{}'));
                break;
                
            case 'send-email':
                const [senderAccountId, emailData] = args;
                result = await service.sendEmail(senderAccountId, JSON.parse(emailData));
                break;
                
            case 'health-check':
                result = await service.healthCheck();
                break;
                
            // 📅 Comandos de Calendário (v3.0)
            case 'list-calendars':
                const [calAccountId] = args;
                result = await service.listCalendars(calAccountId);
                break;
                
            case 'get-calendar':
                const [getCalendarId, getCalAccountId] = args;
                result = await service.getCalendar(getCalendarId, getCalAccountId);
                break;
                
            case 'list-calendar-events':
                const [listEventsCalendarId, listEventsOptions] = args;
                result = await service.listCalendarEvents(listEventsCalendarId, JSON.parse(listEventsOptions || '{}'));
                break;
                
            case 'create-calendar-event':
                const [createEventCalendarId, createEventData] = args;
                result = await service.createCalendarEvent(createEventCalendarId, JSON.parse(createEventData));
                break;
                
            case 'get-calendar-event':
                const [getEventCalendarId, getEventId] = args;
                result = await service.getCalendarEvent(getEventCalendarId, getEventId);
                break;
                
            case 'edit-calendar-event':
                const [editEventCalendarId, editEventId, editEventData] = args;
                result = await service.editCalendarEvent(editEventCalendarId, editEventId, JSON.parse(editEventData));
                break;
                
            case 'delete-calendar-event':
                const [deleteEventCalendarId, deleteEventId] = args;
                result = await service.deleteCalendarEvent(deleteEventCalendarId, deleteEventId);
                break;
                
            case 'create-legal-event':
                const [legalEventCalendarId, legalEventData] = args;
                result = await service.createLegalEvent(legalEventCalendarId, JSON.parse(legalEventData));
                break;
                
            case 'sync-legal-events':
                const [syncAccountId, syncLitigEvents] = args;
                result = await service.syncLegalEventsWithCalendar(syncAccountId, JSON.parse(syncLitigEvents));
                break;
                
            default:
                result = {
                    success: false,
                    error: `Unknown command: ${command}`,
                    available_commands: [
                        'list-accounts',
                        'connect-linkedin',
                        'connect-instagram',
                        'connect-facebook',
                        'get-company-profile',
                        'get-instagram-profile',
                        'get-facebook-profile',
                        'get-instagram-posts',
                        'get-facebook-posts',
                        'get-social-profiles',
                        'connect-email',
                        'list-emails',
                        'send-email',
                        'health-check',
                        // 📅 Comandos de Calendário
                        'list-calendars',
                        'get-calendar',
                        'list-calendar-events',
                        'create-calendar-event',
                        'get-calendar-event',
                        'edit-calendar-event',
                        'delete-calendar-event',
                        'create-legal-event',
                        'sync-legal-events'
                    ]
                };
        }
        
        console.log(JSON.stringify(result, null, 2));
    }

    executeCommand().catch(error => {
        console.error(JSON.stringify({
            success: false,
            error: error.message,
            timestamp: new Date().toISOString()
        }, null, 2));
        process.exit(1);
    });
}

module.exports = UnipileSDKService; 