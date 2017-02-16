# load necessary libraries/data
from __future__ import division
import pandas as pd

df=pd.read_csv('/path/to/file.csv')

# list of vars to summarize
vars=['ptinc']

# split income equally between spouses
for var in vars:
	splitname=var+'_split'
	df[splitname]=df.groupby(['year','id'])[var].transform('mean')

# functions to take care of weighted percentiles
def weighted_cuts(df,var,weight,perc=[.25,.5,.75]):
	sep=[float('inf')]
	a=df[[var,weight]]
	a=a.sort_values(var)
	b=list(a[weight].cumsum())
	totalpop=a[weight].sum()
	cuts=[per*totalpop for per in perc]
	prevvalue=0
	for i,x in enumerate(b):
		for cut in cuts:
			if prevvalue<=cut and x>cut:
				sep.append((a.iloc[i][var]+a.iloc[i-1][var])/2)
		prevvalue=x
	sep.append(float('inf'))
	return sep

def assign_sters(value,sters):
	if value<=sters[1]:
		return 0
	if value<=sters[2]:
		return 1
	return 2

# create new variables to group observations by category: bottom 50, middle 40, and top 10
for var in vars:
	newname=var+'_q'
	splitname=var+'_split'
	df[newname]=-1
	sterdict={}
	for year in list(set(df.year)):
		sters=weighted_cuts(df[df['year']==year],splitname,'dweght',[.5,.9])
		sterdict[year]=sters
	df[newname]=df.apply(lambda row:assign_sters(row[splitname],sterdict[row['year']]),axis=1)

# sum income for each group and present as % of total
for var in vars:
	newname=var+'_q'
	weghtvar=var+'_weght'
	splitname=var+'_split'
	df[weghtvar]=df[splitname]*df['dweght']
	holder=df.groupby(['year',newname])[weghtvar].sum()
	print "NEW VAR: "+var
	print 'year,bottom50percent,mid40percent,top10percent'
	for year in range(1962,2011):
		if year!=1963 and year!=1965:
			total=holder[year][0]+holder[year][1]+holder[year][2]
			print str(year)+','+str(holder[year][0]/total)+','+str(holder[year][1]/total)+','+str(holder[year][2]/total)

