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
