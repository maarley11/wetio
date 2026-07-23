-- Create public bucket for product images
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'product-images',
    'product-images',
    true,
    10485760,
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
) ON CONFLICT (id) DO NOTHING;

-- RLS: Anyone can view product images
CREATE POLICY "public_read_product_images" ON storage.objects
FOR SELECT TO public
USING (bucket_id = 'product-images');

-- RLS: Authenticated users can upload product images
CREATE POLICY "authenticated_upload_product_images" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'product-images');

-- RLS: Owners can delete their product images
CREATE POLICY "owners_delete_product_images" ON storage.objects
FOR DELETE TO authenticated
USING (bucket_id = 'product-images' AND owner = auth.uid());

-- RLS: Owners can update their product images
CREATE POLICY "owners_update_product_images" ON storage.objects
FOR UPDATE TO authenticated
USING (bucket_id = 'product-images' AND owner = auth.uid());

-- Ensure products table has RLS policies for INSERT
DO $$
BEGIN
  -- Policy: authenticated users can insert their own products
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'products' AND policyname = 'users_insert_own_products'
  ) THEN
    EXECUTE 'CREATE POLICY "users_insert_own_products" ON public.products
      FOR INSERT TO authenticated
      WITH CHECK (owner_id = auth.uid())';
  END IF;

  -- Policy: authenticated users can update their own products
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'products' AND policyname = 'users_update_own_products'
  ) THEN
    EXECUTE 'CREATE POLICY "users_update_own_products" ON public.products
      FOR UPDATE TO authenticated
      USING (owner_id = auth.uid())
      WITH CHECK (owner_id = auth.uid())';
  END IF;

  -- Policy: anyone can read active products
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'products' AND policyname = 'public_read_active_products'
  ) THEN
    EXECUTE 'CREATE POLICY "public_read_active_products" ON public.products
      FOR SELECT TO public
      USING (is_active = true)';
  END IF;

  -- Policy: owners can read all their own products (including inactive)
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'products' AND policyname = 'owners_read_own_products'
  ) THEN
    EXECUTE 'CREATE POLICY "owners_read_own_products" ON public.products
      FOR SELECT TO authenticated
      USING (owner_id = auth.uid())';
  END IF;

  -- Policy: owners can delete their own products
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'products' AND policyname = 'users_delete_own_products'
  ) THEN
    EXECUTE 'CREATE POLICY "users_delete_own_products" ON public.products
      FOR DELETE TO authenticated
      USING (owner_id = auth.uid())';
  END IF;
END $$;
