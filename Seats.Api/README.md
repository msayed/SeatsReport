# Seats.Api (.NET 8)
- Endpoints require JWT Bearer.
- Get token:
  POST /api/auth/token  { "username":"admin", "password":"P@ssw0rd!" }
- Use the `access_token` in `Authorization: Bearer <token>`.

## Run locally
```
dotnet restore
dotnet run
```

## Docker
```
docker build -t seats-api .
docker run -p 8080:8080 seats-api
```
