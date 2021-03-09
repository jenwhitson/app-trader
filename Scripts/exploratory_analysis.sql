SELECT *
FROM app_store_apps
WHERE name ilike 'ROB%'
LIMIT 20;
--cols: name, size_bytes, currency, price (numeric), review_count (text), rating (numeric), content_rating (text), primary_genre
--7,197 rows

SELECT *
FROM play_store_apps
WHERE name ilike 'ROBLOX'
LIMIT 20;
--cols: name, category, rating (numeric), review_count (integer), size, install_count, type, price (text), content_rating (text), genres
--10,840 rows

--all apps and relevant data from both app stores
SELECT name, price::money, review_count::integer, rating, content_rating, primary_genre
FROM app_store_apps
UNION
SELECT name, price::money, review_count, rating, content_rating, genres
FROM play_store_apps
ORDER BY name;

--what apps are present in both app stores?
SELECT apple.name, apple.price::money as apple_money, play.price::money as play_price, apple.review_count::integer as apple_review_count, play.review_count as play_review_count, apple.rating as apple_rating, play.rating as play_rating, apple.content_rating as apple_content_rating, play.content_rating as play_content_rating, apple.primary_genre as apple_genre, play.genres as play_genre
FROM app_store_apps as apple INNER JOIN play_store_apps as play ON apple.name = play.name;

--averaging star ratings and summing review_count
SELECT apple.name, apple.price, SUM(apple.review_count::integer + play.review_count::integer) as total_review_count, (AVG(apple.rating + play.rating)/2) as avg_rating
FROM app_store_apps as apple INNER JOIN play_store_apps as play ON apple.name = play.name
GROUP BY apple.name, apple.price
ORDER BY avg_rating desc, total_review_count desc
LIMIT 20;

--remove all non-free apps and calculate variance of ratings between app stores
SELECT apple.name, 
	SUM(apple.review_count::integer + play.review_count::integer) as total_review_count, 
	(AVG(apple.rating + play.rating)/2) as avg_rating, 
	ABS(SUM(apple.rating - play.rating)) as rating_variance
FROM app_store_apps as apple INNER JOIN play_store_apps as play ON apple.name = play.name
WHERE apple.price = 0
	AND play.price = '0'
GROUP BY apple.name
ORDER BY avg_rating desc, total_review_count desc
LIMIT 20;

/*instead of removing non-free apps, adjusted rating to account for price in app store, 
assuming that apps that are present in both stores generate $5k in income for App Trade
and cost only $1k to market.*/
SELECT apple.name, 
	apple.price, 
	SUM(apple.review_count::integer + play.review_count::integer) as total_review_count, 
	(CASE WHEN apple.price < 1 
			THEN (AVG(apple.rating + play.rating)/2) 
			ELSE ((AVG(apple.rating + play.rating)/2) - ((apple.price - 1) *.208333))
			END) AS adjusted_avg_rating,
	ABS(SUM(apple.rating - play.rating)) as rating_variance
FROM app_store_apps as apple INNER JOIN play_store_apps as play ON apple.name = play.name
GROUP BY apple.name, apple.price
ORDER BY adjusted_avg_rating desc, total_review_count desc
LIMIT 20;

/*Does rating variance make a difference? YES. bc as soon as 1 app 
store runs out, the other one is only generating $1500 per month instead
of $4,000.
Also, now that we know apps have to be purchased from both stores, we will have to run
the numbers for adjusted average ratings in the play store. may be a challenge
since those numbers are stored as text.
Want to add in a column for revenue that will calculate star rating * $4k per month minus purchasing costs.*/

--creating revenue column and life of app column for app store apps
SELECT apple.name, 
		apple.price::money as apple_price, 
		apple.rating as apple_rating, 
		(apple.rating + 1) * 60000 as apple_revenue, 
		(apple.rating * 2) + 1 as apple_years
FROM app_store_apps as apple 
ORDER BY apple.rating desc
LIMIT 100;

--creating revenue column and life of app column for play store apps
SELECT play.name, 
		play.price::money as play_price, 
		play.rating as play_rating, 
		(play.rating + 1) * 60000 as play_revenue, 
		(play.rating * 2) + 1 as play_years
FROM play_store_apps as play
WHERE play.rating IS NOT NULL
ORDER BY play.rating desc
LIMIT 100;


