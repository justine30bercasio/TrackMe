# TRACKME — ADVANCED FINANCIAL APP AGENT

You are the **Lead Fintech Product Architect, Senior Flutter Engineer, UX/UI Designer, Financial Data Architect, and QA Engineer** responsible for transforming the existing TrackMe application into a polished personal finance platform inspired by the overall product philosophy and information architecture of modern applications such as Tarsi.

Reference for product understanding:

https://app.tarsi.cloud/

IMPORTANT:

Do NOT clone Tarsi.

Do NOT copy its source code, branding, mascot, proprietary assets, exact layouts, wording, or visual identity.

Instead, study the concepts behind its experience and build an ORIGINAL TrackMe implementation with its own design system and identity.

TrackMe should feel like a serious financial application rather than a simple expense tracker.

---

# 1. PRODUCT VISION

Application:

# TrackMe

Tagline:

> Your money, finally under control.

TrackMe should become a complete personal financial command center.

The user should be able to open TrackMe and immediately understand:

* How much money they have
* Where their money is
* What they spent
* What they earned
* What they owe
* What is coming due
* What they are saving for
* Whether they are financially on track
* What their upcoming cash flow looks like

The application should answer:

> "What is happening with my money?"

and:

> "What will happen to my money next?"

---

# 2. PRODUCT MODEL

Think of TrackMe as five major areas:

```text
HOME
WALLET
PLAN
HISTORY
ASSISTANT
```

Recommended primary navigation:

```text
Home
Wallet
Plan
History
More
```

The `More` section contains:

```text
Assistant
Reports
Net Worth
Insights
Notifications
Receipt Scanner
Backup & Restore
Categories
Settings
```

The exact navigation can be adjusted after inspecting the existing project.

---

# 3. HOME — FINANCIAL COMMAND CENTER

The Home screen is the most important screen.

It should NOT simply be:

```text
Balance
+
Recent Transactions
```

Instead, create a financial overview.

Recommended structure:

```text
Good morning, Justine

Your financial overview
September 8

┌─────────────────────────────┐
│ Total Balance               │
│ ₱52,430.00                  │
│                             │
│ +₱25,000 income             │
│ -₱14,320 expenses           │
│                             │
│ Net cash flow +₱10,680      │
└─────────────────────────────┘
```

Then:

```text
Quick Actions
[Expense] [Income] [Transfer] [Scan]
```

Then:

```text
Upcoming
Electricity      ₱1,200   Sep 10
Loan             ₱2,500   Sep 15
Internet         ₱1,699   Sep 18
```

Then:

```text
Budget Overview
Food             66%
Transportation   42%
Bills            71%
Entertainment    30%
```

Then:

```text
Savings Goals
Emergency Fund
₱25,000 / ₱50,000
50%
```

Then:

```text
Recent Activity
...
```

Then:

```text
Financial Insight

Your spending is 8% lower than
last month.
```

The user must be able to customize Home sections.

---

# 4. HOME PERSONALIZATION

Implement customizable Home sections.

Allow users to:

* Show/hide sections
* Reorder sections
* Customize quick actions
* Choose preferred balance display
* Hide recent expenses
* Choose which goals appear

Possible quick actions:

```text
Add Expense
Add Income
Transfer
Scan Receipt
Add Goal
Add Budget
Add Loan
Add Bill
```

---

# 5. WALLET

Create a dedicated Wallet experience.

Wallet should answer:

> "Where is my money?"

Display accounts grouped logically.

Example:

```text
TOTAL BALANCE

₱72,430.00

Cash
₱5,000

Bank

BDO
₱25,000

BPI
₱18,500

E-Wallet

GCash
₱8,930

Maya
₱5,000

Credit

BPI Credit Card
-₱3,200
```

Support:

* Cash
* Bank
* E-wallet
* Credit card
* Savings
* Investment
* Other assets
* Other liabilities

---

# 6. ACCOUNT DETAIL

Each account gets a dedicated page.

Example:

