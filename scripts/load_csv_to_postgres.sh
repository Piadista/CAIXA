#!/usr/bin/env bash
set -euo pipefail

CONTAINER_NAME="${1:-caixa-postgres}"
CSV_DIR="${2:-.}"
DB_NAME="${POSTGRES_DB:-testdb}"
DB_USER="${POSTGRES_USER:-postgres}"
DB_PASSWORD="${POSTGRES_PASSWORD:-password}"

MOVIES_CSV="$CSV_DIR/movies.csv"
USERS_CSV="$CSV_DIR/users.csv"
RATINGS_CSV="$CSV_DIR/ratings.csv"
SCHEMA_SQL="$(dirname "$0")/schema.sql"

if ! command -v docker >/dev/null 2>&1; then
  echo "Erro: docker nao encontrado no PATH."
  exit 1
fi

if [[ ! -f "$MOVIES_CSV" || ! -f "$USERS_CSV" || ! -f "$RATINGS_CSV" ]]; then
  echo "Erro: CSVs nao encontrados em $CSV_DIR"
  echo "Esperado: movies.csv, users.csv, ratings.csv"
  exit 1
fi

if [[ ! -f "$SCHEMA_SQL" ]]; then
  echo "Erro: arquivo schema.sql nao encontrado em $SCHEMA_SQL"
  exit 1
fi

if [[ "$(docker inspect -f '{{.State.Running}}' "$CONTAINER_NAME" 2>/dev/null || true)" != "true" ]]; then
  echo "Erro: container '$CONTAINER_NAME' nao esta em execucao."
  echo "Suba primeiro com: docker run -d --name $CONTAINER_NAME -p 5432:5432 caixa-postgres:1.0.0"
  exit 1
fi

echo "[1/4] Criando tabelas..."
docker exec -i -e PGPASSWORD="$DB_PASSWORD" "$CONTAINER_NAME" \
  psql -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 < "$SCHEMA_SQL"

echo "[2/4] Limpando dados antigos..."
docker exec -i -e PGPASSWORD="$DB_PASSWORD" "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -c "TRUNCATE TABLE ratings, users_data, movies RESTART IDENTITY;"

echo "[3/4] Importando CSVs..."
docker exec -i -e PGPASSWORD="$DB_PASSWORD" "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -c "\\copy movies(movie_id,title,year,genre,director) FROM STDIN WITH (FORMAT csv, HEADER true)" < "$MOVIES_CSV"
docker exec -i -e PGPASSWORD="$DB_PASSWORD" "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -c "\\copy users_data(user_id,name,email) FROM STDIN WITH (FORMAT csv, HEADER true)" < "$USERS_CSV"
docker exec -i -e PGPASSWORD="$DB_PASSWORD" "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -c "\\copy ratings(user_id,movie_id,rating,\"timestamp\") FROM STDIN WITH (FORMAT csv, HEADER true)" < "$RATINGS_CSV"

echo "[4/4] Contagem final de linhas:"
docker exec -i -e PGPASSWORD="$DB_PASSWORD" "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" -c "SELECT 'movies' AS tabela, COUNT(*) AS total FROM movies UNION ALL SELECT 'users_data', COUNT(*) FROM users_data UNION ALL SELECT 'ratings', COUNT(*) FROM ratings;"

echo "Importacao concluida com sucesso."
