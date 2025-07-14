#!/usr/bin/env node

/**
 * Unipile SDK Service - Serviço Node.js usando o SDK oficial da Unipile
 * ====================================================================
 * 
 * Este serviço utiliza o SDK oficial da Unipile para simplificar a integração
 * e garantir compatibilidade com as melhores práticas da API.
 * 
 * Baseado na documentação:
 * - https://developer.unipile.com/reference/accountscontroller_listaccounts
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
                
            case 'get-company-profile':
                const [accountId, identifier] = args;
                result = await service.getCompanyProfile(accountId, identifier);
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
                
            default:
                result = {
                    success: false,
                    error: `Unknown command: ${command}`,
                    available_commands: [
                        'list-accounts',
                        'connect-linkedin',
                        'get-company-profile',
                        'connect-email',
                        'list-emails',
                        'send-email',
                        'health-check'
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