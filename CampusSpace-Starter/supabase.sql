-- CampusSpace database setup
-- Jalankan seluruh SQL ini di Supabase > SQL Editor > New query.
-- Gunakan publishable/anon key di frontend. JANGAN pernah masukkan service_role key ke frontend.

create extension if not exists pgcrypto;

create table if not exists public.semesters (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null default 'Semester 5',
  start_date date,
  end_date date,
  absence_limit integer not null default 3 check (absence_limit >= 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.courses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  semester_id uuid references public.semesters(id) on delete set null,
  name text not null,
  lecturer text,
  room text,
  day_of_week integer check (day_of_week between 0 and 6),
  start_time time,
  end_time time,
  color text not null default '#702d43',
  created_at timestamptz not null default now()
);

create table if not exists public.attendance (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  course_id uuid not null references public.courses(id) on delete cascade,
  meeting_date date not null,
  status text not null check (status in ('present','absent','excused','sick')),
  meeting_number integer,
  note text,
  created_at timestamptz not null default now(),
  unique (user_id, course_id, meeting_date)
);

create table if not exists public.tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  course_id uuid not null references public.courses(id) on delete cascade,
  title text not null,
  description text,
  due_date date,
  priority text not null default 'medium' check (priority in ('low','medium','high')),
  status text not null default 'todo' check (status in ('todo','doing','done','submitted')),
  attachment_path text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.materials (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  course_id uuid not null references public.courses(id) on delete cascade,
  title text not null,
  description text,
  meeting_number integer,
  material_date date,
  file_name text not null,
  file_path text not null,
  mime_type text,
  created_at timestamptz not null default now()
);

create table if not exists public.notes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  course_id uuid not null references public.courses(id) on delete cascade,
  title text not null,
  content text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.grades (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  course_id uuid not null references public.courses(id) on delete cascade,
  title text not null,
  score numeric(5,2) check (score between 0 and 100),
  weight numeric(5,2) check (weight between 0 and 100),
  note text,
  created_at timestamptz not null default now()
);

create index if not exists courses_user_semester_idx on public.courses(user_id, semester_id);
create index if not exists attendance_course_date_idx on public.attendance(course_id, meeting_date desc);
create index if not exists tasks_course_due_idx on public.tasks(course_id, due_date);
create index if not exists materials_course_meeting_idx on public.materials(course_id, meeting_number);

alter table public.semesters enable row level security;
alter table public.courses enable row level security;
alter table public.attendance enable row level security;
alter table public.tasks enable row level security;
alter table public.materials enable row level security;
alter table public.notes enable row level security;
alter table public.grades enable row level security;

-- Owner-only policies. Drop/recreate names so this script can be rerun.
do $$
declare t text;
begin
  foreach t in array array['semesters','courses','attendance','tasks','materials','notes','grades']
  loop
    execute format('drop policy if exists "Users manage own %s" on public.%I', t, t);
    execute format('create policy "Users manage own %s" on public.%I for all to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id)', t, t);
  end loop;
end $$;

-- Private storage bucket for lecture materials and task files.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'campus-files',
  'campus-files',
  false,
  20971520,
  array[
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-powerpoint',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'image/jpeg',
    'image/png',
    'image/webp'
  ]
)
on conflict (id) do update set
  public = false,
  file_size_limit = 20971520,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Users access own campus files" on storage.objects;
create policy "Users access own campus files"
on storage.objects for all to authenticated
using (
  bucket_id = 'campus-files'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'campus-files'
  and (storage.foldername(name))[1] = auth.uid()::text
);
