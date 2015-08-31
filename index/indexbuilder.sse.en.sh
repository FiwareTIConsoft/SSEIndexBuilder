# You are expected to run the commands in this script from inside the bin directory in your DBpedia Spotlight installation
# Adjust the paths here if you don't. This script is meant more as a step-by-step guidance than a real automated run-all.
# If this is your first time running the script, we advise you to copy/paste commands from here, closely watching the messages
# and the final output.
#
# BUILD INDEX GENERATION using pre-packaged index jar 
# 
# PREREQUISITE:
# You have to run maven package (maven-shade-plugin) from the module that contains the indexing classes 
# to obtain the pre-packaged JAR (index-06.jar) and transfer it to the target machine used to build index
# cd ../index
# mvn clean package

export DBPEDIA_WORKSPACE=/data/dbpedia-spotlight/dbpedia2014/en
export INDEX_CONFIG_FILE=/data/dbpedia-spotlight/conf/indexing.tmf.en.properties
export JAVA_XMX=16g

# clean redirect file: there is a bug in the DBpedia version 3.9 
#mvn compile

#mvn exec:java -e -Dexec.mainClass="org.dbpedia.spotlight.lucene.index.external.utils.SSERedirectCleaner" -Dexec.args=$INDEX_CONFIG_FILE > out_SSERedirectCleaner.log 2>&1
java -Xmx$JAVA_XMX -cp index-06.jar org.dbpedia.spotlight.lucene.index.external.utils.SSERedirectCleaner $INDEX_CONFIG_FILE > out_SSERedirectCleaner.log 2>&1

#clean the Wikipedia Dump 
#mvn compile
#mvn exec:java -e -Dexec.mainClass="org.dbpedia.spotlight.lucene.index.external.utils.SSEWikiDumpCleaner" -Dexec.args=$INDEX_CONFIG_FILE > out_SSEWikiDumpCleaner.log 2>&1 
java -Xmx$JAVA_XMX -cp index-06.jar org.dbpedia.spotlight.lucene.index.external.utils.SSEWikiDumpCleaner $INDEX_CONFIG_FILE > out_SSEWikiDumpCleaner.log 2>&1

# extract valid URIs, synonyms and surface forms from DBpedia
#mvn scala:run -Dlauncher=ExtractCandidateMap "-DjavaOpts.Xmx=16G" "-DaddArgs=$INDEX_CONFIG_FILE" > out_ExtractCandidateMap.log 2>&1
java -Xmx$JAVA_XMX -cp index-06.jar org.dbpedia.spotlight.util.ExtractCandidateMap $INDEX_CONFIG_FILE > out_ExtractCandidateMap.log 2>&1

# decode URIs of the extracted files 
#mvn compile
#mvn exec:java -e -Dexec.mainClass="org.dbpedia.spotlight.lucene.index.external.utils.SSEUriDecoder" -Dexec.args=$INDEX_CONFIG_FILE > out_SSEUriDecoder.log 2>&1
java -Xmx$JAVA_XMX -cp index-06.jar org.dbpedia.spotlight.lucene.index.external.utils.SSEUriDecoder $INDEX_CONFIG_FILE > out_SSEUriDecoder.log 2>&1

# now we collect parts of Wikipedia dump where DBpedia resources occur and output those occurrences as Tab-Separated-Values
#echo -e "Parsing Wikipedia dump to extract occurrences...\n"
#mvn scala:run -Dlauncher=ExtractOccsFromWikipedia "-DjavaOpts.Xmx=16G" "-DaddArgs=$INDEX_CONFIG_FILE|$DBPEDIA_WORKSPACE/output/occs.tsv" > out_ExtractOccsFromWikipedia.log 2>&1
java -Xmx$JAVA_XMX -cp index-06.jar org.dbpedia.spotlight.lucene.index.ExtractOccsFromWikipedia $INDEX_CONFIG_FILE $DBPEDIA_WORKSPACE/output/occs.tsv > out_ExtractOccsFromWikipedia.log 2>&1

# (recommended) sorting the occurrences by URI will speed up context merging during indexing
#echo -e "Sorting occurrences to speed up indexing...\n"
sort -t$'\t' -k2 $DBPEDIA_WORKSPACE/output/occs.tsv >$DBPEDIA_WORKSPACE/output/occs.uriSorted.tsv > out_sort_occs.log 2>&1 

