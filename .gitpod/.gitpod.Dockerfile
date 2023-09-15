FROM gitpod/workspace-full

# USER gitpod

# Install PostgreSQL 
# https://github.com/larsks/so-example-73710360-gitpod-test/blob/fixed/Dockerfile
# https://github.com/gitpod-io/workspace-images/blob/main/chunks/tool-postgresql/Dockerfile

ENV TRIGGER_REBUILD=3
ENV PGWORKSPACE="/workspace/.pgsql"
ENV PGDATA="$PGWORKSPACE/data"


RUN sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && \
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && \
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
ENV PGUSER="gitpod"
ENV PGPORT="5432"
ENV DATABASE_URL="postgresql://$PGUSER@localhost:$PGPORT"
ENV PGHOSTADDR="127.0.0.1"
ENV PGDATABASE="postgres"
COPY --chown=gitpod:gitpod postgresql-hook.bash $HOME/.bashrc.d/200-postgresql-launch

USER gitpod
