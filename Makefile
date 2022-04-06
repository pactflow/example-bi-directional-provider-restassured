PACTICIPANT := "pactflow-example-bi-directional-provider-restassured"
GITHUB_REPO := "pactflow/example-bi-directional-provider-restassured"
PACT_CLI="docker run --rm -v ${PWD}:${PWD} -e PACT_BROKER_BASE_URL -e PACT_BROKER_TOKEN pactfoundation/pact-cli:latest"


# Only deploy from master
ifeq ($(GIT_BRANCH),master)
	DEPLOY_TARGET=deploy
else
	DEPLOY_TARGET=no_deploy
endif

all: test

## ====================
## CI tasks
## ====================

ci:
	@if make test; then \
		make publish_contract; \
	else \
		make publish_failure; \
	fi;

create_branch_version:
	PACTICIPANT=${PACTICIPANT} ./scripts/create_branch_version.sh

create_version_tag:
	PACTICIPANT=${PACTICIPANT} ./scripts/create_version_tag.sh

publish_contract: create_branch_version create_version_tag
	@echo "\n========== STAGE: publish contract + results (success) ==========\n"
	PACTICIPANT=${PACTICIPANT} ./scripts/publish.sh true

publish_failure: create_branch_version create_version_tag
	@echo "\n========== STAGE: publish contract + results (failure) ==========\n"
	PACTICIPANT=${PACTICIPANT} ./scripts/publish.sh false

# Run the ci target from a developer machine with the environment variables
# set as if it was on GitHub Actions
# Use this for quick feedback when playing around with your workflows.
fake_ci:
	CI=true \
	GIT_COMMIT=`git rev-parse --short HEAD`+`date +%s` \
	GIT_BRANCH=`git rev-parse --abbrev-ref HEAD` \
	PACT_BROKER_PUBLISH_VERIFICATION_RESULTS=true \
	make ci;
	make can_i_deploy $(DEPLOY_TARGET)

## =====================
## Build/test tasks
## =====================

test:
	./gradlew clean test -i

## =====================
## Deploy tasks
## =====================

deploy: can_i_deploy deploy_app

no_deploy:
	@echo "Not deploying as not on master branch"

can_i_deploy:
	@docker run --rm \
	 -e PACT_BROKER_BASE_URL \
	 -e PACT_BROKER_TOKEN \
	  pactfoundation/pact-cli:latest \
	  broker can-i-deploy \
	  --pacticipant ${PACTICIPANT} \
	  --version ${GIT_COMMIT} \
	  --to-environment production

deploy_app: record_deployment
	@echo "Deploying to prod"

record_deployment:
	@"${PACT_CLI}" broker record_deployment --pacticipant ${PACTICIPANT} --version ${GIT_COMMIT} --environment production

## =====================
## Pactflow set up tasks
## =====================
