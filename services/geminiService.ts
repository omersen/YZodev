import { GoogleGenAI } from "@google/genai";

const ai = new GoogleGenAI({ apiKey: process.env.API_KEY });

export const generateEducationalContent = async (prompt: string): Promise<string> => {
  try {
    const response = await ai.models.generateContent({
      model: 'gemini-2.5-flash',
      contents: prompt,
      config: {
        systemInstruction: "Sen deneyimli, yapıcı ve yenilikçi bir Fen Bilimleri eğitmenisin. Öğretmenlere modern ödev tasarımı konusunda yardımcı oluyorsun.",
      }
    });
    
    return response.text || "Bir hata oluştu veya yanıt alınamadı.";
  } catch (error) {
    console.error("Gemini API Error:", error);
    return "Üzgünüm, şu anda YZ servisine ulaşılamıyor. Lütfen API anahtarınızı kontrol edin veya daha sonra tekrar deneyin.";
  }
};
