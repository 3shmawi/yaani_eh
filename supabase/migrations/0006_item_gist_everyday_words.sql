-- The «يعني» line must use words everyone knows, and «ميلك شيك» is a menu
-- word too: these five lines now say what the drink is made of instead.
-- Each line changes only if it still has the launch text, so anything
-- edited in Studio is kept. The touch trigger bumps updated_at, so phones
-- pick the new lines up on their next sync.

update public.items set gist_ar = $c$قهوة باللبن متخفوقة بالتلج$c$
where slug = 'coffee_frappe' and gist_ar = $c$ميلك شيك بالقهوة$c$;
update public.items set gist_en = $c$Coffee and milk blended with ice$c$
where slug = 'coffee_frappe' and gist_en = $c$A coffee milkshake$c$;

update public.items set gist_ar = $c$قهوة متخفوقة بالتلج والكراميل$c$
where slug = 'caramel_frappe' and gist_ar = $c$ميلك شيك قهوة بالكراميل$c$;
update public.items set gist_en = $c$Coffee blended with ice and caramel$c$
where slug = 'caramel_frappe' and gist_en = $c$Caramel coffee milkshake$c$;

update public.items set gist_ar = $c$قهوة متخفوقة بالتلج والشوكولاتة$c$
where slug = 'mocha_frappe' and gist_ar = $c$ميلك شيك قهوة بالشوكولاتة$c$;
update public.items set gist_en = $c$Coffee blended with ice and chocolate$c$
where slug = 'mocha_frappe' and gist_en = $c$Chocolate coffee milkshake$c$;

update public.items set gist_ar = $c$لبن بالفانيليا متخفوق بالتلج، من غير قهوة$c$
where slug = 'vanilla_cream_frappe' and gist_ar = $c$ميلك شيك فانيليا من غير قهوة$c$;
update public.items set gist_en = $c$Vanilla milk blended with ice, no coffee$c$
where slug = 'vanilla_cream_frappe' and gist_en = $c$Vanilla milkshake, no coffee$c$;

update public.items set gist_ar = $c$لبن وآيس كريم وبسكوت متخفوقين$c$
where slug = 'cookies_milkshake' and gist_ar = $c$ميلك شيك بالبسكوت$c$;
update public.items set gist_en = $c$Milk, ice cream and cookies, blended$c$
where slug = 'cookies_milkshake' and gist_en = $c$Cookie milkshake$c$;
