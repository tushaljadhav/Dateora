import { Platform } from 'react-native';

export interface AIExtractedProduct {
  name: string;
  category: 'groceries' | 'dairy' | 'medicine' | 'skincare' | 'beverages' | 'household' | 'pantry' | 'other';
  expiryDate: string; // YYYY-MM-DD format
  quantity?: number | null;
  unit?: string | null;
  location?: string | null;
  notes?: string | null;
  confidence: 'high' | 'medium' | 'low';
  rawSummary?: string;
}

/**
 * Converts a local file URI (from camera or gallery) to a Base64 string and MIME type.
 * Works seamlessly across both native iOS/Android and Web platforms.
 */
export async function convertImageUriToBase64(
  uri: string
): Promise<{ base64: string; mimeType: string }> {
  let mimeType = 'image/jpeg';
  if (uri.toLowerCase().endsWith('.png')) {
    mimeType = 'image/png';
  } else if (uri.toLowerCase().endsWith('.webp')) {
    mimeType = 'image/webp';
  }

  if (Platform.OS === 'web') {
    // Web: Fetch blob and convert via FileReader
    if (uri.startsWith('data:')) {
      const parts = uri.split(',');
      const header = parts[0];
      const match = header.match(/:(.*?);/);
      if (match) mimeType = match[1];
      return { base64: parts[1], mimeType };
    }

    const response = await fetch(uri);
    const blob = await response.blob();
    mimeType = blob.type || mimeType;

    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onloadend = () => {
        const result = reader.result as string;
        const base64Data = result.split(',')[1];
        resolve({ base64: base64Data, mimeType });
      };
      reader.onerror = reject;
      reader.readAsDataURL(blob);
    });
  }

  // Native: expo-file-system
  const FileSystem = require('expo-file-system');
  const base64 = await FileSystem.readAsStringAsync(uri, {
    encoding: FileSystem.EncodingType.Base64,
  });

  return { base64, mimeType };
}

/**
 * Validates a Google Gemini API Key by making a lightweight test request.
 */
export async function testGeminiApiKey(
  apiKey: string
): Promise<{ success: boolean; message: string }> {
  if (!apiKey || !apiKey.trim()) {
    return { success: false, message: 'Please enter an API key.' };
  }

  const cleanKey = apiKey.trim();
  const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=${cleanKey}`;

  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [
          {
            parts: [{ text: 'Respond with the single word: OK' }],
          },
        ],
        generationConfig: {
          maxOutputTokens: 10,
        },
      }),
    });

    if (!response.ok) {
      const errJson = await response.json().catch(() => ({}));
      const errMsg = errJson?.error?.message || `HTTP error ${response.status}`;
      return { success: false, message: errMsg };
    }

    return { success: true, message: 'Google Gemini connected successfully!' };
  } catch (err: any) {
    return { success: false, message: err?.message || 'Network error connecting to Gemini API.' };
  }
}

/**
 * Analyzes a product image using Google Gemini 1.5/2.0 Flash Multimodal Vision API.
 * Extracts item name, category, and expiry date (with relative date computation).
 */
export async function analyzeProductImageWithGemini(
  imageUri: string,
  apiKey?: string
): Promise<AIExtractedProduct> {
  if (!apiKey || !apiKey.trim()) {
    throw new Error(
      'Gemini API Key is not configured. Please add your free key in Settings -> AI Vision Assistant.'
    );
  }

  const { base64, mimeType } = await convertImageUriToBase64(imageUri);

  const today = new Date();
  const todayStr = `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, '0')}-${String(
    today.getDate()
  ).padStart(2, '0')}`;

  const promptText = `You are Dateora AI — a high-accuracy product expiry & label detection specialist.
Analyze this product picture carefully.

Current Reference Date (Today): ${todayStr}

