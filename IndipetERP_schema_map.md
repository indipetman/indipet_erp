# Indipet ERP Schema Map

Canonical source: project memory for `IndipetERP_devTeam`, the latest `Indipet ERP` chat through 2026-05-10, and HRMS phase schema files shared in May 2026.

This map intentionally shows current/locked schema and active design decisions. Older drafts and stale alternatives are not included unless they explain a current deferred item.

## Status Legend

| Status | Meaning |
|---|---|
| LOCKED | Built/accepted schema or module decision |
| IN_PROGRESS | Active design/build area, not yet fully locked |
| PENDING | Required next work, not yet built/seeded |
| DEFERRED | Explicitly postponed until a later phase or data maturity trigger |

## Overall ERP Module Map

```mermaid
flowchart LR
    CORE["Master Data / Registry<br/>62 tables / 11 groups<br/>LOCKED BASELINE"]
    CUSTOMER["Customer Master v2.0<br/>3 tables<br/>LOCKED"]
    PET["Pet Master v1.0<br/>1 table + views/triggers<br/>LOCKED"]
    LOYALTY["Loyalty Module<br/>6 tables<br/>LOCKED"]
    HRMS["HRMS<br/>37 tables + views<br/>LOCKED"]
    PERM["Permission System v1.0<br/>5 tables + views<br/>LOCKED"]
    VENDOR["Vendor Module<br/>3 tables<br/>LOCKED"]
    PROC["Procurement Orchestration P1<br/>centralized PR flow<br/>LOCKED"]
    ITEM["Inventory / Item Master<br/>parent + variants<br/>IN_PROGRESS"]
    CRM["CRM Remaining Tables<br/>tags + consumption rates<br/>PENDING"]
    ORDER["Order / Delivery<br/>feeds KPIs + procurement demand<br/>PENDING"]
    SERVICE["Service Operations<br/>booking + service delivery<br/>PENDING"]
    FIN["Finance / Settlement<br/>CoA + inter-entity flows<br/>PENDING"]

    CORE --> CUSTOMER
    CORE --> PET
    CORE --> LOYALTY
    CORE --> HRMS
    CORE --> PERM
    CORE --> VENDOR
    CORE --> ITEM
    CUSTOMER --> PET
    CUSTOMER --> LOYALTY
    CUSTOMER --> CRM
    PET --> CRM
    ITEM --> VENDOR
    ITEM --> PROC
    ITEM --> CRM
    ITEM --> ORDER
    ITEM --> SERVICE
    VENDOR --> PROC
    PROC --> FIN
    LOYALTY --> FIN
    HRMS --> FIN
    PERM --> HRMS
    ITEM --> HRMS
    ORDER --> HRMS
    SERVICE --> HRMS
    PERM --> CUSTOMER
    PERM --> VENDOR
    PERM --> PROC
    PERM --> LOYALTY
```

## Cross-System Rules

| Area | Canonical decision |
|---|---|
| Entity terminology | `parent_entity`, not `entity_master`; `sub_location`, not `outlet_master` |
| Entity classification | `parent_entity.entity_type` stores legal constitution; pending `parent_entity.entity_role` must store business role: `hq`, `company_owned`, or `franchisee` |
| Master identifiers | Each master layer should keep one readable alphanumeric text primary identifier, such as `IPL101` or `IPL101-SLT201`; duplicate editable code/short-code fields should be removed or generated-only unless finance/integration explicitly needs them |
| Week off selection | UI should expose `location_operating_hours.day_of_week` as `Week Off Day` with an ISO weekday dropdown: `1 Monday` through `7 Sunday`; `No Weekly Off` should store no closed-day row / no week-off value |
| Location operating hours | Base hours stay at location level: office official/operational hours can match, stores can have broader operational hours; `shift_policy_id` is deferred until shift policy setup is finalized |
| Holiday calendar | `holiday_calendar` stores uniform state/company holidays by `state_code`; Kolkata FY 2026-2027 case master uses a compact 13-holiday list with `state_code = WB`, blank `location_id`, `is_closed = true` only for Durga Puja and Doljatra, and `co_eligible = true` for all listed holidays |
| Leave type master | `leave_type_master` stores stable leave categories; FY 2026-2027 case master seeds CL, SL, EL, CO, LOP, ML, and PTL before leave policy setup |
| Leave policy master | `leave_policy_master` stores the FY policy wrapper; FY 2026-2027 case master uses HR/Admin approval, `holiday_calendar`, simultaneous leave blocking, `co_credit_trigger = Attendance`, CO auto-credit, 90-day CO expiry, and 4-hour CO minimum |
| Policy variant | `policy_variant` stores group-wise entitlement JSON under the FY leave policy; case master seeds HQ standard, store standard, probation, and contractor no-paid-leave variants |
| Policy assignment | `policy_assignment` maps variants to supported groups; case master assigns HQ by location, stores by location, contractual vet policy by Veterinary Doctor designation, and adds a probation employee-level placeholder until Employee Master exists |
| Location service config | Current table is `location_service_config(config_id, location_id, service_code, is_active, activated_by)`; `service_code` references `service_type_master.service_code`; HQ is office-only unless explicitly configured |
| Customer identity | Phone is the global unique customer identifier |
| Customer code | System code remains `CUST-NNNNN`; location-style display code such as `DP000155` is derived |
| Pet code | System code remains `PET-NNNNN`; display code such as `DP000155_001` is derived |
| Audit fields | `created_by INTEGER NOT NULL DEFAULT 0`, `created_at NOT NULL DEFAULT CURRENT_TIMESTAMP`, nullable `modified_by`, `modified_at` |
| FK style | Inline `REFERENCES`; avoid named `CONSTRAINT` blocks unless needed for checks/uniques |
| Code generation | `XX-NNNNN` style via database trigger unless a module has a newer locked rule |
| Loyalty eligibility | B2B customers are structurally excluded by `fn_check_loyalty_eligibility` |
| Workflow discipline | Conflict check first, raise issue, propose solve, confirm before implementation |

