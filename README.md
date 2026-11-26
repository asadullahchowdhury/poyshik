<div align="center">

# 💸 Poyshik

**Effortless daily expense tracking — a fast, offline-first mobile app I'm building with Flutter.**

![Status](https://img.shields.io/badge/status-🚧_in_active_development-orange?style=for-the-badge)
![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Riverpod](https://img.shields.io/badge/Riverpod-00B4D8?style=for-the-badge)
![SQLite](https://img.shields.io/badge/Drift_SQLite-003B57?style=for-the-badge&logo=sqlite&logoColor=white)

</div>

> [!NOTE]
> This repository is public so you can follow along with what I'm building. Poyshik isn't released yet and isn't open for reuse or redistribution — the code is shared for showcase purposes only.

## 💡 Why Poyshik?

Most expense trackers feel like accounting software. Poyshik is built for the 5-second moment after you pay for something: open, tap the amount, pick a category, done — no sign-up, no internet required.

## ✨ What it does

- ⚡ **Quick add** — log an expense in seconds with a custom numpad
- 🏦 **Accounts** — track cash, bank and mobile-wallet balances separately
- 🏷️ **Categories** — color-coded categories with icons and a palette picker
- 📜 **Transactions** — full history grouped by day, week and month
- 📊 **Insights** — see where your money goes by period and category
- 🌗 **Light / dark themes** on a consistent design system (colors, spacing, typography)
- 📴 **Offline-first** — everything stays on the device

## 🛠️ Built With

| Concern | Choice |
| --- | --- |
| UI | Flutter, Material |
| Language | Dart |
| State management | Riverpod |
| Navigation | go_router |
| Local database | Drift (SQLite) with code generation |
| i18n / formatting | intl, flutter_localizations |

## 🧱 Architecture

```
lib/
  ├── app/        # App shell, router, theme (colors, spacing, typography)
  ├── core/       # Money & date utilities, shared widgets (numpad, cards, empty states)
  ├── data/       # Drift database, queries, providers, seed data
  └── features/   # accounts · categories · home · insights · settings · transactions
```

Feature-first structure: each feature owns its screens, widgets and providers; shared logic lives in `core`, persistence in `data`.

## 🗺️ Roadmap

- [x] Accounts, categories and transactions
- [x] Insights by period and category
- [x] Light / dark theming
- [ ] Budgets and spending limits
- [ ] Recurring transactions
- [ ] Export to CSV
- [ ] Cloud backup & sync
- [ ] Play Store release

## 👤 Author

**Rahat Chowdhury** — Full-Stack Developer
[Portfolio](https://rahat-chowdhury.vercel.app) · [LinkedIn](https://www.linkedin.com/in/chowdhuryrahat) · [GitHub](https://github.com/asadullahchowdhury)

<sub>© 2026 Rahat Chowdhury. All rights reserved.</sub>
