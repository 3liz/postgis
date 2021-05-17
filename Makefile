SHELL:=bash
# 
# Build postgres+postgis image
#
#

NAME=postgis

POSTGIS_VER:=2.5
POSTGRES_VER:=12
POSTGRES_UID:=$(shell id -u)

VERSION_TAG:=$(POSTGRES_VER)-$(POSTGIS_VER)

ifdef REGISTRY_URL
REGISTRY_PREFIX=$(REGISTRY_URL)/
BUILD_ARGS += --build-arg REGISTRY_PREFIX=$(REGISTRY_PREFIX)
endif

build: manifest
	docker build --rm $(BUILD_ARGS) \
		--build-arg POSTGRES_GID=$(POSTGRES_UID) \
		--build-arg POSTGRES_UID=$(POSTGRES_UID) \
		--build-arg POSTGRES_VER=$(POSTGRES_VER) \
		--build-arg POSTGIS_VER=$(POSTGIS_VER) \
		-t $(NAME):$(VERSION_TAG) --cache-from=$(NAME):$(VERSION_TAG) $(DOCKERFILE) .

MANIFEST=factory.manifest

manifest: 
	@echo name=$(NAME) > $(MANIFEST) && \
    echo version=$(VERSION_TAG) >> $(MANIFEST) && \
    echo buildid=$(BUILDID)   >> $(MANIFEST) && \
    echo commitid=$(COMMITID) >> $(MANIFEST)

push:
	docker tag $(NAME):$(VERSION_TAG)  3liz/$(NAME):$(VERSION_TAG)
	docker push 3liz/$(NAME):$(VERSION_TAG)
ifdef REGISTRY_URL
	docker tag $(NAME):$(VERSION_TAG) $(REGISTRY_URL)/$(NAME):$(VERSION_TAG)
	docker push $(REGISTRY_URL)/$(NAME):$(VERSION_TAG)
endif