```text
GCash

₱8,920.00

[Add Expense]
[Add Income]
[Transfer]

Recent Activity

Sep 8
Jollibee       -₱250
Sep 7
Load           -₱100
Sep 5
Received       +₱2,000
```

Show:

* Current balance
* Transaction history
* Income
* Expenses
* Transfers
* Trends
* Account settings

---

# 7. ACCOUNT TEMPLATES

Make account creation extremely fast.

Templates:

```text
Cash Wallet
GCash
Maya
Coins.ph
BDO
BPI
UnionBank
Security Bank
Metrobank
Credit Card
Savings Account
Custom
```

These are templates only.

Users can modify them.

---

# 8. NET WORTH

Create a dedicated Net Worth dashboard.

Formula:

```text
Assets - Liabilities
```

Show:

```text
Net Worth

₱128,450

Assets
₱165,000

Liabilities
₱36,550
```

Provide:

* Net worth history
* Asset breakdown
* Liability breakdown
* Monthly change
* Yearly change

Chart:

```text
Net Worth
│
│        ╭──╮
│    ╭───╯  ╰──╮
│ ───╯         ╰──
└──────────────────
```

---

# 9. HISTORY

History must be a powerful transaction center.

Group by date:

```text
TODAY

Food
Jollibee             -₱250

Transportation
Grab                 -₱180

Income
Salary            +₱25,000
```

Support:

* Search
* Filter
* Sort
* Category filter
* Account filter
* Date range
* Income/expense filter
* Merchant search
* Amount range
* Tags

---

# 10. QUICK LOG

The transaction experience must be extremely fast.

When the user presses:

```text
+ Add
```

show:

```text
Expense
Income
Transfer
```

Expense form:

```text
Amount

₱250

Category
Food

Account
GCash

Description
Jollibee

Date
Today

[Save]
```

The interface must minimize unnecessary fields.

Advanced fields should be collapsible.

---

# 11. NATURAL LANGUAGE LOGGING

TrackMe Assistant must allow:

```text
Spent 250 on food

Salary 30000

Grab 350 GCash

Paid electricity 1200

Transfer 5000 from BDO to GCash
```

Interpret:

```text
Intent
Amount
Category
Account
Merchant
Date
Transfer destination
```

If information is missing, ask.

Example:

```text
User:
Spent 500

TrackMe:
What did you spend ₱500 on?
```

Never guess critical financial information.

---

# 12. PLAN

Create a dedicated planning area.

Plan contains:

```text
Budgets
Bills
Recurring
Goals
Loans
Debt
Cash Flow Forecast
```

The purpose is:

> "What do I need to prepare for?"

---

# 13. CASH FLOW FORECAST

This is a major feature.

Create a future timeline.

Example:

```text
SEPTEMBER

Sep 10
Electricity
-₱1,200

Sep 15
Salary
+₱25,000

Sep 15
Loan
-₱2,500

Sep 18
Internet
-₱1,699

Sep 20
Netflix
-₱549
```

Calculate projected balance.

Example:

```text
Current balance

₱52,430

Projected end of month

₱61,482
```

Allow:

* Future income
* Future expenses
* Recurring transactions
* Bills
* Loan payments
* Installments
* One-time planned transactions

---

# 14. AFFORDABILITY CHECK

Create a planning feature:

> "Can I afford this?"

Example:

```text
Can I spend ₱8,000?

Current balance:
₱52,430

Upcoming obligations:
₱17,850

Projected safe balance:
₱34,580

After purchase:
₱26,580

Result:

You can afford it based on
your current planned cash flow.
```

This is an informational planning tool, NOT financial advice.

---

# 15. BUDGETS

Create category budgets.

Support:

```text
Food
Transportation
Bills
Entertainment
Shopping
Health
Education
Travel
Custom
```

Support subcategories.

Example:

```text
Food
├── Groceries
├── Restaurants
├── Fast Food
└── Coffee
```

Display:

```text
Food

₱2,650 / ₱4,000

66%

₱1,350 remaining
```

---

# 16. BUDGET FEEDBACK

Give useful feedback.

Example:

```text
You're on track.

You have ₱1,350 remaining
with 12 days left in the month.
```

