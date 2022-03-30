#!/bin/bash

SUCCESS=true
if [ "${1}" != "true" ]; then
  SUCCESS=false
fi

# Avoid breaking for users who don't have GNU base64 command
# https://github.com/pactflow/example-provider-restassured/pull/1
# keep base64 encoded content in one line 
if ! command -v base64 -w 0 &> /dev/null
then
    OAS=$(cat oas/swagger.yml | base64)
else
    OAS=$(cat oas/swagger.yml | base64 -w 0)
fi

REPORT=$(echo 'tested via RestAssured' | base64)

echo "==> Uploading OAS to Pactflow"
curl \
  -X PUT \
  -H "Authorization: Bearer ${PACT_BROKER_TOKEN}" \
  -H "Content-Type: application/json" \
  "${PACT_BROKER_BASE_URL}/contracts/provider/${PACTICIPANT}/version/${GIT_COMMIT}" \
  -d '{
   "content": "'$OAS'",
   "contractType": "oas",
   "contentType": "application/yaml",
   "verificationResults": {
     "success": '$SUCCESS',
     "content": "'$REPORT'",
     "contentType": "text/plain",
     "verifier": "verifier"
   }
 }'