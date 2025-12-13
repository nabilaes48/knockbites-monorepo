# FuelFlow / StationMaster Platform – Master Architecture

## 1. Purpose
This project is a multi-tenant platform for fuel stations and other future verticals (like CameronConnect). All code should follow these rules.

## 2. Core Ideas
- We have ONE shared core engine (auth, tenants, storage, documents, autopilot).
- We can have MANY verticals (FuelFlow, CameronConnect, others).
- All verticals reuse the same core whenever possible.

## 3. Folder Structure (high level)
- /backend – Node.js API and services
- /backend/src/models – Database models (Sequelize)
- /backend/src/services – Business logic
- /backend/src/routes – API endpoints
- /ARCHITECTURE.md – This master document

## 4. Storage Rules
- All files (invoices, EFTs, tank reports, imports) must go through storageService.
- We store files in Google Cloud Storage (GCS), not on the local disk.
- Models that store files:
  - Document
  - ComplianceDocument
  - ExcelImportARCHITECTURE.md

  - RawArchiveRecord

## 5. Multi-Tenant Rules
- Every record that belongs to a customer must have a tenant_id.
- Never mix data between tenants.
- Unique constraints are per tenant, not global.

## 6. Autopilot Engine
- AutopilotPolicy defines WHEN and WHAT to do.
- AutopilotAction represents a specific action to execute.
- Policies should be reusable across verticals.

## 7. Vertical Strategy
- FuelFlow is the first vertical.
- CameronConnect and others will reuse the same core.
- Do NOT duplicate core logic inside verticals.
## 8. Platform Architecture (Three-Level Model)

The platform follows a 3-level structure:

### LEVEL 1 — SaaS Product
Each vertical (FuelFlow, CameronConnect, etc.) appears to the customer as its own product with its own UI, branding, and workflows.

Examples:
- FuelFlow = fuel stations (invoices, EFT, tank reports, autopilot)
- CameronConnect = legal/compliance workflow (or whatever comes later)

### LEVEL 2 — Platform Engine (Shared Core)
All verticals reuse the same core engine modules. This prevents duplication and keeps the system maintainable.

Shared modules include:
- Auth & Tenants
- Storage (GCS + storageService)
- DocumentHub (ingestion + normalization)
- Autopilot Engine
- Observability & DriftGuardian
- Queue + Scheduler
- Multi-tenant rules
- Common utilities (logging, dates, validation)

### LEVEL 3 — Intelligence Mesh
This is the AI layer shared across verticals.

Includes:
- Normalization intelligence
- Drift detection
- Autopilot reasoning
- LearningEvents
- Predictive analytics
- AI lookups
- Cross-vertical knowledge

Rules:
- AI logic should NEVER live inside a single vertical.
- It must live inside `/shared/ai` or inside a shared service.
## 9. Folder Structure Rules

The backend must follow this structure:

/backend
  /src
    /models            → Sequelize models (tables)
    /migrations        → Database schema changes
    /services          → Business logic
    /routes            → API endpoints
    /controllers       → Route handlers
    /utils             → Helpers and shared utilities
    /shared            → AI, Autopilot, Learning, Normalization
    /verticals         → FuelFlow, CameronConnect (vertical-specific logic)
    /config            → env & settings

Rules:
- Core logic NEVER goes inside a vertical directory.
- Services should be thin and follow single responsibility.
- Each vertical has its own subfolder under `/verticals`.
- Shared services must always be referenced through the shared layer.
## 10. DocumentHub Architecture

DocumentHub handles ALL incoming files and raw data.

Data Sources:
- API Upload
- Email → n8n → POST /api/archive/raw
- Manual admin uploads
- Autopilot uploads
- Third-party parsers (later)

### 10.1 RawArchiveRecord
This is the FIRST stop of all information.
It stores:
- raw text
- metadata (sender, source, file type)
- a pointer to the GCS file

Rule:
RawArchiveRecord should NEVER be bypassed.

### 10.2 Normalization Pipeline
Every document type must follow the same normalization pattern:

1. Classification → Decide type (invoice, eft, tank, notice)
2. Extraction → Try structured extraction
3. Regex fallback → If extraction is incomplete
4. Null fields → If nothing is found
5. LearningEvents → System logs knowledge gaps
6. Final normalized model saved to DB

The workflow MUST produce:
- A clean structured object
- Full audit trace
- Clear extraction source (classification/regex/manual)

### 10.3 Models Supported
- Document → general file
- ComplianceDocument
- ExcelImport
- RawArchiveRecord
## 11. Autopilot Engine Architecture

Autopilot automates decision-making.

Two main models:

### AutopilotPolicy
Defines:
- When a rule should run (cron, triggers)
- What conditions should be checked
- What action types should be generated

### AutopilotAction
Represents a real action created by a policy:
- Status: pending, approved, rejected, executed, failed
- May require manual approval
- Executes a handler

Rules:
- Policies must be reusable across verticals.
- Action types should be simple and referenced through shared handlers.
- Policies describe "WHEN + WHAT"
- Actions describe "HOW"
## 12. Multi-Tenant Database Rules

Every customer belongs to a tenant.

Rules:
- Every record that belongs to a customer MUST have tenant_id.
- DO NOT join across tenants.
- Unique constraints MUST be per-tenant (tenant_id + field).
- Public tables (like lookup tables) should not include tenant_id.
- Never store files on local disk (use GCS path + metadata).
## 13. Database Migration Rules

- All schema changes must use Sequelize migrations.
- Migrations must be idempotent (safe to re-run).
- No destructive changes without explicit review.
- Always add indexes for:
  - tenant_id
  - created_at (for time-based queries)
  - any field used for filtering (supplier_name, document_date, etc.)

Partial Indexes:
- When applicable, use partial indexes for soft-delete fields (deleted_at IS NULL).
## 14. DriftGuardian & Observability

The Observability module tracks:
- Schema drift
- Data drift
- Model extraction accuracy
- Autopilot deviations
- Storage errors

