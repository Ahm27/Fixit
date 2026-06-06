# FixIt Flutter Marketplace

Flutter implementation of FixIt with two account roles:

- `customer`: books services, tracks bookings, chats, and manages profile
- `worker`: signs up with trade details, manages requests, tracks earnings, and chats with customers

The app runs in demo mode without credentials and can connect to Supabase through runtime Dart defines.

## What Is Included

- Shared auth flow with role switching for sign in and sign up
- Customer app shell:
  - Home
  - Multi-step booking flow
  - Bookings
  - Messages
  - Profile
- Worker app shell:
  - Requests
  - Earnings
  - Messages
- In-app notifications
- Request image upload
- Worker directory and worker selection
- Request detail/tracking screen
- Realtime refresh hooks for requests, threads, messages, and notifications
- Supabase integration points for:
  - Auth
  - Profiles
  - Worker details
  - Service requests
  - Message threads
  - Messages
- Demo mode with seeded data so the UI works before backend keys are added

## Project Structure

- `lib/src/screens/auth`: shared customer and worker auth UI
- `lib/src/screens/home`: customer shell, worker shell, and shared chat
- `lib/src/services/app_controller.dart`: app state, role routing, demo data, and Supabase operations
- `lib/src/models`: account, request, earnings, and chat models
- `supabase/schema.sql`: schema and RLS policies expected by the app

## Run In Demo Mode

```bash
flutter pub get
flutter run --dart-define=FIXIT_DEMO_MODE=true
```

## Run With Supabase

1. Create a Supabase project.
2. Run the SQL in `supabase/schema.sql`.
3. For easiest testing, disable email confirmation in your Supabase auth settings.
4. Make sure the `avatars` and `request-images` storage buckets exist. The schema file creates them if your project allows storage SQL writes.
5. Start the app with your project values. Do not commit real credentials:

```bash
flutter run \
  --dart-define=SUPABASE_URL=YOUR_SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

6. Deploy the chat Edge Function if chat messages should create notifications:

```bash
supabase functions deploy send-chat-message
```

## Role Behavior

### Customer

- Creates service requests
- Chooses a worker or leaves the request open for auto matching
- Uploads a request image
- Sees active and historical bookings
- Tracks request status in a dedicated details screen
- Chats inside request threads
- Receives notifications for request changes and new messages
- Views profile info

### Worker

- Signs up with:
  - full name
  - email
  - password
  - phone
  - city
  - service category
  - years of experience
  - national ID
  - hourly rate
  - bio
- Toggles availability
- Accepts and progresses requests
- Tracks earnings from completed jobs
- Chats with customers
- Receives notifications for new requests, messages, and earnings updates

## Verification

```bash
flutter analyze
flutter test
```
