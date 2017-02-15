* put the variables you want to analyze here, after ds
ds fninc
local varl r(varlist)

* loop through variables
foreach var in `varl'{
	* split income equally between spouses and weight
	egen equal_``var''=mean(``var''),by(year id)
	gen equal_``var''_weighted=equal_``var''*dweght
}

* create columns with decile ranks for each variable within the year
foreach var in `varl'{
	* loop through all years in the dataset
	levelsof year, local(years)
	gen equal_``var''_rank=0
	foreach y of local years{
		* get percentiles of equal weighted by dweght
		cap: summarize equal_``var'' [aweight=dweght] if year==`y',detail
		local p50 r(p50)
		local p90 r(p90)

		* generate a new variable used for storing the group each row is in (low/middle/high income)
		cap: replace equal_``var''_rank=1 if equal_``var''>`p50' & year==`y'
		cap: replace equal_``var''_rank=2 if equal_``var''>`p90' & year==`y'
	}
}


foreach var in `varl'{
	display "---------",`var',"---------"
	* loop through all years in the dataset
	levelsof year, local(years)
	foreach y of local years{
		* get sum of equal_weighted for each group
		cap: sum equal_``var''_weighted if year==`y' & equal_``var''_rank==0
		local bottom_total `r(sum)'
		cap: sum equal_``var''_weighted if year==`y' & equal_``var''_rank==1
		local middle_total `r(sum)'
		cap: sum equal_``var''_weighted if year==`y' & equal_``var''_rank==2
		local top_total `r(sum)'

		* display
		display `y',(100*`bottom_total'/(`bottom_total'+`middle_total'+`top_total')),(100*`middle_total'/(`bottom_total'+`middle_total'+`top_total')),(100*`top_total'/(`bottom_total'+`middle_total'+`top_total'))
		drop equal_rank
	}
}