DriftGuardian Responsibilities:
- Compare expected schema vs live schema.
- Detect anomalies (missing fields, wrong indexes, changed types).
- Produce a JSON drift report.
- Expose metrics via /api/admin/metrics.

Rules:
- NO direct DB updates here.
- Drift detection must be READ-ONLY.
- Drift reports should trigger LearningEvents.
## 15. Naming Conventions

### 15.1 File Names
Files must use `camelCase` or `kebab-case` depending on location:

- Services → `camelCaseService.js`
- Controllers → `camelCaseController.js`
- Routes → `camelCaseRoutes.js`
- Models → `PascalCase.js` (Sequelize convention)
- Migrations → `timestamp-description.js`

Examples:
- autopilotPolicyService.js
- storageMigrationQueue.js
- normalizeEft.js
- 20250130000023-create-autopilot-tables.js

### 15.2 Folder Names
- `models`, `services`, `routes`, `controllers`, `utils`, `shared`, `verticals`
- Vertical folders MUST be lowercase: `/verticals/fuelflow`, `/verticals/cameronconnect`

### 15.3 Model Field Names
Database columns must use snake_case.

Examples:
- tenant_id
- document_date
- supplier_name
- created_at

### 15.4 JS Variable & Function Names
Use camelCase:

Examples:
- normalizeEft()
- classifyDocument()
- getStorageUri()
- schedulePolicy()

### 15.5 API Endpoints
Use REST naming:

- GET /api/admin/storage/migration-status
- POST /api/archive/raw
- GET /api/admin/metrics

Rules:
- Collections = plural (`/documents`)
- Single item = singular (`/document/:id`)

### 15.6 Multi-Tenant Names
NEVER include tenant name or tenant code in filenames.

All tenant-specific behavior should be enforced by tenant_id inside the DB.

## 16. Vertical Boundary Rules

Verticals (e.g., FuelFlow, CameronConnect) represent separate products built on top of a shared core engine. The goal is to maximize reuse and prevent duplication.

### 16.1 What MUST live in the Shared Core
The following must NEVER be implemented inside a vertical folder:

- Auth logic
- Tenant logic and permissions
- Storage logic (storageService + GCS integration)
- DocumentHub ingestion, classification, and normalization
- Autopilot Engine (policy + action)
- Observability and DriftGuardian modules
- LearningEvents and AI-related logic
- Queue and scheduler logic
- Shared utilities (logging, dates, validation)
- Pricing / billing framework (if added later)
- Any logic needed by more than one vertical

These belong in `/shared` or `/src/services` depending on responsibility.

**Rule:**  
If more than one vertical could use it, it MUST live in the shared core.

---

### 16.2 What CAN live inside a vertical
Each vertical can contain:

- Vertical-specific routes
- Vertical-specific controllers (API handlers)
- Vertical-specific workflows
- Vertical-specific dashboards (frontend)
- Vertical-specific config
- Vertical-specific document rules

Examples for FuelFlow:
- Fuel invoice workflows using the shared extractor
- Fuel-specific compliance checks
- Station metrics dashboards

Examples for CameronConnect:
- Legal/compliance workflows
- Industry-specific document rules
- Cameron dashboards

---

### 16.3 Folder Structure for Verticals

All verticals live under:

`/backend/src/verticals/`

Example:

- `/backend/src/verticals/fuelflow/`
  - `routes/`
  - `controllers/`
  - `workflows/`
  - `config/`
- `/backend/src/verticals/cameronconnect/`
  - `routes/`
  - `controllers/`
  - `workflows/`
  - `config/`

Rules:

- Vertical folders must ONLY contain vertical-specific logic.
- No core logic is allowed here.
- No database models should live here (models belong to `/models`).
- No migrations should live here (migrations belong to `/migrations`).
- No storage logic should live here.

---

### 16.4 API Layer Rule

Shared API endpoints:

- `/api/admin/*`
- `/api/storage/*`
- `/api/autopilot/*`
- `/api/documents/*`
- `/api/observability/*`

Vertical API endpoints:

- `/api/fuelflow/*`
- `/api/cameronconnect/*`

**Rule:**  
Verticals must NOT create endpoints under shared namespaces.

---

### 16.5 Naming Rules for Verticals

- Vertical folder names MUST be lowercase (`fuelflow`, `cameronconnect`).
- Route files inside a vertical should clearly indicate the vertical, e.g.:
  - `fuelflowRoutes.js`
  - `cameronConnectRoutes.js`
- Route paths must include the vertical prefix:
  - `/fuelflow/stations`
  - `/cameronconnect/cases`

---

### 16.6 Multi-Tenant Boundary Rule

Verticals never implement tenant logic directly.

- They must always rely on shared Auth/TenantService.
- Verticals must NOT:
  - modify `tenant_id` directly
  - override tenant isolation rules
  - query across tenants

---

### 16.7 Autopilot & AI Rule

Verticals may define:

- When Autopilot should run (triggers)
- What conditions to check (thresholds, filters)
- Which policies apply to that vertical

BUT they must NOT define:

- How actions execute internally
- How AI classifies or extracts
- How normalization logic works
- How drift is detected
- How LearningEvents are stored

Those live in the shared core.

---

### 16.8 “Mirror Rule”

If a vertical repeats code that another vertical already uses,
that code belongs in the shared core.

**Rule:**  
Duplication across verticals is a bug in the architecture, not a feature.

### 16.9 API Layer Rule

The API layer is divided into two categories: **shared core endpoints** and **vertical endpoints**.  
This separation ensures that verticals remain thin, while all reusable logic stays in the shared core.

---

#### 16.9.1 Shared API Endpoints (Core Engine)

Shared endpoints belong to the platform itself, not to any vertical.  
They expose reusable infrastructure: storage, documents, autopilot, tenants, and observability.

These routes live under `/api/*`:

