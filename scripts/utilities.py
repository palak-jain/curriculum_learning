import codecs, sys, re, gzip  
from indicnlp.syllable import syllabifier as syll
from indicnlp.morph import unsupervised_morph as imorph
from indicnlp import loader
from indicnlp.script import indic_scripts as isc
from indicnlp.transliterate.unicode_transliterate import UnicodeIndicTransliterator as uit

import numpy as np
from scipy.misc.common import logsumexp
import itertools as it
import random
import morfessor 


def ned(srcw,tgtw,slang,tlang,w_del=1.0,w_ins=1.0,w_sub=1.0):
    score_mat=np.zeros((len(srcw)+1,len(tgtw)+1))

    score_mat[:,0]=np.array([si*w_del for si in xrange(score_mat.shape[0])])
    score_mat[0,:]=np.array([ti*w_ins for ti in xrange(score_mat.shape[1])])

    for si,sc in enumerate(srcw,1): 
        for ti,tc in enumerate(tgtw,1): 
            so=isc.get_offset(sc,slang)
            to=isc.get_offset(tc,tlang)
            if isc.in_coordinated_range_offset(so) and isc.in_coordinated_range_offset(to) and so==to: 
                score_mat[si,ti]=score_mat[si-1,ti-1]
            elif not (isc.in_coordinated_range_offset(so) or isc.in_coordinated_range_offset(to)) and sc==tc: 
                score_mat[si,ti]=score_mat[si-1,ti-1]
            else: 
                score_mat[si,ti]= min(
                    score_mat[si-1,ti-1]+w_sub,
                    score_mat[si,ti-1]+w_ins,
                    score_mat[si-1,ti]+w_del,
                )
    return (score_mat[-1,-1],float(len(srcw)),float(len(tgtw)))

def lcsr_indic(srcw,tgtw,slang,tlang):
    score_mat=np.zeros((len(srcw)+1,len(tgtw)+1))

    for si,sc in enumerate(srcw,1): 
        for ti,tc in enumerate(tgtw,1): 
            so=isc.get_offset(sc,slang)
            to=isc.get_offset(tc,tlang)

            if isc.in_coordinated_range_offset(so) and isc.in_coordinated_range_offset(to) and so==to: 
                score_mat[si,ti]=score_mat[si-1,ti-1]+1.0
            elif not (isc.in_coordinated_range_offset(so) or isc.in_coordinated_range_offset(to)) and sc==tc: 
                score_mat[si,ti]=score_mat[si-1,ti-1]+1.0
            else: 
                score_mat[si,ti]= max(
                    score_mat[si,ti-1],
                    score_mat[si-1,ti])

    return (score_mat[-1,-1]/float(max(len(srcw),len(tgtw))),float(len(srcw)),float(len(tgtw)))

def lcsr_any(srcw,tgtw,slang,tlang):
    score_mat=np.zeros((len(srcw)+1,len(tgtw)+1))

    for si,sc in enumerate(srcw,1): 
        for ti,tc in enumerate(tgtw,1): 

            if sc==tc: 
                score_mat[si,ti]=score_mat[si-1,ti-1]+1.0
            else: 
                score_mat[si,ti]= max(
                    score_mat[si,ti-1],
                    score_mat[si-1,ti])

    return (score_mat[-1,-1]/float(max(len(srcw),len(tgtw))),float(len(srcw)),float(len(tgtw)))

def lcsr(srcw,tgtw,slang,tlang):

    if slang==tlang or not isc.is_supported_language(slang) or not isc.is_supported_language(tlang):
        return lcsr_any(srcw,tgtw,slang,tlang)
    else:  
        return lcsr_indic(srcw,tgtw,slang,tlang)

def iterate_parallel_corpus(src_fname,tgt_fname):
    with codecs.open(src_fname,'r','utf-8') as src_file,\
         codecs.open(tgt_fname,'r','utf-8') as tgt_file:

        for sline, tline in it.izip(iter(src_file),iter(tgt_file)):           
            sline=re.sub(ur"\s\s+" , u" ", sline.strip()).replace(u" ",u"^")
            tline=re.sub(ur"\s\s+" , u" ", tline.strip()).replace(u" ",u"^")

            yield (sline,tline)

