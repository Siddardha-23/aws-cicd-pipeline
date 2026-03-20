import Card from '../common/Card';

interface StatsCardProps {
  label: string;
  value: string | number;
  icon: string;
  color?: string;
}

export default function StatsCard({ label, value, icon, color = 'text-blue-500' }: StatsCardProps) {
  return (
    <Card>
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm text-gray-500">{label}</p>
          <p className="text-3xl font-bold text-gray-900 mt-1">{value}</p>
        </div>
        <span className={`text-3xl ${color}`}>{icon}</span>
      </div>
    </Card>
  );
}
