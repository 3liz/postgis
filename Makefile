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

build:
	docker build --rm $(BUILD_ARGS) \
		--build-arg POSTGRES_GID=$(POSTGRES_UID) \
		--build-arg POSTGRES_UID=$(POSTGRES_UID) \
		--build-arg POSTGRES_VER=$(POSTGRES_VER) \
		--build-arg POSTGIS_VER=$(POSTGIS_VER) \
		-t $(NAME):$(VERSION_TAG) --cache-from=$(NAME):$(VERSION_TAG) $(DOCKERFILE) .



