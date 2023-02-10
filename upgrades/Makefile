SHELL:=bash
# 
# Build postgres upgrade image
#
#

NAME=postgis-upgrade

REPO:=

BUILDID=$(shell date +"%Y%m%d%H%M")
COMMITID=$(shell git rev-parse --short HEAD)

ifdef REGISTRY_URL
REGISTRY_PREFIX=$(REGISTRY_URL)/
BUILD_ARGS += --build-arg REGISTRY_PREFIX=$(REGISTRY_PREFIX)
endif

build: VERSION_TAG=$(PGVERSIONOLD)-to-$(PGVERSIONNEW)
build: manifest
	docker build --rm $(BUILD_ARGS) \
		--build-arg PGVERSIONOLD=$(PGVERSIONOLD) \
		--build-arg PGVERSIONNEW=$(PGVERSIONNEW) \
		--build-arg POSTGISVERSIONOLD=$(POSTGISVERSIONOLD) \
		--build-arg POSTGISVERSIONNEW=$(POSTGISVERSIONNEW) \
		-t $(REPO)$(NAME):$(PGVERSIONOLD)-to-$(PGVERSIONNEW) $(DOCKERFILE) .

MANIFEST=factory.manifest

manifest: 
	@echo name=$(NAME) > $(MANIFEST) && \
    echo version=$(VERSION_TAG) >> $(MANIFEST) && \
    echo buildid=$(BUILDID)   >> $(MANIFEST) && \
    echo commitid=$(COMMITID) >> $(MANIFEST)


12-to-13: PGVERSIONOLD=12
12-to-13: PGVERSIONNEW=13
12-to-13: POSTGISVERSIONOLD=2.5
12-to-13: POSTGISVERSIONNEW=3
12-to-13: build

13-to-14: PGVERSIONOLD=13
13-to-14: PGVERSIONNEW=14
13-to-14: POSTGISVERSIONOLD=3
13-to-14: POSTGISVERSIONNEW=3
13-to-14: build

14-to-15: PGVERSIONOLD=14
14-to-15: PGVERSIONNEW=15
14-to-15: POSTGISVERSIONOLD=3
14-to-15: POSTGISVERSIONNEW=3
14-to-15: build

