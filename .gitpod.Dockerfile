
FROM gitpod/workspace-full

ENV RETRIGGER=4

USER root

# Install dazzle, buildkit and pre-commit
ENV BUILDKIT_VERSION=0.12.1
ENV BUILDKIT_FILENAME=buildkit-v${BUILDKIT_VERSION}.linux-amd64.tar.gz
ENV DAZZLE_VERSION=0.1.17

RUN curl -sSL https://github.com/moby/buildkit/releases/download/v${BUILDKIT_VERSION}/${BUILDKIT_FILENAME} | tar -xvz -C /usr
RUN curl -sSL https://github.com/gitpod-io/dazzle/releases/download/v${DAZZLE_VERSION}/dazzle_${DAZZLE_VERSION}_Linux_x86_64.tar.gz | tar -xvz -C /usr/local/bin
RUN curl -sSL https://github.com/mvdan/sh/releases/download/v3.5.1/shfmt_v3.5.1_linux_amd64 -o /usr/bin/shfmt \
    && chmod +x /usr/bin/shfmt
RUN install-packages shellcheck \
    && pip3 install pre-commit
RUN curl -sSL https://github.com/mikefarah/yq/releases/download/v4.22.1/yq_linux_amd64 -o /usr/bin/yq && chmod +x /usr/bin/yq

# Install PostgreSQL 
# https://github.com/larsks/so-example-73710360-gitpod-test/blob/fixed/Dockerfile
# https://github.com/gitpod-io/workspace-images/blob/main/chunks/tool-postgresql/Dockerfile

ENV PGWORKSPACE="/workspace/.pgsql"
ENV PGDATA="$PGWORKSPACE/data"

# ENV PGUSER=gitpod
# ENV PGPASSWORD=gitpod
# ENV PGPORT=5432

RUN sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && \
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && \
    sudo apt -y update && \
    sudo install-packages postgresql-16 postgresql-contrib-16

# Setup PostgreSQL server for user postgres
ENV PATH="/usr/lib/postgresql/16/bin:$PATH"

SHELL ["/usr/bin/bash", "-c"]

RUN PGDATA="${PGDATA//\/workspace/$HOME}" \
 && mkdir -p ~/.pg_ctl/bin ~/.pg_ctl/sockets $PGDATA \
 && initdb -D $PGDATA \
 && printf '#!/bin/bash\npg_ctl -D $PGDATA -l ~/.pg_ctl/log -o "-k ~/.pg_ctl/sockets" start\n' > ~/.pg_ctl/bin/pg_start \
 && printf '#!/bin/bash\npg_ctl -D $PGDATA -l ~/.pg_ctl/log -o "-k ~/.pg_ctl/sockets" stop\n' > ~/.pg_ctl/bin/pg_stop \
 && chmod +x ~/.pg_ctl/bin/*

ENV PATH="$HOME/.pg_ctl/bin:$PATH"
ENV DATABASE_URL="postgresql://gitpod@localhost"
ENV PGHOSTADDR="127.0.0.1"
ENV PGDATABASE="postgres"

COPY --chown=gitpod:gitpod postgresql-hook.bash $HOME/.bashrc.d/200-postgresql-launch

USER gitpod
