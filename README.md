# Finance Manager – Web App

Statische Web-App zur Verwaltung monatlicher Einnahmen und Ausgabenkategorien mit Jahreszielen. Optimiert für iPad, läuft auf jedem Browser.

## Features

- **Monatliche Einnahmen** – Erfasse deine Einnahmen pro Monat
- **Ausgabenkategorien** mit geplantem und tatsächlichem Betrag:
  - 📈 ETF Sparplan
  - ✈️ Urlaub
  - 🚗 Auto
  - 💹 Aktien
- **Jahresziele** – Setze Jahresziele pro Kategorie und verfolge den Fortschritt
- **Dashboard** – Jahresübersicht mit Balkendiagramm und Fortschrittsanzeigen
- **Datenspeicherung** – Lokal im Browser via `localStorage`, keine Cloud nötig

## Deployment via GitHub Pages

### Option A – Automatisch via GitHub Actions (empfohlen)

1. Repository auf GitHub pushen
2. **Settings → Pages → Source: "GitHub Actions"** auswählen
3. Bei jedem Push auf `main` wird automatisch deployed

### Option B – Manuell (Branch)

1. **Settings → Pages → Source: "Deploy from a branch"**
2. Branch: `main`, Folder: `/ (root)` auswählen
3. Speichern → App ist unter `https://<username>.github.io/<repo>/` erreichbar

## Lokal starten

Da es sich um eine reine statische App handelt, reicht ein einfacher HTTP-Server:

```bash
# Python
python3 -m http.server 8080

# Node
npx serve .
```

Dann im Browser: `http://localhost:8080`

## Struktur

```
/
├── index.html          # Einstiegspunkt
├── css/
│   └── styles.css      # Alle Styles
├── js/
│   ├── store.js        # Datenmodell + localStorage
│   ├── views.js        # View-Rendering (Dashboard, Monthly, Goals)
│   └── app.js          # Router, Events, Init
└── .github/workflows/
    └── deploy.yml      # GitHub Actions Deployment
```