#set -e
# create a lucene index out of the occurrences
#echo -e "Creating a context index from occs.tsv...\n"
#mvn scala:run -Dlauncher=IndexMergedOccurrences "-DjavaOpts.Xmx=16G" "-DaddArgs=$INDEX_CONFIG_FILE|$DBPEDIA_WORKSPACE/output/occs.uriSorted.tsv" > out_IndexMergedOccurrences.log 2>&1 
java -Xmx$JAVA_XMX -cp index-06.jar org.dbpedia.spotlight.lucene.index.IndexMergedOccurrences $INDEX_CONFIG_FILE $DBPEDIA_WORKSPACE/output/occs.uriSorted.tsv > out_IndexMergedOccurrences.log 2>&1

# (optional) make a backup copy of the index before you lose all the time you've put into this
#echo -e "Make a backup copy of the index..."
#cp -R $DBPEDIA_WORKSPACE/output/index $DBPEDIA_WORKSPACE/output/index-backup

# add entity types to index
#echo -e "Adding Types to index... \n";
#mvn scala:run -Dlauncher=AddTypesToIndex "-DjavaOpts.Xmx=$JAVA_XMX" "-DaddArgs=$INDEX_CONFIG_FILE|$DBPEDIA_WORKSPACE/output/index" > out_AddTypesToIndex.log 2>&1
java -Xmx$JAVA_XMX -cp index-06.jar org.dbpedia.spotlight.lucene.index.AddTypesToIndex $INDEX_CONFIG_FILE $DBPEDIA_WORKSPACE/output/index > out_AddTypesToIndex.log 2>&1

# add titles to index 
#echo -e "Adding Wikipedia Titles to index... \n"
#mvn scala:run -Dlauncher=AddTitlesToIndex "-DjavaOpts.Xmx=$JAVA_XMX" "-DaddArgs=$INDEX_CONFIG_FILE|$DBPEDIA_WORKSPACE/output/index-withTypes" > out_AddTitlesToIndex.log 2>&1
java -Xmx$JAVA_XMX -cp index-06.jar org.dbpedia.spotlight.lucene.index.external.AddTitlesToIndex $INDEX_CONFIG_FILE $DBPEDIA_WORKSPACE/output/index-withTypes > out_AddTitlesToIndex.log 2>&1

# add images to index 
#echo -e "Adding Images to index... \n"
#mvn scala:run -Dlauncher=AddImagesToIndex "-DjavaOpts.Xmx=$JAVA_XMX" "-DaddArgs=$INDEX_CONFIG_FILE|$DBPEDIA_WORKSPACE/output/index-withTypesTitles" > out_AddImagesToIndex.log 2>&1
java -Xmx$JAVA_XMX -cp index-06.jar org.dbpedia.spotlight.lucene.index.external.AddImagesToIndex $INDEX_CONFIG_FILE $DBPEDIA_WORKSPACE/output/index-withTypesTitles > out_AddImagesToIndex.log 2>&1

# create the Knowledge Base Index of SSE 
#echo -e "Create the Knowledge Base Index of SSE... \n"
#mvn compile
#mvn exec:java -e -Dexec.mainClass="org.dbpedia.spotlight.lucene.index.external.SSEKnowledgeBaseBuilder" -Dexec.args=$INDEX_CONFIG_FILE > out_SSEKnowledgeBaseBuilder.log 2>&1
java -Xmx$JAVA_XMX -cp index-06.jar org.dbpedia.spotlight.lucene.index.external.SSEKnowledgeBaseBuilder $INDEX_CONFIG_FILE > out_SSEKnowledgeBaseBuilder.log 2>&1

# create the Residual Knowledge Base Index of SSE
#echo -e "Create the Residual Knowledge Base Index of SSE... \n"
#mvn compile
#mvn exec:java -e -Dexec.mainClass="org.dbpedia.spotlight.lucene.index.external.SSEResidualKnowledgeBaseBuilder" -Dexec.args=$INDEX_CONFIG_FILE > out_SSEResidualKnowledgeBaseBuilder.log 2>&1
java -Xmx$JAVA_XMX -cp index-06.jar org.dbpedia.spotlight.lucene.index.external.SSEResidualKnowledgeBaseBuilder $INDEX_CONFIG_FILE > out_SSEResidualKnowledgeBaseBuilder.log 2>&1
