import supabase from '@/lib/supabase';
import * as FileSystem from 'expo-file-system';
import * as DocumentPicker from 'expo-document-picker';
import * as ImagePicker from 'expo-image-picker';
import { randomUUID } from 'expo-crypto';

// Tipos para upload de arquivos
export interface FileUploadResult {
  url: string;
  path: string;
  name: string;
  size: number;
  type: string;
}

export interface UploadProgress {
  loaded: number;
  total: number;
  percentage: number;
}

/**
 * Serviço real do Supabase Storage que conecta com APIs reais
 */
class RealSupabaseStorageService {
  
  /**
   * Faz upload de uma imagem selecionada pelo usuário
   */
  async uploadImageFromPicker(
    bucket: string,
    userId: string,
    options?: ImagePicker.ImagePickerOptions,
    onProgress?: (progress: UploadProgress) => void
  ): Promise<FileUploadResult> {
    try {
      // Solicitar permissões
      const { status } = await ImagePicker.requestMediaLibraryPermissionsAsync();
      if (status !== 'granted') {
        throw new Error('Permissão para acessar galeria negada');
      }

      // Abrir seletor de imagem
      const result = await ImagePicker.launchImageLibraryAsync({
        mediaTypes: ImagePicker.MediaTypeOptions.Images,
        allowsEditing: true,
        aspect: [4, 3],
        quality: 0.8,
        ...options,
      });

      if (result.canceled) {
        throw new Error('Seleção de imagem cancelada');
      }

      const asset = result.assets[0];
      return await this.uploadFile(bucket, userId, asset.uri, asset.fileName || 'image.jpg', onProgress);

    } catch (error) {
      console.error('Erro ao fazer upload de imagem:', error);
      throw error;
    }
  }

