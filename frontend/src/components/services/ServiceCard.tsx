import type { Service } from '../../types';
import StatusBadge from '../common/StatusBadge';
import Card from '../common/Card';

interface ServiceCardProps {
  service: Service;
}

export default function ServiceCard({ service }: ServiceCardProps) {
  return (
    <Card>
      <div className="flex items-start justify-between mb-4">
        <h3 className="text-lg font-semibold text-gray-900">{service.name}</h3>
        <StatusBadge status={service.status} />
      </div>
      <p className="text-sm text-gray-500 mb-4">{service.description}</p>
      <div className="space-y-3">
        <div>
          <div className="flex justify-between text-sm mb-1">
            <span className="text-gray-500">Uptime</span>
            <span className="font-medium text-gray-900">{service.uptime_percentage.toFixed(2)}%</span>
          </div>
          <div className="w-full bg-gray-200 rounded-full h-2">
            <div
              className={`h-2 rounded-full ${
                service.uptime_percentage >= 99.9 ? 'bg-green-500' :
                service.uptime_percentage >= 99 ? 'bg-yellow-500' : 'bg-red-500'
              }`}
              style={{ width: `${Math.min(service.uptime_percentage, 100)}%` }}
            />
          </div>
        </div>
        <div className="flex justify-between text-sm">
          <span className="text-gray-500">Last checked</span>
          <span className="text-gray-700">{new Date(service.last_checked).toLocaleString()}</span>
        </div>
        {service.endpoint_url && (
          <div className="text-sm">
            <span className="text-gray-500">Endpoint: </span>
            <span className="font-mono text-xs text-blue-600">{service.endpoint_url}</span>
          </div>
        )}
      </div>
    </Card>
  );
}
