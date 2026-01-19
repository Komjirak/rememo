
import React from 'react';
import { MemoCard } from '../types';

interface ShelvesViewProps {
  cards: MemoCard[];
  onSelect: (card: MemoCard) => void;
}

const ShelvesView: React.FC<ShelvesViewProps> = ({ cards, onSelect }) => {
  // Group by category for shelf representation
  const categories = Array.from(new Set(cards.map(c => c.category)));

  return (
    <div className="px-6 pt-8 space-y-8 animate-fade-in">
      <header className="mb-6">
        <h2 className="text-[34px] font-classic font-light leading-tight tracking-tight text-folio-ink">
          Welcome back,<br /><span className="text-folio-accent italic font-medium">Scholar</span>
        </h2>
        <p className="text-folio-primary/40 text-[10px] mt-2 font-sans font-extrabold tracking-widest uppercase">
          Library size: {cards.length} Volumes
        </p>
      </header>

      {categories.map((cat) => (
        <section key={cat} className="space-y-4">
          <div className="flex items-center justify-between border-b border-folio-border pb-2">
            <h3 className="text-lg font-classic font-semibold tracking-tight text-folio-ink italic">{cat} Musings</h3>
            <span className="material-symbols-outlined text-folio-primary/20 text-lg">arrow_right_alt</span>
          </div>
          
          <div className="flex overflow-x-auto gap-6 pb-6 no-scrollbar snap-x">
            {cards.filter(c => c.category === cat).map((card) => (
              <div 
                key={card.id}
                onClick={() => onSelect(card)}
                className="flex-none w-40 group cursor-pointer snap-start"
              >
                <div className="relative w-full aspect-[3/4.2] rounded-r-md overflow-hidden bg-folio-cream shadow-xl transition-all duration-500 group-hover:-translate-y-2 group-hover:shadow-2xl">
                  {/* Book Spine Detail */}
                  <div className="absolute top-0 bottom-0 left-0 w-1 bg-black/10 z-20"></div>
                  <div className="absolute top-0 bottom-0 left-1 w-px bg-white/20 z-20"></div>
                  
                  <img 
                    src={card.imageUrl} 
                    className="w-full h-full object-cover grayscale-[0.2] group-hover:grayscale-0 transition-all duration-700"
                    alt={card.title}
                  />
                  <div className="absolute inset-0 bg-gradient-to-t from-folio-ink/60 via-transparent to-transparent"></div>
                  <div className="absolute bottom-3 left-4 right-3">
                    <span className="text-[8px] uppercase tracking-[0.3em] font-bold text-folio-cream opacity-60">Volume</span>
                  </div>
                </div>
                <div className="mt-4 px-1">
                  <h4 className="text-[14px] font-classic font-semibold leading-snug text-folio-ink truncate">{card.title}</h4>
                  <p className="text-[10px] text-folio-primary/50 font-sans font-bold uppercase tracking-widest mt-1">Scribed {card.captureDate}</p>
                </div>
              </div>
            ))}
          </div>
        </section>
      ))}
      
      {cards.length === 0 && (
        <div className="flex flex-col items-center justify-center py-24 text-center">
          <span className="material-symbols-outlined text-6xl text-folio-border mb-4">book_4</span>
          <p className="font-serif italic text-folio-primary/40">Your shelves are empty. Start capturing moments of inspiration.</p>
        </div>
      )}
    </div>
  );
};

export default ShelvesView;
