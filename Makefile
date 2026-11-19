TAG ?= v0.3831.0-themes.1
VERSION ?= $(patsubst v%,%,$(TAG))
IMAGE ?= ghcr.io/ivan-vibe/datalens-ui-crab:$(VERSION)
DIST_URL ?=

.PHONY: help dist up down logs image release

help:
	@echo "make dist TAG=$(TAG)   download the release dist into ./dist"
	@echo "make up                build and start on :8094"
	@echo "make down              stop"
	@echo "make logs              follow logs"
	@echo "make image             build the runtime image"
	@echo "make release SRC=... VERSION=...  package and publish a dist"

dist:
	./scripts/fetch-dist.sh $(TAG)

up:
	docker compose up -d --build

down:
	docker compose down

logs:
	docker compose logs -f ui

image:
	docker build $(if $(DIST_URL),--build-arg DIST_URL=$(DIST_URL),) -t $(IMAGE) .

release:
	./scripts/release-dist.sh "$(SRC)" "$(VERSION)"
