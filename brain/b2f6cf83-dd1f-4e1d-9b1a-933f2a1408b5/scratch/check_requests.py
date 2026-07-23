import os
import json
from supabase import create_client, Client

url = "https://zjcnggoxjyonahoiansk.supabase.co"
key = "ey..." # I don't have the full key, but I can find it in env.json

def check():
    with open('c:/wetio/env.json', 'r') as f:
        env = json.load(f)
    
    supabase: Client = create_client(env['SUPABASE_URL'], env['ANON_KEY'])
    
    # Get last 5 requests
    res = supabase.table('delivery_requests').select('*').order('created_at', desc=True).limit(5).execute()
    print("Last 5 requests:")
    for r in res.data:
        print(f"ID: {r['id']}, Initiator: {r.get('initiator_id')}, Partner: {r.get('partner_user_id')}, Status: {r.get('delivery_status')}")

if __name__ == "__main__":
    check()
