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

async function run() {
  const ids = [
    'eaaadf09-4573-465c-acfc-44feb681ab03',
    '4feaf64f-abe9-4975-87d3-00b81468a962',
    'b2c2f1b5-0f65-4f7e-bc50-8c10f4ce64b6'
  ];

  for (const id of ids) {
    console.log(`Deleting ${id}...`);
    try {
      const result = await request('DELETE', `/rest/v1/products?id=eq.${id}`);
      if (result.length > 0) {
        console.log(`Successfully deleted ${id}`);
      } else {
        console.log(`Failed to delete ${id} (possibly due to RLS)`);
      }
    } catch (e) {
      console.error(`Error deleting ${id}: ${e.message}`);
    }
  }
}

run();
