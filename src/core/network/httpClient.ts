import axios, { AxiosInstance } from 'axios';
import { apiConstants } from '../constants/apiConstants';

let client: AxiosInstance | null = null;

export function getHttpClient(): AxiosInstance {
  if (!client) {
    client = axios.create({
      baseURL: apiConstants.baseUrl,
      timeout: 30000,
      headers: { 'Content-Type': 'application/json' },
    });
  }
  return client;
}
