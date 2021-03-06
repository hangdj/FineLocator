#!/bin/bash
deeplearning4jdir=$1
qedir=$2
PYTHON=$3
proj_id=$4
brAfterPTDir=$5
codeAfterPTDir=$6
correspondAfterPTDir=$7
brTfidfDir=$8
codeTfidfDir=$9
brVecDir=${10}
codeVecDir=${11}
dim=${12}
epochs=${13}

function tfidf(){
    rm -f ${brTfidfDir}/${proj_id}
    mkdir -p ${brTfidfDir}

    rm -rf ${codeTfidfDir}/${proj_id} 
    mkdir -p ${codeTfidfDir}/${proj_id}

    ${PYTHON} tfidf.py -br ${brAfterPTDir}/${proj_id} \
                       -co ${codeAfterPTDir}/${proj_id} \
                       -cr ${correspondAfterPTDir}/${proj_id} \
                       -bs ${brTfidfDir}/${proj_id} \
                       -cs ${codeTfidfDir}/${proj_id}
}


function runWord2Vec(){
    rm -rf ${brVecDir}/${proj_id}
    rm -rf ${codeVecDir}/${proj_id} 
    mkdir -p ${codeVecDir}/${proj_id}
    
    model_name=${proj_id}_${epochs}_${dim}
    echo "train word2vec model.. ${model_name}"

    # for convenience, copy bug report files to code dir to pack input for training model.
    # after training, bug reports must be deleted, or will be exported as vector when running next step.
    
    copyBrBeforeFit 
    java -cp word2vec.jar App -name ${model_name} -source ${codeAfterPTDir}/${proj_id} -fit 1 -dim ${dim} -epochs ${epochs} -type type   # whatever type
    clearTmpDir
    echo "train word2vec model finished."
    

    echo "export br vector..."
    java -cp word2vec.jar App -name ${model_name} -source ${brAfterPTDir}/${proj_id}  -dim ${dim} \
         -target ${brVecDir}/${proj_id}  -tfidf ${brTfidfDir}/${proj_id}  -type br
    echo "export br vector finished."

    echo "export code vector..."
    java -cp word2vec.jar App -name ${model_name} -source ${codeAfterPTDir}/${proj_id} \
         -correspond ${correspondAfterPTDir}/${proj_id} -dim ${dim} \
         -target ${codeVecDir}/${proj_id} -tfidf ${codeTfidfDir}/${proj_id} -type code
    echo "export code vector finished."
} 


function copyBrBeforeFit(){
	array=($(ls ${brAfterPTDir} | sort -t "_" -k 2n))
	for ((i=0;i<${#array[*]};i++))
    do
        if [[ "${array[i]}" == "${proj_id}" ]]; then 
    	    rm   -rf ${codeAfterPTDir}/${proj_id}/tmp
            mkdir -p ${codeAfterPTDir}/${proj_id}/tmp
            for ((j=0;j<=$i;j++))
            do
                cp ${brAfterPTDir}/${array[j]} ${codeAfterPTDir}/${proj_id}/tmp
            done
            break
        fi
    done
}

function clearTmpDir(){
	rm -rf ${codeAfterPTDir}/${proj_id}/tmp
}


cd ${qedir}
tfidf
cd ${deeplearning4jdir}
runWord2Vec

rm ${model_name}


