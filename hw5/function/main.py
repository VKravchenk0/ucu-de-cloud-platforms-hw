import json
import os

import functions_framework
from google.cloud import documentai, storage
from google.protobuf.json_format import MessageToDict

_storage_client = storage.Client()
_docai_client = documentai.DocumentProcessorServiceClient(
    client_options={"api_endpoint": f"{os.environ['DOCAI_LOCATION']}-documentai.googleapis.com"}
)


@functions_framework.cloud_event
def process_document(cloud_event):
    data = cloud_event.data
    bucket_name = data["bucket"]
    file_name = data["name"]

    if not file_name.lower().endswith(".pdf"):
        print(f"Skipping non-PDF file: {file_name}")
        return

    print(f"Processing: gs://{bucket_name}/{file_name}")

    pdf_bytes = _storage_client.bucket(bucket_name).blob(file_name).download_as_bytes()

    processor_name = os.environ["PROCESSOR_NAME"]
    request = documentai.ProcessRequest(
        name=processor_name,
        raw_document=documentai.RawDocument(content=pdf_bytes, mime_type="application/pdf"),
    )
    response = _docai_client.process_document(request=request)

    document_dict = MessageToDict(response.document._pb)
    json_bytes = json.dumps(document_dict, ensure_ascii=False, indent=2).encode("utf-8")

    output_bucket_name = os.environ["OUTPUT_BUCKET"]
    output_file_name = os.path.splitext(file_name)[0] + ".json"
    _storage_client.bucket(output_bucket_name).blob(output_file_name).upload_from_string(
        json_bytes, content_type="application/json"
    )

    print(f"Saved: gs://{output_bucket_name}/{output_file_name}")
