* load data
import delimited /path/to/file.csv

* list of vars to summarize
local varl "ptinc"

* split income equally between spouses
foreach var in `varl'{
	egen equal_`var'=mean(`var'),by(year id)
	gen equal_`var'_weighted=equal_`var'*dweght
}


* create new variables to group observations by category: bottom 50, middle 40, and top 10
foreach var in `varl'{
	* loop through all years in the dataset
	levelsof year, local(years)
	gen equal_`var'_rank=0
	foreach y of local years{
		* get percentiles of equal weighted by dweght
		cap: summarize equal_`var' [aweight=dweght] if year==`y',detail
		local p50 r(p50)
		local p90 r(p90)

		* generate a new variable used for storing the group each row is in (low/middle/high income)
		cap: replace equal_`var'_rank=1 if equal_`var'>`p50' & year==`y'
		cap: replace equal_`var'_rank=2 if equal_`var'>`p90' & year==`y'
	}
}

* sum income for each group and present as % of total
foreach var in `varl'{
	display "---------",`var',"---------"
	* loop through all years in the dataset
	levelsof year, local(years)
	foreach y of local years{
		* get sum of equal_weighted for each group
		cap: sum equal_`var'_weighted if year==`y' & equal_`var'_rank==0
		local bottom_total `r(sum)'
		cap: sum equal_`var'_weighted if year==`y' & equal_`var'_rank==1
		local middle_total `r(sum)'
		cap: sum equal_`var'_weighted if year==`y' & equal_`var'_rank==2
		local top_total `r(sum)'

		display `y',(100*`bottom_total'/(`bottom_total'+`middle_total'+`top_total')),(100*`middle_total'/(`bottom_total'+`middle_total'+`top_total')),(100*`top_total'/(`bottom_total'+`middle_total'+`top_total'))
	}
}