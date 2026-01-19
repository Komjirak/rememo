
import React, { useState, useEffect, useRef } from 'react';
import { ViewMode, MemoCard } from './types';
import ShelvesView from './components/ShelvesView';
import ArchiveView from './components/ArchiveView';
import ThreadView from './components/ThreadView';
import DetailView from './components/DetailView';
import SplashScreen from './components/SplashScreen';
import Navigation from './components/Navigation';
import { analyzeScreenshot } from './services/geminiService';

const STORAGE_KEY = 'folio_library_v1';

const App: React.FC = () => {
  const [loading, setLoading] = useState(true);
  const [view, setView] = useState<ViewMode>(ViewMode.SHELVES);
  const [cards, setCards] = useState<MemoCard[]>([]);
  const [selectedCard, setSelectedCard] = useState<MemoCard | null>(null);
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  
  const fileInputRef = useRef<HTMLInputElement>(null);

  // Load from storage
  useEffect(() => {
    const saved = localStorage.getItem(STORAGE_KEY);
    if (saved) {
      try {
        setCards(JSON.parse(saved));
      } catch (e) {
        console.error("Failed to parse saved library", e);
      }
    } else {
      // Default mock data if empty
      setCards([
        {
          id: '1',
          title: 'On the Geometry of Light',
          summary: 'The way natural light interacts with brutalist surfaces creates a temporal rhythm.',
          category: 'Architecture',
          tags: ['Brutalism', 'Light', 'Design'],
          captureDate: 'Oct 24, 2023',
          imageUrl: 'https://picsum.photos/seed/arch/600/800',
        }
      ]);
    }
    
    const timer = setTimeout(() => setLoading(false), 2000);
    return () => clearTimeout(timer);
  }, []);

  // Save to storage
  useEffect(() => {
    if (!loading) {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(cards));
    }
  }, [cards, loading]);

  const handleCapture = () => {
    fileInputRef.current?.click();
  };

  const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = async (event) => {
      const base64 = event.target?.result as string;
      await processImage(base64);
    };
    reader.readAsDataURL(file);
    // Reset input
    e.target.value = '';
  };

  const processImage = async (base64: string, existingId?: string) => {
    setIsAnalyzing(true);
    try {
      const analysis = await analyzeScreenshot(base64);
      const newCard: MemoCard = {
        id: existingId || Date.now().toString(),
        title: analysis.title,
        summary: analysis.summary,
        category: analysis.category,
        tags: analysis.tags,
        captureDate: existingId ? cards.find(c => c.id === existingId)?.captureDate || 'Today' : 'Today',
        imageUrl: base64,
        ocrText: analysis.ocrText
      };

      if (existingId) {
        setCards(prev => prev.map(c => c.id === existingId ? newCard : c));
      } else {
        setCards(prev => [newCard, ...prev]);
      }
      setSelectedCard(newCard);
    } catch (error) {
      console.error("Analysis failed", error);
      alert("The Scribe failed to interpret this capture. Please try again.");
    } finally {
      setIsAnalyzing(false);
    }
  };

  const handleDelete = (id: string) => {
    if (confirm("Are you sure you wish to remove this volume from the archive?")) {
      setCards(prev => prev.filter(c => c.id !== id));
      setSelectedCard(null);
    }
  };

  const handleRegenerate = async (card: MemoCard) => {
    await processImage(card.imageUrl, card.id);
  };

  if (loading) return <SplashScreen />;

  return (
    <div className="flex flex-col min-h-screen max-w-md mx-auto relative overflow-x-hidden bg-folio-paper">
      <input 
        type="file" 
        ref={fileInputRef} 
        className="hidden" 
        accept="image/*" 
        onChange={handleFileChange} 
      />

      {isAnalyzing && (
        <div className="fixed inset-0 z-[100] bg-folio-ink/80 backdrop-blur-md flex flex-col items-center justify-center text-folio-cream p-12 text-center">
          <div className="relative mb-8">
            <span className="material-symbols-outlined text-6xl animate-pulse">auto_awesome</span>
            <div className="absolute inset-0 bg-folio-accent/30 blur-2xl rounded-full scale-150 animate-pulse"></div>
          </div>
          <h2 className="font-display text-xl tracking-widest mb-4">Scribing Archive...</h2>
          <p className="font-serif italic opacity-70">Gemini is distilling the essence of your capture into a permanent memo.</p>
        </div>
      )}

      <header className="sticky top-0 z-30 bg-folio-paper/80 backdrop-blur-md border-b border-folio-border px-6 py-4 flex justify-between items-center">
        <div className="flex items-center gap-3">
          <div className="size-8 bg-folio-primary rounded-lg flex items-center justify-center text-folio-cream shadow-sm">
            <span className="material-symbols-outlined text-xl">folder_managed</span>
          </div>
          <h1 className="font-display text-xl tracking-tight text-folio-ink italic">Folio</h1>
        </div>
        <button className="size-10 rounded-full bg-folio-cream border border-folio-border flex items-center justify-center text-folio-primary shadow-sm active:scale-95 transition-all">
          <span className="material-symbols-outlined">face_6</span>
        </button>
      </header>

      <main className="flex-1 pb-32">
        {view === ViewMode.SHELVES && <ShelvesView cards={cards} onSelect={setSelectedCard} />}
        {view === ViewMode.ARCHIVE && <ArchiveView cards={cards} onSelect={setSelectedCard} />}
        {view === ViewMode.THREAD && <ThreadView cards={cards} onSelect={setSelectedCard} />}
        {view === ViewMode.SETTINGS && (
          <div className="p-10 text-center space-y-6">
            <h2 className="font-display text-2xl tracking-widest text-folio-ink">Library Settings</h2>
            <p className="font-serif italic text-folio-primary/60">Manage your personal collection of captured wisdom.</p>
            <button 
              onClick={() => { if(confirm("Clear entire library?")) setCards([]); }}
              className="px-6 py-3 bg-red-50 text-red-600 border border-red-100 rounded-xl text-xs font-bold uppercase tracking-widest w-full"
            >
              Purge All Archives
            </button>
          </div>
        )}
      </main>

      <div className="fixed bottom-24 right-6 z-40">
        <button 
          onClick={handleCapture}
          className="size-16 bg-folio-ink text-folio-cream rounded-full shadow-2xl flex items-center justify-center active:scale-90 transition-transform ring-4 ring-folio-paper"
        >
          <span className="material-symbols-outlined text-3xl font-light">add_a_photo</span>
        </button>
      </div>

      <Navigation activeView={view} setView={setView} />

      {selectedCard && (
        <DetailView 
          card={selectedCard} 
          onClose={() => setSelectedCard(null)} 
          onDelete={() => handleDelete(selectedCard.id)}
          onRegenerate={() => handleRegenerate(selectedCard)}
        />
      )}
    </div>
  );
};

export default App;