def linguistic_similarity(src_fname,tgt_fname,out_fname,src_lang,tgt_lang,sim_measure='lcsr'):

    sim_measure_func=None

    if sim_measure=='lcsr': 
        sim_measure_func=lcsr 
    elif sim_measure=='ned': 
        sim_measure_func=ned 
    else: 
        raise Exception("")
  
    total=0.0
    n=0.0
    with codecs.open(out_fname,'w','utf-8') as out_file: 
        for sline, tline in iterate_parallel_corpus(src_fname,tgt_fname):           
            score,sl,tl=sim_measure_func(sline,tline,src_lang,tgt_lang)
            total+=score
            n+=1.0

            out_file.write(u'{}|{}|{}\n'.format(score,sl,tl))

        print total/n

def _func_char_ngram_split(line, n=1,overlap=False,space_delim=u"^"): 
    l=re.sub(ur"\s\s+" , u" ", line).replace(u" ",space_delim)
    ngrams=[l[i:i+n] for i in xrange(0, len(l), n-1 if overlap else n)]
    return u' '.join( [x for x in ngrams ] ) 

def char_ngram_split(infname, outfname, n=1,overlap=False,space_delim=u"^"):
    """
    create ngrams from the 
    """
    
    if type(n)==str: 
        n=int(n)

    if type(overlap)==str: 
        if overlap=='True':
            overlap=True
        elif overlap=='False':            
            overlap=False

    with codecs.open(infname,'r','utf-8') as infile, codecs.open(outfname,'w','utf-8') as outfile: 
     
        for line in infile:
            outfile.write( _func_char_ngram_split(line.strip(),n,overlap,space_delim) + u'\n') 

def morph_split(infname, outfname, lang, space_delim=u"^"):
    
    analyzer=imorph.UnsupervisedMorphAnalyzer(lang,False)

    with codecs.open(infname,'r','utf-8') as infile, codecs.open(outfname,'w','utf-8') as outfile: 
     
        for line in infile:
            line=re.sub(ur"\s\s+" , u" ", line)
            morphs=[]
            for word in line.strip().split(u' '):
                morphs.append(u' '.join(analyzer.morph_analyze(word)))
            outfile.write( u' {} '.format(space_delim).join(morphs) + u'\n') 


def urdu_morph_analyze(word,urdu_morfessor_model,urdu_script_check_re): 
    """
    Morphanalyzes a single word and returns a list of component morphemes

    @param word: string input word 
    """

    def urdu_morphanalysis_needed(word):
        return urdu_script_check_re.match(word) 

    m_list=[]
    if urdu_morphanalysis_needed(word): 
        val=urdu_morfessor_model.viterbi_segment(word)
        m_list=val[0]
    else:
        m_list=[word]
    return m_list 

def morph_split_urdu(infname, outfname, model_path, space_delim=u"^"):
    
    urdu_script_range_pat=ur'^[{}-{}{}-{}{}-{}{}-{}]+$'.format(
                unichr(0x0600),unichr(0x06ff), 
                unichr(0x0750),unichr(0x077f), 
                unichr(0xfb50),unichr(0xfdff), 
                unichr(0xfe70),unichr(0xfeff), 
            )
    urdu_script_check_re=re.compile(urdu_script_range_pat)

    io = morfessor.MorfessorIO()
    urdu_morfessor_model=io.read_any_model(model_path)

    with codecs.open(infname,'r','utf-8') as infile, codecs.open(outfname,'w','utf-8') as outfile: 
     
        for line in infile:
            line=re.sub(ur"\s\s+" , u" ", line)
            morphs=[]
            for word in line.strip().split(u' '):
                morphs.append(u' '.join(urdu_morph_analyze(word,urdu_morfessor_model,urdu_script_check_re)))
            outfile.write( u' {} '.format(space_delim).join(morphs) + u'\n') 

def orth_split(infname, outfname, lang,space_delim=u"^"):
    
    with codecs.open(infname,'r','utf-8') as infile, codecs.open(outfname,'w','utf-8') as outfile: 
     
        for line in infile:
            line=re.sub(ur"\s\s+" , u" ", line)
            syllables=[]
            for word in line.strip().split(u' '):
                syllables.append(u' '.join(syll.orthographic_syllabify(word,lang)))

            outfile.write( u' {} '.format(space_delim).join(syllables) + u'\n') 