## Customer, Pet, and CRM Layer

```mermaid
erDiagram
    acquisition_source_master ||--o{ customer_master : "source_id"
    customer_master ||--o{ customer_delivery_address : "customer_id"
    customer_master ||--o{ pet_master : "customer_id"
    customer_master ||--o{ loyalty_point_lots : "customer_id"
    customer_master ||--o{ loyalty_redemption_log : "customer_id"
    pet_master ||--o{ consumption_rate_master : "pet/product demand"
    customer_tag_master ||..o{ customer_master : "future tag source"
    item_master ||..o{ consumption_rate_master : "item_id"

    acquisition_source_master {
        int source_id PK
        string source_name
        boolean is_active
        string status "LOCKED"
    }

    customer_master {
        int customer_id PK
        string customer_code "CUST-NNNNN"
        string phone "global unique"
        string customer_type
        boolean is_b2b "generated"
        string gst_state_code "auto from GSTIN"
        text_array customer_tags "GIN array"
        int active_pet_count "trigger synced"
        string status "LOCKED"
    }

    customer_delivery_address {
        int address_id PK
        int customer_id FK
        boolean is_default
        string status "LOCKED"
    }

    pet_master {
        int pet_id PK
        string pet_code "PET-NNNNN"
        int customer_id FK
        date date_of_birth
        boolean dob_is_approximate
        numeric body_weight
        string size_category "derived for dogs"
        string temperament
        string pet_status
        string status "LOCKED"
    }

    customer_tag_master {
        int tag_id PK
        string tag_name
        string status "PENDING"
    }

    consumption_rate_master {
        int consumption_rate_id PK
        int item_id FK
        string pet_or_customer_segment
        string status "PENDING"
    }
```

### Customer/Pet Notes

- `acquisition_source_master`, `customer_master`, and `customer_delivery_address` are locked as Customer Master v2.0.
- `customer_master.phone` is the global unique identifier; POS can capture only name + phone first and enrich later.
- `pet_master.customer_id` uses `ON DELETE RESTRICT`; age is always derived from `date_of_birth`, never stored.
- `active_pet_count` is synchronized back to `customer_master` by trigger.
- CRM pending work: `customer_tag_master`, `consumption_rate_master`, and CRM permission seeds.

## Loyalty Layer

