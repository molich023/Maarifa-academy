-- ================================================================
-- FUTUREMINDS ACADEMY — COMPLETE SUPABASE DATABASE SCHEMA
-- Run this entire file in Supabase → SQL Editor → New Query → Run
-- ================================================================

-- Enable UUID extension (usually already enabled)
create extension if not exists "uuid-ossp";

-- ────────────────────────────────────────────────────────────────
-- 1. PROFILES  (student public data, linked to auth.users)
-- ────────────────────────────────────────────────────────────────
create table if not exists public.profiles (
  id            uuid references auth.users(id) on delete cascade primary key,
  full_name     text        not null,
  email         text        not null unique,
  phone         text,
  county        text,
  kcse_year     text,
  situation     text,
  first_course  text,
  referral      text,
  role          text        not null default 'student',   -- 'student' | 'admin'
  points        integer     not null default 0,
  streak        integer     not null default 0,
  last_active   date,
  enrolled_at   timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- RLS
alter table public.profiles enable row level security;

create policy "Students can read own profile"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Students can update own profile"
  on public.profiles for update
  using (auth.uid() = id);

create policy "Admins can read all profiles"
  on public.profiles for select
  using (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid() and p.role = 'admin'
    )
  );

create policy "Service role can do everything on profiles"
  on public.profiles for all
  using (auth.role() = 'service_role');

-- Auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, full_name, email, phone, county, kcse_year, first_course, referral)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    new.email,
    new.raw_user_meta_data->>'phone',
    new.raw_user_meta_data->>'county',
    new.raw_user_meta_data->>'kcse_year',
    new.raw_user_meta_data->>'first_course',
    new.raw_user_meta_data->>'referral'
  );
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();


-- ────────────────────────────────────────────────────────────────
-- 2. COURSES
-- ────────────────────────────────────────────────────────────────
create table if not exists public.courses (
  id          text primary key,    -- 'python-basics', 'ms-excel', etc.
  title       text not null,
  emoji       text not null default '📚',
  category    text not null,       -- 'computer' | 'ai' | 'coding'
  level       text not null default 'Beginner',
  duration    text not null,
  modules     integer not null default 0,
  description text,
  active      boolean not null default true,
  created_at  timestamptz not null default now()
);

alter table public.courses enable row level security;

create policy "Anyone can read active courses"
  on public.courses for select
  using (active = true);

create policy "Admins can manage courses"
  on public.courses for all
  using (
    exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin')
  );

-- Seed courses
insert into public.courses (id, title, emoji, category, level, duration, modules, description) values
  ('ms-word',      'Microsoft Word Mastery',           '📝', 'computer', 'Beginner',     '12 hrs', 8,  'From typing to advanced formatting, mail merge and professional reports.'),
  ('ms-excel',     'Microsoft Excel & Data',           '📊', 'computer', 'Beginner',     '15 hrs', 10, 'Formulas, pivot tables, charts. Excel is used in every business worldwide.'),
  ('ms-powerpoint','PowerPoint & Presentations',       '🖥️', 'computer', 'Beginner',     '8 hrs',  6,  'Design stunning presentations with animations, charts and storytelling.'),
  ('internet-basics','Internet & Digital Literacy',    '🌐', 'computer', 'Beginner',     '6 hrs',  5,  'Email, internet safety, cloud storage, Google Workspace.'),
  ('ai-intro',     'Introduction to AI',               '🤖', 'ai',       'Beginner',     '20 hrs', 10, 'What is AI? Machine learning, neural networks, AI in Africa.'),
  ('ml-basics',    'Machine Learning Fundamentals',    '🧠', 'ai',       'Intermediate', '25 hrs', 12, 'Supervised learning, decision trees, regression, build your first ML model.'),
  ('iot-basics',   'Internet of Things (IoT)',         '📡', 'ai',       'Beginner',     '18 hrs', 9,  'Smart devices, Arduino, Raspberry Pi. Smart agriculture projects.'),
  ('ai-tools',     'AI Tools for Work & Life',         '🛠️', 'ai',       'Beginner',     '10 hrs', 7,  'ChatGPT, Gemini, Midjourney, Canva AI. Be 10x more productive.'),
  ('python-basics','Python Programming',               '🐍', 'coding',   'Beginner',     '30 hrs', 15, 'Variables, loops, functions, and real projects in the world''s most popular language.'),
  ('web-basics',   'Web Development',                  '🌐', 'coding',   'Beginner',     '24 hrs', 12, 'HTML, CSS, JavaScript. Build and deploy your first website from scratch.'),
  ('linux-basics', 'Linux Fundamentals',               '🐧', 'coding',   'Beginner',     '16 hrs', 10, 'Command line, file system, shell scripting. Linux powers 96% of servers.'),
  ('databases',    'Databases & SQL',                  '🗄️', 'coding',   'Intermediate', '14 hrs', 8,  'Store and query data. SQL is the language every developer must know.')
on conflict (id) do nothing;


