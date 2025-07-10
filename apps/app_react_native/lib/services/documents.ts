import supabase from '@/lib/supabase';
import * as DocumentPicker from 'expo-document-picker';
import * as FileSystem from 'expo-file-system';

export interface DocumentData {
  id: string;
  case_id: string;
  name: string;
  file_path: string;
  file_size: number;
  file_type: string;
  uploaded_by: string;
  uploaded_at: string;
  description?: string;
  category?: 'contract' | 'evidence' | 'identification' | 'other';
  uploader?: {
    name: string;
    avatar?: string;
    role: 'client' | 'lawyer' | 'admin';
  };
}

export interface DocumentUploadData {
  name: string;
  file: File | string; // File object or base64 string
  description?: string;
  category?: DocumentData['category'];
}

/**
 * Busca os documentos de um caso
 * @param caseId - O ID do caso
 */
export const getCaseDocuments = async (caseId: string): Promise<DocumentData[]> => {
  const { data, error } = await supabase
    .from('documents')
    .select(`
      id,
      case_id,
      name,
      file_path,
      file_size,
      mime_type,
      uploaded_by,
      created_at,
      description,
      document_type,
      profiles:uploaded_by (
        full_name,
        avatar_url,
        role
      )
    `)
    .eq('case_id', caseId)
    .order('created_at', { ascending: false });

  if (error) {
    console.error('Error fetching case documents:', error);
    throw error;
  }

  return data?.map(doc => ({
    ...doc,
    uploader: doc.profiles ? {
      name: doc.profiles.full_name,
      avatar: doc.profiles.avatar_url,
      role: doc.profiles.role
    } : undefined
  })) || [];
};

/**
 * Faz upload de um documento para um caso
 * @param caseId - O ID do caso
 * @param userId - O ID do usuário que está fazendo o upload
 * @param documentData - Os dados do documento
 */
export const uploadDocument = async (
  caseId: string,
  userId: string,
  documentData: DocumentUploadData
): Promise<DocumentData> => {
  try {
    // Gerar nome único para o arquivo
    const timestamp = new Date().getTime();
    const fileExtension = documentData.name.split('.').pop();
    const fileName = `${caseId}/${timestamp}_${documentData.name}`;

    // Upload do arquivo para o storage
    const { data: uploadData, error: uploadError } = await supabase.storage
      .from('case-documents')
      .upload(fileName, documentData.file, {
        cacheControl: '3600',
        upsert: false
      });

    if (uploadError) {
      console.error('Error uploading file:', uploadError);
      throw uploadError;
    }

    // Obter URL pública do arquivo
    const { data: publicUrlData } = supabase.storage
      .from('case-documents')
      .getPublicUrl(fileName);

    // Salvar metadados no banco
    const { data, error } = await supabase
      .from('documents')
      .insert({
        case_id: caseId,
        name: documentData.name,
        original_name: documentData.name,
        file_path: uploadData.path,
        file_size: typeof documentData.file === 'string' ? 0 : documentData.file.size,
        mime_type: typeof documentData.file === 'string' ? 'text/plain' : documentData.file.type,
        uploaded_by: userId,
        description: documentData.description,
        document_type: documentData.category || 'other'
      })
      .select(`
        id,
        case_id,
        name,
        file_path,
        file_size,
        mime_type,
        uploaded_by,
        created_at,
        description,
        document_type,
        profiles:uploaded_by (
          full_name,
          avatar_url,
          role
        )
      `)
      .single();

    if (error) {
      console.error('Error saving document metadata:', error);
      throw error;
    }

    return {
      ...data,
      uploader: data.profiles ? {
        name: data.profiles.full_name,
        avatar: data.profiles.avatar_url,
        role: data.profiles.role
      } : undefined
    };
  } catch (error) {
    console.error('Error in uploadDocument:', error);
    throw error;
  }
};

/**
 * Exclui um documento
 * @param documentId - O ID do documento
 */
