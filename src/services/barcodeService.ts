export interface BarcodeProduct {
  barcode: string;
  name: string;
  brand?: string;
  category: string;
  imageUrl?: string;
  estimatedExpiryDays: number;
}

export async function lookupBarcode(barcode: string): Promise<BarcodeProduct | null> {
  const cleanCode = barcode.trim();
  if (!cleanCode) return null;

  try {
    const response = await fetch(`https://world.openfoodfacts.org/api/v0/product/${cleanCode}.json`);
    if (!response.ok) return null;
    const data = await response.json();

    if (data.status === 1 && data.product) {
      const p = data.product;
      const name = p.product_name || p.generic_name || 'Scanned Product';
      const categoriesText = (p.categories || '').toLowerCase();

      let category = 'groceries';
      let estimatedDays = 14;

      if (
        categoriesText.includes('dairy') ||
        categoriesText.includes('milk') ||
        categoriesText.includes('cheese') ||
        categoriesText.includes('yogurt')
      ) {
        category = 'dairy';
        estimatedDays = 7;
      } else if (
        categoriesText.includes('beverage') ||
        categoriesText.includes('drink') ||
        categoriesText.includes('coffee') ||
        categoriesText.includes('tea')
      ) {
        category = 'beverages';
        estimatedDays = 90;
      } else if (categoriesText.includes('medicine') || categoriesText.includes('pharmacy')) {
        category = 'medicine';
        estimatedDays = 365;
      } else if (
        categoriesText.includes('cosmetic') ||
        categoriesText.includes('beauty') ||
        categoriesText.includes('skin')
      ) {
        category = 'skincare';
        estimatedDays = 180;
      } else if (
        categoriesText.includes('spread') ||
        categoriesText.includes('snack') ||
        categoriesText.includes('biscuit') ||
        categoriesText.includes('cereal')
      ) {
        category = 'pantry';
        estimatedDays = 60;
      }

      return {
        barcode: cleanCode,
        name: p.brands ? `${name} (${p.brands})` : name,
        brand: p.brands,
        category,
        imageUrl: p.image_url || p.image_front_small_url,
        estimatedExpiryDays: estimatedDays,
      };
    }
  } catch (err) {
    console.warn('Barcode lookup failed:', err);
  }

  return null;
}

export const SAMPLE_BARCODES = [
  { label: 'Nutella Hazelnut', code: '3017620422003', emoji: '🍫' },
  { label: 'Oreo Biscuits', code: '7622210449283', emoji: '🍪' },
  { label: 'Nestle Coffee', code: '7613035634567', emoji: '☕' },
  { label: 'Heinz Tomato', code: '8715700421377', emoji: '🥫' },
];
