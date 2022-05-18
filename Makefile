
LATEST_HASH := $(shell cat .git/refs/heads/master)

build:
	docker build -t syntaf/wetrockpolice:$(LATEST_HASH) \
		--build-arg RAILS_ENV=production \
		--build-arg USER_ID=1000 \
		--build-arg GROUP_ID=1000 \
		-f ./Dockerfile.production \
		.

push:
	docker push syntaf/wetrockpolice$(LATEST_HASH)

deploy:
	helm update -n wetrockpolice -f secrets.yaml wetrockpolice k8s/wetrockpolice

commit:
	echo $(LATEST_HASH) > version.txt