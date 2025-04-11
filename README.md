# 🔁 Liquibase + MySQL + Docker (Custom Image Setup)

Liquibase is a powerful tool for managing database schema changes, but getting it up and running with MySQL in Docker can be tricky — especially when it comes to JDBC driver compatibility.

This guide walks you through setting up a **Liquibase + MySQL** development environment using **Docker Compose**, and building a **custom Liquibase image** that properly installs the MySQL driver using Liquibase Package Manager (LPM).

---

## 🔧 Why Not Use the Base Image?

While the official `liquibase/liquibase` image is a great starting point, it **does not include the MySQL JDBC driver** due to licensing restrictions.

There is an `INSTALL_MYSQL=true` environment variable intended to solve this at runtime, but it often behaves inconsistently in Docker Compose environments.

✅ **Solution:** Build a custom image and install the driver via LPM for a clean, consistent setup.

---

## 📁 Project Structure
```bash
liquibase_learning_project/
├── Dockerfile
├── docker-compose.yml
├── deploy.sh
├── .env
├── README.md
└── liquibase/
├── changelog/
│   └── changelog.yaml
├── liquibase.properties
└── liquibase.properties.template (optional for envsubst)
```

---

## 🪜 Setup Steps

### ⚙️ Step 1: Custom Liquibase Dockerfile

Create a `Dockerfile` in your root:

```Dockerfile
FROM liquibase/liquibase:latest
RUN liquibase install mysql
```
---

⚙️ Step 2: docker-compose.yml
```yaml
version: '3.8'

services:
  mysql:
    image: mysql:8.4.4
    container_name: mysql-test
    ports:
      - "${MYSQL_LOCAL_PORT}:${MYSQL_REMOTE_PORT}"
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
    volumes:
      - mysql-data:/var/lib/mysql

  liquibase:
    image: liquibase-mysql
    container_name: liquibase-test
    depends_on:
      - mysql
    environment:
      INSTALL_MYSQL: true
    volumes:
      - ./liquibase/changelog:/liquibase/changelog
      - ./liquibase/liquibase.properties:/liquibase/liquibase.properties
    entrypoint: [
      "liquibase",
      "--defaultsFile=/liquibase/liquibase.properties",
      "update"
    ]

volumes:
  mysql-data:
```
---

⚙️ Step 3: .env File
```env
MYSQL_LOCAL_PORT=3307
MYSQL_REMOTE_PORT=3306
MYSQL_ROOT_PASSWORD=yourpassword
LIQUIBASE_USERNAME=root
LIQUIBASE_PASSWORD=yourpassword
```
---

⚙️ Step 4: Liquibase Properties

liquibase/liquibase.properties:
```properites
searchPath: /liquibase/changelog
changeLogFile: changelog.yaml
url: jdbc:mysql://mysql:3306/mysql
username: ${LIQUIBASE_USERNAME}
password: ${LIQUIBASE_PASSWORD}
```
✅ No need to manually set driver class — the custom image handles that.

---

⚙️ Step 5: Sample Changelog
Create liquibase/changelog/changelog.yaml:
```yaml
databaseChangeLog:
  - changeSet:
      id: 1
      author: you
      changes:
        - createTable:
            tableName: example_table
            columns:
              - column:
                  name: id
                  type: INT
                  autoIncrement: true
                  constraints:
                    primaryKey: true
                    nullable: false
              - column:
                  name: name
                  type: VARCHAR(255)
```
---

🚀 Build & Deploy'
```bash
docker build -t liquibase-mysql .
docker compose up -d --build
```
Liquibase will:
	•	Start MySQL
	•	Run your changelog.yaml
	•	Exit after applying the change
 
 ---
 
 ✅ Verify the Result
 ```bash
mysql -h 127.0.0.1 -P 3307 -u root -p
```
Then run:
```sql
USE mysql;
SHOW TABLES;
SELECT * FROM example_table;
```
You should see both your new table and Liquibase’s internal tracking tables:
databasechangelog and databasechangeloglock.

---

🧼 Cleanup
```bash
docker compose down -v
```
---

🤖 Optional: Deployment Script
Add a deploy.sh:
```bash
#!/bin/bash
set -e

# Load environment variables
set -o allexport
source .env
set +o allexport

# Generate liquibase.properties if templated
echo "Generating liquibase.properties from .env"
envsubst < liquibase/liquibase.properties.template > liquibase/liquibase.properties

# Build and run
echo "Building liquibase image"
docker build -t liquibase-mysql .

echo "Starting docker compose"
docker compose up --build
```

---

🎯 Conclusion

This setup provides a repeatable, isolated, and reliable environment for running Liquibase migrations against MySQL, without unstable runtime flags or classpath issues.
