
import React from 'react';

const SplashScreen: React.FC = () => {
  return (
    <div className="fixed inset-0 bg-folio-cream flex flex-col items-center justify-center p-6 z-[200]">
      {/* Paper Pattern Overlay */}
      <div className="absolute inset-0 pointer-events-none bg-[radial-gradient(circle_at_center,transparent_0%,rgba(0,0,0,0.02)_100%)]"></div>
      
      <div className="flex flex-col items-center animate-pulse">
        <div className="relative mb-12">
          <div className="relative">
            <span className="material-symbols-outlined text-[100px] text-folio-ink/80 leading-none">
              menu_book
            </span>
            <div className="absolute -top-2 -right-2">
              <span className="material-symbols-outlined text-folio-accent text-3xl" style={{ fontVariationSettings: "'FILL' 1" }}>
                auto_awesome
              </span>
            </div>
          </div>
          <div className="absolute inset-0 bg-folio-accent/10 blur-3xl -z-10 rounded-full scale-150"></div>
        </div>

        <div className="flex flex-col items-center gap-4">
          <h1 className="font-display text-4xl tracking-[0.4em] text-folio-ink ml-[0.4em] font-medium">
            FOLIO
          </h1>
          <div className="w-16 h-[1.5px] bg-folio-ink/10"></div>
          <p className="text-[10px] tracking-[0.3em] uppercase text-folio-primary/40 font-bold">
            Personal Intelligence Library
          </p>
        </div>
      </div>

      <div className="fixed bottom-20 flex flex-col items-center gap-8 w-full px-12">
        <div className="text-center italic text-folio-primary/40 text-sm max-w-[240px] leading-relaxed font-serif">
          "A library is not a luxury but one of the necessities of life."
        </div>
        <div className="flex gap-3">
          <div className="w-1 h-1 rounded-full bg-folio-accent animate-bounce"></div>
          <div className="w-1 h-1 rounded-full bg-folio-accent animate-bounce [animation-delay:-0.15s]"></div>
          <div className="w-1 h-1 rounded-full bg-folio-accent animate-bounce [animation-delay:-0.3s]"></div>
        </div>
      </div>
    </div>
  );
};

export default SplashScreen;
