## [1.0.0+25] - 2026-01-29

### Enhanced
- **Template-based Content Summaries**: Applied the content-type specific summary templates to screenshots and image captures as well, ensuring consistent quality across all input methods (Share Link, Screenshot, Camera).
- **Refined Content Type Detection**: Improved logic to distinguish between `Place` (Map/Restaurant), `Shopping`, `News`, and `SNS` more accurately using expanded keyword sets.
- **Unified Analysis Logic**: Merged analysis pathways in `OnDeviceLLM` so that enhanced title extraction and summarization benefit all user flows.

## [1.0.0+24] - 2026-01-29

### Enhanced
- **Advanced Content Analysis**: Improved AI analysis for shared URLs and screenshots.
  - **Smart Title Extraction**: Now intelligently extracts the real title from shared links (e.g., News headlines, SNS captions) instead of generic site names or author IDs.
  - **Content Type Detection**: Automatically categorizes content into `Place` (Map/Restaurant), `Shopping`, `News`, `Tech`, and `SNS` for better organization.
  - **Template-based Summaries**: Provides tailored summary formats for each content type (e.g., "Review/Location" for places, "Price/Product" for shopping, "Key Insights" for articles).
- **Improved Link Processing**: Better handling of shortened URLs (e.g., `naver.me`, `maps.app.goo.gl`) by analyzing the rendered screen content.

### Fixed
- Fixed an issue where generic titles (e.g., "Instagram", "Naver Map") were used for shared links.
- Refined UI noise filtering to prevent legitimate content from being removed during analysis.