-- ────────────────────────────────────────────────────────────────
-- 3. MODULES
-- ────────────────────────────────────────────────────────────────
create table if not exists public.modules (
  id          text primary key,          -- 'py-1', 'me-3', etc.
  course_id   text references public.courses(id) on delete cascade not null,
  title       text not null,
  duration    text not null default '20 min',
  sort_order  integer not null default 0,
  video_url   text,
  pdf_url     text
);

alter table public.modules enable row level security;

create policy "Anyone can read modules"
  on public.modules for select using (true);

create policy "Admins can manage modules"
  on public.modules for all
  using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'));


-- ────────────────────────────────────────────────────────────────
-- 4. ENROLLMENTS
-- ────────────────────────────────────────────────────────────────
create table if not exists public.enrollments (
  id           uuid primary key default uuid_generate_v4(),
  student_id   uuid references public.profiles(id) on delete cascade not null,
  course_id    text references public.courses(id) on delete cascade not null,
  progress_pct integer not null default 0 check (progress_pct between 0 and 100),
  enrolled_at  timestamptz not null default now(),
  completed_at timestamptz,
  unique (student_id, course_id)
);

alter table public.enrollments enable row level security;

create policy "Students can read own enrollments"
  on public.enrollments for select
  using (auth.uid() = student_id);

create policy "Students can insert own enrollments"
  on public.enrollments for insert
  with check (auth.uid() = student_id);

create policy "Students can update own enrollments"
  on public.enrollments for update
  using (auth.uid() = student_id);

create policy "Admins can read all enrollments"
  on public.enrollments for select
  using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'));


-- ────────────────────────────────────────────────────────────────
-- 5. MODULE PROGRESS  (which modules has a student completed)
-- ────────────────────────────────────────────────────────────────
create table if not exists public.module_progress (
  id           uuid primary key default uuid_generate_v4(),
  student_id   uuid references public.profiles(id) on delete cascade not null,
  course_id    text references public.courses(id) on delete cascade not null,
  module_id    text references public.modules(id) on delete cascade not null,
  completed_at timestamptz not null default now(),
  unique (student_id, module_id)
);

alter table public.module_progress enable row level security;

create policy "Students can read own module progress"
  on public.module_progress for select
  using (auth.uid() = student_id);

create policy "Students can insert own module progress"
  on public.module_progress for insert
  with check (auth.uid() = student_id);

-- Auto-update enrollment progress when a module is completed
create or replace function public.update_enrollment_progress()
returns trigger as $$
declare
  total_modules integer;
  completed_modules integer;
  pct integer;
begin
  select count(*) into total_modules
    from public.modules where course_id = new.course_id;

  select count(*) into completed_modules
    from public.module_progress
    where student_id = new.student_id and course_id = new.course_id;

  pct := case when total_modules > 0 then (completed_modules * 100 / total_modules) else 0 end;

  update public.enrollments
    set progress_pct = pct,
        completed_at = case when pct = 100 then now() else null end
    where student_id = new.student_id and course_id = new.course_id;

  -- Award points (50 per module)
  update public.profiles set points = points + 50
    where id = new.student_id;

  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_module_completed on public.module_progress;
create trigger on_module_completed
  after insert on public.module_progress
  for each row execute function public.update_enrollment_progress();


-- ────────────────────────────────────────────────────────────────
-- 6. QUIZ ATTEMPTS
-- ────────────────────────────────────────────────────────────────
create table if not exists public.quiz_attempts (
  id           uuid primary key default uuid_generate_v4(),
  student_id   uuid references public.profiles(id) on delete cascade not null,
  course_id    text references public.courses(id) on delete cascade not null,
  quiz_type    text not null default 'module',  -- 'module' | 'final'
  score_pct    integer not null check (score_pct between 0 and 100),
  passed       boolean not null generated always as (score_pct >= 70) stored,
  attempted_at timestamptz not null default now()
);

alter table public.quiz_attempts enable row level security;

create policy "Students can read own quiz attempts"
  on public.quiz_attempts for select
  using (auth.uid() = student_id);

create policy "Students can insert own quiz attempts"
  on public.quiz_attempts for insert
  with check (auth.uid() = student_id);

create policy "Admins can read all quiz attempts"
  on public.quiz_attempts for select
  using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'));


-- ────────────────────────────────────────────────────────────────
-- 7. CERTIFICATES
-- ────────────────────────────────────────────────────────────────
create table if not exists public.certificates (
  id           uuid primary key default uuid_generate_v4(),
  cert_id      text not null unique,   -- 'MAA-2026-PYTHON-A8K2P1'
  student_id   uuid references public.profiles(id) on delete set null,
  student_name text not null,          -- denormalized for display
  course_id    text references public.courses(id) on delete set null,
  course_name  text not null,          -- denormalized for display
  score_pct    integer not null check (score_pct between 0 and 100),
  issued_at    timestamptz not null default now(),
  revoked      boolean not null default false,
  revoked_at   timestamptz
);

alter table public.certificates enable row level security;

-- Anyone can verify (read) certificates by cert_id
create policy "Public can verify certificates"
  on public.certificates for select
  using (revoked = false);

