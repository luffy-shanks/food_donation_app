# Food Donation & NGO Network

**Flutter assignment project**: a prototype connecting surplus food donors with local NGOs. It demonstrates how organizations can find available food, coordinate a handoff, and track community impact.

## Included demo flows

- Choose a Donor, NGO, or Admin dashboard at startup; switch roles from the app bar.
- Donors post food with category, type, quantity, address, delivery arrangement (NGO pickup or donor delivery), ready time, safe collection deadline, photo URL, approximate location, weight, preparation, storage, and allergen details.
- NGO pickup uses the donor's listed food address. If the donor will deliver, the NGO enters its receiving address; both sides see the handoff address and scheduled time.
- NGOs search/filter food by category and distance from their configured service coordinates, then request a chosen quantity.
- Donors approve or reject requests. An approval reserves only the requested quantity, leaving any remainder listed.
- Demo donor profiles keep sample listings, requests, and notifications separate.
- Approved handoff codes, NGO names, addresses, and scheduled times stay visible on the donor's food listing.
- NGO pickup is confirmed by code, then the NGO confirms distribution. For donor delivery, the NGO confirms receipt with the code and that completes the handoff.
- In-app activity notifications report requests, decisions, upcoming pickups, handoffs, and missed pickups.
- NGOs can cancel pending or approved pickups with a reason; approved quantities return to the listing when cancelled.
- Overdue approved pickups are marked missed while the demo is open or when it is reopened, with a history entry and automatic release when the food is still within its safe deadline.
- Pickup requests must fall after the food is ready and before its safe collection deadline.
- Donors share a demo handoff code with the NGO; the NGO enters it to confirm pickup or delivery receipt.
- Impact reports show delivered meals/items, completed donations, estimated rescued weight, a seven-day activity chart, and links to SDG 2 and SDG 12.
- Admin reviews sample NGO verification records and sees platform summary statistics.
- Admin reports are read-only. The NGO demo profile can switch between sample organizations.
- Food safety guidance and scheduled pickup details are visible in the listing flow.

## Run

Install Flutter, then from this folder run:

```sh
flutter pub get
flutter run
```

## Browser preview

The `preview` folder contains a lightweight static preview for a browser. From that folder, run `npm start` and open `http://localhost:5173`. This preview is separate from the Flutter app; use `flutter run` to run the actual Flutter project.

## Prototype limits

Demo listings, requests, notifications, and profile selections are saved locally on the same device or browser using shared preferences. They are not synchronized across devices or users. Photos are provided by URL; the app does not upload files. Distance is estimated from manually entered coordinates; there is no GPS or map view. Notifications are in-app only and pickup reminders run while the app is open; push notifications are not connected. The handoff code and sample profile switching are demo conveniences, not security controls. Rescued weight is an estimate based on donor-entered weight per unit. Admin verification is a demonstration and does not verify real documents. Real multi-user use needs an authenticated backend, access rules, and server-side reservation transactions.
