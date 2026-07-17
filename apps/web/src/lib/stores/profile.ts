import type { Profile } from '$lib/types';
import { persisted } from '$lib/stores/sync';
import { clampBodyWeight, isPlausibleBodyWeight } from './weight-log';

export const DEFAULT_PROFILE: Profile = {
  age: 21,
  sex: 'male',
  heightCm: 170,
  currentWeightKg: 65,
  targetWeightKg: 65,
  activity: 1.375,
  onboarded: false
};

export const profile = persisted<Profile>('luxifit.profile', DEFAULT_PROFILE);

/** Fix corrupted weights (e.g. 494 kg from unbounded steppers). */
export function sanitizeProfile(p: Profile): Profile {
  const current = isPlausibleBodyWeight(p.currentWeightKg)
    ? clampBodyWeight(p.currentWeightKg)
    : DEFAULT_PROFILE.currentWeightKg;
  const target = isPlausibleBodyWeight(p.targetWeightKg)
    ? clampBodyWeight(p.targetWeightKg)
    : current;
  return { ...p, currentWeightKg: current, targetWeightKg: target };
}

export function saveProfile(p: Profile): void {
  const clean = sanitizeProfile({ ...p, onboarded: true });
  profile.set(clean);
}