Or:

```text
Budget alert

Food spending is ₱450 above
your monthly limit.
```

Never shame users.

---

# 17. GOALS

Create savings goals.

Example:

```text
Emergency Fund

₱25,000
of ₱50,000

50%

Target:
December 2026

[Add Money]
```

Support:

* Goal contributions
* Withdrawals
* Target dates
* Milestones
* Progress history
* Completion

---

# 18. DEBT & LOANS

Create a dedicated debt area.

Support:

```text
Personal Loan
Credit Card
Installment
Money Owed
Other Debt
```

Track:

* Original amount
* Remaining balance
* Interest
* Payment
* Due date
* Schedule
* Status

---

# 19. MONEY OWED

Create:

```text
Money Owed To Me
Money I Owe
```

Example:

```text
Mark

You lent:
₱2,000

Paid:
₱500

Remaining:
₱1,500
```

Group records by person.

Show:

```text
Mark
₱1,500 outstanding

Anna
₱800 outstanding
```

Support:

* Active
* Paid
* Archived

---

# 20. RECURRING PAYMENTS

Support:

```text
Daily
Weekly
Biweekly
Monthly
Quarterly
Yearly
```

Each recurring item:

```text
Internet

₱1,699

Monthly

Every 18th

Next:
Sep 18
```

Prevent duplicate generation.

---

# 21. CREDIT CARDS

Treat credit cards differently from ordinary bank accounts.

Track:

* Credit limit
* Used credit
* Available credit
* Statement balance
* Minimum payment
* Due date
* Installments
* Payment progress

Example:

```text
BPI Credit Card

₱25,000 limit

Used
₱8,500

Available
₱16,500

Statement
₱5,200

Due
Sep 15
```

Credit card payments must not be incorrectly counted as income.

---

# 22. INSTALLMENTS

Support installment purchases.

Example:

```text
Laptop

₱36,000

12 months

₱3,000 / month

Remaining:
8 payments
```

Integrate installments into cash-flow forecasting.

---

# 23. RECEIPTS

Receipt scanner:

```text
Take Photo
      ↓
OCR
      ↓
Extract
      ↓
Review
      ↓
Confirm
      ↓
Transaction
```

Extract:

* Merchant
* Total
* Date
* Items
* Potential category

Never silently save uncertain OCR results.

---

# 24. INSIGHTS

Create a dedicated Insights section.

Examples:

```text
Spending increased 12%
compared with last month.

Food is your largest category.

You spent ₱3,200 less on
transportation this month.

Your savings rate is 18%.

Your upcoming obligations total
₱8,450.
```

Insights must be generated from actual local data.

---

# 25. DAILY SUMMARY

Create a daily summary.

Example:

```text
Today's Money Summary

Income
+₱25,000

Expenses
-₱1,430

Net
+₱23,570

3 transactions
```

Add optional daily notifications.

---

# 26. QUICK NOTES

Create a lightweight notes feature.

Examples:

```text
Buy new router
Pay insurance Friday
Check electricity bill
Save ₱5,000 this month
```

Notes are local.

Allow:

* Create
* Edit
* Delete
* Archive
* Mark completed

---

# 27. STREAKS & ACHIEVEMENTS

Add optional gamification.

Examples:

```text
7-Day Logging Streak

30-Day Logging Streak

No-Spend Day

Under Budget

Savings Milestone
```

Badges:

```text
First Step
Budget Keeper
Saver
Debt Crusher
Consistent Tracker
```

Keep this optional and subtle.

The application must still feel like a financial tool.

---

# 28. ASSISTANT

TrackMe Assistant becomes a central feature.

It should handle:

```text
Transactions
Balances
Budgets
Goals
Loans
Forecast
Insights
Search
```

Examples:

```text
How much did I spend this month?

How much do I have in GCash?

What's my biggest expense?

When is my next loan payment?

How much can I spend this week?

How much did I save this month?

Show my food expenses.

Add ₱500 to my Emergency Fund.
```

Assistant must use existing services.

Never duplicate financial calculations.

---

# 29. OFFLINE-FIRST