```mermaid
erDiagram
    loyalty_programme_master ||--o{ entity_loyalty_profile : "programme_id"
    entity_loyalty_profile ||--o{ loyalty_point_lots : "entity loyalty config"
    customer_master ||--o{ loyalty_point_lots : "customer_id"
    customer_master ||--o{ loyalty_redemption_log : "customer_id"
    loyalty_redemption_log ||--o{ loyalty_redemption_detail : "redemption_id"
    loyalty_point_lots ||--o{ loyalty_redemption_detail : "lot_id FIFO"
    loyalty_settlement_batch ||--o{ loyalty_redemption_log : "monthly settlement"

    loyalty_programme_master {
        uuid programme_id PK
        string programme_name
        boolean is_active
        string status "LOCKED"
    }

    entity_loyalty_profile {
        uuid entity_loyalty_profile_id PK
        uuid programme_id FK
        int parent_entity_id FK
        string status "LOCKED"
    }

    loyalty_point_lots {
        uuid lot_id PK
        int customer_id FK
        numeric points_remaining
        date expiry_date
        string fifo_status
        string status "LOCKED"
    }

    loyalty_redemption_log {
        uuid redemption_id PK
        int customer_id FK
        numeric points_redeemed
        uuid settlement_batch_id FK
        string status "LOCKED"
    }

    loyalty_redemption_detail {
        uuid redemption_detail_id PK
        uuid redemption_id FK
        uuid lot_id FK
        numeric points_from_lot
        string status "LOCKED"
    }

    loyalty_settlement_batch {
        uuid settlement_batch_id PK
        string settlement_month
        numeric settlement_amount
        string status "LOCKED"
    }
```

### Loyalty Notes

- Loyalty replaced the earlier `customer_points_ledger` idea.
- FIFO lots are the accounting and redemption source of truth.
- B2B customers are blocked by `fn_check_loyalty_eligibility`.
- Monthly inter-entity settlement runs through IPL Loyalty Clearing.
- CoA references noted in design: 6400, 2300, 7600, 7700, 7800.

## HRMS Layer

```mermaid
erDiagram
    state_master ||--o{ sub_location : "state_code"
    parent_entity ||--o{ sub_location : "parent_entity_id"
    parent_entity ||--o{ employee_master : "payroll routing"
    sub_location ||--o{ employee_master : "location_id"
    department_master ||--o{ designation_master : "department_id"
    department_master ||--o{ employee_master : "department_id"
    designation_master ||--o{ employee_master : "designation_id"
    role_master ||--o{ employee_master : "role_id"
    employee_master ||--o{ employee_master : "reporting_manager_id"
    employee_master ||--|| employee_finance : "employee_id"
    employee_category_master ||--o{ minimum_wage_master : "category_code"
    salary_structure_master ||--o{ employee_salary : "grade_code"
    employee_master ||--o{ employee_salary : "employee_id"
    employee_master ||--o{ gratuity_ledger : "employee_id"
    employee_master ||--o{ employee_advances : "employee_id"
    leave_policy_master ||--o{ policy_variant : "policy_id"
    leave_policy_master ||--o{ policy_assignment : "policy_id"
    policy_variant ||--o{ policy_assignment : "variant_id"
    leave_type_master ||--o{ attendance : "leave_type_id"
    shift_policy_master ||--o{ employee_shift_preference : "policy_id"
    employee_master ||--o{ employee_shift_preference : "employee_id"
    employee_master ||--o{ employee_skills : "employee_id"
    department_master ||--o{ employee_skills : "department_id"
    sub_location ||--o{ shift_policy_master : "location_id"
    sub_location ||--o{ roster : "location_id"
    shift_policy_master ||--o{ roster : "policy_id"
    roster ||--o{ roster_slots : "roster_id"
    roster ||--o{ roster_history : "roster_id"
    roster ||--o{ attendance : "roster_id"
    roster_slots ||--o{ attendance : "roster_slot_id"
    employee_master ||--o{ attendance : "employee_id"
    attendance ||--o{ attendance_computation : "attendance_id"
    attendance_computation ||--o{ attendance_decision : "computation_id"
    attendance ||--o{ attendance_decision : "attendance_id"
    attendance ||--o{ co_ledger : "source_attendance_id"
    employee_master ||--o{ co_ledger : "employee_id"
    employee_master ||--o{ sales_target_portfolio : "employee_id"
    sub_location ||--o{ sales_target_portfolio : "location_id"
    sub_location ||--o{ store_target_master : "location_id"
    sub_location ||--o{ store_target_slab_config : "location_id"
    sub_location ||--o{ store_pool_hierarchy_config : "location_id"
    designation_master ||--o{ store_pool_hierarchy_config : "designation_id"
    sales_target_portfolio ||--o{ commission_ledger : "portfolio_id"
    payroll_period_master ||--o{ commission_ledger : "period_id"
    employee_master ||--o{ commission_ledger : "employee_id"

    parent_entity {
        int entity_id PK
        string entity_code
        string legal_name
        string entity_type "legal constitution"
        string entity_role "hq/company_owned/franchisee PENDING"
        string status "LOCKED + PENDING entity_role"
    }

    employee_master {
        int employee_id PK
        string employee_code "ED-LOC-NNN"
        int department_id FK
        int designation_id FK
        int location_id FK
        int parent_entity_id FK
        int role_id FK
        int reporting_manager_id FK
        boolean is_salesperson
        date date_of_joining "gratuity base"
        string status "LOCKED"
    }

    attendance_decision {
        int decision_id PK
        int attendance_id FK
        int computation_id FK
        string final_status "authoritative"
        numeric payable_units
        boolean manual_override
        string status "LOCKED"
    }

    commission_ledger {
        int commission_id PK
        int employee_id FK
        int location_id FK
        int payroll_period_id FK
        int portfolio_id FK
        numeric commission_value
        string status "LOCKED"
    }

    employee_salary {
        int salary_id PK
        int employee_id FK
        string grade_code FK
        numeric ctc_annual
        numeric gross_monthly
        date effective_from
        string status "LOCKED"
    }
```

