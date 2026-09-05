# BookVault API

BookVault is a high-performance RESTful backend service architected with FastAPI, SQLModel, PostgreSQL, and Redis. It provides a secure, scalable foundation for book cataloging, user reviews, categorical tagging, and automated email workflows powered by Celery workers.

---

## Architectural Highlights

- **Layered Architecture**: Strict separation of concerns across route handlers, business services, domain models, and data access layers.
- **Asynchronous Data Layer**: Full async I/O database operations powered by SQLAlchemy and SQLModel on top of asyncpg.
- **Token Security and Blacklisting**: Stateless JWT access and refresh token authentication paired with Redis-backed revocation tracking for secure session termination.
- **Role-Based Access Control**: Granular endpoint authorization supporting administrative and standard user scopes.
- **Asynchronous Task Processing**: Decoupled background task execution using Celery and Redis to handle email dispatches, verification links, and password recovery workflows without blocking request threads.
- **Declarative Schema Migrations**: Relational schema evolution managed through Alembic migration scripts.
- **Input Validation and Error Handling**: Strict payload validation via Pydantic schemas accompanied by centralized exception handlers returning uniform error payloads.

---

## Technology Stack

- **Runtime**: Python 3.12
- **Framework**: FastAPI
- **Data Persistence**: PostgreSQL, SQLModel, SQLAlchemy (Async)
- **Caching and Broker**: Redis
- **Background Worker**: Celery, Flower
- **Database Migrations**: Alembic
- **Security and Hashing**: Passlib (Bcrypt), Python-Jose (JWT)
- **Containerization**: Docker, Docker Compose
- **Test Suite**: Pytest, HTTPX

---

## System Architecture and Request Flow

1. **Authentication Flow**:
   - Clients submit registration requests to `/api/v1/auth/signup`.
   - Celery queues an asynchronous verification email containing a signed token.
   - Upon email verification, users obtain short-lived access tokens and refresh tokens via `/api/v1/auth/login`.
   - Subsequent authenticated requests provide the Bearer token in the `Authorization` header.
   - Custom middleware verifies token validity against an active Redis revocation list before proceeding to route logic.

2. **Core Domain Flow**:
   - HTTP requests are validated against Pydantic schemas in the route layer.
   - Route handlers delegate operations to service classes encapsulating business logic and domain constraints.
   - The service layer interacts with the PostgreSQL database through asynchronous SQLModel sessions.
   - Normalized JSON responses and standard HTTP status codes are returned to the client.

---

## Quickstart with Docker

The fastest way to deploy BookVault alongside its database, cache, and worker dependencies is using Docker Compose.

### Prerequisites

- Docker Engine 24.0+
- Docker Compose v2+

### 1. Clone the Repository

```bash
git clone https://github.com/rashi-raturi/book-vault.git
cd book-vault
```

### 2. Configure Environment Variables

Copy the provided sample configuration:

```bash
cp .env.example .env
```

Ensure the values in `.env` match your desired local or container configuration. The default Docker Compose setup provides automated networking between services.

### 3. Build and Start All Services

Run the following command to spin up PostgreSQL, Redis, the FastAPI application, and the Celery worker:

```bash
docker compose up --build -d
```

### 4. Verify Service Health

Inspect container statuses:

```bash
docker compose ps
```

View application logs:

```bash
docker compose logs -f api
```

The API will automatically apply database migrations on startup and bind to `http://localhost:8000`.

Interactive documentation is available at:
- Swagger UI: `http://localhost:8000/api/v1/docs`
- ReDoc: `http://localhost:8000/api/v1/redoc`

---

## Local Development Setup

If you prefer running services directly on your host machine:

### Prerequisites

- Python 3.12 or higher
- PostgreSQL 15+
- Redis 7+

### 1. Virtual Environment Setup

```bash
python -m venv .venv

# On Linux / macOS:
source .venv/bin/activate

# On Windows (PowerShell):
.venv\Scripts\Activate.ps1
```

### 2. Install Dependencies

```bash
pip install -r requirements.txt
```

### 3. Environment Configuration

Create a `.env` file in the project root:

```env
DATABASE_URL=postgresql+asyncpg://postgres:postgres@localhost:5432/bookvault_db
JWT_SECRET=replace_with_a_secure_random_secret_key
JWT_ALGORITHM=HS256
REDIS_URL=redis://localhost:6379/0

MAIL_USERNAME=your_email@gmail.com
MAIL_PASSWORD=your_app_password
MAIL_SERVER=smtp.gmail.com
MAIL_PORT=587
MAIL_FROM=your_email@gmail.com
MAIL_FROM_NAME=BookVault

DOMAIN=localhost:8000

POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=bookvault_db
```

### 4. Database Initialization

Ensure PostgreSQL and Redis are running locally, then execute database schema migrations:

```bash
alembic upgrade head
```

### 5. Launch Services

Start the Celery worker (in a dedicated shell):

```bash
celery -A src.celery_tasks.c_app worker --loglevel=INFO
```

Start the FastAPI application with auto-reload:

```bash
uvicorn src:app --host 0.0.0.0 --port 8000 --reload
```

---

## API Endpoints Reference

### Authentication (`/api/v1/auth`)

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `POST` | `/signup` | Register a new user account |
| `POST` | `/login` | Authenticate credentials and issue JWT tokens |
| `GET` | `/verify/{token}` | Verify user email address |
| `POST` | `/refresh-token` | Generate a new access token using a refresh token |
| `POST` | `/logout` | Revoke active token session via Redis blacklist |
| `GET` | `/me` | Retrieve authenticated user profile |
| `POST` | `/password-reset-request` | Request a password reset email |
| `POST` | `/password-reset-confirm/{token}` | Finalize password reset with new credentials |

### Books Catalog (`/api/v1/books`)

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `GET` | `/` | Paginated listing of books with optional filters |
| `POST` | `/` | Add a new book to the catalog |
| `GET` | `/{book_uid}` | Fetch detailed metadata for a specific book |
| `PATCH` | `/{book_uid}` | Update book details (author or admin only) |
| `DELETE` | `/{book_uid}` | Remove a book from the system |

### Reviews and Ratings (`/api/v1/reviews`)

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `POST` | `/books/{book_uid}/reviews` | Post a rating and review for a book |
| `DELETE` | `/books/{book_uid}/reviews/{review_uid}` | Delete a user review |

### Tag Management (`/api/v1/tags`)

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `GET` | `/` | List all available category tags |
| `POST` | `/` | Create a new categorization tag |
| `POST` | `/books/{book_uid}/tags` | Associate tags with an existing book |
| `DELETE` | `/books/{book_uid}/tags/{tag_uid}` | Dissociate a tag from a book |

---

## Testing

Execute the automated test suite using Pytest:

```bash
pytest src/tests/ -v
```

---

## Author

- **Rashi Raturi** - [GitHub Profile](https://github.com/rashi-raturi)
