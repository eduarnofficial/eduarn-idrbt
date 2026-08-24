# SecureBank Open Banking API — Secure Development Demo

This project is a runnable Ubuntu 22.04 / AWS-friendly demonstration stack based on the supplied
"SecureBank Open Banking API — Final Demo Stack".

The source design calls for Python + FastAPI, SQLite, OAuth2/JWT, Docker, GitHub Actions,
Semgrep, Trivy, OWASP ZAP, Checkov and optional AWS API Gateway. Everything except the API Gateway
can run locally. The demo intentionally keeps the banking domain small and focuses on security.

## What you get

- FastAPI REST API
- OAuth2 password-flow login with JWT
- SQLite database with Alice and Bob
- BOLA/IDOR protection
- Account and transaction APIs
- Pydantic input validation
- SQLAlchemy parameterized database access
- Docker + Docker Compose
- pytest tests
- Semgrep SAST
- Trivy filesystem/container scanning
- Checkov Terraform/IaC scanning
- GitHub Actions security pipeline
- Terraform example for AWS API Gateway

## Demo credentials

- alice / password123
- bob / password123

These credentials are for training only. Never use them in production.

## Architecture

Client -> FastAPI -> OAuth2/JWT -> Authorization -> SQLite

Security pipeline:

GitHub -> Tests -> Semgrep -> Trivy -> Checkov -> Docker Build

AWS extension:

Internet -> AWS API Gateway -> FastAPI backend

## 1. Ubuntu 22.04 prerequisites

```bash
sudo apt update
sudo apt install -y git curl unzip python3 python3-pip python3-venv docker.io docker-compose-plugin

sudo systemctl enable --now docker
sudo usermod -aG docker $USER
newgrp docker

docker --version
docker compose version
python3 --version
```

For Terraform:

```bash
sudo apt install -y gnupg software-properties-common
curl -fsSL https://apt.releases.hashicorp.com/gpg | \
  sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update
sudo apt install -y terraform
terraform version
```

## 2. Run directly with Python

```bash
git clone <YOUR_REPOSITORY_URL>
cd securebank-openbanking-api

python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

cp .env.example .env
python3 - <<'PY'
import secrets
from pathlib import Path
p = Path(".env")
p.write_text(
    "JWT_SECRET=" + secrets.token_urlsafe(48) +
    "\nDATABASE_URL=sqlite:///./data/securebank.db\n"
)
PY

mkdir -p data

export JWT_SECRET="$(python3 -c 'import secrets; print(secrets.token_urlsafe(48))')"

uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Open:

- http://localhost:8000
- http://localhost:8000/docs
- http://localhost:8000/health

## 3. Run with Docker — recommended

```bash
cp .env.example .env
python3 - <<'PY'
import secrets
from pathlib import Path
Path(".env").write_text(
    "JWT_SECRET=" + secrets.token_urlsafe(48) +
    "\nDATABASE_URL=sqlite:////app/data/securebank.db\n"
)
PY

mkdir -p data
docker compose up --build -d
docker compose ps
docker compose logs -f securebank-api
```

Open:

```text
http://localhost:8000/docs
```

Stop:

```bash
docker compose down
```

The SQLite database is persisted in `./data`.

## 4. Test authentication

```bash
curl -X POST http://localhost:8000/auth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=alice&password=password123"
```

Copy the access_token.

Then:

```bash
export TOKEN="<PASTE_TOKEN>"
curl http://localhost:8000/api/v1/accounts \
  -H "Authorization: Bearer $TOKEN"
```

## 5. Demonstrate BOLA / IDOR protection

Alice owns account ID 1 and Bob owns account ID 2.

Alice can request her own account:

```bash
curl http://localhost:8000/api/v1/accounts/1 \
  -H "Authorization: Bearer $TOKEN"
```

Alice must NOT be able to read Bob's account:

```bash
curl -i http://localhost:8000/api/v1/accounts/2 \
  -H "Authorization: Bearer $TOKEN"
