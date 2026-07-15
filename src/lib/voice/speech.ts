// Thin wrapper over the browser Web Speech API (SpeechRecognition).
// Free, on-device transcription — works in Chrome & Safari. No key, no server.

export function isSpeechSupported(): boolean {
  if (typeof window === 'undefined') return false;
  const w = window as unknown as Record<string, unknown>;
  return !!(w.SpeechRecognition || w.webkitSpeechRecognition);
}

export interface Recognizer {
  start: () => void;
  stop: () => void;
}

interface Handlers {
  onpartial?: (text: string) => void;
  onfinal: (text: string) => void;
  onerror: (code: string) => void;
  onend?: () => void;
  lang?: string;
}

export function createRecognizer(handlers: Handlers): Recognizer | null {
  if (!isSpeechSupported()) return null;
  /* eslint-disable @typescript-eslint/no-explicit-any */
  const w = window as unknown as Record<string, any>;
  const Ctor = w.SpeechRecognition || w.webkitSpeechRecognition;
  const rec = new Ctor();
  rec.lang = handlers.lang ?? 'en-IN';
  rec.interimResults = true;
  rec.continuous = false;
  rec.maxAlternatives = 1;

  let finalText = '';
  let lastText = '';

  rec.onresult = (e: any) => {
    let interim = '';
    let fin = '';
    for (let i = 0; i < e.results.length; i++) {
      const r = e.results[i];
      if (r.isFinal) fin += r[0].transcript;
      else interim += r[0].transcript;
    }
    finalText = fin;
    lastText = (fin + interim).trim();
    handlers.onpartial?.(lastText);
  };
  rec.onerror = (e: any) => handlers.onerror(e?.error ?? 'error');
  rec.onend = () => {
    const result = (finalText || lastText).trim();
    if (result) handlers.onfinal(result);
    handlers.onend?.();
  };
  /* eslint-enable @typescript-eslint/no-explicit-any */

  return {
    start: () => {
      finalText = '';
      lastText = '';
      try {
        rec.start();
      } catch {
        /* already started */
      }
    },
    stop: () => {
      try {
        rec.stop();
      } catch {
        /* not running */
      }
    }
  };
}
