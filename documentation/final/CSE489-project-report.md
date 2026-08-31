# DEPARTMENT OF COMPUTER SCIENCE AND ENGINEERING

**Course:** CSE 489  
**Name:**  
**ID:**  
**Email:**  

**Project Title:** Home Cleaning Service Marketplace  

---

## Project Features

By the end of this course, implemented features:

**a) Login system**

The project has a full login and account system. A new user can sign up as a **customer** or a **cleaner**. An existing user can log in with email and password and log out from the current device. After login, the app opens the correct home page for that role (customer, cleaner, or administrator). The user can change password while signed in, and there is a forgot-password and email-verification flow. Passwords are not stored in plain text. The Flutter app talks to a Dart Frog API; the API issues a short-lived access token and a refresh token so the session can continue securely.

**b) Reporting system**

The project has an administrator reporting and control panel. The admin can see cleaner applications and **approve or reject** them. The admin can open a **user list and user detail** and suspend, reactivate, or deactivate an account. The admin can open a **booking list and booking detail** and cancel a booking with a reason. The admin can moderate **reviews** (hide or unhide). The admin can open the **audit log**, which records important actions (who did what and when). Signed-in users also have an in-app **notification** list. Together these screens are the reporting system of the product.

**c) Home cleaning marketplace**

The project is a mobile marketplace for home cleaning. A **customer** can save a profile and addresses, search approved cleaners, compare them, and **book a time slot**. A **cleaner** completes onboarding, waits for admin approval, then sets services and availability, and manages jobs (accept, decline, start, complete). Customer and cleaner can **chat** on a booking. After a job is completed, the customer can leave a **review**. The app is Flutter; the backend is Dart Frog; data is stored in MongoDB Atlas.

What the project does **not** show in the app today: payment, payout, dispute, and finance menus were removed from the three role homes. Those APIs may still exist on the server as a development sandbox, but the demonstrated product is login, marketplace booking, chat/reviews, and admin reporting.

---

## Online Resources used

**a) Reference:**

- W3Schools.com website (general web and programming notes) — https://www.w3schools.com/  
- Flutter official documentation — https://docs.flutter.dev/  
- Dart official documentation — https://dart.dev/guides  
- Dart Frog documentation — https://dartfrog.vgv.dev/  
- MongoDB Atlas documentation — https://www.mongodb.com/docs/atlas/  
- YouTube videos:  
  - Flutter & Dart crash course / official Flutter channel (add the exact URL you watched)  
  - MongoDB Atlas getting started (add the exact URL you watched)  

**b) Stack Overflow or GitHub links**

- Flutter packages used in the project (examples): GoRouter, Dio, Riverpod — https://pub.dev/  
- Dart Frog GitHub — https://github.com/VeryGoodOpenSource/dart_frog  
- Stack Overflow (JWT, Flutter HTTP, MongoDB) — https://stackoverflow.com/  
- This project’s own documentation folder: `documentation/` (architecture notes and viva file map)

---

## Future Enhancements

Following enhancement can be added to the current system which will improve the system.

**a) Understanding of system**

The current system already runs as a Flutter app plus an API plus a database. In the future it can be deployed on a public HTTPS server with monitoring and backups so it is easier to understand and operate as a live product. Chat can become real-time. Customers could search cleaners on a map. Payment and payout screens could be turned back on after a real payment company is connected. These steps would make the whole system closer to a commercial marketplace.

**b) Login system**

The login system already works for the course demo. In the future, real email can be connected so verification and password-reset messages arrive in the user’s inbox. Two-factor authentication can be added. The app can again show a list of devices / “log out from all devices” if that is required.

**c) Reporting system**

The reporting system already lets an admin see users, bookings, reviews, and the audit log. In the future the admin can download CSV or PDF reports by date, see dashboard charts (how many bookings, how many cleaners pending), and receive a scheduled email summary. That would turn operational lists into stronger management reports.

---

*(Write your Name, ID, and Email at the top before submission.)*