  /**
   * Faz upload de um documento selecionado pelo usuário
   */
  async uploadDocumentFromPicker(
    bucket: string,
    userId: string,
    onProgress?: (progress: UploadProgress) => void
  ): Promise<FileUploadResult> {
    try {
      // Abrir seletor de documentos
      const result = await DocumentPicker.getDocumentAsync({
        type: ['application/pdf', 'text/plain', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'],
        copyToCacheDirectory: true,
      });

      if (result.canceled) {
        throw new Error('Seleção de documento cancelada');
      }

      const asset = result.assets[0];
      return await this.uploadFile(bucket, userId, asset.uri, asset.name, onProgress);

    } catch (error) {
      console.error('Erro ao fazer upload de documento:', error);
      throw error;
    }
  }

  /**
   * Faz upload de um arquivo a partir de uma URI
   */
  async uploadFile(
    bucket: string,
    userId: string,
    fileUri: string,
    fileName: string,
    onProgress?: (progress: UploadProgress) => void
  ): Promise<FileUploadResult> {
    try {
      // Verificar se o arquivo existe
      const fileInfo = await FileSystem.getInfoAsync(fileUri);
      if (!fileInfo.exists) {
        throw new Error('Arquivo não encontrado');
      }

      // Gerar nome único para o arquivo
      const fileExtension = fileName.split('.').pop() || 'bin';
      const uniqueFileName = `${userId}/${Date.now()}_${randomUUID()}.${fileExtension}`;

      // Ler o arquivo como base64
      const fileContent = await FileSystem.readAsStringAsync(fileUri, {
        encoding: FileSystem.EncodingType.Base64,
      });

      // Converter base64 para ArrayBuffer
      const byteCharacters = atob(fileContent);
      const byteNumbers = new Array(byteCharacters.length);
      for (let i = 0; i < byteCharacters.length; i++) {
        byteNumbers[i] = byteCharacters.charCodeAt(i);
      }
      const byteArray = new Uint8Array(byteNumbers);

      // Determinar tipo MIME
      const mimeType = this.getMimeType(fileExtension);

      // Simular progresso se callback fornecido
      if (onProgress) {
        onProgress({ loaded: 0, total: byteArray.length, percentage: 0 });
      }

      // Fazer upload para o Supabase Storage
      const { data, error } = await supabase.storage
        .from(bucket)
        .upload(uniqueFileName, byteArray, {
          contentType: mimeType,
          cacheControl: '3600',
          upsert: false,
        });

      if (error) {
        throw error;
      }

      // Simular progresso completo
      if (onProgress) {
        onProgress({ loaded: byteArray.length, total: byteArray.length, percentage: 100 });
      }

      // Obter URL pública
      const { data: publicUrlData } = supabase.storage
        .from(bucket)
        .getPublicUrl(uniqueFileName);

      return {
        url: publicUrlData.publicUrl,
        path: data.path,
        name: fileName,
        size: byteArray.length,
        type: mimeType,
      };

    } catch (error) {
      console.error('Erro no upload do arquivo:', error);
      throw error;
    }
  }

  /**
   * Faz upload de dados base64
   */
  async uploadBase64(
    bucket: string,
    userId: string,
    base64Data: string,
    fileName: string,
    onProgress?: (progress: UploadProgress) => void
  ): Promise<FileUploadResult> {
    try {
      // Extrair dados base64 e tipo MIME
      const [header, data] = base64Data.split(',');
      const mimeType = header.match(/:(.*?);/)?.[1] || 'application/octet-stream';
      
      // Gerar nome único
      const fileExtension = this.getExtensionFromMimeType(mimeType);
      const uniqueFileName = `${userId}/${Date.now()}_${randomUUID()}.${fileExtension}`;

      // Converter para ArrayBuffer
      const byteCharacters = atob(data);
      const byteNumbers = new Array(byteCharacters.length);
      for (let i = 0; i < byteCharacters.length; i++) {
        byteNumbers[i] = byteCharacters.charCodeAt(i);
      }
      const byteArray = new Uint8Array(byteNumbers);

      // Simular progresso
      if (onProgress) {
        onProgress({ loaded: 0, total: byteArray.length, percentage: 0 });
      }

      // Upload
      const { data: uploadData, error } = await supabase.storage
        .from(bucket)
        .upload(uniqueFileName, byteArray, {
          contentType: mimeType,
          cacheControl: '3600',
          upsert: false,
        });

      if (error) {
        throw error;
      }

      // Progresso completo
      if (onProgress) {
        onProgress({ loaded: byteArray.length, total: byteArray.length, percentage: 100 });
      }

      // URL pública
      const { data: publicUrlData } = supabase.storage
        .from(bucket)
        .getPublicUrl(uniqueFileName);

      return {
        url: publicUrlData.publicUrl,
        path: uploadData.path,
        name: fileName,
        size: byteArray.length,
        type: mimeType,
      };

    } catch (error) {
      console.error('Erro no upload base64:', error);
      throw error;
    }
  }

  /**
   * Remove um arquivo do storage
   */
  async deleteFile(bucket: string, filePath: string): Promise<void> {
    try {
      const { error } = await supabase.storage
        .from(bucket)
        .remove([filePath]);

      if (error) {
        throw error;
      }
    } catch (error) {
      console.error('Erro ao deletar arquivo:', error);
      throw error;
    }
  }

  /**
   * Lista arquivos em um bucket
   */
  async listFiles(bucket: string, folder?: string): Promise<any[]> {
    try {
      const { data, error } = await supabase.storage
        .from(bucket)
        .list(folder);

      if (error) {
        throw error;
      }

      return data || [];
    } catch (error) {
      console.error('Erro ao listar arquivos:', error);
      throw error;
    }
  }

  /**
   * Baixa um arquivo do storage
   */
  async downloadFile(bucket: string, filePath: string): Promise<string> {
    try {
      const { data, error } = await supabase.storage
        .from(bucket)
        .download(filePath);

      if (error) {
        throw error;
      }

      // Converter Blob para URI local
      const arrayBuffer = await data.arrayBuffer();
      const base64 = btoa(String.fromCharCode(...new Uint8Array(arrayBuffer)));
      
      // Salvar no sistema de arquivos local
      const fileName = filePath.split('/').pop() || 'download';
      const localUri = `${FileSystem.documentDirectory}${fileName}`;
      
      await FileSystem.writeAsStringAsync(localUri, base64, {
        encoding: FileSystem.EncodingType.Base64,
      });

      return localUri;
    } catch (error) {
      console.error('Erro ao baixar arquivo:', error);
      throw error;
    }
  }

  /**
   * Cria um bucket se não existir
   */
  async createBucketIfNotExists(bucketName: string, isPublic: boolean = false): Promise<void> {
    try {
      // Verificar se bucket existe
      const { data: buckets } = await supabase.storage.listBuckets();
      const bucketExists = buckets?.some(bucket => bucket.name === bucketName);

      if (!bucketExists) {
        const { error } = await supabase.storage.createBucket(bucketName, {
          public: isPublic,
          fileSizeLimit: 50 * 1024 * 1024, // 50MB
          allowedMimeTypes: [
            'image/jpeg',
            'image/png',
            'image/gif',
            'application/pdf',
            'text/plain',
            'application/msword',
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
          ]
        });

        if (error) {
          throw error;
        }
      }
    } catch (error) {
      console.error('Erro ao criar bucket:', error);
      throw error;
    }
  }

  /**
   * Obter URL assinada para arquivo privado
   */
  async getSignedUrl(bucket: string, filePath: string, expiresIn: number = 3600): Promise<string> {
    try {
      const { data, error } = await supabase.storage
        .from(bucket)
        .createSignedUrl(filePath, expiresIn);

      if (error) {
        throw error;
      }

      return data.signedUrl;
    } catch (error) {
      console.error('Erro ao gerar URL assinada:', error);
      throw error;
    }
  }

  /**
   * Utilitários privados
   */
  private getMimeType(extension: string): string {
    const mimeTypes: { [key: string]: string } = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'pdf': 'application/pdf',
      'txt': 'text/plain',
      'doc': 'application/msword',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    };

    return mimeTypes[extension.toLowerCase()] || 'application/octet-stream';
  }

  private getExtensionFromMimeType(mimeType: string): string {
    const extensions: { [key: string]: string } = {
      'image/jpeg': 'jpg',
      'image/png': 'png',
      'image/gif': 'gif',
      'application/pdf': 'pdf',
      'text/plain': 'txt',
      'application/msword': 'doc',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document': 'docx',
    };

    return extensions[mimeType] || 'bin';
  }
}

// Exportar instância singleton
export const realStorageService = new RealSupabaseStorageService();
export default realStorageService; 