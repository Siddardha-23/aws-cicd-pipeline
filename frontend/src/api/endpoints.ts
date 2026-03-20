import client from './client';
import type { DashboardStats, Deployment, Service, Incident } from '../types';

export const getDashboardStats = () =>
  client.get<DashboardStats>('/dashboard/stats').then(res => res.data);

export const getDeployments = (params?: { status?: string; environment?: string; page?: number }) =>
  client.get<{ deployments: Deployment[]; total: number; page: number; pages: number }>('/deployments', { params }).then(res => res.data);

export const getServices = () =>
  client.get<Service[]>('/services').then(res => res.data);

export const getService = (id: number) =>
  client.get<Service>(`/services/${id}`).then(res => res.data);

export const updateService = (id: number, data: Partial<Service>) =>
  client.patch<Service>(`/services/${id}`, data).then(res => res.data);

export const getIncidents = (params?: { status?: string; severity?: string }) =>
  client.get<Incident[]>('/incidents', { params }).then(res => res.data);

export const createIncident = (data: Partial<Incident>) =>
  client.post<Incident>('/incidents', data).then(res => res.data);

export const updateIncident = (id: number, data: Partial<Incident>) =>
  client.patch<Incident>(`/incidents/${id}`, data).then(res => res.data);
