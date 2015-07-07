# sortable

##Caveats:

1. If a certain manufacturer, say, makes accessories for another company's products, and the former's name is part of the other's name, this algorithm will fail.
I did not find this case throughout the supplised products + listings, so I assumed it is safe to do so.
2. Some product model names are only numbers like "600". This causes some listings to fail when this number is used for another purpose (e.g., 600mm)
3. Some model names are strange, creating either false negatives or false positives (e.g., zoom)

##Assumptions:

1. Partial manufacturer names like "Minolta" instead of "Konica Minolta" or "Fuji" instead of "Fujifilm" are deliberately dropped even if the family and model names match.
Even if the family and model names match, that's no proof that we are referring to the same company.
2. Exception to (1) is when the full manufacturer name exists in the listing's title.
3. If the manufacturer full name exists in the listing's title, but with a different manufacturer name, this is deliberately dropped.
Reason: Some company that sells an accessory for a certain product (full manufacturer name + model). This is not a match.
=> Favoring false negatives over false positives.
4. A model name "A70D" for instance is a match to a product with model name "A70".
A quick online search revealed that this is the case (for products that I have checked).

##Running instructions:
1. Clone directory
2. Place "products.txt" and "listings.txt" in the input folder
3. Run "run.sh"
4. Check the results in "output/results.txt"

