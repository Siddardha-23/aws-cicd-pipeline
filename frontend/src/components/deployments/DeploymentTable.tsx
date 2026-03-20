import type { Deployment } from '../../types';
import StatusBadge from '../common/StatusBadge';
import Card from '../common/Card';

interface DeploymentTableProps {
  deployments: Deployment[];
}

export default function DeploymentTable({ deployments }: DeploymentTableProps) {
  const formatDuration = (seconds: number | null) => {
    if (!seconds) return '-';
    if (seconds < 60) return `${seconds}s`;
    return `${Math.floor(seconds / 60)}m ${seconds % 60}s`;
  };

  return (
    <Card>
      <div className="overflow-x-auto">
        <table className="w-full text-sm">
          <thead>
            <tr className="text-left text-gray-500 border-b">
              <th className="pb-3 font-medium">Service</th>
              <th className="pb-3 font-medium">Environment</th>
              <th className="pb-3 font-medium">Status</th>
              <th className="pb-3 font-medium">Commit</th>
              <th className="pb-3 font-medium">Message</th>
              <th className="pb-3 font-medium">Deployed By</th>
              <th className="pb-3 font-medium">Duration</th>
              <th className="pb-3 font-medium">Time</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {deployments.map((d) => (
              <tr key={d.id} className="hover:bg-gray-50">
                <td className="py-3 font-medium text-gray-900">{d.service_name}</td>
                <td className="py-3"><StatusBadge status={d.environment} /></td>
                <td className="py-3"><StatusBadge status={d.status} /></td>
                <td className="py-3 font-mono text-xs text-gray-600">{d.commit_sha}</td>
                <td className="py-3 text-gray-600 max-w-xs truncate">{d.commit_message}</td>
                <td className="py-3 text-gray-600">{d.deployed_by}</td>
                <td className="py-3 text-gray-600">{formatDuration(d.duration_seconds)}</td>
                <td className="py-3 text-gray-500 whitespace-nowrap">{new Date(d.created_at).toLocaleString()}</td>
              </tr>
            ))}
          </tbody>
        </table>
        {deployments.length === 0 && (
          <p className="text-center text-gray-400 py-8">No deployments found</p>
        )}
      </div>
    </Card>
  );
}
