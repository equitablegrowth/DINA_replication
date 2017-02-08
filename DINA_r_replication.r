# load necessary libraries/install packages
library(foreign)
install.packages("devtools")
devtools::install_github("hadley/bigvis")
library(bigvis)

df<-read.csv(file.choose())

# list of vars to summarize
vars=c('fninc')

# split income equally between spouses
for(var in vars){
	df[[paste(var,'_split',sep='')]] <- ave(df[[var]], df$year, df$id, FUN=mean)
}

# create new variables to group observations by category: bottom 50, middle 40, and top 10
for(var in vars){
	q_vector=c()
	for(y in list(set(df['year']))){
		temp=subset(df,year==y)
		q_vector=c(q_vector,cut(temp[[paste(var,'_split',sep='')]],c(-Inf,weighted.quantile(temp[[paste(var,'_split',sep='')]], temp$dweght, probs=c(.5,.9)),Inf),labels=c(0,1,2)))
	}
	df[[paste(var,'_q',sep='')]]<-q_vector
	df[[paste(var,'_weght',sep='')]]<-df[[paste(var,'_split',sep='')]]*df$dweght
}

# print results
for(var in vars){
	varweght=paste(var,'_weght',sep='')
	varq=paste(var,'_q',sep='')
	print(varq)
	for(y in list(set(df['year']))){
		temp=df[df[,'year']==y,]
		q1total=sum(temp[temp[[varq]]==1,][[varweght]])
		q2total=sum(temp[temp[[varq]]==2,][[varweght]])
		q3total=sum(temp[temp[[varq]]==3,][[varweght]])
		total=q1total+q2total+q3total
		print('year,bottom50percent,mid40percent,top10percent')
		print(paste(y,q1total/total,q2total/total,q3total/total,sep=','))
	}
}
