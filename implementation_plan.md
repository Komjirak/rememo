# Implementation Plan - AI Personal Bookmark Library (Stribe)

## 1. Project Overview
**Stribe** is a personal knowledge library service that leverages AI to transform passive screenshot captures into structured, searchable memo cards. The goal is to move from "saving" to "remembering" without manual effort.

## 2. Core Features (MVP)
*   **Capture**: Auto-detect screenshots (iOS focus) and upload.
*   **Processing**: AI Pipeline for OCR, Categorization, Summarization, and Tagging.
*   **Organization**: Inbox for new items, Library for processed/sorted items.
*   **Retrieval**: Full-text search and filtering.
*   **Insights**: Aggregated view of interests over time.

## 3. Technical Architecture & Decisions

### 3.1 Frontend Platform
*Decision: Flutter (Mobile-First)*
*   **Rationale**: Directly addresses the core "Screenshot Capture" requirement. Matches the user's mobile app goal.
*   **Workflow**: The user will provide UI designs/references in Next.js/HTML format. The AI will translate these into Flutter Widgets, ensuring a 1:1 visual match while maintaining native performance.

### 3.2 Design System (Planned)
*   **Aesthetics**: Minimalist, content-focused, "Premium" feel (Glassmorphism, clean typography).
*   **Typography**: Inter or Outfit (Modern Sans).
*   **Theme**: Dark mode support (critical for media-heavy apps).


## 4. Initial Roadmap
1.  **Project Initialization**: Set up the repository and core dependencies.
2.  **Design Tokens**: Define colors, spacing, and typography variables.
3.  **Mock Data / Interface**: Build the "Inbox" and "Memo Card" UI components to validate the "AI Output" structure.
4.  **Prototype Logic**: Mock the AI analysis pipeline to demonstrate the specific metadata extraction (Title, Source, Tags).
