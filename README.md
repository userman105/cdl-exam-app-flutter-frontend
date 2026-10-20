# CDL A to Z Flutter Frontend --- System Architecture

## Application Architecture

``` mermaid
flowchart TB
    Learner["CDL Learner"]

    subgraph Flutter["Flutter Frontend"]
        UI["Presentation Layer\nScreens + Reusable Widgets"]
        State["State Layer\nBLoC / Cubit"]
        Auth["Authentication State"]
        Exam["Exam / Practice State"]
        Profile["Profile / Settings State"]
        Data["Repository / Service Layer"]
        Network["Dio + HTTP"]
        Secure["Flutter Secure Storage"]
        Prefs["SharedPreferences"]
        Connectivity["Connectivity Service"]
        TTS["Text-to-Speech"]
        Theme["Adaptive Theme"]
        IAP["In-App Purchase"]

        UI --> State
        State --> Auth
        State --> Exam
        State --> Profile

        Auth --> Data
        Exam --> Data
        Profile --> Data

        Auth --> Secure
        Profile --> Prefs
        Data --> Network
        Data --> Connectivity

        Exam --> TTS
        UI --> Theme
        UI --> IAP
    end

    Learner --> UI

    Network -->|"REST / JSON\nBearer authentication"| API["AdonisJS Backend API"]

    subgraph Backend["Companion Backend"]
        API --> AuthAPI["Authentication + OTP"]
        API --> ExamAPI["Exam Service"]
        API --> AttemptAPI["Attempt / Progress Service"]
        AuthAPI --> DB[("PostgreSQL")]
        ExamAPI --> DB
        AttemptAPI --> DB
    end
```

## Layer Responsibilities

  -----------------------------------------------------------------------
  Layer                               Responsibility
  ----------------------------------- -----------------------------------
  Presentation                        Screens, controls, question UI,
                                      navigation and visual feedback

  BLoC/Cubit                          Authentication, exam and UI state
                                      transitions

  Repository/services                 Boundary between application state
                                      and remote/platform services

  Dio/HTTP                            REST communication with the CDL
                                      backend

  Secure storage                      Authentication credentials

  SharedPreferences                   Non-sensitive local application
                                      preferences

  Connectivity                        Detect network state and support
                                      appropriate UI behavior

  TTS                                 Read exam content aloud

  Adaptive theme                      Persist/display light and dark
                                      presentation

  Backend API                         Authentication, exams and
                                      authoritative progress

  PostgreSQL                          Persistent users, questions,
                                      answers and attempts
  -----------------------------------------------------------------------

## Exam Data Flow

``` mermaid
flowchart LR
    Category["Choose Category"] --> State["Exam Cubit / BLoC"]
    State --> Repo["Exam Repository / Service"]
    Repo --> API["CDL Backend API"]
    API --> DB[("PostgreSQL")]
    DB --> API
    API --> Repo
    Repo --> State
    State --> Question["Question Screen"]
    Question --> Answer["Submit Answer"]
    Answer --> State
    State --> API
    API --> Progress["Persist Attempt Progress"]
    Progress --> State
    State --> Feedback["Correct / Wrong Feedback"]
```

## Authentication Data Flow

``` mermaid
sequenceDiagram
    actor User
    participant UI as Flutter UI
    participant Auth as Auth State
    participant Store as Secure Storage
    participant API as Backend API

    User->>UI: Login
    UI->>Auth: Submit credentials
    Auth->>API: POST login
    API-->>Auth: Access token / user
    Auth->>Store: Persist token
    Auth-->>UI: Authenticated state

    Note over UI,API: Subsequent protected request

    UI->>Auth: Request exam
    Auth->>Store: Read token
    Auth->>API: Request + Bearer token
    API-->>Auth: Protected resource
    Auth-->>UI: Updated state
```

## Full CDL Project