```

Expected:

```text
HTTP 403
{"detail":"You are not authorized to access this account"}
```

This is the secure implementation of the BOLA scenario described in the source material.

## 6. Input validation

Valid transaction:

```bash
curl -X POST http://localhost:8000/api/v1/transactions \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"to_account":2,"amount":500,"description":"Payment"}'
```

Invalid amount:

```bash
curl -X POST http://localhost:8000/api/v1/transactions \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"to_account":2,"amount":-500,"description":"Invalid"}'
```

The Pydantic model rejects negative amounts and amounts over 100000.

## 7. Run tests

```bash
docker compose exec securebank-api pytest -q
```

Or locally:

```bash
source .venv/bin/activate
export JWT_SECRET=local-test-secret
PYTHONPATH=. pytest -q
```

## 8. Semgrep

Install:

```bash
python3 -m pip install semgrep
```

Run:

```bash
semgrep scan --config auto .
```

For the training demonstration, compare vulnerable SQL construction such as:

```python
query = f"SELECT * FROM accounts WHERE id = {account_id}"
```

with the secure SQLAlchemy filtering used by this project.

## 9. Trivy

Install Trivy using the official Aqua Security installation method for Ubuntu.

Filesystem scan:

```bash
trivy fs .
```

Build and scan the image:

```bash
docker build -t securebank:latest .
trivy image securebank:latest
```

## 10. OWASP ZAP

With the application running:

```bash
docker run --rm --network host \
  -t ghcr.io/zaproxy/zaproxy:stable \
  zap-baseline.py -t http://127.0.0.1:8000
```

For an API-focused workshop, use ZAP's API/OpenAPI scanning against the Swagger/OpenAPI definition exposed by FastAPI.

Do not interpret a baseline scan as proof of production security. Review and triage every finding.

## 11. Checkov

```bash
checkov -d terraform/
```

The Terraform directory contains the AWS API Gateway demonstration infrastructure.

## 12. GitHub Actions

Push the repository to GitHub:

```bash
git init
git add .
git commit -m "Initial SecureBank secure API demo"
git branch -M main
git remote add origin <YOUR_GITHUB_REPOSITORY_URL>
git push -u origin main
```

The workflow in:

```text
.github/workflows/security.yml
```

runs:

1. Unit tests
2. Semgrep
3. Trivy filesystem scan
4. Checkov
5. Docker build
6. Trivy container scan

## 13. AWS EC2 deployment

This project can run on an Ubuntu 22.04 EC2 instance.

Recommended training setup:

- Ubuntu Server 22.04 LTS
- 2 vCPU
- 4 GB RAM
- 20+ GB EBS
- Security Group TCP 22 from your admin IP
- TCP 8000 only from your trusted demo IP if directly exposing the API

Do NOT expose port 8000 to the whole internet for a production deployment.

SSH:

```bash
ssh -i <KEY.pem> ubuntu@<EC2_PUBLIC_IP>
```

Install Docker and run:

```bash
sudo apt update
sudo apt install -y git docker.io docker-compose-plugin
sudo systemctl enable --now docker
sudo usermod -aG docker ubuntu
newgrp docker

git clone <YOUR_REPOSITORY_URL>
cd securebank-openbanking-api

cp .env.example .env
python3 - <<'PY'
import secrets
from pathlib import Path
Path(".env").write_text(
    "JWT_SECRET=" + secrets.token_urlsafe(48) +
    "\nDATABASE_URL=sqlite:////app/data/securebank.db\n"
)
PY

mkdir -p data
docker compose up --build -d
docker compose ps
```

Then:

```text
http://<EC2_PUBLIC_IP>:8000/docs
```

For a real production-style AWS deployment, put HTTPS and controlled access in front of the application rather than exposing the application port directly.

## 14. AWS API Gateway Terraform

The Terraform example creates a regional REST API Gateway proxy and a throttling usage plan.

Important: `backend_url` must be a reachable HTTPS endpoint. An EC2 private/local address will not work from API Gateway.

Example:

```bash
cd terraform

terraform init
terraform fmt
terraform validate

