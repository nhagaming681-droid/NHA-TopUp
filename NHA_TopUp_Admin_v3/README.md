# NHA TopUp — Firestore v1

Orders are written to Cloud Firestore instead of only local storage.

GitHub Actions requires the `GOOGLE_SERVICES_JSON` Actions secret.

Next planned step: Firebase Storage for payment screenshots + Firebase Authentication + Admin Panel + secure Firestore rules.

Real game-currency delivery still requires an authorized supplier/API.


## Admin setup
1. Enable Firebase Authentication > Email/Password.
2. Create an admin user in Authentication.
3. In Firestore create `admins/{UID}` for that user's UID, with `enabled: true`.
4. Deploy/use `firestore.rules` before production.

The app's Account tab now has Admin Login. Admin can view orders and change status.
