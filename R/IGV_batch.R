suppressMessages(library("tidyverse"))
suppressMessages(library("reshape2"))
suppressMessages(library("stringr"))


##### SCRIPT READS IN TWO FILES ###################################
# 1. MUTATION MATRIX- (ANNOVAR annotated in this case but could be anything with following fields)
#     - ESSENTIAL- CHROM, POS, 
#     - OPTIONAL- FAMILY (for each family load bams together)- IF ABSENT- MODIFY SCRIPT TO GET RID OF FAMILY LOOPS
#               - Gene.refGene, ExonicFunc.refGene (for naming output file)
# 2. PED FILE- 2 columns, 1 with Family.ID, 2nd with Sample.ID
#     - Script loops over each family to 
#           - load all bams for all individuals and
#           - then to go to each variant position and save a snapshot
# 
###################################################################

## Variables
snapshotDir = "PATH_TO_SAVE_IMAGES"
bam_path1="PATH_TO_BAM_DIRECTORY"
bam_path2="PATH_TO_BAM_SUBDIRECTORY_WITHIN_SAMPLE_DIR"
genome= "hg38"

## READ BOTH INPUT FILES
setwd("")
mutation_fn <- "NAME OF MUTATION FILE"
variant_table<- read.table(mutation_fn, header=TRUE,sep = "\t")
ped_fn <- "NAME OF PEDIGREE FILE"
ped <- read.table(ped_fn, header=TRUE, sep="\t")

## CREATE IGV BATCH SCRIPT
text <- paste0("new\ngenome ",genome,"\nsnapshotDirectory ",snapshotDir, "\nmaxPanelHeight 200\n")

for (family in unique(ped$Family.ID)){
  if(family %in% variant_table$Family){
    text<- paste0(text,"new\n")
    variant_table_family <- variant_table %>% filter(Family ==family)
    
    ## Load BAM Files for Family
    ped_family <- ped %>% filter(Family.ID==family)
    for (row in 1:nrow(ped_family)) {
      bamID <- gsub("(.*_.{2})\\..*","\\1",ped_family[row,"Sample.ID"])
      text <- paste0(text,"load ",bam_path1,bamID,bam_path2,bamID,".bam\n")
      }
    
    # Loop over mutations
    for (row in 1:nrow(variant_table_family)) {
      snapshotName <- paste0(variant_table_family[row,]$Family,"_",variant_table_family[row,]$Gene.refGene,"_",variant_table_family[row,]$ExonicFunc.refGene,
                             "_",variant_table_family[row,]$CHROM,"-",variant_table_family[row,]$POS,"-",variant_table_family[row,]$POS,".png")
      text <- paste0(text,"goto ",variant_table_family[row,]$CHROM,":",variant_table_family[row,]$POS,"-",variant_table_family[row,]$POS,
                     "\nsort position\ncollapse\nsnapshot ",snapshotName,"\n")
      }
    }
  }

writeLines(text,"igv_batch.sh")
