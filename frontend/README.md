# Academic Scheduler Frontend

Flutter Mobile Client for Academic Task Scheduling with a Neo-Brutalist UI.

## Overview

The Flutter application provides the user interface for:
- Task CRUD (creation, modification, deletion with credit weight, difficulty, deadline, and required duration)
- Free study slot / availability configuration
- Interactive schedule timeline view (15-minute resolution)
- Detailed scheduled block inspection
- Dynamic recalculation trigger
- Settings and offline local persistence

## Architecture

- **State Management / MVVM**: Separation between UI Views, ViewModels / State, and Services.
- **API Client**: Consumes the FastAPI backend (`POST /api/v1/schedule`, `POST /api/v1/schedule/recalculate`).
- **Design System**: Strict Neo-Brutalist visual language as defined in `DESIGN_SYSTEM.md`.

## Setup & Running

```bash
flutter pub get
flutter run
```
