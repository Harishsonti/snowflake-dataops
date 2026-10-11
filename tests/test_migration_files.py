from pathlib import Path
import re

MIGRATIONS_DIR = Path(__file__).resolve().parents[1] / "migrations"
VERSIONED_NAME = re.compile(r"^V(\d+\.\d+\.\d+)__([a-z0-9_]+)\.sql$")


def migration_files():
    return sorted(MIGRATIONS_DIR.glob("*.sql"))


def test_migrations_directory_exists_and_has_sql_files():
    assert migration_files(), "No SQL migration files found in migrations/"


def test_versioned_migration_names_are_valid_and_unique():
    files = migration_files()
    versions = []

    for file in files:
        match = VERSIONED_NAME.match(file.name)
        assert match, f"Invalid migration filename: {file.name}"
        versions.append(tuple(int(part) for part in match.group(1).split(".")))

    assert len(versions) == len(set(versions)), "Duplicate migration versions found"
    assert versions == sorted(versions), "Migration files must be ordered by semantic version"


def test_migration_files_are_not_empty():
    for file in migration_files():
        assert file.read_text(encoding="utf-8").strip(), f"Empty migration file: {file.name}"


def test_expected_schema_objects_are_defined():
    contents = "\n".join(
        file.read_text(encoding="utf-8").upper()
        for file in migration_files()
    )

    assert "CREATE SCHEMA IF NOT EXISTS DATAOPS_DEMO" in contents
    assert "CREATE TABLE IF NOT EXISTS DATAOPS_DEMO.CUSTOMERS" in contents
    assert "CREATE TABLE IF NOT EXISTS DATAOPS_DEMO.ORDERS" in contents
    assert "CREATE OR REPLACE VIEW DATAOPS_DEMO.ORDER_SUMMARY" in contents


def test_migrations_do_not_contain_common_secret_assignments():
    secret_patterns = (
        re.compile(r"(?i)\bpassword\s*=\s*['\"][^'\"]+['\"]"),
        re.compile(r"(?i)\b(secret|token|api_key)\s*=\s*['\"][^'\"]+['\"]"),
    )

    for file in migration_files():
        contents = file.read_text(encoding="utf-8")
        for pattern in secret_patterns:
            assert not pattern.search(contents), f"Possible hard-coded secret in {file.name}"
