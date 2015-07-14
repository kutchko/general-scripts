#rm(list=ls())

args = commandArgs(trailingOnly=TRUE)
tableFile = args[1]
cutoff = args[2]


## FUNCTIONS
normalize = function(data,valid) {
	raw_data = data[valid]
	N = length(raw_data)
	sorted_raw_data = sort(raw_data, decreasing=TRUE)
	percent = N/100
	top_2 = round(percent*2)
	top_10 = round(percent*10)
	message(paste('length:',N))
	if (top_2 != top_10) {
		norm.factor = mean(sorted_raw_data[(top_2+1):top_10])
		message(paste('range:',top_2+1,'-',top_10))
	} else {
		norm.factor = mean(sorted_raw_data[top_2:top_10])
		message(paste('range:',top_2,'-',top_10))
	}
	message(paste('factor:',norm.factor))
	norm.data = data/norm.factor
	norm.data[! valid] = -999
	
	return(norm.data)
}


scale.bg = function(rx, bg, valid, name='', name2='') {
        bg.mean = mean(bg[! valid])
        rx.mean = mean(rx[! valid])
        scale.factor = rx.mean/bg.mean
        message(paste("Multiplying BG by factor",scale.factor))
        
        bg.scaled = bg*scale.factor
        
        plot(rx,type='l',col='deepskyblue',main=paste('Scaled BG:',name,'-',name2))
        lines(bg,col='pink')
        lines(bg.scaled,col='darkred')
        points(which(! valid),bg.scaled[! valid],col='darkred',pch=8)
        legend('topright',c('RX','BG [unscaled]','BG [scaled]'),fill=c('deepskyblue','pink','darkred'))
        
        return(bg.scaled)
}



rep.col = function(x,n) {
	return(matrix(rep(x,each=n),ncol=n,byrow=TRUE))
}

## create output directory
dir.create("SHAPE_plots", showWarnings=FALSE)
dir.create("SHAPE_files", showWarnings=FALSE)

## PLOT SHAPE RESULTS

table = read.delim(tableFile)

labels = c('A','B','C','D','E','F','G','H')
colorList = c('darkred', 'navyblue', 'orange', 'forestgreen', 'orchid', 'steelblue', 'yellowgreen', 'orangered')

# plot wildtype rxn
rx = table[,seq(1, ncol(table)-1, 2)]
bg = wt[,seq(2, ncol(table), 2)]
pdf(width=12,height=7,file='raw_data.pdf')
plot(rx[,1],type='n',ylim=c(0,max(rx)),xlab='Position',ylab='AreaRX',main='Reaction')

for (i in 1:ncol(wt.rx)) {
	points(wt.rx[i],type='l',col=colorList[i])
}
legend('topleft',labels[1:ncol(rx)],fill=colorList,bty='n')

# plot wildtype BG
plot(bg[,1],type='n',ylim=c(0,max(bg)),xlab='Position',ylab='AreaBG',main='Background')

for (i in 1:ncol(bg)) {
	points(bg[i],type='l',col=colorList[i])
	#abline(0.40*max(wt.bg[i]),0,col=colorList[i])
}
legend('topleft',labels[1:ncol(bg)],fill=colorList,bty='n')
dev.off()



## defining high backgrounds

plot_background = function(shape_vals,title='') {
	plot(shape_vals,type='l',xlab='Position',ylab='area.BG',main=title)
	abline(0.5*max(shape_vals),0,col='firebrick')
	abline(0.4*max(shape_vals),0,col='darkorange')
	abline(0.3*max(shape_vals),0,col='gold')
	#abline(less_than_six_percent(shape_vals),0,col='orange')
}

plot_pruned = function(shape_vals,valid,title='') {
	xind = 1:length(shape_vals)
	yind = shape_vals
	yind[! valid] = 0
	plot(xind, yind, ylim=c(min(shape_vals[valid]),max(shape_vals)), type='l', main=title, xlab='Position', ylab='SHAPE')
	invalid = which(valid==FALSE)
	points(invalid,rep(0,length(invalid)),pch=8,col='green')
}


#### FIND CORRELATIONS
library(reshape)


### FINAL NORMALIZATION SCHEMA

# remove least-correlated background
bgSums = mapply(colSums, cor(bg), SIMPLIFY=FALSE)
leastCor = which.min(bgSums)
print(bgSums)
print(leastCor)

# determine the cutoff (% of max background) when defining high-background nucleotides
test_cutoff = function(bg.avg, cutoff, name='') {
    valid = bg.avg < cutoff*max(bg.avg)
    print(count(valid))
    print(which(valid==FALSE))
    plot_pruned(bg.avg,valid,title=paste(name,'BG + removal'))
    return(valid)
}

bg.avg = rowMeans(bg)

pdf('SHAPE_plots/background.pdf')
plot_background(rowMeans(bg),title='Mean BG')
valid = test_cutoff(bg.avg, cutoff, name=tableFile)

dev.off()


# remove least correlated RX
rxSums = mapply(colSums, cor(rx), SIMPLIFY=FALSE)
leastCorRx = lapply(rxSums,which.min)


# scale the background
pdf('SHAPE_plots/scaled_plots.pdf',height=7,width=12)
scale.wrapper = function(rx, bg.avg, valid, mutName) {
    bg.scaled = sapply(colnames(rx), function(x){scale.bg(rx[,x], bg.avg, valid, name=mutName, name2=x)})
    #bg.scaled = apply(rx, 2, scale.bg, bg.avg, valid, name=mutName)
}
scaled.background = scale.wrapper(rx, bg.avg, valid, tableFile)
dev.off()


# normalize RX-BG
pdf('SHAPE_plots/normalized_SHAPE.pdf',height=7,width=12)
rxbg = rx - scaled.background


norm.wrapper = function(rxbg, valid) {
    apply(rxbg,2,normalize,valid)
}
normed.rxbg = norm.wrapper(rxbg, valid)
lapply(names(normed.rxbg), function(x){boxplot(normed.rxbg[[x]][valid[[x]],],main=toupper(x))})

plotShape = function(shape, valid, name='') {
    shape[! valid,] = 0
    matplot(shape, type='l', col=colorList, lty=1, main=paste('Normalized SHAPE:',name),
            xlab='Position',ylab='Normalized SHAPE')
    points(which(! valid), shape[! valid,1], pch=8, col='green')
    legend('topright',colnames(shape),fill=colorList[1:ncol(shape)],bty='n')
}
mapply(plotShape, normed.rxbg, valid, tableData)
dev.off()

# only write to files that have a directory made
for (i in 1:length(nameList)) {
    shape = data.frame(nt=1:nrow(normed.rxbg[[i]]),rowMeans(normed.rxbg[[i]]))
    name = nameList[[i]]
    if (file.exists(paste('RX-BG_final/',name,sep='')))
    {
        write.table(shape, file=paste('RX-BG_final/',name,'/RB1_',name,'_RX-BG_final.shape',sep=''),
                    sep="\t", row.names=FALSE, col.names=FALSE)
        write.table(normed.rxbg[[i]],file=paste('RX-BG_final/normalization/',
                    name,'_normalized_data.txt',sep=''),
                    sep="\t", row.names=FALSE, col.names=TRUE, quote=FALSE)
    }
}

#write.table(wt.rxbg.shape,file='RX-BG_final/WT/RB1_WT_RX-BG_final.shape',sep="\t",row.names=FALSE,col.names=FALSE)




