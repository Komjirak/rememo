
import React from 'react';
import { MemoCard } from '../types';

interface ThreadViewProps {
  cards: MemoCard[];
  onSelect: (card: MemoCard) => void;
}

const ThreadView: React.FC<ThreadViewProps> = ({ cards, onSelect }) => {
  return (
    <div className="relative px-6 pt-10 animate-fade-in min-h-screen">
      {/* Timeline Line */}
      <div className="absolute left-[31px] top-0 bottom-0 w-px bg-folio-border z-0"></div>
      
      <div className="relative space-y-10 z-10">
        <div className="flex items-center gap-4 mb-4">
          <div className="size-9 rounded-full bg-folio-primary flex items-center justify-center ring-4 ring-folio-paper">
            <span className="material-symbols-outlined text-white text-sm" style={{ fontVariationSettings: "'FILL' 1" }}>history_edu</span>
          </div>
          <span className="text-[10px] font-bold uppercase tracking-[0.2em] text-folio-primary/40">Latest Discoveries</span>
        </div>

        {cards.map((card, idx) => (
          <div key={card.id} className="grid grid-cols-[36px_1fr] gap-6">
            <div className="flex flex-col items-center">
              <div className="size-2.5 rounded-full bg-folio-primary ring-4 ring-folio-paper mt-6 shadow-sm"></div>
              {idx < cards.length - 1 && <div className="flex-1 w-px bg-folio-border mt-1"></div>}
            </div>
            
            <div 
              onClick={() => onSelect(card)}
              className="bg-white/70 p-6 rounded-2xl border border-folio-border shadow-[0_4px_20px_rgba(0,0,0,0.03)] hover:shadow-xl hover:translate-x-1 transition-all cursor-pointer group"
            >
              <div className="flex justify-between items-start mb-3">
                <span className="material-symbols-outlined text-folio-accent text-xl">auto_awesome</span>
                <span className="text-[10px] font-bold text-folio-primary/40 tracking-wider uppercase">{card.captureDate}</span>
              </div>
              <h3 className="font-classic font-bold text-folio-ink mb-2 leading-snug text-lg group-hover:text-folio-accent transition-colors">
                {card.title}
              </h3>
              <p className="text-sm text-folio-primary/70 line-clamp-2 leading-relaxed font-serif italic">
                {card.summary}
              </p>
              <div className="mt-4 flex flex-wrap gap-2">
                {card.tags.slice(0, 2).map(tag => (
                  <span key={tag} className="px-2 py-0.5 rounded-md bg-folio-cream text-folio-primary text-[9px] font-bold tracking-wider uppercase border border-folio-border">
                    {tag}
                  </span>
                ))}
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default ThreadView;
