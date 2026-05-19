# Switch from Gemini to Groq API

The goal is to replace the Google Gemini API with Groq's API while maintaining the same functionality of translating military experience into civilian career language.

## Proposed Changes

### Environment Variables
- Update `.env` to include `REACT_APP_GROQ_API_KEY` (for frontend) and `GROQ_API_KEY` (for backend).

### [Backend] [server.js](file:///d:/milspec-translator/server.js) [MODIFY]
- Update the `/api/translate` endpoint to call Groq's API instead of Gemini's.
- Use the `llama-3.3-70b-versatile` model.
- Update error handling for Groq's response format.

### [Frontend] [App.tsx](file:///d:/milspec-translator/src/App.tsx) [MODIFY]
- Update `translateMilitary` function to use Groq's API endpoint.
- Change the request body and response parsing to match Groq (OpenAI-compatible).
- Update the API key environment variable name to `REACT_APP_GROQ_API_KEY`.

### [Frontend] [App.js](file:///d:/milspec-translator/src/App.js) [MODIFY]
- Similar changes as `App.tsx` to ensure both files are updated.

## Verification Plan
- I will test the API call using a mock response or by checking the request structure.
- Since I don't have a real Groq key, I'll ensure the code is syntactically correct and handles potential errors gracefully.
- I'll verify that the prompt and JSON extraction logic remains compatible with Groq's output.
