#!make

SHELL:=/bin/bash
REGISTRY:=example_registry
GCP_REGISTRY:=gcp_example_registry
VERSION:=latest

docker-build-base:
	docker build -f Dockerfile-base -t ${REGISTRY}/gobierto-base:${VERSION} .

docker-build-base-no-cache:
	docker build -f Dockerfile-base -t ${REGISTRY}/gobierto-base:${VERSION} --no-cache .

docker-build:
	docker build -f Dockerfile -t ${REGISTRY}/gobierto:${VERSION} .

docker-push-base:
	docker push ${REGISTRY}/gobierto-base:${VERSION}
 
docker-push:
	docker push ${REGISTRY}/gobierto:${VERSION}

gcloud-push:
	gcloud docker -- push ${GCP_REGISTRY}/gobierto:${VERSION}

docker-compose-up:
	cp .env.example .env
	docker-compose up

docker-stop-all:
	@docker stop $$(docker ps -q); docker rm $$(docker ps -qa)