def orth_simple_split(infname, outfname, lang,space_delim=u"^"):
    
    with codecs.open(infname,'r','utf-8') as infile, codecs.open(outfname,'w','utf-8') as outfile: 
     
        for line in infile:
            line=re.sub(ur"\s\s+" , u" ", line)
            syllables=[]
            for word in line.strip().split(u' '):
                syllables.append(u' '.join(syll.orthographic_simple_syllabify(word,lang)))

            outfile.write( u' {} '.format(space_delim).join(syllables) + u'\n') 

def orth_split_non_indic(infname, outfname, vowel_set_fname, space_delim=u"^"):
   
    vowel_set=set()
    with codecs.open(vowel_set_fname,'r','utf-8') as vowel_file: 
        vowel_set=set([ x.strip() for x in vowel_file ])

    with codecs.open(infname,'r','utf-8') as infile, codecs.open(outfname,'w','utf-8') as outfile: 
     
        for line in infile:
            line=re.sub(ur"\s\s+" , u" ", line)
            syllables=[]
            for word in line.strip().split(u' '):
                syllables_word=[]
                for i in xrange(len(word)): 
                    syllables_word.append(word[i])
                    if word[i] in vowel_set and (i+1==len(word) or word[i+1] not in vowel_set): 
                        syllables_word.append(u' ')
                        
                syllables.append(u''.join(syllables_word).strip())

            outfile.write( u' {} '.format(space_delim).join(syllables) + u'\n') 

def orth_backoff_split(infname, outfname, vocab_fname):

    ## read vocab
    vocab_set=None
    with codecs.open(vocab_fname,'r','utf-8') as vocabfile: 
        vocab_set=set([x.strip().split(u'|')[0] for x in vocabfile])
  
    ## process file 
    with codecs.open(infname,'r','utf-8') as infile, codecs.open(outfname,'w','utf-8') as outfile: 
        for line in infile: 
            words=line.strip().split(u' ')
            new_words=[ x if x in vocab_set else u' '.join(x) for x in words ]
            outfile.write(u' '.join(new_words) + u'\n')

def unsplit(infname, outfname, space_delim=u"^"):
    
    with codecs.open(infname,'r','utf-8') as infile, codecs.open(outfname,'w','utf-8') as outfile: 
     
        for line in infile:
            line=re.sub(ur"\s\s+" , u" ", line.strip()).replace(u' ',u'').replace(space_delim,u' ')
            outfile.write( line + u'\n') 

def unsplit_imarker(infname, outfname, space_delim=u"^"):
    
    with codecs.open(infname,'r','utf-8') as infile, codecs.open(outfname,'w','utf-8') as outfile: 
     
        for line in infile:
            line=re.sub(ur"\s\s+" , u" ", line.strip()).replace(space_delim+u' ',u'')
            outfile.write( line + u'\n') 

def unsplit_nbest_file(infname, outfname, space_delim=u"^"):
    
    with codecs.open(infname,'r','utf-8') as infile, codecs.open(outfname,'w','utf-8') as outfile: 
     
        for record in infile:
            fields=record.strip().split(u' ||| ')
            line=fields[1]
            line=re.sub(ur"\s\s+" , u" ", line.strip()).replace(u' ',u'').replace(space_delim,u' ')
            fields[1]=line
            outfile.write(u' ||| '.join(fields) + u'\n')

def generate_parallel_corpus_pt(infname,outfname_s,outfname_t,n=1,space_delim=u"^"): 
    with gzip.open(infname) as infile, \
            codecs.open(outfname_s,'w','utf-8') as outfile_s, \
            codecs.open(outfname_t,'w','utf-8') as outfile_t:
        for line in codecs.getreader("utf-8")( infile ): 
            fields=line.strip().split(u'|||')
            outfile_s.write(u''.join( _func_char_ngram_split(fields[0].strip(),n,space_delim))+u'\n')
            outfile_t.write(u''.join( _func_char_ngram_split(fields[1].strip(),n,space_delim))+u'\n')

def normalize_punjabi(infname,outfname): 
    with codecs.open(infname,'r','utf-8') as infile, codecs.open(outfname,'w','utf-8') as outfile: 
        for line in infile:
            ## replace tippi with anusvaar
            line=line.replace(u'\u0a70',u'\u0a02')
            ## replace addak+consonant with consonat+halant+consonant
            line=re.sub(ur'\u0a71(.)',u'\\1\u0a4d\\1',line)
            outfile.write(line)

