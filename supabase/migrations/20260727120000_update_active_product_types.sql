/*
  # Update active product types

  ## Problem
  The original constraint (migration 20251213063312) only allowed three
  product types while the registration form offered five. Selecting
  'bimbel_only' or 'vip_plus_membership' therefore always failed on submit
  with a check constraint violation (SQLSTATE 23514).

  ## Change
  - 'bimbel_prop' is no longer offered and is removed from the allowed set.
  - The constraint now matches exactly the products the form can submit.

  Active products: ea_trading, bimbel_only, vip_membership, vip_plus_membership
*/

ALTER TABLE clients DROP CONSTRAINT IF EXISTS clients_product_type_check;

ALTER TABLE clients ADD CONSTRAINT clients_product_type_check
  CHECK (product_type = ANY (ARRAY[
    'ea_trading'::text,
    'bimbel_only'::text,
    'vip_membership'::text,
    'vip_plus_membership'::text
  ]));
