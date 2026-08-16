# How to Open & Run CDA Java Backend in Apache NetBeans IDE

This project is a native **Maven Spring Boot application** specifically optimized for **Apache NetBeans IDE**.

---

## 🚀 Steps to Open in NetBeans

1. Open **Apache NetBeans IDE**.
2. Click **File -> Open Project** (Ctrl + Shift + O).
3. Navigate to `d:\Projects\Cranes app\backend_java`.
4. NetBeans will automatically recognize the project icon as a **Java Maven Spring Boot Project**.
5. Click **Open Project**.

---

## ▶️ Running & Debugging in NetBeans

- **Run Project**: Right-click project name -> Select **Run** (or press **F6**).
- **Debug Project**: Right-click project name -> Select **Debug** (or press **Ctrl + F5**).
- NetBeans will start the Spring Boot server on **`http://localhost:8080`**.

---

## 📡 Profile API Endpoints (Spring Boot REST)

- **`GET /api/v1/user/profile?email=unii12634@gmail.com`**
  Retrieves candidate real profile attributes (Full Name, Degree, College, Target Role, Salary Package, Resume Link).

- **`PUT /api/v1/user/profile?email=unii12634@gmail.com`**
  Persists updated profile fields to the Supabase PostgreSQL database in real time.
