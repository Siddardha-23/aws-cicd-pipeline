import { useState, useCallback } from 'react';
import Header from '../components/layout/Header';
import IncidentList from '../components/incidents/IncidentList';
import CreateIncidentModal from '../components/incidents/CreateIncidentModal';
import LoadingSpinner from '../components/common/LoadingSpinner';
import { useApi } from '../hooks/useApi';
import { getIncidents, createIncident, updateIncident } from '../api/endpoints';

export default function IncidentsPage() {
  const [showModal, setShowModal] = useState(false);
  const [statusFilter, setStatusFilter] = useState('');
  const [severityFilter, setSeverityFilter] = useState('');

  const fetchIncidents = useCallback(
    () => getIncidents({ status: statusFilter || undefined, severity: severityFilter || undefined }),
    [statusFilter, severityFilter]
  );
  const { data: incidents, loading, refetch } = useApi(fetchIncidents);

  const handleCreate = async (data: { title: string; description: string; severity: string }) => {
    await createIncident(data as Partial<import('../types').Incident>);
    setShowModal(false);
    refetch();
  };

  const handleResolve = async (id: number) => {
    await updateIncident(id, { status: 'resolved' });
    refetch();
  };

  return (
    <>
      <Header title="Incidents" onRefresh={refetch} />
      <main className="p-8">
        <div className="flex items-center justify-between mb-6">
          <div className="flex gap-4">
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="border border-gray-300 rounded-lg px-3 py-2 text-sm bg-white"
            >
              <option value="">All Statuses</option>
              <option value="open">Open</option>
              <option value="investigating">Investigating</option>
              <option value="resolved">Resolved</option>
              <option value="closed">Closed</option>
            </select>
            <select
              value={severityFilter}
              onChange={(e) => setSeverityFilter(e.target.value)}
              className="border border-gray-300 rounded-lg px-3 py-2 text-sm bg-white"
            >
              <option value="">All Severities</option>
              <option value="critical">Critical</option>
              <option value="high">High</option>
              <option value="medium">Medium</option>
              <option value="low">Low</option>
            </select>
          </div>
          <button
            onClick={() => setShowModal(true)}
            className="px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-lg hover:bg-blue-700"
          >
            Create Incident
          </button>
        </div>
        {loading ? <LoadingSpinner /> : incidents ? <IncidentList incidents={incidents} onResolve={handleResolve} /> : <p className="text-gray-500">Failed to load incidents.</p>}
      </main>
      {showModal && <CreateIncidentModal onClose={() => setShowModal(false)} onSubmit={handleCreate} />}
    </>
  );
}
