
import React from 'react';
import { ViewMode } from '../types';

interface NavigationProps {
  activeView: ViewMode;
  setView: (v: ViewMode) => void;
}

const Navigation: React.FC<NavigationProps> = ({ activeView, setView }) => {
  const items = [
    { id: ViewMode.SHELVES, icon: 'auto_stories', label: 'Shelves' },
    { id: ViewMode.ARCHIVE, icon: 'folder_managed', label: 'Archives' },
    { id: ViewMode.THREAD, icon: 'brightness_high', label: 'Thread' },
    { id: ViewMode.SETTINGS, icon: 'settings_suggest', label: 'Folio' },
  ];

  return (
    <nav className="fixed bottom-0 left-0 right-0 z-50 bg-folio-paper/95 backdrop-blur-xl border-t border-folio-border px-6 pb-8 pt-4">
      <div className="max-w-md mx-auto flex justify-between items-center">
        {items.map((item) => (
          <button
            key={item.id}
            onClick={() => setView(item.id)}
            className={`flex flex-col items-center gap-1 transition-all duration-300 ${
              activeView === item.id ? 'text-folio-accent scale-110' : 'text-folio-primary/40'
            }`}
          >
            <span 
              className="material-symbols-outlined"
              style={{ fontVariationSettings: `'FILL' ${activeView === item.id ? 1 : 0}` }}
            >
              {item.icon}
            </span>
            <span className="text-[9px] font-sans font-bold uppercase tracking-widest">{item.label}</span>
          </button>
        ))}
      </div>
    </nav>
  );
};

export default Navigation;
