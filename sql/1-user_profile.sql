create table public.user_profile (
                                   user_id uuid not null,
                                   name text not null,
                                   constraint user_profile_pkey primary key (user_id),
                                   constraint user_profile_user_id_fkey foreign KEY (user_id) references auth.users (id) on delete CASCADE
) TABLESPACE pg_default;
