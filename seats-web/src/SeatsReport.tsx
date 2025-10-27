import { useState } from "react";
import { DataGrid, GridColDef } from "@mui/x-data-grid";
import {
  Button,
  Stack,
  Box,
  Typography,
  TextField,
  Paper,
  Divider,
  Alert,
} from "@mui/material";
import { fetchReport, downloadExcel, Row, login, logout } from "./api";

type AuthInfo = {
  username: string;
  fullname: string;
};

const AUTH_INFO_KEY = "auth_info";

const getStoredAuthInfo = (): AuthInfo | null => {
  if (typeof window === "undefined") return null;
  const raw = window.localStorage.getItem(AUTH_INFO_KEY);
  if (!raw) return null;
  try {
    return JSON.parse(raw) as AuthInfo;
  } catch {
    return null;
  }
};

export default function SeatsReport() {
  const [start, setStart] = useState<string>(new Date().toISOString().slice(0, 10));
  const [end, setEnd] = useState<string>(new Date().toISOString().slice(0, 10));
  const [rows, setRows] = useState<Row[]>([]);
  const [columns, setColumns] = useState<GridColDef[]>([]);
  const [loading, setLoading] = useState(false);
  const [authInfo, setAuthInfo] = useState<AuthInfo | null>(() => getStoredAuthInfo());
  const [username, setUsername] = useState(authInfo?.username ?? "");
  const [password, setPassword] = useState("");
  const [loginLoading, setLoginLoading] = useState(false);
  const [loginError, setLoginError] = useState<string | null>(null);

  const isAuthenticated = Boolean(authInfo);

  const doLogin = async () => {
    setLoginError(null);
    setLoginLoading(true);
    try {
      const res = await login(username, password);
      const info: AuthInfo = {
        username: res.username ?? username,
        fullname: res.fullname || res.username || username,
      };
      setAuthInfo(info);
      setUsername(info.username);
      if (typeof window !== "undefined") {
        window.localStorage.setItem(AUTH_INFO_KEY, JSON.stringify(info));
      }
      setPassword("");
    } catch (err: any) {
      if (err?.response?.status === 401) {
        setLoginError("Invalid username or password.");
      } else if (err?.response?.data?.error) {
        setLoginError(String(err.response.data.error));
      } else {
        setLoginError("Unable to login. Please try again.");
      }
    } finally {
      setLoginLoading(false);
    }
  };

  const onSearch = async (detailed = false) => {
    if (!isAuthenticated) {
      setLoginError("Please login before requesting a report.");
      return;
    }
    setLoading(true);
    try {
      const data = await fetchReport(start, end, detailed);

      // API بيرجع { columns: [...], rows: [...] }
      const reportRows = data.rows || [];
      const reportCols = data.columns || [];

      const withId = reportRows.map((r: Row, i: number) => ({ id: i + 1, ...r }));
      setRows(withId);

      // بناء الأعمدة تلقائيًا من الكيز
      if (reportRows.length > 0) {
        const cols: GridColDef[] = Object.keys(reportRows[0])
          .filter((k) => k !== "id")
          .map((k) => ({
            field: k,
            headerName: k,
            width: 160,
            headerAlign: "center",
            align: "center",
            renderCell: (params) => {
              if (k.toLowerCase() === "airportupgrade") {
                const val = Number(params.value ?? 0);
                return (
                  <strong style={{ color: val > 0 ? "#1976d2" : "#333" }}>
                    {params.value}
                  </strong>
                );
              }
              return <span>{String(params.value ?? "")}</span>;
            },
          }));
        setColumns(cols);
      } else setColumns([]);
    } finally {
      setLoading(false);
    }
  };

  const onExport = async (detailed = false) => {
    if (!isAuthenticated) {
      setLoginError("Please login before exporting a report.");
      return;
    }
    const res = await downloadExcel(start, end, detailed);
    const blob = new Blob([res.data], {
      type:
        res.headers["content-type"] ||
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = detailed
      ? "seats-report-details.xlsx"
      : "seats-report.xlsx";
    a.click();
    URL.revokeObjectURL(url);
  };

  const onLogout = () => {
    logout();
    setAuthInfo(null);
    setLoginError(null);
    setPassword("");
    if (typeof window !== "undefined") {
      window.localStorage.removeItem(AUTH_INFO_KEY);
    }
    setRows([]);
    setColumns([]);
  };

  return (
    <Box sx={{ p: 3, bgcolor: "#f9f9f9", minHeight: "100vh" }}>
      <Paper elevation={3} sx={{ p: 3, borderRadius: 3 }}>
        <Typography variant="h5" gutterBottom color="primary">
          🛫 Seats Report Dashboard
        </Typography>
        <Divider sx={{ mb: 2 }} />

        {loginError && (
          <Alert severity="error" sx={{ mb: 2 }} onClose={() => setLoginError(null)}>
            {loginError}
          </Alert>
        )}

        <Stack
          direction={{ xs: "column", sm: "row" }}
          spacing={2}
          alignItems="center"
          mb={2}
        >
          <TextField
            label="Username"
            value={username}
            onChange={(e) => setUsername(e.target.value)}
            disabled={loginLoading}
          />
          <TextField
            label="Password"
            value={password}
            type="password"
            onChange={(e) => setPassword(e.target.value)}
            disabled={loginLoading}
          />
          <Stack direction="row" spacing={1} alignItems="center">
            <Button
              variant="outlined"
              onClick={doLogin}
              disabled={loginLoading || !username || !password}
            >
              {loginLoading ? "Logging in..." : "Login"}
            </Button>
            {isAuthenticated && (
              <Button variant="text" color="error" onClick={onLogout}>
                Logout
              </Button>
            )}
          </Stack>
        </Stack>

        {isAuthenticated && (
          <Typography variant="body2" sx={{ mb: 2 }}>
            Welcome back, <strong>{authInfo?.fullname || authInfo?.username}</strong>
          </Typography>
        )}

        <Stack
          direction={{ xs: "column", sm: "row" }}
          spacing={2}
          alignItems="center"
          mb={2}
        >
          <TextField
            label="Start Date"
            type="date"
            value={start}
            onChange={(e) => setStart(e.target.value)}
            InputLabelProps={{ shrink: true }}
          />
          <TextField
            label="End Date"
            type="date"
            value={end}
            onChange={(e) => setEnd(e.target.value)}
            InputLabelProps={{ shrink: true }}
          />

          <Button
            variant="contained"
            color="primary"
            onClick={() => onSearch(false)}
            disabled={!isAuthenticated || loading}
          >
            Summary
          </Button>
          <Button
            variant="contained"
            color="secondary"
            onClick={() => onSearch(true)}
            disabled={!isAuthenticated || loading}
          >
            Details
          </Button>

          <Button variant="text" onClick={() => onExport(false)} disabled={!isAuthenticated}>
            ⬇️ Export
          </Button>
          <Button variant="text" onClick={() => onExport(true)} disabled={!isAuthenticated}>
            ⬇️ Export Details
          </Button>
        </Stack>

        <div style={{ height: 600, width: "100%" }}>
          <DataGrid
            rows={rows}
            columns={columns}
            loading={loading}
            pageSizeOptions={[25, 50, 100]}
            sx={{
              "& .MuiDataGrid-columnHeaders": { backgroundColor: "#1976d2", color: "#fff" },
              "& .MuiDataGrid-cell": { fontSize: "0.9rem" },
              borderRadius: 2,
              backgroundColor: "#fff",
            }}
          />
        </div>
      </Paper>
    </Box>
  );
}
