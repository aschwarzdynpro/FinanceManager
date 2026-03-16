# Finance Manager – iPad App

Eine SwiftUI iPad-App zur Verwaltung monatlicher Einnahmen und Ausgabenkategorien mit Jahreszielen.

## Features

- **Monatliche Einnahmen** – Erfasse deine Einnahmen pro Monat
- **Ausgabenkategorien** – Plane und tracke Ausgaben in 4 Kategorien:
  - ETF Sparplan
  - Urlaub
  - Auto
  - Aktien
- **Jahresziele** – Setze Jahresziele pro Kategorie und verfolge den Fortschritt
- **Dashboard** – Jahresübersicht mit Fortschrittsbalken und Zusammenfassungen
- **iPad-optimiertes Layout** – NavigationSplitView mit Sidebar

## Anforderungen

- iOS 17.0+
- iPad (optimiert für iPadOS)
- Xcode 15+

## Projekt öffnen

```bash
open FinanceManager.xcodeproj
```

## Architektur

```
FinanceManager/
├── FinanceManagerApp.swift       # App Entry Point
├── ContentView.swift             # NavigationSplitView Root
├── Models/
│   └── Models.swift              # Datenmodelle & AppDataStore (UserDefaults)
└── Views/
    ├── SidebarView.swift         # Sidebar-Navigation
    ├── DashboardView.swift       # Jahresübersicht & Kategorie-Karten
    ├── MonthlyDetailView.swift   # Monats-Detailansicht mit Allokationen
    └── AnnualGoalsView.swift     # Jahresziele setzen & verfolgen
```

## Datenpersistenz

Die App speichert alle Daten lokal mit `UserDefaults` und `Codable`. Keine externe Datenbank erforderlich.
