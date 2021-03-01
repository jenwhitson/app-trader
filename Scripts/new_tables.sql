--final net profit calculations for apps in both stores
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
SELECT apple.name as app_name,
	ROUND(AVG(apple.rating), 2) as apple_rating,
	ROUND(AVG(play.rating), 2) as play_rating,
	ROUND(AVG(astats.apple_revenue + pstats.play_revenue), 2) as total_revenue,
	ROUND(AVG(additional.marketing_costs), 2) as marketing_costs,
	ROUND(AVG(additional.purchase_price), 2) as purchase_price,
	ROUND(AVG(additional.avg_apple_revenue + additional.avg_play_revenue - additional.marketing_costs - additional.purchase_price), 2) as net_profit
FROM apple_stats as astats INNER JOIN play_stats as pstats ON astats.name = pstats.name
											INNER JOIN app_store_apps as apple ON astats.name = apple.name
											INNER JOIN play_store_apps as play ON pstats.name = play.name
											INNER JOIN apurchase ON apurchase.name = apple.name
											INNER JOIN ppurchase ON ppurchase.name = play.name
											INNER JOIN additional ON additional.additional_name = apple.name
GROUP BY app_name
ORDER BY net_profit desc;


--calculating play only revenue
SELECT play.name,
	AVG(play.rating) as rating,
	play.price::money,
	SUM((play.price::money + 1::money)* 10000) as purchase_price,
	SUM((((play.rating::money)*2 + 1::money) * 1500 * 12) - ((play.price::money + 1::money)* 10000)) as net_profit
FROM play_store_apps as play
GROUP BY play.name, play.price;

--calculating apple only revenue
SELECT apple.name,
	AVG(apple.rating) as rating,
	apple.price::money,
	SUM((apple.price::money + 1::money)* 10000) as purchase_price,
	SUM((((apple.rating::money)*2 + 1::money) * 1500 * 12) - ((apple.price::money + 1::money)* 10000)) as net_profit
FROM app_store_apps as apple
GROUP BY apple.name, apple.price;

--apple only net profits
WITH play_only AS (SELECT play.name as name,
						AVG(play.rating) as rating,
						play.price::money,
						SUM((play.price::money + 1::money)* 10000) as purchase_price,
						SUM((((play.rating::money)*2 + 1::money) * 1500 * 12) - ((play.price::money + 1::money)* 10000)) as net_profit
					FROM play_store_apps as play
					GROUP BY play.name, play.price),
apple_only AS (SELECT apple.name as name,
					AVG(apple.rating) as rating,
					apple.price::money,
					SUM((apple.price::money + 1::money)* 10000) as purchase_price,
					SUM((((apple.rating::money)*2 + 1::money) * 1500 * 12) - ((apple.price::money + 1::money)* 10000)) as net_profit
				FROM app_store_apps as apple
				GROUP BY apple.name, apple.price)
SELECT apple.name as apple_only_app, apple.rating as rating, apple.price::money, apple_only.net_profit as apple_only_net_profit
FROM app_store_apps as apple INNER JOIN apple_only ON apple.name = apple_only.name
EXCEPT 
SELECT play.name, play.rating, play.price::money, play_only.net_profit
FROM play_store_apps as play INNER JOIN play_only ON play.name = play_only.name;

--play only net profits. this is still way too complicated, and just spins and spins.
WITH play_money AS (SELECT play.price::money as price
				   	FROM play_store_apps as play),
play_only AS (SELECT play.name as name,
						AVG(play.rating) as rating,
						AVG(play_money.price::numeric) as price,
						AVG((play_money.price::numeric + 1)* 10000) as purchase_price,
						AVG((((play.rating)*2 + 1) * 1500 * 12) - ((play_money.price::numeric + 1::numeric)* 10000)) as net_profit
					FROM play_store_apps as play INNER JOIN play_money ON play.price::money = play_money.price
					GROUP BY play.name, play.price),
apple_only AS (SELECT apple.name as name,
					AVG(apple.rating) as rating,
					apple.price::money,
					SUM((apple.price::money + 1::money)* 10000) as purchase_price,
					SUM((((apple.rating::money)*2 + 1::money) * 1500 * 12) - ((apple.price::money + 1::money)* 10000)) as net_profit
				FROM app_store_apps as apple
				GROUP BY apple.name, apple.price)
SELECT play.name as play_only_app, AVG(play.rating) as rating, AVG(play_only.price::numeric) as price, AVG(play_only.net_profit::numeric) as play_only_net_profit
FROM play_store_apps as play FULL JOIN app_store_apps as apple ON play.name = apple.name
	INNER JOIN play_only ON play.name = play_only.name
	INNER JOIN play_money ON play.price::money = play_money.price
GROUP BY play.name, play_only.price
EXCEPT 
SELECT apple.name, AVG(apple.rating), AVG(apple.price::numeric), AVG(apple_only.net_profit::numeric)
FROM app_store_apps as apple INNER JOIN apple_only ON apple.name = apple_only.name
GROUP BY apple.name, apple.price
ORDER BY play_only_net_profit;


--grouping apple only net profits by rating. this isn't really working yet. 
SELECT apple.rating, 
		apple.price, 
		AVG((apple.price + 1)* 10000) as purchase_price,
		AVG((((apple.rating)*2 + 1) * 1500 * 12) - ((apple.price + 1)* 10000)) as net_profit
FROM app_store_apps as apple
GROUP BY CUBE (apple.rating, apple.price)
ORDER BY apple.rating;

--find most common prices in apple store
SELECT distinct(price),
		COUNT(price)
FROM app_store_apps
WHERE price > .99
GROUP BY price
LIMIT 10;