--joined tables and created total revenue column.
WITH apple_stats AS (SELECT apple.name as name,
					 	(apple.rating + 1) * 60000 as apple_revenue, 
						(apple.rating * 2) + 1 as apple_years
					FROM app_store_apps as apple), 
play_stats AS (SELECT play.name as name,
			   		(play.rating + 1) * 60000 as play_revenue, 
					(play.rating * 2) + 1 as play_years
				FROM play_store_apps as play
				WHERE play.rating IS NOT NULL)
SELECT apple.name as app_name, 
	SUM(astats.apple_revenue + pstats.play_revenue) as total_revenue
FROM apple_stats as astats INNER JOIN play_stats as pstats ON astats.name = pstats.name
							INNER JOIN app_store_apps as apple ON astats.name = apple.name
							INNER JOIN play_store_apps as play ON pstats.name = play.name
GROUP BY app_name
ORDER BY total_revenue desc;


--calculated costs
WITH apple_stats AS (SELECT apple.name as name,
					 	(apple.rating + 1) * 60000 as apple_revenue, 
						(apple.rating * 2) + 1 as apple_years
					FROM app_store_apps as apple
					GROUP BY apple.name), 
play_stats AS (SELECT play.name as name,
			   		(play.rating + 1) * 60000 as play_revenue, 
					(play.rating * 2) + 1 as play_years
				FROM play_store_apps as play
				WHERE play.rating IS NOT NULL)
SELECT apple.name as app_name, 
	AVG(astats.apple_revenue + pstats.play_revenue) as total_revenue,
	ABS(SUM(astats.apple_years - pstats.play_years)) as years_variance
FROM apple_stats as astats INNER JOIN play_stats as pstats ON astats.name = pstats.name
							INNER JOIN app_store_apps as apple ON astats.name = apple.name
							INNER JOIN play_store_apps as play ON pstats.name = play.name
GROUP BY app_name, apple.rating
ORDER BY total_revenue desc;

--Why are we getting such huge numbers for variance?
SELECT name, price::money, review_count::integer, rating, content_rating, primary_genre
FROM app_store_apps
WHERE name iLIKE 'snapchat%'
UNION
SELECT name, price::money, review_count, rating, content_rating, genres
FROM play_store_apps
WHERE name iLIKE 'snapchat%'
ORDER BY name;


--averaged ratings within app stores to account for multiple copies of same app
WITH apple_stats AS (SELECT apple.name as name,
					 	(AVG(apple.rating) + 1) * 60000 as apple_revenue, 
						(AVG(apple.rating) * 2) + 1 as apple_years
					FROM app_store_apps as apple
					GROUP BY apple.name), 
play_stats AS (SELECT play.name as name,
			   		(AVG(play.rating) + .5) * 60000 as play_revenue, 
					(AVG(play.rating) * 2) + 1 as play_years
				FROM play_store_apps as play
				WHERE play.rating IS NOT NULL
			  	GROUP BY play.name)
SELECT apple.name as app_name, 
	ROUND(SUM(astats.apple_revenue + pstats.play_revenue), 2) as total_revenue,
	ROUND(ABS(AVG(astats.apple_years) - AVG(pstats.play_years)), 2) as years_variance,
	ROUND(AVG(apple.rating), 2) as avg_apple_rating,
	ROUND(AVG(play.rating), 2) as avg_play_rating
FROM apple_stats as astats INNER JOIN play_stats as pstats ON astats.name = pstats.name
							INNER JOIN app_store_apps as apple ON astats.name = apple.name
							INNER JOIN play_store_apps as play ON pstats.name = play.name
GROUP BY app_name
ORDER BY years_variance desc;

--Separated out years in both app stores and years in one store.
WITH apple_stats AS (SELECT apple.name as name,
					 	(AVG(apple.rating) + 1) * 60000 as apple_revenue, 
						(AVG(apple.rating) * 2) + 1 as apple_years
					FROM app_store_apps as apple
					GROUP BY apple.name), 
play_stats AS (SELECT play.name as name,
			   		(AVG(play.rating) + .5) * 60000 as play_revenue, 
					(AVG(play.rating) * 2) + 1 as play_years
				FROM play_store_apps as play
				WHERE play.rating IS NOT NULL
			  	GROUP BY play.name)
