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
} from "@mui/material";
import { fetchReport, downloadExcel, Row, login } from "./api";

export default function SeatsReport() {
  const [start, setStart] = useState<string>(new Date().toISOString().slice(0, 10));
  const [end, setEnd] = useState<string>(new Date().toISOString().slice(0, 10));
  const [rows, setRows] = useState<Row[]>([]);
  const [columns, setColumns] = useState<GridColDef[]>([]);
  const [loading, setLoading] = useState(false);
  const [username, setUsername] = useState("admin");
  const [password, setPassword] = useState("P@ssw0rd!");

  const doLogin = async () => {
    await login(username, password);
  };

  const onSearch = async (detailed = false) => {
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

  return (
    <Box sx={{ p: 3, bgcolor: "#f9f9f9", minHeight: "100vh" }}>
      <Paper elevation={3} sx={{ p: 3, borderRadius: 3 }}>
        <Typography variant="h5" gutterBottom color="primary">
          🛫 Seats Report Dashboard
        </Typography>
        <Divider sx={{ mb: 2 }} />

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
          />
          <TextField
            label="Password"
            value={password}
            type="password"
            onChange={(e) => setPassword(e.target.value)}
          />
          <Button variant="outlined" onClick={doLogin}>
            Login
          </Button>
        </Stack>

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
          >
            Summary
          </Button>
          <Button
            variant="contained"
            color="secondary"
            onClick={() => onSearch(true)}
          >
            Details
          </Button>

          <Button variant="text" onClick={() => onExport(false)}>
            ⬇️ Export
          </Button>
          <Button variant="text" onClick={() => onExport(true)}>
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
