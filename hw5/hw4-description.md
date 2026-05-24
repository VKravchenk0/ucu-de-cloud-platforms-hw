
## Infrastructure Components

| Component              | GCP Resource          | Name                                                    |
| ---------------------- | --------------------- | ------------------------------------------------------- |
| Input bucket           | Cloud Storage         | `{project_id}-documents-input`                          |
| Output bucket          | Cloud Storage         | `{project_id}-documents-output`                         |
| Function source bucket | Cloud Storage         | `{project_id}-hw4-function-source`                      |
| OCR function           | Cloud Functions Gen 2 | `hw4-ocr-function`                                      |
| OCR processor          | Document AI           | `hw4-ocr-processor` (type: OCR_PROCESSOR, location: eu) |
| Trigger                | Eventarc              | GCS `object.finalized` on input bucket                  |
| Service account        | IAM                   | `hw4-ocr-sa`                                            |

## Processing Steps

1. User uploads a PDF to `{project_id}-documents-input`
2. GCS emits an `object.finalized` event to Eventarc
3. Eventarc invokes the Cloud Function via HTTP POST (CloudEvents format)
4. Function downloads the PDF bytes from the input bucket
5. Function sends the PDF to Document AI OCR Processor (EU multi-region)
6. Document AI returns a structured `Document` object
7. Function serialises the result to JSON (`MessageToDict`)
8. Function uploads the JSON to `{project_id}-documents-output` with a `.json` extension