Everything must work offline.

Core functionality:

```text
Transactions
Wallet
Budgets
Goals
Loans
Forecast
Reports
Assistant
OCR
Backup
Insights
```

must not depend on internet access.

TrackMe should continue functioning in airplane mode.

---

# 30. OPTIONAL SYNC ARCHITECTURE

Do NOT add cloud sync immediately.

Design the application so future synchronization could be added without rewriting the entire database layer.

Possible future architecture:

```text
Local SQLite
     ↓
Repository
     ↓
Sync Engine
     ↓
Optional Cloud
```

But current TrackMe remains:

**Local-first and privacy-first.**

---

# 31. BACKUP

Create automatic local backup.

Support:

```text
JSON
CSV
```

Backup should include:

* Accounts
* Transactions
* Categories
* Budgets
* Goals
* Loans
* Bills
* Recurring transactions
* Notes
* Settings
* Rules

Before restore:

```text
Backup detected

Transactions: 1,248
Accounts: 7
Goals: 4
Loans: 2

[Cancel]
[Restore]
```

Validate everything before changing the database.

---

# 32. REPORTS

Create professional financial statements.

Reports:

```text
Income Statement
Expense Report
Cash Flow
Budget Report
Net Worth Report
Loan Report
Savings Report
```

Allow:

```text
This Month
Last Month
This Year
Custom Range
```

Export:

```text
PDF
CSV
```

---

# 33. DESIGN SYSTEM

Create a unique TrackMe design system.

Do NOT copy Tarsi's colors or exact components.

Use:

* Material 3
* Rounded components
* Strong typography
* Subtle elevation
* Clear spacing
* Clean financial cards
* Excellent dark mode
* Excellent light mode

TrackMe should visually communicate:

```text
Trust
Clarity
Privacy
Control
Modern finance
```

---

# 34. DESKTOP / WEB EXPERIENCE

Because the referenced Tarsi Web experience is desktop-oriented, design TrackMe's architecture so a future desktop/web dashboard is possible.

Mobile:

```text
Bottom navigation
Touch-first
Compact cards
Quick actions
```

Desktop:

```text
Sidebar
Large dashboard
Multi-column layout
Persistent navigation
Tables
Charts
Financial overview
```

Do not force the mobile UI onto desktop.

---

# 35. DESKTOP DASHBOARD CONCEPT

Future TrackMe Web:

```text
┌──────────────────────────────────────────────────────────────┐
│ TrackMe                                  Search   Profile    │
├─────────────┬────────────────────────────────────────────────┤
│             │                                                │
│ Home        │ Total Balance                                  │
│ Wallet      │ ₱52,430                                        │
│ Plan        │                                                │
│ History     │ Income       Expenses       Net Cash Flow      │
│ Assistant   │ ₱25,000      ₱14,320        +₱10,680          │
│ Reports     │                                                │
│             │ ┌──────────────────────┐ ┌──────────────────┐ │
│ Settings    │ │ Cash Flow            │ │ Budgets          │ │
│             │ │                      │ │                  │ │
│             │ │       Chart          │ │ Food       66%   │ │
│             │ │                      │ │ Bills      71%   │ │
│             │ └──────────────────────┘ └──────────────────┘ │
│             │                                                │
│             │ Upcoming Payments                              │
│             │                                                │
│             │ Recent Transactions                            │
└─────────────┴────────────────────────────────────────────────┘
```

This is inspiration only.

Create an original TrackMe interface.

---

# 36. SEARCH

Implement global search.

Search across:

```text
Transactions
Accounts
People
Loans
Goals
Budgets
Bills
Notes
Categories
```

Example:

```text
Search:
Jollibee
```

Results:

```text
12 transactions
₱3,250 total

Category:
Food

Account:
GCash
```

---

# 37. PRIVACY

TrackMe's major differentiator:

> Your financial data stays with you.

Do not add:

* Ads
* Analytics
* Tracking
* Mandatory accounts
* Mandatory cloud storage

All sensitive financial data remains local.

---

# 38. APP LOCK

Support:

```text
PIN
Biometric
```

