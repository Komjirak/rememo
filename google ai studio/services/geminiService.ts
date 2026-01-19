
import { GoogleGenAI, Type } from "@google/genai";

const getAI = () => new GoogleGenAI({ apiKey: process.env.API_KEY || '' });

export const analyzeScreenshot = async (base64Image: string): Promise<any> => {
  const ai = getAI();
  const model = 'gemini-3-flash-preview';

  const prompt = "Analyze this screenshot and extract its essence into a structured format. Focus on 'why' the user saved this. Generate a high-quality title and summary.";

  const response = await ai.models.generateContent({
    model,
    contents: [
      {
        parts: [
          { text: prompt },
          { inlineData: { mimeType: 'image/png', data: base64Image.split(',')[1] } }
        ]
      }
    ],
    config: {
      responseMimeType: "application/json",
      responseSchema: {
        type: Type.OBJECT,
        properties: {
          title: { type: Type.STRING },
          summary: { type: Type.STRING },
          category: { type: Type.STRING, description: "One of: Technical, Design, Philosophy, Cooking, Life, Art" },
          tags: { type: Type.ARRAY, items: { type: Type.STRING } },
          ocrText: { type: Type.STRING }
        },
        required: ["title", "summary", "category", "tags"]
      }
    }
  });

  return JSON.parse(response.text);
};
