import { useCallback } from 'react';
import Header from '../components/layout/Header';
import ServiceCard from '../components/services/ServiceCard';
import LoadingSpinner from '../components/common/LoadingSpinner';
import { useApi } from '../hooks/useApi';
import { getServices } from '../api/endpoints';

export default function ServicesPage() {
  const fetchServices = useCallback(() => getServices(), []);
  const { data: services, loading, refetch } = useApi(fetchServices);

  return (
    <>
      <Header title="Services" onRefresh={refetch} />
      <main className="p-8">
        {loading ? (
          <LoadingSpinner />
        ) : services ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {services.map((service) => (
              <ServiceCard key={service.id} service={service} />
            ))}
          </div>
        ) : (
          <p className="text-gray-500">Failed to load services.</p>
        )}
      </main>
    </>
  );
}
