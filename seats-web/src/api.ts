import axios from "axios";

const base = import.meta.env.VITE_API_BASE || "http://localhost:8081";

const api = axios.create({ baseURL: base });

const TOKEN_KEY = "auth_token";
let token: string | null = typeof window !== "undefined" ? window.localStorage.getItem(TOKEN_KEY) : null;

export function setToken(t: string | null) {
  token = t;
  if (typeof window === "undefined") return;
  if (t) {
    window.localStorage.setItem(TOKEN_KEY, t);
  } else {
    window.localStorage.removeItem(TOKEN_KEY);
  }
}
api.interceptors.request.use((cfg) => {
  if (token) cfg.headers.Authorization = `Bearer ${token}`;
  return cfg;
});

export type Row = Record<string, any>;

export interface LoginResponse {
  access_token: string;
  token_type: string;
  username?: string;
  fullname?: string;
}

export async function login(username: string, password: string): Promise<LoginResponse> {
  const { data } = await api.post<LoginResponse>("/api/auth/token", { username, password });
  setToken(data.access_token);
  return data;
}

export function logout() {
  setToken(null);
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
