SHELL:=/bin/bash -e

TEST_ARGS=--help

.PHONY: all
all: test maint xsr docker-image

.PHONY: test
test: xsr
	./$< $(TEST_ARGS) 2>&1 1>/dev/null | [[ `tee >(cat >&2) | wc -c` -eq 0 ]]

.PHONY: maint
maint: README.md

README.md: xsr README.md.m4 markdown-preset.m4
	m4 --prefix-builtins markdown-preset.m4 \
		README.md.m4 > README.md

DOCKER=docker

DOCKER_TAG=xsr
.PHONY: docker-image
docker-image: Dockerfile
	$(DOCKER) build . -t $(DOCKER_TAG)

X_SOCKET=/tmp/.X11-unix
XAUTHORITY=.Xauthority
ARGS=--no-countdown
RECORDING_FILE=record.html
$(RECORDING_FILE): docker-image $(X_SOCKET) $(XAUTHORITY)
	touch $@
# Getting realpath for $@ needs to be done at shell level, because else it would get touched after make expansion is done
	$(DOCKER) run -it --rm \
		-v $(realpath $(X_SOCKET)):$(realpath $(X_SOCKET)) \
		-v $(realpath $(XAUTHORITY)):/tmp/imported.Xauthority \
		-v "`realpath $@`":/tmp/record.html \
		-e DISPLAY=$(DISPLAY) \
		-e XAUTHORITY=/tmp/imported.Xauthority \
		$(DOCKER_TAG) /tmp/record.html $(ARGS)

.PHONY: run
# syntactic sugar
run: $(RECORDING_FILE)

# https://stackoverflow.com/questions/16296753/can-you-run-gui-apps-in-a-docker-container/25280523#25280523
.Xauthority:
	xauth nlist :0 | sed -e 's/^..../ffff/' | xauth -f $@ nmerge -

.PHONY: open-record
open-record: $(RECORDING_FILE)
	xdg-open $<
