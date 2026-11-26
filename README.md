<div align="center">

# 💸 Poyshik

**Effortless daily expense tracking — a fast, offline-first Flutter app.**

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Riverpod](https://img.shields.io/badge/Riverpod-00B4D8?style=for-the-badge)
![SQLite](https://img.shields.io/badge/Drift_SQLite-003B57?style=for-the-badge&logo=sqlite&logoColor=white)
![Status](https://img.shields.io/badge/status-in_development-orange?style=for-the-badge)

</div>

## ✨ Features

- ⚡ **Quick add** — log an expense in seconds with a custom numpad
- 🏦 **Accounts** — track cash, bank and mobile-wallet balances separately
- 🏷️ **Categories** — color-coded categories with icons and a palette picker
- 📜 **Transactions** — full history grouped by day, week and month
- 📊 **Insights** — see where your money goes by period and category
- 🌗 **Light / dark themes** with a consistent design system (colors, spacing, typography)
- 📴 **Offline-first** — everything is stored locally on the device

## 🛠️ Tech Stack

| Concern | Choice |
| --- | --- |
| UI | Flutter, Material |
| Language | Dart |
| State management | Riverpod |
| Navigation | go_router |
| Local database | Drift (SQLite) |
| i18n / formatting | intl, flutter_localizations |

## 🧱 Architecture

```
lib/
  ├── app/        # App shell, router, theme (colors, spacing, typography)
  ├── core/       # Money & date utilities, shared widgets (numpad, cards, empty states)
  ├── data/       # Drift database, queries, providers, seed data
  └── features/   # accounts · categories · home · insights · settings · transactions
```

Feature-first structure: each feature owns its screens, widgets and providers, while shared logic lives in `core` and persistence in `data`.

## 🚀 Getting Started

```bash
git clone https://github.com/asadullahchowdhury/poyshik.git
cd poyshik
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # generate Drift code
flutter run
```

## 🗺️ Roadmap

- [ ] Budgets and spending limits
- [ ] Recurring transactions
- [ ] Export to CSV
- [ ] Cloud backup & sync

## 👤 Author

**Rahat Chowdhury** — Full-Stack Developer
[Portfolio](https://rahat-chowdhury.vercel.app) · [LinkedIn](https://www.linkedin.com/in/chowdhuryrahat) · [GitHub](https://github.com/asadullahchowdhury)