- `/api/admin/*`
- `/api/storage/*`
- `/api/autopilot/*`
- `/api/documents/*`
- `/api/observability/*`

**Rule:**  
Verticals must **never** add endpoints under shared namespaces.  
Shared endpoints may only call shared services, not vertical services.

---

#### 16.9.2 Vertical API Endpoints

Vertical-specific features (FuelFlow, CameronConnect, future modules) must live under:

- `/api/fuelflow/*`
- `/api/cameronconnect/*`
- `/api/<vertical>/*`

Vertical endpoints may contain:

- Controllers specific to that vertical  
- Request/response DTOs  
- Vertical-only workflows  
- Light orchestration that calls shared services  

Vertical endpoints must **not** implement:

- Storage logic  
- GCS paths  
- Normalization pipelines  
- Drift detection  
- Autopilot engine internals  
- Tenant logic  
- Any reusable rule or shared mechanism  

Those belong in the shared core.

---

#### 16.9.3 Boundary Rules

To protect architecture integrity:

- A vertical endpoint **may call shared services**, but shared endpoints must **never** call vertical services.
- No database models may exist inside `/backend/src/verticals/*`.
- No migrations may exist inside verticals.
- No vertical may define its own file storage logic — all must use `storageService`.
- Any duplication between verticals indicates a violation of the Mirror Rule (16.8).

---

**Rule:**  
Shared core defines **how the platform works**.  
Vertical endpoints define **what a specific business unit needs**, nothing more.

### 16.10 Directory Structure Rule

The backend is organized to enforce the separation between the shared core engine and all vertical-specific logic.

---

#### 16.10.1 Shared Core Folders

These folders contain the platform engine used by all verticals:

- `/backend/src/models/`  
- `/backend/src/services/`  
- `/backend/src/routes/` (shared namespace only)  
- `/backend/src/core/` (AI, normalization, storage, tenants, autopilot)  
- `/backend/src/observability/`  
- `/backend/src/utils/`  
- `/backend/src/migrations/`  

**Rule:**  
Any logic that is reusable, general, or foundational must live here.  
Nothing inside these folders may reference a vertical.

---

#### 16.10.2 Vertical Folders

Each vertical has its own isolated folder:

- `/backend/src/verticals/fuelflow/`  
- `/backend/src/verticals/cameronconnect/`  
- `/backend/src/verticals/<future-vertical>/`  

A vertical folder may contain:

- Routes under `/api/<vertical>/*`  
- Controllers  
- Request/response DTOs  
- Vertical-only workflows or UI orchestrators  
- Configuration for that vertical  

A vertical folder must **not** contain:

- Database models  
- Migrations  
- Storage logic  
- AI extraction, classification, LLM prompts  
- Tenant logic  
- Normalization pipelines  
- Drift detection  
- Autopilot engine internals  
- Reusable utilities  

Those belong in the shared core.

---

#### 16.10.3 Directory Integrity Rules

- No cross-imports across verticals.  
- No vertical may import another vertical’s files.  
- No shared-core file may import from `/verticals/*`.  
- No file in any vertical may define a model or migration.  
- Shared core must remain independent of verticals at all times.  

---

**Rule:**  
The directory tree defines the architecture. Violating the folder boundaries means violating the platform design.

### 16.11 AI Placement Rule

All AI logic — including extraction, classification, anomaly detection, normalization, and autopilot reasoning — must live strictly inside the **shared core**.  
Verticals may *use* AI, but must never *define* AI logic.

This guarantees:

- A single unified AI pipeline  
- Reusability across FuelFlow, CameronConnect, and all future verticals  
- Zero duplication  
- Consistent accuracy and improvement  
- Central observability and quality control  

---

#### 16.11.1 Where AI Logic Must Live

All AI and ML code belongs in:

- `/backend/src/core/ai/`  
- `/backend/src/core/classification/`  
- `/backend/src/core/extraction/`  
- `/backend/src/core/normalization/`  
- `/backend/src/core/anomalies/`  
- `/backend/src/core/autopilot/`  
- `/backend/src/core/documenthub/`  

These folders may contain:

- Model runners (LLM clients, OCR engines)  
- Prompt templates  
- Classification pipelines  
- Extraction rules  
- AI-based error detection  
- Normalization logic  
- Autopilot reasoning (WHEN + WHAT)  
- LearningEvents logic  
- Drift detection and schema intelligence  

---

#### 16.11.2 What Verticals May Not Do

Verticals **must NOT**:

- Define any prompt  
- Call external AI models directly  
- Run their own OCR, LLM, or extraction logic  
- Perform classification or normalization  
- Detect anomalies or schema drift  
- Evaluate autopilot policies  
- Define their own AI workflows  
- Store model weights or configs per vertical  

These are strictly core responsibilities.

---

#### 16.11.3 What Verticals *May* Do

Verticals are allowed to:

- **Call shared AI services**  
  (e.g. `aiService.extract()`, `normalizationService.run()`)
- **Define vertical workflows** that *use* shared AI output  
- **Configure** which AI policies apply to that vertical  
- **React to AI decisions** (e.g. “invoice missing date → show banner”)

**But they never implement the AI themselves.**

---

#### 16.11.4 Why This Rule Exists

Keeping all AI in the shared core ensures:

- One extraction engine works for all products  
- Improvements instantly help all verticals  
- No version mismatch  
- No duplicated prompt logic  
- No inconsistent normalization pipelines  
- Easier debugging and observability  
- One unified audit trail  
- One unified model policy system  
- Data consistency across the entire platform  
- Cleaner multi-tenancy  
- Faster onboarding of new verticals  

---

#### **Rule:**  
Shared core defines **how intelligence works** across the platform.  
Verticals may only consume AI results — never create them.

### 16.12 Multi-Tenant Data Integrity Rule

Every customer-specific record in the platform — across all verticals — must be permanently tied to a **tenant_id**.  
This ensures strict isolation, prevents data leakage, and preserves the integrity of shared AI, storage, and autopilot logic.