def normalize_malayalam(infname,outfname): 
    with codecs.open(infname,'r','utf-8') as infile, codecs.open(outfname,'w','utf-8') as outfile: 
        for line in infile:

            # instead of chillu characters, use consonant+halant 
            line=line.replace(u'\u0d7a',u'\u0d23\u200d') 
            line=line.replace(u'\u0d7b',u'\u0d28\u200d')
            line=line.replace(u'\u0d7c',u'\u0d30\u200d')
            line=line.replace(u'\u0d7d',u'\u0d32\u200d')
            line=line.replace(u'\u0d7e',u'\u0d33\u200d')
            line=line.replace(u'\u0d7f',u'\u0d15\u200d')
            outfile.write(line)

def clean_pt(infname,outfname): 
    with gzip.open(infname) as infile, \
        gzip.open(outfname,'wb') as outfile:

        writer=codecs.getwriter('utf-8')( outfile)
        for line in codecs.getreader("utf-8")( infile ): 
            fields=line.strip().split(u'|||')
            fields[0]=fields[0].replace(u'[',u'&#91;').replace(u']',u'&#93;')
            fields[1]=fields[1].replace(u'[',u'&#91;').replace(u']',u'&#93;')
            writer.write( u'|||'.join(fields) + u'\n')

def prune_pt(infname,outfname,threshold=0.01,threshold_field=2): 

    if type(threshold) is str: 
        threshold=float(threshold)

    if type(threshold_field) is str: 
        threshold_field=int(threshold_field)

    with gzip.open(infname) as infile, \
        gzip.open(outfname,'wb') as outfile:

        writer=codecs.getwriter('utf-8')( outfile)
        for line in codecs.getreader("utf-8")( infile ): 
            fields=line.strip().split(u'|||')
            tt_feats=[float(x) for x in fields[2].strip().split()]
            if tt_feats[threshold_field]>=threshold: 
                writer.write(line)

def add_lcsr_feature_pt(infname,outfname,slang,tlang): 

    with gzip.open(infname) as infile, \
        gzip.open(outfname,'wb') as outfile:

        writer=codecs.getwriter('utf-8')( outfile)
        for line in codecs.getreader("utf-8")( infile ): 
            fields=line.strip().split(u' ||| ')
            tt_feats=[float(x) for x in fields[2].strip().split()]
            tt_feats.append(lcsr(fields[0].strip(),fields[1].strip(),slang,tlang)[0])
            fields[2]=u' '.join([ str(x) for x in tt_feats])
            writer.write( u' ||| '.join(fields) + u'\n')

def correct(infname,outfname): 

    with gzip.open(infname) as infile, \
        gzip.open(outfname,'wb') as outfile:

        writer=codecs.getwriter('utf-8')( outfile)
        for line in codecs.getreader("utf-8")( infile ): 
            fields=line.strip().split(u' ||| ')
            x=fields[2].strip().index('(')
            pre=fields[2].strip()[:x]
            post=fields[2].strip()[x:]
            fields[2]=pre+str(eval(post)[0])
            writer.write( u' ||| '.join(fields) + u'\n')

def create_moses_conf(template_fname,outfname,slang,tlang,size,exp,order): 
    with codecs.open(template_fname,'r','utf-8') as tfile: 
        with codecs.open(outfname,'w','utf-8') as ofile: 
            template=tfile.read()
            contents=template.format(slang=slang,tlang=tlang,exp=exp,size=size,order=order)
            ofile.write(contents)

def create_joint_mono_corpus(src_mono_fname, tgt_mono_fname, joint_mono_fname, src_lang, tgt_lang):
    """
    Creates a single monolingual corpus for source and target language, by script converting target script to source script.
    This works for Indian scripts.
    """

    with codecs.open(src_mono_fname,'r','utf-8') as srcfile, \
        codecs.open(tgt_mono_fname,'r','utf-8') as tgtfile, \
        codecs.open(joint_mono_fname,'w','utf-8') as jointfile :  

            outlines=[]
            outlines.extend([ l for l in srcfile])
            outlines.extend([ uit.transliterate(l,tgt_lang,src_lang) for l in tgtfile])
            random.shuffle(outlines)

            for line in outlines: 
                jointfile.write(line)

