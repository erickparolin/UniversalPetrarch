#!/bin/bash

FILENAME=$1
language=$2

SCRIPT=../scripts
# FILEPATH=../data/text
FILEPATH=../data/text
STANFORD_SEG=./segmenter
CLASSPATH=$STANFORD_SEG/stanford-segmenter-3.6.0.jar:$STANFORD_SEG/slf4j-api.jar
STANFORD_CORENLP=./stanford-corenlp-full-2018-01-31
udpipePath=./udpipe-1.2.0-bin/bin-osx



if [ "$language" = "AR" ] 
then
	languageModel=${udpipePath}/model/arabic-ud-2.0-170801.udpipe
	STANFORD_PROPERTY=config/StanfordCoreNLP-arabic.properties


	echo "Generate sentence xml file..."
	python3 preprocess_sent.py ${FILEPATH}/$FILENAME

	echo "Call Stanford Segmenter to do arabic word segmentation.."
	java -mx1g -cp $CLASSPATH edu.stanford.nlp.international.arabic.process.ArabicSegmenter -loadClassifier $STANFORD_SEG/data/arabic-segmenter-atb+bn+arztrain.ser.gz -textFile ${FILEPATH}/$FILENAME.raw.txt > ${FILEPATH}/$FILENAME.segmented 
	

	${SCRIPT}/create_conll_corpus_from_text.pl ${FILEPATH}/$FILENAME.segmented > ${FILEPATH}/$FILENAME.conll

	rm ${FILEPATH}/$FILENAME.segmented

else

	if [ "$language" = "ES" ] 
	then
		languageModel=${udpipePath}/model/spanish-ud-1.2-160523.udpipe
		STANFORD_PROPERTY=config/StanfordCoreNLP-spanish.properties

	elif [ "$language" = "EN" ]
	then
		languageModel=${udpipePath}/model/english-ud-1.2-160523.udpipe
		STANFORD_PROPERTY=config/StanfordCoreNLP-english.properties

	fi


	echo "Prepare file for stanford CoreNLP"
	python3 preprocess_sent.py ${FILEPATH}/$FILENAME

	echo "Call Stanford CoreNLP to do tokenization..."
	echo "property file path: "
	echo $STANFORD_PROPERTY
	java -cp "$STANFORD_CORENLP/*" -Xmx4g edu.stanford.nlp.pipeline.StanfordCoreNLP -props ${STANFORD_PROPERTY} -ssplit.newlineIsSentenceBreak always -file ${FILEPATH}/$FILENAME.raw.txt -outputFormat text -outputDirectory ${FILEPATH}

	echo "Generate sentence xml file..."
	python3 preprocess.py ${FILEPATH}/$FILENAME

	${SCRIPT}/create_conll_corpus_from_text.pl ${FILEPATH}/$FILENAME.txt > ${FILEPATH}/$FILENAME.conll

	rm ${FILEPATH}/$FILENAME.raw.txt.out
	rm ${FILEPATH}/$FILENAME.txt

fi


echo "Call udpipe to do pos tagging and dependency parsing..."
echo "Udpipe model path: "
echo $languageModel
${udpipePath}/udpipe --tag --parse --outfile=${FILEPATH}/$FILENAME.conll.predpos.pred --input=conllu $languageModel ${FILEPATH}/$FILENAME.conll 

echo "Ouput parsed xml file..."
python3 generateParsedFile.py ${FILEPATH}/$FILENAME "$language"

rm ${FILEPATH}/$FILENAME.raw.txt
rm ${FILEPATH}/$FILENAME.conll
rm ${FILEPATH}/$FILENAME.conll.predpos.pred