SELECT apple.name as app_name, 
	ROUND(SUM(astats.apple_revenue + pstats.play_revenue), 2) as total_revenue,
	ROUND(AVG(CASE WHEN astats.apple_years > pstats.play_years 
			  		THEN (pstats.play_years) 
			  		ELSE (astats.apple_years) 
			  		END), 0) AS years_in_both_app_stores,
	ROUND(ABS(AVG(astats.apple_years) - AVG(pstats.play_years)), 2) as years_in_one_store,
	ROUND(AVG(apple.rating), 2) as avg_apple_rating,
	ROUND(AVG(play.rating), 2) as avg_play_rating
FROM apple_stats as astats INNER JOIN play_stats as pstats ON astats.name = pstats.name
							INNER JOIN app_store_apps as apple ON astats.name = apple.name
							INNER JOIN play_store_apps as play ON pstats.name = play.name
GROUP BY app_name
ORDER BY years_in_both_app_stores desc, years_in_one_store;

--switch to taking longest years and calculated marketing costs
WITH apple_stats AS (SELECT apple.name as name,
					 	(AVG(apple.rating) + 1) * 60000 as apple_revenue, 
						(AVG(apple.rating) * 2) + 1 as apple_years
					FROM app_store_apps as apple
					GROUP BY apple.name), 
play_stats AS (SELECT play.name as name,
			   		(AVG(play.rating) + .5) * 60000 as play_revenue, 
					(AVG(play.rating) * 2) + 1 as play_years
				FROM play_store_apps as play
				WHERE play.rating IS NOT NULL
			  	GROUP BY play.name)
SELECT apple.name as app_name, 
	ROUND(SUM(astats.apple_revenue + pstats.play_revenue), 2) as total_revenue,
	ROUND(AVG(CASE WHEN astats.apple_years < pstats.play_years 
			  		THEN (pstats.play_years) 
			  		ELSE (pstats.play_years) 
			  		END), 0) AS years_of_revenue,
	ROUND(ABS(AVG(astats.apple_years) - AVG(pstats.play_years)), 2) as years_in_one_store,
	ROUND(AVG(apple.rating), 2) as avg_apple_rating,
	ROUND(AVG(astats.apple_revenue), 2) as avg_apple_revenue,
	ROUND(AVG(play.rating), 2) as avg_play_rating,
	ROUND(AVG(pstats.play_revenue), 2) as avg_play_revenue
FROM apple_stats as astats INNER JOIN play_stats as pstats ON astats.name = pstats.name
							INNER JOIN app_store_apps as apple ON astats.name = apple.name
							INNER JOIN play_store_apps as play ON pstats.name = play.name
GROUP BY app_name
ORDER BY years_of_revenue desc;

/*Next, need to calculate costs somehow. Basically, cost 
will be $500/app store for years in both and $1000 for years in one.
Once marketing costs are calculated, we can bring back in the cost of 
the app to acquire and subtract that from revenue, and then we should 
be able to subtract all costs from all revenue and have our final list.*/

--added marketing costs
WITH apple_stats AS (SELECT apple.name as name,
					 	(AVG(apple.rating) + 1) * 60000 as apple_revenue, 
						(AVG(apple.rating) * 2) + 1 as apple_years
					FROM app_store_apps as apple
					GROUP BY apple.name), 
play_stats AS (SELECT play.name as name,
			   		(AVG(play.rating) + .5) * 60000 as play_revenue, 
					(AVG(play.rating) * 2) + 1 as play_years
				FROM play_store_apps as play
				WHERE play.rating IS NOT NULL
			  	GROUP BY play.name)
SELECT apple.name as app_name, 
	ROUND(ABS(AVG(astats.apple_years) - AVG(pstats.play_years)), 2) as years_in_one_store,
	ROUND(AVG(apple.rating), 2) as avg_apple_rating,
	ROUND(AVG(astats.apple_revenue), 2) as avg_apple_revenue,
	ROUND(AVG(play.rating), 2) as avg_play_rating,
	ROUND(AVG(pstats.play_revenue), 2) as avg_play_revenue,
	ROUND(AVG(CASE WHEN astats.apple_years < pstats.play_years 
			  		THEN (pstats.play_years) 
			  		ELSE (pstats.play_years) 
			  		END), 0) AS years_of_revenue,
	ROUND(AVG(CASE WHEN astats.apple_years < pstats.play_years 
			  		THEN (pstats.play_years * 12000) 
			  		ELSE (astats.apple_years * 12000) 
			  		END), 2) AS marketing_costs
