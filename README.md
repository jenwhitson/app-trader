## App Trader: Premise

Our team was hired by a fictional company called App Trader to help them explore and gain insights from apps that are made available through the Apple App Store and Android Play Store. App Trader is a broker that purchases the rights to apps from developers in order to market the apps and offer in-app purchase. App developers retain **all** money from users purchasing the app, and they retain _half_ of the money made from in-app purchases. App Trader is solely responsible for marketing apps they purchase rights to.  

Our team was instructed to make recommendations to App Trader on what apps to purchase based upon the following assumptions:

<blockquote>a. App Trader purchases apps for 10,000 times the price of the app. For apps that are priced from free up to $1.00, the purchase price is $10,000.

b. Apps earn $5000 per month on average from in-app advertising and in-app purchases _regardless_ of the price of the app.  

c. App Trader spends an average of $1000 per month to market an app _regardless_ of the price of the app. If App Trader owns rights to the app in both stores, it can market the app for both stores for a single cost of $1000 per month.  

d. For every half point that an app gains in rating, its projected lifespan increases by one year, in other words, an app with a rating of 0 can be expected to be in use for 1 year, an app with a rating of 1.0 can be expected to last 3 years, and an app with a rating of 4.0 can be expected to last 9 years. Ratings should be rounded to the nearest 0.5 to evaluate an app's likely longevity.  

e. App Trader would prefer to work with apps that are available in both the App Store and the Play Store since they can market both for the same $1000 per month.</blockquote>

Additionally, we were asked to advise if there were any trends we could recognize based on app price, content rating, genre, or any other factor that may guide App Trader in making their purchases.

Lastly, this was a group project. However, the analysis, visuals, and PowerPoint presentation in this repository were all created by me. 

## Analysis
Analysis was completed exclusively in SQL using 2 datasets: apple store data and play store data. There were a number of issues to work through, as each app store has its own ratings, price, genre and content rating. 

My first step was to determine which apps were present in both app stores, as I assumed these would be most profitable. After some quick experimentation, I determined that trying to filter in broad strokes (e.g., only free apps with 5 star ratings present in both app stores) would not give me the most accurate results, primarily because no apps fit this criteria, and when you try to broaden it at all (e.g., lowering the star rating threshold to 4.5), you would get too many results. 

I decided to simply calculate the total revenue per app and then sort them from highest to lowest profit. This involved quite a bit of arithmetic and some more complex code, but once I had this done, I could pivot to look at genres, content ratings, price, etc., to see hard numbers for which apps created the most profits. 

Once analysis was complete, I exported the data to csv files to be visualized using Excel. Finally, I compiled all of my visualizations and conclusions into a PowerPoint presentation. 

## How to View this Repository

My SQL code is viewable in the Scripts folder. 

To see the completed PowerPoint presentation with all visuals, you can download the Presentation.pptx file and view in PowerPoint.