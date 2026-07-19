-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.attendance (
  attendance_id integer NOT NULL DEFAULT nextval('attendance_attendance_id_seq'::regclass),
  employee_id integer,
  attendance_date date,
  roster_id integer,
  roster_slot_id integer,
  raw_check_in timestamp without time zone,
  raw_check_out timestamp without time zone,
  check_in_time timestamp without time zone,
  check_out_time timestamp without time zone,
  biometric_failure boolean,
  is_weekly_off boolean,
  is_holiday boolean,
  is_on_leave boolean,
  leave_type_id integer,
  worked_on_weekly_off boolean,
  worked_on_holiday boolean,
  final_status character varying,
  payable_units numeric,
  worked_hours numeric,
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  location_id integer,
  shift_id integer,
  remarks text,
  CONSTRAINT attendance_pkey PRIMARY KEY (attendance_id),
  CONSTRAINT attendance_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.sub_location(location_id),
  CONSTRAINT attendance_shift_id_fkey FOREIGN KEY (shift_id) REFERENCES public.shift_policy_master(policy_id),
  CONSTRAINT fk_attendance_employee FOREIGN KEY (employee_id) REFERENCES public.employee_master(employee_id),
  CONSTRAINT fk_attendance_leave_type FOREIGN KEY (leave_type_id) REFERENCES public.leave_type_master(leave_type_id),
  CONSTRAINT fk_attendance_roster FOREIGN KEY (roster_id) REFERENCES public.roster(roster_id),
  CONSTRAINT fk_attendance_roster_slot FOREIGN KEY (roster_slot_id) REFERENCES public.roster_slots(slot_id)
);
CREATE TABLE public.attendance_regularization (
  request_id integer NOT NULL DEFAULT nextval('attendance_regularization_request_id_seq'::regclass),
  employee_id integer NOT NULL,
  attendance_date date NOT NULL,
  issue_type character varying NOT NULL,
  description text,
  requested_status character varying,
  supporting_evidence text,
  status character varying NOT NULL DEFAULT 'Pending'::character varying,
  approved_by integer,
  approved_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT attendance_regularization_pkey PRIMARY KEY (request_id),
  CONSTRAINT attendance_regularization_approved_by_fkey FOREIGN KEY (approved_by) REFERENCES public.employee_master(employee_id),
  CONSTRAINT attendance_regularization_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.employee_master(employee_id)
);
CREATE TABLE public.attendance_reports (
  report_id integer NOT NULL DEFAULT nextval('attendance_reports_report_id_seq'::regclass),
  report_name character varying NOT NULL,
  scope character varying,
  scope_value integer,
  period_start date,
  period_end date,
  filters jsonb DEFAULT '{}'::jsonb,
  owner_id integer,
  last_run_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT attendance_reports_pkey PRIMARY KEY (report_id),
  CONSTRAINT attendance_reports_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES public.employee_master(employee_id)
);
CREATE TABLE public.co_ledger (
  co_id integer NOT NULL DEFAULT nextval('co_ledger_co_id_seq'::regclass),
  employee_id integer,
  co_type character varying,
  source_attendance_id integer,
  credit_date date,
  expiry_date date,
  status character varying,
  CONSTRAINT co_ledger_pkey PRIMARY KEY (co_id),
  CONSTRAINT fk_co_ledger_attendance FOREIGN KEY (source_attendance_id) REFERENCES public.attendance(attendance_id),
  CONSTRAINT fk_co_ledger_employee FOREIGN KEY (employee_id) REFERENCES public.employee_master(employee_id)
);
CREATE TABLE public.delivery_zone (
  zone_id integer NOT NULL DEFAULT nextval('delivery_zone_zone_id_seq'::regclass),
  location_id integer,
  zone_code character varying,
  zone_name character varying,
  radius_km numeric,
  delivery_time_minutes integer,
  fulfillment_type character varying,
  CONSTRAINT delivery_zone_pkey PRIMARY KEY (zone_id),
  CONSTRAINT fk_delivery_zone_location FOREIGN KEY (location_id) REFERENCES public.sub_location(location_id)
);
CREATE TABLE public.department_master (
  department_id integer NOT NULL DEFAULT nextval('department_master_department_id_seq'::regclass),
  department_code character varying UNIQUE,
  department_name character varying,
  revenue_centre_code character varying,
  is_revenue_generating boolean,
  status character varying,
  department_short_code character varying NOT NULL CHECK (department_short_code::text ~ '^[A-Z]{3}$'::text),
  CONSTRAINT department_master_pkey PRIMARY KEY (department_id)
);
CREATE TABLE public.designation_master (
  designation_id integer NOT NULL DEFAULT nextval('designation_master_designation_id_seq'::regclass),
  designation_code character varying UNIQUE,
  designation_name character varying,
  department_id integer,
  grade_code character varying,
  override_grade_code character varying,
  is_keyholder_eligible boolean,
  is_salesperson_eligible boolean,
  status character varying,
  CONSTRAINT designation_master_pkey PRIMARY KEY (designation_id),
  CONSTRAINT fk_designation_department FOREIGN KEY (department_id) REFERENCES public.department_master(department_id)
);
CREATE TABLE public.employee_address (
  employee_address_id integer GENERATED ALWAYS AS IDENTITY NOT NULL,
  employee_id integer,
  is_same_as_present boolean DEFAULT false,
  present_address_line1 text,
  present_address_line2 text,
  present_country text,
  present_state text,
  present_city text,
  present_pincode text,
  permanent_address_line1 text,
  permanent_address_line2 text,
  permanent_country text,
  permanent_state text,
  permanent_city text,
  permanent_pincode text,
  status text,
  same_address boolean DEFAULT false,
  CONSTRAINT employee_address_pkey PRIMARY KEY (employee_address_id),
  CONSTRAINT employee_address_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.employee_master(employee_id)
);
CREATE TABLE public.employee_audit_log (
  log_id integer NOT NULL DEFAULT nextval('employee_audit_log_log_id_seq'::regclass),
  employee_id integer,
  action character varying,
  old_data jsonb,
  new_data jsonb,
  changed_at timestamp without time zone,
  CONSTRAINT employee_audit_log_pkey PRIMARY KEY (log_id),
  CONSTRAINT fk_employee_audit_log_employee FOREIGN KEY (employee_id) REFERENCES public.employee_master(employee_id)
);
CREATE TABLE public.employee_bank_history (
  history_id integer NOT NULL DEFAULT nextval('employee_bank_history_history_id_seq'::regclass),
  employee_id integer,
  bank_name character varying,
  account_number character varying,
  effective_from date,
  effective_to date,
  CONSTRAINT employee_bank_history_pkey PRIMARY KEY (history_id),
  CONSTRAINT fk_employee_bank_history_employee FOREIGN KEY (employee_id) REFERENCES public.employee_master(employee_id)
);
CREATE TABLE public.employee_category_master (
  category_code character varying NOT NULL,
  category_name character varying,
  description text,
  status character varying,
  CONSTRAINT employee_category_master_pkey PRIMARY KEY (category_code)
);
CREATE TABLE public.employee_documents (
  document_id integer NOT NULL DEFAULT nextval('employee_documents_document_id_seq'::regclass),
  employee_id integer,
  document_type character varying,
  file_url character varying,
  issue_date date,
  expiry_date date,
  is_mandatory boolean,
  document_number character varying,
  verification_status character varying,
  document_status character varying,
  CONSTRAINT employee_documents_pkey PRIMARY KEY (document_id),
  CONSTRAINT fk_employee_documents_employee FOREIGN KEY (employee_id) REFERENCES public.employee_master(employee_id)
);
CREATE TABLE public.employee_emergency_contact (
  emergency_contact_id integer NOT NULL DEFAULT nextval('employee_emergency_contact_emergency_contact_id_seq'::regclass),
  employee_id integer,
  contact_name character varying,
  relationship character varying,
  phone character varying,
  alternate_phone character varying,
  is_primary boolean DEFAULT false,
  status character varying DEFAULT 'Active'::character varying,
  address text,
  CONSTRAINT employee_emergency_contact_pkey PRIMARY KEY (emergency_contact_id),
  CONSTRAINT employee_emergency_contact_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.employee_master(employee_id)
);
CREATE TABLE public.employee_exit_workflow (
  workflow_id integer NOT NULL DEFAULT nextval('employee_exit_workflow_workflow_id_seq'::regclass),
  employee_id integer,
  exit_type character varying,
  exit_date date,
  noc_status boolean,
  CONSTRAINT employee_exit_workflow_pkey PRIMARY KEY (workflow_id),
  CONSTRAINT fk_employee_exit_workflow_employee FOREIGN KEY (employee_id) REFERENCES public.employee_master(employee_id)
);
CREATE TABLE public.employee_face_captures (
  sample_id integer NOT NULL DEFAULT nextval('employee_face_captures_sample_id_seq'::regclass),
  employee_id integer NOT NULL,
  capture_index integer NOT NULL,
  image_data_url text NOT NULL,
  descriptor jsonb NOT NULL,
  captured_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT employee_face_captures_pkey PRIMARY KEY (sample_id),
  CONSTRAINT employee_face_captures_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.employee_master(employee_id)
);
CREATE TABLE public.employee_finance (
  finance_id integer NOT NULL DEFAULT nextval('employee_finance_finance_id_seq'::regclass),
  employee_id integer,
  bank_name character varying,
  bank_branch character varying,
  account_number character varying,
  ifsc_code character varying,
  pan_number character varying,
  uan_number character varying,
  pf_number character varying,
  esi_number character varying,
  bank_verification_status character varying,
  CONSTRAINT employee_finance_pkey PRIMARY KEY (finance_id),
  CONSTRAINT fk_employee_finance_employee FOREIGN KEY (employee_id) REFERENCES public.employee_master(employee_id)
);
CREATE TABLE public.employee_leave_balance (
  balance_id integer NOT NULL DEFAULT nextval('employee_leave_balance_balance_id_seq'::regclass),
  employee_id integer,
  leave_type_id integer,
  policy_year smallint NOT NULL DEFAULT (date_part('year'::text, CURRENT_DATE))::smallint,
  entitled_days numeric NOT NULL DEFAULT 0,
  availed_days numeric NOT NULL DEFAULT 0,
  remaining_days numeric DEFAULT (entitled_days - availed_days),
  carry_forward_days numeric NOT NULL DEFAULT 0,
  created_at timestamp without time zone DEFAULT now(),
  updated_at timestamp without time zone DEFAULT now(),
  CONSTRAINT employee_leave_balance_pkey PRIMARY KEY (balance_id),
  CONSTRAINT employee_leave_balance_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.employee_master(employee_id),
  CONSTRAINT employee_leave_balance_leave_type_id_fkey FOREIGN KEY (leave_type_id) REFERENCES public.leave_type_master(leave_type_id)
);
CREATE TABLE public.employee_master (
  employee_id integer NOT NULL DEFAULT nextval('employee_master_employee_id_seq'::regclass),
  employee_code character varying UNIQUE,
  employee_type character varying,
  employment_subtype character varying,
  first_name character varying,
  last_name character varying,
  phone character varying UNIQUE,
  email character varying,
  gender character varying,
  department_id integer,
  designation_id integer,
  location_id integer,
  parent_entity_id integer,
  reporting_manager_id integer,
  employee_category character varying,
  date_of_joining date,
  original_doj date,
  is_salesperson boolean,
  login_id character varying UNIQUE,
  role_id integer,
  default_shift_id integer,
  face_registered boolean,
  shift_preference_mode character varying,
  date_of_exit date,
  exit_type character varying,
  status character varying,
  is_reporting_manager boolean DEFAULT false,
  preferred_weekly_off_day smallint,
  CONSTRAINT employee_master_pkey PRIMARY KEY (employee_id),
  CONSTRAINT fk_employee_default_shift FOREIGN KEY (default_shift_id) REFERENCES public.shift_policy_master(policy_id),
  CONSTRAINT fk_employee_department FOREIGN KEY (department_id) REFERENCES public.department_master(department_id),
  CONSTRAINT fk_employee_designation FOREIGN KEY (designation_id) REFERENCES public.designation_master(designation_id),
  CONSTRAINT fk_employee_location FOREIGN KEY (location_id) REFERENCES public.sub_location(location_id),
  CONSTRAINT fk_employee_parent_entity FOREIGN KEY (parent_entity_id) REFERENCES public.parent_entity(entity_id),
  CONSTRAINT fk_employee_reporting_manager FOREIGN KEY (reporting_manager_id) REFERENCES public.employee_master(employee_id),
  CONSTRAINT fk_employee_role FOREIGN KEY (role_id) REFERENCES public.role_master(role_id)
);
CREATE TABLE public.employee_profile (
  profile_id integer NOT NULL DEFAULT nextval('employee_profile_profile_id_seq'::regclass),
  employee_id integer,
  date_of_birth date,
  marital_status character varying,
  blood_group character varying,
  father_name character varying,
  mother_name character varying,
  spouse_name character varying,
  nationality character varying DEFAULT 'Indian'::character varying,
  profile_status character varying DEFAULT 'Partial'::character varying,
  CONSTRAINT employee_profile_pkey PRIMARY KEY (profile_id),
  CONSTRAINT employee_profile_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.employee_master(employee_id)
);
CREATE TABLE public.employee_salary_history (
  salary_history_id integer NOT NULL DEFAULT nextval('employee_salary_history_salary_history_id_seq'::regclass),
  employee_id integer,
  basic_salary numeric,
  gross_salary numeric,
  effective_from date,
  effective_to date,
  CONSTRAINT employee_salary_history_pkey PRIMARY KEY (salary_history_id),
  CONSTRAINT fk_employee_salary_history_employee FOREIGN KEY (employee_id) REFERENCES public.employee_master(employee_id)
);
CREATE TABLE public.employee_shift_preference (
  preference_id integer NOT NULL DEFAULT nextval('employee_shift_preference_preference_id_seq'::regclass),
  employee_id integer,
  preference_type character varying,
  preference_detail text,
  is_active boolean,
  CONSTRAINT employee_shift_preference_pkey PRIMARY KEY (preference_id),
  CONSTRAINT fk_employee_shift_preference_employee FOREIGN KEY (employee_id) REFERENCES public.employee_master(employee_id)
);
CREATE TABLE public.employee_skills (
  skill_id integer NOT NULL DEFAULT nextval('employee_skills_skill_id_seq'::regclass),
  employee_id integer,
  skill_name character varying,
  certification character varying,
  certified_on date,
  skill_level character varying,
  CONSTRAINT employee_skills_pkey PRIMARY KEY (skill_id),
  CONSTRAINT fk_employee_skills_employee FOREIGN KEY (employee_id) REFERENCES public.employee_master(employee_id)
);
CREATE TABLE public.employee_statutory (
  statutory_id integer NOT NULL DEFAULT nextval('employee_statutory_statutory_id_seq'::regclass),
  employee_id integer,
  aadhaar_number character varying,
  pan_number character varying,
  uan_number character varying,
  pf_number character varying,
  esi_number character varying,
  professional_tax_state character varying,
  nominee_name character varying,
  nominee_relation character varying,
  nominee_phone character varying,
  status character varying DEFAULT 'Active'::character varying,
  CONSTRAINT employee_statutory_pkey PRIMARY KEY (statutory_id),
  CONSTRAINT employee_statutory_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.employee_master(employee_id)
);
CREATE TABLE public.employee_transfer_history (
  transfer_id integer NOT NULL DEFAULT nextval('employee_transfer_history_transfer_id_seq'::regclass),
  employee_id integer,
  from_location_id integer,
  to_location_id integer,
  transfer_date date,
  CONSTRAINT employee_transfer_history_pkey PRIMARY KEY (transfer_id),
  CONSTRAINT fk_employee_transfer_employee FOREIGN KEY (employee_id) REFERENCES public.employee_master(employee_id),
  CONSTRAINT fk_employee_transfer_from_location FOREIGN KEY (from_location_id) REFERENCES public.sub_location(location_id),
  CONSTRAINT fk_employee_transfer_to_location FOREIGN KEY (to_location_id) REFERENCES public.sub_location(location_id)
);
CREATE TABLE public.fnf_settlement (
  settlement_id integer NOT NULL DEFAULT nextval('fnf_settlement_settlement_id_seq'::regclass),
  employee_id integer,
  last_working_date date,
  leave_encashment numeric,
  gratuity_amount numeric,
  final_payout numeric,
  CONSTRAINT fnf_settlement_pkey PRIMARY KEY (settlement_id),
  CONSTRAINT fk_fnf_settlement_employee FOREIGN KEY (employee_id) REFERENCES public.employee_master(employee_id)
);
CREATE TABLE public.gratuity_tracking (
  gratuity_id integer NOT NULL DEFAULT nextval('gratuity_tracking_gratuity_id_seq'::regclass),
  employee_id integer,
  eligibility_date date,
  gratuity_amount numeric,
  status character varying,
  CONSTRAINT gratuity_tracking_pkey PRIMARY KEY (gratuity_id),
  CONSTRAINT fk_gratuity_tracking_employee FOREIGN KEY (employee_id) REFERENCES public.employee_master(employee_id)
);
CREATE TABLE public.holiday_calendar (
  holiday_id integer NOT NULL DEFAULT nextval('holiday_calendar_holiday_id_seq'::regclass),
  holiday_date date,
  holiday_name character varying,
  state_code character varying,
  location_id integer,
  is_closed boolean,
  co_eligible boolean,
  calendar_year smallint,
  CONSTRAINT holiday_calendar_pkey PRIMARY KEY (holiday_id),
  CONSTRAINT fk_holiday_location FOREIGN KEY (location_id) REFERENCES public.sub_location(location_id),
  CONSTRAINT fk_holiday_state FOREIGN KEY (state_code) REFERENCES public.state_master(state_code)
);
CREATE TABLE public.indipet_audit_log (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  role text NOT NULL,
  actor text NOT NULL,
  module text NOT NULL,
  action text NOT NULL,
  details text NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT indipet_audit_log_pkey PRIMARY KEY (id)
);
CREATE TABLE public.indipet_module_records (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  module text NOT NULL,
  role text NOT NULL,
  title text NOT NULL,
  slug text NOT NULL,
  summary text NOT NULL DEFAULT ''::text,
  status text NOT NULL DEFAULT 'draft'::text,
  payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_by text NOT NULL DEFAULT ''::text,
  updated_by text NOT NULL DEFAULT ''::text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT indipet_module_records_pkey PRIMARY KEY (id)
);
CREATE TABLE public.indipet_realtime_events (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  role text NOT NULL,
  module text NOT NULL,
  message text NOT NULL,
  severity text NOT NULL DEFAULT 'info'::text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT indipet_realtime_events_pkey PRIMARY KEY (id)
);
CREATE TABLE public.leave_policy_master (
  policy_id integer NOT NULL DEFAULT nextval('leave_policy_master_policy_id_seq'::regclass),
  policy_code character varying UNIQUE,
  policy_name character varying,
  policy_year smallint,
  effective_from date,
  effective_to date,
  scope character varying,
  calendar_source character varying,
  approval_mode character varying,
  simultaneous_leave_block boolean,
  co_credit_trigger character varying,
  co_auto_credit boolean,
  co_expiry_days integer,
  co_min_hours numeric,
  version_number integer,
  status character varying,
  CONSTRAINT leave_policy_master_pkey PRIMARY KEY (policy_id)
);
CREATE TABLE public.leave_requests (
  request_id integer NOT NULL DEFAULT nextval('leave_requests_request_id_seq'::regclass),
  employee_id integer,
  leave_type_id integer,
  start_date date,
  end_date date,
  duration_days numeric,
  reason text,
  status character varying DEFAULT 'pending'::character varying,
  applied_on date DEFAULT CURRENT_DATE,
  approved_by integer,
  approved_on date,
  period character varying,
  created_at timestamp without time zone DEFAULT now(),
  updated_at timestamp without time zone DEFAULT now(),
  CONSTRAINT leave_requests_pkey PRIMARY KEY (request_id)
);
CREATE TABLE public.leave_type_master (
  leave_type_id integer NOT NULL DEFAULT nextval('leave_type_master_leave_type_id_seq'::regclass),
  leave_code character varying UNIQUE,
  leave_name character varying,
  is_paid boolean,
  pay_percentage numeric,
  accrual_type character varying,
  max_days_per_year numeric,
  carry_forward_allowed boolean,
  gender_restriction character varying,
  requires_approval boolean,
  is_lop boolean,
  status character varying,
  CONSTRAINT leave_type_master_pkey PRIMARY KEY (leave_type_id)
);
CREATE TABLE public.location_audit_log (
  audit_id integer NOT NULL DEFAULT nextval('location_audit_log_audit_id_seq'::regclass),
  location_id integer,
  action character varying,
  old_data jsonb,
  new_data jsonb,
  changed_at timestamp without time zone,
  CONSTRAINT location_audit_log_pkey PRIMARY KEY (audit_id),
  CONSTRAINT fk_location_audit_location FOREIGN KEY (location_id) REFERENCES public.sub_location(location_id)
);
CREATE TABLE public.location_onboarding_checklist (
  checklist_id integer NOT NULL DEFAULT nextval('location_onboarding_checklist_checklist_id_seq'::regclass),
  location_id integer,
  checklist_item character varying,
  item_code character varying,
  is_mandatory boolean,
  is_completed boolean,
  CONSTRAINT location_onboarding_checklist_pkey PRIMARY KEY (checklist_id),
  CONSTRAINT fk_location_onboarding_location FOREIGN KEY (location_id) REFERENCES public.sub_location(location_id)
);
CREATE TABLE public.location_operating_hours (
  hours_id integer NOT NULL DEFAULT nextval('location_operating_hours_hours_id_seq'::regclass),
  location_id integer,
  day_of_week smallint,
  is_open boolean,
  official_open_time time without time zone,
  official_close_time time without time zone,
  operational_open_time time without time zone,
  operational_close_time time without time zone,
  shift_policy_id integer,
  CONSTRAINT location_operating_hours_pkey PRIMARY KEY (hours_id),
  CONSTRAINT fk_location_operating_hours_location FOREIGN KEY (location_id) REFERENCES public.sub_location(location_id),
  CONSTRAINT fk_location_operating_hours_policy FOREIGN KEY (shift_policy_id) REFERENCES public.shift_policy_master(policy_id)
);
CREATE TABLE public.location_service_config (
  config_id integer NOT NULL DEFAULT nextval('location_service_config_config_id_seq'::regclass),
  location_id integer,
  service_code character varying,
  is_active boolean,
  activated_by integer,
  CONSTRAINT location_service_config_pkey PRIMARY KEY (config_id),
  CONSTRAINT fk_location_service_config_activated_by FOREIGN KEY (activated_by) REFERENCES public.employee_master(employee_id),
  CONSTRAINT fk_location_service_config_location FOREIGN KEY (location_id) REFERENCES public.sub_location(location_id),
  CONSTRAINT fk_location_service_config_service FOREIGN KEY (service_code) REFERENCES public.service_type_master(service_code)
);
CREATE TABLE public.minimum_wage_master (
  wage_id integer NOT NULL DEFAULT nextval('minimum_wage_master_wage_id_seq'::regclass),
  state_code character varying,
  employee_category_code character varying,
  wage_amount numeric,
  effective_from date,
  CONSTRAINT minimum_wage_master_pkey PRIMARY KEY (wage_id),
  CONSTRAINT fk_min_wage_category FOREIGN KEY (employee_category_code) REFERENCES public.employee_category_master(category_code),
  CONSTRAINT fk_min_wage_state FOREIGN KEY (state_code) REFERENCES public.state_master(state_code)
);
CREATE TABLE public.parent_entity (
  entity_id integer NOT NULL DEFAULT nextval('parent_entity_entity_id_seq'::regclass),
  entity_code character varying NOT NULL UNIQUE,
  legal_name character varying,
  entity_type character varying,
  gstin character varying,
  gst_type character varying,
  pan_number character varying,
  cin_number character varying,
  phone character varying,
  email character varying,
  address_line1 character varying,
  address_line2 character varying,
  city character varying,
  pincode character varying,
  state character varying,
  country character varying,
  commission_on_products numeric,
  commission_on_services numeric,
  status character varying,
  entity_role text NOT NULL DEFAULT 'Franchisee',
  CONSTRAINT parent_entity_role_check CHECK (entity_role IN ('Primary', 'Franchisee')),
  CONSTRAINT parent_entity_pkey PRIMARY KEY (entity_id)
);
CREATE UNIQUE INDEX parent_entity_single_primary_uq
  ON public.parent_entity ((lower(entity_role)))
  WHERE lower(entity_role) = 'primary';

