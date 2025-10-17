import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';
import { getStates, getCitiesByState, getStoresByCity, getAllStores } from './supabaseClient.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const OUTPUT_DIR = path.join(__dirname, '../../public');
const BASE_PATH = '/directory2'; // GitHub Pages base path

// Ensure output directory exists
async function ensureDir(dir) {
  try {
    await fs.mkdir(dir, { recursive: true });
  } catch (err) {
    if (err.code !== 'EEXIST') throw err;
  }
}

// Read template file
async function readTemplate(templateName) {
  const templatePath = path.join(__dirname, '../templates', templateName);
  return await fs.readFile(templatePath, 'utf-8');
}

// Generate homepage
async function generateHomepage() {
  console.log('Generating homepage...');
  const states = await getStates();
  const template = await readTemplate('home.html');
  
  const totalStores = states.reduce((sum, s) => sum + s.store_count, 0);
  
  const statesList = states.map(state => `
    <div class="state-card">
      <div class="state-emoji">${state.emoji || '📍'}</div>
      <div class="state-info">
        <h3>${state.name}</h3>
        <div class="state-stats">
          <span>${state.store_count} stores</span>
          <span>${state.city_count} cities</span>
        </div>
      </div>
      <a href="${BASE_PATH}/scratch-and-dent-appliances/${state.slug}" class="btn-primary">View Directory</a>
    </div>
  `).join('');
  
  const html = template
    .replace('{{STATES_LIST}}', statesList)
    .replace(/{{TOTAL_STORES}}/g, totalStores.toLocaleString());
  
  await fs.writeFile(path.join(OUTPUT_DIR, 'index.html'), html);
}

// Generate state pages
async function generateStatePages() {
  console.log('Generating state pages...');
  const states = await getStates();
  
  for (const state of states) {
    const cities = await getCitiesByState(state.id);
    const template = await readTemplate('state.html');
    
    const citiesList = cities.map(city => `
      <div class="city-card">
        <div class="city-info">
          <h3>${city.name}</h3>
          <p class="city-count">${city.store_count} stores</p>
        </div>
        <a href="${BASE_PATH}/scratch-and-dent-appliances/${state.slug}/${city.slug}" class="btn-secondary">View Stores</a>
      </div>
    `).join('');
    
    const html = template
      .replace(/{{STATE_NAME}}/g, state.name)
      .replace('{{CITIES_LIST}}', citiesList)
      .replace('{{STORE_COUNT}}', state.store_count)
      .replace('{{CITY_COUNT}}', state.city_count)
      .replace('{{STATE_EMOJI}}', state.emoji || '📍');
    
    const stateDir = path.join(OUTPUT_DIR, 'scratch-and-dent-appliances', state.slug);
    await ensureDir(stateDir);
    await fs.writeFile(path.join(stateDir, 'index.html'), html);
    
    // Generate city pages for this state
    await generateCityPages(state, cities);
  }
}

// Generate city pages
async function generateCityPages(state, cities) {
  for (const city of cities) {
    const stores = await getStoresByCity(city.id);
    const template = await readTemplate('city.html');
    
    const storesList = stores.map(store => `
      <div class="store-card">
        <div class="store-header">
          <h3>${store.name}</h3>
        </div>
        <div class="store-details">
          <p><strong>📍 Address:</strong> ${store.address || 'N/A'}</p>
          ${store.phone ? `<p><strong>📞 Phone:</strong> <a href="tel:${store.phone}">${store.phone}</a></p>` : ''}
          ${store.website ? `<p><strong>🌐 Website:</strong> <a href="${store.website}" target="_blank" rel="noopener">Visit Website</a></p>` : ''}
        </div>
        <a href="${BASE_PATH}/stores/${store.id}" class="btn-primary">View Details</a>
      </div>
    `).join('');
    
    const html = template
      .replace(/{{STATE_NAME}}/g, state.name)
      .replace(/{{CITY_NAME}}/g, city.name)
      .replace('{{STORES_LIST}}', storesList)
      .replace('{{STORE_COUNT}}', city.store_count)
      .replace('{{STATE_SLUG}}', state.slug);
    
    const cityDir = path.join(OUTPUT_DIR, 'scratch-and-dent-appliances', state.slug, city.slug);
    await ensureDir(cityDir);
    await fs.writeFile(path.join(cityDir, 'index.html'), html);
  }
}

// Generate individual store pages
async function generateStorePages() {
  console.log('Generating store detail pages...');
  const stores = await getAllStores();
  const template = await readTemplate('store.html');
  
  for (const store of stores) {
    const html = template
      .replace(/{{STORE_NAME}}/g, store.name)
      .replace('{{STORE_ADDRESS}}', store.address || 'Address not available')
      .replace('{{STORE_PHONE}}', store.phone || 'N/A')
      .replace('{{STORE_WEBSITE}}', store.website || '#')
      .replace('{{STORE_EMAIL}}', store.email || 'N/A')
      .replace('{{STORE_DESCRIPTION}}', store.description || 'No description available.')
      .replace('{{CITY_NAME}}', store.cities?.name || 'Unknown')
      .replace('{{STATE_NAME}}', store.states?.name || 'Unknown')
      .replace('{{CITY_SLUG}}', store.cities?.slug || '')
      .replace('{{STATE_SLUG}}', store.states?.slug || '');
    
    const storeDir = path.join(OUTPUT_DIR, 'stores', store.id.toString());
    await ensureDir(storeDir);
    await fs.writeFile(path.join(storeDir, 'index.html'), html);
  }
}

// Copy static assets
async function copyStaticAssets() {
  console.log('Copying static assets...');
  const cssSource = path.join(__dirname, '../styles/main.css');
  const cssTarget = path.join(OUTPUT_DIR, 'main.css');
  await fs.copyFile(cssSource, cssTarget);
}

// Main build function
async function build() {
  console.log('🚀 Starting build process...\n');
  
  await ensureDir(OUTPUT_DIR);
  await copyStaticAssets();
  await generateHomepage();
  await generateStatePages();
  await generateStorePages();
  
  console.log('\n✅ Build complete! Site generated in /public directory');
}

build().catch(err => {
  console.error('❌ Build failed:', err);
  process.exit(1);
});