create policy "Admins can manage certificates"
  on public.certificates for all
  using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'));

create policy "Service role full access on certificates"
  on public.certificates for all
  using (auth.role() = 'service_role');

-- Auto-issue certificate when final exam is passed
create or replace function public.auto_issue_certificate()
returns trigger as $$
declare
  s_name text;
  c_name text;
  new_cert_id text;
begin
  if new.quiz_type = 'final' and new.passed = true then
    -- Check not already issued
    if not exists (
      select 1 from public.certificates
      where student_id = new.student_id and course_id = new.course_id and revoked = false
    ) then
      select full_name into s_name from public.profiles where id = new.student_id;
      select title into c_name from public.courses where id = new.course_id;

      -- Generate cert ID: MAA-YEAR-COURSECODE-RANDOM
      new_cert_id := 'MAA-' ||
        extract(year from now())::text || '-' ||
        upper(substring(replace(new.course_id, '-', ''), 1, 6)) || '-' ||
        upper(substring(md5(new.student_id::text || new.course_id || now()::text), 1, 6));

      insert into public.certificates (cert_id, student_id, student_name, course_id, course_name, score_pct)
      values (new_cert_id, new.student_id, s_name, new.course_id, c_name, new.score_pct);

      -- Award bonus points
      update public.profiles set points = points + 500 where id = new.student_id;
    end if;
  end if;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_exam_passed on public.quiz_attempts;
create trigger on_exam_passed
  after insert on public.quiz_attempts
  for each row execute function public.auto_issue_certificate();


-- ────────────────────────────────────────────────────────────────
-- 8. LEADERBOARD VIEW  (real-time computed)
-- ────────────────────────────────────────────────────────────────
create or replace view public.leaderboard as
  select
    p.id,
    p.full_name,
    p.county,
    p.points,
    p.streak,
    count(distinct e.course_id) filter (where e.completed_at is not null) as courses_completed,
    count(distinct e.course_id)                                            as courses_enrolled,
    count(distinct c.id)                                                   as certificates,
    row_number() over (order by p.points desc, p.full_name asc)           as rank
  from public.profiles p
  left join public.enrollments e  on e.student_id = p.id
  left join public.certificates c on c.student_id = p.id and c.revoked = false
  where p.role = 'student'
  group by p.id
  order by p.points desc;

-- ────────────────────────────────────────────────────────────────
-- 9. SEED DEMO CERTIFICATES (for verify page testing)
-- ────────────────────────────────────────────────────────────────
insert into public.certificates (cert_id, student_name, course_id, course_name, score_pct, issued_at)
values
  ('MAA-2026-MSEXCE-A8K2P1', 'Jane Wanjiku Mwangi', 'ms-excel',  'Microsoft Excel & Data Analysis', 88, '2026-03-01 10:00:00+03'),
  ('MAA-2026-DATABA-B9L3Q2', 'Brian Kamau Njoroge', 'databases', 'Databases & SQL',                  92, '2026-02-15 14:30:00+03'),
  ('MAA-2026-PYTHON-C7M4R3', 'Brian Kamau Njoroge', 'python-basics','Python Programming',            74, '2026-03-05 09:00:00+03')
on conflict (cert_id) do nothing;

-- ────────────────────────────────────────────────────────────────
-- 10. STORAGE BUCKETS  (run in Supabase Dashboard → Storage)
-- ────────────────────────────────────────────────────────────────
-- NOTE: Storage cannot be created via SQL. Set up manually:
--
--   Bucket name : materials
--   Public      : YES (for PDF downloads)
--   File size   : 50 MB max
--   MIME types  : application/pdf, application/zip, text/plain
--
--   Bucket name : certificates
--   Public      : YES (for sharing)
--   MIME types  : application/pdf, image/png

-- ────────────────────────────────────────────────────────────────
-- 11. HELPFUL INDEXES
-- ────────────────────────────────────────────────────────────────
create index if not exists idx_enrollments_student    on public.enrollments(student_id);
create index if not exists idx_enrollments_course     on public.enrollments(course_id);
create index if not exists idx_module_progress_student on public.module_progress(student_id, course_id);
create index if not exists idx_quiz_attempts_student  on public.quiz_attempts(student_id, course_id);
create index if not exists idx_certificates_cert_id   on public.certificates(cert_id);
create index if not exists idx_certificates_student   on public.certificates(student_id);
create index if not exists idx_profiles_role          on public.profiles(role);
create index if not exists idx_profiles_points        on public.profiles(points desc);

-- ────────────────────────────────────────────────────────────────
-- DONE! 
-- Next steps:
--   1. Go to Authentication → Settings → Enable Email signup
--   2. Set up Storage buckets (see above)
--   3. Copy Project URL + Anon Key into js/app.js (MA_CONFIG)
--   4. To create your first admin: run this query replacing the UUID:
--      UPDATE profiles SET role = 'admin' WHERE email = 'your@email.com';
-- ────────────────────────────────────────────────────────────────
