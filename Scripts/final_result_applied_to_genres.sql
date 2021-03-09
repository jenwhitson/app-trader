--grouping by play genres
WITH apurchase as (SELECT apple.name as name,
				   	CASE WHEN apple.price::money < 1::money THEN 10000::money
							ELSE (apple.price::money + .01::money) * 10000 
				   			END as apple_purchase_price
					FROM app_store_apps as apple
					GROUP BY apple.name, apple.price),
	ppurchase as (SELECT play.name as name,
				  	CASE WHEN play.price::money < 1::money THEN 10000::money
							ELSE (play.price::money + .01::money) * 10000 
				  			END as play_purchase_price
					FROM play_store_apps as play
					GROUP BY play.name, play.price),
	apple_stats AS (SELECT apple.name as name,
					 	AVG((((apple.rating) * 2) + 1) * 30000) as apple_revenue, 
						AVG(((apple.rating) * 2) + 1) as apple_years
					FROM app_store_apps as apple
					GROUP BY apple.name), 
	play_stats AS (SELECT play.name as name,
			   		AVG((((play.rating) * 2) + 1) * 30000) as play_revenue, 
					AVG(((play.rating) * 2) + 1) as play_years
				FROM play_store_apps as play
				WHERE play.rating IS NOT NULL
			  	GROUP BY play.name),
	additional AS (SELECT apple.name as additional_name, 
					AVG(astats.apple_revenue) as avg_apple_revenue,
				   	AVG(pstats.play_revenue) as avg_play_revenue,
				   	ROUND(AVG(CASE WHEN astats.apple_years < pstats.play_years 
									THEN (pstats.play_years) 
									ELSE (astats.apple_years) 
									END), 0) AS years_of_revenue,
					ROUND(AVG(CASE WHEN astats.apple_years < pstats.play_years 
									THEN (pstats.play_years * 12000) 
									ELSE (astats.apple_years * 12000) 
									END), 2) AS marketing_costs,
					ROUND(AVG(apurchase.apple_purchase_price::numeric + 
							   ppurchase.play_purchase_price::numeric), 2) as purchase_price
				FROM apple_stats as astats INNER JOIN play_stats as pstats ON astats.name = pstats.name
											INNER JOIN app_store_apps as apple ON astats.name = apple.name
											INNER JOIN play_store_apps as play ON pstats.name = play.name
											INNER JOIN apurchase ON apurchase.name = apple.name
											INNER JOIN ppurchase ON ppurchase.name = play.name
				GROUP BY additional_name
				ORDER BY years_of_revenue desc)
SELECT 
	DISTINCT(play.name) as name,
	SELECT ROUND(AVG(apple.rating), 2) as apple_rating,
	ROUND(AVG(play.rating), 2) as play_rating,
	ROUND(AVG(astats.apple_revenue + pstats.play_revenue), 2) as total_revenue,
	ROUND(AVG(additional.marketing_costs), 2) as marketing_costs,
	ROUND(AVG(additional.purchase_price), 2) as purchase_price,
	ROUND(AVG(additional.avg_apple_revenue + additional.avg_play_revenue - additional.marketing_costs - additional.purchase_price), 2) as net_profit,
	play.genres
FROM apple_stats as astats INNER JOIN play_stats as pstats ON astats.name = pstats.name
											INNER JOIN app_store_apps as apple ON astats.name = apple.name
											INNER JOIN play_store_apps as play ON pstats.name = play.name
											INNER JOIN apurchase ON apurchase.name = apple.name
											INNER JOIN ppurchase ON ppurchase.name = play.name
											INNER JOIN additional ON additional.additional_name = apple.name
WHERE play.genres ilike '%card%'
GROUP BY play.name, play.genres
ORDER BY net_profit desc
LIMIT 10;

SELECT DISTINCT(play.name), play.genres
FROM play_store_apps as play INNER JOIN app_store_apps as apple ON play.name = apple.name
WHERE play.genres ILIKE 'card%'
--card; Brain Games is just Solitaire

SELECT DISTINCT(play.name), play.genres
FROM play_store_apps as play INNER JOIN app_store_apps as apple ON play.name = apple.name
WHERE play.genres ILIKE 'trivia';
--Trivia is just Trivia Crack

SELECT DISTINCT(play.name), play.genres
FROM play_store_apps as play INNER JOIN app_store_apps as apple ON play.name = apple.name
WHERE play.genres ILIKE 'action;action%';
--OK K.O.! Lakewood Plaza Turbo

SELECT DISTINCT(play.name), play.genres
FROM play_store_apps as play INNER JOIN app_store_apps as apple ON play.name = apple.name
WHERE play.genres ILIKE 'racing;action%';
--Hot Wheels: Race Off, Real Racing 3

SELECT DISTINCT(play.name), play.genres
FROM play_store_apps as play INNER JOIN app_store_apps as apple ON play.name = apple.name
WHERE play.genres ILIKE 'casual';
--17 apps

SELECT DISTINCT(play.name), play.genres
FROM play_store_apps as play INNER JOIN app_store_apps as apple ON play.name = apple.name
WHERE play.genres ILIKE 'puzzle;brain%';
--inside out thought bubbles, where's my water?

SELECT DISTINCT(play.name), play.genres
FROM play_store_apps as play INNER JOIN app_store_apps as apple ON play.name = apple.name
WHERE play.genres ILIKE 'arcade';
--27 apps

SELECT DISTINCT(play.name), play.genres
FROM play_store_apps as play INNER JOIN app_store_apps as apple ON play.name = apple.name
WHERE play.genres ILIKE 'Puzzle%';
--Frozen Free Fall, PAC-MAN Pop

SELECT DISTINCT(play.name), play.genres
FROM play_store_apps as play INNER JOIN app_store_apps as apple ON play.name = apple.name
WHERE play.genres ILIKE 'adventure;action%';
--LEGO Batman, ROBLOX