---

#### 16.12.1 Mandatory Tenant ID Requirement

All models representing customer-owned data **must include**:

- `tenant_id` (UUID)
- Index on `(tenant_id, created_at)`
- Per-tenant uniqueness constraints

Examples:

- Invoice  
- EFT  
- Tank Report  
- Document  
- ComplianceDocument  
- ExcelImport  
- RawArchiveRecord  
- AutopilotPolicy  
- AutopilotAction  
- LearningEvent  

**Rule:**  
If a model belongs to a customer, it must include `tenant_id`.  
If it does not belong to a customer (e.g., lookup tables), it must NOT include `tenant_id`.

---

#### 16.12.2 No Cross-Tenant Joins Allowed

The backend must never join data across different tenants.

Forbidden examples:

- Joining documents of tenant A with invoices of tenant B  
- Aggregating financial totals across all tenants  
- Fetching all files globally  

Allowed examples:

- Aggregations within a single tenant  
- Shared-core lookup tables (no tenant_id)  
- Shared AI models (not tenant-specific data)  

**Rule:**  
A tenant may only access its own data.

---

#### 16.12.3 API Enforcement

All APIs serving customer data must scope queries by:

- `where: { tenant_id: req.tenant_id }`  
- Or derive tenant context from the authenticated user  

Shared APIs must also enforce scoping:

- `/api/storage/*`  
- `/api/documents/*`  
- `/api/autopilot/*`  
- `/api/observability/*`  

Vertical APIs must enforce the same.

---

#### 16.12.4 Database Integrity Constraints

To protect correctness at the database level:

1. **Unique Constraints per Tenant**  
   Example:  
   `(tenant_id, invoice_number)` must be unique.  
   Not `invoice_number` globally.

2. **Partial Indexes for Soft Deletes**  
   Example:  
   `WHERE deleted_at IS NULL`

3. **Foreign Keys must include tenant scope**  
   Example:  
   An EFT referencing an Invoice must ensure both have **the same tenant_id**.

4. **No Global Uniqueness on Customer Fields**  
   Example:  
   Two different tenants may have:  
   - the same station names  
   - the same supplier names  
   - identical invoice numbers  

---

#### 16.12.5 Storage (GCS) Tenant Isolation

GCS paths must include tenant identifiers to avoid intermixing:

gs://bucket/raw/{tenantId}/{recordId}
gs://bucket/documents/{tenantId}/{documentId}
gs://bucket/imports/{tenantId}/{fileId}

**Rule:**  
Two tenants must never share a file path prefix.

---

#### 16.12.6 Autopilot & AI Tenant Boundaries

Autopilot, DocumentHub, extraction engines, and normalization pipelines must:

- read only the requesting tenant’s data  
- write only to the requesting tenant  
- produce LearningEvents scoped to one tenant  
- never aggregate across tenants  
- never train on raw tenant-specific data directly  

AI models may be global,  
but **AI outputs must remain tenant-scoped**.

---

#### 16.12.7 Observability & Drift Rules

DriftGuardian must:

- run per environment, not per tenant  
- only analyze schema drift, not customer data  
- ensure that migrations and schema changes apply identically to all tenants  

Customer usage telemetry must be tenant-isolated.

---

#### **Rule:**  
Tenant isolation is absolute.  
No cross-tenant joins, no cross-tenant file mixing, no shared customer data, ever.

### 16.13 Vertical Creation Guide

A vertical represents a business-specific module built on top of the shared platform core.  
Examples: FuelFlow, CameronConnect, future integrations.

A vertical must remain **thin**, **isolated**, and **dependent on the shared core**, never the other way around.

This guide defines the only correct way to create a new vertical.

---

#### 16.13.1 What a Vertical Is Allowed to Contain

A vertical folder may include:

- Vertical-specific routes (`/api/<vertical>/*`)
- Vertical controllers
- DTOs (request/response objects)
- Vertical configuration files
- Workflow orchestrators that **call** shared services
- Small utilities used only by that vertical
- UI triggers or vertical-specific dashboard logic (if applicable)

These files exist under:

/backend/src/verticals/<vertical-name>/

---

#### 16.13.2 What a Vertical May **Not** Contain

A vertical must never define:

- Database models  
- Migrations  
- Storage logic  
- GCS path builders  
- AI logic, prompts, or model runners  
- Classification or extraction logic  
- Normalization logic  
- Drift detection  
- Autopilot internals  
- Multi-tenant logic  
- RawArchive ingestion  
- DocumentHub processing logic  
- LearningEvent or AI pipelines  
- Cross-tenant or shared queries  
- Shared utility functions  

**Rule:**  
If the logic is reusable or core to the platform, it belongs in the shared core, not inside a vertical.

---

#### 16.13.3 Vertical Folder Structure

A recommended standard folder structure:

/backend/src/verticals/<vertical>/
controllers/
routes/
workflows/
dto/
config/
utils/ (vertical-only)

Controllers should be extremely thin.  
Workflows orchestrate vertical behaviors by calling:

- `documentService`
- `storageService`
- `normalizationService`
- `autopilotService`
- `tenantService`
- `aiService`
- `driftService`
- etc.

Vertical workflows **never** reinvent these capabilities.

---

#### 16.13.4 Creating a New Vertical

**Step 1 — Create folder**

/backend/src/verticals/<vertical>/

**Step 2 — Add route file**

Example:

/backend/src/verticals/<vertical>/routes/<vertical>.routes.js

Routes must use prefix:

