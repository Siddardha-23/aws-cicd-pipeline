interface HeaderProps {
  title: string;
  onRefresh?: () => void;
}

export default function Header({ title, onRefresh }: HeaderProps) {
  return (
    <header className="bg-white border-b border-gray-200 px-8 py-4 flex items-center justify-between">
      <h2 className="text-2xl font-semibold text-gray-800">{title}</h2>
      {onRefresh && (
        <button
          onClick={onRefresh}
          className="px-4 py-2 text-sm bg-gray-100 hover:bg-gray-200 text-gray-700 rounded-lg transition-colors"
        >
          ↻ Refresh
        </button>
      )}
    </header>
  );
}
