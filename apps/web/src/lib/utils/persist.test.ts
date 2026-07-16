import { describe, it, expect, beforeEach } from 'vitest';
import { get } from 'svelte/store';
import { persisted } from './persist';

describe('persisted', () => {
  beforeEach(() => localStorage.clear());

  it('uses the initial value when nothing is stored', () => {
    const s = persisted('luxifit.test', { n: 1 });
    expect(get(s)).toEqual({ n: 1 });
  });

  it('writes updates to localStorage', () => {
    const s = persisted<{ n: number }>('luxifit.test', { n: 1 });
    s.set({ n: 5 });
    expect(JSON.parse(localStorage.getItem('luxifit.test')!)).toEqual({ n: 5 });
  });

  it('rehydrates from localStorage on re-create', () => {
    localStorage.setItem('luxifit.test', JSON.stringify({ n: 9 }));
    const s = persisted<{ n: number }>('luxifit.test', { n: 1 });
    expect(get(s)).toEqual({ n: 9 });
  });
});
