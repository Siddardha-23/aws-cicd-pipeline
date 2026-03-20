import { useState, useCallback } from 'react';
import Header from '../components/layout/Header';
import DeploymentTable from '../components/deployments/DeploymentTable';
import LoadingSpinner from '../components/common/LoadingSpinner';
import { useApi } from '../hooks/useApi';
import { getDeployments } from '../api/endpoints';

export default function DeploymentsPage() {
  const [statusFilter, setStatusFilter] = useState('');
  const [envFilter, setEnvFilter] = useState('');

  const fetchDeployments = useCallback(
    () => getDeployments({ status: statusFilter || undefined, environment: envFilter || undefined }),
    [statusFilter, envFilter]
  );
  const { data, loading, refetch } = useApi(fetchDeployments);

  return (
    <>
      <Header title="Deployments" onRefresh={refetch} />
      <main className="p-8">
        <div className="flex gap-4 mb-6">
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="border border-gray-300 rounded-lg px-3 py-2 text-sm bg-white"
          >
            <option value="">All Statuses</option>
            <option value="success">Success</option>
            <option value="failed">Failed</option>
            <option value="in_progress">In Progress</option>
            <option value="rolled_back">Rolled Back</option>
          </select>
          <select
            value={envFilter}
            onChange={(e) => setEnvFilter(e.target.value)}
            className="border border-gray-300 rounded-lg px-3 py-2 text-sm bg-white"
          >
            <option value="">All Environments</option>
            <option value="production">Production</option>
            <option value="staging">Staging</option>
            <option value="development">Development</option>
          </select>
        </div>
        {loading ? <LoadingSpinner /> : data ? <DeploymentTable deployments={data.deployments} /> : <p className="text-gray-500">Failed to load deployments.</p>}
      </main>
    </>
  );
}