### HRMS Table Groups

| Group | Tables / views | Status |
|---|---|---|
| Core employee registry | `state_master`, `parent_entity`, `sub_location`, `department_master`, `designation_master`, `role_master`, `employee_master`, `employee_finance` | LOCKED |
| Leave, shift, compliance, payroll policy | `holiday_calendar`, `leave_type_master`, `employee_category_master`, `leave_policy_master`, `policy_variant`, `policy_assignment`, `shift_policy_master`, `pt_slab_master`, `minimum_wage_master`, `payroll_period_master`, `salary_structure_master`, `state_compliance_master` | LOCKED |
| Preferences and capability | `employee_shift_preference`, `employee_skills` | LOCKED |
| Roster and attendance | `roster`, `roster_slots`, `roster_history`, `attendance`, `co_ledger`, `attendance_computation`, `attendance_decision`, `v_co_balance`, `v_payroll_input` | LOCKED |
| Performance and incentives | `sales_target_portfolio`, `store_target_master`, `store_target_slab_config`, `store_pool_hierarchy_config`, `commission_ledger`, `v_commission_payroll` | LOCKED |
| Salary, gratuity, advances, exit | `employee_salary`, `gratuity_ledger`, `employee_advances`, `v_fnf_settlement` | LOCKED |

### HRMS Notes

- HRMS currently reconciles to 37 SQL tables across Phase 1 through Phase 7, plus payroll/FnF/commission/CO views.
- `employee_master` is the HRMS anchor and drives attendance, roster, leave, payroll, commission, gratuity, advances, and FnF.
- Employee Master seed rule: case master starts with 26 active people across HQ and four stores, including store keyholders, sales staff, grooming staff, clinic staff, two probation employees, and one contractual veterinary doctor.
- Employee Master should include `is_reporting_manager_eligible` as a boolean checkbox/tick field. `reporting_manager_id` dropdown should list active employees with this tick enabled, then apply location/area/HQ visibility rules and block self-reporting.
- Employee Category is treated as statutory wage/skill class for `minimum_wage_master.employee_category_code`: `MGT601` managerial/supervisory, `ADM602` administrative/clerical, `HSK603` highly skilled, `SKD604` skilled, `SSK605` semi-skilled, `USK606` unskilled.
- Grade authority is controlled through `designation_master.grade_code`, not Employee Category. Employee Category remains a wage/compliance class only.
- `designation_master.override_level` should use the same grade-code dropdown (`A`, `B`, `C`, `D`) for override authority; blank means the designation has no override power. Runtime override must check both assigned role permission and the employee's designation grade, so Role Manager alone cannot create override authority.
- Employee Master menu alignment: `employee_type` uses `Full Time` or `Contractor`, `employment_subtype` uses `Permanent`, `Probation`, or `Contractual`, `shift_preference_mode` uses `Fixed`, `Rotational`, or `Flexible`, and `status` uses `Active`.
- Employee Profile companion-layer recommendation: keep `employee_master` as the anchor and expose accordion sections for profile checklist, personal details, address, emergency contact, statutory/KYC, finance, documents, skills, shift preferences, and lifecycle.
- Current schema already has `employee_finance`, `employee_skills`, and `employee_shift_preference`; proposed new companion tables are needed for personal details, address, emergency contact, statutory/nominee detail, and documents.
- `parent_entity.entity_type` is legal constitution only (`company`, `llp`, `partnership`, `proprietorship`). It must not be overloaded for HQ/franchisee classification.
- Pending schema enhancement: add `parent_entity.entity_role` with controlled values `hq`, `company_owned`, and `franchisee`; payroll/entity classification should read this field once implemented.
- Payroll routing is derived from `employee_master.parent_entity_id -> parent_entity`; no redundant payroll entity field is stored.
- `employee_master.date_of_joining` is the single joining date and gratuity service-date base.
- Shift Policy Master seed rule: HQ has one 9-hour office shift, and each retail store has two overlapping 9-hour fixed shifts (`10:30-19:30` and `12:30-21:30`) against `shift_policy_master.location_id`.
- Shift policy menu alignment: `shift_type = Fixed`, `coverage_mode = Single/Dual`, `roster_cycle = Weekly/Monthly`, `weekly_off_pattern = Fixed/Rotational`, `holiday_working_policy = Co Credit/None`, and `policy_status = Active`.
- Store weekly off is roster-based, so `shift_policy_master.weekly_off_day` stays blank for stores; HQ uses ISO day `7` for Sunday. Current UI still shows this as text/smallint, not an ISO dropdown.
- `shift_policy_master.co_credit_trigger` is boolean in the current schema: stores use `true` for calendar-controlled holiday/CO handling, while the HQ office shift uses `false`.
- `attendance_computation` is a pure measurement layer; `attendance_decision` is the authoritative payable-status layer and feeds `v_payroll_input`.
- `employee_skills` is intentionally separate from `designation_master`; service booking and groomer commission should read skills/capabilities, not only formal designation.
- Performance audit lives mainly in `sales_target_portfolio`, `store_target_master`, `store_target_slab_config`, `store_pool_hierarchy_config`, and `commission_ledger`.
- HRMS-to-order/POS links are deferred FKs: `commission_ledger.pos_transaction_id`, `commission_ledger.pos_line_item_id`, and item/category/brand portfolio references.
- HRMS-to-finance links are action-level: payroll input, commission payable, gratuity provision/payment, salary advances, and FnF settlement.
- Location audit support is in Phase 8 via `location_audit_log`; it connects to HRMS through `employee_master` as actor/configurer but keeps `changed_by` as non-FK integer so audit history survives employee deletion.

