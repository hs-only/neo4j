FROM python:3.11-bookworm

ARG NEO4J_VERSION=5

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        curl \
        gnupg \
        openjdk-17-jre-headless \
    && curl -fsSL https://debian.neo4j.com/neotechnology.gpg.key \
        | gpg --dearmor -o /usr/share/keyrings/neo4j.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/neo4j.gpg] https://debian.neo4j.com stable ${NEO4J_VERSION}" \
        > /etc/apt/sources.list.d/neo4j.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends neo4j \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN neo4j-admin dbms set-initial-password foobarbaz

RUN sed -i 's/#\?server.default_listen_address=.*/server.default_listen_address=0.0.0.0/' \
        /etc/neo4j/neo4j.conf

WORKDIR /app

COPY requirements.txt requirements-dev.txt pyproject.toml README.md ./
COPY neomodel/ neomodel/
COPY test/ test/
COPY bin/ bin/

RUN echo 'pytest<9' > /tmp/constraints.txt \
    && pip install --no-cache-dir -c /tmp/constraints.txt -e '.[dev,extras]'

ENV NEO4J_BOLT_URL=bolt://neo4j:foobarbaz@localhost:7687
ENV NEO4J_ACCEPT_LICENSE_AGREEMENT=yes

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["pytest"]
