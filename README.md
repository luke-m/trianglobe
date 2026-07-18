# Trianglobe

*Find the five. Solve the sphere.*

[![CI](https://github.com/luke-m/trianglobe/actions/workflows/ci.yml/badge.svg)](https://github.com/luke-m/trianglobe/actions/workflows/ci.yml)

A daily geography puzzle: one trivia question defines five hidden cities on a 3D globe.
Tap to find them — misses tell you only the distance to the closest unfound target.

**Live:** http://63.180.155.186 · **Spec:** [docs/SPEC.md](docs/SPEC.md) · **Decisions:** [docs/adr/](docs/adr/)

**Stack:** Java 21 · Spring Boot · PostgreSQL · React + TypeScript + Vite + Tailwind ·
Docker · GitHub Actions · AWS (EC2, ECR, IAM/OIDC) via Terraform

> **Status: M0 — walking skeleton.** Health endpoint and frontend deployed end-to-end;
> game logic lands in M1 (see [SPEC §9](docs/SPEC.md) for the milestone plan).

## Local development

```bash
# Backend (http://localhost:8080)
cd backend && ./mvnw spring-boot:run

# Frontend dev server (http://localhost:5173, proxies /api to :8080)
cd frontend && npm install && npm run dev

# Full stack as it runs in production (http://localhost:8080)
docker compose up --build
```

Tests: `./mvnw verify` (backend) · `npm test` (frontend)

## Architecture, briefly

One production container: the Vite build is baked into the Spring Boot jar's static
resources at image build time (multi-stage [Dockerfile](Dockerfile)) — one origin, no CORS,
one deploy unit. CI tests every push; on `main` it also pushes the image to ECR,
authenticating via **GitHub OIDC** — no long-lived AWS keys exist anywhere. Hosting is a
single EC2 micro instance behind an Elastic IP, chosen deliberately over Fargate/ALB for
cost at zero users ([ADR 001](docs/adr/001-single-ec2-over-fargate.md)); shell access is
SSM-only (no port 22). A $5/month AWS budget alert guards the bill.

## Deployment

Infrastructure is Terraform in [infra/](infra/) (17 resources: ECR, OIDC provider + CI
role, EC2 + instance role, security group, EIP, budget alert).

```bash
cd infra
cp terraform.tfvars.example terraform.tfvars   # fill in alert_email
terraform init && terraform apply              # prints app_url + ci_role_arn

# once, so CI may push images:
gh variable set AWS_ROLE_ARN --body "$(terraform output -raw ci_role_arn)"
```

Redeploy after a new image lands in ECR (any push to `main`):

```bash
terraform apply -replace=aws_instance.app      # fresh instance pulls :latest on boot
```

Tear it all down anytime: `terraform destroy`.