CREATE OR REPLACE FUNCTION public.enforce_parent_entity_role_rules()
RETURNS trigger AS $$
BEGIN
  NEW.entity_role := CASE lower(trim(coalesce(NEW.entity_role, '')))
    WHEN 'primary' THEN 'Primary'
    WHEN 'franchisee' THEN 'Franchisee'
    WHEN 'franchaisee' THEN 'Franchisee'
    ELSE NEW.entity_role
  END;

  IF NEW.entity_role NOT IN ('Primary', 'Franchisee') THEN
    RAISE EXCEPTION 'Entity Role must be either Primary or Franchisee.';
  END IF;

  IF NEW.entity_role = 'Primary'
    AND EXISTS (
      SELECT 1
      FROM public.parent_entity
      WHERE entity_role = 'Primary'
        AND entity_id <> COALESCE(NEW.entity_id, -1)
    ) THEN
    RAISE EXCEPTION 'Only one Primary Entity can exist. Add Franchisee entities after the Primary Entity.';
  END IF;

  IF NEW.entity_role = 'Franchisee'
    AND NOT EXISTS (
      SELECT 1
      FROM public.parent_entity
      WHERE entity_role = 'Primary'
        AND entity_id <> COALESCE(NEW.entity_id, -1)
    ) THEN
    RAISE EXCEPTION 'Create the Primary Entity first. After that, only Franchisee entities can be added.';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_parent_entity_role_rules
  BEFORE INSERT OR UPDATE OF entity_role
  ON public.parent_entity
  FOR EACH ROW
  EXECUTE FUNCTION public.enforce_parent_entity_role_rules();
