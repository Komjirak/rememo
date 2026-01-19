
export interface MemoCard {
  id: string;
  title: string;
  summary: string;
  category: string;
  tags: string[];
  captureDate: string;
  sourceUrl?: string;
  imageUrl: string;
  ocrText?: string;
}

export enum ViewMode {
  SHELVES = 'shelves',
  ARCHIVE = 'archive',
  THREAD = 'thread',
  SETTINGS = 'settings'
}

export interface LibraryStats {
  totalVolumes: number;
  activeNodes: number;
}
