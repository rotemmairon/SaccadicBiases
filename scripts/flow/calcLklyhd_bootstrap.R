library(dplyr)
library(ggplot2)
library(Matrix)
library(matrixcalc)

# sample n saccades 
		N = 1000 # for bootstrapping
		n_Rep = 100


source('flowDistFunctions.R')

makeLLHfig <- function(datasets, nr)
{
	LLHresults = data.frame(
		dataset=character(),
		biasmodel=character(),
		logLik=numeric(),
		deltaLogLik=numeric())

	for (d in datasets)
	{
		print(d)

		if (d == 'Asher2013')
		{
			asp.rat = 0.80
		} else 	{
			asp.rat = 0.75
		}

		# get saccade info
		saccades = read.csv(paste('../../data/saccs/', d, 'saccs.txt', sep=''), header=FALSE)

		# First transform fixations
		# saccades[,5:6] = unboundTransform(saccades[,3:4])
		names(saccades) = c("n", "x1", "y1", "x2", "y2")

		saccades = filter(saccades, x2>-1, y2>-asp.rat, x2<1, y2<asp.rat)
		saccades = filter(saccades, x1>-1, y1>-asp.rat, x1<1, y1<asp.rat)
		saccades = filter(saccades, n>1)

		for (kk in 1:n_Rep)
		{
			saccades_samples = saccades[sample(nrow(saccades), N),]

			######################################################################################
			# first caculate log-likelihood of dataset given Clarke-Tatler 2014 central bias
			# also use best fit gaussian, and use uniform as baseline
			#####################################################################################

			fixs = select(saccades_samples, x2, y2)

			uniformLLH = nrow(fixs)  * log(1/(4*asp.rat))

			# LLHresults = rbind(LLHresults, 
			# 	data.frame(
			# 		dataset=d, 
			# 		biasmodel='uniform', 
			# 		logLik=uniformLLH,
			# 		deltaLogLik=0))

			# CT2014
			mu = c(0,0)
			sigma = array(c(0.22,0,0,0.45*0.22), dim=c(2,2))
			llh = sum(dmvnorm(fixs, mu, sigma, log=T))

			LLHresults = rbind(LLHresults, data.frame(
				dataset=d, 
				biasmodel='CT2014', 
				logLik = llh,
				deltaLogLik = llh-uniformLLH))
			rm(llh, mu, sigma)

			# CT2017
			mu = c(0,0)
			sigma = array(c(0.32,0,0,0.45*0.32), dim=c(2,2))
			llh = sum(dtmvnorm(cbind(fixs$x2, fixs$y2), mu, sigma,
				lower=c(-1,-asp.rat),
				upper=c(1,asp.rat), log=T))

			LLHresults = rbind(LLHresults, data.frame(
				dataset=d, 
				biasmodel='CT2017', 
				logLik = llh,
				deltaLogLik = llh-uniformLLH))
			rm(llh, mu, sigma)

			
			######################################################################################
			# now find out how much flow helps!
			#####################################################################################
		 
			trainedOn = 'All'
			flowModel = 'tN'

			saccades_samples = calcLLHofSaccades(saccades_samples, flowModel, trainedOn, asp.rat)
			llh = sum(saccades_samples$llh)
			LLHresults = rbind(LLHresults, data.frame(
				dataset=d, 
				biasmodel = "Flow", 		
				logLik=sum(saccades_samples$llh),
				deltaLogLik = sum(saccades_samples$llh)-uniformLLH))
		}
	}

	# aggregate over bootstraps
	LLHresults2 = (LLHresults 
		%>% group_by(dataset, biasmodel) 
		%>%	summarise(
			meanLLH = mean(deltaLogLik),
			stddev = sd(deltaLogLik),
			stderr = sd(deltaLogLik)/sqrt(n_Rep),
			upper = meanLLH+1.96*stderr,
			lower = meanLLH-1.96*stderr))	


	plt  = ggplot(LLHresults2, aes(y=meanLLH, x=biasmodel, ymin=lower, ymax=upper))
	plt = plt + geom_point() + geom_errorbar()
	plt = plt + facet_wrap(~dataset, nrow=nr)
	plt = plt + scale_fill_brewer(palette="Set2") + theme_bw()
    plt = plt + scale_y_continuous(name= 'log likelihood ratio')
	plt = plt + scale_x_discrete(name='bias model')
	plt = plt + geom_hline(yintercept=0)
	# plt = plt + guides(fill=guide_legend(title="bias model"))

	return(plt)

} 


datasets = c(
'Clarke2013', 
'Einhauser2008',
'Tatler2005', 
'Tatler2007freeview', 
'Tatler2007search',
'Judd2009', 
'Yun2013SUN',
 'Yun2013PASCAL') #


plt = makeLLHfig(datasets,4)
ggsave(paste('figs/llh_Training.pdf', sep=''), width=6, height=9)



datasets = c(
	'Jiang2014',
 'Clarke2009',
 'Asher2013',
 'Ehinger2007') #

plt = makeLLHfig(datasets, 2)
ggsave(paste('figs/llh_Testing.pdf', sep=''), width=6, height=4.5)






