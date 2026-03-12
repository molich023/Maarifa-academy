# Maarifa Academy 🚀
**Free world-class tech education for Kenyan youth.**

---

## 📁 Project Structure

```
futureminds/
├── index.html                  ← Homepage (landing page)
├── netlify.toml                ← Netlify deploy config + security headers
├── schema.sql                  ← Full Supabase database schema
├── README.md                   ← This file
├── css/
│   └── main.css                ← Complete design system
├── js/
│   └── app.js                  ← Supabase client, COURSES data, utilities
└── pages/
    ├── enroll.html             ← 3-step enrollment form
    ├── student-portal.html     ← Full student dashboard
    ├── course.html             ← Course viewer + quiz engine
    ├── admin.html              ← Admin panel
    └── verify-certificate.html ← Public certificate verification
```

---

## 🚀 Deploy to Netlify (3 minutes)

### Option A — Drag & Drop (fastest)
1. Zip the entire `futureminds/` folder
2. Go to **app.netlify.com → Add new site → Deploy manually**
3. Drag the zip file onto the upload area
4. Done! Your site is live.

### Option B — GitHub (recommended for updates)
1. Push `futureminds/` to a GitHub repo:
   ```bash
   git init && git add . && git commit -m "Maarifa Academy"
   git remote add origin https://github.com/molich023/maarifa.git
   git push -u origin main
   ```
2. Connect the repo in Netlify → **Add new site → Import from Git**
3. Build settings: **Publish directory = `.`** (leave build command blank)
4. Deploy!

---

## 🗄️ Supabase Setup (10 minutes)

### Step 1: Create Project
1. Go to **supabase.com** → New Project
2. Name it `futureminds-academy`
3. Choose a strong database password and save it
4. Select region: **Europe West** (closest to Kenya with good latency)

### Step 2: Run Schema
1. In Supabase → **SQL Editor → New Query**
2. Paste the entire contents of `schema.sql`
3. Click **Run** — all 11 tables, triggers, policies, and seed data created

### Step 3: Get Your Keys
1. Go to **Project Settings → API**
2. Copy **Project URL** and **anon public** key

### Step 4: Configure the Site
Open `js/app.js` and replace:
```js
const MA_CONFIG = {
  supabaseUrl:  'https://YOUR_PROJECT_ID.supabase.co',  // ← paste here
  supabaseKey:  'YOUR_ANON_KEY_HERE',                   // ← paste here
  ...
};
```

### Step 5: Enable Auth
1. Supabase → **Authentication → Settings**
2. Enable **Email** provider
3. Set **Site URL** to your Netlify URL (e.g. `https://maarifaacademy.netlify.app`)
4. Add Netlify URL to **Redirect URLs**

### Step 6: Create Your Admin Account
1. Enroll on the site with your real email
2. In Supabase → SQL Editor, run:
   ```sql
   UPDATE profiles SET role = 'admin' WHERE email = 'your@email.com';
   ```
3. You can now log in at `/pages/admin.html`

### Step 7: Storage (for PDF downloads)
1. Supabase → **Storage → New bucket**
2. Name: `materials` · Public: **Yes**
3. Upload your PDF study guides into this bucket
4. Update download links in `pages/course.html`

---

## 📞 Contact Information
- **Phone:** 0704-658022
- **Email:** molich60@gmail.com
- **GitHub:** github.com/molich023/maarifa

---

## 🎓 Courses Available (12 total, all free)

| Category | Course | Modules | Duration |
|---|---|---|---|
| 💻 Computer | MS Word | 8 | 12 hrs |
| 💻 Computer | MS Excel | 10 | 15 hrs |
| 💻 Computer | PowerPoint | 6 | 8 hrs |
| 💻 Computer | Internet & Digital Literacy | 5 | 6 hrs |
| 🤖 AI | Introduction to AI | 10 | 20 hrs |
| 🤖 AI | Machine Learning Fundamentals | 12 | 25 hrs |
| 🤖 AI | Internet of Things (IoT) | 9 | 18 hrs |
| 🤖 AI | AI Tools for Work | 7 | 10 hrs |
| 🐍 Coding | Python Programming | 15 | 30 hrs |
| 🐍 Coding | Web Development | 12 | 24 hrs |
| 🐍 Coding | Linux Fundamentals | 10 | 16 hrs |
| 🐍 Coding | Databases & SQL | 8 | 14 hrs |

---

## 🔐 Demo Credentials

| Role | Email | Password |
|---|---|---|
| Student | jane@demo.com | demo1234 |
| Admin | Randy.voti@owasp.org | admin123 |

**Demo Certificate IDs (for verification page):**
- `MAA-2026-MSEXCE-A8K2P1` — Jane W., Excel, 88%
- `MAA-2026-DATABA-B9L3Q2` — Brian K., SQL, 92%
- `MAA-2026-PYTHON-C7M4R3` — Brian K., Python, 74%

---

## ✅ Feature Checklist

### Working (fully functional)
- [x] Homepage with animated hero, stats, course tabs
- [x] 3-step enrollment form with validation
- [x] Student portal with login + demo mode
- [x] Dashboard: metrics, enrolled courses, streak, achievements
- [x] All courses browser (all 12)
- [x] Course viewer with module sidebar, video player, lesson content
- [x] Full quiz engine (5-question, scored, pass/fail)
- [x] Final exam (pass at 70%)
- [x] Certificate generator with unique IDs
- [x] Certificate verification (public, no login needed)
- [x] Progress tracker with activity chart
- [x] Leaderboard
- [x] Free resources links (8 platforms)
- [x] Downloads list
- [x] Admin panel (students, courses, enrollments, certs, quiz results)
- [x] Netlify deploy config with security headers
- [x] Full Supabase schema (8 tables, triggers, RLS policies)
- [x] Mobile responsive on all pages

### Needs Supabase to activate
- [ ] Real user accounts (sign up / sign in)
- [ ] Cloud progress sync across devices  
- [ ] Real leaderboard from live data
- [ ] PDF download from Storage
- [ ] Certificate PDF generation (server-side)
- [ ] Email notifications

---

## 🛠️ Tech Stack
- **Frontend:** Vanilla HTML5 + CSS3 + JavaScript (ES2020)
- **Fonts:** Syne · Space Grotesk · JetBrains Mono (Google Fonts)
- **Auth & Database:** Supabase (PostgreSQL + Auth + Storage)
- **Hosting:** Netlify (free tier)
- **No frameworks** — pure HTML/CSS/JS = loads fast on 3G in Kenya
