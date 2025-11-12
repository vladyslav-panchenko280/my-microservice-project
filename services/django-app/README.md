# Django Web Application with PostgreSQL and Nginx

This project demonstrates a containerized Django web application integrated with PostgreSQL database and Nginx reverse proxy. The implementation showcases modern DevOps practices including containerization, environment variable configuration, and production-ready web server setup.

## Project Overview

The application consists of three main components:
- Django Web Service: A Python-based web framework with database connectivity
- PostgreSQL Database: Containerized relational database for data persistence
- Nginx Reverse Proxy: High-performance web server for request routing and load balancing

## Tech Stack

- Backend: Django 4.2 (Python web framework)
- Database: PostgreSQL 14
- ORM: Django ORM
- Containerization: Docker & Docker Compose
- Web Server: Nginx (reverse proxy)
- Configuration: Environment variables
- Python: 3.10

## Architecture

The project utilizes Docker Compose for orchestration, providing a complete development and deployment environment. The Django application connects to PostgreSQL through environment variables, while Nginx handles incoming requests and routes them to the Django backend, ensuring configuration flexibility and security.

## Prerequisites

- Docker and Docker Compose installed on your system
- Git for repository cloning

## Installation and Deployment

1. Clone the repository:
```bash
git clone <repository-url>
cd django-base-infrastructure
```

2. Create environment file:
```bash
cp .env.example .env
# Edit .env file with your database credentials
```

3. Start the application stack:
```bash
docker-compose up --build
```

4. Access the services:
   - **Django Application**: http://localhost:8000
   - **Nginx Proxy**: http://localhost:80
   - **PostgreSQL Database**: localhost:5432

5. Stop the services:
```bash
docker-compose down
```

## Configuration

The application uses environment variables for database connectivity:

- `POSTGRES_HOST`: Database hostname (default: db)
- `POSTGRES_PORT`: Database port (default: 5432)
- `POSTGRES_NAME`: Database name
- `POSTGRES_USER`: PostgreSQL username
- `POSTGRES_PASSWORD`: PostgreSQL password

## Development Setup

For local development without Docker:

1. Create virtual environment:
```bash
python3 -m venv .venv
source .venv/bin/activate
```

2. Install dependencies:
```bash
pip install -r djangoapp/requirements.txt
```

3. Run migrations:
```bash
cd djangoapp
python manage.py migrate
```

4. Start development server:
```bash
python manage.py runserver
```

## Project Structure

```
django-base-infrastructure/
├── docker-compose.yml          # Container orchestration
├── djangoapp/                  # Django application
│   ├── Dockerfile              # Application container
│   ├── manage.py               # Django management script
│   ├── requirements.txt        # Python dependencies
│   └── djangoapp/              # Django project settings
│       ├── settings.py         # Django configuration
│       ├── urls.py             # URL routing
│       ├── wsgi.py             # WSGI application
│       └── asgi.py             # ASGI application
└── nginx/                      # Nginx configuration
    └── default.conf             # Reverse proxy setup
```
