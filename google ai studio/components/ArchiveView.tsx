
import React, { useState, useMemo } from 'react';
import { MemoCard } from '../types';

interface ArchiveViewProps {
  cards: MemoCard[];
  onSelect: (card: MemoCard) => void;
}

const ArchiveView: React.FC<ArchiveViewProps> = ({ cards, onSelect }) => {
  const [searchTerm, setSearchTerm] = useState('');

  const filteredCards = useMemo(() => {
    if (!searchTerm) return cards;
    const term = searchTerm.toLowerCase();
    return cards.filter(c => 
      c.title.toLowerCase().includes(term) || 
      c.summary.toLowerCase().includes(term) ||
      c.category.toLowerCase().includes(term) ||
      c.tags.some(t => t.toLowerCase().includes(term))
    );
  }, [cards, searchTerm]);

  return (
    <div className="animate-fade-in">
      <div className="px-6 pt-6 pb-4">
        <div className="relative flex items-center">
          <span className="material-symbols-outlined absolute left-3 text-folio-primary/30">search</span>
          <input 
            type="text" 
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            placeholder="Search the archives..." 
            className="w-full bg-white/50 border border-folio-border rounded-xl pl-10 py-3 text-sm focus:ring-folio-accent focus:border-folio-accent transition-all placeholder:italic"
          />
        </div>
      </div>

      <div className="w-full overflow-hidden mt-2">
        <table className="min-w-full divide-y divide-folio-border">
          <thead className="bg-folio-cream/50">
            <tr>
              <th className="px-6 py-3 text-left text-[9px] font-bold text-folio-primary/40 uppercase tracking-[0.2em]">Volume Title</th>
              <th className="px-4 py-3 text-left text-[9px] font-bold text-folio-primary/40 uppercase tracking-[0.2em]">Format</th>
              <th className="px-6 py-3 text-right text-[9px] font-bold text-folio-primary/40 uppercase tracking-[0.2em]">Tags</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-folio-border/40 bg-white/30">
            {filteredCards.length > 0 ? filteredCards.map((card) => (
              <tr 
                key={card.id} 
                onClick={() => onSelect(card)}
                className="hover:bg-folio-cream/30 transition-colors cursor-pointer group"
              >
                <td className="px-6 py-5">
                  <div className="flex flex-col">
                    <span className="text-[14px] font-classic font-bold text-folio-ink leading-tight group-hover:text-folio-accent transition-colors">
                      {card.title}
                    </span>
                    <span className="text-[9px] font-bold text-folio-primary/40 uppercase mt-1 tracking-wider">
                      {card.captureDate}
                    </span>
                  </div>
                </td>
                <td className="px-4 py-5">
                  <div className="flex items-center gap-1.5">
                    <span className="material-symbols-outlined text-folio-accent text-lg">sticky_note_2</span>
                    <span className="text-[9px] font-bold text-folio-primary/60 uppercase">Memo</span>
                  </div>
                </td>
                <td className="px-6 py-5 text-right">
                  <span className="text-[10px] font-bold text-folio-ink bg-folio-cream px-2 py-0.5 rounded border border-folio-border">
                    {card.tags.length}
                  </span>
                </td>
              </tr>
            )) : (
              <tr>
                <td colSpan={3} className="px-6 py-20 text-center">
                  <p className="text-folio-primary/40 font-serif italic">No matching volumes found in registry.</p>
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      <div className="px-6 py-10 bg-folio-cream/30 border-t border-folio-border mt-8">
        <h4 className="text-[10px] font-bold text-folio-primary/40 uppercase tracking-[0.2em] mb-4">Registry Metrics</h4>
        <div className="grid grid-cols-2 gap-4">
          <div className="bg-white p-5 rounded-xl border border-folio-border shadow-sm">
            <span className="text-3xl font-display text-folio-ink">{filteredCards.length}</span>
            <p className="text-[9px] font-bold text-folio-primary/40 uppercase tracking-widest mt-1">Visible Volumes</p>
          </div>
          <div className="bg-white p-5 rounded-xl border border-folio-border shadow-sm">
            <span className="text-3xl font-display text-folio-accent">{filteredCards.reduce((acc, c) => acc + c.tags.length, 0)}</span>
            <p className="text-[9px] font-bold text-folio-primary/40 uppercase tracking-widest mt-1">Network Nodes</p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ArchiveView;