export const deleteDocument = async (documentId: string): Promise<void> => {
  try {
    // Primeiro, buscar o documento para obter o caminho do arquivo
    const { data: doc, error: fetchError } = await supabase
      .from('documents')
      .select('file_path')
      .eq('id', documentId)
      .single();

    if (fetchError) {
      console.error('Error fetching document:', fetchError);
      throw fetchError;
    }

    // Extrair o nome do arquivo do caminho
    const fileName = doc.file_path.split('/').pop();
    
    // Excluir o arquivo do storage
    const { error: storageError } = await supabase.storage
      .from('case-documents')
      .remove([fileName]);

    if (storageError) {
      console.warn('Error deleting file from storage:', storageError);
      // Continuar mesmo se houver erro no storage
    }

    // Excluir o registro do banco
    const { error: deleteError } = await supabase
      .from('documents')
      .delete()
      .eq('id', documentId);

    if (deleteError) {
      console.error('Error deleting document record:', deleteError);
      throw deleteError;
    }
  } catch (error) {
    console.error('Error in deleteDocument:', error);
    throw error;
  }
};

/**
 * Baixa um documento
 * @param documentId - O ID do documento
 */
export const downloadDocument = async (documentId: string): Promise<string> => {
  try {
    const { data: doc, error } = await supabase
      .from('documents')
      .select('file_path, name')
      .eq('id', documentId)
      .single();

    if (error) {
      console.error('Error fetching document:', error);
      throw error;
    }

    // Para React Native, você pode usar FileSystem para baixar
    const downloadDir = FileSystem.documentDirectory + 'downloads/';
    const fileUri = downloadDir + doc.name;

    // Criar diretório se não existir
    const dirInfo = await FileSystem.getInfoAsync(downloadDir);
    if (!dirInfo.exists) {
      await FileSystem.makeDirectoryAsync(downloadDir, { intermediates: true });
    }

    // Baixar o arquivo
    const downloadResult = await FileSystem.downloadAsync(doc.file_path, fileUri);
    
    return downloadResult.uri;
  } catch (error) {
    console.error('Error downloading document:', error);
    throw error;
  }
};

/**
 * Abre o seletor de documentos do dispositivo
 */
export const pickDocument = async (): Promise<DocumentPicker.DocumentPickerResult> => {
  try {
    const result = await DocumentPicker.getDocumentAsync({
      type: '*/*',
      copyToCacheDirectory: true,
      multiple: false
    });

    return result;
  } catch (error) {
    console.error('Error picking document:', error);
    throw error;
  }
};

/**
 * Verifica se um tipo de arquivo é válido
 * @param fileType - O tipo do arquivo
 */
export const isValidFileType = (fileType: string): boolean => {
  const allowedTypes = [
    'pdf',
    'doc',
    'docx',
    'jpg',
    'jpeg',
    'png',
    'gif',
    'txt',
    'rtf',
    'xls',
    'xlsx',
    'ppt',
    'pptx'
  ];
  
  return allowedTypes.includes(fileType.toLowerCase());
};

/**
 * Formata o tamanho do arquivo
 * @param bytes - O tamanho em bytes
 */
export const formatFileSize = (bytes: number): string => {
  if (bytes === 0) return '0 Bytes';
  
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
};

/**
 * Obtém o ícone baseado no tipo de arquivo
 * @param fileType - O tipo do arquivo
 */
export const getFileIcon = (fileType: string): string => {
  const type = fileType.toLowerCase();
  
  if (['pdf'].includes(type)) return 'file-pdf';
  if (['doc', 'docx'].includes(type)) return 'file-word';
  if (['xls', 'xlsx'].includes(type)) return 'file-excel';
  if (['ppt', 'pptx'].includes(type)) return 'file-powerpoint';
  if (['jpg', 'jpeg', 'png', 'gif'].includes(type)) return 'file-image';
  if (['txt', 'rtf'].includes(type)) return 'file-text';
  
  return 'file';
};