``` mermaid
flowchart LR
    User["Learner"] --> Mobile["CDL A to Z\nFlutter Frontend"]
    Mobile -->|"REST API"| Server["CDL Exam API\nAdonisJS 6"]
    Server --> DB[("PostgreSQL")]
    Server --> Email["OTP Email"]
    Mobile --> Google["Google Sign-In"]
    Server --> Google
```

# CDL A to Z

> A cross-platform Flutter application for Commercial Driver's License
> (CDL) exam preparation, practice tests, progress tracking, and
> accessible study tools.

CDL A to Z is the mobile client for the CDL Exam project. It connects to
the companion backend API to provide authentication, exam categories,
resumable test sessions, user progress, profile management, and
study-focused features through a responsive Flutter interface.

## Features

-   User registration, login, logout, and account verification
-   Google Sign-In
-   Secure authentication token storage
-   CDL practice exam categories
    -   General Knowledge
    -   Air Brakes
    -   Combination / Tractors & Trailers
-   Practice questions and answer feedback
-   Exam progress and resumable sessions
-   Text-to-speech support for questions
-   User profile and settings
-   Network/connectivity awareness
-   Light/dark adaptive theming
-   Arabic-oriented UI/font support
-   Subscription / in-app-purchase UI
-   Image selection for profile-related flows
-   Animated loading and feedback states

## Tech Stack

  Area                Technology
  ------------------- ------------------------------------
  Framework           Flutter
  Language            Dart
  State Management    flutter_bloc / Cubit
  HTTP                Dio + `http`
  Authentication      Bearer tokens + Google Sign-In
  Secure Storage      flutter_secure_storage
  Local Preferences   SharedPreferences
  Connectivity        connectivity_plus
  Accessibility       flutter_tts
  Theming             adaptive_theme
  Purchases           in_app_purchase
  UI                  Material, Google Fonts, SVG assets
  Animation           animate_do, shimmer
  Feedback            awesome_snackbar_content

## System Architecture

``` mermaid
flowchart LR
    User["CDL Learner"] --> UI["Flutter Screens & Widgets"]

    subgraph Client["CDL A to Z — Flutter Client"]
        UI --> State["BLoC / Cubit State Management"]

        State --> Auth["Authentication"]
        State --> Exams["Exam / Practice State"]
        State --> Profile["Profile & Settings"]

        Auth --> Secure["Secure Token Storage"]
        Profile --> Prefs["SharedPreferences"]

        Auth --> API["API / Repository Layer"]
        Exams --> API
        Profile --> API

        API --> Dio["Dio / HTTP Client"]

        Exams --> TTS["Text-to-Speech"]
        API --> Connectivity["Connectivity Monitoring"]

        UI --> Theme["Adaptive Theme"]
        UI --> IAP["In-App Purchases"]
    end

    Dio -->|"REST / JSON"| Backend["CDL Exam Backend API"]
    Backend --> DB[("PostgreSQL")]
    Backend --> Mail["OTP / Email Service"]
    Backend --> Google["Google OAuth"]
```

## Full-Stack Relationship

This repository is the **Flutter frontend** of the CDL Exam project. The
companion backend is maintained separately:

-   Frontend: `userman105/cdl-exam-app-flutter-frontend`
-   Backend: `userman105/cdl-exam-app`

``` mermaid
flowchart TB
    subgraph Mobile["Flutter Mobile Application"]
        Screens["Screens / Widgets"]
        Bloc["BLoC / Cubits"]
        Repo["Repositories / Services"]
        Local["Secure Storage + Preferences"]

        Screens --> Bloc
        Bloc --> Repo
        Bloc --> Local
    end

    Repo -->|"HTTPS + Bearer Token"| API["AdonisJS 6 REST API"]

    subgraph Server["CDL Exam Backend"]
        API --> Auth["Authentication / OTP"]
        API --> Exam["Exam Logic"]
        API --> Attempts["Attempt / Progress Logic"]
    end

    Auth --> PostgreSQL[("PostgreSQL")]
    Exam --> PostgreSQL
    Attempts --> PostgreSQL
```

## Exam Flow

