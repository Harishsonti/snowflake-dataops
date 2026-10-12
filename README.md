# Snowflake DataOps: Versioned SQL Migrations & CI/CD

A working portfolio project demonstrating version-controlled Snowflake schema changes, automated validation with GitHub Actions, and controlled deployments using **schemachange**.

## Verified project status

- [x] Versioned SQL migration scripts for schema, tables, and view
- [x] Automated migration-file tests on pushes and pull requests
- [x] Snowflake connection check and dry-run preview
- [x] Manual live deployment workflow with an explicit confirmation gate
- [x] Deployment workflow serializes runs to avoid overlapping migration executions
- [x] First live deployment completed successfully
- [x] Change history records versions `1.0.0`, `1.1.0`, and `1.2.0` as `Success`
- [ ] Additive `1.3.0` customer-segmentation migration created; pending CI, dry-run, and live deployment verification
- [x] `ORDER_SUMMARY` queried successfully and returned customer-level totals
- [x] Configure and verify GitHub Actions with the dedicated `DATAOPS_DEPLOY_ROLE`
- [ ] Add sanitized portfolio evidence screenshots

## Architecture

```text
Developer change -> Pull request / push -> pytest migration checks
                                      -> Manual Snowflake connection + dry run
                                      -> Confirmed, serialized manual deployment
                                      -> Snowflake objects + change history
```

## Repository layout

```text
.github/workflows/
  validate.yml             # Tests on push / pull request
  snowflake-check.yml      # Manual connection check + dry run
  snowflake-deploy.yml     # Confirmed deployment; serializes runs
docs/
  least-privilege-setup.sql # Starter SQL for deployment role grants
migrations/
  V1.0.0__create_schema.sql
  V1.1.0__create_tables.sql
  V1.2.0__create_views.sql
  V1.3.0__add_customer_segment.sql
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
| `1.3.0` | Add nullable `CUSTOMER_SEGMENT` column to `CUSTOMERS` without changing existing rows |

Migration names follow `V<major>.<minor>.<patch>__<description>.sql`. Tests check naming, semantic-version ordering, duplicate versions, required objects, non-empty files, and common hard-coded secret assignment patterns. These are static checks, not a full SQL parser or comprehensive secret scanner.

Treat a version that has been deployed to a shared environment as immutable; add a new version for later changes instead of editing an applied migration.

## GitHub Actions configuration

Create these **repository Actions secrets** (never commit credentials):

- `SNOWFLAKE_ACCOUNT` — Snowflake account identifier accepted by the Python connector
- `SNOWFLAKE_USER` — Snowflake deployment user
- `SNOWFLAKE_PASSWORD` — password for that user

The workflows target warehouse `DATAOPS_WH`, database `DATAOPS_DB`, and schema `DATAOPS_DEMO`. Adjust the workflow and `schemachange-config.yml` if your environment uses different names.

For live deployment, configure a GitHub Actions environment named `snowflake-demo` under **Settings → Environments**. Add required reviewers/protection rules where available. The deployment workflow requires an explicit confirmation phrase and serializes deployment runs. These are safeguards, not substitutes for correct permissions.

### 1. Run validation

Push a change or open a pull request against `main`, then open **Actions → Validate SQL Migrations** and confirm pytest passes.

### 2. Check connectivity and preview

Open **Actions → Snowflake Migration Check → Run workflow** on `main`. Confirm connection verification and the dry-run preview succeed. This workflow does not apply migrations.

### 3. Deploy migrations (executes SQL)

1. Confirm the target account, role, warehouse, database, schema, and secrets.
2. Open **Actions → Deploy Snowflake Migrations → Run workflow**.
3. Type exactly `DEPLOY_TO_DATAOPS_DEMO` into the `confirmation` input.
4. Review the run logs.

This workflow executes SQL against the configured Snowflake account. Do not run it against a shared or production account without approval. The first live deployment and a subsequent deployment using `DATAOPS_DEPLOY_ROLE` have completed successfully in the demo environment.

## Verify the deployment

Run these checks in a Snowflake worksheet:

```sql
SELECT *
FROM DATAOPS_DB.DATAOPS_DEMO.CHANGE_HISTORY
ORDER BY INSTALLED_ON;

SHOW TABLES IN SCHEMA DATAOPS_DB.DATAOPS_DEMO;
SHOW VIEWS IN SCHEMA DATAOPS_DB.DATAOPS_DEMO;

SELECT *
FROM DATAOPS_DB.DATAOPS_DEMO.ORDER_SUMMARY;
```

The initial deployment recorded versions `1.0.0`, `1.1.0`, and `1.2.0` with status `Success`. The `ORDER_SUMMARY` view returned customer-level order counts and amounts.

## Run tests locally

Requires Python 3.10+ (CI uses Python 3.12).

```bash
python -m pip install -r requirements.txt
python -m pytest -v
```

## Least-privilege role setup

The starter SQL in [`docs/least-privilege-setup.sql`](docs/least-privilege-setup.sql) documents the role setup. The role was created and its grants were reviewed in Snowflake, including `SELECT` on `ORDERS`. Both GitHub Actions workflows now set `SNOWFLAKE_ROLE=DATAOPS_DEPLOY_ROLE`. The migration-check workflow (connection verification plus dry-run) and the confirmed deployment workflow have both completed successfully using that role. For a production implementation, use a dedicated service user instead of a human account.

## Security and operational hardening

- Store credentials only in GitHub Actions secrets.
- Never print secrets or commit local environment files.
- The first deployment used the account's original role; subsequent check and deployment workflow runs verified the dedicated `DATAOPS_DEPLOY_ROLE`.
- Grant only the required warehouse, database, schema, object-creation, and migration-history permissions.
- Keep live deployment manual and protect the `snowflake-demo` environment where the repository plan supports approvals.
- Static secret checks are guardrails, not a guarantee that every secret pattern will be detected.

## Next steps

1. Capture sanitized evidence of passing CI, the dry-run, successful deployment, and the change-history table.
2. Run the migration-check workflow to validate and preview migration `1.3.0`; then deploy it with explicit confirmation and verify the new column in Snowflake.
3. Consider switching from a human Snowflake user to a dedicated service user for a more production-like setup.
