begin;

create or replace function public.prevent_duplicate_active_payment_month()
returns trigger language plpgsql set search_path = '' as $$
begin
  if new.status in ('pending', 'confirmed') and exists (
    select 1 from public.payment_allocations pa
    where pa.user_id = new.user_id
      and pa.allocation_month = date_trunc('month', new.allocation_month)::date
      and pa.status in ('pending', 'confirmed')
      and pa.id <> new.id
  ) then
    raise exception 'This month already has a pending or confirmed payment';
  end if;
  new.allocation_month := date_trunc('month', new.allocation_month)::date;
  return new;
end; $$;

drop trigger if exists prevent_duplicate_active_payment_month on public.payment_allocations;
create trigger prevent_duplicate_active_payment_month
before insert or update of user_id, allocation_month, status on public.payment_allocations
for each row execute function public.prevent_duplicate_active_payment_month();

create or replace function public.add_manual_selected_months_payment_admin(
  target_user_id uuid, amount_per_month numeric, payment_months date[],
  proof_path text, payment_note text
) returns uuid language plpgsql security definer set search_path = '' as $$
declare transaction_id uuid; total_amount numeric; first_month date; last_month date;
begin
  if not public.is_admin() then raise exception 'Only admin can add manual payments'; end if;
  if amount_per_month <= 0 or cardinality(payment_months) not between 1 and 24 then raise exception 'Select 1-24 months'; end if;
  if (select count(*) from unnest(payment_months)) <> (select count(distinct date_trunc('month', m)::date) from unnest(payment_months) m) then raise exception 'Duplicate months are not allowed'; end if;
  if nullif(trim(proof_path), '') is null or length(trim(payment_note)) < 5 then raise exception 'Proof and meaningful note are required'; end if;
  if exists (
    select 1 from public.payment_allocations pa
    join unnest(payment_months) m
      on pa.allocation_month = date_trunc('month', m)::date
    where pa.user_id = target_user_id and pa.status in ('pending','confirmed')
  ) then raise exception 'One or more selected months are already paid or pending'; end if;
  select min(date_trunc('month', m)::date), max(date_trunc('month', m)::date) into first_month, last_month from unnest(payment_months) m;
  total_amount := amount_per_month * cardinality(payment_months);
  insert into public.transactions(user_id,amount,month,month_year,status,confirmed_by,confirmed_at,note,receipt_url,entry_source,manual_proof_url)
  values(target_user_id,total_amount,to_char(first_month,'Mon YYYY') || case when cardinality(payment_months)>1 then ' + '||(cardinality(payment_months)-1)||' selected' else '' end,first_month,'confirmed',auth.uid(),now(),'[ADMIN MANUAL] '||trim(payment_note),trim(proof_path),'admin_manual',trim(proof_path)) returning id into transaction_id;
  insert into public.payment_allocations(transaction_id,user_id,allocation_month,amount,status)
  select transaction_id,target_user_id,date_trunc('month',m)::date,amount_per_month,'confirmed' from unnest(payment_months) m;
  update public.profiles set total_saved=coalesce(total_saved,0)+total_amount,dues=greatest(coalesce(dues,0)-total_amount,0),updated_at=now() where id=target_user_id and role='user';
  return transaction_id;
end; $$;
revoke all on function public.add_manual_selected_months_payment_admin(uuid,numeric,date[],text,text) from public,anon;
grant execute on function public.add_manual_selected_months_payment_admin(uuid,numeric,date[],text,text) to authenticated;
commit;
notify pgrst, 'reload schema';
