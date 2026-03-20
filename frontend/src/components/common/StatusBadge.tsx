interface StatusBadgeProps {
  status: string;
}

const statusColors: Record<string, string> = {
  success: 'bg-green-100 text-green-800',
  healthy: 'bg-green-100 text-green-800',
  failed: 'bg-red-100 text-red-800',
  down: 'bg-red-100 text-red-800',
  critical: 'bg-red-100 text-red-800',
  in_progress: 'bg-yellow-100 text-yellow-800',
  investigating: 'bg-yellow-100 text-yellow-800',
  degraded: 'bg-orange-100 text-orange-800',
  high: 'bg-orange-100 text-orange-800',
  rolled_back: 'bg-blue-100 text-blue-800',
  medium: 'bg-blue-100 text-blue-800',
  open: 'bg-gray-100 text-gray-800',
  low: 'bg-gray-100 text-gray-800',
  resolved: 'bg-green-100 text-green-800',
  closed: 'bg-gray-100 text-gray-600',
};

export default function StatusBadge({ status }: StatusBadgeProps) {
  const colors = statusColors[status] || 'bg-gray-100 text-gray-800';
  return (
    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${colors}`}>
      {status.replace('_', ' ')}
    </span>
  );
}
