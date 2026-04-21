CREATE TABLE IF NOT EXISTS movies (
    movie_id TEXT PRIMARY KEY,
    title TEXT,
    year TEXT,
    genre TEXT,
    director TEXT
);

CREATE TABLE IF NOT EXISTS users_data (
    user_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE
);

CREATE TABLE IF NOT EXISTS ratings (
    user_id INTEGER NOT NULL REFERENCES users_data(user_id),
    movie_id TEXT NOT NULL REFERENCES movies(movie_id),
    rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
    "timestamp" DATE NOT NULL,
    PRIMARY KEY (user_id, movie_id)
);
