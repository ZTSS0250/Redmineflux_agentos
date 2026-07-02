# UI Wireframes (ASCII) — redmineflux_agentos

Text wireframes for Phase 1 sign-off. Visual design/CSS is a Phase 4+ concern; these establish layout and information hierarchy only.

---

## 1. AI Chat / New AI Project Wizard

```
┌─────────────────────────────────────────────────────────────────┐
│ AgentOS  ›  New AI Project                                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌─ Requirement Analyst Agent ───────────────────────────────┐  │
│  │ Tell me about the software you want to build.              │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ┌─ You ─────────────────────────────────────────────────────┐  │
│  │ Build an Employee Management System with Leave,            │  │
│  │ Attendance, Payroll, Notifications and Reports.             │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ┌─ Requirement Analyst Agent ───────────────────────────────┐  │
│  │ A few things I need before I can plan this properly:        │  │
│  │  1. Who are the primary users? (HR admins, employees, both) │  │
│  │  2. Do you need role-based access (Admin/Manager/Employee)? │  │
│  │  3. Any existing payroll/accounting system to integrate?    │  │
│  │  4. Mobile app needed, or web-only for v1?                  │  │
│  │  5. Any compliance requirements (statutory leave rules)?    │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ Type your answer...                             [ Send ]   │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                   │
│  Progress: [███████░░░░░░░░░░░] Requirement confidence: 42%     │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. Requirement Review (SRS approval)

```
┌─────────────────────────────────────────────────────────────────┐
│ AgentOS  ›  Requirement Review                v2   [Draft]       │
├─────────────────────────────────────────────────────────────────┤
│ Software Requirement Specification                               │
│ ───────────────────────────────                                  │
│ 1. Overview .......................................              │
│ 2. Users & Roles ...................................              │
│ 3. Modules (Leave, Attendance, Payroll, Notifications, Reports)  │
│ 4. Non-Functional Requirements .....................              │
│ 5. Integrations .....................................             │
│ 6. Assumptions & Open Risks .........................             │
│                                                                   │
│ [ Edit inline ]                    [ Ask another question ]     │
│                                                                   │
├─────────────────────────────────────────────────────────────────┤
│              [ Request Changes ]        [ Approve & Create Plan ]│
└─────────────────────────────────────────────────────────────────┘
```

---

## 3. Agent Dashboard

```
┌─────────────────────────────────────────────────────────────────┐
│ AgentOS  ›  Agent Dashboard              Project: EMS             │
├─────────────────────────────────────────────────────────────────┤
│ Agent               Status         Current Ticket   Last Update  │
│ ───────────────────────────────────────────────────────────────  │
│ Project Manager     ● running      —                 2m ago      │
│ Requirement Analyst ○ completed    —                 1h ago      │
│ Database Agent      ● running      EMS-014            30s ago     │
│ Backend Agent       ◐ waiting_dep  EMS-018 (needs 014) 30s ago    │
│ API Agent           ○ queued       EMS-022            —          │
│ QA Agent            ○ queued       —                  —          │
│ Security Agent      ✖ dead         EMS-019 [Retry] [View log]    │
│ ...                                                                │
├─────────────────────────────────────────────────────────────────┤
│ Pending Approvals (2)                                             │
│  • bulk_close_issues on 14 tickets — requested by Deployment Agent│
│    [ Approve ]  [ Reject ]                                        │
│  • delete_issue EMS-007 (duplicate) — requested by PM Agent       │
│    [ Approve ]  [ Reject ]                                        │
└─────────────────────────────────────────────────────────────────┘
```

---

## 4. Dependency Dashboard

```
┌─────────────────────────────────────────────────────────────────┐
│ AgentOS  ›  Dependency Dashboard          Project: EMS             │
├─────────────────────────────────────────────────────────────────┤
│  [DB: EMS-014] ──► [Backend: EMS-018] ──► [API: EMS-022]          │
│      done              in progress            blocked             │
│                                                    │                │
│                                                    ▼                │
│                                          [Frontend: EMS-031]        │
│                                               blocked               │
│                                                                     │
│  Legend:  ✅ done   🔵 in progress   ⛔ blocked   ⚪ not started    │
└─────────────────────────────────────────────────────────────────┘
```

---

## 5. Release Planner

```
┌─────────────────────────────────────────────────────────────────┐
│ AgentOS  ›  Release Planner               Project: EMS             │
├─────────────────────────────────────────────────────────────────┤
│ Release: v1.0 — Core HR Foundation           Status: In Progress  │
│  ├─ Sprint 1 (Jul 7 - Jul 18): DB + Backend schema       ✅ 8/8   │
│  ├─ Sprint 2 (Jul 21 - Aug 1): API + Auth                🔵 5/9   │
│  └─ Sprint 3 (Aug 4 - Aug 15): Leave + Attendance UI     ⚪ 0/12  │
│                                                                     │
│ Release: v1.1 — Payroll & Reports            Status: Planned      │
│  └─ Sprint 4-6 ...                                                 │
│                                                                     │
│                                          [ + Add Release ]         │
└─────────────────────────────────────────────────────────────────┘
```

---

## 6. Token Usage / Cost Dashboard

```
┌─────────────────────────────────────────────────────────────────┐
│ AgentOS  ›  Token Usage & Cost              Project: EMS            │
├─────────────────────────────────────────────────────────────────┤
│ This month:  1.82M tokens   ·   $14.62 estimated cost             │
│                                                                     │
│ By agent                          By day                          │
│ Requirement Analyst  ▓▓▓▓▓▓ 420K   ▂▃▅▇▆▄▃▂▁▂▃▅▇█▆▄▃▂             │
│ Database Agent       ▓▓▓ 210K                                     │
│ Backend Agent        ▓▓▓▓ 280K                                    │
│ QA Agent             ▓▓ 140K                                      │
│ ...                                                                │
│                                                                     │
│ Budget alert: none configured   [ Set monthly budget ]            │
└─────────────────────────────────────────────────────────────────┘
```

---

## 7. Execution History / Logs

```
┌─────────────────────────────────────────────────────────────────┐
│ AgentOS  ›  Execution History              Project: EMS             │
├─────────────────────────────────────────────────────────────────┤
│ Time       Agent            Event                        Ticket   │
│ 14:02:11   Database Agent   MCP: create_issue → EMS-014  EMS-014  │
│ 14:02:14   Database Agent   status: queued → running     EMS-014  │
│ 14:05:40   Database Agent   status: running → completed  EMS-014  │
│ 14:05:41   Dependency Eng.  cleared blocker for EMS-018   EMS-018  │
│ 14:05:42   Backend Agent    status: waiting_dep → queued  EMS-018 │
│ 14:11:03   Security Agent   MCP call failed (retry 1/3)   EMS-019 │
│ ...                                                                │
│                                          [ Filter ▾ ] [ Export ]  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Design principles applied across all screens

- Every screen that shows agent/ticket state is a **read-model view** backed by the Dashboard module (§2.2 of the spec) — never a live query against the LLM.
- Any action that would trigger a `requires_confirmation` MCP tool surfaces in the same "Pending Approvals" pattern shown in the Agent Dashboard, wherever it originates.
- All screens respect the permission table in the spec — e.g. Token Usage is hidden entirely for a user without `view_token_usage`, not just visually disabled.
