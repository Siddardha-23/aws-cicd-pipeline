import { useCallback } from 'react';
import Header from '../components/layout/Header';
import StatsCard from '../components/dashboard/StatsCard';
import RecentDeployments from '../components/dashboard/RecentDeployments';
import LoadingSpinner from '../components/common/LoadingSpinner';
import { useApi } from '../hooks/useApi';
import { getDashboardStats } from '../api/endpoints';

export default function DashboardPage() {
  const fetchStats = useCallback(() => getDashboardStats(), []);
  const { data: stats, loading, refetch } = useApi(fetchStats);

  return (
    <>
      <Header title="Dashboard" onRefresh={refetch} />
      <main className="p-8">
        {loading ? (
          <LoadingSpinner />
        ) : stats ? (
          <div className="space-y-8">
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
              <StatsCard label="Deployments Today" value={stats.deployments_today} icon="▲" color="text-blue-500" />
              <StatsCard label="Success Rate" value={`${stats.success_rate.toFixed(1)}%`} icon="✓" color="text-green-500" />
              <StatsCard label="Open Incidents" value={stats.open_incidents} icon="⚠" color="text-yellow-500" />
              <StatsCard label="Services Healthy" value={`${stats.healthy_services}/${stats.total_services}`} icon="◉" color="text-green-500" />
            </div>
            <RecentDeployments deployments={stats.recent_deployments} />
          </div>
        ) : (
          <p className="text-gray-500">Failed to load dashboard data.</p>
        )}
      </main>
    </>
  );
}
