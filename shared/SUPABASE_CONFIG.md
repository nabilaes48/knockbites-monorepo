# Shared Supabase Configuration

All KnockBites apps connect to the same Supabase backend.

## Production Credentials

These should be configured in each app's environment:

| Variable | Platform | Location |
|----------|----------|----------|
| `SUPABASE_URL` | Web | `.env.local` |
| `SUPABASE_ANON_KEY` | Web | `.env.local` |
| `SUPABASE_URL` | iOS | `Config/Debug.xcconfig` |
| `SUPABASE_ANON_KEY` | iOS | `Config/Debug.xcconfig` |

## Security Notes

- Never commit actual credentials to the repository
- Use `.xcconfig.example` files as templates
- iOS apps read credentials from Info.plist (injected at build time)
- Web app reads from `import.meta.env.VITE_*` variables

## Shared Schema

All apps use the same database schema. Key tables:

- `stores` - Store locations
- `menu_items` - Menu with prices
- `orders` / `order_items` - Order data
- `customers` - Customer profiles
- `user_profiles` - Staff users

See `web/supabase/migrations/` for full schema.
