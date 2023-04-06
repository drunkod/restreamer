ARG RESTREAMER_UI_IMAGE=datarhei/restreamer-ui:latest

ARG CORE_IMAGE=datarhei/base:alpine-core-latest

ARG FFMPEG_IMAGE=datarhei/base:alpine-ffmpeg-latest

FROM $RESTREAMER_UI_IMAGE as restreamer-ui

FROM $CORE_IMAGE as core

FROM $FFMPEG_IMAGE

RUN apk --no-cache add sudo tini shadow bash

ARG USERNAME=core
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Add group and user
RUN addgroup $USERNAME -g $USER_GID && \
    adduser -G $USERNAME -u $USER_UID -s /bin/bash -D $USERNAME && \
    echo $USERNAME ALL=\(ALL\) NOPASSWD:ALL > /etc/sudoers.d/nopasswd

# Change user
USER $USERNAME

# Configure a nice terminal
RUN echo "export PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '" >> /home/$USERNAME/.bashrc && \
# Fake poweroff (stops the container from the inside by sending SIGHUP to PID 1)
    echo "alias poweroff='kill -1 1'" >> /home/$USERNAME/.bashrc


COPY --from=core /core /core
COPY --from=restreamer-ui /ui/build /core/ui

ADD https://raw.githubusercontent.com/datarhei/restreamer/2.x/CHANGELOG.md /core/ui/CHANGELOG.md
COPY ./run.sh /core/bin/run.sh
COPY ./ui-root /core/ui-root

RUN ffmpeg -buildconf

ENV CORE_CONFIGFILE=/core/config/config.json
ENV CORE_DB_DIR=/core/config
ENV CORE_ROUTER_UI_PATH=/core/ui
ENV CORE_STORAGE_DISK_DIR=/core/data

EXPOSE 8080/tcp
EXPOSE 8181/tcp
EXPOSE 1935/tcp
EXPOSE 1936/tcp
EXPOSE 6000/udp

VOLUME ["/core/data", "/core/config"]

ENTRYPOINT ["/sbin/tini", "--", "/core/bin/run.sh"]
WORKDIR /core
CMD ["/bin/bash"]