def compute_mdl_jointbpe_segmentation(model_fname,src_fname,tgt_fname):
    """
    Compute the Minimum Description Length of the Model+data for the Joint BPE segmentation
    """

    model_size=0
    src_size=0
    tgt_size=0

    with codecs.open(model_fname,'r','utf-8') as model_file: 
        model_size=len(model_file.read())

    with codecs.open(src_fname,'r','utf-8') as src_file: 
        for line in src_file: 
            src_size+=len(line.strip().split(' '))

    with codecs.open(tgt_fname,'r','utf-8') as tgt_file: 
        for line in tgt_file: 
            tgt_size+=len(line.strip().split(' '))

    print model_size+src_size+tgt_size, model_size, src_size, tgt_size 

def length_stats(infname): 
    with codecs.open(infname,'r','utf-8') as infile:
        lengths=[]
        for line in infile:
            lengths.append(len(line.split()))

        mx=len(filter(lambda x:x>50,lengths))
        print mx 

def space_to_boundary_marker_format(line,marker_char=u'^'): 
    return line.replace(u' {}'.format(marker_char), u'{}'.format(marker_char))

def space_to_internal_marker_format(line,marker_char=u'^'): 
    return u' '.join([ x[:-1]  if x[-1]==marker_char else x+marker_char for x in space_to_boundary_marker_format(line,marker_char).split() ])

def format_converter(infname,outfname,converter_function): 

    with codecs.open(infname,'r','utf-8') as infile,\
            codecs.open(outfname,'w','utf-8') as outfile: 
        for line in infile:
            line=re.sub(ur"\s\s+" , u" ", line).strip()
            output_line=converter_function(line)
            outfile.write( output_line + u'\n') 

def format_converter_wrapper(infname,outfname,converter_function_name):

    func_map={
        'space_to_boundary_marker_format': space_to_boundary_marker_format,
        'space_to_internal_marker_format': space_to_internal_marker_format,
        }

    format_converter(infname,outfname,func_map[converter_function_name])


def create_sent_length_mask(infname, mask_fname, binsize=10, nbins=5): 
    with codecs.open(infname,'r','utf-8') as infile,\
            codecs.open(mask_fname,'w','utf-8') as maskfile: 
        for line in infile:
            line=re.sub(ur"\s\s+" , u" ", line).strip()
            bin_n=(len(line.split())-1)/binsize
            bin_n = (nbins-1) if bin_n >= nbins else bin_n
            maskfile.write('{}\n'.format(bin_n))

def split_by_sent_mask(infname, mask_fname, outdir, nbins=5): 
    with codecs.open(infname,'r','utf-8') as infile,\
            codecs.open(mask_fname,'r','utf-8') as maskfile: 
        
        ### open output file handles                 
        split_files=[ codecs.open('{}/{}.txt'.format(outdir,i),'w','utf-8') for i in range(nbins) ]

        ### write each sentence to appropriate bin file                     
        for (bin_n, line) in it.izip(iter(maskfile),iter(infile)):
            bin_n=int(bin_n.strip())
            split_files[bin_n].write(line)

        ## close the file handles             
        for i in range(nbins): 
            split_files[i].close()

def filter_by_sent_mask(mask_fname, selected_bin_n): 
    infile=codecs.getreader('utf-8')(sys.stdin)
    outfile=codecs.getwriter('utf-8')(sys.stdout)
    selected_bin_n=int(selected_bin_n)

    ### read the mask file 
    mask=[]
    with codecs.open(mask_fname,'r','utf-8') as maskfile: 
        mask=[ int(bin_n.strip()) for bin_n in maskfile ]
        
    ### select only the lines for the requested bin 
    for (line_n, line) in enumerate(iter(infile)):
        bin_n=mask[line_n]
        if bin_n==selected_bin_n: 
            outfile.write(line)


def isvalid(word): 
    return len(word)>=3 and not True in [ x.isnumeric() for x in word ]

def create_word_prediction_dataset(text_fname, nsentences, testset_fname, gold_fname): 
    """
        Create a word prediction dataset from a monolingual corpus as follows: 
        - Select the first `nsentences` of the file `text_fname`
        - For each selected sentence: 
          - Select a random word at word_index  
          - output the triple (sentno, word_index, word)


        text_fname: input file
        nsentences: the number of top sentences to select 
        testset_fname: output file 
    """

    nsentences=int(nsentences)

    with codecs.open(text_fname,'r','utf-8') as textfile, \
         codecs.open(testset_fname,'w','utf-8') as testset_file, \
         codecs.open(gold_fname,'w','utf-8') as gold_file:

        for sent_no, line in enumerate(it.islice(iter(textfile),nsentences)): 

            words=line.strip().split(u' ')
            index=random.randint(0,len(words)-1)
            while not isvalid(words[index]): 
                index=random.randint(0,len(words)-1)
            gold_file.write(u'|'.join([str(sent_no),str(index),words[index]]) + u'\n' )
            words[index]=u'@@UNK@@'
            testset_file.write(u' '.join(words)+u'\n')

