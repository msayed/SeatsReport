# SeatsSolution
This bundle includes:
- Seats.Api (.NET 8) with JWT authentication and Excel export
- seats-web (React + Vite) with login + report screens
- Dockerfiles for both + docker-compose
- Place your real SQL files under `Seats.Api/Sql/`

## Quick start (Docker Compose)
```
docker compose build
docker compose up
```
Web: http://localhost:8081
API: http://localhost:8080
Login: admin / P@ssw0rd!
```

## Local Dev
- API: `dotnet run` (listens on 8080 via ASPNETCORE_URLS)
- Web: `npm run dev` (set VITE_API_BASE in `.env`)
