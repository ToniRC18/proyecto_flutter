-- Función que se ejecuta al crear un usuario nuevo en Auth
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  v_tenant_id UUID;
BEGIN
  -- Crear perfil del usuario
  INSERT INTO profiles (id, name, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'Usuario'),
    NEW.raw_user_meta_data->>'avatar_url'
  )
  ON CONFLICT (id) DO NOTHING;

  -- Crear tenant personal
  INSERT INTO tenants (id, name, type)
  VALUES (
    gen_random_uuid(),
    'Personal',
    'personal'
  )
  RETURNING id INTO v_tenant_id;

  -- Agregar usuario como owner del tenant personal
  INSERT INTO tenant_members (tenant_id, user_id, role)
  VALUES (v_tenant_id, NEW.id, 'owner')
  ON CONFLICT DO NOTHING;

  -- Crear cuenta de efectivo por defecto
  INSERT INTO accounts (tenant_id, name, type, balance)
  VALUES (v_tenant_id, 'Efectivo', 'cash', 0.00)
  ON CONFLICT DO NOTHING;

  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Log del error sin romper el registro
    RAISE WARNING 'handle_new_user falló para %: %', NEW.id, SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Eliminar trigger si existe para evitar duplicados
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Crear trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();
