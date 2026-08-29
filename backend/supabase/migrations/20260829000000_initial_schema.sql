-- Initial schema for the Life Achievement App ("Stones"), matching
-- docs/domain-model.md v0.1.
--
-- Four owned tables, per domain-model.md §0/§1/§3/§4:
--   1. quest_chains                 — chain-level metadata: a chain's own
--                                     name/description (public read)
--   2. achievement_definitions      — the shared catalog (public read)
--   3. user_achievement_instances   — one row per (user, definition), the
--                                     state machine + verification state
--                                     (private to owner)
--   4. xp_ledger                    — append-only XP grants/reversals
--                                     (private to owner)
--
-- RLS defaults to private (no public access) except quest_chains and
-- achievement_definitions, which are shared catalog content readable by
-- any authenticated user.
--
-- NOTE: this migration is hand-written in a session with no access to the
-- founder's actual Supabase project. Reconcile against a real
-- `supabase init` / `supabase link` before treating it as final — see the
-- delivery report.

-- =========================================================================
-- Enum types (mirroring the Swift enums in LifeAchievementCore 1:1)
-- =========================================================================

create type achievement_category as enum (
    'fitness',
    'adventure',
    'travel',
    'money',
    'career',
    'education',
    'skills',
    'relationships',
    'makerProjects',
    'experiences',
    'general'
);

create type achievement_source as enum (
    'builtIn',
    'userCreated',
    'aiGenerated',
    'integrationDetected'
);

create type rarity_label as enum (
    'common',
    'uncommon',
    'rare',
    'epic',
    'legendary'
);

