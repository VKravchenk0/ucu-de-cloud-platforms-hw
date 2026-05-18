# HW4 Architecture: PDF OCR Pipeline

DocumentAI OCR pipeline. Triggered when a user uploads a PDF file to the input bucket, extracts JSON using DocumentAI, and stores the result in the output bucket.

## Diagram

```mermaid
flowchart LR
    User -->|uploads PDF| InputBucket[(GCS<br>documents-input)]
    InputBucket -->| | Eventarc[Eventarc Trigger]
    Eventarc -->|HTTP POST CloudEvent| CloudFunction[Cloud Function Gen2<br>hw4-ocr-function]
    CloudFunction -->|reads PDF bytes| InputBucket
    CloudFunction -->|OCR request| DocumentAI[Document AI<br>OCR Processor]
    DocumentAI -->|Document JSON| CloudFunction
    CloudFunction -->|uploads json| OutputBucket[(GCS<br>documents-output)]
```