FROM apple_stats as astats INNER JOIN play_stats as pstats ON astats.name = pstats.name
							INNER JOIN app_store_apps as apple ON astats.name = apple.name
							INNER JOIN play_store_apps as play ON pstats.name = play.name
GROUP BY app_name
ORDER BY years_of_revenue desc;

--calculated purchase costs
SELECT CASE WHEN apple.price::money < 1::money THEN 10000::money
			ELSE (apple.price::money - .99::money) * 10000 END as apple_purchase_price
FROM app_store_apps as apple
GROUP BY apple.name, apple.price;

SELECT CASE WHEN play.price::money < 1::money THEN 10000::money
			ELSE (play.price::money - .99::money) * 10000 END as play_purchase_price
FROM play_store_apps as play
GROUP BY play.name, play.price;

--added in purchase costs
WITH apurchase as (SELECT apple.name as name,
				   	CASE WHEN apple.price::money < 1::money THEN 10000::money
							ELSE (apple.price::money - .99::money) * 10000 
				   			END as apple_purchase_price
					FROM app_store_apps as apple
					GROUP BY apple.name, apple.price),
	ppurchase as (SELECT play.name as name,
				  	CASE WHEN play.price::money < 1::money THEN 10000::money
							ELSE (play.price::money - .99::money) * 10000 
				  			END as play_purchase_price
					FROM play_store_apps as play
					GROUP BY play.name, play.price),
	apple_stats AS (SELECT apple.name as name,
					 	(AVG(apple.rating) + 1) * 60000 as apple_revenue, 
						(AVG(apple.rating) * 2) + 1 as apple_years
					FROM app_store_apps as apple
					GROUP BY apple.name), 
	play_stats AS (SELECT play.name as name,
			   		(AVG(play.rating) + .5) * 60000 as play_revenue, 
					(AVG(play.rating) * 2) + 1 as play_years
				FROM play_store_apps as play
				WHERE play.rating IS NOT NULL
			  	GROUP BY play.name)
