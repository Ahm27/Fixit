# FixIt Feature Documentation

## Product Overview

FixIt is a mobile-first home services marketplace app that helps users book technicians for household repair and maintenance jobs. The current implementation is focused on the customer experience, from onboarding through booking, status tracking, messaging, and profile management.

The app is built as a single-screen mobile shell with React Router-based navigation and bilingual support for English and Arabic.

## Primary User Journey

The currently wired customer journey in the source code is:

1. Splash screen
2. Onboarding
3. Sign up or log in
4. Home service catalog
5. Service selection
6. Technician list
7. Booking review
8. Booking success
9. Request tracking

Users can also access profile, booking history, active bookings, and messages from the main navigation.

## Core Features

### 1. Onboarding and Entry Flow

- Branded splash screen for app entry
- Introductory onboarding screen highlighting trust, speed, and affordability
- Guided CTA into account creation

## 2. Authentication and User Setup

- Sign up form with:
  - Full name
  - Email
  - Phone number
  - Password
  - Optional profile photo upload
- Login form for returning users
- Local user session state stored in React context

## 3. Bilingual Experience

- English and Arabic language support
- Runtime language toggle on major screens
- RTL layout support via the mobile container
- Shared translation dictionary for core UI labels and booking states

## 4. Home and Service Discovery

- Home dashboard listing service categories as tappable cards
- Current service categories:
  - Plumbing
  - Carpentry
  - Electrical
  - Painting
  - AC Repair
  - Appliance Repair
- Drawer/sidebar access to key areas:
  - Home
  - Bookings
  - Messages
  - Profile
  - Settings entry point

## 5. Service Request Setup

- Service-specific selection screen
- Users can:
  - Choose a sub-service
  - Enter a short problem description
  - Choose preferred timing between today and tomorrow

Current implemented sub-services are plumbing-focused:

- Fix Leak
- Install Faucet
- Full Maintenance
- Pipe Replacement
- Toilet Repair
- Water Heater Service
- Other

## 6. Technician Discovery and Selection

- List of available technicians
- Selection-based comparison UI
- Technician cards display:
  - Name
  - Verification badge
  - Trade/specialty label
  - Rating
  - Experience
  - Starting price
- Informational note encouraging users to compare profiles and pricing

## 7. Booking Review

- Service summary screen before submission
- Reviewable fields include:
  - Category
  - Service type
  - Description
  - Preferred time
  - Address
- Estimated price range shown before confirmation
- Messaging indicates that final price may vary after inspection

## 8. Payment

- A payment screen exists in the app with two payment options:
  - Pay Online
  - Cash on Delivery
- Booking confirmation CTA is present

Note: this screen is implemented as a route, but it is not part of the currently connected primary booking flow.

## 9. Booking Confirmation and Success

- Success screen after booking submission
- Confirmation messaging
- CTA to track request
- CTA to return home

## 10. Request Tracking

- Live-style booking tracking screen
- Technician card includes:
  - Name
  - Profession
  - Rating
  - Call action
- Visit details include:
  - Service address
  - Estimated arrival time
- Multi-step service progress timeline:
  - Request Submitted
  - Technician Assigned
  - On the way
  - In Progress
  - Completed

## 11. Active Bookings

- Dedicated screen for ongoing service requests
- Each active booking shows:
  - Service title
  - Assigned technician
  - Booking status
  - Service location
  - Estimated arrival
- Available actions:
  - Track request
  - Call technician

Supported active-booking statuses in the UI:

- Technician Assigned
- On the Way
- In Progress

## 12. Booking History

- Historical bookings list
- Each item includes:
  - Service type
  - Technician name
  - Booking date
  - Final cost
  - Status badge

Implemented status badges:

- Completed
- Cancelled

## 13. Messaging

- Conversation list screen
- Search bar for messages
- Unread badge support in the conversation list
- Chat thread screen with:
  - Technician header
  - Online status
  - Message bubbles for user and technician
  - Text input
  - Send action

## 14. Profile and Account Management

- Profile overview card with:
  - User photo
  - Name
  - Email
  - Phone number
- In-profile photo update
- Quick access to:
  - Active bookings
  - Booking history
  - Notifications
  - Language
  - Help and support
- Logout action

## 15. Mobile-First Navigation

- Bottom navigation for:
  - Home
  - Bookings
  - Messages
  - Profile
- Sidebar navigation from the home screen
- UI is constrained to a mobile viewport container for app-like presentation

## Screen Inventory

| Route | Screen | Purpose |
| --- | --- | --- |
| `/` | Splash | Branded app entry |
| `/onboarding` | Onboarding | Intro and conversion to signup |
| `/signup` | Signup | New account creation |
| `/login` | Login | Existing user sign-in |
| `/home` | Home | Service discovery dashboard |
| `/service/:serviceId` | Service Selection | Sub-service and problem setup |
| `/request/:serviceId` | Request Form | Detailed request capture |
| `/technicians/:serviceId` | Technician List | Technician comparison and selection |
| `/technician/:technicianId` | Technician Details | Detailed technician profile |
| `/booking-review` | Booking Review | Booking summary and estimated pricing |
| `/payment` | Payment | Payment method selection |
| `/success` | Success | Booking confirmation |
| `/tracking` | Tracking | Service progress tracking |
| `/profile` | Profile | User account hub |
| `/booking-history` | Booking History | Past bookings |
| `/active-bookings` | Active Bookings | Ongoing services |
| `/messages` | Messages | Chat and conversation list |

## Included But Not Fully Wired Into the Main Flow

The codebase includes some screens that are present as routes but are not currently part of the main booking path triggered from the home screen:

- `RequestForm`
- `TechnicianDetails`
- `Payment`

At the moment, the main flow goes from:

`Home -> Service Selection -> Technician List -> Booking Review -> Success`

instead of:

`Home -> Service Selection -> Request Form -> Technician List -> Technician Details -> Booking Review -> Payment -> Success`

## Current Product Scope Observed in Code

- The app is customer-facing only
- Data is currently mocked or stored in local React state/context
- No backend integration is visible in the provided source
- No real authentication, payment processing, booking persistence, or live messaging backend is currently connected
- Technician availability, booking history, and message threads are represented with mock data

## Suggested Product Positioning

FixIt can be positioned as:

"A simple mobile app for booking trusted home-service technicians, comparing providers, tracking service progress, and staying in contact throughout the job."

