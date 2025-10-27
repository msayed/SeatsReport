import axios from "axios";

const base = import.meta.env.VITE_API_BASE || "http://localhost:8081";

const api = axios.create({ baseURL: base });

let token: string | null = null;
export function setToken(t: string) { token = t; }
api.interceptors.request.use((cfg) => {
  if (token) cfg.headers.Authorization = `Bearer ${token}`;
  return cfg;
});

export type Row = Record<string, any>;

export async function login(username: string, password: string) {
  const { data } = await api.post("/api/auth/token", { username, password });
  setToken(data.access_token);
  return data;
}

export async function fetchReport(start: string, end: string, detailed = false): Promise<Row[]> {
  const url = detailed ? "/api/seats/report-details" : "/api/seats/report";
  const { data } = await api.get(url, { params: { start, end } });
  return data;
}

export async function downloadExcel(start: string, end: string, detailed = false) {
  const url = detailed ? "/api/seats/report-details.xlsx" : "/api/seats/report.xlsx";
  return api.get(url, { params: { start, end }, responseType: "blob" });
}
