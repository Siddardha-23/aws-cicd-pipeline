import type { Incident } from '../../types';
import StatusBadge from '../common/StatusBadge';
import Card from '../common/Card';

interface IncidentListProps {
  incidents: Incident[];
  onResolve?: (id: number) => void;
}

export default function IncidentList({ incidents, onResolve }: IncidentListProps) {
  return (
    <Card>
      <div className="space-y-4">
        {incidents.map((incident) => (
          <div key={incident.id} className="border border-gray-100 rounded-lg p-4 hover:bg-gray-50">
            <div className="flex items-start justify-between">
              <div className="flex-1">
                <h4 className="font-medium text-gray-900">{incident.title}</h4>
                <p className="text-sm text-gray-500 mt-1">{incident.description}</p>
              </div>
              <div className="flex gap-2 ml-4">
                <StatusBadge status={incident.severity} />
                <StatusBadge status={incident.status} />
              </div>
            </div>
            <div className="flex items-center justify-between mt-3 text-sm text-gray-500">
              <div className="flex gap-4">
                <span>Assigned: {incident.assigned_to || 'Unassigned'}</span>
                <span>Created: {new Date(incident.created_at).toLocaleString()}</span>
                {incident.resolved_at && (
                  <span>Resolved: {new Date(incident.resolved_at).toLocaleString()}</span>
                )}
              </div>
              {onResolve && (incident.status === 'open' || incident.status === 'investigating') && (
                <button
                  onClick={() => onResolve(incident.id)}
                  className="text-green-600 hover:text-green-800 font-medium"
                >
                  Resolve
                </button>
              )}
            </div>
          </div>
        ))}
        {incidents.length === 0 && (
          <p className="text-center text-gray-400 py-8">No incidents found</p>
        )}
      </div>
    </Card>
  );
}
