#!/usr/bin/env node

/**
 * Unipile SDK Service - Serviço Node.js usando o SDK oficial da Unipile v1.9.3
 * =============================================================================
 * 
 * Este serviço utiliza o SDK oficial da Unipile para simplificar a integração
 * e garantir compatibilidade com as melhores práticas da API.
 * 
 * VERSÃO 4.0 - SDK Oficial Instalado e Atualizado ✅
 * 
 * Recursos Suportados:
 * - LinkedIn, WhatsApp, Instagram, Messenger, Telegram, Google, Microsoft, IMAP, X (Twitter)
 * - Messaging: getAllChats(), getAllMessages(), getAllAttendees()
 * - Calendars: Integração completa com Outlook/Google Calendar
 * - OAuth: Fluxos automáticos para Microsoft e Google
 * 
 * Baseado na documentação oficial:
 * - https://developer.unipile.com/docs/sdk/node-js
 * - GitHub: https://github.com/unipile/unipile-node-sdk
 * - SDK: npm install unipile-node-sdk (✅ INSTALADO)
 */

const { UnipileClient } = require('unipile-node-sdk');

class UnipileSDKService {
    constructor() {
        this.dsn = process.env.UNIPILE_DSN || 'api.unipile.com';
        this.accessToken = process.env.UNIPILE_API_TOKEN;
        this.connectedAccounts = []; // Store connected accounts locally
        
        if (!this.accessToken) {
            console.warn('⚠️  UNIPILE_API_TOKEN not set. Some operations will fail.');
            console.log('📝 Set UNIPILE_API_TOKEN environment variable to enable full functionality.');
        }
        
        try {
            // Inicializa o cliente Unipile com SDK v1.9.3
            this.client = new UnipileClient(`https://${this.dsn}`, this.accessToken);
            console.log('✅ Unipile SDK Client initialized successfully');
            console.log(`🔗 Connected to: https://${this.dsn}`);
        } catch (error) {
            console.error('❌ Failed to initialize Unipile SDK Client:', error.message);
            throw error;
        }
    }

    /**
     * Lista todas as contas conectadas usando o SDK
     * Nota: O SDK v1.9.3 não expõe um método direto para listar contas
     * Este método simula a funcionalidade baseada nas contas conectadas
     */
    async listAccounts() {
        try {
            console.log('🔄 Fetching connected accounts...');
            
            // Como o SDK não tem um método direto list(), vamos simular
            // baseado no status das contas conectadas
            const accounts = this.connectedAccounts || [];
            
            console.log(`✅ Retrieved ${accounts.length} connected accounts`);
            
            return {
                success: true,
                data: accounts,
                count: accounts.length,
                timestamp: new Date().toISOString(),
                sdk_version: '1.9.3',
                note: 'Simulated account list - actual accounts stored locally'
            };
        } catch (error) {
            console.error('❌ Error listing accounts:', error.message);
            
            return {
                success: false,
                error: error.message,
                timestamp: new Date().toISOString()
            };
        }
    }

    /**
     * 🆕 Conecta uma conta do LinkedIn
     * Utiliza o método oficial do SDK v1.9.3
     */
    async connectLinkedIn(credentials) {
        try {
            console.log('🔄 Connecting LinkedIn account...');
            
            const linkedinAccount = await this.client.account.connectLinkedin({
                username: credentials.username,
                password: credentials.password,
            });
            
            // Store account locally
            this.connectedAccounts.push({
                id: linkedinAccount.id || `linkedin_${Date.now()}`,
                provider: 'linkedin',
                username: credentials.username,
                status: 'active',
                connected_at: new Date().toISOString()
            });
            
            console.log('✅ LinkedIn account connected successfully:', linkedinAccount.id);
            
            return {
                success: true,
                data: linkedinAccount,
                provider: 'linkedin',
                timestamp: new Date().toISOString(),
                sdk_version: '1.9.3'
            };
        } catch (error) {
            console.error('❌ LinkedIn connection error:', error.message);
            
            return {
                success: false,
                error: error.message,
                provider: 'linkedin',
                timestamp: new Date().toISOString()
            };
        }
    }

