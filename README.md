# RunRealm: Gamified Social Running App

RunRealm is a futuristic, social running application that turns your workouts into a territorial conquest game.

## 🎮 Game Mode: Territory Capture (Turf War)
RunRealm uses a unique "Painter's Algorithm" to gamify your running path:
*   **Claim Land:** Every time you run, the area enclosed by your path becomes your territory.
*   **Group Wars:** Create "Squads" with friends. The map dynamically updates to show who owns which area within that specific group.
*   **Leaderboards:** Compete for the most "Visible Area" in your squad. Newer runs capture territory from older runs (Painter's Algorithm), keeping the game dynamic and encouraging consistency.

## 🏃 Run Tracking Metrics
The app provides comprehensive tracking for your runs:
*   **Real-time Stats:** Distance, Pace, Duration, and Speed.
*   **Visual Trail:** A neon cyan trail follows your path on the dark-themed map.
*   **History:** Detailed logs of your past runs with mapping visualizations.
*   **Location Awareness:** Automatically detects your starting position using GPS.

## 🛠 Tech Stack
*   **Frontend:** Flutter (Mobile App) with a custom Futuristic Glassmorphism Theme.
*   **Backend:** Node.js, Express, PostGIS (for complex spatial calculations).
*   **Database:** PostgreSQL (Spatial Data) & Firestore (User/Social Data).
*   **Maps:** Mapbox GL.

## 🚀 Getting Started
1.  **App:** Open `runrealm_flutter` and run `flutter run`.
2.  **Backend:** The backend is deployed on Google Cloud Run. To run locally, navigate to `runrealm-territory-api`, install dependencies with `npm install`, and run `npm start`.
