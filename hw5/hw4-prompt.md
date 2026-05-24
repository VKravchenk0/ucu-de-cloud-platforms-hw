Create PoC for Application that makes PDF image recognition and saving it to gcp storage in json format.

do all work in the hw4 folder.

1) Draw the architecture of the solution. Use mermaid format
2) Create terraform code to deploy the required infrastructure. 
	1) Use the latest possible version of gcp provider (7 at least)
	2) Make sure to enable all required apis in terraform
	3) Set all required service accounts
	4) Make sure to set all required dependencies in terraform correctly
3) Set a trigger to the input bucket (call it `documents-input`) that will execute a cloud function once new document arrives to the bucket. The function should take that document and send it to the Document AI service that will make OCR as a PDF, get result in JSON and put JSON to the GCP Storage
4) Do not perform the terraform apply command, I'll do it myself
5) Perform terraform plan to see whether the terraform code is correct. If not correct - do the necessary updates and try once more. Retry until the plan would be sucessfull, or you do more then 20 attempts