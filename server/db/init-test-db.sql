-- Runs once when the local PostgreSQL container is first created: adds the
-- database the server tests use (they wipe it before every test).
CREATE DATABASE ebucard_test OWNER ebucard;
