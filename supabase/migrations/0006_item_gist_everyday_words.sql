-- The «يعني» line must use words everyone knows, and «ميلك شيك» is a menu
-- word too, and so is «متخفوق»: these five lines now say what goes into
-- the blender, which everyone has at home.
-- Each line changes only if it still has the launch text, so anything
-- edited in Studio is kept. The touch trigger bumps updated_at, so phones
-- pick the new lines up on their next sync.

update public.items set gist_ar = $c$قهوة باللبن والتلج في الخلاط$c$
where slug = 'coffee_frappe' and gist_ar = $c$ميلك شيك بالقهوة$c$;
update public.items set gist_en = $c$Coffee, milk and ice in a blender$c$
where slug = 'coffee_frappe' and gist_en = $c$A coffee milkshake$c$;

update public.items set gist_ar = $c$قهوة وتلج وكراميل في الخلاط$c$
where slug = 'caramel_frappe' and gist_ar = $c$ميلك شيك قهوة بالكراميل$c$;
update public.items set gist_en = $c$Coffee, ice and caramel in a blender$c$
where slug = 'caramel_frappe' and gist_en = $c$Caramel coffee milkshake$c$;

update public.items set gist_ar = $c$قهوة وتلج وشوكولاتة في الخلاط$c$
where slug = 'mocha_frappe' and gist_ar = $c$ميلك شيك قهوة بالشوكولاتة$c$;
update public.items set gist_en = $c$Coffee, ice and chocolate in a blender$c$
where slug = 'mocha_frappe' and gist_en = $c$Chocolate coffee milkshake$c$;

update public.items set gist_ar = $c$لبن وفانيليا وتلج في الخلاط، من غير قهوة$c$
where slug = 'vanilla_cream_frappe' and gist_ar = $c$ميلك شيك فانيليا من غير قهوة$c$;
update public.items set gist_en = $c$Milk, vanilla and ice in a blender, no coffee$c$
where slug = 'vanilla_cream_frappe' and gist_en = $c$Vanilla milkshake, no coffee$c$;

update public.items set gist_ar = $c$لبن وآيس كريم وبسكوت في الخلاط$c$
where slug = 'cookies_milkshake' and gist_ar = $c$ميلك شيك بالبسكوت$c$;
update public.items set gist_en = $c$Milk, ice cream and cookies in a blender$c$
where slug = 'cookies_milkshake' and gist_en = $c$Cookie milkshake$c$;