def create_subword_prediction_dataset(text_fname, nsentences, testset_fname, gold_fname, delim=u'^'): 
    """
        Create a word prediction dataset from a monolingual corpus as follows: 
        - Select the first `nsentences` of the file `text_fname`
        - For each selected sentence: 
          - Select a random word at word_index  
          - output the triple (sentno, word_index, word)


        text_fname: input file
        testset_fname: output file 
        gold_fname: file containing information about words to be masked
            (created by word level prediction dataset creation)
    """

    nsentences=int(nsentences)

    with codecs.open(text_fname,'r','utf-8') as textfile,  \
         codecs.open(gold_fname,'r','utf-8') as gold_file, \
         codecs.open(testset_fname,'w','utf-8') as testset_file:

        for data_line, info_line in it.izip(it.islice(iter(textfile),nsentences), iter(gold_file)): 
            
            info=info_line.strip().split(u'|')

            words=data_line.strip().split(delim)
            index=int(info[1])

            subwords=words[index].strip().split(u' ')
            assert(info[2]==u''.join(subwords))
            nsubwords=len(subwords)
            words[index]=u' '+u' '.join([u'@@UNK@@']*nsubwords)+u' '

            testset_file.write(delim.join(words)+u'\n')


def evaluate_predicted_word(pred_text_fname, gold_fname, pred_word_fname): 
    """
    """
    with codecs.open(pred_text_fname,'r','utf-8') as pred_text_file, \
         codecs.open(gold_fname,'r','utf-8') as gold_file, \
         codecs.open(pred_word_fname,'w','utf-8') as pred_word_file:

        matches=[]             
        for data_line, info_line in it.izip(iter(pred_text_file), iter(gold_file)): 

            info=info_line.strip().split(u'|')

            words=data_line.strip().split(u' ')
            index=int(info[1])

            pred_word_file.write(words[index] + u'\n' )
            matches.append(info[2]==words[index])

        print float(len(filter(lambda x:x==True,matches)))/float(len(matches))

### Methods for parsing n-best lists
def parse_nbest_line(line):
    """
        line in n-best file 
        return list of fields
    """
    fields=[ x.strip() for x in  line.strip().split('|||') ]
    fields[0]=int(fields[0])
    fields[3]=float(fields[3])
    return fields

def iterate_nbest_list(nbest_fname): 
    """
        nbest_fname: moses format nbest file name 
        return iterator over tuple of sent_no, list of n-best candidates

    """

    infile=codecs.open(nbest_fname,'r','utf-8')
    
    for sent_no, lines in it.groupby(iter(infile),key=lambda x:parse_nbest_line(x)[0]):
        parsed_lines = [ parse_nbest_line(line) for line in lines ]
        yield((sent_no,parsed_lines))

    infile.close()

def transfer_pivot_translate(output_s_b_fname,output_b_t_fname,output_final_fname,n=10): 

    b_t_iter=iter(iterate_nbest_list(output_b_t_fname))

    with codecs.open(output_final_fname,'w','utf-8') as output_final_file: 
        for (sent_no, parsed_bridge_lines) in iterate_nbest_list(output_s_b_fname):     
            candidate_list=[]
            for parsed_bridge_line in parsed_bridge_lines: 
                (_,parsed_tgt_lines)=b_t_iter.next()
                for parsed_tgt_line in parsed_tgt_lines:
                    output=parsed_tgt_line[1]
                    score=parsed_bridge_line[3]+parsed_tgt_line[3]
                    candidate_list.append((output,score))

            ## if there are duplicates their log probabilities need to be summed 
            candidate_list.sort(key=lambda x:x[0])
            group_iterator=it.groupby(candidate_list,key=lambda x:x[0])
            candidate_list=[ (k,logsumexp([x[1] for x in group]))  for k, group in group_iterator ]
                
            candidate_list.sort(key=lambda x:x[1],reverse=True)

            for c,score in candidate_list[:n]:
                output_final_file.write( u'{} ||| {} ||| {} ||| {}\n'.format( sent_no, c, '0.0 0.0 0.0 0.0', score  ) )