## Permission Layer

```mermaid
erDiagram
    erp_module_master ||--o{ erp_sub_module_master : "module_id"
    erp_module_master ||--o{ role_permission : "module_id"
    erp_sub_module_master ||--o{ role_permission : "sub_module_id"
    erp_report_master ||--o{ role_report_permission : "report_id"
    role_permission ||..|| v_role_permissions : "middleware view"
    role_report_permission ||..|| v_role_report_permissions : "middleware view"

    erp_module_master {
        uuid module_id PK
        string module_code
        string module_name
        boolean requires_hq_entity
        string status "LOCKED"
    }

    erp_sub_module_master {
        uuid sub_module_id PK
        uuid module_id FK
        string sub_module_code
        string status "LOCKED"
    }

    role_permission {
        uuid role_permission_id PK
        uuid role_id FK
        uuid module_id FK
        uuid sub_module_id FK
        boolean can_view
        boolean can_create
        boolean can_edit
        boolean can_delete
        string status "LOCKED"
    }

    erp_report_master {
        uuid report_id PK
        string report_code
        string report_name
        string status "LOCKED"
    }

    role_report_permission {
        uuid role_report_permission_id PK
        uuid role_id FK
        uuid report_id FK
        boolean can_view
        string status "LOCKED"
    }

    v_role_permissions {
        string view_name
        string purpose "middleware permissions"
        string status "LOCKED"
    }

    v_role_report_permissions {
        string view_name
        string purpose "middleware report permissions"
        string status "LOCKED"
    }
```

### Permission Notes

- `erp_module_master` has 19 modules seeded, including `MOD-PURCHASE`.
- `erp_sub_module_master` has 70+ sub-modules, including `SUB-PUR-VENDORS`, `SUB-PUR-PO`, `SUB-PUR-GRN`, and `SUB-PUR-PAYMENTS`.
- `erp_report_master` has 29 reports.
- `MOD-LOYALTY` and `MOD-SETTINGS` require HQ entity access.
- Procurement permission seeds remain pending.

## Vendor and Procurement Layer