CREATE TABLE public.payroll_compliance (
  compliance_id integer NOT NULL DEFAULT nextval('payroll_compliance_compliance_id_seq'::regclass),
  payroll_run_id integer,
  pf_employee numeric,
  pf_employer numeric,
  esi_employee numeric,
  esi_employer numeric,
  CONSTRAINT payroll_compliance_pkey PRIMARY KEY (compliance_id),
  CONSTRAINT fk_payroll_compliance_run FOREIGN KEY (payroll_run_id) REFERENCES public.payroll_run(payroll_run_id)
);
CREATE TABLE public.payroll_components (
  component_id integer NOT NULL DEFAULT nextval('payroll_components_component_id_seq'::regclass),
  summary_id integer,
  component_type character varying,
  amount numeric,
  CONSTRAINT payroll_components_pkey PRIMARY KEY (component_id),
  CONSTRAINT fk_payroll_components_summary FOREIGN KEY (summary_id) REFERENCES public.payroll_employee_summary(summary_id)
);
CREATE TABLE public.payroll_deductions (
  deduction_id integer NOT NULL DEFAULT nextval('payroll_deductions_deduction_id_seq'::regclass),
  summary_id integer,
  deduction_type character varying,
  amount numeric,
  CONSTRAINT payroll_deductions_pkey PRIMARY KEY (deduction_id),
  CONSTRAINT fk_payroll_deductions_summary FOREIGN KEY (summary_id) REFERENCES public.payroll_employee_summary(summary_id)
);
CREATE TABLE public.payroll_employee_summary (
  summary_id integer NOT NULL DEFAULT nextval('payroll_employee_summary_summary_id_seq'::regclass),
  payroll_run_id integer,
  employee_id integer,
  gross_salary numeric,
  deductions numeric,
  net_salary numeric,
  CONSTRAINT payroll_employee_summary_pkey PRIMARY KEY (summary_id),
  CONSTRAINT fk_payroll_summary_employee FOREIGN KEY (employee_id) REFERENCES public.employee_master(employee_id),
  CONSTRAINT fk_payroll_summary_run FOREIGN KEY (payroll_run_id) REFERENCES public.payroll_run(payroll_run_id)
);
CREATE TABLE public.payroll_period_master (
  period_id integer NOT NULL DEFAULT nextval('payroll_period_master_period_id_seq'::regclass),
  period_code character varying UNIQUE,
  start_date date,
  end_date date,
  payroll_lock_date date,
  status character varying,
  CONSTRAINT payroll_period_master_pkey PRIMARY KEY (period_id)
);
CREATE TABLE public.payroll_run (
  payroll_run_id integer NOT NULL DEFAULT nextval('payroll_run_payroll_run_id_seq'::regclass),
  period_id integer,
  run_date date,
  status character varying,
  CONSTRAINT payroll_run_pkey PRIMARY KEY (payroll_run_id),
  CONSTRAINT fk_payroll_run_period FOREIGN KEY (period_id) REFERENCES public.payroll_period_master(period_id)
);
CREATE TABLE public.policy_assignment (
  assignment_id integer NOT NULL DEFAULT nextval('policy_assignment_assignment_id_seq'::regclass),
  policy_id integer,
  variant_id integer,
  assignment_level character varying,
  target_location_id integer,
  target_department_id integer,
  target_designation_id integer,
  target_gender character varying,
  target_employee_id integer,
  override_direction character varying,
  override_value numeric,
  CONSTRAINT policy_assignment_pkey PRIMARY KEY (assignment_id),
  CONSTRAINT fk_policy_assignment_department FOREIGN KEY (target_department_id) REFERENCES public.department_master(department_id),
  CONSTRAINT fk_policy_assignment_designation FOREIGN KEY (target_designation_id) REFERENCES public.designation_master(designation_id),
  CONSTRAINT fk_policy_assignment_employee FOREIGN KEY (target_employee_id) REFERENCES public.employee_master(employee_id),
  CONSTRAINT fk_policy_assignment_location FOREIGN KEY (target_location_id) REFERENCES public.sub_location(location_id),
  CONSTRAINT fk_policy_assignment_policy FOREIGN KEY (policy_id) REFERENCES public.leave_policy_master(policy_id),
  CONSTRAINT fk_policy_assignment_variant FOREIGN KEY (variant_id) REFERENCES public.policy_variant(variant_id)
);
CREATE TABLE public.policy_variant (
  variant_id integer NOT NULL DEFAULT nextval('policy_variant_variant_id_seq'::regclass),
  policy_id integer,
  variant_code character varying,
  variant_name character varying,
  leave_entitlements jsonb,
  is_default boolean,
  applicable_to character varying,
  status character varying,
  CONSTRAINT policy_variant_pkey PRIMARY KEY (variant_id),
  CONSTRAINT fk_policy_variant_policy FOREIGN KEY (policy_id) REFERENCES public.leave_policy_master(policy_id)
);
CREATE TABLE public.pt_slab_master (
  slab_id integer NOT NULL DEFAULT nextval('pt_slab_master_slab_id_seq'::regclass),
  state_code character varying,
  effective_from date,
  min_salary numeric,
  max_salary numeric,
  pt_amount numeric,
  CONSTRAINT pt_slab_master_pkey PRIMARY KEY (slab_id),
  CONSTRAINT fk_pt_slab_state FOREIGN KEY (state_code) REFERENCES public.state_master(state_code)
);
CREATE TABLE public.role_master (
  role_id integer NOT NULL DEFAULT nextval('role_master_role_id_seq'::regclass),
  role_code character varying UNIQUE,
  role_name character varying,
  permissions jsonb,
  status character varying,
  location_id integer,
  CONSTRAINT role_master_pkey PRIMARY KEY (role_id),
  CONSTRAINT role_master_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.sub_location(location_id)
);
CREATE TABLE public.roster (
  roster_id integer NOT NULL DEFAULT nextval('roster_roster_id_seq'::regclass),
  roster_code character varying UNIQUE,
  location_id integer,
  shift_policy_id integer,
  roster_date date,
  is_holiday boolean,
  is_weekly_off boolean,
  approved_leave_count integer,
  available_staff_count integer,
  scenario character varying,
  effective_open_time time without time zone,
  effective_close_time time without time zone,
  version integer,
  roster_status character varying,
  CONSTRAINT roster_pkey PRIMARY KEY (roster_id),
  CONSTRAINT fk_roster_location FOREIGN KEY (location_id) REFERENCES public.sub_location(location_id),
  CONSTRAINT fk_roster_shift_policy FOREIGN KEY (shift_policy_id) REFERENCES public.shift_policy_master(policy_id)
);
CREATE TABLE public.roster_history (
  history_id integer NOT NULL DEFAULT nextval('roster_history_history_id_seq'::regclass),
  roster_id integer,
  location_id integer,
  roster_date date,
  version integer,
  slots_snapshot jsonb,
  change_reason character varying,
  created_at timestamp without time zone DEFAULT now(),
  action character varying,
  changed_by character varying,
  CONSTRAINT roster_history_pkey PRIMARY KEY (history_id),
  CONSTRAINT fk_roster_history_location FOREIGN KEY (location_id) REFERENCES public.sub_location(location_id),
  CONSTRAINT fk_roster_history_roster FOREIGN KEY (roster_id) REFERENCES public.roster(roster_id)
);
CREATE TABLE public.roster_slots (
  slot_id integer NOT NULL DEFAULT nextval('roster_slots_slot_id_seq'::regclass),
  roster_id integer,
  employee_id integer,
  slot_type character varying,
  is_keyholder boolean,
  slot_start time without time zone,
  slot_end time without time zone,
  preference_applied boolean,
  preference_override boolean,
  slot_status character varying,
  original_employee_id integer,
  CONSTRAINT roster_slots_pkey PRIMARY KEY (slot_id),
  CONSTRAINT fk_roster_slots_employee FOREIGN KEY (employee_id) REFERENCES public.employee_master(employee_id),
  CONSTRAINT fk_roster_slots_original_employee FOREIGN KEY (original_employee_id) REFERENCES public.employee_master(employee_id),
  CONSTRAINT fk_roster_slots_roster FOREIGN KEY (roster_id) REFERENCES public.roster(roster_id)
);
CREATE TABLE public.rosters (
  roster_id integer NOT NULL DEFAULT nextval('rosters_roster_id_seq'::regclass),
  location_id integer NOT NULL,
  start_date date NOT NULL,
  end_date date NOT NULL,
  version character varying NOT NULL DEFAULT 'v1'::character varying,
  status character varying NOT NULL DEFAULT 'Published'::character varying,
  filled_slots integer NOT NULL DEFAULT 0,
  open_slots integer NOT NULL DEFAULT 0,
  conflicts integer NOT NULL DEFAULT 0,
  keyholder_status character varying DEFAULT 'Configured'::character varying,
  roster_data jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT rosters_pkey PRIMARY KEY (roster_id),
  CONSTRAINT rosters_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.sub_location(location_id)
);
CREATE TABLE public.salary_structure_master (
  structure_id integer NOT NULL DEFAULT nextval('salary_structure_master_structure_id_seq'::regclass),
  structure_code character varying UNIQUE,
  grade_code character varying UNIQUE,
  basic_percentage numeric,
  hra_percentage numeric,
  special_allowance_percentage numeric,
  CONSTRAINT salary_structure_master_pkey PRIMARY KEY (structure_id)
);
CREATE TABLE public.service_type_master (
  service_code character varying NOT NULL,
  service_name character varying,
  service_category character varying,
  requires_staff boolean,
  requires_booking boolean,
  linked_department_code character varying,
  linked_department_id integer,
  CONSTRAINT service_type_master_pkey PRIMARY KEY (service_code),
  CONSTRAINT service_type_master_linked_department_id_fkey FOREIGN KEY (linked_department_id) REFERENCES public.department_master(department_id)
);
CREATE TABLE public.shift_exceptions (
  exception_id integer NOT NULL DEFAULT nextval('shift_exceptions_exception_id_seq'::regclass),
  employee_id integer NOT NULL,
  exception_date date NOT NULL,
  shift_id integer,
  exception_type character varying NOT NULL,
  severity character varying DEFAULT 'Open'::character varying,
  expected_in time without time zone,
  actual_in time without time zone,
  expected_out time without time zone,
  actual_out time without time zone,
  resolved_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT shift_exceptions_pkey PRIMARY KEY (exception_id),
  CONSTRAINT shift_exceptions_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.employee_master(employee_id),
  CONSTRAINT shift_exceptions_shift_id_fkey FOREIGN KEY (shift_id) REFERENCES public.shift_policy_master(policy_id)
);
CREATE TABLE public.shift_policy_master (
  policy_id integer NOT NULL DEFAULT nextval('shift_policy_master_policy_id_seq'::regclass),
  policy_code character varying UNIQUE,
  location_id integer,
  policy_name character varying,
  shift_type character varying,
  coverage_mode character varying,
  shift_start_time time without time zone,
  shift_end_time time without time zone,
  total_shift_hours numeric,
  break_duration_minutes integer,
  net_work_hours numeric,
  sanctioned_strength integer,
  max_leave_per_day integer,
  critical_store_flag boolean,
  keyholder_required boolean,
  primary_keyholder_id integer,
  backup_keyholder_id integer,
  roster_auto_generate boolean,
  roster_cycle character varying,
  weekly_off_pattern character varying,
  weekly_off_day smallint,
  max_consecutive_days integer,
  override_authority jsonb,
  holiday_working_policy character varying,
  co_credit_trigger boolean,
  edit_lock_hours integer,
  roster_versioning boolean,
  policy_status character varying,
  shift_category character varying,
  CONSTRAINT shift_policy_master_pkey PRIMARY KEY (policy_id),
  CONSTRAINT fk_shift_policy_backup_keyholder FOREIGN KEY (backup_keyholder_id) REFERENCES public.employee_master(employee_id),
  CONSTRAINT fk_shift_policy_location FOREIGN KEY (location_id) REFERENCES public.sub_location(location_id),
  CONSTRAINT fk_shift_policy_primary_keyholder FOREIGN KEY (primary_keyholder_id) REFERENCES public.employee_master(employee_id)
);
CREATE TABLE public.state_compliance_master (
  compliance_id integer NOT NULL DEFAULT nextval('state_compliance_master_compliance_id_seq'::regclass),
  state_code character varying,
  effective_from date,
  pf_applicable boolean,
  esi_applicable boolean,
  gratuity_applicable boolean,
  CONSTRAINT state_compliance_master_pkey PRIMARY KEY (compliance_id),
  CONSTRAINT fk_state_compliance_state FOREIGN KEY (state_code) REFERENCES public.state_master(state_code)
);
CREATE TABLE public.state_master (
  state_code character varying NOT NULL,
  state_name character varying,
  country_code character varying,
  status character varying,
  created_by integer,
  created_at timestamp without time zone,
  modified_by integer,
  modified_at timestamp without time zone,
  CONSTRAINT state_master_pkey PRIMARY KEY (state_code)
);
CREATE TABLE public.sub_location (
  location_id integer NOT NULL DEFAULT nextval('sub_location_location_id_seq'::regclass),
  location_code character varying UNIQUE,
  parent_entity_id integer,
  location_name character varying,
  brand_flag character varying,
  location_type character varying,
  address_line1 character varying,
  city character varying,
  pincode character varying,
  state character varying,
  state_code character varying,
  latitude numeric,
  longitude numeric,
  phone character varying,
  email character varying,
  cost_centre_code character varying UNIQUE,
  area_manager_id integer,
  onboarding_status character varying,
  status character varying,
  primary_keyholder_id integer,
  backup_keyholder_id integer,
  CONSTRAINT sub_location_pkey PRIMARY KEY (location_id),
  CONSTRAINT fk_sub_location_area_manager FOREIGN KEY (area_manager_id) REFERENCES public.employee_master(employee_id),
  CONSTRAINT fk_sub_location_parent_entity FOREIGN KEY (parent_entity_id) REFERENCES public.parent_entity(entity_id),
  CONSTRAINT fk_sub_location_state FOREIGN KEY (state_code) REFERENCES public.state_master(state_code)
);