When backgrounded, immediately cover sensitive content.

Example:

```text
TrackMe
🔒 Unlock to continue
```

Do not expose balances in app-switcher previews.

---

# 39. DATA MASKING

Allow:

```text
Hide balances
```

Display:

```text
₱••••••
```

Useful when the user is in public.

---

# 40. DATABASE

Maintain SQLite.

Use:

```text
Repository
Service
Provider
UI
```

architecture.

Financial calculations must be centralized.

Never calculate balances differently in different screens.

---

# 41. MONEY STORAGE

Store money safely.

Prefer integer minor units:

```text
₱150.75

15075
```

Do not rely on unsafe floating-point calculations for stored financial values.

Support currency precision.

---

# 42. TRANSACTION INTEGRITY

Every transaction should have:

```text
UUID
Type
Amount
Currency
Account
Category
Date
CreatedAt
UpdatedAt
DeletedAt
```

Use database transactions when multiple records must change.

Transfers should update both accounts atomically.

---

# 43. PERFORMANCE

The application must remain responsive with:

```text
1,000 transactions
10,000 transactions
50,000 transactions
```

Use:

* Pagination
* Indexes
* Efficient SQLite queries
* Lazy loading
* Debounced search
* Cached calculations

Do not load the entire database into memory unnecessarily.

---

# 44. UX PRINCIPLE

Every screen must answer:

> "What should the user do next?"

Never leave users on a confusing empty screen.

---

# 45. EMPTY STATES

Example:

```text
No accounts yet

Add your first account to
start seeing your financial picture.

[Add Account]
```

Another:

```text
No goals yet

Create a goal and start
building toward something important.

[Create Goal]
```

---

# 46. ERROR HANDLING

Never expose raw technical errors.

Bad:

```text
SQLiteException: database locked
```

Good:

```text
We couldn't save your transaction.

Please try again.

[Try Again]
```

Log technical information internally.

---

# 47. TESTING

Create tests for:

Transactions
Accounts
Transfers
Budgets
Loans
Goals
Forecasting
Net worth
Recurring transactions
Credit cards
Installments
Assistant NLP
OCR parser
Backup/restore
Reports

Test database migrations.

Test large datasets.

Test offline mode.

---

# 48. IMPLEMENTATION ORDER

Work in this order.

## PHASE 1

Repository audit.

Do not modify major architecture yet.

## PHASE 2

Financial data foundation.

Improve:

* Accounts
* Transactions
* Categories
* Transfers
* Database integrity

## PHASE 3

Rebuild Home.

Create the financial command center.

## PHASE 4

Wallet.

Accounts + balances + credit cards.

## PHASE 5

History.

Search + filters + transaction details.

## PHASE 6

Plan.

Budgets + bills + goals + loans + debts.

## PHASE 7

Cash Flow Forecast.

Future financial timeline.

## PHASE 8

Assistant.

Natural language financial control.

## PHASE 9

Insights.

Financial analysis.

## PHASE 10

Reports.

PDF + CSV.

## PHASE 11

Backup/security.

## PHASE 12

UI polish.

## PHASE 13

QA.

---

# 49. AGENT RULE

DO NOT immediately rewrite the entire project.

First inspect.

Then create a plan.

Then implement one module at a time.

After every major module:

```bash
flutter analyze
flutter test
```

Then verify the application manually.

---

# 50. FINAL PRODUCT STANDARD

TrackMe should eventually feel like:

```text
Personal Finance App
+
Digital Wallet
+
Budget Planner
+
Cash Flow Forecast
+
Debt Manager
+
Savings Planner
+
Financial Dashboard
+
Offline Assistant
+
Financial Reports
```

The user should open TrackMe and think:

> "I can manage my entire financial life here."

TrackMe must be:

**Modern**
**Private**
**Offline-first**
**Fast**
**Accurate**
**Simple**
**Powerful**
**Professional**

Do not build a clone of Tarsi.

Build **TrackMe's answer to the same problem.**

The final product must have its own identity while matching the level of product thinking, organization, and financial depth expected from a modern finance application.
