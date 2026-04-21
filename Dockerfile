# Dockerfile
FROM postgres:latest

# Você pode adicionar scripts de inicialização se quiser
# COPY init.sql /docker-entrypoint-initdb.d/

ENV POSTGRES_DB=testdb
ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=password

EXPOSE 5432