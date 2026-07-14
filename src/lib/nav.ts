export interface Tab { href: string; label: string; icon: string; }

export const TABS: Tab[] = [
  { href: '/food', label: 'Food', icon: '🍽️' },
  { href: '/progress', label: 'Progress', icon: '📈' },
  { href: '/workout', label: 'Workout', icon: '🏋️' },
  { href: '/anatomy', label: 'Anatomy', icon: '💪' }
];

export const isActive = (href: string, path: string) => path.startsWith(href);