``` mermaid
sequenceDiagram
    actor User
    participant App as Flutter App
    participant State as Exam State
    participant API as CDL REST API
    participant DB as PostgreSQL

    User->>App: Select exam category
    App->>State: Load exam
    State->>API: Request exam/questions
    API->>DB: Load exam data
    DB-->>API: Questions + answers
    API-->>State: Exam data
    State-->>App: Render question

    User->>App: Select answer
    App->>State: Submit answer
    State->>API: Submit response
    API->>DB: Validate + update progress
    DB-->>API: Updated attempt
    API-->>State: Result + progress
    State-->>App: Show feedback

    opt User leaves before completion
        State->>API: Pause/save attempt
    end
```

## Authentication Flow

``` mermaid
flowchart LR
    Launch["App Launch"] --> Token{"Stored token?"}
    Token -->|No| Auth["Login / Register"]
    Token -->|Yes| Validate["Restore authenticated session"]
    Auth --> Password["Email + Password"]
    Auth --> Google["Google Sign-In"]
    Password --> API["Backend API"]
    Google --> API
    API --> Verify{"Verification required?"}
    Verify -->|Yes| OTP["OTP Verification"]
    OTP --> Home["Application Home"]
    Verify -->|No| Home
    Validate --> Home
```

## Project Structure

``` text
cdl-exam-app-flutter-frontend/
├── android/                 # Android platform project
├── assets/
│   ├── icons/               # CDL/category/profile/TTS assets
│   ├── images/              # Splash and application imagery
│   └── json/                # Bundled JSON assets
├── ios/                     # iOS platform project
├── lib/                     # Dart application source
│   ├── screens/             # Application screens
│   ├── widgets/             # Reusable UI components
│   ├── cubit/ / bloc/       # Application state
│   ├── services/            # API/auth/platform services
│   └── main.dart            # Application entry point
├── test/                    # Flutter tests
├── pubspec.yaml             # Dependencies and assets
└── README.md
```

> The exact feature-folder names may evolve as the application is
> refactored; the diagram above describes the logical architecture.

## Getting Started

### Requirements

-   Flutter SDK
-   Dart SDK compatible with `^3.9.2`
-   Android Studio / Android SDK or Xcode
-   Running CDL Exam backend for online functionality

### Clone

``` bash
git clone https://github.com/userman105/cdl-exam-app-flutter-frontend.git
cd cdl-exam-app-flutter-frontend
flutter pub get
```

### Run

``` bash
flutter run
```

To choose a device:

``` bash
flutter devices
flutter run -d <device-id>
```

## Build

### Android APK

``` bash
flutter build apk --release
```

For smaller architecture-specific APKs:

``` bash
flutter build apk --release --split-per-abi
```

### Android App Bundle

``` bash
flutter build appbundle --release
```

### Web

If web support is enabled for the project:

``` bash
flutter build web --release
```

## Key Dependencies

The project currently includes `flutter_bloc`, `equatable`, `dio`,
`http`, `flutter_secure_storage`, `shared_preferences`,
`google_sign_in`, `connectivity_plus`, `flutter_tts`, `adaptive_theme`,
`in_app_purchase`, `image_picker`, `flutter_svg`, `google_fonts`,
`shimmer`, and animation/feedback packages.

## Design Goals

**Clear exam experience.** The interface keeps the learner focused on
the current question, answer choices, feedback, and progress.

**Separation of UI and state.** BLoC/Cubit keeps asynchronous
authentication and exam operations outside presentation widgets.

**Secure sessions.** Authentication credentials are persisted using
secure storage rather than ordinary preferences.

**Accessible study.** Text-to-speech provides an additional way to
consume exam questions.

**Resilient networking.** Connectivity monitoring and a dedicated
networking layer help the UI respond cleanly when the backend is
unavailable.

## Companion Backend

The Flutter application is designed to work with:

`userman105/cdl-exam-app`

The backend provides authentication, OTP verification, Google
authentication, exam/question data, and persistent exam-attempt
progress.

## Repository

`userman105/cdl-exam-app-flutter-frontend`


