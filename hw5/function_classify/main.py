import json
import os

import functions_framework
import vertexai
from google.cloud import storage
from vertexai.generative_models import GenerativeModel

_storage_client = storage.Client()
vertexai.init(project=os.environ["PROJECT_ID"], location=os.environ["VERTEX_REGION"])
_model = GenerativeModel("gemini-2.5-flash")

_PROMPT = (
    "Classify the following document as exactly one of: Invoice, Company Data.\n"
    "Reply with only the label, no explanation.\n\n{text}"
)


def _classify(ocr_json: dict) -> str:
    text = ocr_json.get("text", "")[:8000]
    response = _model.generate_content(_PROMPT.format(text=text))
    label = response.text.strip().lower()
    return "invoice" if "invoice" in label else "company_data"


@functions_framework.cloud_event
def classify_document_event(cloud_event):
    data = cloud_event.data
    bucket_name = data["bucket"]
    file_name = data["name"]

    if not file_name.lower().endswith(".json"):
        print(f"Skipping non-JSON file: {file_name}")
        return

    print(f"Cloud event: {cloud_event}")
    print(f"Classifying: gs://{bucket_name}/{file_name}")

    json_bytes = _storage_client.bucket(bucket_name).blob(file_name).download_as_bytes()
    doc_class = _classify(json.loads(json_bytes))

    if doc_class == "invoice":
        dest_bucket = os.environ["INVOICES_BUCKET"]
    else:
        dest_bucket = os.environ["COMPANY_DATA_BUCKET"]

    _storage_client.bucket(dest_bucket).blob(file_name).upload_from_string(
        json_bytes, content_type="application/json"
    )
    print(f"Classified as {doc_class}, saved to gs://{dest_bucket}/{file_name}")