def create_mosesini_triangulated(template_mosesini_fname,out_mosesini_fname,phrase_table_fname,lm_fname,lm_order): 

    with codecs.open(template_mosesini_fname,'r','utf-8') as tfile: 
        with codecs.open(out_mosesini_fname,'w','utf-8') as ofile: 
            template=tfile.read()
            contents=template.format(phrase_table_fname,lm_fname,lm_order)
            ofile.write(contents)

def convert_to_nbest_format(infname,outfname):
    """
    Input is 1-best format 
    """
    with codecs.open(infname,'r','utf-8') as infile: 
        with codecs.open(outfname,'w','utf-8') as outfile: 
            for n,line in enumerate(iter(infile)):
                outfile.write( u'{} ||| {} ||| {} ||| {}\n'.format( n, line.strip(), 
                    u'Distortion0= 0 LM0= 0 WordPenalty0= 0 PhrasePenalty0= 3 TranslationModel0= 0 0 0 0', u'0' ) )

def convert_to_1best_format(infname,outfname):
    """
    Input is n-best format 
    """
    with codecs.open(outfname,'w','utf-8') as outfile:
        for sent_no, parsed_lines in iterate_nbest_list(infname): 
            outfile.write(parsed_lines[0][1].strip()+u'\n')

def convert_to_kbest_format(infname,outfname,k_str):
    """
    Input is n-best format 
    """
    k=int(k_str)
    with codecs.open(outfname,'w','utf-8') as outfile:
        for sent_no, parsed_lines in iterate_nbest_list(infname): 
            for i in xrange(0,k): 
                outfile.write( u'{} ||| {} ||| {} ||| {}\n'.format( *parsed_lines[i]  ) )

def get_vocabulary(text_fname, vocab_fname): 
    """
    Get the vocabulary of the text_fname and writes it to the vocab_fname along with frequency
    """
    with codecs.open(text_fname,'r','utf-8') as infile, \
         codecs.open(vocab_fname,'w','utf-8') as outfile: 

        count_map={}
        for line in infile:
            sent=line.strip().split(' ')
            for w in sent:
                count_map[w]=count_map.get(w,0.0)+1.0

        for w,c in count_map.iteritems(): 
            outfile.write(u'{}|{}\n'.format(w,c))
    

if __name__=='__main__': 

    loader.load()

    commands={
            'char_ngram_split':char_ngram_split,
            'orth_split':orth_split,
            'orth_simple_split':orth_simple_split,
            'orth_split_non_indic':orth_split_non_indic,
            'orth_backoff_split':orth_backoff_split,
            'morph_split':morph_split,
            'morph_split_urdu':morph_split_urdu,

            'unsplit':unsplit,
            'unsplit_imarker':unsplit_imarker,
            'unsplit_nbest_file':unsplit_nbest_file,

            'generate_parallel_corpus_pt':generate_parallel_corpus_pt,
            'clean_pt':clean_pt,
            'prune_pt':prune_pt,
            'add_lcsr_feature_pt': add_lcsr_feature_pt,
            'correct': correct,

            'normalize_punjabi':normalize_punjabi,
            'normalize_malayalam':normalize_malayalam,

            'create_moses_conf':create_moses_conf,

            'linguistic_similarity':linguistic_similarity,

            'create_joint_mono_corpus': create_joint_mono_corpus,

            'mdl_jointbpe_segmentation': compute_mdl_jointbpe_segmentation,

            'length_stats': length_stats,
            'get_vocabulary': get_vocabulary,

            'format_converter': format_converter_wrapper,

            'create_sent_length_mask': create_sent_length_mask,
            'split_by_sent_mask': split_by_sent_mask,
            'filter_by_sent_mask': filter_by_sent_mask,

            'create_word_prediction_dataset': create_word_prediction_dataset,
            'create_subword_prediction_dataset': create_subword_prediction_dataset,
            'evaluate_predicted_word': evaluate_predicted_word,

            'transfer_pivot_translate': transfer_pivot_translate,
            'create_mosesini_triangulated': create_mosesini_triangulated,

            'convert_to_nbest_format':convert_to_nbest_format,
            'convert_to_1best_format':convert_to_1best_format,
            'convert_to_kbest_format':convert_to_kbest_format,
            }

    commands[sys.argv[1]](*sys.argv[2:])
