import type { Profile } from '$lib/types';
import { persisted } from '$lib/stores/sync';

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

export function saveProfile(p: Profile): void {
  profile.set({ ...p, onboarded: true });
}
