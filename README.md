# KnockBites Monorepo

Multi-platform food ordering system for KnockBites stores across New York.

## Structure

```
KnockBites-Monorepo/
├── web/           # React + TypeScript web app (customer ordering & staff dashboard)
├── ios/
│   ├── customer/  # iOS Customer app (SwiftUI)
│   └── business/  # iOS Business app (SwiftUI)
└── shared/        # Shared configuration and documentation
```

## Platforms

| Platform | Tech Stack | Purpose |
|----------|------------|---------|
| Web | React 18 + TypeScript + Vite + Tailwind | Customer ordering & staff dashboard |
| iOS Customer | SwiftUI + Supabase SDK | Mobile ordering app |
| iOS Business | SwiftUI + Supabase SDK | Staff order management & analytics |

## Quick Start

### Web App

```bash
cd web
npm install
npm run dev
```

### iOS Apps

1. Open `ios/customer/camerons-customer-app.xcodeproj` in Xcode
2. Copy `Config/Debug.xcconfig.example` to `Config/Debug.xcconfig`
3. Add your Supabase credentials
4. Build and run

## Backend

All apps share a single Supabase backend:
- PostgreSQL database with RLS policies
- Real-time subscriptions for order updates
- Edge Functions for secure server-side logic
- Storage for menu images

## Environment Setup

### Supabase Credentials

Web app: Copy `.env.example` to `.env.local` in `/web`
iOS apps: Copy `Debug.xcconfig.example` to `Debug.xcconfig` in each app's `Config/` folder

## Documentation

- Web: See `web/docs/` for architecture and API docs
- iOS: See `CLAUDE.md` in each iOS app folder
