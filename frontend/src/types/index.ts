export interface User {
  id: number;
  username: string;
  email: string;
  role: 'admin' | 'engineer' | 'viewer';
}

export interface Deployment {
  id: number;
  service_name: string;
  environment: 'production' | 'staging' | 'development';
  status: 'success' | 'failed' | 'in_progress' | 'rolled_back';
  commit_sha: string;
  commit_message: string;
  deployed_by: string;
  duration_seconds: number | null;
  created_at: string;
}

export interface Service {
  id: number;
  name: string;
  status: 'healthy' | 'degraded' | 'down';
  uptime_percentage: number;
  last_checked: string;
  endpoint_url: string;
  description: string;
}

export interface Incident {
  id: number;
  title: string;
  description: string;
  severity: 'critical' | 'high' | 'medium' | 'low';
  status: 'open' | 'investigating' | 'resolved' | 'closed';
  assigned_to: string | null;
  service_id: number | null;
  created_at: string;
  resolved_at: string | null;
}

export interface DashboardStats {
  total_deployments: number;
  deployments_today: number;
  success_rate: number;
  total_services: number;
  healthy_services: number;
  degraded_services: number;
  down_services: number;
  open_incidents: number;
  critical_incidents: number;
  recent_deployments: Deployment[];
}