```mermaid
erDiagram
    vendor_master ||--o{ vendor_contact : "vendor_id"
    vendor_master ||--o{ vendor_item_master : "vendor_id"
    item_master ||--o{ vendor_item_master : "item_id"
    sub_location ||--o{ vendor_item_master : "location-specific priority"
    purchase_request_master ||--o{ purchase_request_line : "pr_id"
    purchase_request_line ||..o{ vendor_procurement_request_line : "resolved line"
    vendor_procurement_request ||--o{ vendor_procurement_request_line : "vpr_id"
    vendor_master ||..o{ vendor_procurement_request : "resolved vendor"
    vendor_procurement_request ||--o{ procurement_resolution_log : "resolution snapshot"
    vendor_master ||..o{ vendor_performance_score : "future scoring"
    vendor_performance_score ||..|| v_vendor_recommendation : "future recommendation"
    vendor_procurement_request ||..o{ vpr_communication_log : "P1.5 communication"

    vendor_master {
        int vendor_id PK
        string vendor_code
        string default_delivery_mode "HQ_ROUTED default"
        string state_code "VARCHAR(5) pending alter"
        string status "LOCKED"
    }

    vendor_contact {
        int vendor_contact_id PK
        int vendor_id FK
        string contact_name
        string contact_role
        string status "LOCKED"
    }

    vendor_item_master {
        int vendor_item_id PK
        int vendor_id FK
        int item_id FK
        int sub_location_id FK
        string vendor_priority
        string match_type
        string status "LOCKED"
    }

    purchase_request_master {
        int pr_id PK
        int requesting_location_id FK
        int requested_by FK
        string pr_status
        string status "LOCKED P1"
    }

    purchase_request_line {
        int pr_line_id PK
        int pr_id FK
        int item_id FK
        numeric requested_qty
        string status "LOCKED P1"
    }

    vendor_procurement_request {
        int vpr_id PK
        int suggested_vendor_id FK
        jsonb resolution_snapshot
        boolean vendor_overridden
        string dispatch_channel
        string status "LOCKED P1"
    }

    vendor_procurement_request_line {
        int vpr_line_id PK
        int vpr_id FK
        int item_id FK
        numeric resolved_qty
        string status "LOCKED P1"
    }

    procurement_resolution_log {
        int resolution_log_id PK
        int vpr_id FK
        string resolution_source
        jsonb resolution_snapshot
        string status "LOCKED P1"
    }

    vendor_performance_score {
        int vendor_performance_score_id PK
        int vendor_id FK
        string scoring_period
        numeric score
        string status "DEFERRED P2"
    }

    v_vendor_recommendation {
        string view_name
        string purpose "suggest only"
        string status "DEFERRED P2"
    }

    vpr_communication_log {
        int communication_log_id PK
        int vpr_id FK
        string channel
        string status "DEFERRED P1.5"
    }
```

### Procurement Flow

```mermaid
flowchart TD
    STORE["Store user<br/>raises PR only<br/>no vendor visibility"]
    PR["Purchase Request<br/>demand + item + qty"]
    ROUTE{"Vendor mapping exists?"}
    ENGINE["Auto-suggestion engine<br/>location PRIMARY first<br/>network fallback second"]
    HQ["HQ review queue<br/>unmapped or exception cases"]
    RESOLVE["HQ resolution<br/>override allowed with reason"]
    VPR["Vendor Procurement Request<br/>JSONB resolution snapshot"]
    DISPATCH["Manual dispatch P1<br/>WhatsApp deferred P1.5"]
    P2["Vendor scoring / recommendation<br/>after 6 months live data<br/>DEFERRED"]

    STORE --> PR
    PR --> ROUTE
    ROUTE -->|yes| ENGINE
    ROUTE -->|no| HQ
    ENGINE --> RESOLVE
    HQ --> RESOLVE
    RESOLVE --> VPR
    VPR --> DISPATCH
    VPR -.actuals and history.-> P2
```

### Vendor/Procurement Notes

- `vendor_location_assignment` was dropped; dynamic item x location x priority mapping lives in `vendor_item_master`.
- Stores never manually select vendors and should not see vendor information.
- HQ owns vendor resolution, override, and dispatch.
- P1 states include 7 core states plus `CANCELLED` and `NEEDS_HQ_REVIEW`.
- Vendor recommendation P2 is suggest-only and never overrides hardcoded routing.
- Pending ALTER: `vendor_master.state_code` from `VARCHAR(2)` to `VARCHAR(5)`.

## Item Master / Inventory Layer

