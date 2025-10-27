# seats-web (React + Vite)
- Set `VITE_API_BASE` to your API URL (default http://localhost:8080).
- Click **Login** first, then run the reports.

## Dev
```
npm i
npm run dev
```

## Docker
```
# Build with API base injected
docker build -t seats-web --build-arg VITE_API_BASE=http://localhost:8080 .
docker run -p 8081:80 seats-web
```
