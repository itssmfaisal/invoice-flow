# InvoiceFlow

Mobile-first Flutter prototype for embedded invoice financing. The app uses local dummy data only and is ready for API integration later.

## Run

```bash
flutter pub get
flutter run
```

## Included flows

- Dashboard metrics and recent invoice activity
- Invoice search and status filters
- Invoice detail sheet with approve/reject actions
- Financing offers and rate comparison
- Finance volume analytics and top suppliers
- Workspace, supplier, reports, security, and settings shortcuts

Replace the in-memory models in `lib/main.dart` with repository/API models when the backend is connected.
