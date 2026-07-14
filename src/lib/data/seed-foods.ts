import type { Food, Category } from '$lib/types';

type Seed = [
  name: string, icon: string, category: Category, serving: string,
  calories: number, protein: number, carbs: number, fiber: number, fats: number,
  junk?: boolean, vitamins?: string
];

const rows: Seed[] = [
  // Protein
  ['Boiled egg', '🥚', 'protein', '1 egg', 78, 6.3, 0.6, 0, 5.3, false, 'B12, D'],
  ['Egg whites', '🍳', 'protein', '1 white', 17, 3.6, 0.2, 0, 0.1],
  ['Chicken breast', '🍗', 'protein', '100 g', 165, 31, 0, 0, 3.6, false, 'B6'],
  ['Fish (sardine)', '🐟', 'protein', '100 g', 208, 25, 0, 0, 11, false, 'Omega-3, D'],
  ['Fish curry', '🍛', 'protein', '1 cup', 200, 18, 6, 1, 12],
  ['Chicken curry', '🍛', 'protein', '1 cup', 240, 20, 6, 1, 15],
  ['Paneer', '🧀', 'protein', '100 g', 265, 18, 1.2, 0, 21, false, 'Calcium'],
  ['Boiled channa', '🫘', 'protein', '1 cup', 269, 15, 45, 12, 4, false, 'Iron'],
  ['Moong sprouts', '🌱', 'protein', '1 cup', 31, 3, 6, 2, 0.2],
  ['Soya chunks (dry)', '🧆', 'protein', '50 g', 172, 26, 16, 6, 0.5, false, 'Iron'],
  ['Green gram pesarattu', '🥞', 'protein', '1 dosa', 150, 8, 20, 4, 4],
  // Carb / staples
  ['Idli', '⚪', 'carb', '1 idli', 58, 2, 12, 0.6, 0.3],
  ['Plain dosa', '🥞', 'carb', '1 dosa', 133, 2.7, 18, 1, 5.5],
  ['Egg dosa', '🍳', 'carb', '1 dosa', 200, 8, 18, 1, 11],
  ['Wheat dosa', '🥞', 'carb', '1 dosa', 120, 3, 20, 3, 3],
  ['Chapati', '🫓', 'carb', '1 chapati', 104, 3, 18, 2.7, 2.5],
  ['White rice', '🍚', 'carb', '1 cup', 205, 4.3, 45, 0.6, 0.4],
  ['Brown rice', '🍚', 'carb', '1 cup', 216, 5, 45, 3.5, 1.8],
  ['Curd rice', '🍚', 'carb', '1 cup', 197, 6, 30, 1, 6],
  ['Ragi ball', '🟤', 'carb', '1 ball', 220, 5, 48, 8, 1.5, false, 'Calcium, Iron'],
  ['Oats (dry)', '🥣', 'carb', '40 g', 152, 5, 27, 4, 3],
  ['Upma', '🍲', 'carb', '1 cup', 250, 6, 36, 3, 9],
  ['Poha', '🍚', 'carb', '1 cup', 270, 5, 40, 2, 10],
  ['Ven pongal', '🍲', 'carb', '1 cup', 285, 8, 40, 3, 10],
  ['Sweet potato', '🍠', 'carb', '1 medium', 112, 2, 26, 4, 0.1, false, 'Vit A'],
  // Dals / gravies / veg
  ['Sambar', '🍲', 'veg', '1 cup', 150, 6, 20, 5, 5],
  ['Rasam', '🥣', 'veg', '1 cup', 65, 2, 10, 2, 2],
  ['Thuvaram paruppu (dal)', '🍲', 'veg', '1 cup', 190, 12, 28, 8, 3],
  ['Kootu', '🥗', 'veg', '1 cup', 160, 6, 18, 6, 7],
  // Dairy
  ['Curd', '🥛', 'dairy', '1 cup', 110, 9, 12, 0, 4, false, 'Calcium'],
  ['Toned milk', '🥛', 'dairy', '1 cup', 120, 6, 11, 0, 5, false, 'Calcium'],
  ['Buttermilk', '🥛', 'dairy', '1 glass', 40, 3, 5, 0, 1],
  // Fruit / snacks
  ['Banana', '🍌', 'fruit', '1 medium', 105, 1.3, 27, 3, 0.4, false, 'B6, Potassium'],
  ['Apple', '🍎', 'fruit', '1 medium', 95, 0.5, 25, 4, 0.3],
  ['Dates', '🌴', 'fruit', '2 dates', 133, 1, 36, 3, 0.2, false, 'Iron'],
  ['Peanuts', '🥜', 'other', '30 g', 170, 7, 5, 2.5, 14],
  ['Almonds', '🌰', 'other', '10 nuts', 70, 2.5, 2.5, 1.5, 6, false, 'Vit E'],
  // Drinks
  ['Black coffee', '☕', 'drink', '1 cup', 5, 0.3, 0, 0, 0],
  ['Tea with sugar', '🍵', 'drink', '1 cup', 90, 2, 15, 0, 3],
  ['Tender coconut', '🥥', 'drink', '1 whole', 46, 2, 9, 3, 0.5],
  // Junk
  ['Parotta', '🫓', 'junk', '1 parotta', 260, 5, 36, 1.5, 11, true],
  ['Chicken biryani', '🍛', 'junk', '1 plate', 550, 25, 65, 3, 22, true],
  ['Medu vada', '🍩', 'junk', '1 vada', 130, 4, 15, 2, 6, true],
  ['Bajji', '🍤', 'junk', '1 piece', 100, 2, 12, 1, 5, true],
  ['Samosa', '🥟', 'junk', '1 piece', 130, 3, 15, 1.5, 7, true],
  ['Jangiri (sweet)', '🍥', 'junk', '1 piece', 150, 1, 25, 0, 6, true],
  ['Soft drink', '🥤', 'junk', '330 ml', 139, 0, 35, 0, 0, true],
  ['Bakery bun', '🍞', 'junk', '1 bun', 180, 5, 32, 1, 3.5, true]
];

export const seedFoods: Food[] = rows.map(
  ([name, icon, category, servingLabel, calories, protein, carbs, fiber, fats, junk, vitamins], i) => ({
    id: `seed-${i + 1}`,
    name,
    icon,
    category,
    servingLabel,
    perServing: { calories, protein, carbs, fiber, fats },
    vitamins,
    isJunk: junk ?? false,
    isDefault: true
  })
);
