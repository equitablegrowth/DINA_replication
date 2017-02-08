* put the variables you want to analyze here, after ds
ds fainc
local varl r(varlist)

* loop through variables
foreach var in `varl'{
	* split income equally between spouses and weight
	egen equal=mean(``var''),by(year id)
	gen equal_weighted=equal*dweght

* loop through variables
foreach var in `varl'{
	display "---------",`var',"---------"

	* loop through all years in the dataset
	levelsof year, local(years)
	foreach y of local years{
		* get percentiles of equal weighted by dweght
		cap: summarize equal [aweight=dweght] if year==`y',detail
		local p50 r(p50)
		local p90 r(p90)

		* generate a new variable used for storing the group each row is in (low/middle/high income)
		gen equal_rank=0
		cap: replace equal_rank=1 if equal>`p50'
		cap: replace equal_rank=2 if equal>`p90'

		* get sum of equal_weighted for each group
		cap: sum equal_weighted if year==`y' & equal_rank==0
		local bottom_total `r(sum)'
		cap: sum equal_weighted if year==`y' & equal_rank==1
		local middle_total `r(sum)'
		cap: sum equal_weighted if year==`y' & equal_rank==2
		local top_total `r(sum)'

		* display
		display `y',(100*`bottom_total'/(`bottom_total'+`middle_total'+`top_total')),(100*`middle_total'/(`bottom_total'+`middle_total'+`top_total')),(100*`top_total'/(`bottom_total'+`middle_total'+`top_total'))
		drop equal_rank
	}
	drop equal_weighted
	drop equal
}