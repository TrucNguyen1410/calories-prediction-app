import { GoogleGenerativeAI } from "@google/generative-ai";
import dotenv from "dotenv";
dotenv.config();

const genAI = new GoogleGenerativeAI(process.env.SUPER_GEMINI_KEY);

async function listModels() {
    try {
        const result = await fetch(`https://generativelanguage.googleapis.com/v1beta/models?key=${process.env.SUPER_GEMINI_KEY}`);
        const data = await result.json();
        console.log("--- CÁC MODEL BẠN ĐƯỢC PHÉP DÙNG ---");
        console.log(JSON.stringify(data, null, 2));
    } catch (error) {
        console.error(error);
    }
}

listModels();
