# Salesforce Sales Simulator & Currency Converter

## 📋 Project Overview

A robust **Single Page Application (SPA)** built on Salesforce Lightning Web Components (LWC). This solution streamlines the order entry process by allowing users to search for products, manage an in-memory cart, perform real-time currency conversion (USD/EUR/BRL), and commit orders with transactional integrity.

## 🚀 Key Features

### 1. High-Performance Product Search

- **Architecture:** Implemented using **LWC Wire Service** for optimal caching and performance.
- **UX:** Features debouncing logic to minimize server calls during typing.

### 2. Real-Time Currency Integration

- **Integration:** Consumes an external REST API (`awesomeapi`) to fetch live exchange rates.
- **Logic:** Converts the cart total dynamically from USD (Org Default) to BRL or EUR upon user request.

### 3. Scalable Backend (Apex)

- **Bulkification:** The `createOrder` method utilizes the **Collect-Query-Map pattern**, ensuring O(1) query performance regardless of cart size (avoiding SOQL 101 errors).
- **ACID Compliance:** Uses `Database.setSavepoint()` and `Rollback` to ensure atomic transactions (Header + Items are saved together or not at all).

### 4. Interactive UX

- **Notifications:** Uses `ShowToastEvent` with deep linking, allowing users to navigate directly to the created Order record.
- **State Management:** Parent-Child component communication via Custom Events to maintain a decoupled architecture.

## 🛠️ Technical Stack

- **Frontend:** Lightning Web Components (LWC), JavaScript (ES6+).
- **Backend:** Apex (Enterprise Patterns), SOQL.
- **Integration:** REST API, Named Credentials (Simulated).
- **Tools:** VS Code, Salesforce CLI, Git.

---

_Developed as a Portfolio Project focusing on Scalable Architecture._
