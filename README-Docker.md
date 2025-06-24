# Docker Setup for Solar Energy Sentiment Analyzer

This document provides instructions for running the Solar Energy Sentiment Analyzer application using Docker.

## Prerequisites

- Docker installed on your system
- Docker Compose installed on your system

## Quick Start

### 1. Build and Run with Docker Compose (Recommended)

```bash
# Build and start the application
docker-compose up --build

# Run in detached mode
docker-compose up -d --build
```

The application will be available at `http://localhost:3000`

### 2. Build and Run with Docker directly

```bash
# Build the Docker image
docker build -t sentiment-analyzer .

# Run the container
docker run -p 3000:3000 -v $(pwd)/db:/app/db -v $(pwd)/storage:/app/storage sentiment-analyzer
```

## Environment Variables

You can customize the application behavior by setting environment variables:

- `RAILS_ENV`: Set to `production` (default) or `development`
- `RAILS_SERVE_STATIC_FILES`: Set to `true` to serve static assets
- `RAILS_LOG_TO_STDOUT`: Set to `true` to log to stdout
- `DATABASE_URL`: SQLite database URL (default: `sqlite3:/app/db/production.sqlite3`)

## Database

The application uses SQLite as the database. The database file is stored in a Docker volume to persist data between container restarts.

### Database Operations

```bash
# Run database migrations
docker-compose exec web bundle exec rails db:migrate

# Reset database
docker-compose exec web bundle exec rails db:reset

# Seed database (if you have seeds)
docker-compose exec web bundle exec rails db:seed
```

## Logs

```bash
# View application logs
docker-compose logs web

# Follow logs in real-time
docker-compose logs -f web
```

## Stopping the Application

```bash
# Stop the application
docker-compose down

# Stop and remove volumes (WARNING: This will delete your database)
docker-compose down -v
```

## Development with Docker

For development, you can mount the source code as a volume:

```bash
docker run -p 3000:3000 \
  -v $(pwd):/app \
  -v $(pwd)/db:/app/db \
  -v $(pwd)/storage:/app/storage \
  -e RAILS_ENV=development \
  sentiment-analyzer
```

## Production Deployment

For production deployment, consider:

1. Using a production database like PostgreSQL
2. Setting up proper SSL/TLS certificates
3. Configuring environment variables for production
4. Setting up monitoring and logging
5. Using a reverse proxy like Nginx

### Example Production Environment Variables

```bash
RAILS_ENV=production
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_TO_STDOUT=true
SECRET_KEY_BASE=your_secret_key_here
DATABASE_URL=sqlite3:/app/db/production.sqlite3
```

## Troubleshooting

### Common Issues

1. **Port already in use**: Change the port mapping in docker-compose.yml
2. **Permission issues**: Ensure the db, storage, and log directories exist and are writable
3. **Database connection issues**: Check that the database file is properly mounted

### Debugging

```bash
# Access the container shell
docker-compose exec web bash

# Check Rails logs
docker-compose exec web tail -f log/production.log

# Check database status
docker-compose exec web bundle exec rails db:version
```

## Security Considerations

- The application runs as a non-root user inside the container
- Database files are persisted in volumes
- Environment variables should be properly configured for production
- Consider using Docker secrets for sensitive information

## Performance Optimization

- The Docker image includes precompiled assets
- SQLite database is optimized for the container environment
- Health checks are configured to monitor application status
- The container uses Ubuntu 24.04 LTS for stability and security updates 