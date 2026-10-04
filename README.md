# Smart Warehouse Management System

Hệ thống quản lý kho đa điểm cho **VietHome Distribution** (doanh nghiệp giả định, phân phối đồ gia dụng, 3 kho).
v1: modular monolith (Spring Boot) + Next.js + Keycloak + PostgreSQL.

- Thiết kế Phase 0: [`docs/superpowers/specs/2026-09-30-phase-0-design.md`](docs/superpowers/specs/2026-09-30-phase-0-design.md)
- Kế hoạch Phase 0: [`docs/superpowers/plans/2026-10-01-phase-0-design-docs.md`](docs/superpowers/plans/2026-10-01-phase-0-design-docs.md)
- Tài liệu: [`docs/`](docs/)

## Bắt đầu

```bash
nvm use                                  # Node 22 (xem .nvmrc)
git config core.hooksPath .githooks      # chặn commit thẳng lên main
./scripts/check-docs.sh                  # kiểm tra tài liệu
```

## Quy trình

Mọi thay đổi đi qua branch → PR → CI xanh → squash merge. Ba commit đầu trên `main` là giai đoạn bootstrap, trước khi có quy trình.
