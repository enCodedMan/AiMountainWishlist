# Product Decisions

## PD-001 — No paid XP

Decision:
XP may never be directly purchased or multiplied through Premium.

Reason:
XP needs credibility as a measure of real accomplishments.

Date:
2026-08-28

---

## PD-002 — Trust-first verification

Decision:
Most achievements are self-reported.

Photo or integration verification is supplemental.

Reason:
Mandatory verification creates too much friction.

---

## PD-003 — Social is profile-first

Decision:
Do not prioritize an algorithmic social feed.

Reason:
Product should showcase lives, not maximize scrolling.

---

## PD-004 — Working app name: Stones

Decision:
Working display name is "Stones"; bundle identifier
`com.stonesapp.Stones` (placeholder, trivially renameable pre-launch).

Reason:
app-engineer needs a concrete name/bundle id to scaffold the Xcode
project; this is cheap to change until the app has been through
TestFlight or App Store Connect.

Date:
2026-08-29

---

## PD-005 — MVP sign-in methods: Apple + email/password

Decision:
Launch with Sign in with Apple and email/password only. No Google or
other third-party social login for MVP.

Reason:
Simplest scope; automatically satisfies Apple's requirement that any
third-party sign-in be accompanied by Sign in with Apple, with no extra
OAuth setup. Revisit if user research shows real demand.

Date:
2026-08-29