```mermaid
erDiagram
    revenue_centre_master ||--o{ sub_category_master : "default revenue centre"
    expense_account_master ||..o{ item_master : "operational/consumable expense"
    category_master ||--o{ sub_category_master : "category_id"
    sub_category_master ||--o{ item_master : "sub_category_id"
    brand_master ||--o{ item_master : "brand_id"
    tax_master ||--o{ item_master : "tax_id"
    uom_master ||--o{ item_variant_master : "uom_id"
    item_master ||--o{ item_variant_master : "item_id"
    animal_master ||..o{ item_master : "animal_ids"
    nested_category_master ||..o{ item_master : "nested_category_ids"
    item_variant_master ||--o{ vendor_item_master : "variant/item procurement"
    item_variant_master ||--o{ pricing_rules_master : "sellable target"
    item_variant_master ||--o{ scheme_bulk_pack_master : "bundle source"
    item_variant_master ||--o{ purchase_request_line : "item demand"
    item_master ||--o{ new_product_request : "duplicate link"

    revenue_centre_master {
        int revenue_centre_id PK
        string rc_code "RC-RETAIL etc"
        string status "IN_PROGRESS foundation"
    }

    expense_account_master {
        int expense_account_id PK
        string expense_code
        string status "IN_PROGRESS foundation"
    }

    category_master {
        int category_id PK
        string category_name
        string status "IN_PROGRESS"
    }

    sub_category_master {
        int sub_category_id PK
        int category_id FK
        int revenue_centre_id FK
        boolean consumption_tracking
        boolean expiry_management
        string status "IN_PROGRESS"
    }

    brand_master {
        int brand_id PK
        string brand_code "system validated"
        string brand_name
        string status "IN_PROGRESS foundation"
    }

    tax_master {
        int tax_id PK
        string tax_code
        numeric gst_rate
        numeric cess_rate
        string status "IN_PROGRESS foundation"
    }

    uom_master {
        int uom_id PK
        string uom_code
        string uom_type
        string status "IN_PROGRESS foundation"
    }

    animal_master {
        int animal_id PK
        string animal_code
        string status "IN_PROGRESS foundation"
    }

    nested_category_master {
        int nested_category_id PK
        string nested_category_name
        string status "IN_PROGRESS"
    }

    item_master {
        int item_id PK
        string parent_sku "brand scoped sequence"
        string supply_type "PRODUCT/SERVICE/CONSUMABLE/OPERATIONAL"
        int sub_category_id FK
        int brand_id FK
        int tax_id FK
        int revenue_centre_id FK
        int expense_account_id FK
        boolean has_variations
        boolean online_listing_eligible
        string status "IN_PROGRESS"
    }

    item_variant_master {
        int item_variant_id PK
        int item_id FK
        string variant_sku
        string variant_attribute
        string variant_value
        string variant_supply_type
        numeric pack_qty
        int uom_id FK
        numeric mrp
        numeric selling_price
        numeric purchase_price
        numeric landing_cost
        numeric service_charge
        int service_duration_minutes
        boolean online_flag
        boolean is_active
        string status "IN_PROGRESS"
    }

    new_product_request {
        int request_id PK
        int requested_by FK
        int requesting_location FK
        string status_flow
        int duplicate_item_id FK
        string status "IN_PROGRESS companion"
    }
```

### Item Master Decisions From Latest Chat

| Decision | Current value |
|---|---|
| `supply_type` | Four values: `PRODUCT`, `SERVICE`, `CONSUMABLE`, `OPERATIONAL` |
| Customer display code | Derived from location-style display, system code remains `CUST-NNNNN` |
| Pet display code | Derived from customer display + sequence, system code remains `PET-NNNNN` |
| Revenue centre | On `sub_category_master`, inherited by item |
| Variations | Parent `item_master` plus child `item_variant_master` |
| Service variants | Allowed from the start |
| Variant model | Single-axis initially; multi-axis deferred |
| Pricing location | Every sellable thing is a variant; default variant auto-created when `has_variations = FALSE` |
| SKU generation | System-generated only, brand-scoped parent sequence |
| Brand code | System-validated and collision-resolved at creation |
| `online_flag` | Variant-level for product/service/consumable |
| Active/deactive control | Variant-level through `item_variant_master.is_active`; parent remains the catalog definition |
| Operational online sale | Locked false because it has no revenue infrastructure |

### Item Master Flow