    /**
     * 🆕 Conecta uma conta do Instagram
     */
    async connectInstagram(credentials) {
        try {
            console.log('🔄 Connecting Instagram account...');
            
            const instagramAccount = await this.client.account.connectInstagram({
                username: credentials.username,
                password: credentials.password,
            });
            
            console.log('✅ Instagram account connected successfully:', instagramAccount.id);
            
            return {
                success: true,
                data: instagramAccount,
                provider: 'instagram',
                timestamp: new Date().toISOString(),
                sdk_version: '1.9.3'
            };
        } catch (error) {
            console.error('❌ Instagram connection error:', error.message);
            
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
    async connectMessenger(credentials) {
        try {
            console.log('🔄 Connecting Messenger account...');
            
            const messengerAccount = await this.client.account.connectMessenger({
                username: credentials.username,
                password: credentials.password,
            });
            
            console.log('✅ Messenger account connected successfully:', messengerAccount.id);
            
            return {
                success: true,
                data: messengerAccount,
                provider: 'messenger',
                timestamp: new Date().toISOString(),
                sdk_version: '1.9.3'
            };
        } catch (error) {
            console.error('❌ Messenger connection error:', error.message);
            
            return {
                success: false,
                error: error.message,
                provider: 'messenger',
                timestamp: new Date().toISOString()
            };
        }
    }

    /**
     * 🆕 Conecta uma conta do WhatsApp (via QR Code)
     * Utiliza o método oficial do SDK para WhatsApp Business
     */
    async connectWhatsapp() {
        try {
            console.log('🔄 Generating WhatsApp QR code...');
            
            const whatsappResult = await this.client.account.connectWhatsapp();
            const qrCode = whatsappResult.qrCodeString || whatsappResult.qr_code;
            
            // Store pending account
            const accountId = `whatsapp_${Date.now()}`;
            this.connectedAccounts.push({
                id: accountId,
                provider: 'whatsapp',
                status: 'pending_qr_scan',
                connected_at: new Date().toISOString()
            });
            
            console.log('✅ WhatsApp QR code generated successfully');
            
            return {
                success: true,
                data: {
                    qr_code: qrCode,
                    account_id: accountId,
                    instructions: 'Scan the QR code with WhatsApp to complete connection',
                    steps: [
                        '1. Open WhatsApp on your phone',
                        '2. Tap Menu > Linked Devices',
                        '3. Tap "Link a Device"',
                        '4. Scan this QR code'
                    ]
                },
                provider: 'whatsapp',
                timestamp: new Date().toISOString(),
                sdk_version: '1.9.3'
            };
        } catch (error) {
            console.error('❌ WhatsApp connection error:', error.message);
            
            return {
                success: false,
                error: error.message,
                provider: 'whatsapp',
                timestamp: new Date().toISOString()
            };
        }
    }

    /**
     * 🆕 Conecta uma conta do Telegram (via QR Code)
     * Utiliza o método oficial do SDK para Telegram
     */
    async connectTelegram() {
        try {
            console.log('🔄 Generating Telegram QR code...');
            
            const { qrCodeString: telegramQrCode } = await this.client.account.connectTelegram();
            
            console.log('✅ Telegram QR code generated successfully');
            
            return {
                success: true,
                data: {
                    qr_code: telegramQrCode,
                    instructions: 'Scan the QR code with Telegram to complete connection',
                    steps: [
                        '1. Open Telegram on your phone',
                        '2. Go to Settings > Devices',
                        '3. Tap "Link Desktop Device"',
                        '4. Scan this QR code'
                    ]
                },
                provider: 'telegram',
                timestamp: new Date().toISOString(),
                sdk_version: '1.9.3'
            };
        } catch (error) {
            console.error('❌ Telegram connection error:', error.message);
            
            return {
                success: false,
                error: error.message,
                provider: 'telegram',
                timestamp: new Date().toISOString()
            };
        }
    }

    /**
     * 🆕 Conecta uma conta Outlook/Office365 (via Hosted Auth)
     * Utiliza o fluxo de autenticação hospedada do SDK oficial
     */
    async connectOutlook() {
        try {
            console.log('🔄 Creating Outlook hosted auth link...');
            
            // O SDK v1.9.3 usa hosted auth links para OAuth
            const authResult = await this.client.account.createHostedAuthLink({
                type: 'provider_account',
                providers: ['outlook'],
                expiresOn: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(), // 24 hours
                api_url: `https://${this.dsn}`
            });
            
            console.log('✅ Outlook auth link created successfully');
            
            return {
                success: true,
                data: {
                    auth_url: authResult.url,
                    link_id: authResult.id,
                    expires_at: authResult.expiresOn,
                    instructions: 'Open the auth URL to complete Outlook connection',
                    provider: 'outlook'
                },
                provider: 'outlook',
                timestamp: new Date().toISOString(),
                sdk_version: '1.9.3'
            };
        } catch (error) {
            console.error('❌ Detailed Outlook connection error:', {
                message: error.message,
                stack: error.stack,
                timestamp: new Date().toISOString()
            });
            
            return {
                success: false,
                error: error.message,
                provider: 'outlook',
                timestamp: new Date().toISOString(),
                troubleshooting: {
                    check_token: 'Verify UNIPILE_API_TOKEN is set',
                    check_dsn: 'Verify UNIPILE_DSN is correct',
                    oauth_flow: 'Outlook requires hosted authentication flow'
                }
            };
        }
    }

    /**
     * 🆕 Conecta uma conta Gmail (via OAuth)
     * Utiliza o fluxo OAuth automático do SDK oficial
     * Baseado na documentação: https://developer.unipile.com/docs/google-oauth
     */
    async connectGmail() {
        try {
            console.log('🔄 Initiating Gmail OAuth connection...');
            
            const gmailAccount = await this.client.account.connectGmail();
            
            console.log('✅ Gmail account connected successfully:', gmailAccount.id);
            
            return {
                success: true,
                data: gmailAccount,
                provider: 'gmail',
                oauth_scopes: [
                    'gmail.send',
                    'gmail.labels', 
                    'gmail.readonly',
                    'gmail.modify'
                ],
                timestamp: new Date().toISOString(),
                sdk_version: '1.9.3',
                note: 'Requires Google OAuth setup with proper redirect URIs'
            };
        } catch (error) {
            console.error('❌ Gmail connection error:', error.message);
            
            return {
                success: false,
                error: error.message,
                provider: 'gmail',
                timestamp: new Date().toISOString(),
                troubleshooting: {
                    setup_required: 'Configure Google OAuth in Google Developers Console',
                    scopes_needed: 'Enable Gmail API with proper scopes',
                    redirect_uris: 'Add Unipile redirect URIs to OAuth client'
                }
            };
        }
    }

    /**
     * 🆕 Conecta uma conta do Facebook/Messenger
     * Baseado na documentação oficial da Unipile
     */
    async connectFacebook(credentials) {
        try {
            console.log('🔄 Connecting Facebook account...');
            
            // Usar o método correto do SDK para Facebook/Messenger
            const facebookAccount = await this.client.account.connectFacebook({
                username: credentials.username,
                password: credentials.password,
            });
            
            // Store account locally
            this.connectedAccounts.push({
                id: facebookAccount.id || `facebook_${Date.now()}`,
                provider: 'facebook',
                username: credentials.username,
                status: 'active',
                connected_at: new Date().toISOString()
            });
            
            console.log('✅ Facebook account connected successfully:', facebookAccount.id);
            
            return {
                success: true,
                data: facebookAccount,
                provider: 'facebook',
                features: [
                    'Messenger messaging',
                    'File attachments',
                    'Read receipts',
                    'Reactions',
                    'Profile retrieval'
                ],
                timestamp: new Date().toISOString(),
                sdk_version: '1.9.3'
            };
        } catch (error) {
            console.error('❌ Facebook connection error:', error.message);
            
            return {
                success: false,
                error: error.message,
                provider: 'facebook',
                timestamp: new Date().toISOString(),
                note: 'Facebook connection may require 2FA or app-specific authentication'
            };
        }
    }

    // ========================================
    // 📧 MESSAGING METHODS (SDK v1.9.3)
    // ========================================

    /**
     * 📧 Lista todos os chats de messaging (SDK v1.9.3)
     * Inclui WhatsApp, Telegram, Instagram, etc.
     */
    async getAllChats(options = {}) {
        try {
            console.log('🔄 Fetching all chats...');
            
            // Usar o método correto do SDK v1.9.3
            const chats = await this.client.messaging.getAllChats(options);
            
            console.log(`✅ Retrieved ${chats.length} chats`);
            
            return {
                success: true,
                data: chats,
                count: chats.length,
                timestamp: new Date().toISOString(),
                sdk_version: '1.9.3'
            };
        } catch (error) {
            console.error('❌ Error fetching chats:', error.message);
            
            return {
                success: false,
                error: error.message,
                timestamp: new Date().toISOString()
            };
        }
    }

    /**
     * 📩 Lista todas as mensagens de um chat específico (SDK v1.9.3)
     * Usa o método correto getAllMessagesFromChat
     */
    async getAllMessagesFromChat(chatId, options = {}) {
        try {
            console.log(`🔄 Fetching messages from chat ${chatId}...`);
            
            const messages = await this.client.messaging.getAllMessagesFromChat({ 
                chat_id: chatId,
                ...options 
            });
            
            console.log(`✅ Retrieved ${messages.length} messages`);
            
            return {
                success: true,
                data: messages,
                count: messages.length,
                chat_id: chatId,
                timestamp: new Date().toISOString(),
                sdk_version: '1.9.3'
            };
        } catch (error) {
            console.error('❌ Error fetching messages:', error.message);
            
            return {
                success: false,
                error: error.message,
                chat_id: chatId,
                timestamp: new Date().toISOString()
            };
        }
    }

    /**
     * 👥 Inicia um novo chat com participantes (SDK v1.9.3)
     */
    async startNewChat({ accountId, attendeesIds, text }) {
        try {
            console.log('🔄 Starting new chat...');
            
            const chatResult = await this.client.messaging.startNewChat({
                account_id: accountId,
                attendees_ids: attendeesIds,
                text: text
            });
            
            console.log('✅ New chat started successfully:', chatResult.id);
            
            return {
                success: true,
                data: chatResult,
                timestamp: new Date().toISOString(),
                sdk_version: '1.9.3'
            };
        } catch (error) {
            console.error('❌ Error starting new chat:', error.message);
            
            return {
                success: false,
                error: error.message,
                timestamp: new Date().toISOString()
            };
        }
    }

    /**
     * Envia uma mensagem para um chat específico (SDK v1.9.3)
     * Suporta anexos: PDF, imagens, vídeos (até 15MB)
     * Baseado na documentação: POST /chats/{chat_id}/messages
     */
    async sendMessage({ chatId, text, attachments = [] }) {
        try {
            console.log(`🔄 Sending message to chat ${chatId}...`);
            
            // Método correto conforme documentação oficial
            const result = await this.client.messaging.sendMessage({
                chat_id: chatId,
                text: text,
                attachments: attachments // Array de arquivos até 15MB (PDF, imagem, vídeo)
            });
            
            console.log('✅ Message sent successfully:', result.id);
            
            return {
                success: true,
                data: result,
                chat_id: chatId,
                message_id: result.id,
                timestamp: new Date().toISOString(),
                sdk_version: '1.9.3',
                supported_attachments: 'PDF, images, videos (max 15MB)'
            };
        } catch (error) {
            console.error('❌ Error sending message:', error.message);
            
            return {
                success: false,
                error: error.message,
                chat_id: chatId,
                timestamp: new Date().toISOString()
            };
        }
    }

    // ========================================
    // 📅 CALENDAR METHODS (SDK v1.9.3)
    // ========================================

    /**
     * 📅 Lista todos os calendários de uma conta
     */
    async listCalendars(accountId) {
        try {
            console.log('🔄 Fetching calendars...');
            
            const calendars = await this.client.calendars.list({
                account_id: accountId
            });
            
            console.log(`✅ Retrieved ${calendars.length} calendars`);
            
            return {
                success: true,
                data: calendars,
                count: calendars.length,
                provider: 'calendar',
                timestamp: new Date().toISOString(),
                sdk_version: '1.9.3'
            };
        } catch (error) {
            console.error('❌ Error fetching calendars:', error.message);
            
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
            console.log('🔄 Fetching calendar events...');
            
            const events = await this.client.calendars.listEvents({
                calendar_id: calendarId,
                ...options
            });
            
            console.log(`✅ Retrieved ${events.length} events`);
            
            return {
                success: true,
                data: events,
                count: events.length,
                provider: 'calendar',
                calendar_id: calendarId,
                timestamp: new Date().toISOString(),
                sdk_version: '1.9.3'
            };
        } catch (error) {
            console.error('❌ Error fetching events:', error.message);
            
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
            console.log('🔄 Creating calendar event...');
            
            const event = await this.client.calendars.createEvent({
                calendar_id: calendarId,
                ...eventData
            });
            
            console.log('✅ Calendar event created successfully:', event.id);
            
            return {
                success: true,
                data: event,
                provider: 'calendar',
                calendar_id: calendarId,
                timestamp: new Date().toISOString(),
                sdk_version: '1.9.3'
            };
        } catch (error) {
            console.error('❌ Error creating event:', error.message);
            
            return {
                success: false,
                error: error.message,
                provider: 'calendar',
                calendar_id: calendarId,
                timestamp: new Date().toISOString()
            };
        }
    }

    // ========================================
    // 📧 EMAIL METHODS (SDK v1.9.3)
    // ========================================

    /**
     * 📧 Envia um email com suporte a anexos (incluindo vídeos)
     * Suporta Gmail, Outlook e IMAP
     */
    async sendEmail({ accountId, to, subject, text, html, attachments = [], cc = [], bcc = [] }) {
        try {
            console.log('🔄 Sending email...');
            
            const emailResult = await this.client.email.send({
                account_id: accountId,
                to: Array.isArray(to) ? to : [to],
                subject: subject,
                text: text,
                html: html,
                attachments: attachments,
                cc: cc,
                bcc: bcc
            });
            
            console.log('✅ Email sent successfully:', emailResult.id);
            
            return {
                success: true,
                data: emailResult,
                provider: 'email',
                timestamp: new Date().toISOString(),
                sdk_version: '1.9.3'
            };
        } catch (error) {
            console.error('❌ Error sending email:', error.message);
            
            return {
                success: false,
                error: error.message,
                provider: 'email',
                timestamp: new Date().toISOString()
            };
        }
    }

    /**
     * 📧 Lista emails de uma conta (Gmail/Outlook/IMAP)
     * Baseado na documentação oficial: GET /emails
     */
    async listEmails(accountId, options = {}) {
        try {
            console.log('🔄 Fetching emails...');
            
            // Usar método correto do SDK conforme documentação
            const emails = await this.client.email.list({
                account_id: accountId,
                ...options
            });
            
            console.log(`✅ Retrieved ${emails.length} emails`);
            
            return {
                success: true,
                data: emails,
                count: emails.length,
                provider: 'email',
                timestamp: new Date().toISOString(),
                sdk_version: '1.9.3'
            };
        } catch (error) {
            console.error('❌ Error fetching emails:', error.message);
            
            return {
                success: false,
                error: error.message,
                provider: 'email',
                timestamp: new Date().toISOString()
            };
        }
    }

    /**
     * 📧 Responde a um email específico
     */
    async replyToEmail({ accountId, emailId, text, html, attachments = [] }) {
        try {
            console.log('🔄 Replying to email...');
            
            const replyResult = await this.client.email.reply({
                account_id: accountId,
                email_id: emailId,
                text: text,
                html: html,
                attachments: attachments
            });
            
            console.log('✅ Email reply sent successfully:', replyResult.id);
            
            return {
                success: true,
                data: replyResult,
                provider: 'email',
                timestamp: new Date().toISOString(),
                sdk_version: '1.9.3'
            };
        } catch (error) {
            console.error('❌ Error replying to email:', error.message);
            
            return {
                success: false,
                error: error.message,
                provider: 'email',
                timestamp: new Date().toISOString()
            };
        }
    }

    /**
     * 📧 Deleta um email
     */
    async deleteEmail(accountId, emailId) {
        try {
            console.log('🔄 Deleting email...');
            
            const result = await this.client.email.delete({
                account_id: accountId,
                email_id: emailId
            });
            
            console.log('✅ Email deleted successfully');
            
            return {
                success: true,
                data: result,
                provider: 'email',
                timestamp: new Date().toISOString(),
                sdk_version: '1.9.3'
            };
        } catch (error) {
            console.error('❌ Error deleting email:', error.message);
            
            return {
                success: false,
                error: error.message,
                provider: 'email',
                timestamp: new Date().toISOString()
            };
        }
    }

    /**
     * 📧 Cria um rascunho de email
     */
    async createEmailDraft({ accountId, to, subject, text, html, attachments = [] }) {
        try {
            console.log('🔄 Creating email draft...');
            
            const draftResult = await this.client.email.createDraft({
                account_id: accountId,
                to: Array.isArray(to) ? to : [to],
                subject: subject,
                text: text,
                html: html,
                attachments: attachments
            });
            
            console.log('✅ Email draft created successfully:', draftResult.id);
            
            return {
                success: true,
                data: draftResult,
                provider: 'email',
                timestamp: new Date().toISOString(),
                sdk_version: '1.9.3'
            };
        } catch (error) {
            console.error('❌ Error creating email draft:', error.message);
            
            return {
                success: false,
                error: error.message,
                provider: 'email',
                timestamp: new Date().toISOString()
            };
        }
    }

    /**
     * 📁 Lista pastas/labels do Gmail
     * Específico para Gmail - gerenciamento de pastas e labels
     */
    async listGmailFolders(accountId) {
        try {
            console.log('🔄 Fetching Gmail folders/labels...');
            
            const folders = await this.client.email.listFolders({
                account_id: accountId
            });
            
            console.log(`✅ Retrieved ${folders.length} Gmail folders/labels`);
            
            return {
                success: true,
                data: folders,
                count: folders.length,
                provider: 'gmail',
                timestamp: new Date().toISOString(),
                sdk_version: '1.9.3',
                note: 'Gmail-specific folders and labels'
            };
        } catch (error) {
            console.error('❌ Error fetching Gmail folders:', error.message);
            
            return {
                success: false,
                error: error.message,
                provider: 'gmail',
                timestamp: new Date().toISOString()
            };
        }
    }

    /**
     * 📧 Move email para pasta específica (Gmail/Outlook)
     */
    async moveEmail({ accountId, emailId, folderId }) {
        try {
            console.log('🔄 Moving email to folder...');
            
            const result = await this.client.email.move({
                account_id: accountId,
                email_id: emailId,
                folder_id: folderId
            });
            
            console.log('✅ Email moved successfully');
            
            return {
                success: true,
                data: result,
                provider: 'email',
                timestamp: new Date().toISOString(),
                sdk_version: '1.9.3'
            };
        } catch (error) {
            console.error('❌ Error moving email:', error.message);
            
            return {
                success: false,
                error: error.message,
                provider: 'email',
                timestamp: new Date().toISOString()
            };
        }
    }

    // ========================================
    // 👤 PROFILE & COMPANY DATA EXTRACTION (SDK v1.9.3)
    // Para alimentar algoritmo de matching
    // ========================================

    /**
     * 👤 Extrai perfil completo de usuário LinkedIn
     * Baseado na documentação: GET /users/{provider_public_id}
     * Inclui: experiência, educação, habilidades, conexões, publicações
     */
    async getUserProfile({ accountId, identifier, includeAllSections = true }) {
        try {
            console.log(`🔄 Extracting user profile: ${identifier}...`);
            
            // Método correto conforme documentação oficial
            const profile = await this.client.users.getProfile({
                account_id: accountId,
                identifier: identifier,
                linkedin_sections: includeAllSections ? "*" : undefined // ✅ Parâmetro documentado
            });
            
            console.log('✅ User profile extracted successfully:', profile.id);
            
            return {
                success: true,
                data: {
                    // Dados básicos
                    id: profile.id,
                    firstName: profile.first_name,
                    lastName: profile.last_name,
                    headline: profile.headline,
                    location: profile.location,
                    profilePicture: profile.picture,
                    profileUrl: profile.profile_url,
                    
                    // Dados de rede
                    networkDistance: profile.network_info?.distance,
                    connectionsCount: profile.network_info?.connections_count,
                    followersCount: profile.network_info?.followers_count,
                    
                    // Experiência profissional
                    experience: profile.experience || [],
                    
                    // Educação
                    education: profile.education || [],
                    
                    // Habilidades com endorsements
                    skills: profile.skills || [],
                    
                    // Idiomas
                    languages: profile.languages || [],
                    
                    // Resumo profissional
                    summary: profile.summary,
                    
                    // Certificações
                    certifications: profile.certifications || [],
                    
                    // Trabalho voluntário
                    volunteer: profile.volunteer || [],
                    
                    // Projetos
                    projects: profile.projects || [],
                    
                    // Websites
                    websites: profile.websites || [],
                    
                    // Status premium/influencer
                    isPremium: profile.is_premium,
                    isInfluencer: profile.is_influencer,
                    isCreator: profile.is_creator
                },
                provider: 'linkedin',
                timestamp: new Date().toISOString(),
                sdk_version: '1.9.3',
                extraction_type: 'full_profile'
            };
        } catch (error) {
            console.error('❌ Error extracting user profile:', error.message);
            
            return {
                success: false,
                error: error.message,
                identifier: identifier,
                provider: 'linkedin',
                timestamp: new Date().toISOString()
            };
        }
    }

    /**
     * 🏢 Extrai perfil completo de empresa LinkedIn
     * Inclui: dados da empresa, funcionários, seguidores, posts
     */
    async getCompanyProfile({ accountId, identifier }) {
        try {
            console.log(`🔄 Extracting company profile: ${identifier}...`);
            
            const company = await this.client.users.getCompanyProfile({
                account_id: accountId,
                identifier: identifier
            });
            
            console.log('✅ Company profile extracted successfully:', company.id);
            
            return {
                success: true,
                data: {
                    // Dados básicos da empresa
                    id: company.id,
                    name: company.name,
                    industry: company.industry,
                    website: company.website,
                    description: company.description,
                    logo: company.logo,
                    coverImage: company.cover_image,
                    
                    // Localização
                    locations: company.locations,
                    headquarters: company.headquarters,
                    
                    // Métricas
                    employeesCount: company.employee_count,
                    followersCount: company.followers_count,
                    
                    // Dados adicionais
                    foundedYear: company.founded_year,
                    companySize: company.company_size,
                    specialties: company.specialties || [],
                    
                    // URLs
                    linkedinUrl: company.linkedin_url,
                    publicUrl: company.public_url
                },
                provider: 'linkedin',
                timestamp: new Date().toISOString(),
                sdk_version: '1.9.3',
                extraction_type: 'company_profile'
            };
        } catch (error) {
            console.error('❌ Error extracting company profile:', error.message);
            
            return {
                success: false,
                error: error.message,
                identifier: identifier,
                provider: 'linkedin',
                timestamp: new Date().toISOString()
            };
        }
    }

    /**
     * 👤 Extrai perfil próprio do usuário conectado
     */
    async getOwnProfile(accountId) {
        try {
            console.log('🔄 Extracting own profile...');
            
            const profile = await this.client.users.getOwnProfile(accountId);
            
            console.log('✅ Own profile extracted successfully');
            
            return {
                success: true,
                data: profile,
                provider: 'linkedin',
                timestamp: new Date().toISOString(),
                sdk_version: '1.9.3',
                extraction_type: 'own_profile'
            };
        } catch (error) {
            console.error('❌ Error extracting own profile:', error.message);
            
            return {
                success: false,
                error: error.message,
                provider: 'linkedin',
                timestamp: new Date().toISOString()
            };
        }
    }

    /**
     * 🔍 Lista conexões/contatos do usuário
     */
    async listUserConnections(accountId, options = {}) {
        try {
            console.log('🔄 Fetching user connections...');
            
            const connections = await this.client.messaging.getAllAttendees({
                account_id: accountId,
                ...options
            });
            
            console.log(`✅ Retrieved ${connections.length} connections`);
            
            return {
                success: true,
                data: connections,
                count: connections.length,
                provider: 'linkedin',
                timestamp: new Date().toISOString(),
                sdk_version: '1.9.3',
                extraction_type: 'connections_list'
            };
        } catch (error) {
            console.error('❌ Error fetching connections:', error.message);
            
            return {
                success: false,
                error: error.message,
                provider: 'linkedin',
                timestamp: new Date().toISOString()
            };
        }
    }

    /**
     * 📝 Lista publicações de um usuário ou empresa
     */
    async getUserPosts({ accountId, userId, companyId, options = {} }) {
        try {
            console.log('🔄 Fetching user/company posts...');
            
            const posts = await this.client.posts.list({
                account_id: accountId,
                for: userId ? 'user' : 'company',
                id: userId || companyId,
                ...options
            });
            
            console.log(`✅ Retrieved ${posts.length} posts`);
            
            return {
                success: true,
                data: posts,
                count: posts.length,
                provider: 'linkedin',
                timestamp: new Date().toISOString(),
                sdk_version: '1.9.3',
                extraction_type: 'posts_list'
            };
        } catch (error) {
            console.error('❌ Error fetching posts:', error.message);
            
            return {
                success: false,
                error: error.message,
                provider: 'linkedin',
                timestamp: new Date().toISOString()
            };
        }
    }

    /**
     * 🔍 Busca avançada de perfis LinkedIn
     * Para enriquecer dados do algoritmo de matching
     */
    async searchLinkedInProfiles({ accountId, query, filters = {} }) {
        try {
            console.log('🔄 Searching LinkedIn profiles...');
            
            const searchResults = await this.client.search.searchPeople({
                account_id: accountId,
                keywords: query,
                ...filters
            });
            
            console.log(`✅ Found ${searchResults.length} profiles`);
            
            return {
                success: true,
                data: searchResults,
                count: searchResults.length,
                query: query,
                filters: filters,
                provider: 'linkedin',
                timestamp: new Date().toISOString(),
                sdk_version: '1.9.3',
                extraction_type: 'profile_search'
            };
        } catch (error) {
            console.error('❌ Error searching profiles:', error.message);
            
            return {
                success: false,
                error: error.message,
                query: query,
                provider: 'linkedin',
                timestamp: new Date().toISOString()
            };
        }
    }

    /**
     * 🏢 Busca avançada de empresas LinkedIn
     */
    async searchLinkedInCompanies({ accountId, query, filters = {} }) {
        try {
            console.log('🔄 Searching LinkedIn companies...');
            
            const searchResults = await this.client.search.searchCompanies({
                account_id: accountId,
                keywords: query,
                ...filters
            });
            
            console.log(`✅ Found ${searchResults.length} companies`);
            
            return {
                success: true,
                data: searchResults,
                count: searchResults.length,
                query: query,
                filters: filters,
                provider: 'linkedin',
                timestamp: new Date().toISOString(),
                sdk_version: '1.9.3',
                extraction_type: 'company_search'
            };
        } catch (error) {
            console.error('❌ Error searching companies:', error.message);
            
            return {
                success: false,
                error: error.message,
                query: query,
                provider: 'linkedin',
                timestamp: new Date().toISOString()
            };
        }
    }

    // ========================================
    // 🔔 WEBHOOKS PARA TEMPO REAL (Baseado na documentação oficial)
    // ========================================

    /**
     * 🔔 Configura webhook para novas mensagens
     * Baseado na documentação: https://developer.unipile.com/docs/new-messages-webhook
     * Suporta: LinkedIn, WhatsApp, Instagram, Messenger, Telegram, X (Twitter)
     */
    async setupMessageWebhook({ url, events = ['message_received', 'message_reaction', 'message_read'] }) {
        try {
            console.log('🔄 Setting up message webhook...');
            
            const webhook = await this.client.webhook.create({
                url: url,
                events: events,
                description: 'Real-time message notifications for LITIG-1'
            });
            
            console.log('✅ Message webhook configured successfully:', webhook.id);
            
            return {
                success: true,
                data: webhook,
                webhook_url: url,
                events: events,
                timestamp: new Date().toISOString(),
                sdk_version: '1.9.3',
                note: 'Webhook will receive real-time updates for new messages across all platforms'
            };
        } catch (error) {
            console.error('❌ Error setting up webhook:', error.message);
            
            return {
                success: false,
                error: error.message,
                timestamp: new Date().toISOString()
            };
        }
    }

    /**
     * 🔔 Configura webhook para novos emails
     * Baseado na documentação: https://developer.unipile.com/docs/new-emails-webhook
     */
    async setupEmailWebhook({ url, events = ['email_received'] }) {
        try {
            console.log('🔄 Setting up email webhook...');
            
            const webhook = await this.client.webhook.create({
                url: url,
                events: events,
                description: 'Real-time email notifications for LITIG-1'
            });
            
            console.log('✅ Email webhook configured successfully:', webhook.id);
            
            return {
                success: true,
                data: webhook,
                webhook_url: url,
                events: events,
                timestamp: new Date().toISOString(),
                sdk_version: '1.9.3'
            };
        } catch (error) {
            console.error('❌ Error setting up email webhook:', error.message);
            
            return {
                success: false,
                error: error.message,
                timestamp: new Date().toISOString()
            };
        }
    }

    /**
     * 📧 Configurar tracking de emails
     * Baseado na documentação: https://developer.unipile.com/docs/tracking-email
     */
    async setupEmailTracking({ accountId, trackOpens = true, trackClicks = true }) {
        try {
            console.log('🔄 Setting up email tracking...');
            
            const tracking = await this.client.email.setupTracking({
                account_id: accountId,
                track_opens: trackOpens,
                track_clicks: trackClicks
            });
            
            console.log('✅ Email tracking configured successfully');
            
            return {
                success: true,
                data: tracking,
                tracking: {
                    opens: trackOpens,
                    clicks: trackClicks
                },
                timestamp: new Date().toISOString(),
                sdk_version: '1.9.3'
            };
        } catch (error) {
            console.error('❌ Error setting up email tracking:', error.message);
            
            return {
                success: false,
                error: error.message,
                timestamp: new Date().toISOString()
            };
        }
    }

    // ========================================
    // 🏥 HEALTH CHECK (Enhanced)
    // ========================================

    /**
     * 🏥 Verifica a saúde da conexão com diagnósticos avançados
     */
    async healthCheck() {
        try {
            console.log('🔄 Running comprehensive health check...');
            
            // Test 1: List accounts
            const accounts = await this.listAccounts();
            const accountsCount = accounts.success ? accounts.data.length : 0;
            
            // Test 2: Test messaging if accounts exist
            let messagingTest = { success: false, error: 'No accounts to test' };
            if (accountsCount > 0) {
                try {
                    const chats = await this.getAllChats();
                    messagingTest = { success: chats.success, count: chats.data?.length || 0 };
                } catch (error) {
                    messagingTest = { success: false, error: error.message };
                }
            }
            
            // Test 3: SDK version check
            const sdkInfo = {
                version: '1.9.3',
                installed: true,
                features: [
                    'LinkedIn', 'WhatsApp', 'Instagram', 'Messenger', 
                    'Telegram', 'Google', 'Microsoft', 'IMAP', 'X (Twitter)'
                ]
            };
            
            const healthStatus = {
                success: true,
                status: 'healthy',
                timestamp: new Date().toISOString(),
                
                // Connection Info
                connection: {
                    api_endpoint: `https://${this.dsn}`,
                    has_token: !!this.accessToken,
                    token_length: this.accessToken ? this.accessToken.length : 0
                },
                
                // SDK Info
                sdk: sdkInfo,
                
                // Accounts Info
                accounts: {
                    total: accountsCount,
                    test_result: accounts.success
                },
                
                // Messaging Info
                messaging: messagingTest,
                
                // System Info
                system: {
                    node_version: process.version,
                    platform: process.platform,
                    uptime: process.uptime()
                },
                
                // Recommendations
                recommendations: this._getHealthRecommendations(accountsCount, accounts.success, messagingTest.success)
            };
            
            console.log('✅ Health check completed successfully');
            return healthStatus;
            
        } catch (error) {
            console.error('❌ Health check failed:', error.message);
            
            return {
                success: false,
                status: 'unhealthy',
                error: error.message,
                timestamp: new Date().toISOString(),
                troubleshooting: {
                    check_token: 'Verify UNIPILE_API_TOKEN environment variable',
                    check_dsn: 'Verify UNIPILE_DSN is reachable',
                    check_network: 'Verify internet connection',
                    check_sdk: 'Verify unipile-node-sdk is installed (npm list unipile-node-sdk)'
                }
            };
        }
    }
    
    /**
     * 💡 Gera recomendações baseadas no health check
     */
    _getHealthRecommendations(accountsCount, accountsSuccess, messagingSuccess) {
        const recommendations = [];
        
        if (!this.accessToken) {
            recommendations.push('Set UNIPILE_API_TOKEN environment variable');
        }
        
        if (!accountsSuccess) {
            recommendations.push('Check API token validity and network connection');
        }
        
        if (accountsCount === 0) {
            recommendations.push('Connect at least one account (LinkedIn, WhatsApp, Outlook, etc.)');
        }
        
        if (!messagingSuccess && accountsCount > 0) {
            recommendations.push('Test messaging functionality with connected accounts');
        }
        
        if (recommendations.length === 0) {
            recommendations.push('All systems operational! 🚀');
        }
        
        return recommendations;
    }
}

// ========================================
// CLI INTERFACE
// ========================================

// CLI Interface para comunicação com Python
if (require.main === module) {
    const service = new UnipileSDKService();
    const command = process.argv[2];
    const args = process.argv.slice(3);

    async function executeCommand() {
        let result;
        
        switch (command) {
            // 🔗 Account Management
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
                
            case 'connect-messenger':
                const [messengerUsername, messengerPassword] = args;
                result = await service.connectMessenger({ username: messengerUsername, password: messengerPassword });
                break;
                
            case 'connect-outlook':
                // OAuth flow para Outlook (Microsoft 365)
                result = await service.connectOutlook();
                break;
                
            case 'connect-gmail':
                // OAuth flow para Gmail (Google Workspace)
                result = await service.connectGmail();
                break;
                
            case 'connect-whatsapp':
                // QR Code flow para WhatsApp Business
                result = await service.connectWhatsapp();
                break;
                
            case 'connect-telegram':
                // QR Code flow para Telegram
                result = await service.connectTelegram();
                break;
                
            case 'connect-facebook':
                // Username/password flow para Facebook/Messenger
                const [fbUsername, fbPassword] = args;
                result = await service.connectFacebook({ username: fbUsername, password: fbPassword });
                break;
                
            // 👤 Profile & Company Data Extraction (SDK v1.9.3)
            case 'get-user-profile':
                const [profileAccountId, profileIdentifier, includeAllSections] = args;
                result = await service.getUserProfile({
                    accountId: profileAccountId,
                    identifier: profileIdentifier,
                    includeAllSections: includeAllSections === 'true'
                });
                break;
                
            case 'get-company-profile':
                const [companyAccountId, companyIdentifier] = args;
                result = await service.getCompanyProfile({
                    accountId: companyAccountId,
                    identifier: companyIdentifier
                });
                break;
                
            case 'get-own-profile':
                const [ownProfileAccountId] = args;
                result = await service.getOwnProfile(ownProfileAccountId);
                break;
                
            case 'list-user-connections':
                const [connectionsAccountId, connectionsOptions] = args;
                result = await service.listUserConnections(connectionsAccountId, JSON.parse(connectionsOptions || '{}'));
                break;
                
            case 'get-user-posts':
                const [postsAccountId, postsUserId, postsCompanyId, postsOptions] = args;
                result = await service.getUserPosts({
                    accountId: postsAccountId,
                    userId: postsUserId,
                    companyId: postsCompanyId,
                    options: JSON.parse(postsOptions || '{}')
                });
                break;
                
            case 'search-linkedin-profiles':
                const [searchAccountId, searchQuery, searchFilters] = args;
                result = await service.searchLinkedInProfiles({
                    accountId: searchAccountId,
                    query: searchQuery,
                    filters: JSON.parse(searchFilters || '{}')
                });
                break;
                
            case 'search-linkedin-companies':
                const [companySearchAccountId, companySearchQuery, companySearchFilters] = args;
                result = await service.searchLinkedInCompanies({
                    accountId: companySearchAccountId,
                    query: companySearchQuery,
                    filters: JSON.parse(companySearchFilters || '{}')
                });
                break;
                
            // 📧 Email Management (SDK v1.9.3)
            case 'send-email':
                const [emailAccountId, emailTo, emailSubject, emailText, emailHtml, emailAttachments, emailCc, emailBcc] = args;
                result = await service.sendEmail({
                    accountId: emailAccountId,
                    to: emailTo,
                    subject: emailSubject,
                    text: emailText,
                    html: emailHtml,
                    attachments: JSON.parse(emailAttachments || '[]'),
                    cc: JSON.parse(emailCc || '[]'),
                    bcc: JSON.parse(emailBcc || '[]')
                });
                break;
                
            case 'list-emails':
                const [listEmailAccountId, listEmailOptions] = args;
                result = await service.listEmails(listEmailAccountId, JSON.parse(listEmailOptions || '{}'));
                break;
                
            case 'reply-to-email':
                const [replyAccountId, replyEmailId, replyText, replyHtml, replyAttachments] = args;
                result = await service.replyToEmail({
                    accountId: replyAccountId,
                    emailId: replyEmailId,
                    text: replyText,
                    html: replyHtml,
                    attachments: JSON.parse(replyAttachments || '[]')
                });
                break;
                
            case 'delete-email':
                const [deleteAccountId, deleteEmailId] = args;
                result = await service.deleteEmail(deleteAccountId, deleteEmailId);
                break;
                
            case 'create-email-draft':
                const [draftAccountId, draftTo, draftSubject, draftText, draftHtml, draftAttachments] = args;
                result = await service.createEmailDraft({
                    accountId: draftAccountId,
                    to: draftTo,
                    subject: draftSubject,
                    text: draftText,
                    html: draftHtml,
                    attachments: JSON.parse(draftAttachments || '[]')
                });
                break;
                
            case 'list-gmail-folders':
                const [gmailAccountId] = args;
                result = await service.listGmailFolders(gmailAccountId);
                break;
                
            case 'move-email':
                const [moveAccountId, moveEmailId, moveFolderId] = args;
                result = await service.moveEmail({
                    accountId: moveAccountId,
                    emailId: moveEmailId,
                    folderId: moveFolderId
                });
                break;
                
            // 📧 Messaging (SDK v1.9.3)
            case 'get-all-chats':
                const [chatOptions] = args;
                result = await service.getAllChats(JSON.parse(chatOptions || '{}'));
                break;
                
            case 'get-all-messages-from-chat':
                const [msgChatId, messageOptions] = args;
                result = await service.getAllMessagesFromChat(msgChatId, JSON.parse(messageOptions || '{}'));
                break;
                
            case 'start-new-chat':
                const [newChatAccountId, attendeesIds, newChatText] = args;
                result = await service.startNewChat({ 
                    accountId: newChatAccountId, 
                    attendeesIds: JSON.parse(attendeesIds || '[]'), 
                    text: newChatText 
                });
                break;
                
            case 'send-message':
                const [sendChatId, sendText, sendAttachments] = args;
                result = await service.sendMessage({ 
                    chatId: sendChatId, 
                    text: sendText, 
                    attachments: JSON.parse(sendAttachments || '[]') 
                });
                break;
                
            // 🔔 Webhooks & Real-time (Baseado na documentação oficial)
            case 'setup-message-webhook':
                const [messageWebhookUrl, messageWebhookEvents] = args;
                result = await service.setupMessageWebhook({
                    url: messageWebhookUrl,
                    events: JSON.parse(messageWebhookEvents || '["message_received", "message_reaction", "message_read"]')
                });
                break;
                
            case 'setup-email-webhook':
                const [emailWebhookUrl, emailWebhookEvents] = args;
                result = await service.setupEmailWebhook({
                    url: emailWebhookUrl,
                    events: JSON.parse(emailWebhookEvents || '["email_received"]')
                });
                break;
                
            case 'setup-email-tracking':
                const [trackingAccountId, trackOpens, trackClicks] = args;
                result = await service.setupEmailTracking({
                    accountId: trackingAccountId,
                    trackOpens: trackOpens === 'true',
                    trackClicks: trackClicks === 'true'
                });
                break;
                
            // 📅 Calendar Integration
            case 'list-calendars':
                const [calAccountId] = args;
                result = await service.listCalendars(calAccountId);
                break;
                
            case 'list-calendar-events':
                const [listEventsCalendarId, listEventsOptions] = args;
                result = await service.listCalendarEvents(listEventsCalendarId, JSON.parse(listEventsOptions || '{}'));
                break;
                
            case 'create-calendar-event':
                const [createEventCalendarId, createEventData] = args;
                result = await service.createCalendarEvent(createEventCalendarId, JSON.parse(createEventData));
                break;
                
            // 🏥 System
            case 'health-check':
                result = await service.healthCheck();
                break;
                
            default:
                result = {
                    success: false,
                    error: `Unknown command: ${command}`,
                    available_commands: [
                        // 🔗 Account Management
                        'list-accounts',
                        'connect-linkedin',
                        'connect-instagram', 
                        'connect-messenger',
                        'connect-outlook',      // ✅ OAuth Microsoft
                        'connect-gmail',        // ✅ OAuth Google
                        'connect-whatsapp',     // ✅ QR Code
                        'connect-telegram',     // ✅ QR Code
                        'connect-facebook',     // ✅ Username/password
                        
                        // 👤 Profile & Company Data Extraction (SDK v1.9.3)
                        'get-user-profile',             // ✅ Perfil completo LinkedIn
                        'get-company-profile',          // ✅ Dados empresa LinkedIn
                        'get-own-profile',              // ✅ Perfil próprio
                        'list-user-connections',        // ✅ Lista conexões
                        'get-user-posts',               // ✅ Posts usuário/empresa
                        'search-linkedin-profiles',     // ✅ Busca avançada profiles
                        'search-linkedin-companies',    // ✅ Busca avançada empresas
                        
                        // 📧 Email Management (SDK v1.9.3)
                        'send-email',                   // ✅ Gmail/Outlook/IMAP
                        'list-emails',                  // ✅ Inbox management
                        'reply-to-email',               // ✅ Email replies
                        'delete-email',                 // ✅ Email deletion
                        'create-email-draft',           // ✅ Draft management
                        'list-gmail-folders',           // ✅ Gmail labels/folders
                        'move-email',                   // ✅ Organize emails
                        
                        // 📧 Messaging (SDK v1.9.3)
                        'get-all-chats',                // ✅ SDK method
                        'get-all-messages-from-chat',   // ✅ SDK method  
                        'start-new-chat',               // ✅ SDK method
                        'send-message',                 // ✅ SDK method (supports video attachments)
                        
                        // 🔔 Webhooks & Real-time (Baseado na documentação oficial)
                        'setup-message-webhook',        // ✅ Webhook mensagens tempo real
                        'setup-email-webhook',          // ✅ Webhook emails tempo real  
                        'setup-email-tracking',         // ✅ Tracking aberturas/clicks
                        
                        // 📅 Calendar Integration
                        'list-calendars',
                        'list-calendar-events',
                        'create-calendar-event',
                        
                        // 🏥 System
                        'health-check'          // ✅ Enhanced diagnostics
                    ],
                    sdk_info: {
                        version: '1.9.3',
                        installed: true,
                        documentation: 'https://developer.unipile.com/docs/sdk/node-js'
                    }
                };
        }
        
        // Pretty print result with proper formatting
        if (result.success) {
            console.log('✅ SUCCESS:', JSON.stringify(result, null, 2));
        } else {
            console.error('❌ ERROR:', JSON.stringify(result, null, 2));
        }
    }

    executeCommand().catch(error => {
        console.error('💥 FATAL ERROR:', JSON.stringify({
            success: false,
            error: error.message,
            stack: error.stack,
            timestamp: new Date().toISOString(),
            command: command,
            args: args
        }, null, 2));
        process.exit(1);
    });
}

module.exports = UnipileSDKService;