/api/<vertical>/*

**Step 3 — Add controller file**

Controllers should only:

- validate input  
- extract parameters  
- call shared services  
- return results  

**Step 4 — Add optional workflow**

If needed, create:

/workflows/<feature>Workflow.js

Workflows coordinate calls to shared services.

**Step 5 — Register routes**

In:

/backend/src/routes/appRoutes.tsx

Add the new vertical routes under the vertical switch.

**Step 6 — Verify boundaries**

Before merging:

- no model imports  
- no migrations  
- no storage logic  
- no AI logic  
- no tenant logic  
- no database joins  
- no shared core “reach-in” hacks  

**Rule:**  
A vertical should feel like a *thin plugin* using the platform engine — never a min-platform itself.

---

#### 16.13.5 Adding Vertical-Specific Policies or Rules

A vertical may define configuration like:

- Which Autopilot policies apply  
- Which document types it supports  
- Which workflows it allows  
- Which fields are required for its business logic  

But it may not define:

- new DocumentHub logic  
- new Autopilot engines  
- new AI pipelines  
- new storage systems  
- new tenant flows  

Configurable = allowed.  
Core logic = forbidden.

---

#### 16.13.6 Vertical Independence & Future-Proofing

Verticals must not:

- import each other  
- depend on each other’s files  
- share utilities directly  

Only shared core can be a dependency.

This guarantees:

- easy addition of future verticals  
- consistent behaviors across the platform  
- testing separation  
- independent deployment  
- predictable performance  
- no domino failures  

---

#### **Rule:**  
The vertical exists to provide business-specific behavior **without ever modifying or duplicating** the platform engine.

### 16.14 File Storage & GCS Lifecycle Rule

All files entering the platform — including invoices, EFTs, tank reports, imports, compliance files, and email attachments — must follow a strict lifecycle.  
This ensures consistency across verticals, stable AI pipelines, and reliable observability.

The lifecycle has **five mandatory stages**.

---

#### 16.14.1 Stage 1 — Ingestion → RawArchiveRecord

All external files enter the platform as a **RawArchiveRecord**.

Sources may include:

- n8n email ingestion  
- Direct file upload (UI or API)  
- SFTP import  
- Mobile app upload  
- Integration partners (e.g., CameronConnect external providers)

RawArchiveRecord must include:

- `tenant_id`
- `source` (email, upload, system)
- `filename`
- `mimeType`
- `storageUri` (GCS path)
- `rawText` (optional raw OCR / email text)
- `status` (new, processed, failed)

**Rule:**  
Nothing bypasses RawArchiveRecord.  
Every file in the system originates here.

---

#### 16.14.2 Stage 2 — Storage Upload (GCS)

All raw files MUST be uploaded to GCS using the canonical path:

gs://<bucket>/raw/{tenantId}/{rawArchiveId}/{filename}

Requirements:

- No local disk storage  
- No writing directly from verticals  
- Only `storageService` handles uploads  
- Only GCS; never S3, local folder, tmp directory, or vertical-specific paths

**Rule:**  
Verticals must use `storageService.upload()`; never build paths manually.

---

#### 16.14.3 Stage 3 — AI Extraction → Document

Once RawArchiveRecord is stored, the DocumentHub pipeline converts it into a **Document**.

Document fields may include:

- extracted text  
- structured fields (invoice_number, date, amount, etc.)  
- confidence scores  
- extraction metadata  
- classification results  
- anomalies  
- normalization results  

Documents must follow the canonical GCS storage path:

gs://<bucket>/documents/{tenantId}/{documentId}.json

**Rule:**  
Documents are the normalized form of raw files.  
Only the shared AI pipeline may create or modify them.

---

#### 16.14.4 Stage 4 — Normalization Pipeline

After extraction, the Document is passed into the normalization pipeline:

- classification → extraction → regex fallback → null fill → LearningEvents  
- fields must include extraction source  
- uncertainties must be logged  
- AI and heuristic rules must be unified in the shared core  
- normalization is versioned and auditable  

Verticals may **use** normalized fields, but may not define normalization logic.

---

#### 16.14.5 Stage 5 — Final Storage & Indexing

After normalization:

- Document is saved to Postgres  
- GCS JSON is updated  
- indexes are maintained for fast queries  
- storageUri must be present  
- RawArchiveRecord is updated with processing results  

**Rule:**  
A file is not considered “complete” until both the Document model and the GCS JSON object are fully synchronized.

---

#### 16.14.6 No Bypassing the Lifecycle

Forbidden shortcuts:

- Direct creation of Document without RawArchiveRecord  
- Storing files outside of storageService  
- Placing files directly in `/documents` without DB entry  
- Running AI on UI-uploaded files without RawArchive path  
- Vertical-specific storage folders  
- Per-vertical extraction logic  

Every file must go through:

RawArchiveRecord → GCS Raw → AI/DocumentHub → Document → GCS Document JSON

No exceptions.

---

#### 16.14.7 Email Integration & n8n Compatibility

Email ingestion (via n8n or external pipelines) must:

1. Extract attachments  
2. Extract raw text  
3. POST to `/api/storage/raw-archive`  
4. Let the shared core handle the entire lifecycle  

n8n is only responsible for **transport**, not processing.

---

#### **Rule:**  
File ingestion, storage, extraction, normalization, and AI must follow one unified lifecycle across all verticals.  
This guarantees data integrity, AI accuracy, and future scalability.

### 16.15 DocumentHub Pipeline Rule

DocumentHub is the unified pipeline that transforms raw files into structured, normalized, and AI-enriched documents.  
All verticals must use DocumentHub exactly as defined here.  
No vertical may modify or replace any part of this pipeline.

The DocumentHub pipeline consists of **six mandatory stages**.

---

#### 16.15.1 Stage 1 — Start at RawArchiveRecord

All pipelines must begin with:

- A `RawArchiveRecord` entry  
- A GCS raw file  
- Associated metadata (filename, mimeType, source, tenant_id)

**Rule:**  
DocumentHub must never be invoked on a file that did not pass through RawArchive.

---

#### 16.15.2 Stage 2 — Classification

The first AI step identifies:

- document type (invoice, EFT, tank report, import, other)  
- vendor/supplier  
- relevant date ranges  
- extraction strategy  
- AI confidence levels  
- routing metadata  

Output includes:

- `classificationResult`
- `confidence`
- `classifierVersion`

**Rule:**  
Classification logic lives only in `/core/classification/`.  
Verticals cannot define their own classifiers.

---

#### 16.15.3 Stage 3 — Extraction

Extraction uses:

- AI models  
- OCR text  
- regex fallback patterns  
- domain-specific heuristics  
- supplier templates (if applicable)

Extracted fields include:

- invoice number  
- date  
- amount  
- items  
- gallons  
- pricing  
- station name  
- payment references  
- any vertical-specific business fields  

Every extraction must produce:

- `extractedFields`
- `extractionSource` (AI, OCR, regex, fallback)
- `confidenceScores`
- `extractionVersion`

**Rule:**  
Extraction logic must never exist inside a vertical folder.

---

#### 16.15.4 Stage 4 — Normalization

Normalization converts extracted raw fields into a clean, structured, platform-standard format.

Normalization includes:

- field coercion (dates, numbers, decimals)  
- standardization of invoice numbers  
- unit conversion (e.g., gallons → liters if needed)  
- null-filling rules  
- domain constraints  
- cross-field validation  
- error marking  
- supplier-specific edge cases  
- mapping to canonical enums  
- tenant-specific business rules (if defined by configuration)

Output includes:

- `normalizedFields`
- `normalizationVersion`
- `sourceMap` (where each field came from)

**Rule:**  
All normalization must be implemented in `/core/normalization/`.

---

#### 16.15.5 Stage 5 — LearningEvents

DocumentHub generates `LearningEvents` to improve future AI performance.

LearningEvents record:

- extraction errors  
- low-confidence extractions  
- normalization fallbacks  
- user corrections  
- field mismatches  
- anomalies  
- exceptions or unexpected patterns  

Each event includes:

- `tenant_id`  
- `rawArchiveId`  
- `documentId`  
- `field`  
- `expected` vs `actual`  
- `confidence`  
- `source`  
- `version`  

**Rule:**  
LearningEvents are the feedback engine for all future improvements.  
Verticals may **never** generate their own LearningEvents.

---

#### 16.15.6 Stage 6 — Document Creation & Storage

The final stage transforms all pipeline output into a saved **Document**.

Every Document must have:

- tenant_id  
- rawArchiveId  
- classification block  
- extraction block  
- normalization block  
- anomalies  
- source maps  
- AI versions  
- timestamps  
- full audit trail  

Storage must update:

1. Postgres record for Document  
2. GCS JSON at:

gs://bucket/documents/{tenantId}/{documentId}.json

**Rule:**  
A document is not considered “complete” until both DB and GCS representations match.

---

### 16.15.7 No Custom Pipelines in Verticals

Verticals may **use** DocumentHub but must never:

- define new extraction logic  
- override classification rules  
- redefine normalization  
- bypass LearningEvents  
- create their own pipeline stages  
- manipulate AI results directly  

**Rule:**  
DocumentHub is a single global intelligence pipeline shared across all verticals.

---

### 16.15.8 End-to-End Lifecycle Summary

RawArchiveRecord
→ Classification
→ Extraction
→ Normalization
→ LearningEvents
→ Document (DB + GCS)

This lifecycle is enforced for every vertical and every document type.

---

#### **Rule:**  
DocumentHub defines how intelligence flows through the system.  
Verticals only consume the results — never create or modify the pipeline.

### 16.16 Autopilot Deep Architecture (WHEN + WHAT + HOW)

Autopilot is the platform-wide automation engine that performs actions based on policies.  
It must behave consistently across all verticals and must remain fully tenant-safe.

Autopilot has three layers:

1. **WHEN** — triggers and conditions  
2. **WHAT** — the requested automation or outcome  
3. **HOW**  — the execution logic, performed by AutopilotAction  

All logic lives strictly in shared core.

---

#### 16.16.1 AutopilotPolicy — WHEN + WHAT

An AutopilotPolicy defines *when* the system should evaluate a rule and *what* outcome is desired.

A policy includes:

- `tenant_id`
- `triggerType` (cron, event, schedule, ingestion, anomaly, documentReady, etc.)  
- `conditions` (filters, thresholds, business constraints)  
- `actionType` (what kind of action should be executed)
- `config` (optional rule configuration)
- `enabled` flag  
- version fields  

Policies are:

- evaluated by the shared AutopilotEngine  
- reusable across all verticals  
- tenant-scoped  
- declarative, not procedural  

**Rule:**  
Policies define *intent*, never execution logic.

---

#### 16.16.2 AutopilotAction — HOW

An AutopilotAction defines *how* Autopilot executes a requested automation.

An action includes:

- `tenant_id`
- `policyId`
- `status` (pending, running, success, failed, cancelled, retrying)
- execution payload
- timestamps  

Execution rules:

- Actions run in queues  
- They support retries  
- They are idempotent  
- They must never perform cross-tenant actions  
- They must call shared services only  

**Rule:**  
Action handlers contain execution logic; policies do not.

---

#### 16.16.3 AutopilotEngine — The Core Brain

The AutopilotEngine is responsible for:

- evaluating policies on schedule  
- evaluating policies on events  
- generating actions  
- executing them through handlers  
- recording failures  
- retrying failed actions  
- enforcing tenant boundaries  
- preventing conflicts  
- logging execution history  
- producing LearningEvents when relevant  

AutopilotEngine lives in:

/backend/src/core/autopilot/

Verticals may ONLY:

- configure which policies apply to them  
- inspect results  
- request manual approval flows (if needed)

They may NOT define:

- new engine logic  
- new handlers  
- new evaluators  
- new scheduling rules  
- custom execution pipelines  

---

#### 16.16.4 Autopilot Trigger Types

Supported triggers include:

- `cron`  
- `documentCreated`  
- `EFTProcessed`  
- `invoiceReady`  
- `tankReportReady`  
- `anomalyDetected`  
- `driftDetected`  
- `importCompleted`  
- `policyUpdated`  

Verticals may *use* these triggers but may not create new trigger types.

New triggers must be added only to shared core.

---

#### 16.16.5 Autopilot Conditions (Filters)

A policy may define:

- field thresholds (e.g., gallons > X)  
- missing fields (e.g., invoice date missing)  
- anomaly presence  
- document confidence score < Y  
- station filters  
- supplier filters  
- time ranges  
- tenant-specific configurations  

Conditions must be:

- declarative  
- pluggable  
- reusable across tenants and verticals  

**Rule:**  
Conditions are evaluated only by the AutopilotEngine.

---

#### 16.16.6 Autopilot Action Handlers

Examples of actions:

- send alert  
- request human review  
- reconcile document with EFT  
- flag anomaly  
- enrich document  
- update invoice fields  
- upload corrected file  
- trigger normalization refresh  
- generate audit entry  

Handlers must be written in:

/backend/src/core/autopilot/actions/<handler>.js

Each handler:

- is idempotent  
- is tenant-safe  
- may call shared services  
- must log failures  
- should record LearningEvents when appropriate  

Verticals cannot define their own handlers.

---

#### 16.16.7 Autopilot Safety Rules

To prevent accidents:

- No destructive actions are allowed by default  
- Every destructive action requires explicit manual approval flow  
- All autopilot events must be auditable  
- Autopilot must respect tenant boundaries  
- Autopilot must log every execution  
- Autopilot must support soft-fail + retry  
- Autopilot must never block ingestion or DocumentHub  
- Autopilot must remain non-blocking and asynchronous  

---

#### 16.16.8 Autopilot Versioning

Every policy and action stores:

- engine version  
- policy version  
- handler version  

This ensures:

- safe migrations  
- safe rollbacks  
- reproducible behavior  
- testability  

---

#### **Rule:**  
Autopilot defines **automation intent** (WHEN + WHAT) in policies,  
and **execution behavior** (HOW) in actions.  
Verticals may configure Autopilot but may never implement Autopilot logic.

### 16.17 Chaos Engineering & Failure Simulation

Chaos engineering allows controlled simulation of failure conditions in non-production
environments (staging, dev) to ensure the platform behaves predictably under stress.

Chaos features must never be enabled in production without explicit code changes.

---

#### 16.17.1 Purpose

Chaos mode exists to validate:

- Autopilot resiliency
- DocumentHub robustness during extraction/normalization
- GCS storage error recovery
- API failover handling
- DriftGuardian behavior during schema drift or outage
- Queue pressure and retry logic
- Tenant isolation under stress
- End-to-end ingestion lifecycle durability

Chaos mode is strictly optional, tenant-safe, and environment-guarded.

---

#### 16.17.2 Chaos Config (CHAOS_CONFIG)

All chaos settings are centralized in:

/backend/src/core/config/chaosConfig.js

The config defines:

- `enabled` — global toggle  
- `gcsFailureRate` — probability (0.0–1.0) of GCS calls failing  
- `apiFailureRate` — probability (0.0–1.0) of API endpoints failing  
- `latencyMs` — artificial delay added to targeted requests  
- `targetEnvironments` — comma-separated environment allowlist  
- `seed` — deterministic random for reproducible chaos  

Chaos must activate only if:

1. `CHAOS_ENABLED=true`  
2. current environment is included in `CHAOS_TARGET_ENVIRONMENTS`

**Rule:** Production must never be included in target environments.

---

#### 16.17.3 Chaos Middleware (API Layer)

Chaos middleware may:

- inject latency  
- randomly fail requests  
- simulate 500s, 504s, timeouts  
- simulate network flakes  
- produce structured chaos logs  

Chaos middleware lives in:

/backend/src/core/middleware/chaosMiddleware.js

**Rule:**  
Chaos middleware may never alter business logic or validation;  
it only wraps the handler and manipulates latency or failure.

---

#### 16.17.4 GCS Chaos Injection

Storage operations may simulate:

- upload failures  
- download failures  
- missing files  
- transient 503 errors  
- corrupted GCS responses  

Injection happens only through:

/backend/src/core/storage/gcsClient.js

Never directly inside vertical code.

**Rule:**  
Chaos injections must always:

- respect tenant isolation  
- log the chaos event  
- preserve original request metadata  
- fall back to retry logic where configured

---

#### 16.17.5 Latency Simulator

A shared utility to simulate variable latency:

latencyHelper.simulate(minMs, maxMs)

Used for:

- Autopilot evaluations  
- DriftGuardian schema scans  
- DocumentHub extraction pipelines  
- Queue workers under load  

Latency must be:

- reproducible when `seed` is used  
- easily disabled  
- fully logged  

---

#### 16.17.6 Chaos Control Admin Endpoints

Admin endpoints expose chaos state via:

GET /api/admin/chaos/state
POST /api/admin/chaos/toggle
POST /api/admin/chaos/config

Admin endpoints are:

- protected  
- tenant-agnostic  
- staging-only  
- auditable  

Verticals may not create or modify chaos endpoints.

---

#### 16.17.7 Frontend Staging Chaos Console

A small UI accessible only in staging:

- toggles chaos mode  
- shows chaos logs  
- lets QA simulate outages  
- provides live sliders for latency ranges  
- shows failure probabilities in real time  

Lives in:

frontend/src/app/pages/AdminChaosPage.tsx

**Rule:** Chaos UI may never show in production builds.

---

#### 16.17.8 Load-Test Script

A Node-based stress test tool for:

- API concurrency  
- document ingestion speed  
- GCS upload/download pressure  
- Autopilot action queues  
- DriftGuardian scans under load  

The script simulates:

- 100–10,000 parallel requests  
- Chaos injections  
- Predictable seeded randomness  

Tool lives in:

scripts/loadtest/runChaosLoadTest.js

---

#### 16.17.9 Chaos Playbook Documentation

A playbook describing:

- how to enable/disable chaos  
- recommended test scenarios (GCS outage, API flakiness, latency spike)  
- expected platform behaviors  
- recovery flows  
- manual cleanup steps  
- how to interpret chaos logs  
- safe rollback procedures  

---

#### 16.17.10 N8N Chaos Workflow Docs

n8n workflows must remain transport-only.  
Chaos may be applied to:

- inbound email attachments  
- webhook ingestion  
- GCS writing via API  
- delayed webhook sending  

But n8n must never:

- simulate extraction errors  
- modify DocumentHub logic  
- alter Autopilot behavior  

**Rule:** n8n chaos = network + timing only.

---

#### **Rule:**  
Chaos may only simulate failures around the platform —  
never inside core logic.

Chaos tests the resilience of the system;  
it must never rewrite it.

### 16.18 Observability & DriftGuardian Doctrine

Observability and DriftGuardian ensure the platform behaves as designed over time.  
They detect **drift** between:

- expected vs actual DB schema  
- expected vs actual environment config  
- expected vs actual storage layout  
- expected vs actual metrics behavior  

DriftGuardian is **read-only** and must never change data or schema.

---

#### 16.18.1 Goals

- Detect breaking changes before production impact  
- Catch schema drift between environments  
- Catch env config drift (`.env` vs `.env.staging.example` etc.)  
- Detect storage mismatches (legacy vs modern URIs, missing files)  
- Surface errors, slow endpoints, and queue issues  
- Feed LearningEvents / Autopilot with safe signals  

Observability is for **insight**, not for mutation.

---

#### 16.18.2 Observability Module

Core files:

- `/backend/src/observability/logger.js`  
- `/backend/src/observability/metrics.js`  
- `/backend/src/observability/errorTracker.js`  
- `/backend/src/observability/index.js`  

Responsibilities:

- Structured logging (JSON where possible)  
- Request/response logging (redacting secrets)  
- Metrics (counters, gauges, histograms)  
- Error capture + tagging (tenant_id, route, env, vertical, correlationId)  

**Rule:**  
All new backend modules must use the shared observability helpers, not custom loggers.

---

#### 16.18.3 Admin Observability Routes

Admin-only routes expose system health:

- `GET /api/admin/metrics` — aggregated metrics snapshot  
- `GET /api/admin/errors` — recent error summaries  
- `GET /api/admin/drift-check` — runs DriftGuardian checks  
- `GET /api/admin/storage/drift-report` — storage-specific drift report (Phase 18.4)  

Properties:

- Auth-protected  
- Environment-aware (staging vs production)  
- Tenant-agnostic (no customer data in responses)  
- Safe to call repeatedly  

---

#### 16.18.4 DriftGuardian – DB Schema Drift

DB drift detection compares:

- **Expected schema** from migrations / Sequelize models  
- **Live schema** from the database

Checks include:

- Missing tables / extra tables  
- Missing columns / extra columns  
- Wrong data types or nullability  
- Missing indexes (especially on `tenant_id`, `created_at`, soft-delete filters)  
- Constraint mismatches  

Output:

- JSON report with `status`, `differences[]`, `severity`  
- Metrics emitted via `/api/admin/metrics`  
- Optional LearningEvents creation for severe drift  

**Rule:**  
DB drift checks must be **read-only** and must not auto-migrate.

---

#### 16.18.5 DriftGuardian – Env Config Drift

Env drift scripts (e.g. `scripts/diagnostics/check-env-drift.sh`) compare:

- `.env.production.example`  
- `.env.staging.example`  
- actual `.env` used by the process  

Checks include:

- missing keys  
- keys with different names but same intent  
- obviously invalid values (e.g. wrong boolean/number formats)  

Output:

- CLI report (for CI)  
- JSON where possible  
- Non-zero exit code if critical keys are missing  

**Rule:**  
No deployment to staging/production should pass if critical env drift is detected.

---

#### 16.18.6 DriftGuardian – Storage Drift (Legacy vs Modern)

Storage drift checks ensure:

- records that should have `storageUri` actually have it  
- GCS objects exist for all expected URIs  
- legacy file fields (e.g. old path columns) match modern storage mapping  
- no object is referenced by multiple tenants  

The storage drift report must include:

- count of legacy records  
- count of fully migrated records  
- count of records missing URIs  
- sample IDs for inspection  

**Rule:**  
Storage drift reports are diagnostic only;  
actual migrations must go through the storage migration engine.

---

#### 16.18.7 Metrics & Alerts

Metrics must cover:

- request rate / latency / error rate per route  
- GCS call success/failure rates  
- Autopilot evaluations vs actions created vs actions failed  
- DocumentHub throughput (per minute/hour)  
- queue lengths and processing latency  
- n8n ingestion latency (if integrated via metrics)  

Alerts may be wired to:

- Slack  
- Email  
- n8n workflows  

Alerts should fire on:

- sustained error spikes  
- abnormal latency  
- repeated drift detection failures  
- storage drift above threshold  

---

#### 16.18.8 Staging-First Observability

Staging is the main playground for:

- new metrics  
- new drift checks  
- new chaos scenarios  

Rules:

- New observability features must be validated in staging first.  
- DriftGuardian must run on staging regularly (e.g. hourly/daily).  
- Production drift checks must be more conservative and primarily read-only.

---

#### 16.18.9 Integration with LearningEvents & Autopilot

When appropriate, DriftGuardian and observability may create LearningEvents to record:

- repeated failure patterns  
- chronic latency issues  
- recurring drift on specific models  
- misconfigured tenants  

Autopilot policies may react to:

- persistent drift warnings  
- recurring failures for a tenant  
- sustained queue congestion  

But:

**Rule:**  
DriftGuardian itself never executes destructive Autopilot actions.  
It only reports, logs, and optionally opens actions that require explicit approval.

---

#### **Rule:**  
Observability and DriftGuardian must always be **read-only, tenant-safe, and environment-aware**.  
They shine a light on problems; they never silently “fix” them.
