import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.SUPABASE_URL || 'YOUR_SUPABASE_URL';
const supabaseKey = process.env.SUPABASE_ANON_KEY || 'YOUR_SUPABASE_ANON_KEY';

export const supabase = createClient(supabaseUrl, supabaseKey);

// Fetch all states with counts
export async function getStates() {
  const { data, error } = await supabase
    .from('states')
    .select('*')
    .order('store_count', { ascending: false });
  
  if (error) throw error;
  return data;
}

// Fetch cities for a state
export async function getCitiesByState(stateId) {
  const { data, error } = await supabase
    .from('cities')
    .select('*')
    .eq('state_id', stateId)
    .order('store_count', { ascending: false });
  
  if (error) throw error;
  return data;
}

// Fetch stores for a city
export async function getStoresByCity(cityId) {
  const { data, error } = await supabase
    .from('stores')
    .select('*')
    .eq('city_id', cityId)
    .order('name');
  
  if (error) throw error;
  return data;
}

// Fetch single store
export async function getStore(id) {
  const { data, error } = await supabase
    .from('stores')
    .select('*, cities(name, slug), states(name, slug)')
    .eq('id', id)
    .single();
  
  if (error) throw error;
  return data;
}

// Get all stores for generating store detail pages
export async function getAllStores() {
  const { data, error } = await supabase
    .from('stores')
    .select('*, cities(name, slug), states(name, slug)')
    .order('id');
  
  if (error) throw error;
  return data;
}
