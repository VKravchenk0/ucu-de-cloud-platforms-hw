# HW5: PDF OCR + Classification Pipeline

Two-stage serverless pipeline: OCR extracts text from uploaded PDFs, then a Vertex AI Gemini-powered classifier routes each JSON result to a dedicated bucket based on document type (Invoice or Company Data).

## Diagram

```mermaid
flowchart LR
    User -->|uploads PDF| InputBucket[(GCS\npdf-input)]

    InputBucket --> Eventarc1[Eventarc Trigger]
    Eventarc1 -->|CloudEvent| OCRFunction[Cloud Function Gen2\nhw5-ocr-function]
    OCRFunction -->|reads PDF bytes| InputBucket
    OCRFunction -->|OCR request| DocumentAI[Document AI\nOCR Processor]
    DocumentAI -->|Document JSON| OCRFunction
    OCRFunction -->|uploads JSON| OCROutput[(GCS\nocr-results)]

    OCROutput --> Eventarc2[Eventarc Trigger]
    Eventarc2 -->|CloudEvent| ClassifyFunction[Cloud Function Gen2\nhw5-classify-function]
    ClassifyFunction -->|reads JSON| OCROutput
    ClassifyFunction -->|classify text| Gemini[Vertex AI\nGemini]
    Gemini -->|Invoice / Company Data| ClassifyFunction
    ClassifyFunction -->|Invoice| InvoicesBucket[(GCS\ninvoices)]
    ClassifyFunction -->|Company Data| CompanyDataBucket[(GCS\ncompany-data)]
```

## Buckets

| Bucket | Purpose |
|--------|---------|
| `{project}-pdf-input` | Raw PDF uploads (pipeline entry point) |
| `{project}-ocr-results` | Intermediate OCR JSON (feeds classifier) |
| `{project}-invoices` | Classified invoice documents |
| `{project}-company-data` | Classified company data documents |
| `{project}-hw5-function-source` | Cloud Function deployment archives |

## Classification

`hw5-classify-function` sends the OCR text to **Vertex AI Gemini** (`gemini-2.0-flash-001`) with a zero-shot prompt asking it to label the document as *Invoice* or *Company Data*. The result determines which output bucket receives the JSON.
