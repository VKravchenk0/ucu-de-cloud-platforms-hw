echo -n "github_pat" | gcloud secrets create github-pat \
  --data-file=-

  gcloud secrets add-iam-policy-binding github-pat \
  --member="serviceAccount:$(gcloud projects describe playground-482811 --format='value(projectNumber)')@cloudbuild.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"


  curl -H "Authorization: token github_pat" \
https://api.github.com/user/installations

curl -H "Authorization: token github_pat" \
https://api.github.com/user/installations