import supabase from './supabase';
import * as FileSystem from 'expo-file-system';
import { randomUUID } from 'expo-crypto';

// Pequeno utilitário para decodificar base64 em Uint8Array sem depender de módulos nativos
const decodeBase64 = (data: string): Uint8Array => {
  const cleaned = data.replace(/^data:.*;base64,/, '');
  const binary = globalThis.atob ? globalThis.atob(cleaned) : Buffer.from(cleaned, 'base64').toString('binary');
  const len = binary.length;
  const bytes = new Uint8Array(len);
  for (let i = 0; i < len; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes;
};

class StorageService {
  async uploadBase64Image(base64: string, bucket: string, userId: string): Promise<string> {
    try {
      const fileExt = this.getFileExtension(base64);
      if (!fileExt) {
        throw new Error('Não foi possível determinar o tipo do arquivo.');
      }

      const fileName = `${userId}/${randomUUID()}.${fileExt}`;
      const contentType = `image/${fileExt}`;
      
      const { error } = await supabase.storage
        .from(bucket)
        .upload(fileName, decodeBase64(base64), { contentType });

      if (error) {
        throw error;
      }
      
      const { data } = supabase.storage
        .from(bucket)
        .getPublicUrl(fileName);

      return data.publicUrl;

    } catch (error) {
      console.error('Erro no upload da imagem:', error);
      if (error instanceof Error) {
        throw new Error(`Falha no upload da imagem: ${error.message}`);
      }
      throw new Error('Falha no upload da imagem devido a um erro desconhecido.');
    }
  }

  async uploadFile(fileUri: string, bucket: string, userId: string, fileName: string): Promise<string> {
    try {
      // Ler o arquivo como ArrayBuffer
      const fileInfo = await FileSystem.getInfoAsync(fileUri);
      if (!fileInfo.exists) {
        throw new Error('Arquivo não encontrado');
      }

      const fileContent = await FileSystem.readAsStringAsync(fileUri, { encoding: FileSystem.EncodingType.Base64 });
      const arrayBuffer = decodeBase64(`data:application/octet-stream;base64,${fileContent}`);
      
      const fileExt = this.getFileExtensionFromName(fileName);
      const contentType = this.getContentType(fileExt);
      const uploadFileName = `${userId}/${randomUUID()}.${fileExt}`;
      
      const { error } = await supabase.storage
        .from(bucket)
        .upload(uploadFileName, arrayBuffer, { contentType });

      if (error) {
        throw error;
      }
      
      const { data } = supabase.storage
        .from(bucket)
        .getPublicUrl(uploadFileName);

      return data.publicUrl;

    } catch (error) {
      console.error('Erro no upload do arquivo:', error);
      if (error instanceof Error) {
        throw new Error(`Falha no upload do arquivo: ${error.message}`);
      }
      throw new Error('Falha no upload do arquivo devido a um erro desconhecido.');
    }
  }

  private getFileExtension(base64: string): string | null {
    if (base64.startsWith('data:image/jpeg')) return 'jpg';
    if (base64.startsWith('data:image/png')) return 'png';
    // Adicione outros tipos se necessário
    return 'jpg'; // fallback
  }

  private getFileExtensionFromName(fileName: string): string {
    const parts = fileName.split('.');
    return parts[parts.length - 1].toLowerCase();
  }

  private getContentType(extension: string): string {
    const contentTypes: { [key: string]: string } = {
      'pdf': 'application/pdf',
      'txt': 'text/plain',
      'doc': 'application/msword',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
    };
    return contentTypes[extension] || 'application/octet-stream';
  }
}

const storageService = new StorageService();
export default storageService; 