SELECT apple.name as app_name, 
	ROUND(AVG(apple.rating), 2) as avg_apple_rating,
	ROUND(AVG(astats.apple_revenue), 2) as avg_apple_revenue,
	ROUND(AVG(play.rating), 2) as avg_play_rating,
	ROUND(AVG(pstats.play_revenue), 2) as avg_play_revenue,
	ROUND(AVG(CASE WHEN astats.apple_years < pstats.play_years 
			  		THEN (pstats.play_years) 
			  		ELSE (pstats.play_years) 
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
GROUP BY app_name
ORDER BY years_of_revenue desc;

--calculated net_profit
WITH apurchase as (SELECT apple.name as name,
				   	CASE WHEN apple.price::money < 1::money THEN 10000::money
							ELSE (apple.price::money - .99::money) * 10000 
				   			END as apple_purchase_price
					FROM app_store_apps as apple
					GROUP BY apple.name, apple.price),
	ppurchase as (SELECT play.name as name,
				  	CASE WHEN play.price::money < 1::money THEN 10000::money
							ELSE (play.price::money - .99::money) * 10000 
				  			END as play_purchase_price
					FROM play_store_apps as play
					GROUP BY play.name, play.price),
	apple_stats AS (SELECT apple.name as name,
					 	(AVG(apple.rating) + 1) * 60000 as apple_revenue, 
						(AVG(apple.rating) * 2) + 1 as apple_years
					FROM app_store_apps as apple
					GROUP BY apple.name), 
	play_stats AS (SELECT play.name as name,
			   		(AVG(play.rating) + .5) * 60000 as play_revenue, 
					(AVG(play.rating) * 2) + 1 as play_years
				FROM play_store_apps as play
				WHERE play.rating IS NOT NULL
			  	GROUP BY play.name),
	additional AS (SELECT apple.name as additional_name, 
					ROUND(AVG(apple.rating), 2) as avg_apple_rating,
					ROUND(AVG(astats.apple_revenue), 2) as avg_apple_revenue,
					ROUND(AVG(play.rating), 2) as avg_play_rating,
					ROUND(AVG(pstats.play_revenue), 2) as avg_play_revenue,
					ROUND(AVG(CASE WHEN astats.apple_years < pstats.play_years 
									THEN (pstats.play_years) 
									ELSE (pstats.play_years) 
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
	SUM(additional.avg_apple_revenue + additional.avg_play_revenue - additional.marketing_costs - additional.purchase_price) as net_profit
FROM apple_stats as astats INNER JOIN play_stats as pstats ON astats.name = pstats.name
											INNER JOIN app_store_apps as apple ON astats.name = apple.name
											INNER JOIN play_store_apps as play ON pstats.name = play.name
											INNER JOIN apurchase ON apurchase.name = apple.name
											INNER JOIN ppurchase ON ppurchase.name = play.name
			
			INNER JOIN additional ON additional.additional_name = apple.name
GROUP BY app_name
ORDER BY net_profit desc;

--added in descriptive columns AND CORRECTED SEVERAL ERRORS
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
	AVG(additional.avg_apple_revenue + additional.avg_play_revenue - additional.marketing_costs - additional.purchase_price) as net_profit
FROM apple_stats as astats INNER JOIN play_stats as pstats ON astats.name = pstats.name
											INNER JOIN app_store_apps as apple ON astats.name = apple.name
											INNER JOIN play_store_apps as play ON pstats.name = play.name
											INNER JOIN apurchase ON apurchase.name = apple.name
											INNER JOIN ppurchase ON ppurchase.name = play.name
											INNER JOIN additional ON additional.additional_name = apple.name
GROUP BY app_name
ORDER BY net_profit desc
LIMIT 300;

/*Next, we can look at some trends across
genres, content ratings, and prices, or 
if the fellas get that done, we can focus
on viz.*/

--apple content rating in order of avg net profit
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
	ROUND(AVG(apple.rating), 2) as apple_rating,
	ROUND(AVG(play.rating), 2) as play_rating,
	ROUND(AVG(astats.apple_revenue + pstats.play_revenue), 2) as total_revenue,
	ROUND(AVG(additional.marketing_costs), 2) as marketing_costs,
	ROUND(AVG(additional.purchase_price), 2) as purchase_price,
	ROUND(AVG(additional.avg_apple_revenue + additional.avg_play_revenue - additional.marketing_costs - additional.purchase_price), 2) as net_profit,
	apple.content_rating
FROM apple_stats as astats INNER JOIN play_stats as pstats ON astats.name = pstats.name
											INNER JOIN app_store_apps as apple ON astats.name = apple.name
											INNER JOIN play_store_apps as play ON pstats.name = play.name
											INNER JOIN apurchase ON apurchase.name = apple.name
											INNER JOIN ppurchase ON ppurchase.name = play.name
											INNER JOIN additional ON additional.additional_name = apple.name
GROUP BY apple.content_rating
ORDER BY net_profit desc;


--grouping by apple genre
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
	ROUND(AVG(apple.rating), 2) as apple_rating,
	ROUND(AVG(play.rating), 2) as play_rating,
	ROUND(AVG(astats.apple_revenue + pstats.play_revenue), 2) as total_revenue,
	ROUND(AVG(additional.marketing_costs), 2) as marketing_costs,
	ROUND(AVG(additional.purchase_price), 2) as purchase_price,
	ROUND(AVG(additional.avg_apple_revenue + additional.avg_play_revenue - additional.marketing_costs - additional.purchase_price), 2) as net_profit,
	apple.primary_genre
FROM apple_stats as astats INNER JOIN play_stats as pstats ON astats.name = pstats.name
											INNER JOIN app_store_apps as apple ON astats.name = apple.name
											INNER JOIN play_store_apps as play ON pstats.name = play.name
											INNER JOIN apurchase ON apurchase.name = apple.name
											INNER JOIN ppurchase ON ppurchase.name = play.name
											INNER JOIN additional ON additional.additional_name = apple.name
GROUP BY apple.primary_genre
ORDER BY net_profit desc
LIMIT 10;

--grouping by apple price
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
	ROUND(AVG(apple.rating), 2) as apple_rating,
	ROUND(AVG(play.rating), 2) as play_rating,
	ROUND(AVG(astats.apple_revenue + pstats.play_revenue), 2) as total_revenue,
	ROUND(AVG(additional.marketing_costs), 2) as marketing_costs,
	ROUND(AVG(additional.purchase_price), 2) as purchase_price,
	ROUND(AVG(additional.avg_apple_revenue + additional.avg_play_revenue - additional.marketing_costs - additional.purchase_price), 2) as net_profit,
	apple.price
FROM apple_stats as astats INNER JOIN play_stats as pstats ON astats.name = pstats.name
											INNER JOIN app_store_apps as apple ON astats.name = apple.name
											INNER JOIN play_store_apps as play ON pstats.name = play.name
											INNER JOIN apurchase ON apurchase.name = apple.name
											INNER JOIN ppurchase ON ppurchase.name = play.name
											INNER JOIN additional ON additional.additional_name = apple.name
GROUP BY apple.price
ORDER BY net_profit desc;

--grouping by play content rating
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
	ROUND(AVG(apple.rating), 2) as apple_rating,
	ROUND(AVG(play.rating), 2) as play_rating,
	ROUND(AVG(astats.apple_revenue + pstats.play_revenue), 2) as total_revenue,
	ROUND(AVG(additional.marketing_costs), 2) as marketing_costs,
	ROUND(AVG(additional.purchase_price), 2) as purchase_price,
	ROUND(AVG(additional.avg_apple_revenue + additional.avg_play_revenue - additional.marketing_costs - additional.purchase_price), 2) as net_profit,
	play.content_rating
FROM apple_stats as astats INNER JOIN play_stats as pstats ON astats.name = pstats.name
											INNER JOIN app_store_apps as apple ON astats.name = apple.name
											INNER JOIN play_store_apps as play ON pstats.name = play.name
											INNER JOIN apurchase ON apurchase.name = apple.name
											INNER JOIN ppurchase ON ppurchase.name = play.name
											INNER JOIN additional ON additional.additional_name = apple.name
GROUP BY play.content_rating
ORDER BY net_profit desc;

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
GROUP BY play.genres
ORDER BY net_profit desc
LIMIT 10;

--grouping by play price
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
	ROUND(AVG(apple.rating), 2) as apple_rating,
	ROUND(AVG(play.rating), 2) as play_rating,
	ROUND(AVG(astats.apple_revenue + pstats.play_revenue), 2) as total_revenue,
	ROUND(AVG(additional.marketing_costs), 2) as marketing_costs,
	ROUND(AVG(additional.purchase_price), 2) as purchase_price,
	ROUND(AVG(additional.avg_apple_revenue + additional.avg_play_revenue - additional.marketing_costs - additional.purchase_price), 2) as net_profit,
	play.price
FROM apple_stats as astats INNER JOIN play_stats as pstats ON astats.name = pstats.name
											INNER JOIN app_store_apps as apple ON astats.name = apple.name
											INNER JOIN play_store_apps as play ON pstats.name = play.name
											INNER JOIN apurchase ON apurchase.name = apple.name
											INNER JOIN ppurchase ON ppurchase.name = play.name
											INNER JOIN additional ON additional.additional_name = apple.name
GROUP BY play.price
ORDER BY net_profit desc;

--grouping by apple price
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
	ROUND(AVG(apple.rating), 2) as apple_rating,
	ROUND(AVG(play.rating), 2) as play_rating,
	ROUND(AVG(astats.apple_revenue + pstats.play_revenue), 2) as total_revenue,
	ROUND(AVG(additional.marketing_costs), 2) as marketing_costs,
	ROUND(AVG(additional.purchase_price), 2) as purchase_price,
	ROUND(AVG(additional.avg_apple_revenue + additional.avg_play_revenue - additional.marketing_costs - additional.purchase_price), 2) as net_profit,
	apple.price
FROM apple_stats as astats INNER JOIN play_stats as pstats ON astats.name = pstats.name
											INNER JOIN app_store_apps as apple ON astats.name = apple.name
											INNER JOIN play_store_apps as play ON pstats.name = play.name
											INNER JOIN apurchase ON apurchase.name = apple.name
											INNER JOIN ppurchase ON ppurchase.name = play.name
											INNER JOIN additional ON additional.additional_name = apple.name
GROUP BY apple.price
ORDER BY net_profit desc;