```mermaid
flowchart TD
    CREATE["Super Admin creates item<br/>HQ-only master data"]
    TYPE{"Select supply_type"}
    PRODUCT["PRODUCT fields<br/>brand + HSN + stock + price"]
    SERVICE["SERVICE fields<br/>SAC + duration + service charge"]
    CONSUMABLE["CONSUMABLE fields<br/>stock + sale + internal expense"]
    OPERATIONAL["OPERATIONAL fields<br/>internal stock + expense only"]
    PARENT["item_master parent<br/>system parent SKU"]
    VARIANT{"has_variations?"}
    DEFAULT["Auto-create default variant<br/>when no variations"]
    CHILDREN["Create variant rows<br/>variant SKU + per-variant price/channel"]
    ONLINE["online_flag lives on variant<br/>PRODUCT/SERVICE/CONSUMABLE"]
    ACTIVE["Active/deactive lives on variant<br/>stop selling a specific pack or service size"]
    LOCK["Supply type and variation mode locked after creation"]

    CREATE --> TYPE
    TYPE --> PRODUCT
    TYPE --> SERVICE
    TYPE --> CONSUMABLE
    TYPE --> OPERATIONAL
    PRODUCT --> PARENT
    SERVICE --> PARENT
    CONSUMABLE --> PARENT
    OPERATIONAL --> PARENT
    PARENT --> VARIANT
    VARIANT -->|no| DEFAULT
    VARIANT -->|yes| CHILDREN
    DEFAULT --> ONLINE
    CHILDREN --> ONLINE
    ONLINE --> ACTIVE
    ACTIVE --> LOCK
```

### SKU Format Reference

| Level | Format | Example |
|---|---|---|
| Parent item | `[BRAND_CODE]-[SEQ_WITHIN_BRAND]` | `RC-489` |
| Variant | parent + `-[PACK_QTY][UOM_CODE]` or service variant suffix | `RC-489-10KG` |
| Bundle/scheme | variant + `-P[BUNDLE_QTY]` | `RC-489-10KG-P12` |

No human types a SKU. Brand codes are system-validated and collision-resolved. Parent and variant SKUs are generated by triggers after insert.

## Deferred and Pending Work

```mermaid
flowchart LR
    CRM1["customer_tag_master<br/>PENDING"]
    CRM2["consumption_rate_master<br/>PENDING"]
    CRM3["CRM permission seeds<br/>PENDING"]
    PUR1["Procurement permission seeds<br/>PENDING"]
    PUR2["vendor_performance_score<br/>DEFERRED P2"]
    PUR3["v_vendor_recommendation<br/>DEFERRED P2"]
    HR1["sales_target_portfolio item/brand/category FKs<br/>DEFERRED until Item Master"]
    HR2["commission_ledger POS line/transaction FKs<br/>DEFERRED until Order/POS"]
    HR3["commission_ledger payroll_run_id FK<br/>DEFERRED until Payroll Engine"]
    WABA["WhatsApp Business API<br/>DEFERRED P1.5"]
    PORTAL["magic-link vendor portal<br/>DEFERRED P1.5"]
    COMM["vpr_communication_log<br/>DEFERRED P1.5"]
    ALTER["vendor_master.state_code<br/>VARCHAR(2) to VARCHAR(5)<br/>PENDING ALTER"]
    PE1["parent_entity.entity_role<br/>PENDING schema enhancement<br/>hq / company_owned / franchisee"]
    ID1["master identifier cleanup<br/>PENDING schema simplification<br/>readable alphanumeric PK per master layer"]

    CRM1 --> CRM2
    CRM1 --> CRM3
    HR1 --> HR2
    HR2 --> HR3
    PUR1 --> PUR2
    PUR2 --> PUR3
    WABA --> COMM
    PORTAL --> COMM
```

## Source Coverage Check

| Included area | Source basis | Status |
|---|---|---|
| Customer Master v2.0 | Project memory | LOCKED |
| Pet Master v1.0 | Project memory | LOCKED |
| Loyalty Module | Project memory | LOCKED |
| HRMS table count, performance layer, payroll/FnF views, and audit posture | Phase 1-8 HRMS SQL files + schema map refresh, 2026-05-13 | LOCKED |
| Permission System v1.0 | Project memory | LOCKED |
| Vendor Module | Project memory + latest ERP chat | LOCKED |
| Procurement Orchestration P1 | Project memory + latest ERP chat | LOCKED |
| Item Master | Latest `Indipet ERP` chat, 2026-05-10 | IN_PROGRESS |
| Parent entity business role | User-identified schema gap during case-master preparation, 2026-05-26 | PENDING |
| Master identifier simplification | User-identified schema simplification during case-master preparation, 2026-05-26: use readable alphanumeric text IDs such as `IPL101`, `SCP102`, and `IPL101-SLT201` | PENDING |
| CRM tags and consumption rate | Project memory | PENDING |
| Vendor scoring and WhatsApp | Project memory | DEFERRED |
