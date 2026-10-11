# Snowflake DataOps: Versioned SQL Migrations & CI/CD

A portfolio project demonstrating version-controlled Snowflake schema changes, automated validation with GitHub Actions, and controlled deployment using **schemachange**.

## Project status

- [x] Versioned SQL migration scripts
- [x] Automated migration-file checks on pushes and pull requests
- [x] Snowflake connection check and dry-run preview
- [x] Manual deployment workflow with an explicit confirmation gate
- [ ] First live deployment and migration-history verification
- [ ] Least-privilege deployment role and final evidence screenshots

> A successful dry run validates connectivity and previews the scripts. It does **not** execute SQL or prove that a live deployment has completed.

## Architecture

```text
Developer change -> Pull request / push -> pytest migration checks
                                      -> Manual Snowflake connection + dry run
                                      -> Confirmed manual deployment
                                      -> Snowflake objects + change history
```

## Repository layout

```text
.github/workflows/
  validate.yml             # Tests on push / pull request
  snowflake-check.yml      # Manual connection check + dry run
  snowflake-deploy.yml     # Manually confirmed live deployment
migrations/
  V1.0.0__create_schema.sql
  V1.1.0__create_tables.sql
  V1.2.0__create_views.sql
tests/test_migration_files.py
requirements.txt
schemachange-config.yml
```

## Migrations

| Version | Change |
|---|---|
| `1.0.0` | Create `DATAOPS_DEMO` schema if it does not exist |
| `1.1.0` | Create `CUSTOMERS` and `ORDERS` tables if they do not exist |
| `1.2.0` | Create or replace the `ORDER_SUMMARY` view |

Migration names follow `V<major>.<minor>.<patch>__<description>.sql`. Treat a version that has been deployed to a shared environment as immutable; add a new version for later changes instead of editing an applied migration.

## GitHub Actions configuration

Create these **repository Actions secrets** (never commit credentials):

- `SNOWFLAKE_ACCOUNT` — Snowflake account identifier accepted by the Python connector
- `SNOWFLAKE_USER` — Snowflake deployment user
- `SNOWFLAKE_PASSWORD` — password for that user

The workflows target warehouse `DATAOPS_WH`, database `DATAOPS_DB`, and schema `DATAOPS_DEMO`. Adjust the workflow and `schemachange-config.yml` if your environment uses different names.

For live deployment, configure a GitHub Actions environment named `snowflake-demo` under **Settings → Environments**. Add required reviewers/protection rules where available. For production, use a dedicated least-privilege deployment identity, not `ACCOUNTADMIN`.

### 1. Run validation

Push a change or open a pull request against `main`, then open **Actions → Validate SQL Migrations** and confirm pytest passes.

### 2. Check connectivity and preview

Open **Actions → Snowflake Migration Check → Run workflow** on `main`. Confirm connection verification and the dry-run preview succeed. This workflow does not apply migrations.

### 3. Deploy migrations (executes SQL)

1. Confirm the target account, role, warehouse, database, schema, and secrets.
2. Open **Actions → Deploy Snowflake Migrations → Run workflow**.
3. Type exactly `DEPLOY_TO_DATAOPS_DEMO` into the `confirmation` input.
4. Review the run logs.

This workflow executes SQL against the configured Snowflake account. Do not run it against a shared or production account without approval. The confirmation gate is an operational guard, not a replacement for least privilege or environment approval.

The first deployment is expected to create `DATAOPS_DB.DATAOPS_DEMO.CHANGE_HISTORY` and process the three versioned migration files. The schema and table migrations use `IF NOT EXISTS`; the view migration uses `CREATE OR REPLACE VIEW`. Verify the view definition and target environment before running the deployment.

## Verify a live deployment

After the deployment succeeds, run these checks in a Snowflake worksheet:

```sql
SELECT *
FROM DATAOPS_DB.DATAOPS_DEMO.CHANGE_HISTORY
ORDER BY INSTALLED_ON;

SHOW TABLES IN SCHEMA DATAOPS_DB.DATAOPS_DEMO;
SHOW VIEWS IN SCHEMA DATAOPS_DB.DATAOPS_DEMO;

SELECT *
FROM DATAOPS_DB.DATAOPS_DEMO.ORDER_SUMMARY;
```

Confirm versions `1.0.0`, `1.1.0`, and `1.2.0` appear in migration history, the expected objects exist, and the view returns the expected aggregation. If schemachange reports an already-applied migration or a state mismatch, inspect the migration history and object state rather than inserting history rows manually.

## Run tests locally

Requires Python 3.10+ (CI uses Python 3.12).

```bash
python -m pip install -r requirements.txt
python -m pytest -v
```

## Security

- Store credentials only in GitHub Actions secrets.
- Never print secrets or commit local environment files.
- Use a dedicated deployment identity with only the permissions required for the demo schema objects and migration-history table.
- Keep live deployment manual and protected.

## Known limitations / next steps

- The first live deployment has not yet been verified.
- Add SQL linting and migration dependency checks if the project grows.
- Capture sanitized evidence of passing CI, dry-run, successful deployment, and the migration-history table.
