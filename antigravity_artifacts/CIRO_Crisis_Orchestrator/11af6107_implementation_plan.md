# Implementation Plan - Commercial Release V2.0

This plan covers the major architecture overhaul to support multiple LLM providers, dynamic UI, and enhanced user context features.

## Proposed Changes

### 1. LLM Engine Expansion
#### [x] `src/llm_factory.py`
*   Create `LLMFactory` to instantiate clients based on config.
*   Define abstract base class `BaseLLMClient`.

#### [x] `src/llm_client.py` -> `src/llm_providers.py`
*   Refactor existing `GroqLLMClient` to `GroqClient`.
*   Implement new classes:
    *   `GeminiClient` (using `google-generativeai`)
    *   `OpenAIClient` (using `openai`)
    *   `AnthropicClient` (using `anthropic`)

### 2. Configuration & Settings
#### [x] `src/config_manager.py`
*   Update `LLMConfig` to support multiple providers and API keys.
*   Add `context` section for Resume/Job Description storage.

#### [x] `src/settings_dialog.py`
*   **Redesign AI Tab**:
    *   Provider Dropdown (Groq, Gemini, OpenAI, Anthropic).
    *   Dynamic API Key input field (changes based on provider).
    *   Model selection dropdown (updates based on provider).
*   **New "Context" Tab**:
    *   Text area for "Resume / Experience Summary".
    *   Text area for "Job Description".
    *   These will be injected into the System Prompt automatically.

### 3. UI/UX Overhaul
#### [x] `src/overlay_window.py`
*   **Dynamic Resizing**:
    *   Remove fixed height constraints.
    *   Implement `adjustSize()` logic in `ContentPanel` to grow/shrink based on text content.
    *   Add animations for smooth resizing.
*   **Visual Polish**:
    *   Improve typography (Inter font).
    *   Add "Copy to Clipboard" button for AI responses.
    *   Add "Clear" button.

### 4. Dependencies
#### [x] `requirements.txt`
*   Add: `google-generativeai`, `openai`, `anthropic`.

## Verification Plan

### Automated Tests
*   `tests/test_llm_factory.py`: Verify correct client instantiation.
*   `tests/test_providers.py`: Mocked tests for each provider's `generate_response`.

### Manual Verification
1.  **Multi-Model Test**:
    *   Switch to Gemini -> Generate response.
    *   Switch to OpenAI -> Generate response.
2.  **Context Test**:
    *   Paste a dummy resume into Settings.
    *   Ask "Tell me about my experience".
    *   Verify AI references the resume.
3.  **UI Resize Test**:
    *   Trigger a long response. Verify window expands.
    *   Trigger a short response. Verify window shrinks.
