# CampusSpace

Aplikasi web pribadi untuk mengelola kuliah: absensi, tugas, materi, catatan, nilai, dan semester.

## Teknologi
- React + Vite
- Supabase Auth, Postgres, dan Storage
- Netlify untuk hosting

## 1. Siapkan Supabase
1. Buat project Supabase baru khusus CampusSpace.
2. Buka **SQL Editor → New query**.
3. Salin seluruh isi `supabase.sql`, lalu klik **Run**.
4. Buka **Project Settings → API** (atau Connect) dan salin Project URL serta publishable/anon key.
5. Di Authentication → URL Configuration, tambahkan URL website Netlify ke Site URL dan Redirect URLs setelah deploy.

## 2. Upload ke GitHub
1. Ekstrak ZIP ini di komputer.
2. Buat repository GitHub baru bernama `campusspace`.
3. Upload seluruh isi folder project ke root repository (pastikan `package.json`, `index.html`, `netlify.toml`, `supabase.sql`, dan folder `src` ada di root).
4. Jangan upload file `.env` yang berisi kredensial.

## 3. Deploy ke Netlify
1. Netlify → Add new site → Import an existing project.
2. Pilih repository `campusspace`.
3. Build command: `npm run build`
4. Publish directory: `dist`
5. Tambahkan Environment variables:
   - `VITE_SUPABASE_URL` = Project URL Supabase
   - `VITE_SUPABASE_ANON_KEY` = publishable/anon key Supabase
6. Deploy site.

## 4. Daftar dan mulai pakai
1. Buka website.
2. Daftar dengan email dan password.
3. Jika Supabase meminta verifikasi email, buka email dan verifikasi.
4. Masuk, lalu tambahkan mata kuliah dari menu **Mata Kuliah**.
5. Buka mata kuliah untuk mengelola absensi, tugas, materi, catatan, dan nilai.

## Catatan keamanan
- Jangan gunakan `service_role` key di frontend.
- Database menggunakan Row Level Security; tiap akun hanya dapat mengakses data miliknya sendiri.
- File disimpan di bucket privat dan hanya dapat diakses oleh pemilik yang login.
- Batas file 20 MB per file.
- Penghitungan absensi menganggap status **Alpa** dan **Izin** sebagai tidak hadir yang memakai toleransi; **Sakit** dan **Hadir** tidak mengurangi toleransi. Sesuaikan kebijakan kampus/dosen jika berbeda.
- Versi awal ini belum mengirim notifikasi push/email otomatis; deadline dan peringatan tampil di dalam aplikasi.
