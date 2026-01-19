
import React from 'react';
import { MemoCard } from '../types';

interface DetailViewProps {
  card: MemoCard;
  onClose: () => void;
  onDelete: () => void;
  onRegenerate: () => void;
}

const DetailView: React.FC<DetailViewProps> = ({ card, onClose, onDelete, onRegenerate }) => {
  return (
    <div className="fixed inset-0 z-[60] bg-folio-ink/20 backdrop-blur-md flex items-end sm:items-center justify-center p-0 sm:p-4 animate-fade-in">
      <div 
        className="w-full max-w-lg bg-folio-paper h-[92vh] sm:h-auto sm:max-h-[85vh] overflow-y-auto rounded-t-[2.5rem] sm:rounded-3xl shadow-2xl relative"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Navigation Bar */}
        <div className="sticky top-0 z-10 bg-folio-paper/80 backdrop-blur-lg border-b border-folio-border px-6 h-14 flex items-center justify-between">
          <button onClick={onClose} className="flex items-center gap-1 text-folio-primary/60 hover:text-folio-ink">
            <span className="material-symbols-outlined">chevron_left</span>
            <span className="font-sans text-xs font-bold uppercase tracking-wider">Back</span>
          </button>
          <span className="font-display text-sm tracking-widest text-folio-ink">Memo Card</span>
          <button onClick={onDelete} className="text-red-400 hover:text-red-600 transition-colors">
            <span className="material-symbols-outlined">delete</span>
          </button>
        </div>

        <div className="p-8 pb-32">
          {/* Header */}
          <div className="space-y-6">
            <div className="flex items-center gap-2 text-folio-primary/40">
              <span className="material-symbols-outlined text-lg">calendar_today</span>
              <span className="font-sans text-[10px] uppercase tracking-[0.2em] font-bold">{card.captureDate}</span>
            </div>
            <h1 className="text-3xl font-classic font-bold text-folio-ink leading-tight">{card.title}</h1>
          </div>

          {/* AI Content */}
          <div className="mt-10 space-y-10">
            <div className="border-l-2 border-folio-accent/20 pl-6 py-1">
              <label className="font-sans text-[10px] uppercase tracking-[0.2em] font-extrabold text-folio-primary/30 mb-2 block">Topic</label>
              <p className="text-xl font-classic text-folio-ink italic">{card.category}</p>
            </div>

            <div className="border-l-2 border-folio-accent/20 pl-6 py-1">
              <label className="font-sans text-[10px] uppercase tracking-[0.2em] font-extrabold text-folio-primary/30 mb-2 block">Core Synthesis</label>
              <p className="text-lg font-serif italic text-folio-ink leading-relaxed">
                {card.summary}
              </p>
            </div>

            <div className="space-y-4">
              <label className="font-sans text-[10px] uppercase tracking-[0.2em] font-extrabold text-folio-primary/30 block">Reflections & Tags</label>
              <div className="flex flex-wrap gap-2">
                {card.tags.map(tag => (
                  <span key={tag} className="px-3 py-1 bg-folio-cream border border-folio-border rounded-lg text-folio-primary text-xs font-medium">
                    #{tag}
                  </span>
                ))}
              </div>
            </div>

            {/* Original Capture */}
            <div className="space-y-4">
              <label className="font-sans text-[10px] uppercase tracking-[0.2em] font-extrabold text-folio-primary/30 block">Original Source Reference</label>
              <div className="relative rounded-2xl overflow-hidden border border-folio-border shadow-lg aspect-auto">
                <img src={card.imageUrl} className="w-full h-full object-contain bg-folio-cream" alt="Original screenshot" />
                <div className="absolute top-4 right-4 bg-folio-paper/80 backdrop-blur-md px-3 py-1.5 rounded-full shadow-sm">
                  <span className="material-symbols-outlined text-folio-accent text-sm">screenshot_region</span>
                </div>
              </div>
            </div>

            {card.ocrText && (
              <div className="space-y-4">
                <label className="font-sans text-[10px] uppercase tracking-[0.2em] font-extrabold text-folio-primary/30 block">Extracted Context (OCR)</label>
                <div className="bg-folio-cream/50 rounded-xl p-4 font-serif text-sm text-folio-primary/60 leading-relaxed italic border border-folio-border/40">
                  {card.ocrText}
                </div>
              </div>
            )}
          </div>
        </div>

        {/* Action Toolbar */}
        <div className="absolute bottom-8 left-8 right-8 flex justify-center">
          <div className="bg-folio-ink/90 backdrop-blur-xl px-6 py-3 rounded-full flex gap-8 items-center shadow-2xl">
            <button className="text-folio-cream/60 hover:text-folio-cream"><span className="material-symbols-outlined">edit_square</span></button>
            <button className="text-folio-cream/60 hover:text-folio-cream"><span className="material-symbols-outlined">link</span></button>
            <div className="w-[1px] h-4 bg-folio-cream/20"></div>
            <button 
              onClick={onRegenerate}
              className="text-folio-accent flex items-center gap-2 font-sans font-bold text-[10px] tracking-widest uppercase active:scale-95 transition-transform"
            >
              <span className="material-symbols-outlined text-lg">auto_awesome</span>
              Regenerate
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default DetailView;
