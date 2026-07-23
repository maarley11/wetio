const https = require('https');

const SUPABASE_URL = 'zjcnggoxjyonahoiansk.supabase.co';
const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpqY25nZ294anlvbmFob2lhbnNrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxMDg4NzksImV4cCI6MjA3NDY4NDg3OX0.ECbaWk_cl6VNCrodLwvAzMDWk3gO5UfkmKS6Ca4Qg2E';

function request(method, path) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: SUPABASE_URL,
      path: path,
      method: method,
      headers: {
        'apikey': SUPABASE_KEY,
        'Authorization': `Bearer ${SUPABASE_KEY}`,
        'Content-Type': 'application/json',
        'Prefer': 'return=representation'
      }
    };

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        console.log(`Response for ${method} ${path}: ${res.statusCode}`);
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(data ? JSON.parse(data) : []);
        } else {
          reject(new Error(`Status ${res.statusCode}: ${data}`));
        }
      });
    });

    req.on('error', reject);
    req.end();
  });
}

async function cleanup() {
  const titlesToDelete = [
    'Robe été fleurie',
    'Sac à main vintage',
    'Livre de cuisine végétarienne'
  ];

  try {
    console.log('Fetching products...');
    const products = await request('GET', '/rest/v1/products?select=id,title');
    
    const toDelete = products.filter(p => titlesToDelete.includes(p.title));
    console.log('Products to delete:', toDelete.map(p => p.title));

    for (const product of toDelete) {
      console.log(`Attempting to delete: ${product.title} (${product.id})`);
      try {
        await request('DELETE', `/rest/v1/products?id=eq.${product.id}`);
        console.log(`Successfully deleted: ${product.title}`);
      } catch (e) {
        console.error(`Failed to delete ${product.title}: ${e.message}`);
      }
    }

    console.log('Cleanup finished.');
  } catch (error) {
    console.error('Error:', error.message);
  }
}

cleanup();
