require('dotenv').config();
const prisma = require('../src/config/prisma');

// Demo-only merchant directory — no external payment gateway yet, per
// PROJECT_CONTEXT.md. `merchantLogo` stores an icon name (matching the
// Purpose Wallet icon convention), resolved to an image on the Flutter side.
const MERCHANTS = [
  { merchantCode: 'BIGBASKET', merchantName: 'BigBasket', merchantCategory: 'GROCERY', merchantLogo: 'shopping_cart' },
  { merchantCode: 'RELIANCE_FRESH', merchantName: 'Reliance Fresh', merchantCategory: 'GROCERY', merchantLogo: 'local_grocery_store' },
  { merchantCode: 'DMART', merchantName: 'DMart', merchantCategory: 'GROCERY', merchantLogo: 'store' },
  { merchantCode: 'AMAZON', merchantName: 'Amazon', merchantCategory: 'SHOPPING', merchantLogo: 'shopping_bag' },
  { merchantCode: 'FLIPKART', merchantName: 'Flipkart', merchantCategory: 'SHOPPING', merchantLogo: 'shopping_bag' },
  { merchantCode: 'SWIGGY', merchantName: 'Swiggy', merchantCategory: 'FOOD', merchantLogo: 'delivery_dining' },
  { merchantCode: 'ZOMATO', merchantName: 'Zomato', merchantCategory: 'FOOD', merchantLogo: 'restaurant' },
  { merchantCode: 'INDIAN_OIL', merchantName: 'Indian Oil', merchantCategory: 'FUEL', merchantLogo: 'local_gas_station' },
  { merchantCode: 'APOLLO_PHARMACY', merchantName: 'Apollo Pharmacy', merchantCategory: 'HEALTHCARE', merchantLogo: 'local_pharmacy' },
  { merchantCode: 'IRCTC', merchantName: 'IRCTC', merchantCategory: 'TRAVEL', merchantLogo: 'train' },
  // Phase 7 (Scheduled Payments) — UTILITY/OTHER merchants so Electricity,
  // Water, Internet, Mobile Recharge, Insurance, and EMI schedules have a
  // real merchant to target out of the box (no UTILITY-category merchant
  // existed before this, despite the enum value already existing).
  { merchantCode: 'STATE_ELECTRICITY', merchantName: 'State Electricity Board', merchantCategory: 'UTILITY', merchantLogo: 'bolt' },
  { merchantCode: 'MUNICIPAL_WATER', merchantName: 'Municipal Water Works', merchantCategory: 'UTILITY', merchantLogo: 'water_drop' },
  { merchantCode: 'AIRTEL_BROADBAND', merchantName: 'Airtel Broadband', merchantCategory: 'UTILITY', merchantLogo: 'wifi' },
  { merchantCode: 'AIRTEL_PREPAID', merchantName: 'Airtel Prepaid Recharge', merchantCategory: 'UTILITY', merchantLogo: 'sim_card' },
  { merchantCode: 'LIC_INSURANCE', merchantName: 'LIC Insurance', merchantCategory: 'OTHER', merchantLogo: 'shield' },
  { merchantCode: 'HDFC_LOAN_EMI', merchantName: 'HDFC Loan EMI', merchantCategory: 'OTHER', merchantLogo: 'account_balance' },
];

async function main() {
  for (const merchant of MERCHANTS) {
    await prisma.merchant.upsert({
      where: { merchantCode: merchant.merchantCode },
      update: merchant,
      create: merchant,
    });
  }
  console.log(`Seeded ${MERCHANTS.length} demo merchants.`);
}

main()
  .catch((err) => {
    console.error('Seed failed:', err);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