Your mission:
1. Identify the PRODUCT NAME (Clean, concise, including brand and variant/quantity, e.g. "Amul Taaza Toned Milk 500ml", "Crocin 650mg Paracetamol", "Cetaphil Gentle Skin Cleanser 250ml", "Brown Bread Loaf").
2. Determine CATEGORY (Must be exactly one of: "groceries", "dairy", "medicine", "skincare", "beverages", "household", "pantry", "other").
3. Detect EXPIRED / BEST BEFORE / USE BY DATE:
   - If an absolute date is printed on the package (e.g., "EXP 15/11/2026", "USE BY 28-OCT-26", "24/05/2027"), extract and standardize it into strict "YYYY-MM-DD" format.
   - If the package says relative shelf-life (e.g., "Best before 6 months from Mfg 01/2026"), calculate the target date based on the Mfg date and output strict "YYYY-MM-DD".
   - If the image shows fresh produce (fruits, vegetables, bakery items) with no printed date, estimate a realistic safe shelf-life from today's reference date (${todayStr}) and return that "YYYY-MM-DD".
   - If a date is completely unidentifiable, set expiryDate to 7 days from today: "${todayStr}" + 7 days.
4. Extract QUANTITY and UNIT if clearly visible (e.g., 500 and "ml", 10 and "tablets", 1 and "kg").
5. Suggest STORAGE LOCATION (e.g., "Fridge", "Medicine Box", "Pantry", "Bathroom").
6. Provide brief NOTES explaining how the expiry date was identified.
7. Assign CONFIDENCE: "high" (clear label seen), "medium" (inferred from relative mfg/shelf-life), or "low" (estimated).

Return strictly a valid JSON object matching this schema without any markdown, backticks, or explanation:
{
  "name": "string",
  "category": "groceries" | "dairy" | "medicine" | "skincare" | "beverages" | "household" | "pantry" | "other",
  "expiryDate": "YYYY-MM-DD",
  "quantity": number | null,
  "unit": string | null,
  "location": string | null,
  "notes": string | null,
  "confidence": "high" | "medium" | "low"
}`;

  const cleanKey = apiKey.trim();
  const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=${cleanKey}`;

  const requestBody = {
    contents: [
      {
        parts: [
          { text: promptText },
          {
            inlineData: {
              mimeType: mimeType,
              data: base64,
            },
          },
        ],
      },
    ],
    generationConfig: {
      temperature: 0.1,
      responseMimeType: 'application/json',
    },
  };

  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(requestBody),
  });

  if (!response.ok) {
    const errorData = await response.json().catch(() => ({}));
    const message = errorData?.error?.message || `HTTP ${response.status} from Gemini API`;
    if (response.status === 400 || response.status === 403) {
      throw new Error(`Invalid Gemini API Key: ${message}`);
    }
    if (response.status === 429) {
      throw new Error('Gemini API quota exceeded. Please wait a moment and try again.');
    }
    throw new Error(`Gemini Vision Error: ${message}`);
  }

  const data = await response.json();
  const candidateText = data?.candidates?.[0]?.content?.parts?.[0]?.text;

  if (!candidateText) {
    throw new Error('No response returned by Gemini Vision model.');
  }

  // Parse JSON response
  let parsed: any;
  try {
    const cleanedText = candidateText.trim().replace(/^```json/i, '').replace(/```$/i, '').trim();
    parsed = JSON.parse(cleanedText);
  } catch (err) {
    throw new Error('Could not parse Gemini JSON response. Please retake the photo with good lighting.');
  }

  // Sanitize and validate outputs
  const allowedCategories = ['groceries', 'dairy', 'medicine', 'skincare', 'beverages', 'household', 'pantry', 'other'];
  const category = allowedCategories.includes(parsed.category) ? parsed.category : 'groceries';

  // Validate date format YYYY-MM-DD
  let expiryDate = parsed.expiryDate;
  if (!expiryDate || !/^\d{4}-\d{2}-\d{2}$/.test(expiryDate)) {
    const fallback = new Date();
    fallback.setDate(fallback.getDate() + 7);
    expiryDate = fallback.toISOString().split('T')[0];
  }

  return {
    name: parsed.name || 'Unnamed Product',
    category,
    expiryDate,
    quantity: typeof parsed.quantity === 'number' ? parsed.quantity : null,
    unit: parsed.unit || null,
    location: parsed.location || null,
    notes: parsed.notes || null,
    confidence: parsed.confidence || 'medium',
    rawSummary: candidateText,
  };
}