-- notDiscovered is intentionally excluded: it has no database row
-- (domain-model.md §1.4's implicit-state rule) and must never be written.
create type achievement_state as enum (
    'discovered',
    'interested',
    'active',
    'completed',
    'paused',
    'abandoned'
);

create type quest_slot_type as enum (
    'none',
    'main',
    'side'
);

create type verification_level as enum (
    'selfReported',
    'evidence',
    'verified'
);

-- =========================================================================
-- quest_chains — chain-level metadata (domain-model.md §4)
-- =========================================================================
--
-- `achievement_definitions.quest_chain_id` has always been a bare grouping
-- UUID shared by a chain's rungs, with nothing storing the chain's own
-- display name/description (e.g. "5K Questline") — needed for the
-- achievement-detail screen's "Part of the 5K Questline · Step 3 of 6"
-- (docs/wireframes.md). This table is shared catalog content, same as
-- achievement_definitions' built-in rows: hand-authored, not user-editable.

create table quest_chains (
    id uuid primary key,
    name text not null,
    description text not null default '',
    -- A chain lives in exactly one category, matching all of its rungs.
    category achievement_category not null,
    created_at timestamptz not null default now()
);

-- =========================================================================
-- achievement_definitions — the shared catalog (domain-model.md §1.1)
-- =========================================================================

create table achievement_definitions (
    id uuid primary key default gen_random_uuid(),
    name text not null,
    category achievement_category not null,
    description text not null default '',
    -- {"type": "binary"}
    -- {"type": "cumulativeCount", "targetValue": number, "unit": string}
    -- {"type": "thresholdRecord", "targetValue": number, "unit": string, "comparisonDirection": "atLeast" | "atMost"}
    completion_criteria jsonb not null,
    -- Discrete XP band values only — domain-model.md §3.1. This is a hard
    -- rule for seed-content authors and future admin tooling, not a
    -- suggestion.
    xp_value integer not null,
    quest_chain_id uuid null references quest_chains (id) on delete restrict,
    quest_chain_position integer null,
    -- Design-time-only placeholder for seed content (§5). Never confused
    -- with computed rarity, which is a backend aggregate over
    -- user_achievement_instances, not stored on the definition.
    provisional_rarity rarity_label null,
    is_secret boolean not null default false,
    source achievement_source not null,
    creator_user_id uuid null references auth.users (id) on delete set null,
    created_at timestamptz not null default now(),

    constraint achievement_definitions_xp_value_is_banded check (
        xp_value = any (array[
            10, 15, 20, 25, 30, 40, 50,
            100, 150, 200, 250, 300, 400, 500,
            750, 1000, 1500, 2000, 2500,
            5000, 7500, 10000
        ])
    ),

    constraint achievement_definitions_quest_chain_fields_paired check (
        (quest_chain_id is null and quest_chain_position is null)
        or (quest_chain_id is not null and quest_chain_position is not null and quest_chain_position >= 1)
    ),

    constraint achievement_definitions_creator_matches_source check (
        (source = 'userCreated' and creator_user_id is not null)
        or (source <> 'userCreated' and creator_user_id is null)
    ),

    constraint achievement_definitions_completion_criteria_shape check (
        (completion_criteria ->> 'type' = 'binary')
        or (
            completion_criteria ->> 'type' = 'cumulativeCount'
            and completion_criteria ? 'targetValue'
            and completion_criteria ? 'unit'
        )
        or (
            completion_criteria ->> 'type' = 'thresholdRecord'
            and completion_criteria ? 'targetValue'
            and completion_criteria ? 'unit'
            and completion_criteria ->> 'comparisonDirection' in ('atLeast', 'atMost')
        )
    )
);

-- Each chain rung occupies exactly one position within its chain.
create unique index achievement_definitions_chain_position_uidx
    on achievement_definitions (quest_chain_id, quest_chain_position)
    where quest_chain_id is not null;

create index achievement_definitions_category_idx on achievement_definitions (category);
create index achievement_definitions_quest_chain_id_idx on achievement_definitions (quest_chain_id) where quest_chain_id is not null;
create index achievement_definitions_creator_user_id_idx on achievement_definitions (creator_user_id) where creator_user_id is not null;

-- =========================================================================
-- user_achievement_instances — per-user state (domain-model.md §1.2)
-- =========================================================================

create table user_achievement_instances (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users (id) on delete cascade,
    achievement_definition_id uuid not null references achievement_definitions (id) on delete cascade,
    state achievement_state not null,
    quest_slot_type quest_slot_type not null default 'none',
    verification_level verification_level not null default 'selfReported',
    evidence_ref text null,
    progress_value double precision null,
    is_hidden_from_profile boolean not null default false,
    discovered_at timestamptz null,
    activated_at timestamptz null,
    completed_at timestamptz null,
    -- FK to xp_ledger added below via ALTER, after xp_ledger exists
    -- (the two tables reference each other).
    xp_ledger_entry_id uuid null,

    -- One instance row per (user, achievement) pair, created lazily on
    -- first real discovery event (§1.4) — never one row per user per
    -- catalog item up front.
    constraint user_achievement_instances_unique_per_user unique (user_id, achievement_definition_id)
);

create index user_achievement_instances_user_id_idx on user_achievement_instances (user_id);
create index user_achievement_instances_definition_id_idx on user_achievement_instances (achievement_definition_id);
-- Supports the quest-slot cap queries (§6): count active Main/Side quests per user.
create index user_achievement_instances_active_slots_idx
    on user_achievement_instances (user_id, quest_slot_type)
    where state = 'active' and quest_slot_type <> 'none';

-- =========================================================================
-- xp_ledger — append-only XP grants/reversals (domain-model.md §3)
-- =========================================================================

create table xp_ledger (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users (id) on delete cascade,
    category achievement_category not null,
    -- Positive for a grant, negative for a reversal. Never zero.
    amount integer not null,
    achievement_definition_id uuid null references achievement_definitions (id) on delete set null,
    user_achievement_instance_id uuid null references user_achievement_instances (id) on delete set null,
    granted_at timestamptz not null default now(),
    -- Set only on a reversal row; points at the original grant it
    -- reverses. A reversal is a new row, never an update to the original
    -- — see the immutability trigger below.
    reversal_of_entry_id uuid null references xp_ledger (id) on delete restrict,

    constraint xp_ledger_amount_nonzero check (amount <> 0),
    constraint xp_ledger_no_self_reversal check (reversal_of_entry_id is distinct from id)
);

create index xp_ledger_user_id_idx on xp_ledger (user_id);
create index xp_ledger_user_category_idx on xp_ledger (user_id, category);
create index xp_ledger_reversal_of_idx on xp_ledger (reversal_of_entry_id) where reversal_of_entry_id is not null;

-- Now that xp_ledger exists, wire up the FK from user_achievement_instances.
alter table user_achievement_instances
    add constraint user_achievement_instances_xp_ledger_entry_fkey
    foreign key (xp_ledger_entry_id) references xp_ledger (id) on delete set null;

-- A row can be reversed at most once (mirrors LifeAchievementCore's
-- XPLedger.reverse, which rejects a second reversal of the same entry).
create unique index xp_ledger_reversal_of_entry_uidx
    on xp_ledger (reversal_of_entry_id)
    where reversal_of_entry_id is not null;

-- Enforce true append-only-ness at the database level, not just via RLS
-- (RLS doesn't constrain privileged roles). "An append-only per-user XP
-- ledger... one immutable row per grant" (domain-model.md §3.4) is a hard
-- invariant, not a suggestion.
create or replace function xp_ledger_forbid_mutation()
returns trigger
language plpgsql
as $$
begin
    raise exception 'xp_ledger is append-only: % is not permitted', tg_op;
end;
$$;

create trigger xp_ledger_forbid_update
    before update on xp_ledger
    for each row execute function xp_ledger_forbid_mutation();

create trigger xp_ledger_forbid_delete
    before delete on xp_ledger
    for each row execute function xp_ledger_forbid_mutation();

-- =========================================================================
-- Row Level Security
-- =========================================================================

alter table quest_chains enable row level security;
alter table achievement_definitions enable row level security;
alter table user_achievement_instances enable row level security;
alter table xp_ledger enable row level security;

-- quest_chains: shared catalog content, same treatment as the built-in
-- achievement_definitions rows — public read for any authenticated user,
-- no insert/update/delete policy at all. Chains are hand-authored (only
-- built-in for now), same as achievement_definitions' built-in rows; there
-- is no user-facing "create your own chain" feature yet.
create policy quest_chains_select_authenticated
    on quest_chains
    for select
    to authenticated
    using (true);

-- achievement_definitions: built-in/AI-generated/integration-detected rows
-- are shared catalog content, publicly readable by any authenticated user
-- (constitution: this is shared content, not private user data).
-- userCreated rows are personal content the constitution treats as
-- private by default (a user's own goal, not yet a public library
-- addition) — visible only to their creator until a future
-- share-with-friends/community-library feature explicitly changes that.
create policy achievement_definitions_select_authenticated
    on achievement_definitions
    for select
    to authenticated
    using (
        source <> 'userCreated'
        or creator_user_id = auth.uid()
    );

-- Users may create their own achievement definitions...
create policy achievement_definitions_insert_own_user_created
    on achievement_definitions
    for insert
    to authenticated
    with check (
        source = 'userCreated'
        and creator_user_id = auth.uid()
    );

-- ...and may edit or delete only what they created. Built-in / AI-
-- generated / integration-detected catalog content is never user-editable.
create policy achievement_definitions_update_own_user_created
    on achievement_definitions
    for update
    to authenticated
    using (source = 'userCreated' and creator_user_id = auth.uid())
    with check (source = 'userCreated' and creator_user_id = auth.uid());

create policy achievement_definitions_delete_own_user_created
    on achievement_definitions
    for delete
    to authenticated
    using (source = 'userCreated' and creator_user_id = auth.uid());

-- user_achievement_instances: private to the owning user. No public or
-- friend-level access yet — profile/trophy-case sharing is out of scope
-- for M0 (architecture.md); the default must be private, not public.
create policy user_achievement_instances_owner_select
    on user_achievement_instances
    for select
    to authenticated
    using (auth.uid() = user_id);

create policy user_achievement_instances_owner_insert
    on user_achievement_instances
    for insert
    to authenticated
    with check (auth.uid() = user_id);

create policy user_achievement_instances_owner_update
    on user_achievement_instances
    for update
    to authenticated
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

create policy user_achievement_instances_owner_delete
    on user_achievement_instances
    for delete
    to authenticated
    using (auth.uid() = user_id);

-- xp_ledger: private to the owning user. Grants are inserted by the
-- owner (via the app, at completion time); no update/delete policy is
-- defined at all — combined with the triggers above, this makes the
-- ledger genuinely append-only rather than merely "append-only by
-- convention."
create policy xp_ledger_owner_select
    on xp_ledger
    for select
    to authenticated
    using (auth.uid() = user_id);

create policy xp_ledger_owner_insert
    on xp_ledger
    for insert
    to authenticated
    with check (auth.uid() = user_id);
