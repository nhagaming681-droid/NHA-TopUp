NHA TopUp Firebase Anonymous Auth Fix

Changes:
- Firebase Anonymous Authentication is used automatically for customers.
- Firestore orders use Firebase Auth UID as customerId.
- Customer can create Pending orders and read only their own orders.
- Admin access remains email/password plus admins/{uid}.enabled == true.
- Secure Firestore rules are included in firestore.rules.

Do not publish allow read, write: if true.
