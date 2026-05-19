# Interview Assistant V2.0 - Commercial Release

**We have successfully upgraded the application to a commercial-grade V2.0.**

## 🌟 Key Features

### 1. Multi-LLM Support
The user can now choose their preferred AI engine. We support:
*   **Groq**: Fastest, free (default).
*   **OpenAI**: GPT-4 / GPT-3.5 (Requires API Key).
*   **Gemini**: Google's latest models (Requires API Key).
*   **Anthropic**: Claude 3 Opus/Sonnet (Requires API Key).

> **How to use**: Go to **Settings -> AI Engine**, select a provider, and paste your API key.

### 2. Context Awareness
You can now provide your background information to get personalized answers.
*   **Resume/Experience**: Paste your summary. The AI will reference your actual experience when suggesting answers.
*   **Job Description**: Paste the target JD. The AI will tailor answers to the role's requirements.

> **How to use**: Go to **Settings -> Context** tab.

### 3. Dynamic UI
*   The overlay window now **automatically resizes** based on the length of the transcript and AI response.
*   Smooth animations for a premium feel.
*   Updated typography and themes.

### 4. Robust Audio System (No VB-Cable Required)
*   Continues to use the native WASAPI Loopback system we implemented previously.
*   Works out-of-the-box with "System Audio" mode for capturing interviewer questions.

## Setup Instructions
1.  **Install New Dependencies**:
    ```bash
    pip install -r requirements.txt
    ```
2.  **Run the App**:
    ```bash
    python src/main.py
    ```
3.  **Configure**:
    *   Open **Settings**.
    *   Set your **AI Provider** (e.g., paste your OpenAI key).
    *   Paste your **Resume** in the Context tab.
    *   Select **System Audio** in the Audio tab for the interview.

## Verification
*   **Check Providers**: Switch between Groq and another provider in Settings. Ask a question and ensure a response is generated.
*   **Check Context**: Add "I have 10 years of Python experience" to the Resume context. Ask "Tell me about myself". The AI should mention the 10 years of experience.
