# Implementation Plan - MilSpec Translator Commercialization

## Goal Description
Transform the current prototype into a commercially viable product by improving security, code manageability, and user experience. The key focus is moving API credentials to the backend, restructuring the monolithic `App.tsx`, and adding proper PDF export functionality.

## User Review Required
> [!IMPORTANT]
> **API Key Security**: Currently, the Groq API key is exposed in the frontend code. I will move this to the backend (`server.js`) to secure it. This requires running both the React app and the Express server.

> [!NOTE]
> **Hardcoded Enhancements**: The current `enhanceWithVeteranSpecifics` function contains hardcoded overrides (e.g., `if (true)` blocks). I will assume these were temporary hacks and refactor them to be more dynamic or clearly separated strategies.

## Proposed Changes

### Backend (Security)
#### [MODIFY] [server.js](file:///d:/milspec-translator/server.js)
- Update `/api/translate` endpoint to handle the specific prompts and interaction with Groq.
- Ensure `dotenv` is working correctly for `GROQ_API_KEY`.
- Add proper validation and error handling.

### Frontend (Architecture & UI)
#### [MODIFY] [App.tsx](file:///d:/milspec-translator/src/App.tsx)
- Remove direct API calls to Groq. replace with calls to `/api/translate`.
- Extract components to `src/components/` (InputForm, ResultsDisplay, Header, etc.).
- Remove the "fake" hardcoded logic or move it to a refined post-processing utility if needed.

#### [NEW] [src/components/InputForm.tsx](file:///d:/milspec-translator/src/components/InputForm.tsx)
- Encapsulate the form inputs (Military Role, Years, etc.).

#### [NEW] [src/components/ResultsDisplay.tsx](file:///d:/milspec-translator/src/components/ResultsDisplay.tsx)
- Display the translation results (Civilian Titles, Skills, etc.).

#### [NEW] [src/services/api.ts](file:///d:/milspec-translator/src/services/api.ts)
- Centralize API calling logic.

### Functionality (PDF Export)
#### [NEW] [src/utils/pdfGenerator.ts](file:///d:/milspec-translator/src/utils/pdfGenerator.ts)
- Implement `jspdf` or `react-pdf` to generate a professional PDF report instead of a text file.

## Verification Plan

### Automated Tests
- Run `npm test` to ensure no regressions in basic logic.

### Manual Verification
1.  **Security**: Inspect network tab to ensure no calls to `api.groq.com` are made directly from the browser (only to `localhost:5000/api/translate`).
2.  **functionality**: Complete a full flow (Input -> Generate -> Result) and verify data quality.
3.  **PDF**: Generate a report and verify it opens as a formatted PDF.