export AWS_ACCESS_KEY_ID="<ACCESS_KEY>"
export AWS_SECRET_ACCESS_KEY="<SECRET_KEY>"
export AWS_DEFAULT_REGION="ap-south-1"

terraform plan \
  -var='backend_url=https://YOUR-HTTPS-BACKEND.example.com'

terraform apply \
  -var='backend_url=https://YOUR-HTTPS-BACKEND.example.com'
```

Get the output:

```bash
terraform output
```

The simple example intentionally does not create the EC2 instance, VPC, TLS certificate, domain, or load balancer. Those should be separate production infrastructure components.

## 15. Security demonstration sequence

### Part 1 — Bank API

Open:

```text
http://localhost:8000/docs
```

Demonstrate:

- POST /auth/token
- GET /api/v1/accounts
- GET /api/v1/accounts/{account_id}
- POST /api/v1/transactions

### Part 2 — BOLA

Login as Alice.

Try to read account 2.

Expected secure behavior: 403.

### Part 3 — Input validation

Try:

```json
{"to_account": 2, "amount": -500, "description": "Invalid"}
```

Then:

```json
{"to_account": 2, "amount": 999999999, "description": "Invalid"}
```

### Part 4 — Secrets

The source code does not contain a hard-coded JWT secret.

Instead:

```text
.env -> Docker -> application
```

### Part 5 — SAST

Run Semgrep and explain how insecure SQL patterns can be detected before deployment.

### Part 6 — Dependency/container security

Run Trivy against:

```text
trivy fs .
trivy image securebank:latest
```

### Part 7 — DAST

Run ZAP against the running API.

### Part 8 — IaC

Run:

```bash
checkov -d terraform/
```

### Part 9 — AWS

Show:

```text
Internet
   |
AWS API Gateway
   |
SecureBank API
   |
SQLite
```

## 16. Important production limitations

This is a training/demo application, not a production banking platform.

For production you would normally replace or enhance:

- SQLite -> managed relational database
- Demo OAuth2 password flow -> hardened enterprise IdP/authorization server
- EC2 direct exposure -> private service + load balancer/API Gateway
- Demo JWT secret -> AWS Secrets Manager/KMS or equivalent
- CORS `*` -> explicit trusted origins
- Simple transfer logic -> transactional ledger and concurrency controls
- Demo credentials -> enterprise identity lifecycle
- Basic logging -> centralized audit/security logging
- Single container -> highly available deployment
- No TLS termination in the app -> managed HTTPS/TLS
- No WAF -> AWS WAF where appropriate
- No production observability -> metrics, logs, traces and alerting

## 17. Expected final result

After setup you should have:

```text
SecureBank Open Banking API
|
+-- FastAPI REST API
+-- Swagger/OpenAPI UI
+-- OAuth2/JWT authentication
+-- User authorization
+-- BOLA protection
+-- Input validation
+-- SQLite demo database
+-- Docker runtime
+-- Automated tests
+-- Semgrep SAST
+-- Trivy filesystem/container scan
+-- OWASP ZAP DAST
+-- Checkov IaC scan
+-- GitHub Actions security pipeline
+-- Terraform AWS API Gateway example
```

## 18. Quick start

For the fastest demo:

```bash
git clone <YOUR_REPOSITORY_URL>
cd securebank-openbanking-api
cp .env.example .env
python3 - <<'PY'
import secrets
from pathlib import Path
Path(".env").write_text(
    "JWT_SECRET=" + secrets.token_urlsafe(48) +
    "\nDATABASE_URL=sqlite:////app/data/securebank.db\n"
)
PY
mkdir -p data
docker compose up --build -d
```

Open:

```text
http://<HOST>:8000/docs
```

Login:

```text
alice / password123
```

Then demonstrate the BOLA test against account `2`.

## Source alignment

This implementation follows the supplied demo stack: FastAPI + SQLite + OAuth2/JWT, Docker,
GitHub Actions, Semgrep, Trivy, OWASP ZAP, Checkov and optional AWS API Gateway. The supplied
material specifically recommends keeping AWS API Gateway as the final cloud step so that most of
the security demonstration remains runnable locally.
