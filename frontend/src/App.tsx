import { Routes, Route } from 'react-router-dom';
import Layout from './components/layout/Layout';
import DashboardPage from './pages/DashboardPage';
import DeploymentsPage from './pages/DeploymentsPage';
import ServicesPage from './pages/ServicesPage';
import IncidentsPage from './pages/IncidentsPage';

function App() {
  return (
    <Routes>
      <Route path="/" element={<Layout />}>
        <Route index element={<DashboardPage />} />
        <Route path="deployments" element={<DeploymentsPage />} />
        <Route path="services" element={<ServicesPage />} />
        <Route path="incidents" element={<IncidentsPage />} />
      </Route>
    </Routes>
  );
}

export default App;
