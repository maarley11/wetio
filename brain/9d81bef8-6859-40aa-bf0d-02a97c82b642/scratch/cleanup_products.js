const https = require('https');

const SUPABASE_URL = 'zjcnggoxjyonahoiansk.supabase.co';
const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpqY25nZ294anlvbmFob2lhbnNrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxMDg4NzksImV4cCI6MjA3NDY4NDg3OX0.ECbaWk_cl6VNCrodLwvAzMDWk3gO5UfkmKS6Ca4Qg2E';

function request(method, path, body = null) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: SUPABASE_URL,
      path: path,
      method: method,
      headers: {
        'apikey': SUPABASE_KEY,
        'Authorization': `Bearer ${SUPABASE_KEY}`,
        'Content-Type': 'application/json'
      }
    };

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(data ? JSON.parse(data) : null);
        } else {
          reject(new Error(`Status ${res.statusCode}: ${data}`));
        }
      });
    });

    req.on('error', reject);
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

async function cleanup() {
  try {
    console.log('Fetching profiles...');
    const profiles = await request('GET', '/rest/v1/user_profiles');
    const allowedPhones = ['755225438', '786577921'];
    const allowedUserIds = profiles
      .filter(p => p.phone && allowedPhones.some(phone => p.phone.includes(phone)))
      .map(p => p.id);
    
    console.log('Allowed User IDs:', allowedUserIds);

    console.log('Fetching products...');
    const products = await request('GET', '/rest/v1/products');
    const productsToDelete = products.filter(p => !allowedUserIds.includes(p.owner_id));

    console.log('Products found:', products.length);
    console.log('Products to delete:', productsToDelete.length);

    for (const product of productsToDelete) {
      console.log(`Deleting product: ${product.title} (${product.id})`);
      await request('DELETE', `/rest/v1/products?id=eq.${product.id}`);
    }

    console.log('Cleanup complete!');
  } catch (error) {
    console.error('Error during cleanup:', error.message);
  }
}

cleanup();
