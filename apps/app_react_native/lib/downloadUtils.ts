import { Linking } from 'react-native';

const API_URL = process.env.EXPO_PUBLIC_API_URL || 'https://api.example.com';

/**
 * Downloads a file by opening the download URL in the browser
 * @param fileId - The ID of the file to download
 */
export const downloadFile = async (fileId: string) => {
  try {
    const url = `${API_URL}/files/${fileId}/download`;
    
    // For mobile, we'll open the URL in the browser
    const supported = await Linking.canOpenURL(url);
    
    if (supported) {
      await Linking.openURL(url);
    } else {
      console.warn('Cannot open URL:', url);
    }
  } catch (error) {
    console.error('Error downloading file:', error);
  }
};

/**
 * Formats file size in bytes to human readable format
 * @param bytes - Size in bytes
 * @returns Formatted string (e.g., "2.5 MB")
 */
export const formatFileSize = (bytes: number): string => {
  if (bytes === 0) return '0 B';
  
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  
  return `${parseFloat((bytes / Math.pow(k, i)).toFixed(1))} ${sizes[i]}`;
};

/**
 * Gets file extension from filename
 * @param filename - The filename
 * @returns File extension (e.g., "pdf", "jpg")
 */
export const getFileExtension = (filename: string): string => {
  return filename.split('.').pop()?.toLowerCase() || '';
};

/**
 * Determines if a file is an image based on its extension
 * @param filename - The filename
 * @returns True if the file is an image
 */
export const isImageFile = (filename: string): boolean => {
  const imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg'];
  const extension = getFileExtension(filename);
  return imageExtensions.includes(extension);
};

/**
 * Determines if a file is a document based on its extension
 * @param filename - The filename
 * @returns True if the file is a document
 */
export const isDocumentFile = (filename: string): boolean => {
  const docExtensions = ['pdf', 'doc', 'docx', 'txt', 'rtf', 'odt'];
  const extension = getFileExtension(filename);
  return docExtensions.includes(extension);
};

/**
 * Extracts text from a PDF file using OCR.space API
 * @param fileUri - The URI of the PDF file
 * @returns Promise with extracted text
 */
export const extractTextFromPDF = async (fileUri: string): Promise<string> => {
  try {
    // Using OCR.space API for PDF text extraction
    const formData = new FormData();
    formData.append('file', {
      uri: fileUri,
      type: 'application/pdf',
      name: 'curriculum.pdf',
    } as any);
    formData.append('apikey', 'K87899142388957'); // Free API key for OCR.space
    formData.append('language', 'por'); // Portuguese
    formData.append('isOverlayRequired', 'false');
    formData.append('detectOrientation', 'true');
    formData.append('scale', 'true');
    formData.append('isTable', 'true');
    formData.append('OCREngine', '2');

    const response = await fetch('https://api.ocr.space/parse/image', {
      method: 'POST',
      body: formData,
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    });

    if (!response.ok) {
      throw new Error(`OCR API error: ${response.status}`);
    }

    const result = await response.json();
    
    if (result.IsErroredOnProcessing) {
      throw new Error(`OCR processing error: ${result.ErrorMessage}`);
    }

    // Extract text from all pages
    let extractedText = '';
    if (result.ParsedResults && result.ParsedResults.length > 0) {
      for (const page of result.ParsedResults) {
        if (page.ParsedText) {
          extractedText += page.ParsedText + '\n\n';
        }
      }
    }

    if (!extractedText.trim()) {
      throw new Error('Não foi possível extrair texto do arquivo PDF');
    }

    return extractedText.trim();
  } catch (error) {
    console.error('Error extracting text from PDF:', error);
    throw new Error('Erro ao extrair texto do PDF. Verifique se o arquivo é válido.');
  }
};

/**
 * Extracts text from different file types
 * @param fileUri - The URI of the file
 * @param filename - The filename to determine type
 * @returns Promise with extracted text
 */
export const extractTextFromFile = async (fileUri: string, filename: string): Promise<string> => {
  const extension = getFileExtension(filename);
  
  switch (extension) {
    case 'pdf':
      return await extractTextFromPDF(fileUri);
    case 'txt':
      // For text files, read directly
      const response = await fetch(fileUri);
      return await response.text();
    default:
      throw new Error(`Tipo de arquivo não suportado: ${extension}. Apenas PDF e TXT são aceitos.`);
  }
}; 